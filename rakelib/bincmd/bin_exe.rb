class BinExe
  def initialize(bin_filename)
    @bin_filename = bin_filename
  end

  def to_s
    proj_dir = 2.times.inject(File.expand_path(__dir__)) { |dir| File.dirname(dir) }
    rlib_includes = [
      File.join(proj_dir, 'lib'),
      File.join(proj_dir, 'sharelib')
    ]
      .map { |rlib| rlib.prepend('-I') }
      .join(' ')
    script_file = File.join(proj_dir, 'bin', @bin_filename)
    "ruby #{rlib_includes} #{script_file}"
  end
end