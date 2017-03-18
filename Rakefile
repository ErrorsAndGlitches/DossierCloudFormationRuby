require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dossier do

  OAUTH_TOKEN_KEY = :github_oauth_token
  PHONE_NUM_KEY = :build_failure_phone_num_key
  REQUIRED_PARAMETERS = [OAUTH_TOKEN_KEY, PHONE_NUM_KEY]

  def run_cf_command_with_params(command, args)
    run_cf_command(
      command,
      '--parameters',
      [
        "GitHubOauthToken=#{args_value(args, OAUTH_TOKEN_KEY)}",
        "BuildFailurePhoneNum=#{args_value(args, PHONE_NUM_KEY)}"
      ].join(';').prepend('"').concat('"')
    )
  end

  def run_cf_command(command, *args)
    dir = File.dirname(__FILE__)
    rlib_dir = File.join(dir, 'lib')
    cf_script_file = File.join(dir, 'bin', 'create-dossier-cf-template.rb')

    puts `ruby -I#{rlib_dir} #{cf_script_file} #{command} --region us-west-2 #{args.join(' ')}`
  end

  def args_value(args, key)
    value = args[key]
    if value.nil?
      STDERR.puts "#{key} must be specified in the rake command e.g. rake task[args]"
      exit 1
    else
      value
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
  task :create, REQUIRED_PARAMETERS do |t, args|
    run_cf_command_with_params(:create, args)
  end

  desc 'Update template'
  task :update, REQUIRED_PARAMETERS do |t, args|
    run_cf_command_with_params(:update, args)
  end

  desc 'Delete template'
  task :delete do Rake::Task['dossier:run'].invoke(:delete) end

  desc 'Check if diff with existing template'
  task :diff, REQUIRED_PARAMETERS do |t, args|
    run_cf_command_with_params(:diff, args)
  end

  desc 'Help'
  task :help do Rake::Task['dossier:run'].invoke(:help) end
end
