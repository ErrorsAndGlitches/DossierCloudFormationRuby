require 'cf_template_constants'

require 'rake_task_arg_keys'
require 'bincmd/env_param'
require 'bincmd/bin_exe'
require 'bincmd/cf_parameters_option'
require 'kms_encryption'
require 'cloud_formation_output'

class RakeCfTemplateCmd
  include RakeTaskArgKeys
  include CfTemplateConstants

  @@REGION = 'us-west-2'

  def initialize(rake_args, command)
    @rake_args = rake_args
    @command = command
  end

  def run
    puts `\
      #{EnvParam.new(cf_stage_env_var_key, stage_num)} \
      #{BinExe.new('create-dossier-cf-template.rb')} \
      #{@command} \
      --region #{@@REGION} \
      #{CfParametersOption.new(cf_params)} \
    `
  end

  private

  def stage_num
    @rake_args.value(rt_stage_num_key).to_i
  end

  def cf_params
    [
      {
        key: cf_github_connection_arn_param,
        value: @rake_args.value(rt_github_connection_arn_key)
      },
      {
        key: cf_cb_build_failure_phone_num_param,
        value: @rake_args.value(rt_cb_build_failure_phone_num_key)
      }
    ]
  end
end