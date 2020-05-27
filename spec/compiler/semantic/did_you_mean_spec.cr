require "../../spec_helper"

describe "Semantic: did you mean" do
  it "says did you mean for one mistake in short word in instance method" do
    assert_error "
      class Foo
        def bar
        end
      end

      Foo.new.baz
      ",
      nil,
      notes: ["Did you mean 'bar'?"]
  end

  it "says did you mean for two mistakes in long word in instance method" do
    assert_error "
      class Foo
        def barbara
        end
      end

      Foo.new.bazbaza
      ",
      nil,
      notes: ["Did you mean 'barbara'?"]
  end

  it "says did you mean for global method with parenthesis" do
    assert_error "
      def bar
      end

      baz()
      ",
      nil,
      notes: ["Did you mean 'bar'?"]
  end

  it "says did you mean for global method without parenthesis" do
    assert_error "
      def bar
      end

      baz
      ",
      nil,
      notes: ["Did you mean 'bar'?"]
  end

  it "says did you mean for variable" do
    assert_error "
      bar = 1
      baz
      ",
      nil,
      notes: ["Did you mean 'bar'?"]
  end

  it "says did you mean for class" do
    assert_error "
      class Foo
      end

      Fog.new
      ",
      nil,
      notes: ["Did you mean 'Foo'?"]
  end

  it "says did you mean for nested class" do
    assert_error "
      class Foo
        class Bar
        end
      end

      Foo::Baz.new
      ",
      nil,
      notes: ["Did you mean 'Foo::Bar'?"]
  end

  it "says did you mean finds most similar in def" do
    assert_error "
      def barbaza
      end

      def barbara
      end

      barbarb
      ",
      nil,
      notes: ["Did you mean 'barbara'?"]
  end

  it "says did you mean finds most similar in type" do
    assert_error "
      class Barbaza
      end

      class Barbara
      end

      Barbarb
      ",
      nil,
      notes: ["Did you mean 'Barbara'?"]
  end

  it "doesn't suggest for operator" do
    error = assert_error %(
      class Foo
        def +
        end
      end

      Foo.new.a
      )
    error.notes.should be_empty
  end

  it "says did you mean for named argument" do
    assert_error "
      def foo(barbara = 1)
      end

      foo bazbaza: 1
      ",
      nil,
      notes: ["Did you mean 'barbara'?", "Matches are:\n - foo(barbara = 1)"]
  end

  it "says did you mean for instance var" do
    error = assert_error %(
      class Foo
        def initialize
          @barbara = 1
        end

        def foo
          @bazbaza.abs
        end
      end

      Foo.new.foo
      ),
      "can't infer the type of instance variable '@bazbaza' of Foo"

    error.notes[0].should eq "Did you mean '@barbara'?"
    error.notes[1].should start_with "The type of a instance variable, if not declared explicitly with\n`@bazbaza : Type`, is inferred"
  end

  it "says did you mean for instance var in subclass" do
    error = assert_error %(
      class Foo
        def initialize
          @barbara = 1
        end
      end

      class Bar < Foo
        def foo
          @bazbaza.abs
        end
      end

      Bar.new.foo
      ),
      "can't infer the type of instance variable '@bazbaza' of Bar"
    error.notes[0].should eq "Did you mean '@barbara'?"
    error.notes[1].should start_with "The type of a instance variable, if not declared explicitly with\n`@bazbaza : Type`, is inferred"
  end

  it "doesn't suggest when declaring var with suffix if and using it (#946)" do
    assert_error %(
      a if a = 1
      ),
      nil,
      notes: ["If you declared 'a' in a suffix if, declare it in a regular if for this to work. If the variable was declared in a macro it's not visible outside it."]
  end

  it "doesn't suggest when declaring var inside macro (#466)" do
    assert_error %(
      macro foo
        a = 1
      end

      foo
      a
      ),
      nil,
      notes: ["If you declared 'a' in a suffix if, declare it in a regular if for this to work. If the variable was declared in a macro it's not visible outside it."]
  end

  it "suggest that there might be a type for an initialize method" do
    assert_error %(
      class Foo
        def intialize(x)
        end
      end

      Foo.new(1)
      ),
      "wrong number of arguments for 'Foo.new' (given 1, expected 0)",
      notes: ["do you maybe have a typo in this 'intialize' method?", "Overloads are:\n - Reference.new()"]
  end

  it "suggest that there might be a type for an initialize method in inherited class" do
    assert_error %(
      class Foo
        def initialize
        end
      end

      class Bar < Foo
        def intialize(x)
        end
      end

      Bar.new(1)
      ),
      "wrong number of arguments for 'Bar.new' (given 1, expected 0)",
      notes: ["do you maybe have a typo in this 'intialize' method?", "Overloads are:\n - Foo.new()"]
  end

  it "suggest that there might be a type for an initialize method with overload" do
    assert_error %(
      class Foo
        def initialize(x : Int32)
        end

        def intialize(y : Float64)
        end
      end

      Foo.new(1.0)
      ),
      "no overload matches 'Foo.new' with type Float64",
      notes: ["do you maybe have a typo in this 'intialize' method?", "Overloads are:\n - Foo.new(x : Int32)"]
  end

  it "suggests for class variable" do
    error = assert_error %(
      class Foo
        @@foobar = 1
        @@fooobar
      end
      ),
      "can't infer the type of class variable '@@fooobar' of Foo"

    error.notes[0].should eq "Did you mean '@@foobar'?"
    error.notes[1].should start_with "The type of a class variable, if not declared explicitly with\n`@@fooobar : Type`, is inferred"
  end

  it "suggests a better alternative to logical operators (#2715)" do
    ex = assert_error %(
      def rand(x : Int32)
      end

      class String
        def bytes
          self
        end
      end

      if "a".bytes and 1
        1
      end
      ),
      "undefined method 'and' for top-level",
      notes: ["Did you mean '&&'?"]
  end

  it "says did you mean in instance var declaration" do
    assert_error %(
      class FooBar
      end

      class Foo
        @x : FooBaz
      end
      ),
      nil,
      notes: ["Did you mean 'FooBar'?"]
  end
end
