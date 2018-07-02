require "spec"
require "xml"

private def doc
  XML.parse(%(\
    <?xml version='1.0' encoding='UTF-8'?>
    <people>
      <person id="1">
        <name>John</name>
      </person>
      <person id="2">
        <name>Peter</name>
      </person>
    </people>
    ))
end

private def translate_selector(css)
  XML::SelectorParser.new(css).parse
end

describe "XML css_to_xpath" do
  {
    "type" => {"foo", "//foo"},
    "universal" => {"*", "//*"},
    "descendant" => {"foo bar", "//foo//bar"},
    "universal descentand" => {"foo *", "//foo//*"},
    "child" =>      {"foo > bar", "//foo/bar"},
    "universal child" => {"foo > *", "//foo/*"},
    "adjacent sibling" => {"foo + bar", "//foo/following-sibling::*[1]/self::bar"},
    "general sibling" => {"foo ~ bar", "//foo/following-sibling::*[count(bar)]"},
    "class" =>      {".bar", %(//*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')])},
    "class with name" =>      {"foo.bar", %(//foo[contains(concat(' ', normalize-space(@class), ' '), ' bar ')])},
    "id"    =>      {"#bar", %(//*[@id = 'bar'])},
    "id with name"    =>      {"foo#bar", %(//foo[@id = 'bar'])},

    "argument presence" => {"[bar]", "//*[@bar]"},
    "argument presence" => {"foo[bar]", "//foo[@bar]"},
    "argument equality" => {"[bar=baz]", "//*[@bar = 'baz']"},
    "argument contains" => {"[bar*=baz]", "//*[contains(@bar, 'baz')]"},
    "argument starts with" => {"[bar|=baz]", "//*[@bar = 'baz' or starts-with(@bar, concat('baz', '-'))]"},
    "argument starts with prefix" => {"[bar^=baz]", "//*[starts-with(@bar, 'baz')]"},
    "argument ends with" => { %([bar$="baz"]), "//*[substring(@bar, string-length(@bar) - 3) = 'baz']"},
    "argument like" => {"[bar~=baz]", "//*[contains(concat(' ', @bar, ' '), ' baz ')]"},
    "argument negation" => {"[bar!=baz]", "//*[@bar != 'baz']"},

    "pseudo" => {"foo:first-child", "//foo[count(preceding-sibling::*) = 0]"},
    "pseudo child" => {"foo > *:first-child", "//foo/*[count(preceding-sibling::*) = 0]"},
  }.each do |name, strings|
    it "#{name} '#{strings[0]}'" do
      translate_selector(strings[0]).should eq strings[1]
    end
  end

  it "not_simple_selector" do
    translate_selector("ol > *:not(li)").should eq "//ol/*[not(self::li)]"
  end

  it "not_last_child" do
    translate_selector("ol > *:not(:last-child)").should eq "//ol/*[not(count(following-sibling::*) = 0)]"
  end

  it "not_only_child" do
    translate_selector("ol > *:not(:only-child)").should eq "//ol/*[not(count(preceding-sibling::*) = 0 and count(following-sibling::*) = 0)]"
  end

  it "function_calls_allow_at_params" do
    translate_selector("a:foo(@href)").should eq "//a[foo(., @href)]"
    translate_selector("a:foo(@a, b)").should eq "//a[foo(., @a, b)]"
    translate_selector("a:foo(a, 10)").should eq "//a[foo(., a, 10)]"
  end

  it "namespace_conversion" do
    translate_selector("aaron|a").should eq "//aaron:a"
    translate_selector("|a").should eq "//a"
  end

  pending "namespaced_attribute_conversion" do
    translate_selector("a[flavorjones|href]").should eq "//a[has(., @flavorjones:href)]"
    translate_selector("a[|href]").should eq "//a[has(., @href)]"
    translate_selector("*[flavorjones|href]").should eq "//*[has(., @flavorjones:href)]"
  end

  it "namespaced_attribute_conversion" do
    translate_selector("a[flavorjones|href]").should eq "//a[@flavorjones:href]"
    translate_selector("a[|href]").should eq "//a[@href]"
    translate_selector("*[flavorjones|href]").should eq "//*[@flavorjones:href]"
  end

  it "unknown_psuedo_classes_get_pushed_down" do
    translate_selector("a:aaron").should eq "//a[aaron(.)]"
  end

  it "unknown_functions_get_dot_plus_args" do
    translate_selector("a:aaron()").should eq "//a[aaron(.)]"
    translate_selector("a:aaron(12)").should eq "//a[aaron(., 12)]"
    translate_selector("a:aaron(12, 1)").should eq "//a[aaron(., 12, 1)]"
  end

  it "class_selectors" do
    translate_selector(".red").should eq "//*[contains(concat(' ', normalize-space(@class), ' '), ' red ')]"
  end

  it "pipe" do
    translate_selector("a[id|='Boing']").should eq "//a[@id = 'Boing' or starts-with(@id, concat('Boing', '-'))]"
  end

  # from nokogiri css/test_parser.rb

  it "has" do
    translate_selector("a:has(b)").should eq "//a[has(., b)]"
    translate_selector("a:has(b > c)").should eq "//a[has(., b/c)]"
  end

  pending "dashmatch" do
    # These are not valid CSS
    translate_selector("a[@class|='bar']").should eq "//a[@class = 'bar' or starts-with(@class, concat('bar', '-'))]"
    translate_selector("a[@class |= 'bar']").should eq "//a[@class = 'bar' or starts-with(@class, concat('bar', '-'))]"
  end

  pending "includes" do
    # These are not valid CSS
    translate_selector("a[@class~='bar']").should eq "//a[contains(concat(\" \", @class, \" \"),concat(\" \", 'bar', \" \"))]"
    translate_selector("a[@class ~= 'bar']").should eq "//a[contains(concat(\" \", @class, \" \"),concat(\" \", 'bar', \" \"))]"
  end

  pending "function_with_arguments" do
    # This is not valid CSS
    translate_selector("a[2]").should eq "//a[count(preceding-sibling::*) = 1]"
  end

  it "function_with_arguments" do
    translate_selector("a:nth-child(2)").should eq "//a[count(preceding-sibling::*) = 1]"
  end

  it "carrot" do
    translate_selector("a[id^='Boing']").should eq "//a[starts-with(@id, 'Boing')]"
    translate_selector("a[id ^= 'Boing']").should eq "//a[starts-with(@id, 'Boing')]"
  end

  it "suffix_match" do
    translate_selector("a[id$='Boing']").should eq "//a[substring(@id, string-length(@id) - string-length('Boing') + 1, string-length('Boing')) = 'Boing']"
    translate_selector("a[id $= 'Boing']").should eq "//a[substring(@id, string-length(@id) - string-length('Boing') + 1, string-length('Boing')) = 'Boing']"
  end

  pending "attributes_with_at" do
    ## This is non standard CSS
    translate_selector("a[@id='Boing']").should eq "//a[@id = 'Boing']"
    translate_selector("a[@id = 'Boing']").should eq "//a[@id = 'Boing']"
  end

  pending "attributes_with_at_and_stuff" do
    ## This is non standard CSS
    translate_selector("a[@id='Boing'] div").should eq "//a[@id = 'Boing']//div"
  end

  pending "not_equal" do
    ## This is non standard CSS
    translate_selector("a[text()!='Boing']").should eq "//a[child::text() != 'Boing']"
    translate_selector("a[text() != 'Boing']").should eq "//a[child::text() != 'Boing']"
  end

  pending "function" do
    ## This is non standard CSS
    translate_selector("a[text()]").should eq "//a[child::text()]"

    ## This is non standard CSS
    translate_selector("text()").should eq "//child::text()"

    ## This is non standard CSS
    translate_selector("a[text()*='Boing']").should eq "//a[contains(child::text(), 'Boing')]"
    translate_selector("a[text() *= 'Boing']").should eq "//a[contains(child::text(), 'Boing')]"

    ## This is non standard CSS
    translate_selector("script comment()").should eq "//script//comment()"
  end

  pending "nonstandard_nth_selectors" do
    ## These are non standard CSS
    translate_selector("a:first()").should eq "//a[position() = 1]"
    translate_selector("a:first").should eq "//a[position() = 1]" # no parens
    translate_selector("a:eq(99)").should eq "//a[position() = 99]"
    translate_selector("a:nth(99)").should eq "//a[position() = 99]"
    translate_selector("a:last()").should eq "//a[position() = last()]"
    translate_selector("a:last").should eq "//a[position() = last()]" # no parens
    translate_selector("a:parent").should eq "//a[node()]"
  end

  it "standard_nth_selectors" do
    translate_selector("a:first-of-type()").should eq "//a[position() = 1]"
    translate_selector("a:first-of-type").should eq "//a[position() = 1]" # no parens
    translate_selector("a.b:first-of-type").should eq "//a[contains(concat(' ', normalize-space(@class), ' '), ' b ')][position() = 1]" # no parens
    translate_selector("a:nth-of-type(99)").should eq "//a[position() = 99]"
    translate_selector("a.b:nth-of-type(99)").should eq "//a[contains(concat(' ', normalize-space(@class), ' '), ' b ')][position() = 99]"
    translate_selector("a:last-of-type()").should eq "//a[position() = last()]"
    translate_selector("a:last-of-type").should eq "//a[position() = last()]" # no parens
    translate_selector("a.b:last-of-type").should eq "//a[contains(concat(' ', normalize-space(@class), ' '), ' b ')][position() = last()]" # no parens
    translate_selector("a:nth-last-of-type(1)").should eq "//a[position() = last()]"
    translate_selector("a:nth-last-of-type(99)").should eq "//a[position() = last() - 98]"
    translate_selector("a.b:nth-last-of-type(99)").should eq "//a[contains(concat(' ', normalize-space(@class), ' '), ' b ')][position() = last() - 98]"
  end

  it "nth_child_selectors" do
    translate_selector("a:first-child").should eq "//a[count(preceding-sibling::*) = 0]"
    translate_selector("a:nth-child(99)").should eq "//a[count(preceding-sibling::*) = 98]"
    translate_selector("a:last-child").should eq "//a[count(following-sibling::*) = 0]"
    translate_selector("a:nth-last-child(1)").should eq "//a[count(following-sibling::*) = 0]"
    translate_selector("a:nth-last-child(99)").should eq "//a[count(following-sibling::*) = 98]"
  end

  it "miscellaneous_selectors" do
    translate_selector("a:only-child").should eq "//a[count(preceding-sibling::*) = 0 and count(following-sibling::*) = 0]"
    translate_selector("a:only-of-type").should eq "//a[last() = 1]"
    translate_selector("a:empty").should eq "//a[not(node())]"
  end

  it "nth_a_n_plus_b" do
    translate_selector("a:nth-of-type(2n)").should eq "//a[(position() mod 2) = 0]"
    translate_selector("a:nth-of-type(2n+1)").should eq "//a[(position() >= 1) and (((position()-1) mod 2) = 0)]"
    translate_selector("a:nth-of-type(even)").should eq "//a[(position() mod 2) = 0]"
    translate_selector("a:nth-of-type(odd)").should eq "//a[(position() >= 1) and (((position()-1) mod 2) = 0)]"
    translate_selector("a:nth-of-type(4n+3)").should eq "//a[(position() >= 3) and (((position()-3) mod 4) = 0)]"
    translate_selector("a:nth-of-type(-1n+3)").should eq "//a[position() <= 3]"
    translate_selector("a:nth-of-type(-n+3)").should eq "//a[position() <= 3]"
    translate_selector("a:nth-of-type(1n+3)").should eq "//a[position() >= 3]"
    translate_selector("a:nth-of-type(n+3)").should eq "//a[position() >= 3]"

    translate_selector("a:nth-last-of-type(2n)").should eq "//a[((last()-position()+1) mod 2) = 0]"
    translate_selector("a:nth-last-of-type(2n+1)").should eq "//a[((last()-position()+1) >= 1) and ((((last()-position()+1)-1) mod 2) = 0)]"
    translate_selector("a:nth-last-of-type(even)").should eq "//a[((last()-position()+1) mod 2) = 0]"
    translate_selector("a:nth-last-of-type(odd)").should eq "//a[((last()-position()+1) >= 1) and ((((last()-position()+1)-1) mod 2) = 0)]"
    translate_selector("a:nth-last-of-type(4n+3)").should eq "//a[((last()-position()+1) >= 3) and ((((last()-position()+1)-3) mod 4) = 0)]"
    translate_selector("a:nth-last-of-type(-1n+3)").should eq "//a[(last()-position()+1) <= 3]"
    translate_selector("a:nth-last-of-type(-n+3)").should eq "//a[(last()-position()+1) <= 3]"
    translate_selector("a:nth-last-of-type(1n+3)").should eq "//a[(last()-position()+1) >= 3]"
    translate_selector("a:nth-last-of-type(n+3)").should eq "//a[(last()-position()+1) >= 3]"
  end

  it "preceding_selector" do
    translate_selector("E ~ F").should eq "//E/following-sibling::F"

    translate_selector("E ~ F G").should eq "//E/following-sibling::F//G"
  end

  it "direct_preceding_selector" do
    translate_selector("E + F").should eq "//E/following-sibling::*[1]/self::F"

    translate_selector("E + F G").should eq "//E/following-sibling::*[1]/self::F//G"
  end

  it "child_selector" do
    translate_selector("a b>i").should eq "//a//b/i"
    translate_selector("a b > i").should eq "//a//b/i"
    translate_selector("a > b > i").should eq "//a/b/i"
  end


  pending "prefixless_child_selector" do
    # this is not valid CSS
    translate_selector(">a").should eq "./a"
    translate_selector("> a").should eq "./a"
    translate_selector(">a b>i").should eq "./a//b/i"
    translate_selector("> a > b > i").should eq "./a/b/i"
  end

  pending "prefixless_preceding_sibling_selector" do
    # this is not valid CSS
    translate_selector("~a").should eq "./following-sibling::a"
    translate_selector("~ a").should eq "./following-sibling::a"
    translate_selector("~a b~i").should eq "./following-sibling::a//b/following-sibling::i"
    translate_selector("~ a b ~ i").should eq "./following-sibling::a//b/following-sibling::i"
  end

  pending "prefixless_direct_adjacent_selector" do
    # this is not valid CSS
    translate_selector("+a").should eq "./following-sibling::*[1]/self::a"
    translate_selector("+ a").should eq "./following-sibling::*[1]/self::a"
    translate_selector("+a+b").should eq "./following-sibling::*[1]/self::a/following-sibling::*[1]/self::b"
    translate_selector("+ a + b").should eq "./following-sibling::*[1]/self::a/following-sibling::*[1]/self::b"
  end

  it "attribute" do
    translate_selector("h1[a='Tender Lovemaking']").should eq "//h1[@a = 'Tender Lovemaking']"
  end

  it "attribute_with_number_or_string" do
    translate_selector("img[width='200']").should eq "//img[@width = '200']"
    translate_selector("img[width=200]").should eq "//img[@width = '200']"
  end

  it "id" do
    translate_selector("#foo").should eq "//*[@id = 'foo']"
    translate_selector("#escape\:needed\,").should eq "//*[@id = 'escape:needed,']"
    translate_selector("#escape\3Aneeded\,").should eq "//*[@id = 'escape:needed,']"
    translate_selector("#escape\3A needed\2C").should eq "//*[@id = 'escape:needed,']"
    translate_selector("#escape\00003Aneeded").should eq "//*[@id = 'escape:needed']"
  end

  it "pseudo_class_no_ident" do
    translate_selector(":link").should eq "//*[link(.)]"
  end

  it "pseudo_class" do
    translate_selector("a:link").should eq "//a[link(.)]"
    translate_selector("a:visited").should eq "//a[visited(.)]"
    translate_selector("a:hover").should eq "//a[hover(.)]"
    translate_selector("a:active").should eq "//a[active(.)]"
    translate_selector("a:active.foo").should eq "//a[active(.) and contains(concat(' ', normalize-space(@class), ' '), ' foo ')]"
  end

  it "significant_space" do
    translate_selector("x :first-child [a] [b]").should eq "//x//*[count(preceding-sibling::*) = 0]//*[@a]//*[@b]"
    translate_selector(" [a] [b]").should eq "//*[@a]//*[@b]"
  end

  it "star" do
    translate_selector("*").should eq "//*"
    translate_selector("*.pastoral").should eq "//*[contains(concat(' ', normalize-space(@class), ' '), ' pastoral ')]"
  end

  it "class" do
    translate_selector(".a.b").should eq "//*[contains(concat(' ', normalize-space(@class), ' '), ' a ') and contains(concat(' ', normalize-space(@class), ' '), ' b ')]"
    translate_selector(".awesome").should eq "//*[contains(concat(' ', normalize-space(@class), ' '), ' awesome ')]"
    translate_selector("foo.awesome").should eq "//foo[contains(concat(' ', normalize-space(@class), ' '), ' awesome ')]"
    translate_selector("foo .awesome").should eq "//foo//*[contains(concat(' ', normalize-space(@class), ' '), ' awesome ')]"
    translate_selector("foo .awe\\.some").should eq "//foo//*[contains(concat(' ', normalize-space(@class), ' '), ' awe.some ')]"
  end

  it "bare_not" do
    translate_selector(":not(.a)").should eq "//*[not(contains(concat(' ', normalize-space(@class), ' '), ' a '))]"
  end

  it "not_so_simple_not" do
    translate_selector("#p:not(.a)").should eq "//*[@id = 'p' and not(contains(concat(' ', normalize-space(@class), ' '), ' a '))]"
    translate_selector("p.a:not(.b)").should eq "//p[contains(concat(' ', normalize-space(@class), ' '), ' a ') and not(contains(concat(' ', normalize-space(@class), ' '), ' b '))]"
    translate_selector("p[a='foo']:not(.b)").should eq "//p[@a = 'foo' and not(contains(concat(' ', normalize-space(@class), ' '), ' b '))]"
  end

  it "multiple_not" do
    translate_selector("p:not(.a):not(.b):not(.c)").should eq "//p[not(contains(concat(' ', normalize-space(@class), ' '), ' a ')) and not(contains(concat(' ', normalize-space(@class), ' '), ' b ')) and not(contains(concat(' ', normalize-space(@class), ' '), ' c '))]"
  end

  it "ident" do
    translate_selector("x").should eq "//x"
  end

  it "parse_space" do
    translate_selector("x y").should eq "//x//y"
  end

  it "parse_descendant" do
    translate_selector("x > y").should eq "//x/y"
  end

  pending "parse_slash" do
    ## This is non standard CSS
    translate_selector("x/y").should eq "//x/y"
  end

  pending "parse_doubleslash" do
    ## This is non standard CSS
    translate_selector("x//y").should eq "//x//y"
  end

  pending "multi_path" do
    assert_xpath ["//x/y", "//y/z"], @parser.parse("x > y, y > z")
    assert_xpath ["//x/y", "//y/z"], @parser.parse("x > y,y > z")
  end

  pending "attributes_with_namespace" do
    ## Default namespace is not applied to attributes.
    ## So this must be @class, not @xmlns:class.
    assert_xpath "//xmlns:a[@class = 'bar']", @parser_with_ns.parse("a[class='bar']")
    assert_xpath "//xmlns:a[@hoge:class = 'bar']", @parser_with_ns.parse("a[hoge|class='bar']")
  end
end

struct XML::Node
  pending "#css" do
    it "finds nodes" do
      doc = doc()

      nodes = doc.css("people > person").as(NodeSet)
      nodes.size.should eq(2)

      nodes[0].name.should eq("person")
      nodes[0]["id"].should eq("1")

      nodes[1].name.should eq("person")
      nodes[1]["id"].should eq("2")

      nodes = doc.css_nodes("people > person")
      nodes.size.should eq(2)
    end

    it "raises on invalid css" do
      expect_raises XML::Error do
        doc = doc()
        doc.css("> foo")
      end
    end

    it "returns nil with invalid css" do
      doc = doc()
      doc.css_node(". invalid").should be_nil
    end

    it "finds with namespace" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
        </feed>
        ))
      nodes = doc.css("atom/feed", namespaces: {"atom" => "http://www.w3.org/2005/Atom"}).as(NodeSet)
      nodes.size.should eq(1)
      nodes[0].name.should eq("feed")
      ns = nodes[0].namespace.not_nil!
      ns.href.should eq("http://www.w3.org/2005/Atom")
      ns.prefix.should be_nil
    end

    it "finds with root namespaces" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
        </feed>
        ))
      nodes = doc.css("xmlns/feed", namespaces: doc.root.not_nil!.namespaces).as(NodeSet)
      nodes.size.should eq(1)
      nodes[0].name.should eq("feed")
      ns = nodes[0].namespace.not_nil!
      ns.href.should eq("http://www.w3.org/2005/Atom")
      ns.prefix.should be_nil
    end

    it "finds with variable binding" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed>
          <person id="1"/>
          <person id="2"/>
        </feed>
        ))
      nodes = doc.css("feed > person[id=$value]", variables: {"value" => 2}).as(NodeSet)
      nodes.size.should eq(1)
      nodes[0]["id"].should eq("2")
    end

    it "finds with variable binding (node)" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed>
          <person id="1"/>
          <person id="2"/>
        </feed>
        ))
      node = doc.css_node("feed > person[id=$value]", variables: {"value" => 2}).not_nil!
      node["id"].should eq("2")
    end
  end
end
