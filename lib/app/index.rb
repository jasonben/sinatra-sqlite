# frozen_string_literal: true

#=====================================

APP_VERSION = "0.1"
require "rubygems"
require "bundler"
def production? = ENV["APP_ENV"] == "production"

def development? = ENV["APP_ENV"] == "development"
envs = [:default]
envs += [:development, :test] unless production?
Bundler.require(*envs)

#=====================================

require "sinatra/base"
require "sinatra/respond_with"
require "sinatra/activerecord"
require "sinatra/reloader"
require "jsonapi/serializer"
require "rack/contrib"
require "digest/sha1"

#=====================================

# Example serializer
class EventSerializer
  include JSONAPI::Serializer
  set_type :event
  attributes :name, :place, :created_at
end

#=====================================

# Example model
class Event < ActiveRecord::Base
  validates :name, presence: true

  def to_h
    EventSerializer.new(self).serializable_hash
  end

  def sha1
    Digest::SHA1.hexdigest("#{id}#{updated_at}#{APP_VERSION}")
  end
end

#=====================================

# Sinatra App
class App < Sinatra::Base
  use Rack::Deflater
  use Rack::JSONBodyParser
  use Rack::MethodOverride
  register Sinatra::Reloader if development?
  register Sinatra::RespondWith
  respond_to :html, :json
  # enable :inline_templates
  set :server, "puma"
  set :bind, "0.0.0.0"
  set :port, 3000
  set :strict_paths, false
  set :logging, true

  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: "db/development.sqlite3",
    pool: 5,
    timeout: 5000
  )

  # Database schema
  ActiveRecord::Schema.define do
    def ensure_table(name)
      return if table_exists?(name)
      create_table name
    end

    def ensure_column(table:, column:, type:)
      return if column_exists?(table, column)
      change_table table do |t|
        t.send(type, column)
      end
    end
    ensure_table(:events)
    ensure_column(column: :name, type: :string, table: :events)
    ensure_column(column: :place, type: :string, table: :events)
    ensure_column(column: :thing, type: :string, table: :events)
    ensure_column(column: :created_at, type: :datetime, table: :events)
    ensure_column(column: :updated_at, type: :datetime, table: :events)
  end

  helpers do
    def hx_request? = request.env["HTTP_HX_REQUEST"].present?

    def hx_redirect(path)
      if hx_request?
        headers "HX-Redirect" => path
        status 200
        ""
      else
        redirect path
      end
    end

    def render_with_layout(&block)
      content = block.call
      hx_request? ? content : render_layout(content)
    end

    def render_layout(content)
      erb <<~ERB, locals: {content: content}
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="/tailwind.css">
            <title>Bfield.app</title>
          </head>
          <body class="text-white bg-gray-900">
            <nav class="bg-white border-gray-200 px-2 sm:px-4 rounded dark:bg-gray-900 py-2.5">
              <div class="container flex flex-wrap items-center justify-between mx-auto">
                <a href="/" class="flex items-center">
                  <img src="/logo.svg" class="h-6 mr-3 sm:h-9" loading="lazy" />
                  <span class="self-center text-xl font-semibold whitespace-nowrap dark:text-white">Bfield.app</span>
                </a>
                <div class="flex md:order-2">
                  <button type="button" class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center mr-3 md:mr-0 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Get started</button>
                  <button type="button" data-collapse-toggle="navbar-cta" aria-controls="navbar-cta" aria-expanded="false" class="inline-flex items-center p-2 text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600">
                    <span class="sr-only">Open main menu</span>
                    <svg class="w-6 h-6" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd"></path>
                    </svg>
                  </button>
                </div>
                <div class="items-center justify-between hidden w-full md:flex md:w-auto md:order-1" id="navbar-cta">
                  <ul class="flex flex-col p-4 mt-4 border border-gray-100 rounded-lg bg-gray-50 md:flex-row md:space-x-8 md:mt-0 md:text-sm md:font-medium md:border-0 md:bg-white dark:bg-gray-800 md:dark:bg-gray-900 dark:border-gray-700">
                    <li><a href="#" class="block py-2 pl-3 pr-4 text-white bg-blue-700 rounded md:bg-transparent md:text-blue-700 md:p-0 dark:text-white" aria-current="page">Home</a></li>
                    <li><a href="#" class="block py-2 pl-3 pr-4 text-gray-700 rounded hover:bg-gray-100 md:hover:bg-transparent md:hover:text-blue-700 md:p-0 md:dark:hover:text-white dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">About</a></li>
                    <li><a href="#" class="block py-2 pl-3 pr-4 text-gray-700 rounded hover:bg-gray-100 md:hover:bg-transparent md:hover:text-blue-700 md:p-0 md:dark:hover:text-white dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Services</a></li>
                    <li><a href="#" class="block py-2 pl-3 pr-4 text-gray-700 rounded hover:bg-gray-100 md:hover:bg-transparent md:hover:text-blue-700 md:p-0 md:dark:hover:text-white dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Contact</a></li>
                  </ul>
                </div>
              </div>
            </nav>
            <nav class="flex px-5 py-3 text-gray-700 border border-gray-200 rounded-lg bg-gray-50 dark:bg-gray-800 dark:border-gray-700" aria-label="Breadcrumb">
              <ol class="inline-flex items-center space-x-1 md:space-x-3">
                <li class="inline-flex items-center">
                  <a href="/" class="inline-flex items-center text-sm font-medium text-gray-700 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white">
                    <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"></path>
                    </svg>
                    Home
                  </a>
                </li>
                <li>
                  <div class="flex items-center">
                    <svg class="w-6 h-6 text-gray-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
                    </svg>
                    <a href="/events" class="ml-1 text-sm font-medium text-gray-700 hover:text-gray-900 md:ml-2 dark:text-gray-400 dark:hover:text-white">Events</a>
                  </div>
                </li>
                <li aria-current="page">
                  <div class="flex items-center">
                    <svg class="w-6 h-6 text-gray-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
                    </svg>
                    <a href="/tw" class="ml-1 text-sm font-medium text-gray-500 md:ml-2 dark:text-gray-400">All</a>
                  </div>
                </li>
              </ol>
            </nav>
            <div class="p-4 px-4 md:container md:mx-auto">
              <%= content %>
            </div>
            <footer></footer>
          </body>
        </html>
      ERB
    end

    def render_card(event)
      erb <<~ERB, locals: {event:}
        <div class="max-w-sm bg-white border border-gray-200 rounded-lg shadow-md dark:bg-gray-800 dark:border-gray-700">
          <img class="object-cover w-full rounded-t-lg" src="/image-1.jpg" alt="" loading="lazy" />
          <div class="p-5">
            <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
              <%= event&.name || "Hello" %>@<%= event&.place || "World" %>
            </h5>
            <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
              <%= event.created_at || Time.now %>
            </p>
            <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
              <%= event.thing %>
            </p>
            <a href="/events/<%= event.id %>/edit" class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
              Edit
              <svg class="w-4 h-4 ml-2 -mr-1" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>
            </a>
          </div>
        </div>
      ERB
    end
  end

  # set :layout, false

  get "/" do
    etag APP_VERSION
    render_with_layout do
      erb <<~ERB
        <h1>Sinatra Is Fun!</h1>
      ERB
    end
  end

  get "/events/new" do
    render_with_layout do
      erb <<~ERB
        <form action="/events" method="post" class="max-w-sm p-6 mx-auto mt-10 bg-white border border-gray-200 rounded-lg shadow-md space-y-4 dark:bg-gray-800 dark:border-gray-700">
          <div class="p-4">
            <h2 class="m-8 text-xl font-semibold text-gray-900 dark:text-white">Enter Information</h2>

            <div class="mb-3">
              <label for="name" class="block text-sm font-medium text-gray-400 dark:text-gray-300">Name</label>
              <input type="text" name="name" id="name" required class="block w-full mt-1 text-gray-900 bg-white border border-gray-300 rounded-md dark:border-gray-600 dark:bg-gray-700 dark:text-white focus:border-blue-500 focus:ring-blue-500">
            </div>

            <div class="mb-3">
              <label for="place" class="block text-sm font-medium text-gray-400 dark:text-gray-300">Place</label>
              <input type="text" name="place" id="place" required class="block w-full mt-1 text-gray-900 bg-white border border-gray-300 rounded-md dark:border-gray-600 dark:bg-gray-700 dark:text-white focus:border-blue-500 focus:ring-blue-500">
            </div>

            <div class="mb-3">
              <label for="thing" class="block text-sm font-medium text-gray-400 dark:text-gray-300">Thing</label>
              <input type="text" name="thing" id="thing" required class="block w-full mt-1 text-gray-900 bg-white border border-gray-300 rounded-md dark:border-gray-600 dark:bg-gray-700 dark:text-white focus:border-blue-500 focus:ring-blue-500">
            </div>

            <div class="mb-3">
              <button type="submit" class="w-full px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                Submit
              </button>
            </div>
          </div>
        </form>
      ERB
    end
  end

  get "/events/:id/edit" do
    @event = Event.find(params[:id])  # Adjust based on your data store

    render_with_layout do
      erb <<~ERB
        <form action="/events/#{@event.id}" method="post" class="max-w-sm p-6 mx-auto mt-10 bg-white border border-gray-200 rounded-lg shadow-md space-y-4 dark:bg-gray-800 dark:border-gray-700">
          <input type="hidden" name="_method" value="put">
          <div class="p-4">
            <h2 class="m-8 text-xl font-semibold text-gray-900 dark:text-white">Edit Event</h2>
            <div class="mb-3">
              <label for="name" class="block text-sm font-medium text-gray-400 dark:text-gray-300">Name</label>
              <input type="text" name="name" id="name" value="#{@event.name}" required class="block w-full mt-1 text-gray-900 bg-white border border-gray-300 rounded-md dark:border-gray-600 dark:bg-gray-700 dark:text-white focus:border-blue-500 focus:ring-blue-500">
            </div>
            <div class="mb-3">
              <label for="place" class="block text-sm font-medium text-gray-400 dark:text-gray-300">Place</label>
              <input type="text" name="place" id="place" value="#{@event.place}" required class="block w-full mt-1 text-gray-900 bg-white border border-gray-300 rounded-md dark:border-gray-600 dark:bg-gray-700 dark:text-white focus:border-blue-500 focus:ring-blue-500">
            </div>
            <div class="mb-3">
              <label for="thing" class="block text-sm font-medium text-gray-400 dark:text-gray-300">Thing</label>
              <input type="text" name="thing" id="thing" value="#{@event.thing}" required class="block w-full mt-1 text-gray-900 bg-white border border-gray-300 rounded-md dark:border-gray-600 dark:bg-gray-700 dark:text-white focus:border-blue-500 focus:ring-blue-500">
            </div>
            <div class="mb-3">
              <button type="submit" class="w-full px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                Update
              </button>
            </div>
          </div>
        </form>
      ERB
    end
  end

  put "/events/:id" do
    event = Event.find(params[:id])
    event.update(
      name: params[:name],
      place: params[:place],
      thing: params[:thing]
    )
    redirect "/events"
  end

  get "/events" do
    last_event = Event.order(updated_at: :desc).first
    etag last_event&.sha1
    last_modified last_event&.updated_at

    @events = Event.order(updated_at: :desc)

    respond_to do |f|
      f.html do
        render_with_layout do
          erb <<~ERB
            <h1>Events <%= @events.count %></h1>
            <div class="my-4">
              <a href="/events/new" class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
                New Event
              </a>
            </div>
            <div class="grid lg:grid-cols-3 md:grid-cols-2 sm:grid-cols-2 gap-4">
              <% @events.each do |event| %>
                <%= render_card(event) %>
              <% end %>
            </div>
          ERB
        end
      end

      f.json { json @events.map(&:to_h) }
    end
  end

  get "/events/:id" do
    @event = Event.find(params[:id])
    respond_to do |f|
      last_modified @event.updated_at
      etag @event.sha1
      f.html do
        render_with_layout do
          erb <<~ERB
            <div id="hxt-event">
              <div class="p-4">
                <button class="btn" hx-post="/events?name=slim&place=home" hx-swap="innerHTML" hx-target="#hxt-event">
                  Click Me
                </button>
              </div>
              <%= render_card(@event) %>
            </div>
          ERB
        end
      end
      f.json { @event.to_h }
    end
  end

  post "/events" do
    @event = Event.new
    @event.created_at = Time.now
    @event.updated_at = Time.now
    @event.name = params[:name]
    @event.place = params[:place]
    @event.thing = params[:thing]
    @event.save

    respond_to do |f|
      f.html { hx_redirect("/events") }
      f.json { @event.to_h }
    end
  end

  run! if __FILE__ == $0
end
