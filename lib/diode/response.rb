require 'time'

module Diode

class Response

	STATUS = {
		200 => "OK",
		400 => "Bad Request",
		403 => "Forbidden",
		404 => "Not Found",
		405 => "Method Not Allowed"
	}

	DEFAULT_HEADERS = {
		"Content-Type" => "application/json",
		"Date" => Time.now.rfc2822(),
		"Cache-Control" => "no-store",
		"Server" => "Diode/1.0",
		"Connection" => "Keep-Alive"
	}

	# returns the html for a few status codes
	def self.standard(code)
		raise("code #{code} is not supported") unless STATUS.key?(code)
		message = STATUS[code]
		body = "<html><head><title>#{message}</title></head><body><h1>#{code} - #{message}</h1></body></html>\n"
		h = DEFAULT_HEADERS.merge({"Content-Type" => "text/html"})
		new(code, body, h)
	end

	attr_accessor(:code, :body, :headers)

	def initialize(code, body="", headers={})
		@code = code.to_i()
		@body = body
		@headers = DEFAULT_HEADERS.merge(headers)
	end

	# return the response as a raw HTTP string
	def to_s()
		@headers["Content-Length"] = @body.bytes.size() unless @body.empty?
		msg = ["HTTP/1.1 #{@code} #{STATUS[@code]}"]
		@headers.keys.each { |k|
			msg << "#{k}: #{@headers[k]}"
		}
		msg.join("\r\n") + "\r\n\r\n" + @body
	end

end
end

