module XML
  class SelectorParser
    def initialize(string : String)
      @reader = Char::Reader.new(string)
      @io = String::Builder.new(string.size)
    end

    DECENDANT_OPERATORS = {'>', '~', '+'}
    TYPE_SPECIFICATION_OPERATORS = {'#', '.', '[', ':'}

    def parse
      parse_selector

      @io.to_s
    end

    private def parse_selector
      parse_simple_selector_sequence("//")

      next_prefix = "/"

      loop do
        skip_whitespace

        break unless @reader.has_next?

        case @reader.current_char
        when '>'
          @reader.next_char
          skip_whitespace
          parse_simple_selector_sequence("/")
          next_prefix = "/"
        when '+'
          @reader.next_char
          skip_whitespace
          @io << "/following-sibling::*[1]/self::"
          parse_simple_selector_sequence("")
          next_prefix = ""
        when '~'
          @reader.next_char
          skip_whitespace
          #@io << "/following-sibling::*[count("
          @io << "/following-sibling::"
          parse_simple_selector_sequence("")
          #@io << ")]"
          next_prefix = "/"
        when ','
          break
        else
          parse_simple_selector_sequence("//")
        end
      end
    end

    private def parse_simple_selector_sequence(prefix)
      current_arguments = [] of String

      type_name = parse_simple_selector_sequence(current_arguments, prefix)

      @io << prefix
      if type_name
        @io << type_name
      else
        @io << "*"
      end

      unless current_arguments.empty?
        @io << '['
        current_arguments.join(" and ", @io)
        @io << ']'
      end
    end

    private def parse_simple_selector_sequence(current_arguments, prefix)
      first = true
      type_name = nil
      skip_whitespace

      loop do
      #   string = @io.to_s
      #   pp string, @reader.current_char
      #   @io = String::Builder.new << string
        case char = @reader.current_char
        when '#'
          @reader.next_char
          id = consume_identifier
          current_arguments << "@id = '#{id}'"
        when '.'
          @reader.next_char
          klass = consume_identifier
          current_arguments << "contains(concat(' ', normalize-space(@class), ' '), ' #{klass} ')"
        when '['
          parse_attribute(current_arguments)
        when ':'
          parse_pseudo(current_arguments)
        else
          if first
            type_name = parse_type_selector
          else
            break
          end
        end

        first = false
        break unless @reader.has_next?
      end

      raise "empty selector" if first

      type_name
    end

    private def parse_type_selector
      if @reader.current_char == '*'

        @reader.next_char
        char = @reader.current_char
        unless TYPE_SPECIFICATION_OPERATORS.includes?(char) || DECENDANT_OPERATORS.includes?(char) || char.whitespace? || char == Char::ZERO
          raise "invalid identifier starting with #{@reader.string.byte_slice(@reader.pos - 2, @reader.pos).inspect}"
        end

        return "*"
      else
        # TODO: case-insensitive type matching?
        namespace, name = consume_namespaced_identifier

        if namespace
          name = "#{namespace}:#{name}"
        end

        return name
      end
    end

    private def parse_attribute(current_arguments)
      start_pos = @reader.pos
      @reader.next_char
      skip_whitespace

      namespace, name = consume_namespaced_identifier
      if namespace
        name = "#{namespace}:#{name}"
      end

      skip_whitespace
      case comparator = @reader.current_char
      when ']'
        current_arguments << "@#{name}"
        @reader.next_char
        return
      when '='
        @reader.next_char
      when '~', '!', '|', '^', '$', '*'
        @reader.next_char
        if @reader.current_char != '='
          raise "invalid argument #{name}: #{@reader.string.byte_slice(start_pos, @reader.pos - start_pos).inspect}"
        end
        @reader.next_char
      else
        raise "invalid argument #{name}: #{@reader.string.byte_slice(start_pos, @reader.pos - start_pos).inspect}"
      end

      skip_whitespace

      case char = @reader.current_char
      when '"', '\''
        value = consume_string(char)
      else
        value = consume_attribute_value
      end

      if @reader.current_char != ']'
        raise "invalid argument #{name}: #{@reader.string.byte_slice(start_pos, @reader.pos - start_pos).inspect}"
      end

      @reader.next_char

      # value = escape_string(value)

      case comparator
      when '='
        current_arguments << "@#{name} = '#{value}'"
      when '~'
        current_arguments << "contains(concat(' ', @#{name}, ' '), ' #{value} ')"
      when '!'
        current_arguments << "@#{name} != '#{value}'"
      when '|'
        current_arguments << "@#{name} = '#{value}' or starts-with(@#{name}, concat('#{value}', '-'))"
      when '^'
        current_arguments << "starts-with(@#{name}, '#{value}')"
      when '$'
        current_arguments << "substring(@#{name}, string-length(@#{name}) - string-length('#{value}') + 1, string-length('#{value}')) = '#{value}'"
      when '*'
        current_arguments << "contains(@#{name}, '#{value}')"
      end
    end

    private def parse_pseudo(current_arguments)
      start_pos = @reader.pos
      @reader.next_char
      name = consume_identifier

      case name
      when "first"
        current_arguments << "position() = 1"
      when "first-child"
        current_arguments << "count(preceding-sibling::*) = 0"
      when "last"
        current_arguments << "position() = last()"
      when "last-child"
        current_arguments << "count(following-sibling::*) = 0"
      when "first-of-type"
        current_arguments << "position() = 1"
      when "last-of-type"
        current_arguments << "position() = last()"
      when "only-child"
        current_arguments << "count(preceding-sibling::*) = 0 and count(following-sibling::*) = 0"
      when "only-of-type"
        current_arguments << "last() = 1"
      when "empty"
        current_arguments << "not(node())"
      when "parent"
        current_arguments << "node()"
      when "root"
        current_arguments << "not(parent::*)"
      when "not"
        raise "pseudo class ':not' requires a parenthesized argument" unless @reader.current_char == '('
        @reader.next_char

        skip_whitespace

        case char = @reader.current_char
        when .ascii_letter?
          ns, type_name = consume_namespaced_identifier
          type_name = "#{ns}:#{type_name}" if ns
          current_arguments << "not(self::#{type_name})"
        else
          negated_arguments = [] of String

          parse_simple_selector_sequence(negated_arguments, "")

          current_arguments << "not(#{negated_arguments.join(" and ")})"
        end

        skip_whitespace

        raise "pseudo class ':not' requires a parenthesized argument" unless @reader.current_char == ')'
        @reader.next_char
      when "nth-child", "nth-of-type"
        raise "pseudo class ':#{name}' not implemented"
      else
        if @reader.current_char == '('
          @reader.next_char
          open_scopes = 1
          arguments_start_pos = @reader.pos
          while @reader.has_next?
            # FIXME: This is a naive implementation
            case @reader.current_char
            when ')'
              open_scopes -= 1

              if open_scopes == 0
                break
              end
            when '('
              open_scopes += 1
            end
            @reader.next_char
          end
          arguments = @reader.string.byte_slice(arguments_start_pos, @reader.pos - arguments_start_pos)

          if arguments.empty?
            current_arguments << "#{name}(.)"
          else
            current_arguments << "#{name}(., #{arguments})"
          end

          @reader.next_char
        else
          current_arguments << "#{name}(.)"
        end
      end
    end

    private def skip_whitespace
      is_whitespace = @reader.current_char.whitespace?

      while @reader.has_next?
        if @reader.current_char.whitespace?
          @reader.next_char
        else
          break
        end
      end

      is_whitespace
    end

    private def consume_namespaced_identifier
      namespace = nil
      expect_namspace = true

      if @reader.current_char == '|'
        @reader.next_char
        expect_namspace = false
      end

      name = consume_identifier

      pos = @reader.pos
      if expect_namspace && @reader.current_char == '|'
        @reader.next_char
        if @reader.current_char.ascii_letter?
          namespace, name = name, consume_identifier
        else
          @reader.pos = pos
        end
      end

      return namespace, name
    end

    private def consume_identifier
      start_pos = @reader.pos

      String.build do |io|
        char = @reader.current_char
        raise "unexpected identifier character #{@reader.current_char.inspect}" unless char.ascii_letter?
        @reader.next_char

        while @reader.has_next?
          char = @reader.current_char

          case char
          when .alphanumeric?, '_', '-'
            @reader.next_char
          when '\\'
            io << @reader.string.byte_slice(start_pos, @reader.pos - start_pos)
            @reader.next_char

            start_pos = @reader.pos

            raise "invalid identifier escape" unless @reader.has_next?
            @reader.next_char
          else
            break
          end
        end

        io << @reader.string.byte_slice(start_pos, @reader.pos - start_pos)
      end
    end

    private def consume_identifier_escaped
      start_pos = @reader.pos

      char = @reader.current_char
      raise "unexpected identifier character #{@reader.current_char.inspect}" unless char.ascii_letter?
      @reader.next_char

      while @reader.has_next?
        char = @reader.current_char

        case char
        when .alphanumeric?, '_', '-'
          @reader.next_char
        when '\\'
          @reader.next_char

          raise "invalid identifier escape" unless @reader.has_next?
          @reader.next_char
        else
          break
        end
      end

      @reader.string.byte_slice(start_pos, @reader.pos - start_pos)
    end

    private def consume_attribute_value
      start_pos = @reader.pos

      while @reader.has_next?
        char = @reader.current_char

        case char
        when ']'
          break
        else
          @reader.next_char
        end
      end

      @reader.string.byte_slice(start_pos, @reader.pos - start_pos)
    end

    private def consume_string(delimiter)

      char = @reader.current_char
      raise "unexpected string character #{@reader.current_char.inspect}" unless char == delimiter

      escaped = false

      @reader.next_char
      start_pos = @reader.pos

      while @reader.has_next?
        char = @reader.current_char

        case char
        when delimiter
          unless escaped
            @reader.next_char
            return @reader.string.byte_slice(start_pos, @reader.pos - 1 - start_pos)
          end
        end

        @reader.next_char
      end

      raise "unterminated string"
    end
  end
end
