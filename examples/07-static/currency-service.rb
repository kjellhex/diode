require 'sqlite3'

class CurrencyService

	def initialize()
		$db ||= SQLite3::Database.new("forex.db")
		create_database() if $db.table_info("currency").empty?
	end

	def serve(request)
    request.method == "GET" ? get(request) : post(request)
  end

  def get(request)
		cid = request.params["cid"] || ""
		if cid.empty? # return a list of currency codes
		  rows = $db.execute("SELECT cid FROM currency")
		  body = JSON.dump(rows)  # expect something like [['1'],['2']]
		else # return the details for a single currency
		  row = $db.execute("SELECT * FROM currency WHERE cid=?", cid)
		  return Diode::Response.new(404, "{}") if row.empty?
		  h = ["cid","name","iso","price"].zip(row.first).to_h
		  body = JSON.dump(h)
		end
		Diode::Response.new(200, body)
  end

  def post(request)
		# omit validation and error checking for brevity
		j = JSON.parse(request.body)
		$db.execute("UPDATE currency SET name=?, isocode=?, lastprice=? WHERE cid=?", j["name"], j["iso"], j["price"],j["cid"])
		Diode::Response.new(200, "{}")
  end

	def create_database()
		$db.execute("CREATE TABLE currency( cid int PRIMARY KEY, name text, isocode text, lastprice int ); ")
		$db.execute("INSERT INTO currency VALUES (1, 'Russian Ruble', 'RUB', 61)")
		$db.execute("INSERT INTO currency VALUES (2, 'Euro', 'EUR', 60)")
		$db.execute("INSERT INTO currency VALUES (2, 'Swedish Krona', 'SEK', 7)")
	end

end
