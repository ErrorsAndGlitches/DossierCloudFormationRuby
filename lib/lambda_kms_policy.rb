module LambdaKmsPolicy

  def self.lambda_policy_document(lambda_role_arn)
    {
      :Version => '2012-10-17',
      :Statement => [
        {
          Sid: 'Enable the root account to delete the KMS key',
          Effect: 'Allow',
          Principal: {
            AWS: [
              sub(
                'arn:aws:iam::${AccountId}:root',
                AccountId: aws_account_id
              )
            ]
          },
          Action: 'kms:*',
          Resource: '*'
        },
        {
          Sid: 'Enable the S3Dropbox Lambda function to use the KMS key',
          Effect: 'Allow',
          Principal: {
            AWS: lambda_role_arn
          },
          Action: [
            'kms:Encrypt',
            'kms:Decrypt',
            'kms:ReEncrypt*',
            'kms:GenerateDataKey*',
            'kms:DescribeKey'
          ],
          Resource: '*'
        }
      ]
    }
  end
end