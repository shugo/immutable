require "rake"
require "rake/testtask"
require "rubygems/package_task"

require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :test

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require "yard"
require "yard/rake/yardoc_task"

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
  t.options = []
  t.options << '--debug' << '--verbose' if $trace
end
