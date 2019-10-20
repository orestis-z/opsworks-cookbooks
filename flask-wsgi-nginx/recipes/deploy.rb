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

execute "Install PIP requirements" do
  user "root"
  cwd helper.app_dir
  command "pipenv install --skip-lock"
end

if node["flask-wsgi-nginx"]["flask"]["db"]
  bash "Upgrade database" do
    user "root"
    cwd helper.app_dir
    code  <<-EOS
        LC_ALL=#{helper.app[:environment][:LC_ALL]} pipenv run flask db upgrade
      EOS
  end
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
