require "spec"
require "http/cookie"

private def parse_first_cookie(header)
  cookies = HTTP::Cookie::Parser.parse_cookies(header)
  cookies.size.should eq(1)
  cookies.first
end

private def parse_set_cookie(header)
  cookie = HTTP::Cookie::Parser.parse_set_cookie(header)
  cookie.should_not be_nil
end

describe HTTP::Cookie::Parser do
  describe "parse_cookies" do
    it "parses key=value" do
      cookie = parse_first_cookie("key=value")
      cookie.name.should eq("key")
      cookie.value.should eq("value")
      cookie.to_set_cookie_header.should eq("key=value")
    end

    it "parse_set_cookie with space" do
      cookie = parse_set_cookie("key=value; path=/test")
      parse_set_cookie("key=value;path=/test").should eq cookie
      parse_set_cookie("key=value;  \t\npath=/test").should eq cookie
    end

    it "parses key=" do
      cookie = parse_first_cookie("key=")
      cookie.name.should eq("key")
      cookie.value.should eq("")
      cookie.to_set_cookie_header.should eq("key=")
    end

    it "parses key=key=value" do
      cookie = parse_first_cookie("key=key=value")
      cookie.name.should eq("key")
      cookie.value.should eq("key=value")
      cookie.to_set_cookie_header.should eq("key=key=value")
    end

    it "parses key=key%3Dvalue" do
      cookie = parse_first_cookie("key=key%3Dvalue")
      cookie.name.should eq("key")
      cookie.value.should eq("key%3Dvalue")
      cookie.to_set_cookie_header.should eq("key=key%3Dvalue")
    end

    it "parses special character in name" do
      cookie = parse_first_cookie("key%3Dvalue=value")
      cookie.name.should eq("key%3Dvalue")
      cookie.value.should eq("value")
      cookie.to_set_cookie_header.should eq("key%3Dvalue=value")
    end

    it "parses multiple cookies" do
      cookies = HTTP::Cookie::Parser.parse_cookies("foo=bar; foobar=baz")
      cookies.size.should eq(2)
      first, second = cookies
      first.name.should eq("foo")
      second.name.should eq("foobar")
      first.value.should eq("bar")
      second.value.should eq("baz")
    end
  end

  describe "parse_set_cookie" do
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
