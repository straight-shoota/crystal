require "../spec_helper"
require "compiler/crystal/error"
require "compiler/crystal/error/loader"

describe Crystal::ErrorFormatter do
  describe ".load_source" do
    it "LocationError" do
      filename = "foo.cr"
      error = Crystal::LocationError.new(nil, Crystal::ErrorLocation.new(filename, 2, 3, 3))
      file_cache = {filename => "def baz(foo)\n   bar(foo)\nend".lines}
      Crystal::ErrorFormatter.load_source(error, file_cache)
      error.location.source.should eq "   bar(foo)"
    end
  end

  describe ".load_sources" do
    it "loads source from file" do
      filename = compiler_datapath("errors", "error_trace")
      error = Crystal::LocationError.new("", Crystal::ErrorLocation.new(filename, 2, 3, 3))
      Crystal::ErrorFormatter.load_sources(error)
      error.location.source.should eq "  bar(foo)"
    end
  end
end
