include_recipe "flask-wsgi-nginx::env"

################
## Update App ##
################

execute "Stop wsgi program" do
  user "root"
  command "supervisorctl -c /etc/supervisord.conf stop wsgi"
end

scm_revision = helper.app_source[:revision]
bash "Pull code" do
  user "root"
  cwd helper.app_dir
  code <<-EOS
    git fetch origin #{scm_revision.nil? ? "master" : scm_revision}
    git reset --hard FETCH_HEAD
    git clean -df
  EOS
end

bash "Install PIP requirements" do
  user "root"
  cwd helper.app_dir
  code <<-EOS
    source venv/bin/activate
    pip install -r requirements.txt
  EOS
end

bash "Upgrade database" do
  user "root"
  cwd helper.app_dir
  code  <<-EOS
      source venv/bin/activate
      LC_ALL=#{helper.app[:environment][:LC_ALL]} flask db upgrade
    EOS
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
