class Status
  @@operationalStatus = :online
  @@validStates = [:online, :quiet, :offline]

  def serve(request)
    request.method == "GET" ? get(request) : post(request)
  end

  def get(request)
    h = { "operationalStatus": @@operationalStatus.to_s() }
    h["category"] = request["category"] if request.params["extra"].to_s == "true"
    Diode::Response.new(200, JSON.dump(h), {"Cache-Control" => "no-cache"})
  end

  def post(request)
    return badRequest() unless request.headers["Content-Type"].downcase() == "application/json"
    payload = JSON.parse(request.body)
    newState = payload["state"].to_sym
    unless @@validStates.include?(newState)
      p :badstate, payload, request # so we can see what the payload contains
      return badRequest()
    end
    @@operationalStatus = newState
    Diode::Response.new(200, JSON.dump({"status": "updated"}))
  end

  def badRequest()
    Diode::Response.new(400, JSON.dump({"status": "bad request"}))
  end

end
