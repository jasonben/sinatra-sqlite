require "spec_helper"

describe App, type: :feature do
  it "serves html on /events" do
    visit "/events"
    expect(page).to have_content "Events"
  end

  it "serves html on /events/new" do
    visit "/events/new"
    expect(page).to have_content "Click Me"
  end
end

describe App do
  include Rack::Test::Methods

  def app = App

  before(:example) do
    Event.delete_all
    @events = 3.times.map { Event.create name: "jason" }
  end

  it "200 status code on /events" do
    get "/events"
    expect(last_response).to be_ok
  end

  it "serves valid json on /events" do
    header "Accept", "application/json"
    get "/events", {"Accept": "application/json"}
    data = JSON.parse last_response.body
    expect(data.size).to eq 3
  end

  it "conforms to json api spec on /events" do
    header "Accept", "application/json"
    get "/events", {"Accept": "application/json"}
    response = JSON.parse last_response.body
    # ap response[0]
    expect(response[0]["data"].keys).to eq(%w[id type attributes])
  end

  # it "creates event via get request to /events/new" do
  #   header "Accept", "application/json"
  #   get "/events/new", {"Accept": "application/json"}
  #   response = JSON.parse last_response.body
  #   expect(response["data"].keys).to eq(%w[id type attributes])
  # end
end
