require 'erb'


template = ERB.new <<-EOS
    # Redirect only allowed user agents
    <% if [].length() > 0 %>
    set $pass 0;
    <% end %>
    <% ["allowed_user_agent", "c"].each do |v| %>
    if ($http_user_agent ~ "<%= v %>") {
        set $pass 1;
    }
    <% end %>
    if ($pass = 1) {
      return 403;
    }   
EOS
puts template.result(binding)
