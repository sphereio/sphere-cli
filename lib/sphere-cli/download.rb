require 'openssl'
require 'pathname'
require 'tmpdir'

module Sphere

  class Download
    include Sphere::WWW

    def initialize(www_url)
      @www_url = www_url
    end

    def download_snowflake_template
      download_binary "#{@www_url}#{snowflake_template}"
    end

    def download_binary(url, quiet=false)
      start_time = Time.now
      printStatusLine "Downloading... #{url}" unless quiet
      n = Pathname.new(url).basename
      d = Dir.mktmpdir 'sphere'
      at_exit { FileUtils.rm_rf d }
      t = File.join d, n
      File.open(t, 'wb') do |saved_file|
        open(url, 'rb', 'User-Agent' => Sphere::Client::USER_AGENT) do |read_file|
          saved_file.write(read_file.read)
        end
      end
      duration = Time.now - start_time
      printStatusLine "Downloading... Done in #{"%5.2f" % duration} seconds\n" unless quiet
      t
    end
  end
end
