# status-server.rb
require 'diode/server'
routing = [
  [%r{^/status$}, "Status"]      # GET and POST
]
settings = {
  "category": "development"
}
load 'status.rb'
diode = Diode::Server.new(3999, routing, settings).start()
