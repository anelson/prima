require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

Rake::TestTask.new('test:benchmark') do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_benchmark.rb'
end

Rake::TestTask.new('test:profile') do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_profile.rb'
end

Rake::TestTask.new('test:sandbox') do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_sandbox.rb'
end

desc "Run tests"
task :default => :test
