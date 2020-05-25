require "../spec_helper"
require "compiler/crystal/error"
require "compiler/crystal/syntax/location"
require "compiler/crystal/error/loader"

describe Crystal::ErrorFormatter do
  describe ".load_source" do
    it "CodeError" do
      filename = "foo.cr"
      error = Crystal::CodeError.new(nil, Crystal::ErrorLocation.new(filename, 2, 3, 3))
      file_cache = {filename => "def baz(foo)\n   bar(foo)\nend".lines}
      Crystal::ErrorFormatter.load_source(error, file_cache)
      error.source.should eq "   bar(foo)"
    end

    it "ErrorFrame" do
      filename = "foo.cr"
      frame = Crystal::ErrorFrame.new(:other, Crystal::ErrorLocation.new(filename, 2, 3, 3))
      file_cache = {filename => "def baz(foo)\n   bar(foo)\nend".lines}
      Crystal::ErrorFormatter.load_source(frame, file_cache)
      frame.source.should eq "   bar(foo)"
    end
  end

  describe ".load_sources" do
    it "loads source from file" do
      filename = compiler_datapath("errors", "error_trace")
      error = Crystal::CodeError.new("", Crystal::ErrorLocation.new(filename, 2, 3, 3))
      Crystal::ErrorFormatter.load_sources(error)
      error.source.should eq "  bar(foo)"
    end

    it "loads sources from same file" do
      filename = compiler_datapath("errors", "error_trace")
      error = Crystal::CodeError.new("", Crystal::ErrorLocation.new(filename, 11, 1, 3))

      f1 = Crystal::ErrorFrame.new(:other, Crystal::ErrorLocation.new(filename, 6, 3, 3))
      error.frames << f1
      f2 = Crystal::ErrorFrame.new(:other, Crystal::ErrorLocation.new(filename, 2, 3, 3))
      error.frames << f2

      Crystal::ErrorFormatter.load_sources(error)
      error.source.should eq "foo(1)"
      f1.source.should eq "  baz(bar)"
      f2.source.should eq "  bar(foo)"
    end
  end
end
