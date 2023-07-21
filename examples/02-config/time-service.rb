# time-service.rb
class TimeService

  def initialize(timezone, city)
    @tz = timezone
    @city = city
  end

  def serve(request)
    h = { "name": "Time Service", "location": @city } # use the servlet-specific property @city
    h["time"] = DateTime.now.new_offset(@tz).to_time.rfc2822
    h["stage"] = request[:environment] # use an application-wide property - shortcut to request.env[:environment]
    body = JSON.dump(h)
    Diode::Response.new(200, body)
  end

end
