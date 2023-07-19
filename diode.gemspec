Gem::Specification.new do |s|
  s.name        = "diode"
  s.version     = "1.0"
  s.summary     = "A fast, simple, pure-ruby application server."
  s.description = "A simple hello world gem"
  s.authors     = ["Kjell Koda"]
  s.email       = "kjell@null4.net"
  s.files       = ["request.rb","response.rb","server.rb","static.rb"].collect{|f| "lib/diode/#{f}"}
  s.homepage    = "https://github.com/kjellhex/diode"
  s.license     = "MIT"
  s.add_dependency "async-io"
end
