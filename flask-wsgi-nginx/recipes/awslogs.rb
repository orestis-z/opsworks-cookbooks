##############
## AWS Logs ##
##############

unless node["flask-wsgi-nginx"]["awslogs"]["multi_line_start_pattern"].nil?
  template "/tmp/configure_awslogs.py" do
    source "configure_awslogs.py.erb"
  end

  execute "Configure AWS Logs" do
    user "root"
    command "python3 /tmp/configure_awslogs.py"
  end

  execute "Restart AWS Logs" do
    user "root"
    command "service awslogs restart"
  end
end
