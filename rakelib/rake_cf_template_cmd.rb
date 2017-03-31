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
    params = [
      {
        key: cf_github_oauth_token_param,
        value: @rake_args.value(rt_github_oauth_token_key)
      },
      {
        key: cf_cb_build_failure_phone_num_param,
        value: @rake_args.value(rt_cb_build_failure_phone_num_key)
      }
    ]

    if is_lambda_stage?(stage_num)
      params.concat [
        {
          key: cf_encrypted_db_app_key_param,
          value: encrypted_db_app_key_value
        },
        {
          key: cf_encrypted_db_secret_key_param,
          value: encrypted_db_secret_key_value
        }
      ]
    end

    params
  end

  def encrypted_db_app_key_value
    KmsEncryption
      .new(kms_arn)
      .encrypt(@rake_args.value(rt_dropbox_app_key_key))
  end

  def encrypted_db_secret_key_value
    KmsEncryption
      .new(kms_arn)
      .encrypt(@rake_args.value(rt_dropbox_secret_key_key))
  end

  def kms_arn
    CloudFormationOutput
      .new(cf_stack_name)
      .output_value(cf_lambda_env_var_kms_key)
  end
end