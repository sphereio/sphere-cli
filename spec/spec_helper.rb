#require 'simplecov'
#SimpleCov.start do
#  add_filter "spec/"
#end
#require 'simplecov-rcov'
#SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

require 'sphere-cli'
require 'gli-extensions'

def capture_outs(&block)
  stdout = $stdout
  stderr = $stderr
  $stdout = fakeout = StringIO.new
  $stderr = fakeerr = StringIO.new
  begin
    yield
  ensure
    $stdout = stdout
    $stderr = stderr
  end
  return fakeout.string, fakeerr.string
end

RSpec.configure do |config|
  config.before(:each) do
    $dir_before = Dir.pwd
    $working_dir = Dir.mktmpdir 'sphere-cli-testing-folder'
    $sphere_folder = File.join $working_dir, '.sphere'
    Dir.chdir $working_dir

    $sphere_client_instance = Sphere::Client.new(Excon.new('https://localhost', :mock => true))
    $sphere_folder_instance = Sphere::Folder.new
  end
  config.after(:each) do
    Dir.chdir $dir_before
    FileUtils.rm_rf $working_dir
  end
end
