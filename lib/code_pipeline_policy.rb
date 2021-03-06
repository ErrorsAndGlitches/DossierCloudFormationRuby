module CodePipelinePolicy

  def self.document
    {
      :Statement => [
        {
          :Action => %w(s3:GetObject s3:GetObjectVersion s3:GetBucketVersioning),
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => ['s3:PutObject'],
          :Resource => %w(arn:aws:s3:::codepipeline* arn:aws:s3:::elasticbeanstalk*),
          :Effect => 'Allow',
        },
        {
          :Action => [
            'codecommit:CancelUploadArchive',
            'codecommit:GetBranch',
            'codecommit:GetCommit',
            'codecommit:GetRepository',
            'codecommit:GetUploadArchiveStatus',
            'codecommit:UploadArchive',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => [
            'appconfig:StartDeployment',
            'appconfig:GetDeployment',
            'appconfig:StopDeployment',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => [
            'codestar-connections:UseConnection',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => [
            'codedeploy:CreateDeployment',
            'codedeploy:GetApplicationRevision',
            'codedeploy:GetDeployment',
            'codedeploy:GetDeploymentConfig',
            'codedeploy:RegisterApplicationRevision',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => [
            'elasticbeanstalk:*',
            'ec2:*',
            'elasticloadbalancing:*',
            'autoscaling:*',
            'cloudwatch:*',
            's3:*',
            'sns:*',
            'cloudformation:*',
            'rds:*',
            'sqs:*',
            'ecs:*',
            'iam:PassRole',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => ['lambda:InvokeFunction', 'lambda:ListFunctions'],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => [
            'opsworks:CreateDeployment',
            'opsworks:DescribeApps',
            'opsworks:DescribeCommands',
            'opsworks:DescribeDeployments',
            'opsworks:DescribeInstances',
            'opsworks:DescribeStacks',
            'opsworks:UpdateApp',
            'opsworks:UpdateStack',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => [
            'cloudformation:CreateStack',
            'cloudformation:DeleteStack',
            'cloudformation:DescribeStacks',
            'cloudformation:UpdateStack',
            'cloudformation:CreateChangeSet',
            'cloudformation:DeleteChangeSet',
            'cloudformation:DescribeChangeSet',
            'cloudformation:ExecuteChangeSet',
            'cloudformation:SetStackPolicy',
            'cloudformation:ValidateTemplate',
            'iam:PassRole',
          ],
          :Resource => '*',
          :Effect => 'Allow',
        },
        {
          :Action => ['codebuild:BatchGetBuilds', 'codebuild:StartBuild'],
          :Resource => '*',
          :Effect => 'Allow',
        },
      ],
      :Version => '2012-10-17',
    }
  end
end