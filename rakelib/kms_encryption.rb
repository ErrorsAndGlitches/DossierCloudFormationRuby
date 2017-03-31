require 'aws-sdk'
require 'base64'

class KmsEncryption
  def initialize(kms_arn)
    @kms_arn = kms_arn
  end

  def encrypt(plain_text)
    cipher_blob = Aws::KMS::Client
      .new
      .encrypt({
        key_id: @kms_arn,
        plaintext: plain_text
      })
      .ciphertext_blob

    Base64.strict_encode64(cipher_blob)
  end
end