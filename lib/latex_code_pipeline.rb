module LatexCodePipeline
  def self.stages(code_build_ref)
    latex_src_snapshot_name = 'LatexSourceSnapshot'
    [
      {
        Name: 'LatexSourceRepository',
        Actions: [
          {
            Name: 'LatexSourceAction',
            ActionTypeId: {
              Category: 'Source',
              Owner: 'AWS',
              Version: 1,
              Provider: 'CodeCommit'
            },
            Configuration: {
              RepositoryName: 'dossiers',
              BranchName: 'mainline'
            },
            OutputArtifacts: [{ Name: latex_src_snapshot_name }],
            RunOrder: 1
          }
        ]
      },
      {
        Name: 'LatexCompilationAndS3Upload',
        Actions: [
          {
            Name: 'LatexCompilation',
            ActionTypeId: {
              Category: 'Build',
              Owner: 'AWS',
              Version: 1,
              Provider: 'CodeBuild'
            },
            Configuration: {
              ProjectName: code_build_ref
            },
            InputArtifacts: [{ Name: latex_src_snapshot_name }],
            RunOrder: 1
          }
        ]
      }
    ]
  end
end