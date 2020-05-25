module Crystal
  # Base class for all errors in the compiler.
  class Error < ::Exception
    def to_json(json : ::JSON::Builder)
      json.object do
        json.field "message", message
        json.field "class", self.class.to_s
      end
    end
  end

  # Base class for all errors caused by compiling invalid user code.
  class CodeError < Error
    getter location : ErrorLocation?
    property source : String?
    property frames = [] of ErrorFrame
    getter notes : Array(String)

    def self.new(message : String?, location : Location, notes : Array(String) = [] of String, cause : Exception? = nil, size = 0)
      new(message, nil, notes, cause).at(location, size: size)
    end

    def self.new(message : String?, node : ASTNode, notes : Array(String) = [] of String, cause : Exception? = nil)
      new(message, nil, notes, cause).at(node)
    end

    def initialize(message : String?, @location : ErrorLocation? = nil, @notes : Array(String) = [] of String, cause : Exception? = nil)
      super(message, cause)
    end

    def initialize(@cause : Exception, @location : ErrorLocation? = nil)
      @notes = [] of String
    end

    def at(node : ASTNode)
      at(node.error_location, node.error_size)
    end

    def at(@location : Nil, size = 0)
      @source = nil
      self
    end

    def at(location : Location, size = 0)
      @location = ErrorLocation.new(location, size: size)

      virtual_file = location.try &.filename.as?(VirtualFile)
      if virtual_file
        self.source = virtual_file.source.lines[location.line_number - 1]?
      end

      self
    end

    def source(@source : String?)
      self
    end

    def inspect(io : IO) : Nil
      io << "#<" << self.class.name
      io << ':' << message

      if location = @location
        io << '@'
        location.inspect(io)
      end
      if source = @source
        io << "::"
        source.inspect(io)
      end
      if notes = @notes
        notes.each do |note|
          io << " notes="
          note.inspect(io)
        end
      end
      if cause = @cause
        io << " cause="
        cause.inspect(io)
      end

      io << '>'
    end
  end

  class ErrorFrame
    enum FrameType
      REQUIRE
      DEF
      TYPE
      MACRO
      INSTANTIATING
      OTHER
    end

    getter frame_type : FrameType
    getter location : ErrorLocation?
    getter name : String?

    property source : String?

    def self.def(node : Call, name : String) : self
      new(:def, node, name)
    end

    def self.def(node : Def, name : String) : self
      new(:def, node, name)
    end

    def self.macro(node : ASTNode, name : String) : self
      new(:macro, node, name)
    end

    def self.type(node : Generic, name : String) : self
      new(:type, node, name)
    end

    def self.require(node : Crystal::Require, name : String) : self
      new(:require, node, name)
    end

    def self.instantiating(pointer : ProcPointer, name : String) : self
      new(:instantiating, nil, name).at(pointer.location)
    end

    def self.new(message : String, location : ErrorLocation? = nil) : self
      new(:other, location, message)
    end

    def self.new(message : String, node : ASTNode)
      new(message, nil).at(node)
    end

    def self.new(frame_type : FrameType, node : ASTNode, name : String? = nil)
      new(frame_type, nil, name).at(node)
    end

    def initialize(@frame_type : FrameType, @location : ErrorLocation?, @name : String? = nil)
    end

    def at(node : ASTNode)
      at(node.error_location, node.error_size)
    end

    def at(@location : Nil, size = 0)
      @source = nil
      self
    end

    def at(location : Location, size = 0)
      @location = ErrorLocation.new(location, size: size)

      virtual_file = location.try &.filename.as?(VirtualFile)
      if virtual_file
        self.source = virtual_file.source.lines[location.line_number - 1]?
      end

      self
    end

    def source(@source : String?)
      self
    end

    def_equals_and_hash @frame_type, @location, @name
  end

  class SyntaxError < CodeError
  end

  class SemanticError < CodeError
  end

  class NilableError < SemanticError
    def self.new(nil_reason : NilReason, cause)
      msg = case nil_reason.reason
            when .used_before_initialized?
              "Instance variable '#{nil_reason.name}' was used before it was initialized in one of the 'initialize' methods, rendering it nilable"
            when .used_self_before_initialized?
              "'self' was used before initializing instance variable '#{nil_reason.name}', rendering it nilable"
            when .initialized_in_rescue?
              "Instance variable '#{nil_reason.name}' is initialized inside a begin-rescue, so it can potentially be left uninitialized if an exception is raised and rescued"
            end
      new(msg, nil, cause: cause, nil_reason: nil_reason.reason)
    end

    getter nil_reason

    def initialize(message, location, cause, @nil_reason : NilReason::ReasonType)
      super(message, location, cause: cause)
    end
  end

  class MethodTraceError < SemanticError
    getter owner

    def initialize(@owner : Type?, @trace : Array(ASTNode))
      super(nil, nil)
    end

    def has_trace?
      @trace.any?(&.location)
    end
  end

  class FrozenTypeError < SemanticError
  end

  class UndefinedMethodError < SemanticError
    getter method_name
    getter target
    getter could_be_local_variable

    def self.new(method_name : String, target : String?, node : ASTNode, could_be_local_variable : Bool = false, notes = [] of String)
      new(method_name, target, nil, could_be_local_variable, notes).at(node)
    end

    def initialize(@method_name : String, @target : String?, location : ErrorLocation? = nil, @could_be_local_variable : Bool = false, notes = [] of String)
      message = String.build do |io|
        io << "undefined "
        if could_be_local_variable
          io << "local variable or "
        end
        io << "method "
        io << "'" << method_name << "'"
        io << " for " << target
      end
      super message, location, notes
    end
  end

  class UndefinedMacroMethodError < SemanticError
  end

  class MacroRaiseError < SemanticError
  end
end
