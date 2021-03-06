module LambdaFunctionPolicy

  def self.document(lambda_func_name_ref, latex_bucket_ref, latex_pdf_key, lambda_bucket_ref)
    {
      :Version => '2012-10-17',
      :Statement => [
        {
          Effect: 'Allow',
          Action: 'logs:CreateLogGroup',
          Resource: sub('arn:aws:logs:us-west-2:${AccountId}:*', AccountId: aws_account_id)
        },
        {
          Effect: 'Allow',
          Action: %w(logs:CreateLogStream logs:PutLogEvents),
          Resource: [
            sub(
              'arn:aws:logs:us-west-2:${AccountId}:log-group:/aws/lambda/${LambdaFuncNameRef}:*',
              LambdaFuncNameRef: lambda_func_name_ref,
              AccountId: aws_account_id
            )
          ]
        },
        {
          Effect: 'Allow',
          Action: %w(kms:Decrypt kms:Encrypt kms:GenerateDataKey),
          Resource: '*'
        },
        {
          Effect: 'Allow',
          Action: %w(s3:GetObject s3:PutObject),
          Resource: sub(
            'arn:aws:s3:::${BucketName}/dbx-credentials.json',
            {
              BucketName: lambda_bucket_ref
            }
          )
        },
        {
          Effect: 'Allow',
          Action: [
            's3:GetObject'
          ],
          Resource: sub(
            'arn:aws:s3:::${BucketName}/${ObjectKey}',
            {
              BucketName: latex_bucket_ref,
              ObjectKey: latex_pdf_key
            }
          )
        }
      ]
    }
  end
end