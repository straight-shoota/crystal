module Crystal::Conversions
  def self.numeric_argument(node, var, visitor, unaliased_type, expected_type, actual_type)
    convert_call_name = "to_#{unaliased_type.kind}!"
    convert_call = Call.new(var, convert_call_name).at(node)

    begin
      convert_call.accept visitor
    rescue ex : Crystal::Error
      if ex.is_a?(UndefinedMethodError) && ex.method_name == convert_call_name
        return nil
      end

      raise Crystal::SemanticError.new("converting from #{actual_type} to #{expected_type} by invoking '#{convert_call_name}'", node, cause: ex)
    end

    if convert_call.type? != unaliased_type
      node.raise "invoked '#{convert_call_name}' to convert from #{actual_type} to #{expected_type}, but got #{convert_call.type?}"
    end

    convert_call
  end

  def self.to_unsafe(node, target, visitor, actual_type, expected_type)
    unsafe_call = try_to_unsafe(target, visitor) do |ex|
      unless to_unsafe_lookup_failed?(ex)
        ex.frames << ErrorFrame.new(:other, node)
        raise ex
      end
      return nil
    end
    if unsafe_call.type? != expected_type
      node.raise "invoked 'to_unsafe' to convert from #{actual_type} to #{expected_type}, but got #{unsafe_call.type?}"
    end
    unsafe_call
  end

  def self.try_to_unsafe(target, visitor)
    unsafe_call = Call.new(target, "to_unsafe").at(target)
    begin
      unsafe_call.accept visitor
    rescue ex : SemanticError
      yield ex
    end
    unsafe_call
  end

  def self.to_unsafe_lookup_failed?(ex)
    ex.is_a?(UndefinedMethodError) && ex.method_name == "to_unsafe"
  end
end
