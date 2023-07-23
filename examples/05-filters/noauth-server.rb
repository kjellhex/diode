class Hello
  def serve(request)
    body = JSON.dump({ "message": "Hello World!" })
    Diode::Response.new(200, body)
  end
end

require 'diode/server'
routing = [
  [%r{^/}, "Hello"]
]
server = Diode::Server.new(3999, routing)
server.start()
