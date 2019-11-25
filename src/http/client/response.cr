require "../client"
require "../common"
require "mime/media_type"

class HTTP::Client::Response
  getter version : String
  getter status : HTTP::Status
  getter status_message : String?
  getter headers : Headers
  @cookies : Cookies?

  def initialize(@status : HTTP::Status, @body : String? = nil, @headers : Headers = Headers.new, status_message = nil, @version = "HTTP/1.1")
    @status_message = status_message || @status.description

    if Response.mandatory_body?(@status)
      #@body = "" unless @body
    else
      if @body && (headers["Content-Length"]? != "0")
        raise ArgumentError.new("Status #{status.code} should not have a body")
      end
    end
  end

  def self.new(status_code : Int32, body : String? = nil, headers : Headers = Headers.new, status_message = nil, version = "HTTP/1.1")
    new(HTTP::Status.new(status_code), body, headers, status_message, version)
  end

  def body
    @body || ""
  end

  def body?
    @body
  end

  # Returns `true` if the response status code is between 200 and 299.
  def success?
    @status.success?
  end

  # Returns a convenience wrapper around querying and setting cookie related
  # headers, see `HTTP::Cookies`.
  def cookies
    @cookies ||= Cookies.from_headers(headers)
  end

  def keep_alive?
    HTTP.keep_alive?(self)
  end

  def content_type : String?
    mime_type.try &.media_type
  end

  # Convenience method to retrieve the HTTP status code.
  def status_code
    status.code
  end

  def charset : String?
    mime_type.try &.["charset"]?
  end

  def mime_type : MIME::MediaType?
    if content_type = headers["Content-Type"]?.presence
      MIME::MediaType.parse(content_type)
    end
  end

  def to_io(io, body_io = nil)
    io << @version << ' ' << @status.code << ' ' << @status_message << "\r\n"
    cookies = @cookies
    headers = cookies ? cookies.add_response_headers(@headers) : @headers
    HTTP.serialize_headers_and_body(io, headers, body_io, nil, @version)
  end

  # :nodoc:
  def consume_body_io(body_io : IO)
    @body = body_io.gets_to_end
  end

  def self.mandatory_body?(status : HTTP::Status) : Bool
    !(status.informational? || status.no_content? || status.not_modified?)
  end

  def self.supports_chunked?(version) : Bool
    version == "HTTP/1.1"
  end

  def self.from_io(io, ignore_body = false, decompress = true)
    from_io?(io, ignore_body, decompress) ||
      raise("Unexpected end of http request")
  end

  # Parses an `HTTP::Client::Response` from the given `IO`.
  # Might return `nil` if there's no data in the `IO`,
  # which probably means that the connection was closed.
  def self.from_io?(io, ignore_body = false, decompress = true)
    from_io?(io, ignore_body: ignore_body, decompress: decompress) do |response|
      if response
        response, body_io = response
        response.consume_body_io(body_io) if body_io
        return response
      else
        return nil
      end
    end
  end

  def self.from_io(io, ignore_body = false, decompress = true)
    from_io?(io, ignore_body, decompress) do |r|
      if r
        response, body_io = r
        yield response, body_io.not_nil!
      else
        raise("Unexpected end of http request")
      end
    end
  end

  # Parses an `HTTP::Client::Response` from the given `IO` and yields
  # it to the block. Might yield `nil` if there's no data in the `IO`,
  # which probably means that the connection was closed.
  def self.from_io?(io, ignore_body = false, decompress = true, &block)
    line = io.gets(4096, chomp: true)
    return yield nil unless line

    pieces = line.split(3)
    raise "Invalid HTTP response" if pieces.size < 2

    http_version = pieces[0]
    raise "Unsupported HTTP version: #{http_version}" unless HTTP::SUPPORTED_VERSIONS.includes?(http_version)

    status_code = pieces[1].to_i?

    unless status_code && 100 <= status_code < 1000
      raise "Invalid HTTP status code: #{pieces[1]}"
    end

    status = HTTP::Status.new(status_code)
    status_message = pieces[2]? ? pieces[2].chomp : ""

    body_type = HTTP::BodyType::OnDemand
    body_type = HTTP::BodyType::Mandatory if mandatory_body?(status)
    body_type = HTTP::BodyType::Prohibited if ignore_body

    HTTP.parse_headers_and_body(io, body_type: body_type, decompress: decompress) do |headers, body|
      return yield({new(status, nil, headers, status_message, http_version), body})
    end

    nil
  end
end
