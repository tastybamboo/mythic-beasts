require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task default: [:standard, :spec]

desc "Run tests and linters"
task test: [:standard, :spec]

desc "Fix standard violations automatically"
task fix: ["standard:fix"]
