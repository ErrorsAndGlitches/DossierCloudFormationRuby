module CodeBuildRolePolicyDoc

  def self.cb_policy_document(cb_project_name, artifacts_bucket_name)
    {
      :Version => '2012-10-17',
      :Statement => [
        {
          :Effect => 'Allow',
          :Resource => [
            "arn:aws:logs:us-west-2:000000000000:log-group:/aws/codebuild/#{cb_project_name}",
            "arn:aws:logs:us-west-2:000000000000:log-group:/aws/codebuild/#{cb_project_name}:*"
          ],
          :Action => %w(logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents),
        },
        {
          :Effect => 'Allow',
          :Resource => [sub(
            'arn:aws:s3:::${BucketName}/*',
            { BucketName: artifacts_bucket_name }
          )],
          :Action => %w(s3:GetObject s3:GetObjectVersion s3:PutObject),
        },
        {
          Effect: 'Allow',
          Resource: ['*'],
          Action: %w(sns:SendMessage sns:Publish)
        },
      ],
    }
  end
end