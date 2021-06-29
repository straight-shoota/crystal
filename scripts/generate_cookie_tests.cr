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
    property sent_raw

    def to_s(io : IO)
      io.puts "  # #{test}"
      received.each_with_index do |r, i|
        io.puts "  it_parses_set_cookie #{r.inspect}, #{sent[i]? || "nil"}"
      end
    end
  end

SOURCE_URL = "https://raw.githubusercontent.com/inikulin/cookie-compat/gh-pages/data/test-cases.json"

response = HTTP::Client.get(SOURCE_URL)

test_cases = Array(TestCase).from_json(response.body)

test_cases.each do |test_case|
  puts test_case
end
