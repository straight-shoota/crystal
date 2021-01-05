class Crystal::ErrorFormatter
  def self.load_sources(error, file_cache = Hash(String, Array(String)).new)
    load_source(error, file_cache)
  end

  def self.load_source(error : LocationError, file_cache)
    if error.location.source.nil? && (filename = error.location.filename.as?(String))
      lines = file_cache.fetch(filename) do
        file_cache[filename] = read_file(filename) || break
      end

      return unless lines

      error.location.source = lines[error.location.line_number - 1]?
    end
  end

  def self.read_file(filename)
    return unless File.readable?(filename) && File.file?(filename)

    begin
      File.read_lines(filename)
    rescue IO::Error
      # ignore error
    end
  end
end
