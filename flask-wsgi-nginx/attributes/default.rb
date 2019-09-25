# general

default["flask-wsgi-nginx"]["project_root"] = "/srv/www/"
default["flask-wsgi-nginx"]["app_subfolder"] = ""

# wsgi

default["flask-wsgi-nginx"]["wsgi"]["server"] = "gunicorn"
default["flask-wsgi-nginx"]["wsgi"]["module"] = ""
default["flask-wsgi-nginx"]["wsgi"]["workers"] = 1
default["flask-wsgi-nginx"]["wsgi"]["worker_timeout"] = 30
default["flask-wsgi-nginx"]["wsgi"]["graceful_timeout"] = 30
default["flask-wsgi-nginx"]["wsgi"]["log_level"] = "INFO"
default["flask-wsgi-nginx"]["wsgi"]["async"] = 0
default["flask-wsgi-nginx"]["wsgi"]["worker_class"] = "sync"

# nginx

default["flask-wsgi-nginx"]["nginx"]["allowed_user_agents"] = []
default["flask-wsgi-nginx"]["nginx"]["build_from_source"] = false
default["flask-wsgi-nginx"]["nginx"]["version"] = "1.16.1"
default["flask-wsgi-nginx"]["nginx"]["enable_sse"] = false

# supervisor

default["flask-wsgi-nginx"]["supervisor"]["memmon"]["enabled"] = false
default["flask-wsgi-nginx"]["supervisor"]["memmon"]["max_rss"] = 1000
default["flask-wsgi-nginx"]["supervisor"]["memmon"]["email"] = ""
