class EnvParam
  def initialize(var_name, value)
    @var_name = var_name
    @value = value
  end

  def to_s
    "#{@var_name}=#{@value}"
  end
end