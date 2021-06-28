require "spec"
require "http/cookie"

private def parse_set_cookie(header)
  cookie = HTTP::Cookie::Parser.parse_set_cookie(header)
  cookie.should_not be_nil
end

private def it_parses_cookies(header, expected, *, string = header, file = __FILE__, line = __LINE__)
  if expected.is_a?(HTTP::Cookie)
    expected = [expected]
  end
  it "parses #{header.inspect}", file: file, line: line do
    actual = HTTP::Cookie::Parser.parse_cookies(header)
    actual.should eq(expected)
    actual.join("; ", &.to_set_cookie_header).should eq(string)
  end
end

private def it_parses_set_cookie(header, expected, *, string = header, file = __FILE__, line = __LINE__)
  it "parses #{header.inspect}", file: file, line: line do
    actual = HTTP::Cookie::Parser.parse_set_cookie(header)
    actual.should eq(expected)
    actual.try(&.to_set_cookie_header).should eq(string)
  end
end

describe HTTP::Cookie::Parser do
  describe ".parse_cookies" do
    it_parses_cookies "key=value", HTTP::Cookie.new("key", "value")
    it_parses_cookies "key=", HTTP::Cookie.new("key", "")
    it_parses_cookies "key=key=value", HTTP::Cookie.new("key", "key=value")
    it_parses_cookies "key=key%3Dvalue", HTTP::Cookie.new("key", "key%3Dvalue")
    it_parses_cookies "key%3Dvalue=value", HTTP::Cookie.new("key%3Dvalue", "value")
    it_parses_cookies %(key="value"), HTTP::Cookie.new("key", "value"), string: "key=value"
    it_parses_cookies "foo=bar; foobar=baz", [HTTP::Cookie.new("foo", "bar"), HTTP::Cookie.new("foobar", "baz")]
  end

  describe ".parse_set_cookie" do
    it "parse_set_cookie with space" do
      cookie = parse_set_cookie("key=value; path=/test")
      parse_set_cookie("key=value;path=/test").should eq cookie
      parse_set_cookie("key=value;  \t\npath=/test").should eq cookie
    end

    it_parses_set_cookie "key=value; path=/test", HTTP::Cookie.new("key", "value", path: "/test")

    it_parses_set_cookie "key=value; Secure", HTTP::Cookie.new("key", "value", secure: true)

    it_parses_set_cookie "key=value; HttpOnly", HTTP::Cookie.new("key", "value", http_only: true)

    describe "SameSite" do
      it_parses_set_cookie "key=value; SameSite=Lax", HTTP::Cookie.new("key", "value", samesite: :lax)
      it_parses_set_cookie "key=value; SameSite=Strict", HTTP::Cookie.new("key", "value", samesite: :strict)
      it_parses_set_cookie "key=value; SameSite=None", HTTP::Cookie.new("key", "value", samesite: :none)
      it_parses_set_cookie "key=value; SameSite=Foo", HTTP::Cookie.new("key", "value", samesite: nil), string: "key=value"
    end

    it_parses_set_cookie "key=value; domain=www.example.com", HTTP::Cookie.new("key", "value", domain: "www.example.com")

    describe "expires" do
      it_parses_set_cookie "key=value; expires=Sun, 06-Nov-1994 08:49:37 GMT", HTTP::Cookie.new("key", "value", expires: Time.utc(1994, 11, 6, 8, 49, 37)), string: "key=value; expires=Sun, 06 Nov 1994 08:49:37 GMT"
      it_parses_set_cookie "key=value; expires=Sun, 06 Nov 1994 08:49:37 GMT", HTTP::Cookie.new("key", "value", expires: Time.utc(1994, 11, 6, 8, 49, 37))
      it_parses_set_cookie "key=value; expires=Sunday, 06-Nov-94 08:49:37 GMT", HTTP::Cookie.new("key", "value", expires: Time.utc(1994, 11, 6, 8, 49, 37)), string: "key=value; expires=Sun, 06 Nov 1994 08:49:37 GMT"
      it_parses_set_cookie "key=value; expires=Sun Nov  6 08:49:37 1994", HTTP::Cookie.new("key", "value", expires: Time.utc(1994, 11, 6, 8, 49, 37)), string: "key=value; expires=Sun, 06 Nov 1994 08:49:37 GMT"
      it_parses_set_cookie "key=value; expires=Thu, 01 Jan 1970 00:00:00 -0000", HTTP::Cookie.new("key", "value", expires: Time.utc(1970, 1, 1, 0, 0, 0)), string: "key=value; expires=Thu, 01 Jan 1970 00:00:00 GMT"
    end

    it_parses_set_cookie "key=value; path=/test; domain=www.example.com; HttpOnly; Secure; expires=Sun, 06 Nov 1994 08:49:37 GMT; SameSite=Strict",
      HTTP::Cookie.new("key", "value",
        path: "/test",
        domain: "www.example.com",
        http_only: true,
        secure: true,
        expires: Time.utc(1994, 11, 6, 8, 49, 37),
        samesite: HTTP::Cookie::SameSite::Strict,
      ),
      string: "key=value; domain=www.example.com; path=/test; expires=Sun, 06 Nov 1994 08:49:37 GMT; Secure; HttpOnly; SameSite=Strict"

    it_parses_set_cookie "key=value; domain=127.0.0.1", HTTP::Cookie.new("key", "value", domain: "127.0.0.1")

    describe "max-age" do
      it "parse max-age as seconds from current time" do
        cookie = parse_set_cookie("a=1; max-age=10")
        delta = cookie.expires.not_nil! - Time.utc
        delta.should be_close(10.seconds, 1.second)

        cookie = parse_set_cookie("a=1; max-age=0")
        delta = Time.utc - cookie.expires.not_nil!
        delta.should be_close(0.seconds, 1.second)
      end

      it "parses large max-age (#8744)" do
        cookie = parse_set_cookie("a=1; max-age=3153600000")
        delta = cookie.expires.not_nil! - Time.utc
        delta.should be_close(3153600000.seconds, 1.second)
      end
    end
  end
end
