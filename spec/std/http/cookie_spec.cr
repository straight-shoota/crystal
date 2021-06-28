require "spec"
require "http/cookie"
require "http/headers"

private def parse_set_cookie(header)
  cookie = HTTP::Cookie::Parser.parse_set_cookie(header)
  cookie.should_not be_nil
end

module HTTP
  describe Cookie do
    it "#==" do
      cookie = Cookie.new("a", "b", path: "/path", expires: Time.utc, domain: "domain", secure: true, http_only: true, samesite: :strict, extension: "foo=bar")
      cookie.should eq(cookie.dup)
      cookie.should_not eq(cookie.dup.tap { |c| c.name = "c" })
      cookie.should_not eq(cookie.dup.tap { |c| c.value = "c" })
      cookie.should_not eq(cookie.dup.tap { |c| c.path = "/c" })
      cookie.should_not eq(cookie.dup.tap { |c| c.domain = "c" })
      cookie.should_not eq(cookie.dup.tap { |c| c.expires = Time.utc(2021, 1, 1) })
      cookie.should_not eq(cookie.dup.tap { |c| c.secure = false })
      cookie.should_not eq(cookie.dup.tap { |c| c.http_only = false })
      cookie.should_not eq(cookie.dup.tap { |c| c.samesite = :lax })
      cookie.should_not eq(cookie.dup.tap { |c| c.extension = nil })
    end

    describe ".new" do
      it "raises on invalid name" do
        expect_raises IO::Error, "Invalid cookie name" do
          HTTP::Cookie.new("", "")
        end
        expect_raises IO::Error, "Invalid cookie name" do
          HTTP::Cookie.new("\t", "")
        end
        # more extensive specs on #name=
      end

      it "raises on invalid value" do
        expect_raises IO::Error, "Invalid cookie value" do
          HTTP::Cookie.new("x", %(foo\rbar))
        end
        # more extensive specs on #value=
      end
    end

    describe "#name=" do
      it "raises on invalid name" do
        cookie = HTTP::Cookie.new("x", "")
        expect_raises IO::Error, "Invalid cookie name" do
          cookie.name = ""
        end
        expect_raises IO::Error, "Invalid cookie name" do
          cookie.name = "\t"
        end
        expect_raises IO::Error, "Invalid cookie name" do
          cookie.name = "\r"
        end
        expect_raises IO::Error, "Invalid cookie name" do
          cookie.name = "a\nb"
        end
        expect_raises IO::Error, "Invalid cookie name" do
          cookie.name = "a\rb"
        end
      end
    end

    describe "#value=" do
      it "raises on invalid value" do
        cookie = HTTP::Cookie.new("x", "")
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = %(foo\rbar)
        end
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = %(foo"bar)
        end
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = "foo;bar"
        end
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = "foo\\bar"
        end
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = "foo\\bar"
        end
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = "foo bar"
        end
        expect_raises IO::Error, "Invalid cookie value" do
          cookie.value = "foo,bar"
        end
      end
    end

    describe "#to_set_cookie_header" do
      it { HTTP::Cookie.new("x", "v$1").to_set_cookie_header.should eq "x=v$1" }

      it { HTTP::Cookie.new("x", "seven", domain: "127.0.0.1").to_set_cookie_header.should eq "x=seven; domain=127.0.0.1" }

      it { HTTP::Cookie.new("x", "y", path: "/").to_set_cookie_header.should eq "x=y; path=/" }
      it { HTTP::Cookie.new("x", "y", path: "/example").to_set_cookie_header.should eq "x=y; path=/example" }

      it { HTTP::Cookie.new("x", "expiring", expires: Time.unix(1257894000)).to_set_cookie_header.should eq "x=expiring; expires=Tue, 10 Nov 2009 23:00:00 GMT" }
      it { HTTP::Cookie.new("x", "expiring-1601", expires: Time.utc(1601, 1, 1, 1, 1, 1, nanosecond: 1)).to_set_cookie_header.should eq "x=expiring-1601; expires=Mon, 01 Jan 1601 01:01:01 GMT" }

      it "samesite" do
        HTTP::Cookie.new("x", "samesite-default", samesite: nil).to_set_cookie_header.should eq "x=samesite-default"
        HTTP::Cookie.new("x", "samesite-lax", samesite: :lax).to_set_cookie_header.should eq "x=samesite-lax; SameSite=Lax"
        HTTP::Cookie.new("x", "samesite-strict", samesite: :strict).to_set_cookie_header.should eq "x=samesite-strict; SameSite=Strict"
        HTTP::Cookie.new("x", "samesite-none", samesite: :none).to_set_cookie_header.should eq "x=samesite-none; SameSite=None"
      end

      it { HTTP::Cookie.new("empty-value", "").to_set_cookie_header.should eq "empty-value=" }
    end

    describe "#expired?" do
      it "by max-age=0" do
        parse_set_cookie("bla=1; max-age=0").expired?.should eq true
      end

      it "by old date" do
        parse_set_cookie("bla=1; expires=Thu, 01 Jan 1970 00:00:00 -0000").expired?.should eq true
      end

      it "not expired" do
        parse_set_cookie("bla=1; max-age=1").expired?.should eq false
      end

      it "not expired" do
        parse_set_cookie("bla=1; expires=Thu, 01 Jan #{Time.utc.year + 2} 00:00:00 -0000").expired?.should eq false
      end

      it "not expired" do
        parse_set_cookie("bla=1").expired?.should eq false
      end
    end
  end

  describe Cookies do
    describe ".from_client_headers" do
      it "parses Cookie header" do
        cookies = Cookies.from_client_headers Headers{"Cookie" => "a=b"}
        cookies.to_h.should eq({"a" => Cookie.new("a", "b")})
      end
      it "does not accept Set-Cookie header" do
        cookies = Cookies.from_client_headers Headers{"Cookie" => "a=b", "Set-Cookie" => "x=y"}
        cookies.to_h.should eq({"a" => Cookie.new("a", "b")})
      end
    end

    describe ".from_server_headers" do
      it "parses Set-Cookie header" do
        cookies = Cookies.from_server_headers Headers{"Set-Cookie" => "a=b; path=/foo"}
        cookies.to_h.should eq({"a" => Cookie.new("a", "b", path: "/foo")})
      end
      it "does not accept Cookie header" do
        cookies = Cookies.from_server_headers Headers{"Set-Cookie" => "a=b", "Cookie" => "x=y"}
        cookies.to_h.should eq({"a" => Cookie.new("a", "b")})
      end
    end

    it "allows adding cookies and retrieving" do
      cookies = Cookies.new
      cookies << Cookie.new("a", "b")
      cookies["c"] = Cookie.new("c", "d")
      cookies["d"] = "e"

      cookies["a"].value.should eq "b"
      cookies["c"].value.should eq "d"
      cookies["d"].value.should eq "e"
      cookies["a"]?.should_not be_nil
      cookies["e"]?.should be_nil
      cookies.has_key?("a").should be_true
    end

    it "allows retrieving the size of the cookies collection" do
      cookies = Cookies.new
      cookies.size.should eq 0
      cookies << Cookie.new("1", "2")
      cookies.size.should eq 1
      cookies << Cookie.new("3", "4")
      cookies.size.should eq 2
    end

    it "allows clearing the cookies collection" do
      cookies = Cookies.new
      cookies << Cookie.new("test_key", "test_value")
      cookies << Cookie.new("a", "b")
      cookies << Cookie.new("c", "d")
      cookies.clear
      cookies.should be_empty
    end

    it "allows deleting a particular cookie by key" do
      cookies = Cookies.new
      cookies << Cookie.new("the_key", "the_value")
      cookies << Cookie.new("not_the_key", "not_the_value")
      cookies << Cookie.new("a", "b")
      cookies.has_key?("the_key").should be_true
      cookies.delete("the_key").not_nil!.value.should eq "the_value"
      cookies.has_key?("the_key").should be_false
      cookies.size.should eq 2
    end

    describe "adding request headers" do
      it "overwrites a pre-existing Cookie header" do
        headers = Headers.new
        headers["Cookie"] = "some_key=some_value"

        cookies = Cookies.new
        cookies << Cookie.new("a", "b")

        headers["Cookie"].should eq "some_key=some_value"

        cookies.add_request_headers(headers)

        headers["Cookie"].should eq "a=b"
      end

      it "use encode_www_form to write the cookie's value" do
        headers = Headers.new
        cookies = Cookies.new
        cookies << Cookie.new("a", "b+c")
        cookies.add_request_headers(headers)
        headers["Cookie"].should eq "a=b+c"
      end

      it "merges multiple cookies into one Cookie header" do
        headers = Headers.new
        cookies = Cookies.new
        cookies << Cookie.new("a", "b")
        cookies << Cookie.new("c", "d")

        cookies.add_request_headers(headers)

        headers["Cookie"].should eq "a=b; c=d"
      end

      describe "when no cookies are set" do
        it "does not set a Cookie header" do
          headers = Headers.new
          headers["Cookie"] = "a=b"
          cookies = Cookies.new

          headers["Cookie"]?.should_not be_nil
          cookies.add_request_headers(headers)
          headers["Cookie"]?.should be_nil
        end
      end
    end

    describe "adding response headers" do
      it "overwrites all pre-existing Set-Cookie headers" do
        headers = Headers.new
        headers.add("Set-Cookie", "a=b")
        headers.add("Set-Cookie", "c=d")

        cookies = Cookies.new
        cookies << Cookie.new("x", "y")

        headers.get("Set-Cookie").size.should eq 2
        headers.get("Set-Cookie").includes?("a=b").should be_true
        headers.get("Set-Cookie").includes?("c=d").should be_true

        cookies.add_response_headers(headers)

        headers.get("Set-Cookie").size.should eq 1
        headers.get("Set-Cookie")[0].should eq "x=y"
      end

      it "sets one Set-Cookie header per cookie" do
        headers = Headers.new
        cookies = Cookies.new
        cookies << Cookie.new("a", "b")
        cookies << Cookie.new("c", "d")

        headers.get?("Set-Cookie").should be_nil
        cookies.add_response_headers(headers)
        headers.get?("Set-Cookie").should_not be_nil

        headers.get("Set-Cookie").includes?("a=b").should be_true
        headers.get("Set-Cookie").includes?("c=d").should be_true
      end

      it "uses encode_www_form on Set-Cookie value" do
        headers = Headers.new
        cookies = Cookies.new
        cookies << Cookie.new("a", "b+c")
        cookies.add_response_headers(headers)
        headers.get("Set-Cookie").includes?("a=b+c").should be_true
      end

      describe "when no cookies are set" do
        it "does not set a Set-Cookie header" do
          headers = Headers.new
          headers.add("Set-Cookie", "a=b")
          cookies = Cookies.new

          headers.get?("Set-Cookie").should_not be_nil
          cookies.add_response_headers(headers)
          headers.get?("Set-Cookie").should be_nil
        end
      end
    end

    it "disallows adding inconsistent state" do
      cookies = Cookies.new

      expect_raises ArgumentError do
        cookies["a"] = Cookie.new("b", "c")
      end
    end

    it "allows to iterate over the cookies" do
      cookies = Cookies.new
      cookies["a"] = "b"
      cookies.each do |cookie|
        cookie.name.should eq "a"
        cookie.value.should eq "b"
      end

      cookie = cookies.each.next
      cookie.should eq Cookie.new("a", "b")
    end

    it "allows transform to hash" do
      cookies = Cookies.new
      cookies << Cookie.new("a", "b")
      cookies["c"] = Cookie.new("c", "d")
      cookies["d"] = "e"
      cookies_hash = cookies.to_h
      compare_hash = {"a" => Cookie.new("a", "b"), "c" => Cookie.new("c", "d"), "d" => Cookie.new("d", "e")}
      cookies_hash.should eq(compare_hash)
      cookies["x"] = "y"
      cookies.to_h.should_not eq(cookies_hash)
    end
  end
end
