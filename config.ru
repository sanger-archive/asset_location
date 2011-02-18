#\ -w -p 3011
require "asset_location"
disable :run, :reload

run Sinatra::Application
