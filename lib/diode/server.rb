require 'async/scheduler'
require 'time'
require 'json'
require 'diode/request'
require 'diode/response'
require 'diode/static'

Fiber.set_scheduler(Async::Scheduler.new())

module Diode

class Server

  attr_accessor(:env, :filters)

  def initialize(port, routing=[], env={})
    @port = port.to_i()
    @routing = routing
    @env = env
    @filters = [self] # list of filters that requests pass through before dispatch to a servlet
  end

  def start()
    validate_routing()
    Fiber.schedule do
      server = TCPServer.new(@port)
      Signal.trap("INT") {
        server.stop()
      }
      loop do
        Fiber.schedule do
          client = server.accept
          rawRequest = read_request(client)
          begin
            request = Diode::Request.new(rawRequest)
            request.remote = client.io.remote_address # decorate with request source address
            request.env = @env.dup() # copy environment into request
            request.filters = @filters.dup
            response = (request.filters.shift).serve(request)
          rescue Diode::SecurityError, Diode::RequestError => e
            response = Diode::Response.standard(e.code)
          end
          complete(client, response)
          client.close_write()
        end
      end
    end
  rescue
    # ignore errors such as bad file decriptor on shutdown
  end

  # check routing table is sane
  def validate_routing()
    newRouting = []
    @routing.each { |pattern, klass, *args|
      raise("invalid pattern='#{pattern}' in routing table") unless pattern.is_a?(Regexp)
      begin
        servletKlass = klass.split("::").inject(Object) { |o,c| o.const_get(c) }
        newRouting << [pattern, servletKlass, args]
      rescue NameError
        raise("unrecognised class #{klass} found in routing table")
      end
    }
    @routing = newRouting # optimised so we can instantiate the servlet quickly
  end

  def read_request(client)
    message = client.recv(2048000)
    unless message.empty?
      unless message.index("Content-Length: ").nil?  # handle large messages such as file uploads
        start = message.index("Content-Length: ")
        stop = message.index("\r\n", start)
        len = message[start..stop].chomp.sub("Content-Length: ","").to_i
        bodyStart = message.index("\r\n\r\n") + 3 # up to end of 4 bytes
        byteStart = message[0..bodyStart].bytes.size
        remaining = len - (message.bytes.size - byteStart)  # we have already read some of the content
        while remaining > 0
          chunk = client.recv(2048000)
          message = message + chunk
          remaining = remaining - chunk.bytes.size
        end
      end
    end
    message
  end

  # handle a new request connection
  def serve(request) # keep signature consistent with filters and servlets
    pattern, klass, args = @routing.find{ |pattern, klass, args|
      not pattern.match(request.path).nil?
    }
    raise(Diode::RequestError.new(404)) if klass.nil?
    servlet = klass.new(*args)
    request.pattern = pattern  # provide the mount pattern to the request, useful for Diode::Static
    response = servlet.serve(request)
  end

  def complete(conn, response)  # send the response, make sure its all sent
    begin
      http = response.to_s
      total = http.bytes.size()
      sent = 0
      while sent < total
        msgsize = conn.send(http.byteslice(sent..-1), 0)
        sent = sent + msgsize
      end
    rescue Errno::EPIPE # ignore, we're finished anyway
    end
  end

  def url_encode(s)
    s.b.gsub(/([^ a-zA-Z0-9_.-]+)/) { |m|
      '%' + m.unpack('H2' * m.bytesize).join('%').upcase
    }.tr(' ', '+').force_encoding(Encoding::UTF_8) # url-encoded message
  end

end
end
