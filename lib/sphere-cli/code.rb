def silently(&block)
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = warn_level
  result
  end
# we get some stupid warning on MacOs/ruby 1.9.3-p194 when requiring this. Thus we make ruby calm for this moment.
silently { require 'rubygems/package' }

require 'zlib'

module Sphere

  class Code

    def initialize(server_url)
      @sphereCodeFolder = Dir.getwd
      @server_url = server_url
    end

    def useTemplate(t)
      printStatusLine 'Creating sample application in current folder... '
      Gem::Package::TarReader.new(Zlib::GzipReader.open(t)).each do |entry|
        destination_file = File.join @sphereCodeFolder, entry.full_name
        if entry.directory?
          FileUtils.mkdir_p destination_file
        else
          destination_directory = File.dirname destination_file
          FileUtils.mkdir_p destination_directory unless File.directory? destination_directory
          File.open destination_file, 'wb' do |f|
            f.print entry.read
          end
        end
      end
      printMsg "Done"
    end

    def configure json
      fn = 'conf/application.conf'
      printStatusLine "Configuring application via '#{fn}'... "
      c = File.read fn
      File.open fn, 'w' do |file|
        c.gsub!(/^sphere.project=.*$/, "sphere.project=\"#{json['key']}\"")
        # TODO: let the user decide which client to use.
        c.gsub!(/^sphere.clientId=.*$/, "sphere.clientId=\"#{json['clients'][0]['id']}\"")
        c.gsub!(/^sphere.clientSecret=.*$/, "sphere.clientSecret=\"#{json['clients'][0]['secret']}\"")

        if @server_url == 'https://admin.sphere-ci.cloud.commercetools.de'
          c.gsub!(/^sphere.core=.*$/, 'sphere.core="https://api.sphere-ci.cloud.commercetools.de:11999"')
          c.gsub!(/^sphere.auth=.*$/, 'sphere.auth="https://auth.sphere-ci.cloud.commercetools.de:7776"')
        elsif @server_url == 'https://admin.escemo.com'
          c.gsub!(/^sphere.core=.*$/, 'sphere.core="https://api.escemo.com"')
          c.gsub!(/^sphere.auth=.*$/, 'sphere.auth="https://auth.escemo.com"')
        end
        file.puts c
      end
      printMsg "Done"
    end
  end
end
