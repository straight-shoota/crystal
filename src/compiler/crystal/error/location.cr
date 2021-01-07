require "compiler/crystal/syntax/location"

module Crystal
  struct ErrorLocation
    getter size : Int32
    property source : String?

    UNKNOWN = ErrorLocation.new(nil, 0, 0, 0)

    def self.new(filename, line_number, column_number, size = 0, source = nil)
      new(Location.new(filename, line_number, column_number), size, source)
    end

    def initialize(@location : Location, @size : Int32 = 0, @source : String? = nil)
    end

    def source=(@source : String?)
    end

    def virtual?
      @location.filename.is_a?(VirtualFile)
    end

    def unknown?
      @location.filename.nil?
    end

    delegate filename, original_filename, line_number, column_number, to: @location

    def_equals_and_hash @location, @size

    def inspect(io : IO) : Nil
      io << "ErrorLocation("
      @location.to_s(io)

      unless @size.zero?
        io << '+' << @size
      end

      if filename = @location.filename.as?(VirtualFile)
        io << ", virtual: "
        filename.inspect(io)
      end

      io << ", source: "
      if source = @source
        source.inspect(io)
      else
        io << "nil"
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
