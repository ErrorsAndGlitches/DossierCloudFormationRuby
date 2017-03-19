require 'cloudformation-ruby-dsl/cfntemplate'

require 'code_pipeline_role_policy_doc'
require 'code_build_role_policy_doc'
require 'dossier_cp_stages'
require 'lambda_cp_stages'
require 'lambda_function_role_policy_doc'

template do
  @stack_name = 'dossier-system'
  stage_num = ENV['STAGE'].to_i

  github_oauth_token_name = 'GitHubOauthToken'
  parameter(
    github_oauth_token_name,
    {
      Type: 'String',
      Description: 'The GitHub OAuth token used for CodePipeline and CodeBuild to access the GitHub repositories.',
      NoEcho: true # mask the value
    }
  )

  cb_build_failure_phone_number = 'BuildFailurePhoneNum'
  parameter(
    cb_build_failure_phone_number,
    {
      Type: 'String',
      Description: 'The phone number that will receive a notification if a CodeBuild build fails e.g. +1xxxyyyzzzz',
      NoEcho: true # mask the value
    }
  )

  trigger_bucket_source_account = 'LambdaTriggerBucketSourceAccount'
  parameter(
    trigger_bucket_source_account,
    {
      Type: 'String',
      Description: 'The source account number that owns the bucket that will trigger the Lambda function.',
      NoEcho: true # mask the value
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

  # TODO: both the Latex and Lambda CodeBuild project reference the same Role thus the Role's permissions are too wide.
  cb_role_name = 'CodeBuildRole'
  resource cb_role_name,
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

  cp_assume_role_policy_name = 'CodePipelineAssumeRolePolicy'
  resource cp_assume_role_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: cp_assume_role_policy_name,
      PolicyDocument: CodePipelineRolePolicyDoc.policy_document,
      Roles: [ref(cp_role_name)]
    }

  lambda_func_name = 'S3DropboxLambdaFunction'
  dossier_artifacts_bucket_name = 'DossierCodePipelineArtifactsBucket'
  dossier_pdf_key = 'DossierLatexPdfs/dossier-latex-pdfs.zip'
  resource dossier_artifacts_bucket_name,
    Type: 'AWS::S3::Bucket',
    Properties: stage_num >= 2 ? {
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
      }
    } : {}

  dossier_lambda_code_bucket = 'DossierLambdaCodeBucket'
  resource dossier_lambda_code_bucket,
    Type: 'AWS::S3::Bucket'

  ##################################################################
  # Latex Compilation Pipeline
  ##################################################################

  latex_cb_proj_name = 'DossierLatexCodeBuildProject'
  latex_cb_assume_role_policy_name = 'DossierLatexCodeBuildAssumeRolePolicy'
  resource latex_cb_assume_role_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: latex_cb_assume_role_policy_name,
      PolicyDocument: CodeBuildRolePolicyDoc.cb_policy_document(
        latex_cb_proj_name,
        ref(dossier_artifacts_bucket_name)
      ),
      Roles: [ref(cb_role_name)]
    }

  resource latex_cb_proj_name,
    Type: 'AWS::CodeBuild::Project',
    Properties: {
      Name: latex_cb_proj_name,
      Description: 'Compile the latex documents into PDFs',
      ServiceRole: get_att(cb_role_name, 'Arn'),
      Source: {
        Type: 'CODEPIPELINE'
      },
      Environment: {
        Type: 'LINUX_CONTAINER',
        Image: 'errorsandglitches/ubuntu-latex',
        ComputeType: 'BUILD_GENERAL1_SMALL',
        EnvironmentVariables: [
          {
            Name: 'DOSSIER_PDF_ZIP_FILE_NAME',
            Value: 'dossier-latex-pdfs.zip'
          },
          {
            Name: 'DOSSIER_PDF_BUCKET',
            Value: ref(dossier_artifacts_bucket_name)
          },
          {
            Name: 'DOSSIER_PDF_KEY',
            Value: dossier_pdf_key
          },
          {
            Name: 'BUILD_FAILURE_PHONE_NUM',
            Value: ref(cb_build_failure_phone_number)
          }
        ]
      },
      Artifacts: {
        Type: 'CODEPIPELINE',
        Location: ref(dossier_artifacts_bucket_name),
        Packaging: 'ZIP'
      },
      TimeoutInMinutes: 5
    }

  latex_cp_name = 'DossierLatexCodePipeline'
  resource latex_cp_name,
    Type: 'AWS::CodePipeline::Pipeline',
    Properties: {
      RoleArn: get_att(cp_role_name, 'Arn'),
      Stages: DossierCpStages.code_pipeline_stages(ref(latex_cb_proj_name)),
      ArtifactStore: {
        Type: 'S3',
        Location: ref(dossier_artifacts_bucket_name)
      },
      RestartExecutionOnUpdate: true
    }

  ##################################################################
  # Lambda Pipeline
  ##################################################################

  lambda_cb_proj_name = 'DossierLambdaCodeBuildProject'
  lambda_cb_assume_role_policy_name = 'DossierLambdaCodeBuildAssumeRolePolicy'
  resource lambda_cb_assume_role_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: lambda_cb_assume_role_policy_name,
      PolicyDocument: CodeBuildRolePolicyDoc.cb_policy_document(
        lambda_cb_proj_name,
        ref(dossier_lambda_code_bucket)
      ),
      Roles: [ref(cb_role_name)]
    }

  lambda_code_jar_key = 'S3DropboxLambdaJar/S3-dropbox-lambda-assembly.jar'
  resource lambda_cb_proj_name,
    Type: 'AWS::CodeBuild::Project',
    Properties: {
      Name: lambda_cb_proj_name,
      Description: 'Compile and assemble the AWS Lambda',
      ServiceRole: get_att(cb_role_name, 'Arn'),
      Source: {
        Type: 'CODEPIPELINE'
      },
      Environment: {
        Type: 'LINUX_CONTAINER',
        Image: '1science/sbt',
        ComputeType: 'BUILD_GENERAL1_SMALL',
        EnvironmentVariables: [
          {
            Name: 'LAMBDA_CODE_JAR_BUCKET',
            Value: ref(dossier_lambda_code_bucket)
          },
          {
            Name: 'LAMBDA_CODE_JAR_KEY',
            Value: lambda_code_jar_key
          },
          {
            Name: 'BUILD_FAILURE_PHONE_NUM',
            Value: ref(cb_build_failure_phone_number)
          }
        ]
      },
      Artifacts: {
        Type: 'CODEPIPELINE',
        Location: ref(dossier_artifacts_bucket_name)
      },
      TimeoutInMinutes: 10
    }

  lambda_cp_name = 'DossierLambdaCodePipeline'
  resource lambda_cp_name,
    Type: 'AWS::CodePipeline::Pipeline',
    Properties: {
      RoleArn: get_att(cp_role_name, 'Arn'),
      Stages: LambdaCpStages.code_pipeline_stages(ref(github_oauth_token_name), ref(lambda_cb_proj_name)),
      ArtifactStore: {
        Type: 'S3',
        Location: ref(dossier_artifacts_bucket_name)
      },
      RestartExecutionOnUpdate: true
    }

  ##################################################################
  # Lambda Function
  ##################################################################

  if stage_num >= 1
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

    lambda_assume_role_policy_name = 'DossierLambdaFunctionAssumeRolePolicy'
    resource lambda_assume_role_policy_name,
      Type: 'AWS::IAM::Policy',
      Properties: {
        PolicyName: lambda_assume_role_policy_name,
        PolicyDocument: LambdaFunctionRolePolicyDoc.lambda_policy_document(
          ref(lambda_func_name),
          ref(dossier_artifacts_bucket_name),
          dossier_pdf_key
        ),
        Roles: [ref(lambda_role)]
      }

    resource lambda_func_name,
      Type: 'AWS::Lambda::Function',
      Properties: {
        Code: {
          S3Bucket: ref(dossier_lambda_code_bucket),
          S3Key: lambda_code_jar_key
        },
        Description: 'A Lambda Function to copy the compiled Latex PDFs from S3 to Dropbox',
        Handler: 'com.s3dropbox.lambda.LambdaMain::handleRequest',
        Role: get_att(lambda_role, 'Arn'),
        Runtime: 'java8',
        MemorySize: 512,
        Timeout: 60
      }

    resource 'S3DropboxLambdaPermission',
      Type: 'AWS::Lambda::Permission',
      Properties: {
        Action: 'lambda:InvokeFunction',
        FunctionName: get_att(lambda_func_name, 'Arn'),
        Principal: 's3.amazonaws.com',
        SourceAccount: ref(trigger_bucket_source_account),
        SourceArn: sub(
          'arn:aws:s3:::${BucketName}',
          { BucketName: ref(dossier_artifacts_bucket_name) }
        )
      }
  end

  ##################################################################
  # Stack Outputs
  ##################################################################

  output(
    'LambdaPipelineName',
    {
      Description: 'The name of the CodePipeline that compiles and deploys the S3DropboxLambda AWS Lambda code.',
      Value: ref(lambda_cp_name)
    }
  )
end.exec!
