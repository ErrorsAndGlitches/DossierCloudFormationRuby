require 'cloudformation-ruby-dsl/cfntemplate'

require 'cf_template_constants'

require 'code_pipeline_policy'
require 'latex_code_pipeline'
require 'latex_cb_policy'
require 'lambda_code_pipeline'
require 'lambda_cb_policy'
require 'lambda_function_policy'
require 'lambda_kms_policy'

# Open up the TemplateDSL class to add CfTemplateConstants module
TemplateDSL.class_eval do
  include CfTemplateConstants
end

template do
  @stack_name = cf_stack_name
  stage_num = ENV[cf_stage_env_var_key].to_i

  parameter(
    cf_github_connection_arn_param,
    {
      Type: 'String',
      Description: 'The GitHub OAuth token used for CodePipeline and CodeBuild to access the GitHub repositories.',
      NoEcho: true # mask the value
    }
  )

  parameter(
    cf_cb_build_failure_phone_num_param,
    {
      Type: 'String',
      Description: 'The phone number that will receive a notification if a CodeBuild build fails e.g. +1xxxyyyzzzz',
      NoEcho: true
    }
  )

  ##################################################################
  # Shared Resources
  ##################################################################

  cp_role_name = 'CodePipelineRole'
  resource cp_role_name,
    Type: 'AWS::IAM::Role',
    Properties: {
      AssumeRolePolicyDocument: {
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: ['codepipeline.amazonaws.com'] },
            Action: ['sts:AssumeRole']
          }
        ]
      },
      Path: '/'
    }

  cp_assume_role_policy_name = 'CodePipelineAssumeRolePolicy'
  resource cp_assume_role_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: cp_assume_role_policy_name,
      PolicyDocument: CodePipelinePolicy.document,
      Roles: [ref(cp_role_name)]
    }

  lambda_func_name = 'S3DropboxLambdaFunction'
  latex_bucket = 'LatexBucket'
  dossier_pdf_key = 'DossierLatexPdfs/dossier-latex-pdfs.zip'
  resource latex_bucket,
    Type: 'AWS::S3::Bucket',
    Properties: is_s3_trigger_stage?(stage_num) ? {
      NotificationConfiguration: {
        LambdaConfigurations: [
          {
            Event: 's3:ObjectCreated:*',
            Filter: {
              S3Key: {
                Rules: [
                  { Name: 'prefix', Value: dossier_pdf_key }
                ]
              }
            },
            Function: get_att(lambda_func_name, 'Arn')
          }
        ]
      },
      PublicAccessBlockConfiguration: {
        BlockPublicAcls: true,
        BlockPublicPolicy: true,
        IgnorePublicAcls: true,
        RestrictPublicBuckets: true
      }
    } : {}

  ##################################################################
  # Latex Compilation Pipeline
  ##################################################################

  latex_cb_role_name = 'LatexCodeBuildRole'
  resource latex_cb_role_name,
    Type: 'AWS::IAM::Role',
    Properties: {
      AssumeRolePolicyDocument: {
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: ['codebuild.amazonaws.com'] },
            Action: ['sts:AssumeRole']
          }
        ]
      },
      Path: '/'
    }

  latex_cb_proj_name = 'LatexCodeBuildProject'
  latex_cb_policy_name = 'LatexCodeBuildPolicy'
  resource latex_cb_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: latex_cb_policy_name,
      PolicyDocument: LatexCbPolicy.document(
        latex_cb_proj_name,
        ref(latex_bucket)
      ),
      Roles: [ref(latex_cb_role_name)]
    }

  resource latex_cb_proj_name,
    Type: 'AWS::CodeBuild::Project',
    Properties: {
      Name: latex_cb_proj_name,
      Description: 'Compile the latex documents into PDFs',
      ServiceRole: get_att(latex_cb_role_name, 'Arn'),
      Source: {
        Type: 'CODEPIPELINE'
      },
      Environment: {
        Type: 'LINUX_CONTAINER',
        Image: sub(
          '${AccountId}.dkr.ecr.us-west-2.amazonaws.com/errorsandglitches/ubuntu-latex:latest',
          AccountId: aws_account_id
        ),
        ComputeType: 'BUILD_GENERAL1_SMALL',
        EnvironmentVariables: [
          {
            Name: 'DOSSIER_PDF_ZIP_FILE_NAME',
            Value: 'dossier-latex-pdfs.zip'
          },
          {
            Name: 'DOSSIER_PDF_BUCKET',
            Value: ref(latex_bucket)
          },
          {
            Name: 'DOSSIER_PDF_KEY',
            Value: dossier_pdf_key
          },
          {
            Name: 'BUILD_FAILURE_PHONE_NUM',
            Value: ref(cf_cb_build_failure_phone_num_param)
          }
        ]
      },
      Artifacts: {
        Type: 'CODEPIPELINE',
        Location: ref(latex_bucket),
        Packaging: 'ZIP'
      },
      TimeoutInMinutes: 5
    }

  latex_cp_name = 'LatexCodePipeline'
  resource latex_cp_name,
    Type: 'AWS::CodePipeline::Pipeline',
    Properties: {
      RoleArn: get_att(cp_role_name, 'Arn'),
      Stages: LatexCodePipeline.stages(ref(latex_cb_proj_name)),
      ArtifactStore: {
        Type: 'S3',
        Location: ref(latex_bucket)
      },
      RestartExecutionOnUpdate: true
    }

  ##################################################################
  # Lambda Function
  ##################################################################
  lambda_role = 'S3DropboxLambdaRole'
  resource lambda_role,
    Type: 'AWS::IAM::Role',
    Properties: {
      AssumeRolePolicyDocument: {
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: ['lambda.amazonaws.com'] },
            Action: ['sts:AssumeRole']
          }
        ]
      },
      Path: '/service-role/'
    }

  resource cf_lambda_env_var_kms_key,
    Type: 'AWS::KMS::Key',
    Properties: {
      Description: 'The KMS key used to encrypt environment variables for the AWS Lambda function.',
      KeyPolicy: LambdaKmsPolicy.document(get_att(lambda_role, 'Arn'))
    }

  # This is just a placeholder Lambda function that is eventually updated by the package that contains the
  # implementation of the S3 to Dropbox publishing.
  resource lambda_func_name,
    Type: 'AWS::Lambda::Function',
    Properties: {
      Description: 'A Lambda Function to copy the compiled Latex PDFs from S3 to Dropbox',
      Handler: 'lambda_function.lambda_handler',
      Role: get_att(lambda_role, 'Arn'),
      Runtime: 'python2.7',
      Code: {
        ZipFile: %Q(
          def lambda_handler(event, context):
            return 'This is a placeholder implementation.'
        )
      },
      MemorySize: 512,
      Timeout: 60,
    }

  lambda_bucket = 'LambdaBucket'
  resource lambda_bucket,
    Type: 'AWS::S3::Bucket'

  lambda_assume_role_policy_name = 'LambdaFunctionAssumeRolePolicy'
  resource lambda_assume_role_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: lambda_assume_role_policy_name,
      PolicyDocument: LambdaFunctionPolicy.document(
        ref(lambda_func_name),
        ref(latex_bucket),
        dossier_pdf_key,
        ref(lambda_bucket)
      ),
      Roles: [ref(lambda_role)]
    }

  resource 'S3DropboxLambdaPermission',
    Type: 'AWS::Lambda::Permission',
    Properties: {
      Action: 'lambda:InvokeFunction',
      FunctionName: get_att(lambda_func_name, 'Arn'),
      Principal: 's3.amazonaws.com',
      SourceAccount: aws_account_id,
      SourceArn: sub(
        'arn:aws:s3:::${BucketName}',
        { BucketName: ref(latex_bucket) }
      )
    }

  ##################################################################
  # Lambda Pipeline
  ##################################################################

  if is_lambda_pipeline_stage?(stage_num)
    lambda_cb_role_name = 'LambdaCodeBuildRole'
    resource lambda_cb_role_name,
      Type: 'AWS::IAM::Role',
      Properties: {
        AssumeRolePolicyDocument: {
          Statement: [
            {
              Effect: 'Allow',
              Principal: { Service: ['codebuild.amazonaws.com'] },
              Action: ['sts:AssumeRole']
            }
          ]
        },
        Path: '/'
      }

    lambda_cb_proj_name = 'LambdaCodeBuildProject'
    lambda_cb_policy_name = 'LambdaCodeBuildPolicy'
    resource lambda_cb_policy_name,
      Type: 'AWS::IAM::Policy',
      Properties: {
        PolicyName: lambda_cb_policy_name,
        PolicyDocument: LambdaCbPolicy.document(lambda_cb_proj_name, ref(lambda_bucket)),
        Roles: [ref(lambda_cb_role_name)]
      }

    lambda_code_jar_key = 'S3DropboxLambdaJar/S3-dropbox-lambda-assembly.jar'
    resource lambda_cb_proj_name,
      Type: 'AWS::CodeBuild::Project',
      Properties: {
        Name: lambda_cb_proj_name,
        Description: 'Compile and assemble the AWS Lambda',
        ServiceRole: get_att(lambda_cb_role_name, 'Arn'),
        Source: {
          Type: 'CODEPIPELINE'
        },
        Environment: {
          Type: 'LINUX_CONTAINER',
          Image: 'mozilla/sbt',
          ComputeType: 'BUILD_GENERAL1_SMALL',
          EnvironmentVariables: [
            {
              Name: 'LAMBDA_CODE_JAR_BUCKET',
              Value: ref(lambda_bucket)
            },
            {
              Name: 'LAMBDA_CODE_JAR_KEY',
              Value: lambda_code_jar_key
            },
            {
              Name: 'LAMBDA_FUNCTION_ARN',
              Value: get_att(lambda_func_name, 'Arn')
            },
            {
              Name: 'BUILD_FAILURE_PHONE_NUM',
              Value: ref(cf_cb_build_failure_phone_num_param)
            },
            {
              Name: 'DBX_CREDENTIAL_KMS_ID',
              Value: ref(cf_lambda_env_var_kms_key)
            },
            {
              Name: 'DBX_CREDENTIAL_S3_KEY',
              Value: 'dbx-credentials.json'
            },
            {
              Name: 'DBX_CREDENTIAL_S3_BUCKET',
              Value: ref(lambda_bucket)
            },
          ]
        },
        Artifacts: {
          Type: 'CODEPIPELINE',
          Location: ref(lambda_bucket)
        },
        TimeoutInMinutes: 10
      }

    lambda_cp_name = 'LambdaCodePipeline'
    resource lambda_cp_name,
      Type: 'AWS::CodePipeline::Pipeline',
      Properties: {
        RoleArn: get_att(cp_role_name, 'Arn'),
        Stages: LambdaCodePipeline.stages(ref(cf_github_connection_arn_param), ref(lambda_cb_proj_name)),
        ArtifactStore: {
          Type: 'S3',
          Location: ref(lambda_bucket)
        },
        RestartExecutionOnUpdate: true
      }
  end

  ##################################################################
  # Stack Outputs
  ##################################################################

  output(
    cf_lambda_env_var_kms_key,
    {
      Description: 'The KMS key ARN that is used to encrypt the environment variables for the Lambda function.',
      Value: get_att(cf_lambda_env_var_kms_key, 'Arn')
    }
  )
end.exec!
