# A helper class for encapsulating information about the installation and configuration of the app.
class Helper
  def initialize(node)
    @node = node
  end
  
  def appshortname
    @node["flask-gunicorn-nginx"][:appshortname]
  end

  def app_deploy
    @node[:deploy][appshortname]
  end

  def repository_dir
    File.join(app_deploy[:deploy_to], "current")
  end

  def app_dir 
    File.join(repository_dir, app_deploy[:document_root])
  end

  def gunicorn_syslog
    "unix://" + File.join(app_deploy[:deploy_to], "log/gunicorn.sock")
  end

  def gunicorn_start_path
    File.join(app_deploy[:deploy_to], "bin/gunicorn-start.sh")
  end

  def gunicorn_supervisor_conf_path
    File.join(app_deploy[:deploy_to], "etc/gunicorn.conf")
  end
end
  
# Update the Chef::Resource, Chef::Recipe and Chef::Mixin::Template::TemplateContext classes to make our helper available in recipes, resources and templates.
class Chef
  class Resource
    def helper
      Helper.new node
    end
  end
  class Recipe
    def helper
      Helper.new node
    end
  end
  module Mixin
    module Template
      class TemplateContext
        def helper
          Helper.new node
        end
      end
    end
  end
end
