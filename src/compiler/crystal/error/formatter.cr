require "colorize"
require "./loader"

class Crystal::ErrorFormatter
  def self.run(io, error, base_dir, colorize = nil)
    formatter = new(io)
    formatter.base_dir = base_dir
    if colorize.is_a?(Bool)
      formatter.colorize = colorize
    end
    load_sources(error)
    formatter.format(error)
  end

  property base_dir : ::Path = ::Path.new(Dir.current)
  @colorize : Colorize::Object(Nil)

  def initialize(@io : IO)
    @colorize = Colorize::Object.new(nil)
    self.colorize = @io.tty?
  end

  def colorize=(flag : Bool)
    @colorize = @colorize.toggle(flag)
  end

  def colorize? : Bool
    @colorize.@enabled
  end

  def format(error : Crystal::Error)
    print_error(error)
  end

  def print_error(error)
    if error.is_a?(Crystal::LocationError)
      print_location(error)
    end

    print_error_label
    print_error_message(error, bold: true)
  end

  def print_location(error)
    colorize(fore: :dark_gray) do
      print_location_name(error.location)
    end
    @io.puts

    if filename = error.location.filename.as?(VirtualFile)
      print_macro_source_location(filename)
    end

    print_source(error.location)
  end

  def print_location_name(location)
    case filename = location.filename
    in VirtualFile
      @io << filename
    in String
      @io << relative_filename(filename)
    in Nil
      @io << "<unknown>"
    end

    @io << ":" << location.line_number
    @io << ":" << location.column_number
  end

  def print_macro_source_location(virtual_file)
    location = virtual_file.macro.location
    @io << "defined in "
    colorize(fore: :dark_gray) do
      print_location_name(location)
    end
    @io.puts

    if (filename = location.try(&.filename)).is_a?(VirtualFile)
      print_macro_source_location(filename)
    end
  end

  def relative_filename(filename)
    return unless filename
    ::Path.new(filename).relative_to(base_dir)
  end

  def print_source(location)
    line = location.source
    return unless line

    no_indent_line = line.lstrip
    indent = line.size - no_indent_line.size

    if location
      offset = colorize(fore: :dark_gray) do
        print_line_number(location.line_number)
      end
      if colorize?
        highlight_source_location(no_indent_line, location.column_number - indent, location.size)
      else
        @io << no_indent_line
      end
      @io.puts

      colorize(fore: :blue) do
        print_location_indicator(offset, location.column_number - indent, location.size)
      end
    else
      @io << no_indent_line
    end

    @io.puts
  end

  def highlight_source_location(line, start, size)
    start -= 1
    @io << line[0, start]?
    colorize(bold: true) do
      @io << line[start, size]?
    end
    @io << line[(start + size)..]?
  end

  def print_line_number(line_number)
    str = " #{line_number} | "
    @io << str
    str.size
  end

  def print_location_indicator(offset, column_number, size)
    @io << (" " * (offset + column_number - 1))
    @io << '^'
    if size > 0
      @io << ("~" * (size - 1))
    end
  end

  def print_error_label
    if colorize?
      colorize(fore: :white, back: :red, bold: true) do
        @io << " Error "
      end
      @io << " "
    else
      @io << "Error: "
    end
  end

  def print_error_label
    colorize(fore: :red, bold: true) do
      @io << "Error: "
    end
  end

  def print_error_message(error, bold = false)
    if message = error.message
      colorize(bold: bold) do
        @io << message
      end
    end
    @io.puts
  end

  private def colorize(*, fore = nil, back = nil, bold = nil)
    colorize = @colorize
    if fore
      colorize = colorize.fore(fore)
    end
    if back
      colorize = colorize.back(back)
    end
    if bold
      colorize = colorize.bold
    end

    colorize.surround(@io) do
      yield
    end
  end
end
