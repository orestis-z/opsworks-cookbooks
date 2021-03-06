# general

default["flask-wsgi-nginx"]["project_root"] = "/srv/www/"
default["flask-wsgi-nginx"]["apt_packages"] = []
default["flask-wsgi-nginx"]["pip_version"] = nil
default["flask-wsgi-nginx"]["pip_install_flags"] = []
default["flask-wsgi-nginx"]["pip_ignore_installed"] = []
default["flask-wsgi-nginx"]["pip_force_reinstall"] = []


# wsgi

default["flask-wsgi-nginx"]["wsgi"]["server"] = "gunicorn"
default["flask-wsgi-nginx"]["wsgi"]["module"] = ""

# nginx

default["flask-wsgi-nginx"]["nginx"]["allowed_user_agents"] = []
default["flask-wsgi-nginx"]["nginx"]["build_from_source"] = false
default["flask-wsgi-nginx"]["nginx"]["version"] = "1.16.1"
default["flask-wsgi-nginx"]["nginx"]["enable_sse"] = false

# supervisor

default["flask-wsgi-nginx"]["supervisor"]["memmon"]["enabled"] = false
default["flask-wsgi-nginx"]["supervisor"]["memmon"]["max_rss"] = 1000
default["flask-wsgi-nginx"]["supervisor"]["memmon"]["email"] = ""
