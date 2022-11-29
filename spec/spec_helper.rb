$: << File.join(File.dirname(__FILE__), "..", "lib/app")
require "script"
require "index"

require "capybara/rspec"
Capybara.app = App
Capybara.server = :puma
