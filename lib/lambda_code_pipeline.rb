module LambdaCodePipeline
  def self.stages(token, code_build_ref)
    lambda_src_snapshot_name = 'LambdaSourceSnapshot'
    [
      {
        Name: 'Source',
        Actions: [
          {
            Name: 'LambdaSourceAction',
            ActionTypeId: {
              Category: 'Source',
              Owner: 'ThirdParty',
              Version: 1,
              Provider: 'GitHub'
            },
            Configuration: {
              Owner: 'ErrorsAndGlitches',
              Repo: 'S3DropboxLambda',
              Branch: 'master',
              OAuthToken: token
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