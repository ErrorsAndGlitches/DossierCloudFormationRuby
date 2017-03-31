class CfParametersOption
  def initialize(parameters)
    @params = parameters
  end

  def to_s
    "--parameters \"#{param_list}\""
  end

  private

  def param_list
    @params
      .map { |param| "#{param[:key]}=#{param[:value]}" }
      .join(';')
  end
end