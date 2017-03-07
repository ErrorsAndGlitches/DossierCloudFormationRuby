require 'cloudformation-ruby-dsl/cfntemplate'

require 'code_pipeline_role_policy_doc'
require 'code_build_role_policy_doc'
require 'dossier_cp_stages'

template do
  @stack_name = 'dossier-system'

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

  dossier_artifacts_bucket_name = 'DossierCodePipelineArtifactsBucket'
  resource dossier_artifacts_bucket_name,
    Type: 'AWS::S3::Bucket'

  latex_cb_proj_name = 'DossierLatexCodeBuildProject'
  latex_cb_assume_role_policy_name = 'DossierLatexCodeBuildAssumeRolePolicy'
  resource latex_cb_assume_role_policy_name,
    Type: 'AWS::IAM::Policy',
    Properties: {
      PolicyName: latex_cb_assume_role_policy_name,
      PolicyDocument: CodeBuildRolePolicyDoc.latex_cb_policy_document(
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
        ComputeType: 'BUILD_GENERAL1_SMALL'
      },
      Artifacts: {
        Name: 'dossier-latex-files.zip',
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
      Name: latex_cp_name,
      RestartExecutionOnUpdate: true
    }

  # NOTES: need to build the pipeline for the lambda and its deployment
end.exec!
