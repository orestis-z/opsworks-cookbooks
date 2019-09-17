# general

default['flask-gunicorn-nginx']['project_root'] = '/srv/www/'
default['flask-gunicorn-nginx']['app_subfolder'] = ''

# gunicorn

default['flask-gunicorn-nginx']['gunicorn']["workers"] = 1
default['flask-gunicorn-nginx']['gunicorn']["timeout"] = 30
default['flask-gunicorn-nginx']['gunicorn']["log-level"] = "INFO"
default['flask-gunicorn-nginx']['gunicorn']["worker-class"] = "sync"

# nginx

default['flask-gunicorn-nginx']['nginx']["allowed_user_agents"] = []
