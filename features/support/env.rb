require 'aruba/cucumber'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  @temp_dir = Dir.mktmpdir
  @dirs = [ @temp_dir ]
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  @aruba_timeout_seconds = 10
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

Before '~@nobackend', '~@noautosignup' do
  if not $account_created
    $unique_id = "#{Time.now.strftime('%Y%m%d%H%M%S')}-#{Random.new.rand(10..99)}"
    $user = "webtests+cli-#{$unique_id}@alias.commercetools.de"
    signup_with_secret $user
    $account_created = true
    at_exit {
      login_with_secret $user
      run_simple "sphere -f account delete", false, @aruba_timeout_seconds
    }
  end
  login_with_secret $user
end

After do
  if $user
    login_with_secret $user
    run_simple "sphere -f project delete #{$project}", false, @aruba_timeout_seconds if $project
  end
  ENV['RUBYLIB'] = @original_rubylib
  FileUtils.rm_rf @temp_dir
end

AfterStep do
#  ask "Continue?"
end
