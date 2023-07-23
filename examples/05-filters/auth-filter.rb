class AuthFilter

  def serve(request)
    # do pre-processing with the request
    unless request.headers["Authorization"] == "Bearer token-123="  # pretend we verified the token properly
      redirect = Diode::Response.new(402, JSON.dump({"status": "not authenticated"}))
      remoteIP = request.remote.ip_address # the source of the request is available
      puts("[.] intercepting an unauthenticated request from ip=#{remoteIP}")  # pretend we logged the failed access attempt
      return redirect
    end

    # invoke the next filter
    response = (request.filters.shift).serve(request)
    # Warning!! if the parentheses around the shift are omitted, the next filter will NOT be removed from the list beforehand

    # do post-processing with the response
    response.headers["Cache-Control"] = "no-store"
    return response
  end

end
