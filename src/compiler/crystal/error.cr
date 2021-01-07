module Crystal
  # Base class for all errors in the compiler.
  class Error < ::Exception
  end

  class LocationError < Error
    ALL_ERRORS = Set(String | Nil).new
    getter location : ErrorLocation

    def self.new(message, location : Location, size = nil)
      new(message, location: ErrorLocation.new(location, size || 0))
    end

    def initialize(message, @location : ErrorLocation)
      super(message)

      ALL_ERRORS << message if message
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "message", @message
        json.field "location", @location
      end
    end

    def_equals_and_hash @message, @location

    def at(location : Location, size = 0)
      @location = ErrorLocation.new(location, size: size)

      self
    end

    def inspect(io : IO)
      io << "#<Crystal::Error("
      @message.inspect(io)
      io << ", location="
      @location.inspect(io)
      io << ")>"
    end
  end
end

require "./error/*"

# Spec.after_suite do
#   Crystal::LocationError::ALL_ERRORS.each do |e|
#     puts e.inspect
#   end
# end
