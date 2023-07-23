require 'sqlite3'
db = SQLite3::Database.new "library.db"
db.execute("DROP TABLE IF EXISTS books;")
db.execute("CREATE TABLE IF NOT EXISTS books ( id int primary key, title text, author text );")
db.execute("INSERT INTO books (id, title, author) VALUES (?,?,?)", [3, "War and Peace", "Leo Tolstoy"])
db.execute("INSERT INTO books (id, title, author) VALUES (?,?,?)", [7, "Disintegration", "Andrei Martyanov"])
puts("[+] sample database created")
