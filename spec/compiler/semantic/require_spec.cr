require "../../spec_helper"

describe "Semantic: require" do
  it "raises crystal exception if can't find require (#7385)" do
    node = parse(%(require "file_that_doesnt_exist"))
    ex = expect_raises Crystal::Error do
      semantic(node)
    end
  end
end
