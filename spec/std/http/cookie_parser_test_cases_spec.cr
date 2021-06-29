require "spec"
require "http"

def it_receives_cookies(name, received, sent, sent_raw, *, file = __FILE__, line = __LINE__)
  it name, file: file, line: line do
    headers = HTTP::Headers.new
    headers.add "Set-Cookie", received

    cookies = HTTP::Cookies.from_server_headers(headers)
    cookies.size.should eq sent.size
    cookies.zip(sent) do |actual, expected|
      if expected
        actual = actual.should be_a(HTTP::Cookie)
        actual.name.should eq expected[0]
        actual.value.should eq expected[1]
      else
        actual.should be_nil
      end
    end
    headers.clear
    cookies.add_request_headers(headers)
    headers.fetch("Cookie", "").should eq sent_raw
  end
end

describe "foo" do
  it_receives_cookies "0001", ["foo=bar"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0002", ["foo=bar; Expires=Fri, 07 Aug 2019 08:04:19 GMT"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0003", ["foo=bar; Expires=Fri, 07 Aug 2007 08:04:19 GMT", "foo2=bar2; Expires=Fri, 07 Aug 2017 08:04:19 GMT"], [{"foo2", "bar2"}], "foo2=bar2"

  it_receives_cookies "0004", ["foo"], [] of Nil, ""

  it_receives_cookies "0005", ["foo=bar; max-age=10000;"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0006", ["foo=bar; max-age=0;"], [] of Nil, ""

  it_receives_cookies "0007", ["foo=bar; version=1;"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0008", ["foo=bar; version=1000;"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0009", ["foo=bar; customvalue=1000;"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0010", ["foo=bar; secure;"], [] of Nil, ""

  it_receives_cookies "0011", ["foo=bar; customvalue=\"1000 or more\";"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0012", ["foo=bar; customvalue=\"no trailing semicolon\""], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "0013", ["foo=bar", "foo=qux"], [{"foo", "qux"}], "foo=qux"

  it_receives_cookies "0014", ["foo1=bar", "foo2=qux"], [{"foo1", "bar"}, {"foo2", "qux"}], "foo1=bar; foo2=qux"

  it_receives_cookies "0015", ["a=b", "z=y"], [{"a", "b"}, {"z", "y"}], "a=b; z=y"

  it_receives_cookies "0016", ["z=y", "a=b"], [{"z", "y"}, {"a", "b"}], "z=y; a=b"

  # it_receives_cookies "0017", ["z=y, a=b"], [{"z", "y, a=b", skip_validation: true}], "z=y, a=b"

  it_receives_cookies "0018", ["z=y; foo=bar, a=b"], [{"z", "y"}], "z=y"

  it_receives_cookies "0019", ["foo=b;max-age=3600, c=d;path=/"], [{"foo", "b"}], "foo=b"

  it_receives_cookies "0020", ["a=b", "=", "c=d"], [{"a", "b"}, {"c", "d"}], "a=b; c=d"

  it_receives_cookies "0021", ["a=b", "=x", "c=d"], [{"a", "b"}, {"c", "d"}], "a=b; c=d"

  it_receives_cookies "0022", ["a=b", "x=", "c=d"], [{"a", "b"}, {"x", ""}, {"c", "d"}], "a=b; x=; c=d"

  it_receives_cookies "0023", ["foo", ""], [] of Nil, ""

  it_receives_cookies "0024", ["foo", "="], [] of Nil, ""

  it_receives_cookies "0025", ["foo", "; bar"], [] of Nil, ""

  it_receives_cookies "0026", ["foo", "   "], [] of Nil, ""

  it_receives_cookies "0027", ["foo", "bar"], [] of Nil, ""

  it_receives_cookies "0028", ["foo", "\t"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0001", ["foo=bar; Secure"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0002", ["foo=bar; seCURe"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0003", ["foo=bar; \"Secure\""], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0004", ["foo=bar; Secure="], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0005", ["foo=bar; Secure=aaaa"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0006", ["foo=bar; Secure qux"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0007", ["foo=bar; Secure =aaaaa"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0008", ["foo=bar; Secure= aaaaa"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0009", ["foo=bar; Secure; qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0010", ["foo=bar; Secure;qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0011", ["foo=bar; Secure    ; qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0012", ["foo=bar;                Secure"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0013", ["foo=bar;       Secure     ;"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0014", ["foo=bar; Path"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0015", ["foo=bar; Path="], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0016", ["foo=bar; Path=/"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0017", ["foo=bar; Path=/qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0018", ["foo=bar; Path    =/qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0019", ["foo=bar; Path=    /qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0020", ["foo=bar; Path=/qux      ; taz"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0021", ["foo=bar; Path=/qux; Path=/"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0022", ["foo=bar; Path=/; Path=/qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0023", ["foo=bar; Path=/qux; Path=/cookie-parser-result"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "ATTRIBUTE0024", ["foo=bar; Path=/cookie-parser-result; Path=/qux"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0025", ["foo=bar; qux; Secure"], [] of Nil, ""

  it_receives_cookies "ATTRIBUTE0026", ["foo=bar; qux=\"aaa;bbb\"; Secure"], [] of Nil, ""

  it_receives_cookies "CHARSET0001", ["foo=春节回家路·春运完全手册"], [{"foo", "春节回家路·春运完全手册"}], "foo=春节回家路·春运完全手册"

  it_receives_cookies "CHARSET0002", ["春节回=家路·春运完全手册"], [{"春节回", "家路·春运完全手册"}], "春节回=家路·春运完全手册"

  it_receives_cookies "CHARSET0003", ["春节回=家路·春运; 完全手册"], [{"春节回", "家路·春运"}], "春节回=家路·春运"

  it_receives_cookies "CHARSET0004", ["foo=\"春节回家路·春运完全手册\""], [{"foo", "\"春节回家路·春运完全手册\""}], "foo=\"春节回家路·春运完全手册\""

  it_receives_cookies "CHROMIUM0001", ["a=b"], [{"a", "b"}], "a=b"

  it_receives_cookies "CHROMIUM0002", ["aBc=\"zzz \"   ;"], [{"aBc", "\"zzz \""}], "aBc=\"zzz \""

  it_receives_cookies "CHROMIUM0003", ["aBc=\"zzz \" ;"], [{"aBc", "\"zzz \""}], "aBc=\"zzz \""

  it_receives_cookies "CHROMIUM0004", ["aBc=\"zz;pp\" ; ;"], [{"aBc", "\"zz"}], "aBc=\"zz"

  it_receives_cookies "CHROMIUM0005", ["aBc=\"zz ;"], [{"aBc", "\"zz"}], "aBc=\"zz"

  it_receives_cookies "CHROMIUM0006", ["aBc=\"zzz \"   \"ppp\"  ;"], [{"aBc", "\"zzz \"   \"ppp\""}], "aBc=\"zzz \"   \"ppp\""

  it_receives_cookies "CHROMIUM0007", ["aBc=\"zzz \"   \"ppp\" ;"], [{"aBc", "\"zzz \"   \"ppp\""}], "aBc=\"zzz \"   \"ppp\""

  it_receives_cookies "CHROMIUM0008", ["aBc=A\"B ;"], [{"aBc", "A\"B"}], "aBc=A\"B"

  it_receives_cookies "CHROMIUM0009", ["BLAHHH; path=/;"], [] of Nil, ""

  it_receives_cookies "CHROMIUM0010", ["\"BLA\\\"HHH\"; path=/;"], [] of Nil, ""

  it_receives_cookies "CHROMIUM0011", ["a=\"B"], [{"a", "\"B"}], "a=\"B"

  it_receives_cookies "CHROMIUM0012", ["=ABC"], [] of Nil, ""

  it_receives_cookies "CHROMIUM0013", ["ABC=;  path = /"], [{"ABC", ""}], "ABC="

  it_receives_cookies "CHROMIUM0014", ["  A  = BC  ;foo;;;   bar"], [{"A", "BC"}], "A=BC"

  it_receives_cookies "CHROMIUM0015", ["  A=== BC  ;foo;;;   bar"], [{"A", "== BC"}], "A=== BC"

  it_receives_cookies "CHROMIUM0016", ["foo=\"zohNumRKgI0oxyhSsV3Z7D\"  ; expires=Sun, 18-Apr-2027 21:06:29 GMT ; path=/  ;  "], [{"foo", "\"zohNumRKgI0oxyhSsV3Z7D\""}], "foo=\"zohNumRKgI0oxyhSsV3Z7D\""

  it_receives_cookies "CHROMIUM0017", ["foo=zohNumRKgI0oxyhSsV3Z7D  ; expires=Sun, 18-Apr-2027 21:06:29 GMT ; path=/  ;  "], [{"foo", "zohNumRKgI0oxyhSsV3Z7D"}], "foo=zohNumRKgI0oxyhSsV3Z7D"

  it_receives_cookies "CHROMIUM0018", ["    "], [] of Nil, ""

  it_receives_cookies "CHROMIUM0019", ["a=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"], [{"a", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}], "a=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  it_receives_cookies "CHROMIUM0021", [""], [] of Nil, ""

  it_receives_cookies "COMMA0001", ["foo=bar, baz=qux"], [{"foo", "bar, baz=qux"}], "foo=bar, baz=qux"

  it_receives_cookies "COMMA0002", ["foo=\"bar, baz=qux\""], [{"foo", "\"bar, baz=qux\""}], "foo=\"bar, baz=qux\""

  it_receives_cookies "COMMA0003", ["foo=bar; b,az=qux"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "COMMA0004", ["foo=bar; baz=q,ux"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "COMMA0005", ["foo=bar; Max-Age=50,399"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "COMMA0006", ["foo=bar; Expires=Fri, 07 Aug 2019 08:04:19 GMT"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "COMMA0007", ["foo=bar; Expires=Fri 07 Aug 2019 08:04:19 GMT, baz=qux"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DISABLED_CHROMIUM0020", ["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"], [] of Nil, ""

  it_receives_cookies "DISABLED_CHROMIUM0022", ["AAA=BB\u0000ZYX"], [{"AAA", "BB"}], "AAA=BB"

  it_receives_cookies "DISABLED_CHROMIUM0023", ["AAA=BB\rZYX"], [{"AAA", "BB"}], "AAA=BB"

  it_receives_cookies "DISABLED_PATH0029", ["foo=bar; path=/cookie-parser-result/foo/bar"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0001", ["foo=bar; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0002", ["foo=bar; domain=home.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0003", ["foo=bar; domain=.home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0004", ["foo=bar; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0005", ["foo=bar; domain=.home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0006", ["foo=bar; domain=.home.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0007", ["foo=bar; domain=sibling.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0008", ["foo=bar; domain=.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0009", ["foo=bar; domain=example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0010", ["foo=bar; domain=..home.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0011", ["foo=bar; domain=home..example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0012", ["foo=bar; domain=  .home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0013", ["foo=bar; domain=  .  home.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0014", ["foo=bar; domain=home.example.org."], [] of Nil, ""

  it_receives_cookies "DOMAIN0015", ["foo=bar; domain=home.example.org.."], [] of Nil, ""

  it_receives_cookies "DOMAIN0016", ["foo=bar; domain=home.example.org ."], [] of Nil, ""

  it_receives_cookies "DOMAIN0017", ["foo=bar; domain=.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0018", ["foo=bar; domain=.org."], [] of Nil, ""

  it_receives_cookies "DOMAIN0019", ["foo=bar; domain=home.example.org", "foo2=bar2; domain=.home.example.org"], [{"foo", "bar"}, {"foo2", "bar2"}], "foo=bar; foo2=bar2"

  it_receives_cookies "DOMAIN0020", ["foo2=bar2; domain=.home.example.org", "foo=bar; domain=home.example.org"], [{"foo2", "bar2"}, {"foo", "bar"}], "foo2=bar2; foo=bar"

  it_receives_cookies "DOMAIN0021", ["foo=bar; domain=\"home.example.org\""], [] of Nil, ""

  it_receives_cookies "DOMAIN0022", ["foo=bar; domain=home.example.org", "foo2=bar2; domain=.example.org"], [{"foo", "bar"}, {"foo2", "bar2"}], "foo=bar; foo2=bar2"

  it_receives_cookies "DOMAIN0023", ["foo2=bar2; domain=.example.org", "foo=bar; domain=home.example.org"], [{"foo2", "bar2"}, {"foo", "bar"}], "foo2=bar2; foo=bar"

  it_receives_cookies "DOMAIN0024", ["foo=bar; domain=.example.org; domain=home.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0025", ["foo=bar; domain=home.example.org; domain=.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0026", ["foo=bar; domain=home.eXaMpLe.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0027", ["foo=bar; domain=home.example.org:8888"], [] of Nil, ""

  it_receives_cookies "DOMAIN0028", ["foo=bar; domain=subdomain.home.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0029", ["foo=bar"], [] of Nil, ""

  it_receives_cookies "DOMAIN0031", ["foo=bar; domain=home.example.org; domain=.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0033", ["foo=bar; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0034", ["foo=bar; domain=home.example.org; domain=home.example.com"], [] of Nil, ""

  it_receives_cookies "DOMAIN0035", ["foo=bar; domain=home.example.com; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0036", ["foo=bar; domain=home.example.org; domain=home.example.com; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0037", ["foo=bar; domain=home.example.com; domain=home.example.org; domain=home.example.com"], [] of Nil, ""

  it_receives_cookies "DOMAIN0038", ["foo=bar; domain=home.example.org; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0039", ["foo=bar; domain=home.example.org; domain=example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0040", ["foo=bar; domain=example.org; domain=home.example.org"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "DOMAIN0041", ["foo=bar; domain=.sibling.example.org"], [] of Nil, ""

  it_receives_cookies "DOMAIN0042", ["foo=bar; domain=.sibling.home.example.org"], [] of Nil, ""

  it_receives_cookies "MOZILLA0001", ["foo=bar; max-age=-1"], [] of Nil, ""

  it_receives_cookies "MOZILLA0002", ["foo=bar; max-age=0"], [] of Nil, ""

  it_receives_cookies "MOZILLA0003", ["foo=bar; expires=Thu, 10 Apr 1980 16:33:12 GMT"], [] of Nil, ""

  it_receives_cookies "MOZILLA0004", ["foo=bar; max-age=60"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "MOZILLA0005", ["foo=bar; max-age=-20"], [] of Nil, ""

  it_receives_cookies "MOZILLA0006", ["foo=bar; max-age=60"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "MOZILLA0007", ["foo=bar; expires=Thu, 10 Apr 1980 16:33:12 GMT"], [] of Nil, ""

  it_receives_cookies "MOZILLA0008", ["foo=bar; max-age=60", "foo1=bar; max-age=60"], [{"foo", "bar"}, {"foo1", "bar"}], "foo=bar; foo1=bar"

  it_receives_cookies "MOZILLA0009", ["foo=bar; max-age=60", "foo1=bar; max-age=60", "foo=differentvalue; max-age=0"], [{"foo1", "bar"}], "foo1=bar"

  it_receives_cookies "MOZILLA0010", ["foo=bar; max-age=60", "foo1=bar; max-age=60", "foo=differentvalue; max-age=0", "foo2=evendifferentvalue; max-age=0"], [{"foo1", "bar"}], "foo1=bar"

  it_receives_cookies "MOZILLA0011", ["test=parser; domain=.parser.test; ;; ;=; ,,, ===,abc,=; abracadabra! max-age=20;=;;"], [] of Nil, ""

  it_receives_cookies "MOZILLA0012", ["test=\"fubar! = foo;bar\\\";\" parser; max-age=6", "five; max-age=2.63,"], [{"test", "\"fubar! = foo"}], "test=\"fubar! = foo"

  it_receives_cookies "MOZILLA0013", ["test=kill; max-age=0", "five; max-age=0"], [] of Nil, ""

  it_receives_cookies "MOZILLA0014", ["six"], [] of Nil, ""

  it_receives_cookies "MOZILLA0015", ["six", "seven"], [] of Nil, ""

  it_receives_cookies "MOZILLA0016", ["six", "seven", " =eight"], [] of Nil, ""

  it_receives_cookies "MOZILLA0017", ["six", "seven", " =eight", "test=six"], [{"test", "six"}], "test=six"

  it_receives_cookies "NAME0001", ["a=bar"], [{"a", "bar"}], "a=bar"

  it_receives_cookies "NAME0002", ["1=bar"], [{"1", "bar"}], "1=bar"

  it_receives_cookies "NAME0003", ["$=bar"], [{"$", "bar"}], "$=bar"

  it_receives_cookies "NAME0004", ["!a=bar"], [{"!a", "bar"}], "!a=bar"

  it_receives_cookies "NAME0005", ["@a=bar"], [{"@a", "bar"}], "@a=bar"

  it_receives_cookies "NAME0006", ["#a=bar"], [{"#a", "bar"}], "#a=bar"

  it_receives_cookies "NAME0007", ["$a=bar"], [{"$a", "bar"}], "$a=bar"

  it_receives_cookies "NAME0008", ["%a=bar"], [{"%a", "bar"}], "%a=bar"

  it_receives_cookies "NAME0009", ["^a=bar"], [{"^a", "bar"}], "^a=bar"

  it_receives_cookies "NAME0010", ["&a=bar"], [{"&a", "bar"}], "&a=bar"

  it_receives_cookies "NAME0011", ["*a=bar"], [{"*a", "bar"}], "*a=bar"

  it_receives_cookies "NAME0012", ["(a=bar"], [{"(a", "bar"}], "(a=bar"

  it_receives_cookies "NAME0013", [")a=bar"], [{")a", "bar"}], ")a=bar"

  it_receives_cookies "NAME0014", ["-a=bar"], [{"-a", "bar"}], "-a=bar"

  it_receives_cookies "NAME0015", ["_a=bar"], [{"_a", "bar"}], "_a=bar"

  it_receives_cookies "NAME0016", ["+=bar"], [{"+", "bar"}], "+=bar"

  it_receives_cookies "NAME0017", ["=a=bar"], [] of Nil, ""

  it_receives_cookies "NAME0018", ["a =bar"], [{"a", "bar"}], "a=bar"

  it_receives_cookies "NAME0019", ["\"a=bar"], [{"\"a", "bar"}], "\"a=bar"

  it_receives_cookies "NAME0020", ["\"a=b\"=bar"], [{"\"a", "b\"=bar"}], "\"a=b\"=bar"

  it_receives_cookies "NAME0021", ["\"a=b\"=bar", "\"a=qux"], [{"\"a", "qux"}], "\"a=qux"

  it_receives_cookies "NAME0022", ["   foo=bar"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "NAME0023", ["foo;bar=baz"], [] of Nil, ""

  it_receives_cookies "NAME0024", ["$Version=1; foo=bar"], [{"$Version", "1"}], "$Version=1"

  it_receives_cookies "NAME0025", ["===a=bar"], [] of Nil, ""

  it_receives_cookies "NAME0026", ["foo=bar    "], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "NAME0027", ["foo=bar    ;"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "NAME0028", ["=a"], [] of Nil, ""

  it_receives_cookies "NAME0029", ["="], [] of Nil, ""

  it_receives_cookies "NAME0030", ["foo bar=baz"], [{"foo bar", "baz"}], "foo bar=baz"

  it_receives_cookies "NAME0031", ["\"foo;bar\"=baz"], [] of Nil, ""

  it_receives_cookies "NAME0032", ["\"foo\\\"bar;baz\"=qux"], [] of Nil, ""

  it_receives_cookies "NAME0033", ["=foo=bar", "aaa"], [] of Nil, ""

  it_receives_cookies "OPTIONAL_DOMAIN0030", ["foo=bar; domain="], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "OPTIONAL_DOMAIN0041", ["foo=bar; domain=example.org; domain="], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "OPTIONAL_DOMAIN0042", ["foo=bar; domain=foo.example.org; domain="], [] of Nil, ""

  it_receives_cookies "OPTIONAL_DOMAIN0043", ["foo=bar; domain=foo.example.org; domain="], [] of Nil, ""

  it_receives_cookies "ORDERING0001", ["key=val0;", "key=val1; path=/cookie-parser-result", "key=val2; path=/", "key=val3; path=/bar", "key=val4; domain=.example.org", "key=val5; domain=.example.org; path=/cookie-parser-result/foo"], [{"key", "val5"}, {"key", "val1"}, {"key", "val2"}, {"key", "val4"}], "key=val5; key=val1; key=val2; key=val4"

  it_receives_cookies "PATH0001", ["a=b; path=/", "x=y; path=/cookie-parser-result"], [{"x", "y"}, {"a", "b"}], "x=y; a=b"

  it_receives_cookies "PATH0002", ["a=b; path=/cookie-parser-result", "x=y; path=/"], [{"a", "b"}, {"x", "y"}], "a=b; x=y"

  it_receives_cookies "PATH0003", ["x=y; path=/", "a=b; path=/cookie-parser-result"], [{"a", "b"}, {"x", "y"}], "a=b; x=y"

  it_receives_cookies "PATH0004", ["x=y; path=/cookie-parser-result", "a=b; path=/"], [{"x", "y"}, {"a", "b"}], "x=y; a=b"

  it_receives_cookies "PATH0005", ["foo=bar; path=/cookie-parser-result/foo"], [] of Nil, ""

  it_receives_cookies "PATH0006", ["foo=bar", "foo=qux; path=/cookie-parser-result/foo"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0007", ["foo=bar; path=/cookie-parser-result/foo"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0008", ["foo=bar; path=/cookie-parser-result/foo"], [] of Nil, ""

  it_receives_cookies "PATH0009", ["foo=bar; path=/cookie-parser-result/foo/qux"], [] of Nil, ""

  it_receives_cookies "PATH0010", ["foo=bar; path=/cookie-parser-result/foo/qux"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0011", ["foo=bar; path=/cookie-parser-result/foo/qux"], [] of Nil, ""

  it_receives_cookies "PATH0012", ["foo=bar; path=/cookie-parser-result/foo/qux"], [] of Nil, ""

  it_receives_cookies "PATH0013", ["foo=bar; path=/cookie-parser-result/foo/qux/"], [] of Nil, ""

  it_receives_cookies "PATH0014", ["foo=bar; path=/cookie-parser-result/foo/qux/"], [] of Nil, ""

  it_receives_cookies "PATH0015", ["foo=bar; path=/cookie-parser-result/foo/qux/"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0016", ["foo=bar; path=/cookie-parser-result/foo/"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0017", ["foo=bar; path=/cookie-parser-result/foo/"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0018", ["foo=bar; path=/cookie-parser-result/foo/"], [] of Nil, ""

  it_receives_cookies "PATH0019", ["foo=bar; path"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0020", ["foo=bar; path="], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0021", ["foo=bar; path=/"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0022", ["foo=bar; path= /"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0023", ["foo=bar; Path=/cookie-PARSER-result"], [] of Nil, ""

  it_receives_cookies "PATH0024", ["foo=bar; path=/cookie-parser-result/foo/qux?"], [] of Nil, ""

  it_receives_cookies "PATH0025", ["foo=bar; path=/cookie-parser-result/foo/qux#"], [] of Nil, ""

  it_receives_cookies "PATH0026", ["foo=bar; path=/cookie-parser-result/foo/qux;"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0027", ["foo=bar; path=\"/cookie-parser-result/foo/qux;\""], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0028", ["foo=bar; path=/cookie-parser-result/f%6Fo/bar"], [] of Nil, ""

  it_receives_cookies "PATH0029", ["a=b; \tpath\t=\t/cookie-parser-result\t", "x=y; \tpath\t=\t/book\t"], [{"a", "b"}], "a=b"

  it_receives_cookies "PATH0030", ["foo=bar; path=/dog; path="], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "PATH0031", ["foo=bar; path=; path=/dog"], [] of Nil, ""

  it_receives_cookies "PATH0032", ["foo=bar; path=/cookie-parser-result", "foo=qux; path=/cookie-parser-result/"], [{"foo", "qux"}, {"foo", "bar"}], "foo=qux; foo=bar"

  it_receives_cookies "VALUE0001", ["foo=  bar"], [{"foo", "bar"}], "foo=bar"

  it_receives_cookies "VALUE0002", ["foo=\"bar\""], [{"foo", "\"bar\""}], "foo=\"bar\""

  it_receives_cookies "VALUE0003", ["foo=\"  bar \""], [{"foo", "\"  bar \""}], "foo=\"  bar \""

  it_receives_cookies "VALUE0004", ["foo=\"bar;baz\""], [{"foo", "\"bar"}], "foo=\"bar"

  it_receives_cookies "VALUE0005", ["foo=\"bar=baz\""], [{"foo", "\"bar=baz\""}], "foo=\"bar=baz\""

  it_receives_cookies "VALUE0006", ["\tfoo\t=\tbar\t \t;\tttt"], [{"foo", "bar"}], "foo=bar"

end
