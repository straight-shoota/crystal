require "./lexer"

class JSON::Parser
  property max_nesting = 512

  def initialize(string_or_io : String | IO)
    @lexer = JSON::Lexer.new(string_or_io)
    @nest = 0
  end

  def parse : Any
    json = parse_value
    next_token
    check :EOF
    json
  end

  private def parse_value
    next_token
    consume_value
  end

  private def consume_value
    case token.kind
    when .int?
      Any.new(token.int_value)
    when .float?
      Any.new(token.float_value)
    when .string?
      Any.new(token.string_value)
    when .null?
      Any.new(nil)
    when .true?
      Any.new(true)
    when .false?
      Any.new(false)
    when .begin_array?
      parse_array
    when .begin_object?
      parse_object
    else
      unexpected_token
    end
  end

  private def parse_array
    ary = [] of Any

    nest do
      while true
        next_token
        break if ary.empty? && token.kind.end_array?

        ary << consume_value

        next_token
        case token.kind
        when .comma?
        when .end_array?
          break
        else
          unexpected_token
        end
      end
    end

    Any.new(ary)
  end

  private def parse_object
    next_token_expect_object_key

    object = {} of String => Any

    nest do
      unless token.kind.end_object?
        while true
          check :string
          key = token.string_value

          next_token
          check :colon

          value = parse_value

          object[key] = value

          next_token
          case token.kind
          when .comma?
            next_token_expect_object_key
            unexpected_token if token.kind.end_object?
          when .end_object?
            break
          else
            unexpected_token
          end
        end
      end
    end

    Any.new(object)
  end

  private delegate token, to: @lexer
  private delegate next_token, to: @lexer
  private delegate next_token_expect_object_key, to: @lexer

  private def check(kind : Token::Kind)
    unexpected_token unless token.kind == kind
  end

  private def unexpected_token
    parse_exception "unexpected token '#{token}'"
  end

  private def parse_exception(msg)
    raise ParseException.new(msg, token.line_number, token.column_number)
  end

  private def nest(&)
    @nest += 1
    if @nest > @max_nesting
      parse_exception "Nesting of #{@nest} is too deep"
    end

    yield
    @nest -= 1
  end
end
