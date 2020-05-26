require "../spec_helper"

describe Crystal::CodeError do
  describe ".new" do
    it "loads source from virtual file" do
      filename = Crystal::VirtualFile.new(Crystal::Macro.new("foo"), "def foo\n  bar\nend", nil)
      error = Crystal::CodeError.new("", Crystal::Location.new(filename, 2, 3), size: 3)
      error.location.should eq Crystal::ErrorLocation.new("foo", 2, 3, 3, virtual: true)
      error.source.should eq "  bar"
    end
  end

  it "syntax error" do
    ex = expect_raises(Crystal::SyntaxError, "unterminated char literal") do
      parse("'")
    end
    ex.location.should eq Crystal::ErrorLocation.new("", 1, 1)
  end

  it "semantic error" do
    ex = expect_raises(Crystal::SemanticError, "can't cast Int32 to Float64") do
      semantic("1.as(Float64)", inject_primitives: false)
    end
    ex.location.should eq Crystal::ErrorLocation.new("", 1, 1, 0)
  end

  it "semantic error" do
    ex = expect_raises(Crystal::SemanticError, "undefined local variable or method 'foo' for top-level") do
      semantic("foo", inject_primitives: false)
    end
    ex.location.should eq Crystal::ErrorLocation.new("", 1, 1, 3)
    ex.frames.should be_empty
  end

  describe "frames" do
    describe "method" do
      it "top-level method" do
        ex = expect_raises(Crystal::SemanticError, "undefined local variable or method 'foo' for top-level") do
          semantic(<<-CR, inject_primitives: false)
          def bar
            foo
          end
          bar
          CR
        end
        ex.location.should eq Crystal::ErrorLocation.new("", 2, 3, 3)
        ex.frames.should eq [
          Crystal::ErrorFrame.new(:def, Crystal::ErrorLocation.new("", 4, 1, 3), "bar()"),
        ]
      end

      it "instance method" do
        ex = expect_raises(Crystal::SemanticError, "undefined local variable or method 'foo' for Bar") do
          semantic(<<-CR, inject_primitives: false)
          class Bar
            def bar
              foo
            end
          end
          Bar.new.bar
          CR
        end
        ex.location.should eq Crystal::ErrorLocation.new("", 3, 5, 3)
        ex.frames.should eq [
          Crystal::ErrorFrame.new(:def, Crystal::ErrorLocation.new("", 6, 9, 3), "Bar#bar()"),
        ]
      end
    end

    describe "macro" do
      it "top-level macro" do
        ex = expect_raises(Crystal::SemanticError, "undefined local variable or method 'foo' for top-level") do
          semantic(<<-CR, inject_primitives: false)
        macro bar
          foo
        end
        bar
        CR
        end
        ex.location.should eq Crystal::ErrorLocation.new("bar", 1, 3, 3, virtual: true)
        ex.frames.should eq [
          Crystal::ErrorFrame.new(:macro, Crystal::ErrorLocation.new("", 4, 1, 3), "bar"),
        ]
        ex.source.should eq "  foo"
      end

      it "class macro" do
        ex = expect_raises(Crystal::SemanticError, "undefined local variable or method 'foo' for top-level") do
          semantic(<<-CR, inject_primitives: false)
        class Bar
          macro bar
            foo
          end
        end
        Bar.bar
        CR
        end
        ex.location.should eq Crystal::ErrorLocation.new("bar", 1, 5, 3, virtual: true)
        ex.frames.should eq [
          Crystal::ErrorFrame.new(:macro, Crystal::ErrorLocation.new("", 6, 5, 3), "Bar.bar"),
        ]
        ex.source.should eq "    foo"
      end
    end
  end

  describe "multiple" do
    it "top-level methods" do
      ex = expect_raises(Crystal::SemanticError, "undefined local variable or method 'foo' for top-level") do
        semantic(<<-CR, inject_primitives: false)
        def bar
          foo
        end
        def baz
          bar
        end
        baz
        CR
      end
      ex.location.should eq Crystal::ErrorLocation.new("", 2, 3, 3)
      ex.frames.should eq [
        Crystal::ErrorFrame.new(:def, Crystal::ErrorLocation.new("", 5, 3, 3), "bar()"),
        Crystal::ErrorFrame.new(:def, Crystal::ErrorLocation.new("", 7, 1, 3), "baz()"),
      ]
    end
  end
end
