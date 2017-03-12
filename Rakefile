require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dossier do

  OAUTH_TOKEN_KEY = :github_oauth_token

  def run_cf_command(command, *args)
    dir = File.dirname(__FILE__)
    rlib_dir = File.join(dir, 'lib')
    cf_script_file = File.join(dir, 'bin', 'create-dossier-cf-template.rb')

    puts `ruby -I#{rlib_dir} #{cf_script_file} #{command} --region us-west-2 #{args.join(' ')}`
  end

  def oauth_token(args)
    oauth_token = args[:github_oauth_token]
    if oauth_token.nil?
      STDERR.puts 'Github OAuth token must be specified in the rake command e.g. rake task[args]'
      exit 1
    else
      oauth_token
    end
  end

  # For command options, see https://github.com/bazaarvoice/cloudformation-ruby-dsl
  # valid commands are:
  #   help|expand|diff|validate|create|update|cancel-update|delete|describe|describe-resource|get-template
  desc 'Run the Dossier system cloud formation template command'
  task :run, [:command] do |t, args|
    run_cf_command(args[:command])
  end

  desc 'Validate the template'
  task :validate do Rake::Task['dossier:run'].invoke(:validate) end

  desc 'Print template to STDOUT'
  task :print do Rake::Task['dossier:run'].invoke(:expand) end

  desc 'Create template'
  task :create, [OAUTH_TOKEN_KEY] do |t, args|
    run_cf_command(:create, '--parameters', "GitHubOauthToken=#{oauth_token(args)}")
  end

  desc 'Update template'
  task :update, [OAUTH_TOKEN_KEY] do |t, args|
    run_cf_command(:update, '--parameters', "GitHubOauthToken=#{oauth_token(args)}")
  end

  desc 'Delete template'
  task :delete do Rake::Task['dossier:run'].invoke(:delete) end

  desc 'Check if diff with existing template'
  task :diff, [OAUTH_TOKEN_KEY] do |t, args|
    run_cf_command(:diff, '--parameters', "GitHubOauthToken=#{oauth_token(args)}")
  end

  desc 'Help'
  task :help do Rake::Task['dossier:run'].invoke(:help) end
end
