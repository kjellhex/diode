class Book

  def serve(request)
    request.method == "GET" ? get(request) : post(request)
  end

  def get(request)
    if request.params.key?("id")
      bookid = request.params["id"] || ""
      return Diode::Response.new(404, JSON.dump({"reason": "no id"})) if bookid.empty?
      row = $db.execute("SELECT * FROM books WHERE id=?", bookid.to_i()).first()
      return Diode::Response.new(404, JSON.dump({"reason": "not found"})) if row.empty?
      bookid, title, author = row
      body = assemble_xml(bookid, title, author)
    else # return all books
      list = $db.execute("SELECT * FROM books").collect{ |id,title,author|
        assemble_xml(id, title, author)
      }
      body = "<list>\n#{list.join("\n")}\n</list>"
    end
    Diode::Response.new(200, body, {"Content-Type" => "application/xml"})
  end

  def post(request)
    return Diode::Response.new(400, JSON.dump({"reason": "not xml"})) unless request.headers["Content-Type"].downcase().end_with?("/xml")
    request.hash_xml()  # parse the XML payload into the request.fields hash
    p request
    bookid = request.fields["id"] || ""
    title = request.fields["title"] || ""
    author = request.fields["author"] || ""
    return Diode::Response.new(400, JSON.dump({"reason": "need id, title, author"})) if bookid.empty? or author.empty? or title.empty?
    $db.execute("UPDATE books SET title=?, author=? WHERE id=?", [title, author, bookid])
    Diode::Response.new(200, "<status>success</status>", {"Content-Type" => "application/xml"})
  rescue
    Diode::Response.new(500, "<status>failure</status>", {"Content-Type" => "application/xml"})
  end

  def assemble_xml(id, title, author)
    ["<book id=\"#{bookid}\">",
     "  <title>#{title}</title>",
     "  <author>#{author}</author>",
     "</book>"
    ].join("\n")
  end

end
