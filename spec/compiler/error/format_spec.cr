require "../spec_helper"
require "compiler/crystal/error"
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
        location = Crystal::ErrorLocation.new(VirtualFile.new(Macro.new("foo"), "", Location.new("foo", 2, 7)), 2, 7, 3)
        formatter = Crystal::ErrorFormatter.new(io)
        formatter.print_location_name(location)
      end
      result.should eq "expanded macro: foo:2:7"
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
    error = Crystal::LocationError.new("message", Crystal::ErrorLocation.new("foo.cr", 2, 7, 3, source: "  foo(baz)"))
    assert_format(error, <<-ERROR)
      foo.cr:2:7
       2 | foo(baz)
               ^~~
      Error: message
      ERROR
  end

  it "no overload" do
    error = Crystal::LocationError.new(
      "no overload matches 'foo' with type Int32",
      Crystal::ErrorLocation.new("no_overload.cr", 4, 1, 3, source: "foo(1)"))

    assert_format(error, <<-ERROR)
      no_overload.cr:4:1
       4 | foo(1)
           ^~~
      Error: no overload matches 'foo' with type Int32
      ERROR
  end

  describe "#print_source" do
    describe "colorized" do
      it "underlines" do
        location = Crystal::ErrorLocation.new("", 10, 9, 3, "    foo(Bar)")
        String.build do |io|
          Crystal::ErrorFormatter.new(io).tap { |f| f.colorize = true }.print_source(location)
        end.chomp.should eq <<-OUT
        #{" 10 | ".colorize.dark_gray}foo(#{"Bar".colorize.bold})
        #{"          ^~~".colorize.blue}
        OUT
      end
    end

    describe "non-colorized" do
      it "underlines" do
        location = Crystal::ErrorLocation.new("", 10, 9, 3, "    foo(Bar)")
        String.build do |io|
          Crystal::ErrorFormatter.new(io).print_source(location)
        end.chomp.should eq <<-OUT
         10 | foo(Bar)
                  ^~~
        OUT
      end
    end
  end

  describe "virtual file nesting" do
    it do
      location = Crystal::ErrorLocation.new(
        Crystal::VirtualFile.new(
          Crystal::Macro.new("foo"),
          source: "  asdasdasdasd++\n",
          expanded_location: Crystal::Location.new(
            Crystal::VirtualFile.new(
              Crystal::Macro.new("bar"),
              source: " foo; ",
              expanded_location: Crystal::Location.new("test.cr", 8, 1)
            ),
            1, 2
          )
        ),
        1, 16,
        source: "macro foo"
      )

      String.build do |io|
        Crystal::ErrorFormatter.new(io).print_location(location)
      end.chomp.should eq <<-OUT
        There was a problem expanding macro 'foo'

        Code in macro 'bar'

        1 | foo;
            ^
        Called macro defined in test.cr:1:1

        1 | macro foo

        Which expanded to:

        > 1 | asdasdasdasd++
                            ^
      OUT
    end
  end
end
