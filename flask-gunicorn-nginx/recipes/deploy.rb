####################
## ENV Varriables ##
####################

helper.app[:environment].each do |key, value|
  Chef::Log.info "Setting #{key} to \"#{value}\"" 
  ENV[key] = value
end

################
## Update App ##
################

execute "Stop gunicorn program" do
  user "root"
  command "supervisorctl -c /etc/supervisord.conf stop gunicorn"
end

execute "Pull code" do
  user "root"
  cwd helper.app_dir
  command "git pull"
end

execute "Install PIP requirements" do
  user "root"
  cwd helper.app_dir
  command "pip install -r requirements.txt"
end

execute "Upgrade database" do
  user "root"
  cwd helper.app_dir
  command  "LC_ALL=#{helper.app[:environment][:LC_ALL]} flask db upgrade"
end

###############################
## Start Giunicorn and NGINX ##
###############################

execute "Restart gunicorn under supervisor" do
  user "root"
  command "supervisorctl -c /etc/supervisord.conf reload"
end

service "nginx" do
  action :restart
end
