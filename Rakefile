# encoding: UTF-8
begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "fluxx_grant"
    gem.summary = "Fluxx Grant Core"
    gem.email = "fluxx@acesfconsulting.com"
    gem.authors = ["Eric Hansen"]
    gem.files = Dir["{lib}/**/*", "{app}/**/*", "{config}/**/*"]
    gem.add_dependency('fastercsv', '>= 1.5.3')
    gem.add_dependency('formtastic-rails3', '>= 0.9.10.0')
    gem.add_dependency('haml', '>= 3')
#gem "will_paginate", :git => "http://github.com/mislav/will_paginate.git", :branch => "rails3"
    gem.add_development_dependency('jsmin', '>= 1.0.1')
    gem.add_development_dependency('thin', '>= 1.2.7')
    gem.add_development_dependency('json', '>= 1.4.3')
  end
rescue
  puts "Jeweler or dependency not available."
end

require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task :default => :test

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FluxxGrant'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name = "fluxx_grant"
  s.summary = "Insert FluxxGrant summary."
  s.description = "Insert FluxxGrant description."
  s.files =  FileList["[A-Z]*", "lib/**/*"]
  s.version = "0.0.1"
end

Rake::GemPackageTask.new(spec) do |pkg|
end

desc "Install the gem #{spec.name}-#{spec.version}.gem"
task :install do
  system("gem install pkg/#{spec.name}-#{spec.version}.gem --no-ri --no-rdoc")
end
require 'rcov/rcovtask'

desc "Create a cross-referenced code coverage report."
Rcov::RcovTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.rcov_opts << "--exclude \"test/*,gems/*,/Library/Ruby/*,config/*\" --rails"
end

