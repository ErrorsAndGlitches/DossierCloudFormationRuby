require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dossier do

  OAUTH_TOKEN_KEY = :github_oauth_token
  PHONE_NUM_KEY = :build_failure_phone_num_key
  AWS_ACCOUNT_NUM = :aws_account_num
  STAGE_KEY = :stage_key
  REQUIRED_PARAMETERS = [OAUTH_TOKEN_KEY, PHONE_NUM_KEY, AWS_ACCOUNT_NUM, STAGE_KEY]

  VALID_STAGES = [*0..2]

  # For command options, see https://github.com/bazaarvoice/cloudformation-ruby-dsl
  # valid commands are:
  #   help|expand|diff|validate|create|update|cancel-update|delete|describe|describe-resource|get-template
  desc 'Run the Dossier system cloud formation template command'
  task :run, [:command] do |t, args|
    run_cf_command(args[:command])
  end

  desc 'Validate the template'
  task :validate do Rake::Task['dossier:run'].invoke(:validate) end

  desc 'Check if diff with existing template'
  task :print, REQUIRED_PARAMETERS do |t, args|
    run_cf_command_with_params(:print, args)
  end

  desc "Deploy the given CloudFormationStage. Valid values are #{VALID_STAGES}"
  task :deploy_stage, REQUIRED_PARAMETERS do |t, args|
    stage_num = args_value(args, STAGE_KEY).to_i
    command = stage_num == 0 ? :create : :update
    run_cf_command_with_params(command, args)
  end

  desc 'Check if diff with existing template'
  task :diff, REQUIRED_PARAMETERS do |t, args|
    run_cf_command_with_params(:diff, args)
  end

  desc 'Delete template'
  task :delete do Rake::Task['dossier:run'].invoke(:delete) end

  desc 'Help'
  task :help do Rake::Task['dossier:run'].invoke(:help) end

  def run_cf_command(command)
    puts `#{base_ruby_command(command)}`
  end

  def run_cf_command_with_params(command, args)
    puts `STAGE=#{args_value(args, STAGE_KEY)} #{base_ruby_command(command)} --parameters #{cf_parameters(args)}`
  end

  def base_ruby_command(command)
    dir = File.dirname(__FILE__)
    rlib_dir = File.join(dir, 'lib')
    cf_script_file = File.join(dir, 'bin', 'create-dossier-cf-template.rb')

    "ruby -I#{rlib_dir} #{cf_script_file} #{command} --region us-west-2"
  end

  def cf_parameters(args)
    [
      "GitHubOauthToken=#{args_value(args, OAUTH_TOKEN_KEY)}",
      "BuildFailurePhoneNum=#{args_value(args, PHONE_NUM_KEY)}",
      "LambdaTriggerBucketSourceAccount=#{args_value(args, AWS_ACCOUNT_NUM)}"
    ].join(';').prepend('"').concat('"')
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
end
