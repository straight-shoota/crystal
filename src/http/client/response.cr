require "../client"
require "../common"

class HTTP::Client::Response
  getter version : String
  getter status_code : Int32
  getter status_message : String
  getter headers : Headers
  getter! body_io : IO
  @cookies : Cookies?

  def initialize(@status_code, @body : String? = nil, @headers : Headers = Headers.new, status_message = nil, @version = "HTTP/1.1", @body_io = nil)
    @status_message = status_message || HTTP.default_status_message_for(@status_code)

    if Response.mandatory_body?(@status_code)
      @body = "" unless @body || @body_io
    else
      if (@body || @body_io) && (headers["Content-Length"]? != "0")
        raise ArgumentError.new("Status #{status_code} should not have a body")
      end
    end
  end

  def body
    @body || ""
  end

  def body?
    @body
  end

  # Returns `true` if the response status code is between 200 and 299.
  def success?
    (200..299).includes?(status_code)
  end

  # Returns a convenience wrapper around querying and setting cookie related
  # headers, see `HTTP::Cookies`.
  def cookies
    @cookies ||= Cookies.from_headers(headers)
  end

  def keep_alive?
    HTTP.keep_alive?(self)
  end

  def content_type
    process_content_type_header.content_type
  end

  def charset
    process_content_type_header.charset
  end

  @computed_content_type_header : ComputedContentTypeHeader?

  private def process_content_type_header
    @computed_content_type_header ||= begin
      HTTP.content_type_and_charset(headers)
    end
  end

  def to_io(io)
    io << @version << ' ' << @status_code << ' ' << @status_message << "\r\n"
    cookies = @cookies
    headers = cookies ? cookies.add_response_headers(@headers) : @headers
    HTTP.serialize_headers_and_body(io, headers, @body, @body_io, @version)
  end

  # :nodoc:
  def consume_body_io
    if io = @body_io
      @body = io.gets_to_end
      @body_io = nil
    end
  end

  def self.mandatory_body?(status_code) : Bool
    !(status_code / 100 == 1 || status_code == 204 || status_code == 304)
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
        response.consume_body_io
        return response
      else
        return nil
      end
    end
  end

  def self.from_io(io, ignore_body = false, decompress = true)
    from_io?(io, ignore_body, decompress) do |response|
      if response
        yield response
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

    status_message = pieces[2]? ? pieces[2].chomp : ""

    body_type = HTTP::BodyType::OnDemand
    body_type = HTTP::BodyType::Mandatory if mandatory_body?(status_code)
    body_type = HTTP::BodyType::Prohibited if ignore_body

    headers_and_body = HTTP.parse_headers_and_body(io, body_type: body_type, decompress: decompress)

    if headers_and_body
      headers, body = headers_and_body
      yield new status_code, nil, headers, status_message, http_version, body
    end
  end
end
