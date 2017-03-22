require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  require 'octorelease'
  require 'rubocop/rake_task'
rescue LoadError
end

task spec: 'spec:all'
namespace :spec do
  task all: ['spec:core',
             'spec:rubocop']
  RSpec::Core::RakeTask.new(:core)
  RuboCop::RakeTask.new
end
