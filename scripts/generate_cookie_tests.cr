require "http"
require "json"

record CookieValue,
  name : String,
  value : String do
    include JSON::Serializable

    def to_s(io : IO)
      io << "HTTP::Cookie.new(#{name.inspect}, #{value.inspect})"
    end
  end


record TestCase,
  test : String,
  received : Array(String),
  sent : Array(CookieValue) do
    include JSON::Serializable
    @[JSON::Field(key: "sent-raw")]
    property sent_raw : String = ""

    def to_s(io : IO)
      io.puts "  it_receives_cookies #{test.inspect}, #{received}, [#{sent.join(", ", &.to_s)}] of HTTP::Cookie?, #{sent_raw.inspect}"
    end
  end

SOURCE_URL = "https://raw.githubusercontent.com/inikulin/cookie-compat/gh-pages/data/test-cases.json"

response = HTTP::Client.get(SOURCE_URL)

test_cases = Array(TestCase).from_json(response.body)

test_cases.each do |test_case|
  puts test_case
end
