module LambdaFunctionRolePolicyDoc

  def self.lambda_policy_document(lambda_func_name, latex_pdf_bucket, latex_pdf_key)
    {
      :Version => '2012-10-17',
      :Statement => [
        {
          Effect: 'Allow',
          Action: 'logs:CreateLogGroup',
          Resource: 'arn:aws:logs:us-west-2:000000000000:*'
        },
        {
          Effect: 'Allow',
          Action: %w(logs:CreateLogStream logs:PutLogEvents),
          Resource: [
            "arn:aws:logs:us-west-2:000000000000:log-group:/aws/lambda/#{lambda_func_name}:*"
          ]
        },
        {
          Effect: 'Allow',
          Action: [
            's3:GetObject'
          ],
          Resource: sub(
            'arn:aws:s3:::${BucketName}/${ObjectKey}',
            {
              BucketName: latex_pdf_bucket,
              ObjectKey: latex_pdf_key
            }
          )
        }
      ]
    }
  end
end