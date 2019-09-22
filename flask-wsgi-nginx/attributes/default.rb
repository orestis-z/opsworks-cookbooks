# general

default["flask-wsgi-nginx"]["project_root"] = "/srv/www/"
default["flask-wsgi-nginx"]["app_subfolder"] = ""

# bjoern

default["flask-wsgi-nginx"]["wsgi"]["server"] = "gunicorn"
default["flask-wsgi-nginx"]["wsgi"]["module"] = ""
default["flask-wsgi-nginx"]["wsgi"]["workers"] = 1
default["flask-wsgi-nginx"]["wsgi"]["worker-timeout"] = 30
default["flask-wsgi-nginx"]["wsgi"]["log-level"] = "INFO"
default["flask-wsgi-nginx"]["wsgi"]["async"] = 0
default["flask-wsgi-nginx"]["wsgi"]["worker-class"] = "sync"

# nginx

default["flask-wsgi-nginx"]["nginx"]["allowed_user_agents"] = []
