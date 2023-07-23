require 'pathname'

class Static

  def initialize(docRoot=".")
    @root = Pathname.new(Pathname.new(docRoot).cleanpath()).realpath()
    raise("Cannot serve static files from path #{@root}") unless @root.directory? and @root.readable?
  end

  def serve(request)
    return Diode::Response.new(405, "Method not allowed", {"Content-type" => "text/plain"}) unless request.method == "GET"
    path = Pathname.new(request.path).cleanpath.sub(request.pattern, "")  # remove the leading portion matching the mount pattern
    filepath = Pathname.new(File.expand_path(path, @root))
    filepath = Pathname.new(File.expand_path("index.html", filepath)) if filepath.directory?
    return Diode::Response.new(404, "<html><body>File not found</body></html>", {"Content-type" => "text/html"}) unless filepath.exist?
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
