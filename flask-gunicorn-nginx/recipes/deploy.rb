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

bash "Restart gunicorn under supervisor" do
  user "root"
  code <<-EOS
    supervisorctl -c /etc/supervisord.conf reread
    supervisorctl -c /etc/supervisord.conf reload
  EOS
end

service "nginx" do
  action :restart
end
