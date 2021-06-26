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
end
