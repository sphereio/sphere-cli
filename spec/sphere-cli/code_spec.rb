require 'spec_helper'

module Sphere
  describe Code do
    before do
      FileUtils.mkdir_p 'conf'
    end
    after do
      FileUtils.rm_rf 'conf'
    end
    it '#configure' do
      File.open 'conf/application.conf', 'w' do |f|
        f.puts 'sphere.project='
        f.puts 'sphere.clientId='
        f.puts 'sphere.clientSecret='
        f.puts 'sphere.core=""'
        f.puts 'sphere.auth=""'
      end

      code = Sphere::Code.new 'https://admin.escemo.com'
      r = '{"key":"my-project","clients":[{"id":"12345","secret":"geheim"}]}'
      j = JSON.parse r
      code.configure j

      c = File.open('conf/application.conf', 'r').read
      lines = c.split "\n"
      lines[0].should eq 'sphere.project="my-project"'
      lines[1].should eq 'sphere.clientId="12345"'
      lines[2].should eq 'sphere.clientSecret="geheim"'
      lines[3].should eq 'sphere.core="https://api.escemo.com"'
      lines[4].should eq 'sphere.auth="https://auth.escemo.com"'
    end
  end
end
