include_recipe "flask-wsgi-nginx::env"

################
## Update App ##
################

execute "Stop wsgi program" do
  user "root"
  command "supervisorctl -c /etc/supervisord.conf stop wsgi"
end

scm_revision = helper.app_source[:revision]
bash "Download code bundle" do
  user "root"
  cwd helper.app_dir
  code <<-EOS
    rm -r ./*
    KEY=`aws s3 ls #{node["flask-wsgi-nginx"][:s3_build_uri]} | sort | tail -n 1 | awk '{print $4}'`
    aws s3 cp #{node["flask-wsgi-nginx"][:s3_build_uri]}$KEY .
    unzip $KEY -d .
    rm $KEY
  EOS
end

execute "Install PIP requirements" do
  user "root"
  cwd helper.app_dir
  command "python3 -m pip install -r requirements.txt " + node["flask-wsgi-nginx"]["pip_install_flags"].join(" ")
end

###############################
## Start Giunicorn and NGINX ##
###############################

execute "Restart wsgi under supervisor" do
  user "root"
  command "supervisorctl -c /etc/supervisord.conf reload"
end

service "nginx" do
  action :restart
end
