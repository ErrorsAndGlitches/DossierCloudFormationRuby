module CfTemplateConstants

  def cf_stack_name
    'dossier-system'
  end

  def cf_github_connection_arn_param
    'GitHubConnectionArn'
  end

  def cf_cb_build_failure_phone_num_param
    'BuildFailurePhoneNum'
  end

  def cf_stage_env_var_key
    'STAGE'
  end

  def cf_lambda_env_var_kms_key
    'LambdaEnvironmentVariableKmsKey'
  end

  def is_first_stage?(stage_num)
    stage_num == 0
  end

  def is_lambda_pipeline_stage?(stage_num)
    stage_num >= 1
  end

  def is_s3_trigger_stage?(stage_num)
    stage_num >= 1
  end

  def valid_stages
    [*0..1]
  end
end
