module LambdaCbPolicy

  def self.document(cb_project_name, lambda_bucket_ref)
    {
      Version: '2012-10-17',
      Statement: [
        {
          Effect: 'Allow',
          Resource: [
            sub("arn:aws:logs:us-west-2:${AccountId}:log-group:/aws/codebuild/#{cb_project_name}", AccountId: aws_account_id),
            sub("arn:aws:logs:us-west-2:${AccountId}:log-group:/aws/codebuild/#{cb_project_name}:*", AccountId: aws_account_id),
          ],
          Action: %w(logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents),
        },
        {
          Effect: 'Allow',
          Resource: [sub(
            'arn:aws:s3:::${BucketName}/*',
            { BucketName: lambda_bucket_ref }
          )],
          Action: %w(s3:GetObject s3:PutObject),
        },
        {
          Effect: 'Allow',
          Resource: ['*'],
          Action: %w(sns:Publish)
        },
        {
          Action: %w(lambda:UpdateFunctionConfiguration lambda:UpdateFunctionCode),
          Effect: 'Allow',
          Resource: sub('arn:aws:lambda:us-west-2:${AccountId}:function:*', AccountId: aws_account_id)
        }
      ]
    }
  end
end