require 'erb'

var = "uwsgi"

template = ERB.new <<-EOS
    # Redirect only allowed user agents
    <%= var %>
    <% if var == "gunicorn" %>
    gunicorn
    <% elsif var == "uwsgi" %>
    uwsgi
    <% else %>
    not found
    <% end %>
EOS
puts template.result(binding)
