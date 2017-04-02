require 'rspec/core/rake_task'

$LOAD_PATH.unshift(File.join(File.expand_path(__dir__), 'rakelib'))
$LOAD_PATH.unshift(File.join(File.expand_path(__dir__), 'sharelib'))

require 'cf_template_constants'

require 'rake_task_args'
require 'rake_task_arg_keys'
require 'rake_cf_template_cmd'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dossier do
  include RakeTaskArgKeys
  include CfTemplateConstants

  REQUIRED_PARAMETERS = [
    rt_github_oauth_token_key,
    rt_cb_build_failure_phone_num_key,
    rt_stage_num_key,
    rt_dbx_token_key
  ]

  # For command options, see https://github.com/bazaarvoice/cloudformation-ruby-dsl
  # valid commands are:
  #   help|expand|diff|validate|create|update|cancel-update|delete|describe|describe-resource|get-template
  desc 'Run the Dossier system cloud formation template command'
  task :run, [:command].concat(REQUIRED_PARAMETERS) do |t, args|
    rake_args = RakeTaskArgs.new(args)
    RakeCfTemplateCmd
      .new(rake_args, rake_args.value(:command))
      .run
  end

  desc 'Validate the template'
  task :validate, REQUIRED_PARAMETERS do |t, args|
    RakeCfTemplateCmd
      .new(RakeTaskArgs.new(args), :validate)
      .run
  end

  desc 'Print the JSON that describes the template'
  task :print, REQUIRED_PARAMETERS do |t, args|
    RakeCfTemplateCmd
      .new(RakeTaskArgs.new(args), :expand)
      .run
  end

  desc "Deploy the given CloudFormationStage; valid values are #{valid_stages}"
  task :deploy_stage, REQUIRED_PARAMETERS do |t, args|
    rake_args = RakeTaskArgs.new(args)
    command = is_first_stage?(rake_args.value(rt_stage_num_key).to_i) ? :create : :update
    RakeCfTemplateCmd
      .new(rake_args, command)
      .run
  end

  desc 'Check if diff with existing template'
  task :diff, REQUIRED_PARAMETERS do |t, args|
    RakeCfTemplateCmd
      .new(RakeTaskArgs.new(args), :diff)
      .run
  end

  desc 'Delete template'
  task :delete, REQUIRED_PARAMETERS do |t, args|
    RakeCfTemplateCmd
      .new(RakeTaskArgs.new(args), :delete)
      .run
  end

  desc 'Help'
  task :help do Rake::Task['dossier:run'].invoke(:help) end
end
