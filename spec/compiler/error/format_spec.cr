require "spec"
require "compiler/crystal/error"
require "compiler/crystal/syntax/location"
require "compiler/crystal/error/formatter"

private def assert_format(error, expected, *, file = __FILE__, line = __LINE__)
  result = String.build do |io|
    formatter = Crystal::ErrorFormatter.new(io)
    formatter.format(error)
  end

  result.chomp.should eq(expected), file, line
end

describe "error format" do
  describe "#print_location_name" do
    it "file" do
      result = String.build do |io|
        location = Crystal::ErrorLocation.new("foo.cr", 2, 7, 3)
        formatter = Crystal::ErrorFormatter.new(io)
        formatter.print_location_name(location)
      end
      result.should eq "foo.cr:2:7"
    end

    it "macro" do
      result = String.build do |io|
        location = Crystal::ErrorLocation.new("foo", 2, 7, 3, virtual: true)
        formatter = Crystal::ErrorFormatter.new(io)
        formatter.print_location_name(location)
      end
      result.should eq "macro foo:2:7"
    end

    it "nil" do
      result = String.build do |io|
        location = Crystal::ErrorLocation.new(nil, 2, 7, 3)
        formatter = Crystal::ErrorFormatter.new(io)
        formatter.print_location_name(location)
      end
      result.should eq "<unknown>:2:7"
    end
  end

  it "simple" do
    error = Crystal::SemanticError.new("message", Crystal::ErrorLocation.new("foo.cr", 2, 7, 3))
    error.source = "  foo(baz)"
    assert_format(error, <<-ERROR)
      foo.cr:2:7
       2 | foo(baz)
               ^~~
      Error: message
      ERROR
  end

  it "no overload" do
    error = Crystal::SemanticError.new(
      "no overload matches 'foo' with type Int32",
      Crystal::ErrorLocation.new("no_overload.cr", 4, 1, 3),
      notes: ["Overloads are:\n - foo(arg : String)\n - foo(arg : Bool)"])
    error.source = "foo(1)"

    assert_format(error, <<-ERROR)
      no_overload.cr:4:1
       4 | foo(1)
           ^~~
      Error: no overload matches 'foo' with type Int32

      Overloads are:
       - foo(arg : String)
       - foo(arg : Bool)
      ERROR
  end

  it "errors" do
    error = Crystal::SemanticError.new(
      "no overload matches 'baz' with type Int32",
      Crystal::ErrorLocation.new("error_trace.cr", 6, 3, 3),
      notes: ["Overloads are:\n - baz(baz : String)"]
    )
    error.source = "  baz(bar)"
    error.frames << Crystal::ErrorFrame.new("instantiating 'bar(Int32)'", Crystal::ErrorLocation.new("error_trace.cr", 2, 3, 3)).source("  bar(foo)")
    error.frames << Crystal::ErrorFrame.new("instantiating 'foo(Int32)'", Crystal::ErrorLocation.new("error_trace.cr", 11, 1, 3)).source("foo(1)")

    assert_format(error, <<-ERROR)
      error_trace.cr:11:1
       11 | foo(1)
            ^~~

      instantiating 'foo(Int32)'
      error_trace.cr:2:3
       2 | bar(foo)
           ^~~

      instantiating 'bar(Int32)'
      error_trace.cr:6:3
       6 | baz(bar)
           ^~~
      Error: no overload matches 'baz' with type Int32

      Overloads are:
       - baz(baz : String)
      ERROR
  end

  describe "#print_error_message" do
    it "prints hint" do
      error = Crystal::SemanticError.new("error message", nil, notes: ["error note"])
      String.build do |io|
        Crystal::ErrorFormatter.new(io).print_error_message(error)
      end.chomp.should eq <<-OUT
        error message

        error note
        OUT
    end

    it "prints hints" do
      error = Crystal::SemanticError.new("error message", nil, notes: ["error note 1", "error note 2"])
      String.build do |io|
        Crystal::ErrorFormatter.new(io).print_error_message(error)
      end.chomp.should eq <<-OUT
        error message

        error note 1

        error note 2
        OUT
    end
  end

  describe "#print_source" do
    describe "colorized" do
      it "underlines" do
        location = Crystal::ErrorLocation.new("", 10, 9, 3)
        line = "    foo(Bar)"
        String.build do |io|
          Crystal::ErrorFormatter.new(io).tap { |f| f.colorize = true }.print_source(location, line)
        end.chomp.should eq <<-OUT
        #{" 10 | ".colorize.dark_gray}foo(#{"Bar".colorize.bold})
        #{"          ^~~".colorize.blue}
        OUT
      end
    end

    describe "non-colorized" do
      it "underlines" do
        location = Crystal::ErrorLocation.new("", 10, 9, 3)
        line = "    foo(Bar)"
        String.build do |io|
          Crystal::ErrorFormatter.new(io).print_source(location, line)
        end.chomp.should eq <<-OUT
         10 | foo(Bar)
                  ^~~
        OUT
      end
    end
  end
end
