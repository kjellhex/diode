require 'uri'

module Diode

class RequestError < StandardError
	attr_accessor(:code)
	def initialize(code, message="")
		@code = code
		super(message)
	end
	def ==(e)	# define equality for convenient testing
		message == e.message
	end
end

class SecurityError < StandardError
end

class Request

	def self.mock(url)
		u = URI(url)
		msg = "GET #{u.path}#{u.query.nil? ? "" : "?"+u.query} HTTP/1.1\r\nHost: #{u.host}\r\nUser-Agent: MockDiode/1.0\r\n\r\n"
		new(msg)
	end

	attr_accessor(:method, :version, :url, :path, :params, :headers, :cookies, :body, :fields, :env, :filters, :remote, :pattern)

	def initialize(msg)
		reqline, sep, msg = msg.partition("\r\n")
		raise(Diode::RequestError.new(400)) if reqline.to_s.empty?
		raise(Diode::RequestError.new(405)) unless reqline.start_with?("GET ") or reqline.start_with?("POST ")
		raise(Diode::RequestError.new(400)) unless reqline.end_with?(" HTTP/1.0") or reqline.end_with?(" HTTP/1.1")
		@method = reqline.start_with?("GET ") ? "GET" : "POST"
		@version = reqline[-3..-1]
		@url = reqline[(@method.size+1)..-10]
		@path, _sep, @query = @url.partition("?")
		@params = {}
		@fields = {}
		unless @query.nil?
			@query.split("&").each{|pair|
				name, value = pair.split("=")
				next if name.to_s.empty?
				@params[name] = url_decode(value)
			}
		end
		return if msg.nil?
		@headers = {}
		begin
			headerline, sep, msg = msg.partition("\r\n")
			while not headerline.strip.empty?
				key, value = headerline.strip.split(': ')
				@headers[key] = value
				headerline, sep, msg = msg.partition("\r\n")
			end
		rescue EOFError
			# tolerate missing \r\n at end of request
		end
		@cookies = {}
		if @headers.key?("Cookie")
			@headers["Cookie"].split('; ').each { |c|
				k, eq, v = c.partition("=")
				@cookies[k] = v
			}
		end
		@body = msg
		@fields = {}  # to store fields from JSON or XML body
		@env = {}     # application settings, added by Diode::Server
		@filters = [] # list of filters, set by Diode::Server
		@remote = nil # AddrInfo set by Diode::Server - useful for logging the source IP
		@pattern = %r{^/} # set by Diode::Server - used by Diode::Static
	end

	# convenience method for extra info
	def [](k)
		@env[k]
	end

	# convenience method to store extra info on a request
	def []=(k,v)
		@env[k] = v
	end

	def url_decode(s)
		s.to_s.b.tr('+', ' ').gsub(/\%([A-Za-z0-9]{2})/) {[$1].pack("H2")}.force_encoding(Encoding::UTF_8)
	end

	# Extract fields by reading xml body in a strict format: any single root element, zero or more direct children only,
	# attributes are ignored. A hash is assembled using tagname of child as key and text of child as value.
	# the root may have an "id" attribute which will be treated like a field (named "id")
	# Anything else is ignored.
	# For example:
	#    <anything id="13"><firstname>john</firstname><age>25</age></anything>
	# becomes:
	#   Hash { "id" => 13, "firstname" => "john", "age" => 25 }
	def hash_xml(xml=nil)
		xml ||= @body.dup()
		pos = xml.index("<")  # find root open tag
		raise(Diode::RequestError.new(400, "invalid xml has no open tag")) if pos.nil?
		xml.slice!(0,pos+1) # discard anything before opening tag name
		pos = xml.index(">")
		rootelement = xml.slice!(0, pos) # we might have "root" or 'root recordid="12345"'
		xml.slice!(0,1) # remove the closing bracket of root element
		pos = rootelement.index(" ")
		if pos.nil?
			roottag = rootelement
		else
			roottag = rootelement.slice(0,pos)
			rest = /id="([^"]+)"/.match(rootelement[pos..-1])
			@fields["id"] = rest[1] unless rest.nil? or rest.size < 2
		end
		raise(Diode::RequestError.new(400, "invalid root open tag")) if roottag.nil? or /\A[a-z][a-z0-9]+\z/.match(roottag).nil?
		ending = xml.slice!(/\<\/#{roottag}\>.*$/m)
		raise(Diode::RequestError.new(400, "invalid root close tag")) if ending.nil? # discard everything after close
		# now we have a list of items like: \t<tagname>value</tagname>\n or maybe <tagname />
		until xml.empty?
			# find a field tagname
			pos = xml.index("<")
			break if pos.nil?
			xml.slice!(0,pos+1) # discard anything before opening tag name
			pos = xml.index(">")
			raise(Diode::RequestError.new(400, "invalid field open tag")) if pos.nil?
			if pos >= 2 and xml[pos-1] == "/"  # we have a self-closed tag eg. <first updated="true"/>
				tagelement = xml.slice!(0, pos+1)[0..-3] # tagname plus maybe attributes
				pos = tagelement.index(" ")
				tagname = (pos.nil?) ? tagelement : tagelement.slice(0,pos) # ignore attributes on fields
				raise(Diode::RequestError.new(400, "invalid field open tag")) if tagname.nil? or /\A[a-z][a-z0-9]+\z/.match(tagname).nil?
				@fields[tagname] = ""
			else # eg. <first updated="true" >some value </first>\n
				tagelement = xml.slice!(0, pos)
				pos = tagelement.index(" ")
				tagname = (pos.nil?) ? tagelement : tagelement.slice(0,pos) # ignore attributes on fields
				raise(Diode::RequestError.new(400, "invalid field open tag")) if tagname.nil? or /\A[a-z][a-z0-9]+\z/.match(tagname).nil?
				raise(Diode::RequestError.new(400, "duplicate field is not permitted")) if @fields.key?(tagname)
				xml.slice!(0,1) # remove closing bracket
				pos = xml.index("</#{tagname}>") # demand strict syntax for closing tag
				raise(Diode::RequestError.new(400, "no closing tag")) if pos.nil?
				raise(Diode::RequestError.new(400, "field value too long")) unless pos < 2048 # no field values 2048 bytes or larger
				value = xml.slice!(0,pos)
				@fields[tagname] = value
				xml.slice!(0, "</#{tagname}>".size)
			end
		end
	end

	# Break up a dataset into an array of records (chunks of xml that can be passed to hash_xml).
	# We insist on dataset/record names for tags.
	def dataset_records()
		xml=@body.dup()
		pos = xml.index("<dataset")  # find root open tag
		raise(Diode::RequestError.new(400, "invalid xml has no root tag")) if pos.nil?
		xml.slice!(0,pos+8) # discard anything before opening tag name
		return([]) if xml.strip.start_with?("/>")
		pos = xml.index("total=")
		xml.slice!(0,pos+7)  # remove up to number of records
		count = xml[/\d+/].to_i()
		return([]) if count.zero?
		xml.slice!(0, xml.index(">")+1) # remove rest of dataset open tag
		records = xml.split("</record>")
		records.pop() # remove the dataset close tag
		raise(Diode::RequestError.new(400, "records do not match total")) unless records.size == count
		records.collect!{ |r| r+"</record>" }
		records
	end

	# throws a SecurityError if there are any additional parameters found not in the list
	def no_extra_parameters(*list)
		kill = @params.keys()
		list.each { |param| kill.delete(param) }
		raise(Diode::SecurityError, "extra parameters #{kill}") unless kill.empty?
	end

	# throws a SecurityError if there are any additional fields found not in the list
	def no_extra_fields(*list)
		kill = @fields.keys()
		list.each { |k| kill.delete(k) }
		raise(Diode::SecurityError, "extra fields #{kill}") unless kill.empty?
	end

	def multipart_boundary()
		spec = "multipart/form-data; boundary="
		contentType = @headers["Content-Type"]
		if contentType.start_with?(spec)
			return(contentType.chomp.sub(spec, "").force_encoding("utf-8"))
		else
			return ""
		end
	end

	# parses a multipart/form-data POST body, using the given boundary separator
	def hash_multipartform(body, boundary)
		# cannot use split on possibly invalid UTF-8, but we can use partition()
		preamble, _, rest = body.partition("--"+boundary)
		raise("preamble before boundary preamble="+preamble.inspect()) unless preamble.empty?
		raise("no multipart ending found, expected --\\r\\n at end") unless rest.end_with?(boundary+"--\r\n")
		until rest == "--\r\n"
			part, _, rest = rest.partition("--"+boundary)
			spec, _, value = part.chomp.partition("\r\n\r\n")
			spec =~ /; name="([^"]+)"/m
			name = $1
			spec =~ /; filename="([^"]+)"/m
			filename = $1
			spec =~ /Content-Type: ([^"]+)/m
			mimetype = $1
			if mimetype.nil?
				@fields[name] = value.force_encoding("UTF-8")
			else
				@fields[name] = {"filename" => filename, "mimetype" => mimetype, "contents" => value}
			end
		end
		@fields
	end

	# return the request as a raw HTTP string
	def to_s()
		@headers["Content-Length"] = @body.bytes.size() unless @body.empty?
		msg = ["#{@method} #{@url} HTTP/1.1"]
		@headers.keys.each { |k|
			msg << "#{k}: #{@headers[k]}"
		}
		msg.join("\r\n") + "\r\n\r\n" + @body
	end

end
end

