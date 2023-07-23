require 'diode/server'
routing = [
  [%r{^/curr$}, "CurrencyService"],
  [%r{^/img/},  "Diode::Static", "images"],
  [%r{^/},      "Diode::Static"]
]
load './currency-service.rb'
Diode::Server.new(3999, routing).start()
