require "rubygems"
require "bundler"
def production? = ENV["APP_ENV"] == "production"
envs = [:default]
envs += [:development, :test] unless production?
Bundler.require(*envs)

#=====================================

require "sinatra/base"
require "sinatra/respond_with"
require "sinatra/activerecord"
require "jsonapi/serializer"
require "rack/cache"
require "digest/sha1"

#=====================================

APP_VERSION = "0.1"

class EventSerializer
  # https://github.com/jsonapi-serializer/jsonapi-serializer#model-definition
  include JSONAPI::Serializer

  set_type :event
  attributes :name, :place, :created_at
end

class Event < ActiveRecord::Base
  validates :name, presence: true
  # validates :place, presence: true

  def to_h
    EventSerializer.new(self).serializable_hash
  end

  def to_json
    to_h.to_json
  end

  def sha1
    Digest::SHA1.hexdigest("#{id}#{created_at}#{APP_VERSION}")
  end
end

class App < Sinatra::Base
  register Sinatra::RespondWith
  enable :inline_templates
  use Rack::Deflater
  use Rack::Cache

  module DatabaseHelpers
    def ensure_table(name)
      unless table_exists?(name)
        create_table name
      end
    end

    def ensure_column(table:, column:, type:)
      unless column_exists?(table, column)
        change_table table do |t|
          t.send(type, column)
        end
      end
    end
  end

  ActiveRecord::Schema.define do
    extend DatabaseHelpers
    ensure_table(:events)
    ensure_column(column: :name, type: :string, table: :events)
    ensure_column(column: :place, type: :string, table: :events)
    ensure_column(column: :thing, type: :string, table: :events)
    ensure_column(column: :created_at, type: :datetime, table: :events)
  end

  set :server, "puma"
  set :bind, "0.0.0.0"
  set :port, 3000
  set :strict_paths, false
  set :logging, true

  def hx_request? = request.env["HTTP_HX_REQUEST"].present?

  before do
    expires 500, :public, :must_revalidate
  end

  get "/" do
    etag APP_VERSION
    slim :index
  end

  get "/tw" do
    etag APP_VERSION
    slim :table
  end

  get "/events/new" do
    @event = Event.create(name: "Party", place: "House")
    respond_to do |f|
      etag @event.sha1
      f.html { slim :event }
      f.json { @event.to_json }
    end
  end

  get "/events/last" do
    @event = Event.last || Event.none
    respond_to do |f|
      etag @events.last&.sha1 || Time.now
      f.html { slim :event }
      f.json { @event.to_json }
    end
  end

  get "/events" do
    @events = Event.all
    @event_count = Event.count
    respond_to do |f|
      etag @events.last&.sha1 || Time.now
      f.html { slim :events }
      f.json { @events.map(&:to_h).to_json }
    end
  end

  get "/events/:id" do
    @event = Event.find(params[:id])
    @event_count = Event.count
    # last_modified @event.created_at
    respond_to do |f|
      etag @event.sha1
      f.html { slim :event, layout: !hx_request? }
      f.json { @event.to_json }
    end
  end

  post "/events" do
    @event = Event.create(name: params[:name])
    @event.created_at = Time.now
    @event.place = params[:place]
    @event.thing = params[:thing]
    @event.save

    @event_count = Event.count

    respond_to do |f|
      etag @event.sha1
      f.html { slim :event, layout: !hx_request? }
      f.json { @event.to_json }
    end
  end

  run! if __FILE__ == $0
end

__END__
#=====================================

@@index
  h1 Slim Sinatra Is Fun!

@@events
h1 Events #{@event_count}
ul
  - @events.each do |event|
    li: a[href="/events/#{event.id}"] = "#{event.name} #{event.created_at}"


@@event
#hxt-event
  h1.prose.prose-h1.text-4xl.font-bold.text-gray-200 = "Events  #{@event_count}"
  hr
  .p-4
    a.mr-4[href="/events"]: button.btn Go back

    button.btn[hx-post="/events?name=slim&place=home"
      hx-swap="innerHTML"
      hx-target="#hxt-event"] Click Me

  == slim :card

@@card
  .max-w-sm.bg-white.border.border-gray-200.rounded-lg.shadow-md.dark:bg-gray-800.dark:border-gray-700
    a href="#"
      img.rounded-t-lg alt="" src="/image-1.jpg" /
    .p-5
      a href="#"
      h5.mb-2.text-2xl.font-bold.tracking-tight.text-gray-900.dark:text-white
        = "#{@event&.name || "Hello"}@#{@event&.place || "World"}"
      p.mb-3.font-normal.text-gray-700.dark:text-gray-400
        = "#{@event.created_at || Time.now}"
      p.mb-3.font-normal.text-gray-700.dark:text-gray-400 Here are the biggest enterprise technology acquisitions of 2021 so far, in reverse chronological order.
      a.inline-flex.items-center.px-3.py-2.text-sm.font-medium.text-center.text-white.bg-blue-700.rounded-lg.hover:bg-blue-800.focus:ring-4.focus:outline-none.focus:ring-blue-300.dark:bg-blue-600.dark:hover:bg-blue-700.dark:focus:ring-blue-800 href="#"
        | Read more
        svg.w-4.h-4.ml-2.-mr-1 aria-hidden="true" fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
          path clip-rule="evenodd" d=("M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z") fill-rule="evenodd"

@@tabs
  .w-full.bg-white.border.rounded-lg.shadow-md.dark:bg-gray-800.dark:border-gray-700
    ul#defaultTab.flex.flex-wrap.text-sm.font-medium.text-center.text-gray-500.border-b.border-gray-200.rounded-t-lg.bg-gray-50.dark:border-gray-700.dark:text-gray-400.dark:bg-gray-800 data-tabs-toggle="#defaultTabContent" role="tablist"
      li.mr-2
        button#about-tab.inline-block.p-4.text-blue-600.rounded-tl-lg.hover:bg-gray-100.dark:bg-gray-800.dark:hover:bg-gray-700.dark:text-blue-500 aria-controls="about" aria-selected="true" data-tabs-target="#about" role="tab" type="button"  About
      li.mr-2
        button#services-tab.inline-block.p-4.hover:text-gray-600.hover:bg-gray-100.dark:hover:bg-gray-700.dark:hover:text-gray-300 aria-controls="services" aria-selected="false" data-tabs-target="#services" role="tab" type="button"  Services
      li.mr-2
        button#statistics-tab.inline-block.p-4.hover:text-gray-600.hover:bg-gray-100.dark:hover:bg-gray-700.dark:hover:text-gray-300 aria-controls="statistics" aria-selected="false" data-tabs-target="#statistics" role="tab" type="button"  Facts
    #defaultTabContent
      #about.hidden.p-4.bg-white.rounded-lg.md:p-8.dark:bg-gray-800 aria-labelledby="about-tab" role="tabpanel"
        h2.mb-3.text-3xl.font-extrabold.tracking-tight.text-gray-900.dark:text-white Powering innovation & trust at 200,000+ companies worldwide
        p.mb-3.text-gray-500.dark:text-gray-400 Empower Developers, IT Ops, and business teams to collaborate at high velocity. Respond to changes and deliver great customer and employee service experiences fast.
        a.inline-flex.items-center.font-medium.text-blue-600.hover:text-blue-800.dark:text-blue-500.dark:hover:text-blue-700 href="#"
          | Learn more
          svg.w-6.h-6.ml-1 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
            path clip-rule="evenodd" d=("M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z") fill-rule="evenodd"
      #services.hidden.p-4.bg-white.rounded-lg.md:p-8.dark:bg-gray-800 aria-labelledby="services-tab" role="tabpanel"
        h2.mb-5.text-2xl.font-extrabold.tracking-tight.text-gray-900.dark:text-white We invest in the world’s potential
        /! List
        ul.space-y-4.text-gray-500.dark:text-gray-400 role="list"
          li.flex.space-x-2
            /! Icon
            svg.flex-shrink-0.w-4.h-4.text-blue-600.dark:text-blue-500 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
              path clip-rule="evenodd" d=("M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z") fill-rule="evenodd"
            span.font-light.leading-tight Dynamic reports and dashboards
          li.flex.space-x-2
            /! Icon
            svg.flex-shrink-0.w-4.h-4.text-blue-600.dark:text-blue-500 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
              path clip-rule="evenodd" d=("M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z") fill-rule="evenodd"
            span.font-light.leading-tight Templates for everyone
          li.flex.space-x-2
            /! Icon
            svg.flex-shrink-0.w-4.h-4.text-blue-600.dark:text-blue-500 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
              path clip-rule="evenodd" d=("M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z") fill-rule="evenodd"
            span.font-light.leading-tight Development workflow
          li.flex.space-x-2
            /! Icon
            svg.flex-shrink-0.w-4.h-4.text-blue-600.dark:text-blue-500 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
              path clip-rule="evenodd" d=("M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z") fill-rule="evenodd"
            span.font-light.leading-tight Limitless business automation
      #statistics.hidden.p-4.bg-white.rounded-lg.md:p-8.dark:bg-gray-800 aria-labelledby="statistics-tab" role="tabpanel"
        dl.grid.max-w-screen-xl.grid-cols-2.gap-8.p-4.mx-auto.text-gray-900.sm:grid-cols-3.xl:grid-cols-6.dark:text-white.sm:p-8
        .flex.flex-col
          dt.mb-2.text-3xl.font-extrabold 73M+
          dd.font-light.text-gray-500.dark:text-gray-400 Developers
        .flex.flex-col
          dt.mb-2.text-3xl.font-extrabold 100M+
          dd.font-light.text-gray-500.dark:text-gray-400 Public repositories
        .flex.flex-col
          dt.mb-2.text-3xl.font-extrabold 1000s
          dd.font-light.text-gray-500.dark:text-gray-400 Open source projects




@@breadcrumb
  nav.flex.px-5.py-3.text-gray-700.border.border-gray-200.rounded-lg.bg-gray-50.dark:bg-gray-800.dark:border-gray-700 aria-label="Breadcrumb"
    ol.inline-flex.items-center.space-x-1.md:space-x-3
      li.inline-flex.items-center
        a.inline-flex.items-center.text-sm.font-medium.text-gray-700.hover:text-gray-900.dark:text-gray-400.dark:hover:text-white href="/"
          svg.w-4.h-4.mr-2 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
            path d=("M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z")
          | Home
      li
        .flex.items-center
          svg.w-6.h-6.text-gray-400 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
            path clip-rule="evenodd" d=("M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z") fill-rule="evenodd"
          a.ml-1.text-sm.font-medium.text-gray-700.hover:text-gray-900.md:ml-2.dark:text-gray-400.dark:hover:text-white href="/events"  Events
      li aria-current="page"
        .flex.items-center
          svg.w-6.h-6.text-gray-400 fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
            path clip-rule="evenodd" d=("M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z") fill-rule="evenodd"
          a.ml-1.text-sm.font-medium.text-gray-500.md:ml-2.dark:text-gray-400 href="/tw" All

@@table
  .max-w-2xl.mx-auto
    .flex.flex-col
      .overflow-x-auto.shadow-md.sm:rounded-lg
        .inline-block.min-w-full.align-middle
          .overflow-hidden
            table.min-w-full.divide-y.divide-gray-200.table-fixed.dark:divide-gray-700
              thead.bg-gray-100.dark:bg-gray-700
                tr
                  th.p-4 scope="col"
                    .flex.items-center
                      input#checkbox-all.w-4.h-4.text-blue-600.bg-gray-100.rounded.border-gray-300.focus:ring-blue-500.dark:focus:ring-blue-600.dark:ring-offset-gray-800.focus:ring-2.dark:bg-gray-700.dark:border-gray-600 type="checkbox" /
                      label.sr-only for="checkbox-all"  checkbox
                  th.py-3.px-6.text-xs.font-medium.tracking-wider.text-left.text-gray-700.uppercase.dark:text-gray-400 scope="col"
                    | Product Name
                  th.py-3.px-6.text-xs.font-medium.tracking-wider.text-left.text-gray-700.uppercase.dark:text-gray-400 scope="col"
                    | Category
                  th.py-3.px-6.text-xs.font-medium.tracking-wider.text-left.text-gray-700.uppercase.dark:text-gray-400 scope="col"
                    | Price
                  th.p-4 scope="col"
                    span.sr-only Edit
              tbody.bg-white.divide-y.divide-gray-200.dark:bg-gray-800.dark:divide-gray-700
                tr.hover:bg-gray-100.dark:hover:bg-gray-700
                  td.p-4.w-4
                    .flex.items-center
                      input#checkbox-table-1.w-4.h-4.text-blue-600.bg-gray-100.rounded.border-gray-300.focus:ring-blue-500.dark:focus:ring-blue-600.dark:ring-offset-gray-800.focus:ring-2.dark:bg-gray-700.dark:border-gray-600 type="checkbox" /
                      label.sr-only for="checkbox-table-1"  checkbox
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white Apple Imac 27"
                  td.py-4.px-6.text-sm.font-medium.text-gray-500.whitespace-nowrap.dark:text-white Desktop PC
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white $1999
                  td.py-4.px-6.text-sm.font-medium.text-right.whitespace-nowrap
                    a.text-blue-600.dark:text-blue-500.hover:underline href="#"  Edit
                tr.hover:bg-gray-100.dark:hover:bg-gray-700
                  td.p-4.w-4
                    .flex.items-center
                      input#checkbox-table-2.w-4.h-4.text-blue-600.bg-gray-100.rounded.border-gray-300.focus:ring-blue-500.dark:focus:ring-blue-600.dark:ring-offset-gray-800.focus:ring-2.dark:bg-gray-700.dark:border-gray-600 type="checkbox" /
                      label.sr-only for="checkbox-table-2"  checkbox
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white Apple MacBook Pro 17"
                  td.py-4.px-6.text-sm.font-medium.text-gray-500.whitespace-nowrap.dark:text-white Laptop
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white $2999
                  td.py-4.px-6.text-sm.font-medium.text-right.whitespace-nowrap
                    a.text-blue-600.dark:text-blue-500.hover:underline href="#"  Edit
                tr.hover:bg-gray-100.dark:hover:bg-gray-700
                  td.p-4.w-4
                    .flex.items-center
                      input#checkbox-table-3.w-4.h-4.text-blue-600.bg-gray-100.rounded.border-gray-300.focus:ring-blue-500.dark:focus:ring-blue-600.dark:ring-offset-gray-800.focus:ring-2.dark:bg-gray-700.dark:border-gray-600 type="checkbox" /
                      label.sr-only for="checkbox-table-3"  checkbox
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white iPhone 13 Pro
                  td.py-4.px-6.text-sm.font-medium.text-gray-500.whitespace-nowrap.dark:text-white Phone
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white $999
                  td.py-4.px-6.text-sm.font-medium.text-right.whitespace-nowrap
                    a.text-blue-600.dark:text-blue-500.hover:underline href="#"  Edit
                tr.hover:bg-gray-100.dark:hover:bg-gray-700
                  td.p-4.w-4
                    .flex.items-center
                      input#checkbox-table-4.w-4.h-4.text-blue-600.bg-gray-100.rounded.border-gray-300.focus:ring-blue-500.dark:focus:ring-blue-600.dark:ring-offset-gray-800.focus:ring-2.dark:bg-gray-700.dark:border-gray-600 type="checkbox" /
                      label.sr-only for="checkbox-table-4"  checkbox
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white Apple Magic Mouse 2
                  td.py-4.px-6.text-sm.font-medium.text-gray-500.whitespace-nowrap.dark:text-white Accessories
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white $99
                  td.py-4.px-6.text-sm.font-medium.text-right.whitespace-nowrap
                    a.text-blue-600.dark:text-blue-500.hover:underline href="#"  Edit
                tr.hover:bg-gray-100.dark:hover:bg-gray-700
                  td.p-4.w-4
                    .flex.items-center
                      input#checkbox-table-5.w-4.h-4.text-blue-600.bg-gray-100.rounded.border-gray-300.focus:ring-blue-500.dark:focus:ring-blue-600.dark:ring-offset-gray-800.focus:ring-2.dark:bg-gray-700.dark:border-gray-600 type="checkbox" /
                      label.sr-only for="checkbox-table-5"  checkbox
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white Apple Watch Series 7
                  td.py-4.px-6.text-sm.font-medium.text-gray-500.whitespace-nowrap.dark:text-white Accessories
                  td.py-4.px-6.text-sm.font-medium.text-gray-900.whitespace-nowrap.dark:text-white $599
                  td.py-4.px-6.text-sm.font-medium.text-right.whitespace-nowrap
                    a.text-blue-600.dark:text-blue-500.hover:underline href="#"  Edit



@@nav
  nav.bg-white.border-gray-200.px-2.sm:px-4.rounded.dark:bg-gray-900 class="py-2.5"
    .container.flex.flex-wrap.items-center.justify-between.mx-auto
      a.flex.items-center href="/"
        img.h-6.mr-3.sm:h-9 src="/logo.svg" /
        span.self-center.text-xl.font-semibold.whitespace-nowrap.dark:text-white Bfield.app
      .flex.md:order-2
        button.text-white.bg-blue-700.hover:bg-blue-800.focus:ring-4.focus:outline-none.focus:ring-blue-300.font-medium.rounded-lg.text-sm.px-5.text-center.mr-3.md:mr-0.dark:bg-blue-600.dark:hover:bg-blue-700.dark:focus:ring-blue-800 class="py-2.5" type="button"  Get started
        button.inline-flex.items-center.p-2.text-sm.text-gray-500.rounded-lg.md:hidden.hover:bg-gray-100.focus:outline-none.focus:ring-2.focus:ring-gray-200.dark:text-gray-400.dark:hover:bg-gray-700.dark:focus:ring-gray-600 aria-controls="navbar-cta" aria-expanded="false" data-collapse-toggle="navbar-cta" type="button"
          span.sr-only Open main menu
          svg.w-6.h-6 aria-hidden="true" fill="currentColor" viewbox=("0 0 20 20") xmlns="http://www.w3.org/2000/svg"
            path clip-rule="evenodd" d=("M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z") fill-rule="evenodd"
      #navbar-cta.items-center.justify-between.hidden.w-full.md:flex.md:w-auto.md:order-1
        ul.flex.flex-col.p-4.mt-4.border.border-gray-100.rounded-lg.bg-gray-50.md:flex-row.md:space-x-8.md:mt-0.md:text-sm.md:font-medium.md:border-0.md:bg-white.dark:bg-gray-800.md:dark:bg-gray-900.dark:border-gray-700
          li
            a.block.py-2.pl-3.pr-4.text-white.bg-blue-700.rounded.md:bg-transparent.md:text-blue-700.md:p-0.dark:text-white aria-current="page" href="#"  Home
          li
            a.block.py-2.pl-3.pr-4.text-gray-700.rounded.hover:bg-gray-100.md:hover:bg-transparent.md:hover:text-blue-700.md:p-0.md:dark:hover:text-white.dark:text-gray-400.dark:hover:bg-gray-700.dark:hover:text-white.md:dark:hover:bg-transparent.dark:border-gray-700 href="#"  About
          li
            a.block.py-2.pl-3.pr-4.text-gray-700.rounded.hover:bg-gray-100.md:hover:bg-transparent.md:hover:text-blue-700.md:p-0.md:dark:hover:text-white.dark:text-gray-400.dark:hover:bg-gray-700.dark:hover:text-white.md:dark:hover:bg-transparent.dark:border-gray-700 href="#"  Services
          li
            a.block.py-2.pl-3.pr-4.text-gray-700.rounded.hover:bg-gray-100.md:hover:bg-transparent.md:hover:text-blue-700.md:p-0.md:dark:hover:text-white.dark:text-gray-400.dark:hover:bg-gray-700.dark:hover:text-white.md:dark:hover:bg-transparent.dark:border-gray-700 href="#"  Contact

@@layout
  doctype html
  html
    head
      == slim :head

    body.bg-gray-900.text-white
      == slim :nav
      == slim :breadcrumb
      .md:container.md:mx-auto.px-4.p-4
        == yield
      footer
      script src="/htmx.min.js"
      script src="/flowbite.js"

@@head
  meta charset="utf-8"
  meta name="viewport" content="width=device-width, initial-scale=1.0"
  link rel="stylesheet" href="/tailwind.css"

  title Bfield.app
