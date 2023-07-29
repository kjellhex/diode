Gem::Specification.new do |s|
  s.name        = "diode"
  s.version     = "1.2.1"
  s.summary     = "A fast, simple, pure-ruby application server."
  s.description = "Diode helps you to build REST application servers by providing a container for your servlets.
  About as simple as rack but more powerful, and nowhere near as complex as passenger, Diode has only four classes
  that make it easy to get up and running quickly, and provides more features as you progress, but only if you want them. "
  s.authors     = ["Kjell Koda"]
  s.email       = "kjell@null4.net"
  s.files       = ["request.rb","response.rb","server.rb","static.rb"].collect{|f| "lib/diode/#{f}"}
  s.homepage    = "https://github.com/kjellhex/diode"
  s.license     = "MIT"
  s.add_dependency "json"
  s.add_dependency "async-io"
end
