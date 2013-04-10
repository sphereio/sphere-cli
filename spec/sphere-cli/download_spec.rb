require 'spec_helper'

module Sphere
  describe Download do
    it '#download' do
      d = Sphere::Download.new ''
      @f = d.download_binary 'https://www.google.com/images/errors/logo_sm.gif', true
      @f.should match /logo.sm.gif$/
      File.should be_file @f
    end
  end 
end


