require 'diode/server'
require 'sqlite3'
$db = SQLite3::Database.new "library.db"
routing = [
  [%r{^/book$}, "Book"]
]
load 'book.rb'
Diode::Server.new(3999, routing).start()
