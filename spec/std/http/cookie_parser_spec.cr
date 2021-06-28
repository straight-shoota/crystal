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

    it "parses path" do
      cookie = parse_set_cookie("key=value; path=/test")
      cookie.name.should eq("key")
      cookie.value.should eq("value")
      cookie.path.should eq("/test")
      cookie.to_set_cookie_header.should eq("key=value; path=/test")
    end

    it "parses Secure" do
      cookie = parse_set_cookie("key=value; Secure")
      cookie.name.should eq("key")
      cookie.value.should eq("value")
      cookie.secure.should be_true
      cookie.to_set_cookie_header.should eq("key=value; Secure")
    end

    it "parses HttpOnly" do
      cookie = parse_set_cookie("key=value; HttpOnly")
      cookie.name.should eq("key")
      cookie.value.should eq("value")
      cookie.http_only.should be_true
      cookie.to_set_cookie_header.should eq("key=value; HttpOnly")
    end

    describe "SameSite" do
      context "Lax" do
        it "parses samesite" do
          cookie = parse_set_cookie("key=value; SameSite=Lax")
          cookie.name.should eq "key"
          cookie.value.should eq "value"
          cookie.samesite.should eq HTTP::Cookie::SameSite::Lax
          cookie.to_set_cookie_header.should eq "key=value; SameSite=Lax"
        end
      end

      context "Strict" do
        it "parses samesite" do
          cookie = parse_set_cookie("key=value; SameSite=Strict")
          cookie.name.should eq "key"
          cookie.value.should eq "value"
          cookie.samesite.should eq HTTP::Cookie::SameSite::Strict
          cookie.to_set_cookie_header.should eq "key=value; SameSite=Strict"
        end
      end

      context "Invalid" do
        it "parses samesite" do
          cookie = parse_set_cookie("key=value; SameSite=Foo")
          cookie.name.should eq "key"
          cookie.value.should eq "value"
          cookie.samesite.should be_nil
          cookie.to_set_cookie_header.should eq "key=value"
        end
      end
    end

    it "parses domain" do
      cookie = parse_set_cookie("key=value; domain=www.example.com")
      cookie.name.should eq("key")
      cookie.value.should eq("value")
      cookie.domain.should eq("www.example.com")
      cookie.to_set_cookie_header.should eq("key=value; domain=www.example.com")
    end

    describe "expires" do
      it "parses expires iis" do
        cookie = parse_set_cookie("key=value; expires=Sun, 06-Nov-1994 08:49:37 GMT")
        time = Time.utc(1994, 11, 6, 8, 49, 37)

        cookie.name.should eq("key")
        cookie.value.should eq("value")
        cookie.expires.should eq(time)
      end

      it "parses expires rfc1123" do
        cookie = parse_set_cookie("key=value; expires=Sun, 06 Nov 1994 08:49:37 GMT")
        time = Time.utc(1994, 11, 6, 8, 49, 37)

        cookie.name.should eq("key")
        cookie.value.should eq("value")
        cookie.expires.should eq(time)
      end

      it "parses expires rfc1036" do
        cookie = parse_set_cookie("key=value; expires=Sunday, 06-Nov-94 08:49:37 GMT")
        time = Time.utc(1994, 11, 6, 8, 49, 37)

        cookie.name.should eq("key")
        cookie.value.should eq("value")
        cookie.expires.should eq(time)
      end

      it "parses expires ansi c" do
        cookie = parse_set_cookie("key=value; expires=Sun Nov  6 08:49:37 1994")
        time = Time.utc(1994, 11, 6, 8, 49, 37)

        cookie.name.should eq("key")
        cookie.value.should eq("value")
        cookie.expires.should eq(time)
      end

      it "parses expires ansi c, variant with zone" do
        cookie = parse_set_cookie("bla=; expires=Thu, 01 Jan 1970 00:00:00 -0000")
        cookie.expires.should eq(Time.utc(1970, 1, 1, 0, 0, 0))
      end
    end

    it "parses full" do
      cookie = parse_set_cookie("key=value; path=/test; domain=www.example.com; HttpOnly; Secure; expires=Sun, 06 Nov 1994 08:49:37 GMT; SameSite=Strict")
      time = Time.utc(1994, 11, 6, 8, 49, 37)

      cookie.name.should eq "key"
      cookie.value.should eq "value"
      cookie.path.should eq "/test"
      cookie.domain.should eq "www.example.com"
      cookie.http_only.should be_true
      cookie.secure.should be_true
      cookie.expires.should eq time
      cookie.samesite.should eq HTTP::Cookie::SameSite::Strict
    end

    it "parse domain as IP" do
      parse_set_cookie("a=1; domain=127.0.0.1; HttpOnly").domain.should eq "127.0.0.1"
    end

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
