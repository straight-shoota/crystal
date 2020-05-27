class Crystal::Program
  def undefined_global_variable(node, similar_name)
    notes = [] of String
    if similar_name
      notes << "Did you mean '#{similar_name}'?"
    end

    notes << undefined_variable_message("global", node.name)

    node.raise "can't infer the type of global variable '#{node.name}'", notes: notes
  end

  def undefined_class_variable(node, owner, similar_name)
    notes = [] of String
    if similar_name
      notes << "Did you mean '#{similar_name}'?"
    end
    notes << undefined_variable_message("class", node.name)

    node.raise "can't infer the type of class variable '#{node.name}' of #{owner.devirtualize}", notes: notes
  end

  def undefined_instance_variable(node, owner, similar_name)
    notes = [] of String
    if similar_name
      notes << "Did you mean '#{similar_name}'?"
    end
    notes << undefined_variable_message("instance", node.name)
    node.raise "can't infer the type of instance variable '#{node.name}' of #{owner.devirtualize}", notes: notes
  end

  def undefined_variable_message(kind, example_name)
    <<-MSG
    The type of a #{kind} variable, if not declared explicitly with
    `#{example_name} : Type`, is inferred from assignments to it across
    the whole program.

    The assignments must look like this:

      1. `#{example_name} = 1` (or other literals), inferred to the literal's type
      2. `#{example_name} = Type.new`, type is inferred to be Type
      3. `#{example_name} = Type.method`, where `method` has a return type
         annotation, type is inferred from it
      4. `#{example_name} = arg`, with 'arg' being a method argument with a
         type restriction 'Type', type is inferred to be Type
      5. `#{example_name} = arg`, with 'arg' being a method argument with a
         default value, type is inferred using rules 1, 2 and 3 from it
      6. `#{example_name} = uninitialized Type`, type is inferred to be Type
      7. `#{example_name} = LibSome.func`, and `LibSome` is a `lib`, type
         is inferred from that fun.
      8. `LibSome.func(out #{example_name})`, and `LibSome` is a `lib`, type
         is inferred from that fun argument.

    Other assignments have no effect on its type.
    MSG
  end
end
