require "spec_helper"

describe Script do
  it "says hello world" do
    s = Script.new
    expect(s.hello).to eq "hello world"
  end

  it "validates name presence false when empty" do
    s = Script.new
    expect(s.valid?).to eq(false)
  end

  it "validates name presence true" do
    s = Script.new
    s.name = "Foo"
    expect(s.valid?).to eq(true)
  end

  it "conforms to json api spec" do
    s = ExampleSerialization.run
    expect(s[:data].first.keys).to eq([:id, :type, :attributes])
  end

  it "serializes into json api spec and has name attribute" do
    s = ExampleSerialization.run
    expect(s[:data].first[:attributes][:name]).to eq("test movie 0")
  end

  it "defines model types" do
    s = ExampleSerialization.run
    expect(s[:data].first[:type]).to eq(:movie)
  end
end

