####################
## ENV Variables ##
####################

helper.app[:environment].each do |key, value|
  Chef::Log.info "Setting #{key} to \"#{value}\"" 
  ENV[key] = value
end
