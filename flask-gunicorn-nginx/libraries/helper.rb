# A helper classes for encapsulating information about the installation and configuration of the app.

class BaseHelper
  def initialize(node)
    @node = node
  end

  def deploy_to
    @node["flask-gunicorn-nginx"][:project_root]
  end

  def repository_dir
    File.join(deploy_to, "current")
  end

  def gunicorn_syslog
    "unix://" + File.join(deploy_to, "log/gunicorn.sock")
  end

  def gunicorn_start_path
    File.join(deploy_to, "bin/gunicorn-start.sh")
  end

  def gunicorn_supervisor_conf_path
    File.join(deploy_to, "etc/gunicorn.conf")
  end
end

class Helper < BaseHelper
  def initialize(node, app)
    super(node)
    @app = app
  end

  def app
    @app
  end

  def app_source
    app[:app_source]
  end
  
  def app_dir
    document_root = app[:attributes][:document_root]
    File.join(repository_dir, document_root.nil? ? "" : document_root)
  end
end

def app
  appshortname = node["flask-gunicorn-nginx"][:appshortname]
  search("aws_opsworks_app", "shortname:#{appshortname}").first
end

# Update the Chef::Resource, Chef::Recipe and Chef::Mixin::Template::TemplateContext classes to make our helper available in resources, recipes and templates.
class Chef
  class Resource
    def helper
      Helper.new node, app
    end
  end
  class Recipe
    def helper
      Helper.new node, app
    end
  end
  module Mixin
    module Template
      class TemplateContext
        def helper
          BaseHelper.new node
        end
      end
    end
  end
end
