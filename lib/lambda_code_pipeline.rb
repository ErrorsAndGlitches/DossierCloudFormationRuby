module LambdaCodePipeline
  def self.stages(git_hub_conn_arn, code_build_ref)
    lambda_src_snapshot_name = 'LambdaSourceSnapshot'
    [
      {
        Name: 'Source',
        Actions: [
          {
            Name: 'LambdaSourceAction',
            ActionTypeId: {
              Category: 'Source',
              Owner: 'AWS',
              Version: 1,
              Provider: 'CodeStarSourceConnection'
            },
            Configuration: {
              ConnectionArn: git_hub_conn_arn,
              FullRepositoryId: 'ErrorsAndGlitches/S3DropboxLambda',
              BranchName: 'master',
              OutputArtifactFormat: 'CODE_ZIP'
            },
            OutputArtifacts: [{ Name: lambda_src_snapshot_name }],
            RunOrder: 1
          }
        ]
      },
      {
        Name: 'Build',
        Actions: [
          {
            Name: 'LambdaCompilation',
            ActionTypeId: {
              Category: 'Build',
              Owner: 'AWS',
              Version: 1,
              Provider: 'CodeBuild'
            },
            Configuration: {
              ProjectName: code_build_ref
            },
            InputArtifacts: [{ Name: lambda_src_snapshot_name }],
            RunOrder: 1
          }
        ]
      }
    ]
  end
end