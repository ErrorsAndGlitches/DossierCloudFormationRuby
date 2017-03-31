require 'aws-sdk'

class CloudFormationOutput
  def initialize(stack_name)
    @stack_name = stack_name
  end

  def output_value(output_key)
    Aws::CloudFormation::Client
      .new
      .describe_stacks({ stack_name: @stack_name })
      .stacks[0]
      .outputs
      .select { |output| output.output_key == output_key }
      .first
      .output_value
  end
end