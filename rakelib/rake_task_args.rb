class RakeTaskArgs
  def initialize(args)
    @args = args
  end

  def value(key)
    value = @args[key]
    if value.nil?
      STDERR.puts "#{key} must be specified in the rake command e.g. rake task[args]"
      exit 1
    else
      value
    end
  end
end