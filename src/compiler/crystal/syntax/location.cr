# A location of an `ASTnode`, including its filename, line number and column number.
class Crystal::Location
  include Comparable(self)

  getter line_number
  getter column_number
  getter filename

  def self.new(filename : String, line_number : Int32, column_number : Int32)
    new(::Path.new(filename), line_number, column_number)
  end

  def initialize(@filename : ::Path | VirtualFile | Nil, @line_number : Int32, @column_number : Int32)
  end

  # Returns the directory name of this location's filename. If
  # the filename is a VirtualFile, this is invoked on its expanded
  # location.
  def dirname : ::Path?
    original_filename.try &.parent
  end

  # Returns the Location whose filename is a ::Path, not a VirtualFile,
  # traversing virtual file expanded locations.
  def original_location
    case filename = @filename
    when ::Path
      self
    when VirtualFile
      filename.expanded_location.try &.original_location
    when Nil
      nil
    end
  end

  # Returns the filename of the `original_location`
  def original_filename
    original_location.try &.filename.as?(::Path)
  end

  def relative_filename
    if (filename = self.filename).is_a?(::Path)
      filename.relative_to(Dir.current)
    end
  end

  def between?(min, max)
    return false unless min && max

    min <= self && self <= max
  end

  def inspect(io : IO) : Nil
    to_s(io)
  end

  def to_s(io : IO) : Nil
    io << filename << ':' << line_number << ':' << column_number
  end

  def pretty_print(pp)
    pp.text to_s
  end

  def <=>(other)
    self_file = @filename
    other_file = other.filename
    if self_file.is_a?(::Path) && other_file.is_a?(::Path) && self_file == other_file
      {@line_number, @column_number} <=> {other.line_number, other.column_number}
    else
      nil
    end
  end
end
