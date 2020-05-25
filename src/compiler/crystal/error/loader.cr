class Crystal::ErrorFormatter
  # def load_sources
  #   self.class.load_sources(@list)
  # end

  def self.load_sources(error : CodeError, file_cache : Hash(String, Array(String)) = Hash(String, Array(String)).new)
    load_source(error, file_cache)

    error.frames.each do |frame|
      next if frame.source
      load_source(frame, file_cache)
    end
  end

  def self.load_source(frame : ErrorFrame | CodeError, file_cache)
    location = frame.location
    return unless location

    case filename = location.filename
    when VirtualFile
      frame.source = extract_line(filename.source.lines, location)
    when String
      lines = file_cache[filename]?
      unless lines
        lines = read_file(filename)
        if lines
          file_cache[filename] = lines
        else
          return
        end
      end

      frame.source = extract_line(lines, location)
    when Nil
      # do nothing
    end
  end

  private def self.extract_line(lines, location)
    lines[location.line_number - 1]?
  end

  def self.read_file(filename)
    return unless File.readable?(filename) && File.file?(filename)

    File.read_lines(filename)
  end
end
