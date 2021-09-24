require "../../support/syntax"

private def expect_inspect(original, expected = original, file = __FILE__, line = __LINE__)
  it "does inspect of #{original.inspect}", file, line do
    str = IO::Memory.new expected.bytesize

    source = original
    if source.is_a?(String)
      parser = Parser.new source
      node = parser.parse
      node.inspect(str)
      str.to_s.should eq(expected), file: file, line: line

      # Check keeping information for `inspect` on clone
      cloned = node.clone
      str.clear
      cloned.inspect(str)
      str.to_s.should eq(expected), file: file, line: line
    else
      source.should eq(expected), file: file, line: line
    end
  end
end

describe "ASTNode#inspect" do
  describe focus: true do
  expect_inspect "[] of T", %(ArrayLiteral{[], of: Path{["T"]}})
  expect_inspect "([] of T).foo", %(Call{Expressions{[ArrayLiteral{[], of: Path{["T"]}}]}, "foo"})
  expect_inspect "({} of K => V).foo", <<-AST
    Call{
     Expressions{
       [HashLiteral{[], of: HashLiteral::Entry{Path{["K"]}, Path{["V"]}}}]
       },
     "foo"
     }
    AST
  expect_inspect "foo(bar)", %(Call{nil, "foo", [Call{nil, "bar"}]})
  expect_inspect "(~1).foo", %(Call{Expressions{[Call{NumberLiteral{"1", :i32}, "~"}]}, "foo"})
  expect_inspect "1 && (a = 2)", <<-AST
    And{
     NumberLiteral{"1", :i32},
     Expressions{[Assign{Var{"a"}, NumberLiteral{"2", :i32}}]}
     }
    AST
  expect_inspect "(a = 2) && 1", <<-AST
    And{
     Expressions{[Assign{Var{"a"}, NumberLiteral{"2", :i32}}]},
     NumberLiteral{"1", :i32}
     }
    AST
  expect_inspect "foo(a.as(Int32))", %(Call{nil, "foo", [Cast{Call{nil, "a"}, Path{["Int32"]}}]})
end
  expect_inspect "(1 + 2).as(Int32)", "(1 + 2).as(Int32)"
  expect_inspect "a.as?(Int32)"
  expect_inspect "(1 + 2).as?(Int32)", "(1 + 2).as?(Int32)"
  describe focus: true do
  expect_inspect "@foo.bar", %(Call{InstanceVar{"@foo"}, "bar"})
  expect_inspect %(:foo), %(SymbolLiteral{"foo"})
  expect_inspect %(:"{"), %(SymbolLiteral{"{"})
  expect_inspect %(%r()), %(RegexLiteral{StringLiteral{""}})
  expect_inspect %(%r()imx), %(RegexLiteral{StringLiteral{""}, IGNORE_CASE | MULTILINE | EXTENDED})
  expect_inspect %(/hello world/), %(RegexLiteral{StringLiteral{"hello world"}})
  expect_inspect %(/hello world/imx), %(RegexLiteral{StringLiteral{"hello world"}, IGNORE_CASE | MULTILINE | EXTENDED})
  expect_inspect %(/\\s/), %(RegexLiteral{StringLiteral{"\\\\s"}})
  expect_inspect %(/\\?/), %(RegexLiteral{StringLiteral{"\\\\?"}})
  expect_inspect %(/\\(group\\)/), %(RegexLiteral{StringLiteral{"\\\\(group\\\\)"}})
  pending { expect_inspect %(/\\//), %(RegexLiteral{StringLiteral{"\\/"}}) }
  expect_inspect %(/\#{1 / 2}/), %(RegexLiteral{\n StringInterpolation{\n  [Call{NumberLiteral{"1", :i32}, "/", [NumberLiteral{"2", :i32}]}]\n  }\n })
  end
  expect_inspect %<%r(/)>, %(/\\//)
  expect_inspect %(/ /), %(/\\ /)
  expect_inspect %(%r( )), %(/\\ /)
  expect_inspect %(foo &.bar), %(foo(&.bar))
  expect_inspect %(foo &.bar(1, 2, 3)), %(foo(&.bar(1, 2, 3)))
  expect_inspect %(foo { |i| i.bar { i } }), "foo do |i|\n  i.bar do\n    i\n  end\nend"
  expect_inspect %(foo do |k, v|\n  k.bar(1, 2, 3)\nend)
  expect_inspect %(foo(3, &.*(2)))
  expect_inspect %(return begin\n  1\n  2\nend)
  expect_inspect %(macro foo\n  %bar = 1\nend)
  expect_inspect %(macro foo\n  %bar = 1; end)
  expect_inspect %(macro foo\n  %bar{1, x} = 1\nend)
  expect_inspect %({% foo %})
  expect_inspect %({{ foo }})
  expect_inspect %({% if foo %}\n  foo_then\n{% end %})
  expect_inspect %({% if foo %}\n  foo_then\n{% else %}\n  foo_else\n{% end %})
  expect_inspect %({% for foo in bar %}\n  {{ foo }}\n{% end %})
  expect_inspect %(macro foo\n  {% for foo in bar %}\n    {{ foo }}\n  {% end %}\nend)
  expect_inspect %[1.as(Int32)]
  expect_inspect %[(1 || 1.1).as(Int32)], %[(1 || 1.1).as(Int32)]
  expect_inspect %[1 & 2 & (3 | 4)], %[(1 & 2) & (3 | 4)]
  expect_inspect %[(1 & 2) & (3 | 4)]
  expect_inspect "def foo(x : T = 1)\nend"
  expect_inspect "def foo(x : X, y : Y) forall X, Y\nend"
  expect_inspect %(foo : A | (B -> C))
  expect_inspect %[%("\#{foo}")], %["\\"\#{foo}\\""]
  expect_inspect "class Foo\n  private def bar\n  end\nend"
  expect_inspect "foo(&.==(2))"
  expect_inspect "foo.nil?"
  expect_inspect "foo._bar"
  expect_inspect "foo._bar(1)"
  expect_inspect "_foo.bar"
  expect_inspect "1.responds_to?(:inspect)"
  expect_inspect "1.responds_to?(:\"&&\")"
  expect_inspect "macro foo(x, *y)\nend"
  expect_inspect "{ {1, 2, 3} }"
  expect_inspect "{ {1 => 2} }"
  expect_inspect "{ {1, 2, 3} => 4 }"
  expect_inspect "{ {foo: 2} }"
  expect_inspect "def foo(*args)\nend"
  expect_inspect "def foo(*args : _)\nend"
  expect_inspect "def foo(**args)\nend"
  expect_inspect "def foo(**args : T)\nend"
  expect_inspect "def foo(x, **args)\nend"
  expect_inspect "def foo(x, **args, &block)\nend"
  expect_inspect "def foo(x, **args, &block : (_ -> _))\nend"
  expect_inspect "def foo(& : (->))\nend"
  expect_inspect "macro foo(**args)\nend"
  expect_inspect "macro foo(x, **args)\nend"
  expect_inspect "def foo(x y)\nend"
  expect_inspect %(foo("bar baz": 2))
  expect_inspect %(Foo("bar baz": Int32))
  expect_inspect %({"foo bar": 1})
  expect_inspect %(def foo("bar baz" qux)\nend)
  expect_inspect "foo()"
  expect_inspect "/a/x"
  expect_inspect "1_f32", "1_f32"
  expect_inspect "1_f64", "1_f64"
  expect_inspect "1.0", "1.0"
  expect_inspect "1e10_f64", "1e10"
  expect_inspect "!a"
  expect_inspect "!(1 < 2)"
  expect_inspect "(1 + 2)..3"
  expect_inspect "macro foo\n{{ @type }}\nend"
  expect_inspect "macro foo\n\\{{ @type }}\nend"
  expect_inspect "macro foo\n{% @type %}\nend"
  expect_inspect "macro foo\n\\{%@type %}\nend"
  expect_inspect "enum A : B\nend"
  expect_inspect "# doc\ndef foo\nend"
  expect_inspect "foo[x, y, a: 1, b: 2]"
  expect_inspect "foo[x, y, a: 1, b: 2] = z"
  expect_inspect %(@[Foo(1, 2, a: 1, b: 2)])
  expect_inspect %(lib Foo\nend)
  expect_inspect %(fun foo(a : Void, b : Void, ...) : Void\n\nend)
  expect_inspect %(lib Foo\n  struct Foo\n    a : Void\n    b : Void\n  end\nend)
  expect_inspect %(lib Foo\n  union Foo\n    a : Int\n    b : Int32\n  end\nend)
  expect_inspect %(lib Foo\n  FOO = 0\nend)
  expect_inspect %(lib LibC\n  fun getch = "get.char"\nend)
  expect_inspect %(enum Foo\n  A = 0\n  B\nend)
  expect_inspect %(alias Foo = Void)
  expect_inspect %(alias Foo::Bar = Void)
  expect_inspect %(type(Foo = Void))
  expect_inspect %(return true ? 1 : 2)
  expect_inspect %(1 <= 2 <= 3)
  expect_inspect %((1 <= 2) <= 3)
  expect_inspect %(1 <= (2 <= 3))
  expect_inspect %(case 1; when .foo?; 2; end), %(case 1\nwhen .foo?\n  2\nend)
  expect_inspect %(case 1; in .foo?; 2; end), %(case 1\nin .foo?\n  2\nend)
  expect_inspect %(case 1; when .!; 2; when .< 0; 3; end), %(case 1\nwhen .!\n  2\nwhen .<(0)\n  3\nend)
  expect_inspect %(case 1\nwhen .[](2)\n  3\nwhen .[]=(4)\n  5\nend)
  expect_inspect %({(1 + 2)})
  expect_inspect %({foo: (1 + 2)})
  expect_inspect %q("#{(1 + 2)}")
  expect_inspect %({(1 + 2) => (3 + 4)})
  expect_inspect %([(1 + 2)] of Int32)
  expect_inspect %(foo(1, (2 + 3), bar: (4 + 5)))
  expect_inspect %(if (1 + 2\n3)\n  4\nend)
  expect_inspect "%x(whoami)", "`whoami`"
  expect_inspect %(begin\n  ()\nend)
  expect_inspect %q("\e\0\""), %q("\e\u0000\"")
  expect_inspect %q("#{1}\0"), %q("#{1}\u0000")
  expect_inspect %q(%r{\/\0}), %q(/\/\0/)
  expect_inspect %q(%r{#{1}\/\0}), %q(/#{1}\/\0/)
  expect_inspect %q(`\n\0`), %q(`\n\u0000`)
  expect_inspect %q(`#{1}\n\0`), %q(`#{1}\n\u0000`)
  expect_inspect "macro foo\n{% verbatim do %}1{% end %}\nend"
  expect_inspect Assign.new("x".var, Expressions.new([1.int32, 2.int32] of ASTNode)), "x = (1\n2\n)"
  expect_inspect "foo.*"
  expect_inspect "foo.%"
  expect_inspect "&+1"
  expect_inspect "&-1"
  expect_inspect "1.&*"
  expect_inspect "1.&**"
  expect_inspect "1.~(2)"
  expect_inspect "1.~(2) do\nend"
  expect_inspect "1.+ do\nend"
  expect_inspect "1.[](2) do\nend"
  expect_inspect "1.[]="
  expect_inspect "1.+(a: 2)"
  expect_inspect "1.+(&block)"
  expect_inspect "1.//(2, a: 3)"
  expect_inspect "1.//(2, &block)"
  expect_inspect %({% verbatim do %}\n  1{{ 2 }}\n  3{{ 4 }}\n{% end %})
  expect_inspect %({% for foo in bar %}\n  {{ if true\n  foo\n  bar\nend }}\n{% end %})
  expect_inspect %(asm("nop" ::::))
  expect_inspect %(asm("nop" : "a"(1), "b"(2) : "c"(3), "d"(4) : "e", "f" : "volatile", "alignstack", "intel"))
  expect_inspect %(asm("nop" :: "c"(3), "d"(4) ::))
  expect_inspect %(asm("nop" :::: "volatile"))
  expect_inspect %(asm("nop" :: "a"(1) :: "volatile"))
  expect_inspect %(asm("nop" ::: "e" : "volatile"))
  expect_inspect %[(1..)]
  expect_inspect %[..3]
  expect_inspect "offsetof(Foo, @bar)"
  expect_inspect "def foo(**options, &block)\nend"
  expect_inspect "macro foo\n  123\nend"
  expect_inspect "if true\n(  1)\nend"
  expect_inspect "begin\n(  1)\nrescue\nend"
  expect_inspect %[他.说("你好")]
  expect_inspect %[他.说 = "你好"]
  expect_inspect %[あ.い, う.え.お = 1, 2]
end
