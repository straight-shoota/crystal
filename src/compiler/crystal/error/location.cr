require "compiler/crystal/syntax/location"

module Crystal
  record ErrorLocation,
    location : Location,
    size : Int32 = 0,
    source : String? = nil do

    UNKNOWN = ErrorLocation.new(nil, 0, 0, 0)

    def self.new(filename, line_number, column_number, size, source = nil)
      new(Location.new(filename, line_number, column_number), size, source)
    end

    def self.new(location : Location, size = 0)
      if (virtual_file = location.filename).is_a?(VirtualFile)
        source = virtual_file.source.lines[location.line_number - 1]?
      end

      new(location, size, source)
    end

    def source=(@source : String?)
    end

    def virtual?
      location.filename.is_a?(VirtualFile)
    end

    def unknown?
      location.filename.nil?
    end

    delegate filename, line_number, column_number, to: @location

    def_equals_and_hash @location, @size

    def inspect(io : IO) : Nil
      io << "ErrorLocation("
      case filename = location.filename
      in VirtualFile
        io << "macro "
      in String
        io << filename
      in Nil
        io << "<unknown>"
      end
      @name.inspect_unquoted(io)
      io << ':' << @location.line_number << ':' << @location.column_number

      unless @size.zero?
        io << '+' << @size
      end

      io << ')'
    end

    def to_s(io : IO) : Nil
      @location.to_s(io)
    end

    def to_json(json)
      json.object do
        # json.field "name", @location.name
        json.field "line", @location.line_number
        json.field "column", @location.column_number
        if @size > 0
          json.field "size", @size
        end
        if virtual?
          json.field "virtual", true
        end
      end
    end
  end
end
