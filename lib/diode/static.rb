require 'pathname'

module Diode

class Static

  def initialize(docRoot=".", guardian=nil)
    @root = Pathname.new(Pathname.new(docRoot).cleanpath()).realpath()
    raise("Cannot serve static files from path #{@root}") unless @root.directory? and @root.readable?
    @guardian = guardian
  end

  def serve(request)
    return Diode::Response.standard(405) unless request.method == "GET"
    unless @guardian.nil?
      securityResponse = @guardian.call(request)
      unless securityResponse.nil? or securityResponse == 200
        return securityResponse if securityResponse.is_a?(Diode::Response)
        return Diode::Response.standard(securityResponse) if [400,403,404,405].include?(securityResponse)
        raise("result of guardian block must be a Diode::Response or one of 400,403,404,405 to deny or else nil to allow") # guardian should log details
      end
    end
    path = Pathname.new(request.path).cleanpath().to_s()
    filepath = Pathname.new(File.expand_path(@root.to_s() + path))
    filepath = Pathname.new(File.expand_path("index.html", filepath)) if filepath.directory?
    return Diode::Response.standard(404) unless filepath.exist?
    mimetype = @@mimetypes[filepath.extname[1..-1]] || "application/octet-stream"
    return Diode::Response.new(200, IO.read(filepath.to_s).b, {"Content-Type"=>mimetype, "Cache-Control" => "no-cache"})
  end

  @@mimetypes = {
    "avi"   => "video/x-msvideo",
    "avif"  => "image/avif",
    "css"   => "text/css",
    "gif"   => "image/gif",
    "htm"   => "text/html",
    "html"  => "text/html",
    "ico"   => "image/x-icon",
    "jpeg"  => "image/jpeg",
    "jpg"   => "image/jpeg",
    "js"    => "application/javascript",
    "json"  => "application/json",
    "mov"   => "video/quicktime",
    "mp4"   => "video/mp4",
    "mpe"   => "video/mpeg",
    "mpeg"  => "video/mpeg",
    "mpg"   => "video/mpeg",
    "otf"   => "font/otf",
    "pdf"   => "application/pdf",
    "png"   => "image/png",
    "qt"    => "video/quicktime",
    "rb"    => "text/plain",
    "svg"   => "image/svg+xml",
    "tif"   => "image/tiff",
    "tiff"  => "image/tiff",
    "ttc"   => "font/collection",
    "ttf"   => "font/ttf",
    "txt"   => "text/plain",
    "webm"  => "video/webm",
    "webp"  => "image/webp",
    "woff"  => "font/woff",
    "woff2" => "font/woff2",
    "xhtml" => "text/html",
    "xml"   => "text/xml",
  }

  def self.mimetypes
    @@mimetypes
  end

end
end
