require "ecr/macros"
require "html"
require "uri"
require "mime"

# A simple handler that lists directories and serves files under a given public directory.
class HTTP::StaticFileHandler
  include HTTP::Handler

  @public_dir : Path

  # Creates a handler that will serve files in the given *public_dir*, after
  # expanding it (using `File#expand_path`).
  #
  # If *fallthrough* is `false`, this handler does not call next handler when
  # request method is neither GET or HEAD, then serves `405 Method Not Allowed`.
  # Otherwise, it calls next handler.
  #
  # If *directory_listing* is `false`, directory listing is disabled. This means that
  # paths matching directories are ignored and next handler is called.
  def initialize(public_dir : String, *, @fallthrough : Bool = true, @directory_listing : Bool = true)
    @public_dir = Path.new(public_dir).expand
  end

  def call(context)
    unless {"GET", "HEAD"}.includes?(context.request.method)
      if @fallthrough
        call_next(context)
      else
        context.response.status = :method_not_allowed
        context.response.headers.add("Allow", "GET, HEAD")
      end
      return
    end

    raw_path = context.request.path
    is_dir_path = raw_path.ends_with?("/")
    request_path = URI.decode(raw_path)

    expanded_path = expand_request_path(request_path)
    unless expanded_path
      context.response.respond_with_status(:bad_request)
      return
    end

    local_info = local_path_info(expanded_path)
    unless local_info
      # Redirect `foo` to `/foo`
      if request_path != expanded_path.to_s
        redirect_to context, expanded_path
        return
      else
        # Path not found
        call_next(context)
        return
      end
    end

    # Redirect `/foo` to `/foo/` if local_path is a directory
    if local_info.directory? && !is_dir_path
      redirect_to context, expanded_path.join("")
      return
    end

    # Redirect `foo` to `/foo`
    if request_path != expanded_path.to_s
      redirect_to context, expanded_path
      return
    end

    if local_info.file?
      serve_file(context, local_info, expanded_path)
    elsif local_info.directory? && @directory_listing
      # Pass on directory if @directory_listing is false

      serve_directory(context, local_info, expanded_path)
    else
      # Can't handle other file types
      call_next(context)
    end
  end

  private def expand_request_path(request_path : String) : Path?
    # File path cannot contains '\0' (NUL) because all filesystem I know
    # don't accept '\0' character as file name.
    return if request_path.includes? '\0'

    request_path = Path.posix(request_path)

    # Ensure the request path always starts with "/"
    request_path.expand("/")
  end

  # :nodoc:
  #
  # This struct encapsulates information about a local file.
  # It consists of the local path, file type and modification time.
  record LocalInfo, path : Path, type : File::Type, last_modified : Time

  # Translates a fully expanded request_path into a local path and information
  # about the file.
  # Returns `nil` if the file does not exist.
  private def local_path_info(request_path) : LocalInfo
    local_path = local_path(request_path)
    file_info = File.info?(local_path)
    return nil unless file_info

    LocalInfo.new local_path, file_info.type, file_info.modification_time
  end

  private def local_path(request_path)
    @public_dir.join(request_path.to_kind(Path::Kind.native))
  end

  private def redirect_to(context, url)
    context.response.status = :found

    url = URI.encode(url.to_s)
    context.response.headers.add "Location", url
  end

  private def serve_directory(context : HTTP::Server::Context, local_info : LocalInfo, request_path : Path)
    context.response.content_type = "text/html"

    DirectoryListing.new(request_path.to_s, path.to_s).to_s(context.response)
  end

  private def serve_file(context : HTTP::Server::Context, local_info : LocalInfo, request_path : Path))
    last_modified = local_info.modification_time
    add_cache_headers(context.response.headers, last_modified)

    if cache_request?(context, last_modified)
      context.response.status = :not_modified
      return
    end

    context.response.content_type = MIME.from_filename(local_path.to_s, "application/octet-stream")
    context.response.content_length = File.size(local_path)

    File.open(local_path) do |file|
      IO.copy(file, context.response)
    end
  end

  private def add_cache_headers(response_headers : HTTP::Headers, last_modified : Time) : Nil
    response_headers["Etag"] = etag(last_modified)
    response_headers["Last-Modified"] = HTTP.format_time(last_modified)
  end

  private def cache_request?(context : HTTP::Server::Context, last_modified : Time) : Bool
    # According to RFC 7232:
    # A recipient must ignore If-Modified-Since if the request contains an If-None-Match header field
    if if_none_match = context.request.if_none_match
      match = {"*", context.response.headers["Etag"]}
      if_none_match.any? { |etag| match.includes?(etag) }
    elsif if_modified_since = context.request.headers["If-Modified-Since"]?
      header_time = HTTP.parse_time(if_modified_since)
      # File mtime probably has a higher resolution than the header value.
      # An exact comparison might be slightly off, so we add 1s padding.
      # Static files should generally not be modified in subsecond intervals, so this is perfectly safe.
      # This might be replaced by a more sophisticated time comparison when it becomes available.
      !!(header_time && last_modified <= header_time + 1.second)
    else
      false
    end
  end

  private def etag(modification_time)
    %{W/"#{modification_time.to_unix}"}
  end

  record DirectoryListing, request_path : String, path : String do
    def each_entry
      Dir.each_child(path) do |entry|
        yield entry
      end
    end

    ECR.def_to_s "#{__DIR__}/static_file_handler.html"
  end
end
