######################
## Install Packages ##
######################

case node[:platform_family]
  # RHEL platforms (redhat, centos, scientific, etc)
  when "rhel"
    execute "Install amazon-linux-extras packages" do
      user "root"
      command "amazon-linux-extras install epel"
    end

    execute "Install yum packages" do
      user "root"
      command "yum install -y python36 python36-devel.x86_64 python36-pip postgresql-devel.x86_64"
    end

  # debian-ish platforms (debian, ubuntu, linuxmint)
  when "debian"
    bash "Install python3.7" do
      user "root"
      code <<-EOS
        apt-get install -y python3.7
        apt-get install -y python3.7-dev python3-distutils python3.7-venv
        apt-get clean
      EOS
    end

    bash "Install PIP" do
      user "root"
      code <<-EOS 
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3.7 get-pip.py
      EOS
    end

    bash "Install apt-get packages" do
      user "root"
      code <<-EOS
        apt-get install -y libpq-dev awscli unzip #{node["flask-wsgi-nginx"][:apt_packages].join(" ")}
        apt-get clean
      EOS
    end
end

execute "Install PIP packages" do
    user "root"
    command "python3.7 -m pip install --upgrade wheel supervisor superlance pip"
end

if not node["flask-wsgi-nginx"][:pip_ignore_installed].empty?
  execute "Install PIP requirements (ignore-installed)" do
    user "root"
    command "python3.7 -m pip install --ignore-installed " + node["flask-wsgi-nginx"][:pip_ignore_installed].join(" ")
  end
end

if not node["flask-wsgi-nginx"][:pip_force_reinstall].empty?
  execute "Install PIP requirements (force-reinstall)" do
    user "root"
    command "python3.7 -m pip install --force-reinstall " + node["flask-wsgi-nginx"][:pip_force_reinstall].join(" ")
  end
end

#################
## Create dirs ##
#################

["bin", "log", "etc", "current"].each do |folder|
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
  mode "0644"
  owner node[:platform_family] == "rhel" ? "nginx" : "www-data"
  group node[:platform_family] == "rhel" ? "nginx" : "www-data"
end

execute "Reload nginx config file" do
  user "root"
  command "systemctl daemon-reload"
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

##########
## VENV ##
##########

execute "Create venv" do
    user "root"
    cwd helper.app_dir
    command "python3.7 -m venv venv"
end

if node["flask-wsgi-nginx"][:pip_version].nil? 
  bash "Upgrade PIP in venv" do
    user "root"
    cwd helper.app_dir
    code <<-EOS
      source venv/bin/activate
      pip install --upgrade pip
    EOS
  end
else
  bash "Upgrade PIP in venv" do
    user "root"
    cwd helper.app_dir
    code <<-EOS
      source venv/bin/activate
      pip install pip==#{node["flask-wsgi-nginx"][:pip_version]}
    EOS
  end
end

############
## Extras ##
############

if not node["flask-wsgi-nginx"][:bash_extra_script_uri].nil?
  bash "Execute extra bash commands" do
    user "root"
    code <<-EOS
      aws s3 cp #{node["flask-wsgi-nginx"][:bash_extra_script_uri]} run_file
      bash run_file
      rm run_file
    EOS
  end
end
