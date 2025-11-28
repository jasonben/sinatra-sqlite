# frozen_string_literal: true

require "rspec/core/rake_task"
require "./lib/app/index"
require "pry"

RSpec::Core::RakeTask.new do |task|
  task.rspec_opts = ["--color", "--format", "doc"]
end

task :console do
  Pry.start
end
