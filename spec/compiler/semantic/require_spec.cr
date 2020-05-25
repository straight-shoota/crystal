require "../../spec_helper"

describe "Semantic: require" do
  describe "file not found" do
    it "require" do
      error = assert_error %(require "file_that_doesnt_exist"),
        "can't find file 'file_that_doesnt_exist'",
        location: Crystal::ErrorLocation.new("", 1, 1, 0),
        inject_primitives: false

      error.notes.size.should eq 1
      error.notes.first.should start_with "If you're trying to require a shard:"
    end

    it "relative require" do
      error = assert_error %(require "./file_that_doesnt_exist"),
        "can't find file './file_that_doesnt_exist'",
        location: Crystal::ErrorLocation.new("", 1, 1, 0),
        inject_primitives: false

      error.notes.should be_empty
    end

    it "wildecard" do
      error = assert_error %(require "file_that_doesnt_exist/*"),
        "can't find file 'file_that_doesnt_exist/*'",
        location: Crystal::ErrorLocation.new("", 1, 1, 0),
        inject_primitives: false

      error.notes.size.should eq 1
      error.notes.first.should start_with "If you're trying to require a shard:"
    end

    it "relative wildecard" do
      error = assert_error %(require "./file_that_doesnt_exist/*"),
        "can't find file './file_that_doesnt_exist/*'",
        location: Crystal::ErrorLocation.new("", 1, 1, 0),
        inject_primitives: false

      error.notes.should be_empty
    end
  end
end
