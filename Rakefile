require "rake/testtask"
require "rails"
require "minitest/autorun"

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/duke/*_test.rb"
  t.warning = false 
end
task :default => :test
