require File.join([File.dirname(__FILE__),'lib','sphere-cli','version.rb'])

spec = Gem::Specification.new do |s|
  s.name = 'sphere-cli'
  s.version = Sphere::VERSION
  s.author = 'Commercetools GmbH'
  s.email = 'support@sphere.io'
  s.homepage = 'http://www.commercetools.de'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.1'
  s.summary = 'Command Line Interface (CLI) to the SPHERE.IO ecommerce platform.'
  s.files = Dir['bin/sphere'] + Dir['lib/**/*.rb']
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'sphere'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_dependency('json')
  s.add_dependency('excon', '0.41.0')
  s.add_dependency('multipart-post', '1.2.0')
  s.add_dependency('gli', '2.5.4')
  s.add_dependency('ruby-progressbar', '1.7.0')
  s.add_dependency('parallel', '0.5.19')
end
