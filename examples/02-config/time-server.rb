# time-server.rb
require 'diode/server'
port=3999
routing = [
  [%r{^/cet}, "TimeService", "CET", "Stockholm"],
  [%r{^/kst}, "TimeService", "KST", "Seoul"],
  [%r{^/},    "TimeService", "UTC", "London"]  # catch any other path
]
load 'time-service.rb'

# configure some application-wide properties that are available to all services
settings = {
  "environment": "development",
  "dbconnect": "postgresql://localhost:5432/work"
}
diode = Diode::Server.new(port, routing, settings)

puts("[+] listening on port #{port}")
diode.start()
puts("\r[.] stopped")
