######################
## Install Packages ##
######################

execute "Install amazon-linux-extras packages" do
  user "root"
  command "amazon-linux-extras install epel"
end

execute "Install yum packages" do
  user "root"
  command "yum install -y python36 python36-devel.x86_64 python36-pip postgresql-devel.x86_64"
end

execute "Upgrade PIP" do
  user "root"
  command "python3 -m pip install --upgrade pip"
end

execute "Install PIP packages" do
    user "root"
    command "python3 -m pip install --upgrade supervisor superlance"
end

#################
## Create dirs ##
#################

["bin", "log", "etc"].each do |folder|
  directory File.join(helper.deploy_to, folder) do
    recursive true
  end
end


#################
## Shared libs ##
#################

bash "Register shared libraries" do
  user "root"
  code <<-EOS
    cp -P /opt/chef/embedded/lib/libiconv.so* /lib64/ # required for uwsgi
    ldconfig
  EOS
end

###########
## NGINX ##
###########

if node["flask-wsgi-nginx"]["nginx"]["build_from_source"]
  # nginx installation file
  template helper.nginx_install_file do
    source "install-nginx.sh.erb"
  end

  execute "Install nginx from source" do
    user "root"
    command "sh #{helper.nginx_install_file}"
  end
else
  package "nginx"
end

# Create systemd unit file for NGINX
template "/etc/systemd/system/nginx.service" do
  source "nginx.service.erb"
end

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
  action [:reload, :enable, :start]
end

################
## supervisor ##
################

bash "Creating default supervisord configuration file" do
  user "root"
  code <<-EOS
    echo_supervisord_conf > /etc/supervisord.conf
    echo "[include]" >> /etc/supervisord.conf
    echo "files = #{helper.wsgi_supervisor_conf_path}" >> /etc/supervisord.conf
  EOS
end

app_dir = helper.app_dir

# supervisord configuration for Gunicorn
template helper.wsgi_supervisor_conf_path do
  source "wsgi.conf.erb"
  variables app_dir: app_dir
end

# wsgi launch file
template helper.wsgi_start_path do
  mode "0700"
  source "wsgi-start.sh.erb"
  variables app_dir: app_dir
end

execute "Start supervisord if not running and stop wsgi program" do
  user "root"
  command "pgrep supervisord > /dev/null || ( supervisord -c /etc/supervisord.conf && supervisorctl -c /etc/supervisord.conf stop wsgi )"
end

#########
## GIT ##
#########

bash "Add SSH key for GIT" do
    user "root"
    code <<-EOS
      touch ~/.ssh/id_rsa
      chmod 400 ~/.ssh/id_rsa
      echo '#{helper.app_source[:ssh_key]}' >> ~/.ssh/id_rsa
      eval $(ssh-agent -s)
      ssh-add ~/.ssh/id_rsa
    EOS
end

execute "Add bitbucket.org to known hosts" do
    user "root"
    command "ssh-keyscan -H bitbucket.org > ~/.ssh/known_hosts"
end

bash "Set dummy email & name to GIT config" do
    user "root"
    code <<-EOS
      git config --global user.email "dummy@mail.com"
      git config --global user.name "dummy"
    EOS
end

directory helper.repository_dir do
  action :delete
  recursive true
  only_if { ::File.directory?(helper.repository_dir) }
end

scm_revision = helper.app_source[:revision]
execute "Cloning repository" do
    user "root"
    command "git clone" + \
      (scm_revision.nil? ? "" : " --single-branch --branch #{scm_revision}" )+ \
      " #{helper.app_source[:url]} #{helper.repository_dir}"
end

##########
## VENV ##
##########

execute "Create venv" do
    user "root"
    cwd helper.app_dir
    command "python3 -m venv venv"
end
