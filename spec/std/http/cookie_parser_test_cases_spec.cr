require "spec"
require "http/cookie"

private def it_parses_set_cookie(header, expected, *, string = header, file = __FILE__, line = __LINE__)
  it "parses #{header.inspect}", file: file, line: line do
    actual = HTTP::Cookie::Parser.parse_set_cookie(header)
    actual.should eq(expected)
    actual.try(&.to_set_cookie_header).should eq(string)
  end
end

describe "" do
  # 0001
  it_parses_set_cookie "foo=bar", HTTP::Cookie.new("foo", "bar")

  # 0002
  it_parses_set_cookie "foo=bar; Expires=Fri, 07 Aug 2019 08:04:19 GMT", HTTP::Cookie.new("foo", "bar")

  # 0003
  it_parses_set_cookie "foo=bar; Expires=Fri, 07 Aug 2007 08:04:19 GMT", HTTP::Cookie.new("foo2", "bar2")
  it_parses_set_cookie "foo2=bar2; Expires=Fri, 07 Aug 2017 08:04:19 GMT", nil

  # 0004
  it_parses_set_cookie "foo", nil

  # 0005
  it_parses_set_cookie "foo=bar; max-age=10000;", HTTP::Cookie.new("foo", "bar")

  # 0006
  it_parses_set_cookie "foo=bar; max-age=0;", nil

  # 0007
  it_parses_set_cookie "foo=bar; version=1;", HTTP::Cookie.new("foo", "bar")

  # 0008
  it_parses_set_cookie "foo=bar; version=1000;", HTTP::Cookie.new("foo", "bar")

  # 0009
  it_parses_set_cookie "foo=bar; customvalue=1000;", HTTP::Cookie.new("foo", "bar")

  # 0010
  it_parses_set_cookie "foo=bar; secure;", nil

  # 0011
  it_parses_set_cookie "foo=bar; customvalue=\"1000 or more\";", HTTP::Cookie.new("foo", "bar")

  # 0012
  it_parses_set_cookie "foo=bar; customvalue=\"no trailing semicolon\"", HTTP::Cookie.new("foo", "bar")

  # 0013
  it_parses_set_cookie "foo=bar", HTTP::Cookie.new("foo", "qux")
  it_parses_set_cookie "foo=qux", nil

  # 0014
  it_parses_set_cookie "foo1=bar", HTTP::Cookie.new("foo1", "bar")
  it_parses_set_cookie "foo2=qux", HTTP::Cookie.new("foo2", "qux")

  # 0015
  it_parses_set_cookie "a=b", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "z=y", HTTP::Cookie.new("z", "y")

  # 0016
  it_parses_set_cookie "z=y", HTTP::Cookie.new("z", "y")
  it_parses_set_cookie "a=b", HTTP::Cookie.new("a", "b")

  # 0017
  it_parses_set_cookie "z=y, a=b", HTTP::Cookie.new("z", "y, a=b")

  # 0018
  it_parses_set_cookie "z=y; foo=bar, a=b", HTTP::Cookie.new("z", "y")

  # 0019
  it_parses_set_cookie "foo=b;max-age=3600, c=d;path=/", HTTP::Cookie.new("foo", "b")

  # 0020
  it_parses_set_cookie "a=b", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "=", HTTP::Cookie.new("c", "d")
  it_parses_set_cookie "c=d", nil

  # 0021
  it_parses_set_cookie "a=b", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "=x", HTTP::Cookie.new("c", "d")
  it_parses_set_cookie "c=d", nil

  # 0022
  it_parses_set_cookie "a=b", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "x=", HTTP::Cookie.new("x", "")
  it_parses_set_cookie "c=d", HTTP::Cookie.new("c", "d")

  # 0023
  it_parses_set_cookie "foo", nil
  it_parses_set_cookie "", nil

  # 0024
  it_parses_set_cookie "foo", nil
  it_parses_set_cookie "=", nil

  # 0025
  it_parses_set_cookie "foo", nil
  it_parses_set_cookie "; bar", nil

  # 0026
  it_parses_set_cookie "foo", nil
  it_parses_set_cookie "   ", nil

  # 0027
  it_parses_set_cookie "foo", nil
  it_parses_set_cookie "bar", nil

  # 0028
  it_parses_set_cookie "foo", nil
  it_parses_set_cookie "\t", nil

  # ATTRIBUTE0001
  it_parses_set_cookie "foo=bar; Secure", nil

  # ATTRIBUTE0002
  it_parses_set_cookie "foo=bar; seCURe", nil

  # ATTRIBUTE0003
  it_parses_set_cookie "foo=bar; \"Secure\"", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0004
  it_parses_set_cookie "foo=bar; Secure=", nil

  # ATTRIBUTE0005
  it_parses_set_cookie "foo=bar; Secure=aaaa", nil

  # ATTRIBUTE0006
  it_parses_set_cookie "foo=bar; Secure qux", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0007
  it_parses_set_cookie "foo=bar; Secure =aaaaa", nil

  # ATTRIBUTE0008
  it_parses_set_cookie "foo=bar; Secure= aaaaa", nil

  # ATTRIBUTE0009
  it_parses_set_cookie "foo=bar; Secure; qux", nil

  # ATTRIBUTE0010
  it_parses_set_cookie "foo=bar; Secure;qux", nil

  # ATTRIBUTE0011
  it_parses_set_cookie "foo=bar; Secure    ; qux", nil

  # ATTRIBUTE0012
  it_parses_set_cookie "foo=bar;                Secure", nil

  # ATTRIBUTE0013
  it_parses_set_cookie "foo=bar;       Secure     ;", nil

  # ATTRIBUTE0014
  it_parses_set_cookie "foo=bar; Path", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0015
  it_parses_set_cookie "foo=bar; Path=", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0016
  it_parses_set_cookie "foo=bar; Path=/", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0017
  it_parses_set_cookie "foo=bar; Path=/qux", nil

  # ATTRIBUTE0018
  it_parses_set_cookie "foo=bar; Path    =/qux", nil

  # ATTRIBUTE0019
  it_parses_set_cookie "foo=bar; Path=    /qux", nil

  # ATTRIBUTE0020
  it_parses_set_cookie "foo=bar; Path=/qux      ; taz", nil

  # ATTRIBUTE0021
  it_parses_set_cookie "foo=bar; Path=/qux; Path=/", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0022
  it_parses_set_cookie "foo=bar; Path=/; Path=/qux", nil

  # ATTRIBUTE0023
  it_parses_set_cookie "foo=bar; Path=/qux; Path=/cookie-parser-result", HTTP::Cookie.new("foo", "bar")

  # ATTRIBUTE0024
  it_parses_set_cookie "foo=bar; Path=/cookie-parser-result; Path=/qux", nil

  # ATTRIBUTE0025
  it_parses_set_cookie "foo=bar; qux; Secure", nil

  # ATTRIBUTE0026
  it_parses_set_cookie "foo=bar; qux=\"aaa;bbb\"; Secure", nil

  # CHARSET0001
  it_parses_set_cookie "foo=春节回家路·春运完全手册", HTTP::Cookie.new("foo", "春节回家路·春运完全手册")

  # CHARSET0002
  it_parses_set_cookie "春节回=家路·春运完全手册", HTTP::Cookie.new("春节回", "家路·春运完全手册")

  # CHARSET0003
  it_parses_set_cookie "春节回=家路·春运; 完全手册", HTTP::Cookie.new("春节回", "家路·春运")

  # CHARSET0004
  it_parses_set_cookie "foo=\"春节回家路·春运完全手册\"", HTTP::Cookie.new("foo", "\"春节回家路·春运完全手册\"")

  # CHROMIUM0001
  it_parses_set_cookie "a=b", HTTP::Cookie.new("a", "b")

  # CHROMIUM0002
  it_parses_set_cookie "aBc=\"zzz \"   ;", HTTP::Cookie.new("aBc", "\"zzz \"")

  # CHROMIUM0003
  it_parses_set_cookie "aBc=\"zzz \" ;", HTTP::Cookie.new("aBc", "\"zzz \"")

  # CHROMIUM0004
  it_parses_set_cookie "aBc=\"zz;pp\" ; ;", HTTP::Cookie.new("aBc", "\"zz")

  # CHROMIUM0005
  it_parses_set_cookie "aBc=\"zz ;", HTTP::Cookie.new("aBc", "\"zz")

  # CHROMIUM0006
  it_parses_set_cookie "aBc=\"zzz \"   \"ppp\"  ;", HTTP::Cookie.new("aBc", "\"zzz \"   \"ppp\"")

  # CHROMIUM0007
  it_parses_set_cookie "aBc=\"zzz \"   \"ppp\" ;", HTTP::Cookie.new("aBc", "\"zzz \"   \"ppp\"")

  # CHROMIUM0008
  it_parses_set_cookie "aBc=A\"B ;", HTTP::Cookie.new("aBc", "A\"B")

  # CHROMIUM0009
  it_parses_set_cookie "BLAHHH; path=/;", nil

  # CHROMIUM0010
  it_parses_set_cookie "\"BLA\\\"HHH\"; path=/;", nil

  # CHROMIUM0011
  it_parses_set_cookie "a=\"B", HTTP::Cookie.new("a", "\"B")

  # CHROMIUM0012
  it_parses_set_cookie "=ABC", nil

  # CHROMIUM0013
  it_parses_set_cookie "ABC=;  path = /", HTTP::Cookie.new("ABC", "")

  # CHROMIUM0014
  it_parses_set_cookie "  A  = BC  ;foo;;;   bar", HTTP::Cookie.new("A", "BC")

  # CHROMIUM0015
  it_parses_set_cookie "  A=== BC  ;foo;;;   bar", HTTP::Cookie.new("A", "== BC")

  # CHROMIUM0016
  it_parses_set_cookie "foo=\"zohNumRKgI0oxyhSsV3Z7D\"  ; expires=Sun, 18-Apr-2027 21:06:29 GMT ; path=/  ;  ", HTTP::Cookie.new("foo", "\"zohNumRKgI0oxyhSsV3Z7D\"")

  # CHROMIUM0017
  it_parses_set_cookie "foo=zohNumRKgI0oxyhSsV3Z7D  ; expires=Sun, 18-Apr-2027 21:06:29 GMT ; path=/  ;  ", HTTP::Cookie.new("foo", "zohNumRKgI0oxyhSsV3Z7D")

  # CHROMIUM0018
  it_parses_set_cookie "    ", nil

  # CHROMIUM0019
  it_parses_set_cookie "a=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", HTTP::Cookie.new("a", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

  # CHROMIUM0021
  it_parses_set_cookie "", nil

  # COMMA0001
  it_parses_set_cookie "foo=bar, baz=qux", HTTP::Cookie.new("foo", "bar, baz=qux")

  # COMMA0002
  it_parses_set_cookie "foo=\"bar, baz=qux\"", HTTP::Cookie.new("foo", "\"bar, baz=qux\"")

  # COMMA0003
  it_parses_set_cookie "foo=bar; b,az=qux", HTTP::Cookie.new("foo", "bar")

  # COMMA0004
  it_parses_set_cookie "foo=bar; baz=q,ux", HTTP::Cookie.new("foo", "bar")

  # COMMA0005
  it_parses_set_cookie "foo=bar; Max-Age=50,399", HTTP::Cookie.new("foo", "bar")

  # COMMA0006
  it_parses_set_cookie "foo=bar; Expires=Fri, 07 Aug 2019 08:04:19 GMT", HTTP::Cookie.new("foo", "bar")

  # COMMA0007
  it_parses_set_cookie "foo=bar; Expires=Fri 07 Aug 2019 08:04:19 GMT, baz=qux", HTTP::Cookie.new("foo", "bar")

  # DISABLED_CHROMIUM0020
  it_parses_set_cookie "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", nil

  # DISABLED_CHROMIUM0022
  it_parses_set_cookie "AAA=BB\u0000ZYX", HTTP::Cookie.new("AAA", "BB")

  # DISABLED_CHROMIUM0023
  it_parses_set_cookie "AAA=BB\rZYX", HTTP::Cookie.new("AAA", "BB")

  # DISABLED_PATH0029
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/bar", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0001
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0002
  it_parses_set_cookie "foo=bar; domain=home.example.org", nil

  # DOMAIN0003
  it_parses_set_cookie "foo=bar; domain=.home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0004
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0005
  it_parses_set_cookie "foo=bar; domain=.home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0006
  it_parses_set_cookie "foo=bar; domain=.home.example.org", nil

  # DOMAIN0007
  it_parses_set_cookie "foo=bar; domain=sibling.example.org", nil

  # DOMAIN0008
  it_parses_set_cookie "foo=bar; domain=.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0009
  it_parses_set_cookie "foo=bar; domain=example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0010
  it_parses_set_cookie "foo=bar; domain=..home.example.org", nil

  # DOMAIN0011
  it_parses_set_cookie "foo=bar; domain=home..example.org", nil

  # DOMAIN0012
  it_parses_set_cookie "foo=bar; domain=  .home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0013
  it_parses_set_cookie "foo=bar; domain=  .  home.example.org", nil

  # DOMAIN0014
  it_parses_set_cookie "foo=bar; domain=home.example.org.", nil

  # DOMAIN0015
  it_parses_set_cookie "foo=bar; domain=home.example.org..", nil

  # DOMAIN0016
  it_parses_set_cookie "foo=bar; domain=home.example.org .", nil

  # DOMAIN0017
  it_parses_set_cookie "foo=bar; domain=.org", nil

  # DOMAIN0018
  it_parses_set_cookie "foo=bar; domain=.org.", nil

  # DOMAIN0019
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")
  it_parses_set_cookie "foo2=bar2; domain=.home.example.org", HTTP::Cookie.new("foo2", "bar2")

  # DOMAIN0020
  it_parses_set_cookie "foo2=bar2; domain=.home.example.org", HTTP::Cookie.new("foo2", "bar2")
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0021
  it_parses_set_cookie "foo=bar; domain=\"home.example.org\"", nil

  # DOMAIN0022
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")
  it_parses_set_cookie "foo2=bar2; domain=.example.org", HTTP::Cookie.new("foo2", "bar2")

  # DOMAIN0023
  it_parses_set_cookie "foo2=bar2; domain=.example.org", HTTP::Cookie.new("foo2", "bar2")
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0024
  it_parses_set_cookie "foo=bar; domain=.example.org; domain=home.example.org", nil

  # DOMAIN0025
  it_parses_set_cookie "foo=bar; domain=home.example.org; domain=.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0026
  it_parses_set_cookie "foo=bar; domain=home.eXaMpLe.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0027
  it_parses_set_cookie "foo=bar; domain=home.example.org:8888", nil

  # DOMAIN0028
  it_parses_set_cookie "foo=bar; domain=subdomain.home.example.org", nil

  # DOMAIN0029
  it_parses_set_cookie "foo=bar", nil

  # DOMAIN0031
  it_parses_set_cookie "foo=bar; domain=home.example.org; domain=.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0033
  it_parses_set_cookie "foo=bar; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0034
  it_parses_set_cookie "foo=bar; domain=home.example.org; domain=home.example.com", nil

  # DOMAIN0035
  it_parses_set_cookie "foo=bar; domain=home.example.com; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0036
  it_parses_set_cookie "foo=bar; domain=home.example.org; domain=home.example.com; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0037
  it_parses_set_cookie "foo=bar; domain=home.example.com; domain=home.example.org; domain=home.example.com", nil

  # DOMAIN0038
  it_parses_set_cookie "foo=bar; domain=home.example.org; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0039
  it_parses_set_cookie "foo=bar; domain=home.example.org; domain=example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0040
  it_parses_set_cookie "foo=bar; domain=example.org; domain=home.example.org", HTTP::Cookie.new("foo", "bar")

  # DOMAIN0041
  it_parses_set_cookie "foo=bar; domain=.sibling.example.org", nil

  # DOMAIN0042
  it_parses_set_cookie "foo=bar; domain=.sibling.home.example.org", nil

  # MOZILLA0001
  it_parses_set_cookie "foo=bar; max-age=-1", nil

  # MOZILLA0002
  it_parses_set_cookie "foo=bar; max-age=0", nil

  # MOZILLA0003
  it_parses_set_cookie "foo=bar; expires=Thu, 10 Apr 1980 16:33:12 GMT", nil

  # MOZILLA0004
  it_parses_set_cookie "foo=bar; max-age=60", HTTP::Cookie.new("foo", "bar")

  # MOZILLA0005
  it_parses_set_cookie "foo=bar; max-age=-20", nil

  # MOZILLA0006
  it_parses_set_cookie "foo=bar; max-age=60", HTTP::Cookie.new("foo", "bar")

  # MOZILLA0007
  it_parses_set_cookie "foo=bar; expires=Thu, 10 Apr 1980 16:33:12 GMT", nil

  # MOZILLA0008
  it_parses_set_cookie "foo=bar; max-age=60", HTTP::Cookie.new("foo", "bar")
  it_parses_set_cookie "foo1=bar; max-age=60", HTTP::Cookie.new("foo1", "bar")

  # MOZILLA0009
  it_parses_set_cookie "foo=bar; max-age=60", HTTP::Cookie.new("foo1", "bar")
  it_parses_set_cookie "foo1=bar; max-age=60", nil
  it_parses_set_cookie "foo=differentvalue; max-age=0", nil

  # MOZILLA0010
  it_parses_set_cookie "foo=bar; max-age=60", HTTP::Cookie.new("foo1", "bar")
  it_parses_set_cookie "foo1=bar; max-age=60", nil
  it_parses_set_cookie "foo=differentvalue; max-age=0", nil
  it_parses_set_cookie "foo2=evendifferentvalue; max-age=0", nil

  # MOZILLA0011
  it_parses_set_cookie "test=parser; domain=.parser.test; ;; ;=; ,,, ===,abc,=; abracadabra! max-age=20;=;;", nil

  # MOZILLA0012
  it_parses_set_cookie "test=\"fubar! = foo;bar\\\";\" parser; max-age=6", HTTP::Cookie.new("test", "\"fubar! = foo")
  it_parses_set_cookie "five; max-age=2.63,", nil

  # MOZILLA0013
  it_parses_set_cookie "test=kill; max-age=0", nil
  it_parses_set_cookie "five; max-age=0", nil

  # MOZILLA0014
  it_parses_set_cookie "six", nil

  # MOZILLA0015
  it_parses_set_cookie "six", nil
  it_parses_set_cookie "seven", nil

  # MOZILLA0016
  it_parses_set_cookie "six", nil
  it_parses_set_cookie "seven", nil
  it_parses_set_cookie " =eight", nil

  # MOZILLA0017
  it_parses_set_cookie "six", HTTP::Cookie.new("test", "six")
  it_parses_set_cookie "seven", nil
  it_parses_set_cookie " =eight", nil
  it_parses_set_cookie "test=six", nil

  # NAME0001
  it_parses_set_cookie "a=bar", HTTP::Cookie.new("a", "bar")

  # NAME0002
  it_parses_set_cookie "1=bar", HTTP::Cookie.new("1", "bar")

  # NAME0003
  it_parses_set_cookie "$=bar", HTTP::Cookie.new("$", "bar")

  # NAME0004
  it_parses_set_cookie "!a=bar", HTTP::Cookie.new("!a", "bar")

  # NAME0005
  it_parses_set_cookie "@a=bar", HTTP::Cookie.new("@a", "bar")

  # NAME0006
  it_parses_set_cookie "#a=bar", HTTP::Cookie.new("#a", "bar")

  # NAME0007
  it_parses_set_cookie "$a=bar", HTTP::Cookie.new("$a", "bar")

  # NAME0008
  it_parses_set_cookie "%a=bar", HTTP::Cookie.new("%a", "bar")

  # NAME0009
  it_parses_set_cookie "^a=bar", HTTP::Cookie.new("^a", "bar")

  # NAME0010
  it_parses_set_cookie "&a=bar", HTTP::Cookie.new("&a", "bar")

  # NAME0011
  it_parses_set_cookie "*a=bar", HTTP::Cookie.new("*a", "bar")

  # NAME0012
  it_parses_set_cookie "(a=bar", HTTP::Cookie.new("(a", "bar")

  # NAME0013
  it_parses_set_cookie ")a=bar", HTTP::Cookie.new(")a", "bar")

  # NAME0014
  it_parses_set_cookie "-a=bar", HTTP::Cookie.new("-a", "bar")

  # NAME0015
  it_parses_set_cookie "_a=bar", HTTP::Cookie.new("_a", "bar")

  # NAME0016
  it_parses_set_cookie "+=bar", HTTP::Cookie.new("+", "bar")

  # NAME0017
  it_parses_set_cookie "=a=bar", nil

  # NAME0018
  it_parses_set_cookie "a =bar", HTTP::Cookie.new("a", "bar")

  # NAME0019
  it_parses_set_cookie "\"a=bar", HTTP::Cookie.new("\"a", "bar")

  # NAME0020
  it_parses_set_cookie "\"a=b\"=bar", HTTP::Cookie.new("\"a", "b\"=bar")

  # NAME0021
  it_parses_set_cookie "\"a=b\"=bar", HTTP::Cookie.new("\"a", "qux")
  it_parses_set_cookie "\"a=qux", nil

  # NAME0022
  it_parses_set_cookie "   foo=bar", HTTP::Cookie.new("foo", "bar")

  # NAME0023
  it_parses_set_cookie "foo;bar=baz", nil

  # NAME0024
  it_parses_set_cookie "$Version=1; foo=bar", HTTP::Cookie.new("$Version", "1")

  # NAME0025
  it_parses_set_cookie "===a=bar", nil

  # NAME0026
  it_parses_set_cookie "foo=bar    ", HTTP::Cookie.new("foo", "bar")

  # NAME0027
  it_parses_set_cookie "foo=bar    ;", HTTP::Cookie.new("foo", "bar")

  # NAME0028
  it_parses_set_cookie "=a", nil

  # NAME0029
  it_parses_set_cookie "=", nil

  # NAME0030
  it_parses_set_cookie "foo bar=baz", HTTP::Cookie.new("foo bar", "baz")

  # NAME0031
  it_parses_set_cookie "\"foo;bar\"=baz", nil

  # NAME0032
  it_parses_set_cookie "\"foo\\\"bar;baz\"=qux", nil

  # NAME0033
  it_parses_set_cookie "=foo=bar", nil
  it_parses_set_cookie "aaa", nil

  # OPTIONAL_DOMAIN0030
  it_parses_set_cookie "foo=bar; domain=", HTTP::Cookie.new("foo", "bar")

  # OPTIONAL_DOMAIN0041
  it_parses_set_cookie "foo=bar; domain=example.org; domain=", HTTP::Cookie.new("foo", "bar")

  # OPTIONAL_DOMAIN0042
  it_parses_set_cookie "foo=bar; domain=foo.example.org; domain=", nil

  # OPTIONAL_DOMAIN0043
  it_parses_set_cookie "foo=bar; domain=foo.example.org; domain=", nil

  # ORDERING0001
  it_parses_set_cookie "key=val0;", HTTP::Cookie.new("key", "val5")
  it_parses_set_cookie "key=val1; path=/cookie-parser-result", HTTP::Cookie.new("key", "val1")
  it_parses_set_cookie "key=val2; path=/", HTTP::Cookie.new("key", "val2")
  it_parses_set_cookie "key=val3; path=/bar", HTTP::Cookie.new("key", "val4")
  it_parses_set_cookie "key=val4; domain=.example.org", nil
  it_parses_set_cookie "key=val5; domain=.example.org; path=/cookie-parser-result/foo", nil

  # PATH0001
  it_parses_set_cookie "a=b; path=/", HTTP::Cookie.new("x", "y")
  it_parses_set_cookie "x=y; path=/cookie-parser-result", HTTP::Cookie.new("a", "b")

  # PATH0002
  it_parses_set_cookie "a=b; path=/cookie-parser-result", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "x=y; path=/", HTTP::Cookie.new("x", "y")

  # PATH0003
  it_parses_set_cookie "x=y; path=/", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "a=b; path=/cookie-parser-result", HTTP::Cookie.new("x", "y")

  # PATH0004
  it_parses_set_cookie "x=y; path=/cookie-parser-result", HTTP::Cookie.new("x", "y")
  it_parses_set_cookie "a=b; path=/", HTTP::Cookie.new("a", "b")

  # PATH0005
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo", nil

  # PATH0006
  it_parses_set_cookie "foo=bar", HTTP::Cookie.new("foo", "bar")
  it_parses_set_cookie "foo=qux; path=/cookie-parser-result/foo", nil

  # PATH0007
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo", HTTP::Cookie.new("foo", "bar")

  # PATH0008
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo", nil

  # PATH0009
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux", nil

  # PATH0010
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux", HTTP::Cookie.new("foo", "bar")

  # PATH0011
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux", nil

  # PATH0012
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux", nil

  # PATH0013
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux/", nil

  # PATH0014
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux/", nil

  # PATH0015
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux/", HTTP::Cookie.new("foo", "bar")

  # PATH0016
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/", HTTP::Cookie.new("foo", "bar")

  # PATH0017
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/", HTTP::Cookie.new("foo", "bar")

  # PATH0018
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/", nil

  # PATH0019
  it_parses_set_cookie "foo=bar; path", HTTP::Cookie.new("foo", "bar")

  # PATH0020
  it_parses_set_cookie "foo=bar; path=", HTTP::Cookie.new("foo", "bar")

  # PATH0021
  it_parses_set_cookie "foo=bar; path=/", HTTP::Cookie.new("foo", "bar")

  # PATH0022
  it_parses_set_cookie "foo=bar; path= /", HTTP::Cookie.new("foo", "bar")

  # PATH0023
  it_parses_set_cookie "foo=bar; Path=/cookie-PARSER-result", nil

  # PATH0024
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux?", nil

  # PATH0025
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux#", nil

  # PATH0026
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/foo/qux;", HTTP::Cookie.new("foo", "bar")

  # PATH0027
  it_parses_set_cookie "foo=bar; path=\"/cookie-parser-result/foo/qux;\"", HTTP::Cookie.new("foo", "bar")

  # PATH0028
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result/f%6Fo/bar", nil

  # PATH0029
  it_parses_set_cookie "a=b; \tpath\t=\t/cookie-parser-result\t", HTTP::Cookie.new("a", "b")
  it_parses_set_cookie "x=y; \tpath\t=\t/book\t", nil

  # PATH0030
  it_parses_set_cookie "foo=bar; path=/dog; path=", HTTP::Cookie.new("foo", "bar")

  # PATH0031
  it_parses_set_cookie "foo=bar; path=; path=/dog", nil

  # PATH0032
  it_parses_set_cookie "foo=bar; path=/cookie-parser-result", HTTP::Cookie.new("foo", "qux")
  it_parses_set_cookie "foo=qux; path=/cookie-parser-result/", HTTP::Cookie.new("foo", "bar")

  # VALUE0001
  it_parses_set_cookie "foo=  bar", HTTP::Cookie.new("foo", "bar")

  # VALUE0002
  it_parses_set_cookie "foo=\"bar\"", HTTP::Cookie.new("foo", "\"bar\"")

  # VALUE0003
  it_parses_set_cookie "foo=\"  bar \"", HTTP::Cookie.new("foo", "\"  bar \"")

  # VALUE0004
  it_parses_set_cookie "foo=\"bar;baz\"", HTTP::Cookie.new("foo", "\"bar")

  # VALUE0005
  it_parses_set_cookie "foo=\"bar=baz\"", HTTP::Cookie.new("foo", "\"bar=baz\"")

  # VALUE0006
  it_parses_set_cookie "\tfoo\t=\tbar\t \t;\tttt", HTTP::Cookie.new("foo", "bar")

end
