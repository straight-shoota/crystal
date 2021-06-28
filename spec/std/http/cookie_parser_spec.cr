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
    it_parses_cookies "foo=bar;foobar=baz", [HTTP::Cookie.new("foo", "bar")], string: "foo=bar"
    it_parses_cookies "foo=bar;  foobar=baz", [HTTP::Cookie.new("foo", "bar")], string: "foo=bar"
    it_parses_cookies "; foo=bar", HTTP::Cookie.new("foo", "bar"), string: "foo=bar"
    it_parses_cookies "foo=bar;  ", HTTP::Cookie.new("foo", "bar"), string: "foo=bar"

    it_parses_cookies "invalid; baz=qux", [HTTP::Cookie.new("baz", "qux")], string: "baz=qux"
    it_parses_cookies "foo=bar; invalid; baz=qux", [HTTP::Cookie.new("foo", "bar"), HTTP::Cookie.new("baz", "qux")], string: "foo=bar; baz=qux"

    it_parses_cookies %(de=; client_region=0; rpld1=0:hispeed.ch|20:che|21:zh|22:zurich|23:47.36|24:8.53|; rpld0=1:08|; backplane-channel=newspaper.com:1471; devicetype=0; osfam=0; rplmct=2; s_pers=%20s_vmonthnum%3D1472680800496%2526vn%253D1%7C1472680800496%3B%20s_nr%3D1471686767664-New%7C1474278767664%3B%20s_lv%3D1471686767669%7C1566294767669%3B%20s_lv_s%3DFirst%2520Visit%7C1471688567669%3B%20s_monthinvisit%3Dtrue%7C1471688567677%3B%20gvp_p5%3Dsports%253Ablog%253Aearly-lead%2520-%2520184693%2520-%252020160820%2520-%2520u-s%7C1471688567681%3B%20gvp_p51%3Dwp%2520-%2520sports%7C1471688567684%3B; s_sess=%20s_wp_ep%3Dhomepage%3B%20s._ref%3Dhttps%253A%252F%252Fwww.google.ch%252F%3B%20s_cc%3Dtrue%3B%20s_ppvl%3Dsports%25253Ablog%25253Aearly-lead%252520-%252520184693%252520-%25252020160820%252520-%252520u-lawyer%252C12%252C12%252C502%252C1231%252C502%252C1680%252C1050%252C2%252CP%3B%20s_ppv%3Dsports%25253Ablog%25253Aearly-lead%252520-%252520184693%252520-%25252020160820%252520-%252520u-s-lawyer%252C12%252C12%252C502%252C1231%252C502%252C1680%252C1050%252C2%252CP%3B%20s_dslv%3DFirst%2520Visit%3B%20s_sq%3Dwpninewspapercom%253D%252526pid%25253Dsports%2525253Ablog%2525253Aearly-lead%25252520-%25252520184693%25252520-%2525252020160820%25252520-%25252520u-s%252526pidt%25253D1%252526oid%25253Dhttps%2525253A%2525252F%2525252Fwww.newspaper.com%2525252F%2525253Fnid%2525253Dmenu_nav_homepage%252526ot%25253DA%3B), [
      HTTP::Cookie.new("de", ""),
      HTTP::Cookie.new("client_region", "0"),
      HTTP::Cookie.new("rpld1", "0:hispeed.ch|20:che|21:zh|22:zurich|23:47.36|24:8.53|"),
      HTTP::Cookie.new("rpld0", "1:08|"),
      HTTP::Cookie.new("backplane-channel", "newspaper.com:1471"),
      HTTP::Cookie.new("devicetype", "0"),
      HTTP::Cookie.new("osfam", "0"),
      HTTP::Cookie.new("rplmct", "2"),
      HTTP::Cookie.new("s_pers", "%20s_vmonthnum%3D1472680800496%2526vn%253D1%7C1472680800496%3B%20s_nr%3D1471686767664-New%7C1474278767664%3B%20s_lv%3D1471686767669%7C1566294767669%3B%20s_lv_s%3DFirst%2520Visit%7C1471688567669%3B%20s_monthinvisit%3Dtrue%7C1471688567677%3B%20gvp_p5%3Dsports%253Ablog%253Aearly-lead%2520-%2520184693%2520-%252020160820%2520-%2520u-s%7C1471688567681%3B%20gvp_p51%3Dwp%2520-%2520sports%7C1471688567684%3B"),
      HTTP::Cookie.new("s_sess", "%20s_wp_ep%3Dhomepage%3B%20s._ref%3Dhttps%253A%252F%252Fwww.google.ch%252F%3B%20s_cc%3Dtrue%3B%20s_ppvl%3Dsports%25253Ablog%25253Aearly-lead%252520-%252520184693%252520-%25252020160820%252520-%252520u-lawyer%252C12%252C12%252C502%252C1231%252C502%252C1680%252C1050%252C2%252CP%3B%20s_ppv%3Dsports%25253Ablog%25253Aearly-lead%252520-%252520184693%252520-%25252020160820%252520-%252520u-s-lawyer%252C12%252C12%252C502%252C1231%252C502%252C1680%252C1050%252C2%252CP%3B%20s_dslv%3DFirst%2520Visit%3B%20s_sq%3Dwpninewspapercom%253D%252526pid%25253Dsports%2525253Ablog%2525253Aearly-lead%25252520-%25252520184693%25252520-%2525252020160820%25252520-%25252520u-s%252526pidt%25253D1%252526oid%25253Dhttps%2525253A%2525252F%2525252Fwww.newspaper.com%2525252F%2525253Fnid%2525253Dmenu_nav_homepage%252526ot%25253DA%3B"),
    ]
  end

  describe ".parse_set_cookie" do
    it_parses_set_cookie "key=value", HTTP::Cookie.new("key", "value")

    pending "quoted value with whitespace" do
      # The "special" cookies have values containing commas or spaces which
      # are disallowed by RFC 6265 but are common in the wild.
      it_parses_set_cookie %(special-1="a z"), HTTP::Cookie.new("special-1", "a z")
      it_parses_set_cookie %(special-2=" z"), HTTP::Cookie.new("special-2", " z")
      it_parses_set_cookie %(special-3="a "), HTTP::Cookie.new("special-3", "a ")
      it_parses_set_cookie %(special-4=" "), HTTP::Cookie.new("special-4", " ")
      it_parses_set_cookie %(special-5="a,z"), HTTP::Cookie.new("special-5", "a,z")
      it_parses_set_cookie %(special-6=",z"), HTTP::Cookie.new("special-6", ",z")
      it_parses_set_cookie %(special-7="a,"), HTTP::Cookie.new("special-7", "a,")
      it_parses_set_cookie %(special-8=","), HTTP::Cookie.new("special-8", ",")
      it_parses_set_cookie %(empty-value=), HTTP::Cookie.new("empty-value", "")
    end

    it "parse_set_cookie with space" do
      cookie = parse_set_cookie("key=value; path=/test")
      parse_set_cookie("key=value;path=/test").should eq cookie
      parse_set_cookie("key=value;  \t\npath=/test").should eq cookie
    end

    it_parses_set_cookie "key=value; path=/test", HTTP::Cookie.new("key", "value", path: "/test")

    it_parses_set_cookie "key=value; Secure", HTTP::Cookie.new("key", "value", secure: true)

    it_parses_set_cookie "key=value; HttpOnly", HTTP::Cookie.new("key", "value", http_only: true)

    it_parses_set_cookie "key=invalid-domain", HTTP::Cookie.new("key", "invalid-domain", domain: nil), string: "key=invalid-domain"
    it_parses_set_cookie "key=invalid-domain", HTTP::Cookie.new("key", "invalid-domain", domain: nil), string: "key=invalid-domain"
    it_parses_set_cookie "key=invalid-domain", HTTP::Cookie.new("key", "invalid-domain", domain: nil), string: "key=invalid-domain"

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

      # According to IETF 6265 Section 5.1.1.5, the year cannot be less than 1601
      it_parses_set_cookie "key=expiring-1601; expires=Mon, 01 Jan 1601 01:01:01 GMT", HTTP::Cookie.new("key", "expiring-1601", expires: Time.utc(1601, 1, 1, 1, 1, 1))
      pending do
        it_parses_set_cookie "key=invalid-expiry; expires=Mon, 01 Jan 1600 01:01:01 GMT", HTTP::Cookie.new("key", "invalid-expiry", expires: Time.utc(1600, 1, 1, 1, 1, 1, nanosecond: 1)), string: "key=invalid-expiry"
      end
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

      pending do
        it_parses_set_cookie "key=value; Max-Age=3600", HTTP::Cookie.new("key", "value", max_age: 3600.seconds)
      end
    end
  end
end
