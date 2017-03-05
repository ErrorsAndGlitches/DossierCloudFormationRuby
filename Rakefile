require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dossier do
  desc 'Run the program to create the Dossier cloud formation template'
  task :run do
    dir = File.dirname(__FILE__)
    puts `ruby -I#{File.join(dir, 'lib')} #{File.join(dir, 'bin', 'create-dossier-cf-template.rb')}`
  end
end
