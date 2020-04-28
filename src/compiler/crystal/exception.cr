require "./util"
require "colorize"

module Crystal
  abstract class Exception < ::Exception
    property? color = false
    property? error_trace = false

    @filename : ::Path | VirtualFile | Nil

    def to_s(io) : Nil
      to_s_with_source(nil, io)
    end

    def warning=(warning)
      @warning = !!warning
    end

    abstract def to_s_with_source(source, io)

    def to_json(json : JSON::Builder)
      json.array do
        to_json_single(json)
      end
    end

    def true_filename(filename = @filename) : ::Path
      case filename
      when VirtualFile
        loc = filename.expanded_location
        if loc
          true_filename loc.filename
        else
          ::Path.new
        end
      when ::Path
        filename
      when Nil
        ::Path.new
      else
        # TODO: Remove this branch when strict exhaustive case is enabled
        raise "unreachable"
      end
    end

    def to_s_with_source(source)
      String.build do |io|
        to_s_with_source source, io
      end
    end

    def relative_filename(filename)
      filename = filename.as?(::Path) || return
      ::Path.new(filename).relative_to(Dir.current)
    end

    def colorize(obj)
      obj.colorize.toggle(@color)
    end

    def with_color
      Colorize.with.toggle(@color)
    end

    def replace_leading_tabs_with_spaces(line)
      found_non_space = false
      line.gsub do |char|
        if found_non_space
          char
        elsif char == '\t'
          ' '
        elsif char.ascii_whitespace?
          char
        else
          found_non_space = true
          char
        end
      end
    end
  end

  class LocationlessException < Exception
    def to_s_with_source(source, io)
      io << @message
    end

    def append_to_s(source, io)
      io << @message
    end

    def has_location?
      false
    end

    def deepest_error_message
      @message
    end

    def to_json_single(json)
      json.object do
        json.field "message", @message
      end
    end
  end

  module ErrorFormat
    MACRO_LINES_TO_SHOW               = 3
    OFFSET_FROM_LINE_NUMBER_DECORATOR = 6

    def error_body(source, default_message) : String | Nil
      case filename = @filename
      when VirtualFile
        return format_macro_error(filename)
      when ::Path
        if File.file?(filename)
          return format_error_from_file(filename)
        end
      when Nil
        # go on
      end

      return format_error(source) if source
      default_message
    end

    def line_number_decorator(line_number)
      " #{line_number} | "
    end

    def append_error_indicator(io, offset, column_number, size = 0)
      size ||= 0
      io << '\n'
      io << (" " * (offset + column_number - 1))
      with_color.green.bold.surround(io) do
        io << '^'
        if size > 0
          io << ("-" * (size - 1))
        end
      end
    end

    def filename_row_col_message(filename, line_number, column_number)
      String.build do |io|
        io << colorize("#{relative_filename(filename)}:#{line_number}:#{column_number}").underline
      end
    end

    # TODO: Path
    def format_error(filename : String, lines, line_number, column_number, size = 0)
      format_error(::Path.new(filename), lines, line_number, column_number, size)
    end

    def format_error(filename : VirtualFile | ::Path | Nil, lines, line_number, column_number, size = 0)
      return "#{relative_filename(filename)}" unless line_number

      unless line = lines[line_number - 1]?
        return filename_row_col_message(filename, line_number, column_number)
      end

      String.build do |io|
        case filename
        when ::Path
          io << filename_row_col_message(filename, line_number, column_number)
        when VirtualFile
          io << "macro '" << colorize("#{filename.macro.name}").underline << '\''
        when Nil
          io << "unknown location"
        end

        decorator = line_number_decorator(line_number)
        lstripped_line = line.lstrip
        space_delta = line.chars.size - lstripped_line.chars.size

        io << "\n\n"
        io << colorize(decorator).dim << colorize(lstripped_line.chomp).bold
        append_error_indicator(io, decorator.chars.size, column_number - space_delta, size || 0)
      end
    end

    def format_error_from_file(filename : ::Path)
      lines = File.read_lines(filename)
      formatted_error = format_error(
        filename: @filename,
        lines: lines,
        line_number: @line_number,
        column_number: @column_number,
        size: @size
      )
      "In #{formatted_error}"
    end

    def format_macro_error(virtual_file : VirtualFile)
      show_where_macro_expanded = !(@error_trace && self.responds_to?(:error_trace=))
      String.build do |io|
        io << "There was a problem expanding macro '#{virtual_file.macro.name}'"
        io << "\n\n"
        if show_where_macro_expanded
          append_where_macro_expanded(io, virtual_file)
          io << '\n'
        end
        io << "Called macro defined in "
        append_macro_definition_location(io, virtual_file)
        io << "\n\n"
        io << "Which expanded to:"
        io << "\n\n"
        append_expanded_macro(io, virtual_file.source)
      end
    end

    def remaining(lines : Array(String))
      String.build do |io|
        return if lines.empty?
        io << "\n\n"
        io << lines.skip_while(&.blank?).join('\n')
      end
    end

    # TODO: Path
    def source_lines(filename : String)
      source_lines(::Path.new(filename))
    end

    def source_lines(filename : VirtualFile | ::Path | Nil)
      case filename
      when Nil
        nil
      when ::Path
        if File.file? filename
          File.read_lines(filename)
        else
          nil
        end
      when VirtualFile
        filename.source.lines
      end
    end

    def append_macro_definition_location(io, filename : VirtualFile)
      macro_source = filename.macro.location
      source_filename = macro_source.try &.filename
      line_number = macro_source.try &.line_number
      column_number = macro_source.try &.column_number

      case source_filename
      when ::Path, String
        # TODO: Path
        io << colorize("#{relative_filename(source_filename)}:#{line_number}:#{column_number}").underline
      when VirtualFile
        io << "macro '" << colorize("#{source_filename.macro.name}").underline << '\''
      when Nil
        "unknown location"
      end

      lines = source_lines(source_filename)

      if lines && line_number
        io << "\n\n"
        io << colorize(line_number_decorator(line_number)).dim
        io << lines[line_number - 1].lstrip
      end
    end

    def minimize_indentation(source)
      min_leading_white_space =
        source.min_of? { |line| leading_white_space(line) } || 0

      if min_leading_white_space > 0
        source = source.map do |line|
          replace_leading_tabs_with_spaces(line).lchop(" " * min_leading_white_space)
        end
      end

      {source, min_leading_white_space}
    end

    private def leading_white_space(line)
      match = line.match(/^(\s+)\S/)
      return 0 unless match

      spaces = match[1]?
      return 0 unless spaces

      spaces.size
    end

    def append_expanded_macro(io, source)
      line_number = @line_number
      if @error_trace || !line_number
        source, _ = minimize_indentation(source.lines)
        io << Crystal.with_line_numbers(source, line_number, @color)
      else
        from_index = [0, line_number - MACRO_LINES_TO_SHOW].max
        source_slice = source.lines[from_index...line_number]
        source_slice, spaces_removed = minimize_indentation(source_slice)

        io << Crystal.with_line_numbers(source_slice, line_number, @color, line_number_start = from_index + 1)
        offset = OFFSET_FROM_LINE_NUMBER_DECORATOR + line_number.to_s.chars.size - spaces_removed
        append_error_indicator(io, offset, @column_number, @size)
      end
    end

    def append_where_macro_expanded(io, filename : VirtualFile)
      expanded_source = filename.expanded_location
      return unless expanded_source
      source_filename = expanded_source.filename
      lines = source_lines(source_filename)
      return unless lines

      io << "Code in " << format_error(
        filename: source_filename,
        lines: lines,
        line_number: expanded_source.line_number,
        column_number: expanded_source.column_number,
      )
    end
  end
end
