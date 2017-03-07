require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dossier do

  # For command options, see https://github.com/bazaarvoice/cloudformation-ruby-dsl
  # valid commands are:
  #   help|expand|diff|validate|create|update|cancel-update|delete|describe|describe-resource|get-template
  desc 'Run the Dossier system cloud formation template command'
  task :run, [:command] do |t, args|
    dir = File.dirname(__FILE__)
    puts `ruby -I#{File.join(dir, 'lib')} #{File.join(dir, 'bin', 'create-dossier-cf-template.rb')} #{args[:command]} --region us-west-2`
  end

  desc 'Validate the template'
  task :validate do Rake::Task['dossier:run'].invoke('validate') end

  desc 'Print template to STDOUT'
  task :print do Rake::Task['dossier:run'].invoke('expand') end

  desc 'Create template'
  task :create do Rake::Task['dossier:run'].invoke('create') end

  desc 'Update template'
  task :update do Rake::Task['dossier:run'].invoke('update') end

  desc 'Delete template'
  task :delete do Rake::Task['dossier:run'].invoke('delete ') end

  desc 'Check if diff with existing template'
  task :diff do Rake::Task['dossier:run'].invoke('diff') end

  desc 'Help'
  task :help do Rake::Task['dossier:run'].invoke('help') end
end
