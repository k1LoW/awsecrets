require 'bundler/gem_tasks'

begin
  require 'rspec'
  require 'rspec/core'
  require 'rspec/core/rake_task'
  require 'octorelease'
  require 'rubocop/rake_task'
rescue LoadError
end

desc 'Default task: run spec'
task default: 'spec'

desc 'Run spec:all - spec:core and spec:rubocop'
task spec: 'spec:all'
namespace :spec do
  task all: ['spec:core', 'spec:rubocop']
  RSpec::Core::RakeTask.new(:core)
  RuboCop::RakeTask.new
end
