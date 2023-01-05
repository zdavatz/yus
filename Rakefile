#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/gem_tasks'
require 'rake/testtask'


# dependencies are now declared in bbmb.gemspec
desc 'Offer a gem task like hoe'
task :gem => :build do
  Rake::Task[:build].invoke
end

desc 'test using minittest via test/suite.rb'
task :test do |t|
  $LOAD_PATH << File.dirname(__FILE__)
  require 'test/suite'
end

require 'rake/clean'
CLEAN.include FileList['pkg/*.gem']
