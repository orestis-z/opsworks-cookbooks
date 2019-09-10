Chef::Log.info "Variables: helper.repository_dir=\"#{helper.repository_dir}\", helper.app_dir=\"#{helper.app_dir}\""

######################
## Install Packages ##
######################

package "git"
package "nginx"

execute "Install yum packages" do
  user "root"
  command "yum install -y python36 python36-devel.x86_64 postgresql96-devel.x86_64"
end

execute "Upgrade PIP" do
  user "root"
  command "python3 -m pip install --upgrade pip"
end

execute "Install PIP packages" do
    user "root"
    command "python3 -m pip install --upgrade autoenv supervisor"
end

#################
## Create dirs ##
#################

["bin", "log", "etc", "run"].each do |folder|
  directory File.join(helper.app_deploy[:deploy_to], folder) do
    recursive true
  end
end

###########
## NGINX ##
###########

# primary NGINX configuration file
template "/etc/nginx/nginx.conf" do
  source "nginx.conf.erb"
end

template "/etc/nginx/conf.d/webapp.conf" do
  source "webapp.conf.erb"
end

file "/var/log/nginx/error.log" do
  mode '0644'
  owner "nginx"
  group "nginx"
end

service "nginx" do
  supports :status => true
  action [:enable, :start]
end

################
## supervisor ##
################

bash "Creating default supervisord configuration file" do
  user "root"
  code <<-EOS
    echo_supervisord_conf > /etc/supervisord.conf
    echo "[include]" >> /etc/supervisord.conf
    echo "files = #{helper.gunicorn_supervisor_conf_path}" >> /etc/supervisord.conf
  EOS
end

# supervisord configuration for Gunicorn
template helper.gunicorn_supervisor_conf_path do
  source "gunicorn.conf.erb"
end

# gunicorn launch file
template helper.gunicorn_start_path do
  mode "0700"
  source "gunicorn-start.sh.erb"
end

execute "Start supervisord if not running" do
  user "root"
  command "pgrep supervisord > /dev/null || supervisord -c /etc/supervisord.conf"
end

#########
## GIT ##
#########

bash "Add SSH key for GIT" do
    user "root"
    code <<-EOS
      touch ~/.ssh/id_rsa
      chmod 400 ~/.ssh/id_rsa
      echo '#{helper.app_deploy["scm"]["ssh_key"]}' >> ~/.ssh/id_rsa
      eval $(ssh-agent -s)
      ssh-add ~/.ssh/id_rsa
    EOS
end

directory helper.repository_dir do
  action :delete
  recursive true
  only_if { ::File.directory?(helper.repository_dir) }
end

scm_revision = helper.app_deploy[:scm][:revision]
execute "Cloning repository" do
    user "root"
    command "git clone" + \
      (scm_revision.nil? ? "" : " --single-branch --branch #{scm_revision}" )+ \
      " #{helper.app_deploy[:scm][:repository]} #{helper.repository_dir}"
end

##########
## VENV ##
##########

execute "Create venv" do
    user "root"
    cwd helper.app_dir
    command "python3 -m venv venv"
end

bash "Setup .env" do
    user "root"
    cwd helper.app_dir
    code <<-EOS
      touch .env
      echo "source venv/bin/activate" >> .env
    EOS
end

execute "Activate autoenv" do
  user "root"
  command "AUTOENV_ASSUME_YES=1 source `which activate.sh`"
end
