# An HTTP Client.
#
# ### One-shot usage
#
# Without a block, an `HTTP::Client::Response` is returned and the response's body
# is available as a `String` by invoking `HTTP::Client::Response#body`.
#
# ```
# require "http/client"
#
# response = HTTP::Client.get "http://www.example.com"
# response.status_code      # => 200
# response.body.lines.first # => "<!doctype html>"
# ```
#
# ### Streaming
#
# With a block, an `HTTP::Client::Response` body is returned and the response's body
# is available as an `IO` by invoking `HTTP::Client::Response#body_io`.
#
# ```
# require "http/client"
#
# HTTP::Client.get("http://www.example.com") do |response|
#   response.status_code  # => 200
#   response.body_io.gets # => "<!doctype html>"
# end
# ```
#
# ### Reusing a connection
#
# Similar to the above cases, but creating an instance of an `HTTP::Client`.
#
# ```
# require "http/client"
#
# client = HTTP::Client.new "www.example.com"
# response = client.get "/"
# response.status_code      # => 200
# response.body.lines.first # => "<!doctype html>"
# client.close
# ```
#
# ### Compression
#
# If `compress` isn't set to `false`, and no `Accept-Encoding` header is explicitly specified,
# an HTTP::Client will add an `"Accept-Encoding": "gzip, deflate"` header, and automatically decompress
# the response body/body_io.
#
# ### Encoding
#
# If a response has a `Content-Type` header with a charset, that charset is set as the encoding
# of the returned IO (or used for creating a String for the body). Invalid bytes in the given encoding
# are silently ignored when reading text content.
class HTTP::Client
  # The set of possible valid body types.
  alias BodyType = String | Bytes | IO | Nil

  # If this client uses TLS, returns its `OpenSSL::SSL::Context::Client`, raises otherwise.
  #
  # Changes made after the initial request will have no effect.
  #
  # ```
  # client = HTTP::Client.new "www.example.com", tls: true
  # client.tls # => #<OpenSSL::SSL::Context::Client ...>
  # ```
  {% if flag?(:without_openssl) %}
    getter! tls : Nil
  {% else %}
    getter! tls : OpenSSL::SSL::Context::Client
  {% end %}

  # Whether automatic compression/decompression is enabled.
  property? compress : Bool = true

  getter transport : Transport

  class_getter default_transport do
    Transport::Default.new
  end

  getter base_uri : URI

  # Creates a new HTTP client with the given *host*, *port* and *tls*
  # configurations. If no port is given, the default one will
  # be used depending on the *tls* arguments: 80 for if *tls* is `false`,
  # 443 if *tls* is truthy. If *tls* is `true` a new `OpenSSL::SSL::Context::Client` will
  # be used, else the given one. In any case the active context can be accessed through `tls`.
  {% if flag?(:without_openssl) %}
    def initialize(@transport : Transport? = self.class.default_transport, tls : Bool = false, @base_uri : URI = URI.new)
      if tls
        raise "HTTP::Client TLS is disabled because `-D without_openssl` was passed at compile time"
      end

      @tls = nil
    end

    def self.new(host : String, port = nil, tls : Bool = false)
      port = (port || (tls ? 443 : 80)).to_i

      new(Transport::TCPTransport.new(host, port), tls, base_uri: URI.new((port == 443 ? "https" : "http"), host, port))
    end
  {% else %}
    def initialize(@transport : Transport? = self.class.default_transport, tls : Bool | OpenSSL::SSL::Context::Client = false, @base_uri : URI = URI.new)
      @tls = case tls
              when true
                OpenSSL::SSL::Context::Client.new
              when OpenSSL::SSL::Context::Client
                tls
              when false
                nil
              end
    end

    def self.new(host : String, port = nil, tls : Bool | OpenSSL::SSL::Context::Client = false)
      port = (port || (tls ? 443 : 80)).to_i

      new(Transport::TCPTransport.new(host, port), tls, base_uri: URI.new((port == 443 ? "https" : "http"), host, port))
    end
  {% end %}

  # Creates a new HTTP client from a URI. Parses the *host*, *port*,
  # and *tls* configuration from the URI provided. Port defaults to
  # 80 if not specified unless using the https protocol, which defaults
  # to port 443 and sets tls to `true`.
  #
  # ```
  # uri = URI.parse("https://secure.example.com")
  # client = HTTP::Client.new(uri)
  #
  # client.tls? # => #<OpenSSL::SSL::Context::Client>
  # client.get("/")
  # ```
  # This constructor will *ignore* any path or query segments in the URI
  # as those will need to be passed to the client when a request is made.
  #
  # If *tls* is given it will be used, if not a new TLS context will be created.
  # If *tls* is given and *uri* is a HTTP URI, `ArgumentError` is raised.
  # In any case the active context can be accessed through `tls`.
  #
  # This constructor will raise an exception if any scheme but HTTP or HTTPS
  # is used.
  def self.new(uri : URI, tls = nil)
    tls = tls_flag(uri, tls)
    host = validate_host(uri)
    new(host, uri.port, tls)
  end

  # Creates a new HTTP client from a URI, yields it to the block and closes the
  # client afterwards. Parses the *host*, *port*, and *tls* configuration from
  # the URI provided. Port defaults to 80 if not specified unless using the
  # https protocol, which defaults to port 443 and sets tls to `true`.
  #
  # ```
  # uri = URI.parse("https://secure.example.com")
  # HTTP::Client.new(uri) do |client|
  #   client.tls? # => #<OpenSSL::SSL::Context::Client>
  #   client.get("/")
  # end
  # ```
  # This constructor will *ignore* any path or query segments in the URI
  # as those will need to be passed to the client when a request is made.
  #
  # If *tls* is given it will be used, if not a new TLS context will be created.
  # If *tls* is given and *uri* is a HTTP URI, `ArgumentError` is raised.
  # In any case the active context can be accessed through `tls`.
  #
  # This constructor will raise an exception if any scheme but HTTP or HTTPS
  # is used.
  def self.new(uri : URI, tls = nil)
    tls = tls_flag(uri, tls)
    host = validate_host(uri)
    client = new(host, uri.port, tls)
    begin
      yield client
    ensure
      client.close
    end
  end

  # Creates a new HTTP client, yields it to the block, and closes
  # the client afterwards.
  #
  # ```
  # HTTP::Client.new("www.example.com") do |client|
  #   client.get "/"
  # end
  # ```
  def self.new(host : String, port = nil, tls = false)
    client = new(host, port, tls)
    begin
      yield client
    ensure
      client.close
    end
  end

  # Configures this client to perform basic authentication in every
  # request.
  def basic_auth(username, password)
    header = "Basic #{Base64.strict_encode("#{username}:#{password}")}"
    before_request do |request|
      request.headers["Authorization"] = header
    end
  end

  # Adds a callback to execute before each request. This is usually
  # used to set an authorization header. Any number of callbacks
  # can be added.
  #
  #
  # ```
  # client = HTTP::Client.new("www.example.com")
  # client.before_request do |request|
  #   request.headers["Authorization"] = "XYZ123"
  # end
  # client.get "/"
  # ```
  def before_request(&callback : HTTP::Request ->)
    before_request = @before_request ||= [] of (HTTP::Request ->)
    before_request << callback
  end

  {% for method in %w(get post put head delete patch options) %}
    # Executes a {{method.id.upcase}} request.
    # The response will have its body as a `String`, accessed via `HTTP::Client::Response#body`.
    #
    # ```
    # client = HTTP::Client.new("www.example.com")
    # response = client.{{method.id}}("/", headers: HTTP::Headers{"User-Agent" => "AwesomeApp"}, body: "Hello!")
    # response.body #=> "..."
    # ```
    def {{method.id}}(path, headers : HTTP::Headers? = nil, body : BodyType = nil) : HTTP::Client::Response
      exec {{method.upcase}}, path, headers, body
    end

    # Executes a {{method.id.upcase}} request and yields the response to the block.
    # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
    #
    # ```
    # client = HTTP::Client.new("www.example.com")
    # client.{{method.id}}("/", headers: HTTP::Headers{"User-Agent" => "AwesomeApp"}, body: "Hello!") do |response|
    #   response.body_io.gets #=> "..."
    # end
    # ```
    def {{method.id}}(path, headers : HTTP::Headers? = nil, body : BodyType = nil)
      exec {{method.upcase}}, path, headers, body do |response|
        yield response
      end
    end

    # Executes a {{method.id.upcase}} request.
    # The response will have its body as a `String`, accessed via `HTTP::Client::Response#body`.
    #
    # ```
    # response = HTTP::Client.{{method.id}}("/", headers: HTTP::Headers{"User-Agent" => "AwesomeApp"}, body: "Hello!")
    # response.body #=> "..."
    # ```
    def self.{{method.id}}(url : String | URI, headers : HTTP::Headers? = nil, body : BodyType = nil, tls = nil) : HTTP::Client::Response
      exec {{method.upcase}}, url, headers, body, tls
    end

    # Executes a {{method.id.upcase}} request and yields the response to the block.
    # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
    #
    # ```
    # HTTP::Client.{{method.id}}("/", headers: HTTP::Headers{"User-Agent" => "AwesomeApp"}, body: "Hello!") do |response|
    #   response.body_io.gets #=> "..."
    # end
    # ```
    def self.{{method.id}}(url : String | URI, headers : HTTP::Headers? = nil, body : BodyType = nil, tls = nil)
      exec {{method.upcase}}, url, headers, body, tls do |response|
        yield response
      end
    end

    # Executes a {{method.id.upcase}} request with form data and returns a `Response`. The "Content-Type" header is set
    # to "application/x-www-form-urlencoded".
    #
    # ```
    # client = HTTP::Client.new "www.example.com"
    # response = client.{{method.id}} "/", form: "foo=bar"
    # ```
    def {{method.id}}(path, headers : HTTP::Headers? = nil, *, form : String | IO) : HTTP::Client::Response
      request = new_request({{method.upcase}}, path, headers, form)
      request.headers["Content-Type"] = "application/x-www-form-urlencoded"
      exec request
    end

    # Executes a {{method.id.upcase}} request with form data and yields the response to the block.
    # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
    # The "Content-Type" header is set to "application/x-www-form-urlencoded".
    #
    # ```
    # client = HTTP::Client.new "www.example.com"
    # client.{{method.id}}("/", form: "foo=bar") do |response|
    #   response.body_io.gets
    # end
    # ```
    def {{method.id}}(path, headers : HTTP::Headers? = nil, *, form : String | IO)
      request = new_request({{method.upcase}}, path, headers, form)
      request.headers["Content-Type"] = "application/x-www-form-urlencoded"
      exec(request) do |response|
        yield response
      end
    end

    # Executes a {{method.id.upcase}} request with form data and returns a `Response`. The "Content-Type" header is set
    # to "application/x-www-form-urlencoded".
    #
    # ```
    # client = HTTP::Client.new "www.example.com"
    # response = client.{{method.id}} "/", form: {"foo" => "bar"}
    # ```
    def {{method.id}}(path, headers : HTTP::Headers? = nil, *, form : Hash(String, String) | NamedTuple) : HTTP::Client::Response
      body = HTTP::Params.encode(form)
      {{method.id}} path, form: body, headers: headers
    end

    # Executes a {{method.id.upcase}} request with form data and yields the response to the block.
    # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
    # The "Content-type" header is set to "application/x-www-form-urlencoded".
    #
    # ```
    # client = HTTP::Client.new "www.example.com"
    # client.{{method.id}}("/", form: {"foo" => "bar"}) do |response|
    #   response.body_io.gets
    # end
    # ```
    def {{method.id}}(path, headers : HTTP::Headers? = nil, *, form : Hash(String, String) | NamedTuple)
      body = HTTP::Params.encode(form)
      {{method.id}}(path, form: body, headers: headers) do |response|
        yield response
      end
    end

    # Executes a {{method.id.upcase}} request with form data and returns a `Response`. The "Content-Type" header is set
    # to "application/x-www-form-urlencoded".
    #
    # ```
    # response = HTTP::Client.{{method.id}} "http://www.example.com", form: "foo=bar"
    # ```
    def self.{{method.id}}(url, headers : HTTP::Headers? = nil, tls = nil, *, form : String | IO | Hash) : HTTP::Client::Response
      exec(url, tls) do |client, path|
        client.{{method.id}}(path, form: form, headers: headers)
      end
    end

    # Executes a {{method.id.upcase}} request with form data and yields the response to the block.
    # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
    # The "Content-Type" header is set to "application/x-www-form-urlencoded".
    #
    # ```
    # HTTP::Client.{{method.id}}("http://www.example.com", form: "foo=bar") do |response|
    #   response.body_io.gets
    # end
    # ```
    def self.{{method.id}}(url, headers : HTTP::Headers? = nil, tls = nil, *, form : String | IO | Hash)
      exec(url, tls) do |client, path|
        client.{{method.id}}(path, form: form, headers: headers) do |response|
          yield response
        end
      end
    end
  {% end %}

  # Executes a request.
  # The response will have its body as a `String`, accessed via `HTTP::Client::Response#body`.
  #
  # ```
  # client = HTTP::Client.new "www.example.com"
  # response = client.exec HTTP::Request.new("GET", "/")
  # response.body # => "..."
  # ```
  def exec(request : HTTP::Request, uri = @base_uri) : HTTP::Client::Response
    exec_internal(uri, request)
  end

  private def exec_internal(uri, request)
    response = exec_internal_single(uri, request)
    return handle_response(response) if response

    # Server probably closed the connection, so retry one
    close
    request.body.try &.rewind
    response = exec_internal_single(uri, request)
    return handle_response(response) if response

    raise "Unexpected end of http response"
  end

  private def exec_internal_single(uri, request)
    decompress, io = send_request(uri, request)

    HTTP::Client::Response.from_io?(io, ignore_body: request.ignore_body?, decompress: decompress)
  end

  private def handle_response(response)
    close unless response.keep_alive?
    response
  end

  # Executes a request request and yields an `HTTP::Client::Response` to the block.
  # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
  #
  # ```
  # client = HTTP::Client.new "www.example.com"
  # client.exec(HTTP::Request.new("GET", "/")) do |response|
  #   response.body_io.gets # => "..."
  # end
  # ```
  def exec(request : HTTP::Request, uri = @base_uri, &block)
    exec_internal(uri, request) do |response|
      yield response
    end
  end

  private def exec_internal(uri, request, &block : Response -> T) : T forall T
    exec_internal_single(uri, request) do |response|
      if response
        return handle_response(response) { yield response }
      end

      # Server probably closed the connection, so retry once
      close
      request.body.try &.rewind
      exec_internal_single(uri, request) do |response|
        if response
          return handle_response(response) do
            yield response
          end
        end
      end
    end
    raise "Unexpected end of http response"
  end

  private def exec_internal_single(uri, request)
    decompress, io = send_request(uri, request)
    HTTP::Client::Response.from_io?(io, ignore_body: request.ignore_body?, decompress: decompress) do |response|
      yield response
    end
  end

  private def handle_response(response)
    value = yield
    response.body_io?.try &.close
    close unless response.keep_alive?
    value
  end

  private def send_request(uri, request)
    decompress = set_defaults request
    run_before_request_callbacks(request)
    io = connect(uri, request)
    request.to_io(io)
    io.flush

    {decompress, io}
  end

  private def set_defaults(request)
    request.headers["User-Agent"] ||= "Crystal"
    {% if flag?(:without_zlib) %}
      false
    {% else %}
      if compress? && !request.headers.has_key?("Accept-Encoding")
        request.headers["Accept-Encoding"] = "gzip, deflate"
        true
      else
        false
      end
    {% end %}
  end

  private def run_before_request_callbacks(request)
    @before_request.try &.each &.call(request)
  end

  # Executes a request.
  # The response will have its body as a `String`, accessed via `HTTP::Client::Response#body`.
  #
  # ```
  # client = HTTP::Client.new "www.example.com"
  # response = client.exec "GET", "/"
  # response.body # => "..."
  # ```
  def exec(method : String, path, headers : HTTP::Headers? = nil, body : BodyType = nil) : HTTP::Client::Response
    exec new_request(method, path, headers, body), relative_uri(path)
  end

  # Executes a request.
  # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
  #
  # ```
  # client = HTTP::Client.new "www.example.com"
  # client.exec("GET", "/") do |response|
  #   response.body_io.gets # => "..."
  # end
  # ```
  def exec(method : String, path, headers : HTTP::Headers? = nil, body : BodyType = nil)
    exec(new_request(method, path, headers, body), relative_uri(path)) do |response|
      yield response
    end
  end

  # Executes a request.
  # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
  #
  # ```
  # response = HTTP::Client.exec "GET", "http://www.example.com"
  # response.body # => "..."
  # ```
  def self.exec(method, url : String | URI, headers : HTTP::Headers? = nil, body : BodyType = nil, tls = nil) : HTTP::Client::Response
    exec(url, tls) do |client, path|
      client.exec method, path, headers, body
    end
  end

  # Executes a request.
  # The response will have its body as an `IO` accessed via `HTTP::Client::Response#body_io`.
  #
  # ```
  # HTTP::Client.exec("GET", "http://www.example.com") do |response|
  #   response.body_io.gets # => "..."
  # end
  # ```
  def self.exec(method, url : String | URI, headers : HTTP::Headers? = nil, body : BodyType = nil, tls = nil)
    exec(url, tls) do |client, path|
      client.exec(method, path, headers, body) do |response|
        yield response
      end
    end
  end

  # Closes this client. If used again, a new connection will be opened.
  def close
  end

  private def new_request(method, path, headers, body : BodyType)
    uri = URI.parse(path)

    if uri.scheme || uri.host
      path = uri.full_path
      host_header = host_header(uri)
    else
      host_header = host_header(@base_uri)
    end

    HTTP::Request.new(method, path, headers, body).tap do |request|
      request.headers["Host"] ||= host_header
    end
  end

  private def connect(uri, request)
    io = transport.connect(uri, request)

    {% if !flag?(:without_openssl) %}
      if (tls = @tls) && uri.scheme == "https"
        io = OpenSSL::SSL::Socket::Client.new(io, context: tls, sync_close: true, hostname: @base_uri.host)
      end
    {% end %}

    io
  end

  private def host_header(uri)
    host = uri.host
    port = uri.port

    raise "Missing host" if !host || host.empty?

    if port && ((uri.scheme == "https" && port != 443) || (uri.scheme == "http" && port != 80))
      "#{host}:#{port}"
    else
      host
    end
  end

  private def self.exec(string : String, tls = nil)
    uri = URI.parse(string)

    unless uri.scheme && uri.host
      # Assume http if no scheme and host are specified
      uri = URI.parse("http://#{string}")
    end

    exec(uri, tls) do |client, path|
      yield client, path
    end
  end

  private def relative_uri(path)
    uri = URI.parse(path)

    return uri if uri.scheme || uri.host

    uri.scheme ||= @base_uri.scheme
    uri.host ||= @base_uri.host
    uri.port ||= @base_uri.port

    uri
  end

  {% if flag?(:without_openssl) %}
    protected def self.tls_flag(uri, context : Nil)
      scheme = uri.scheme
      case scheme
      when nil
        raise ArgumentError.new("Missing scheme: #{uri}")
      when "http"
        false
      when "https"
        true
      else
        raise ArgumentError.new "Unsupported scheme: #{scheme}"
      end
    end
  {% else %}
    protected def self.tls_flag(uri, context : OpenSSL::SSL::Context::Client?)
      scheme = uri.scheme
      case {scheme, context}
      when {nil, _}
        raise ArgumentError.new("Missing scheme: #{uri}")
      when {"http", nil}
        false
      when {"http", OpenSSL::SSL::Context::Client}
        raise ArgumentError.new("TLS context given for HTTP URI")
      when {"https", nil}
        true
      when {"https", OpenSSL::SSL::Context::Client}
        context
      else
        raise ArgumentError.new "Unsupported scheme: #{scheme}"
      end
    end
  {% end %}

  protected def self.validate_host(uri)
    host = uri.host
    return host if host && !host.empty?

    raise ArgumentError.new %(Request URI must have host (URI is: #{uri}))
  end

  private def self.exec(uri : URI, tls = nil)
    tls = tls_flag(uri, tls)
    host = validate_host(uri)

    port = uri.port
    path = uri.full_path
    user = uri.user
    password = uri.password

    HTTP::Client.new(host, port, tls) do |client|
      if user && password
        client.basic_auth(user, password)
      end
      yield client, path
    end
  end
end

{% if !flag?(:without_openssl) %}
  require "openssl"
{% end %}
require "socket"
require "uri"
require "base64"
require "./client/response"
require "./client/transport"
require "./common"
