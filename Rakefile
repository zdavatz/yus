require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

desc 'test using minittest via test/suite.rb'
Rake::TestTask.new do |t|
  $LOAD_PATH << File.dirname(__FILE__)
  require 'test/suite'
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
end


