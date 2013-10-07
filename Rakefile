require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'cucumber'
require 'cucumber/rake/task'
require 'rbconfig'
require "bundler/gem_tasks"

# Cucumber tasks
# --------------
CUKE_RESULTS = 'result.html'
CLEAN << CUKE_RESULTS
desc 'Run features'
Cucumber::Rake::Task.new(:features) do |t|
  opts = "--color --format pretty --format html -out #{CUKE_RESULTS} --tags ~@wip"
  opts += " --tags #{ENV['TAGS']}" if ENV['TAGS']
  t.cucumber_opts = opts
  t.fork = false
end
task :cucumber => :features

desc 'Run features tagged as work-in-progress (@wip)'
Cucumber::Rake::Task.new('features:wip') do |t|
  t.cucumber_opts = "--color --format pretty --format html -out #{CUKE_RESULTS} --tags @wip"
  t.fork = false
end
task :wip => 'features:wip'

# RSpec tasks
# -----------
RSPEC_HTML_RESULTS = 'testresults/rspec.html'
RSPEC_JUNIT_RESULTS = 'testresults/rspec.xml'
CLEAN << RSPEC_HTML_RESULTS
CLEAN << RSPEC_JUNIT_RESULTS

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = [ '--format', 'html', '-o', RSPEC_HTML_RESULTS,
                   '-r', 'rspec_junit_formatter', '--format', 'RspecJunitFormatter', '-o', RSPEC_JUNIT_RESULTS,
                   '--format', 'nested', '--color', '--tag', '~skip' ]
end
task :default => :rspec

def version
  rake_file = Pathname.new(__FILE__).realpath
  $:.unshift File.expand_path("../lib", rake_file)
  require 'sphere-cli/version.rb'
  Sphere::VERSION
end

### Release

desc "Publishes gem to rubygems.org and bumps version"
task :perform_release do
  puts "Updating master..."
  sh "git checkout master && git pull" # This is necessary as Jenkins builds on individual commits and not master.
  sh "git tag | grep jenkins | xargs -n1 git tag -d" # Delete jenkins tags

  puts "rake release..."
  Rake::Task["release"].execute # This sucks on jenkins as it pushes all jenkins build tags

  puts "Updating version.rb file..."
  parts = version.split "."
  bumped_bugfix = parts[2].to_i + 1
  new_version = "#{parts[0]}.#{parts[1]}.#{bumped_bugfix}"

  file = 'lib/sphere-cli/version.rb'
  c = File.read file
  c = c.gsub version, new_version
  File.open(file, 'w') { |f| f.puts c }

  puts "Commit and push changes to version.rb"
  sh "git commit #{file} -m '[automation] Bump version to #{new_version}'."
  sh "git push origin master"
end


### package as pkg - works on Mac OS only!

require 'tmpdir'
require 'erb'

def pkg
  source_dir = Dir.pwd
  temp_dir = Dir.mktmpdir

  Dir.chdir temp_dir do |d|
    FileUtils.mkdir_p 'sphere-cli'
    FileUtils.mkdir_p 'pkg'
    FileUtils.mkdir_p 'pkg/Resources'
    FileUtils.mkdir_p 'pkg/sphere-cli.pkg/Scripts'
  end

  assemble_cli "#{temp_dir}/sphere-cli"
  assemble_gems "#{temp_dir}/sphere-cli"
  assemble_ruby temp_dir

  Dir.chdir temp_dir

  kbytes = %x{ du -ks sphere-cli | cut -f 1 }
  num_files = %x{ find sphere-cli | wc -l }

  dist = File.read "#{source_dir}/resources/pkg/Distribution.erb"
  dist = ERB.new(dist).result binding
  File.open('pkg/Distribution', 'w') { |f| f.puts dist }

  dist = File.read "#{source_dir}/resources/pkg/PackageInfo.erb"
  dist = ERB.new(dist).result binding
  File.open('pkg/sphere-cli.pkg/PackageInfo', 'w') { |f| f.puts dist }

  cp "#{source_dir}/resources/pkg/postinstall", 'pkg/sphere-cli.pkg/Scripts/postinstall'

  sh %{ mkbom -s sphere-cli pkg/sphere-cli.pkg/Bom }

  Dir.chdir("sphere-cli") do
    sh %{ pax -wz -x cpio . > ../pkg/sphere-cli.pkg/Payload }
  end

  sh %{ pkgutil --flatten pkg sphere-cli.pkg }
  mv 'sphere-cli.pkg', source_dir

  Dir.chdir source_dir
  FileUtils.rm_rf temp_dir
end

def assemble_cli(target_dir)
  sh %{ cp -R 'bin' '#{target_dir}' }
  sh "sed -i '' -e 's;^#!.*;#!/usr/local/heroku/ruby/bin/ruby;' '#{target_dir}/bin/sphere'"
  sh "cp -R 'lib' '#{target_dir}'"
end

GEM_BLACKLIST = %w( bundler sphere-cli )
def assemble_gems(target_dir)
  gems = %x{ env BUNDLE_WITHOUT="development:test" bundle show }
  exit 1 unless $? == 0
  gems.split("\n").each do |line|
    if line =~ /^.*\* (.*?) \((.*?)\)$/
      next if GEM_BLACKLIST.include?($1)
      puts "vendoring: #{$1}-#{$2}"
      gem_dir = %x{ bundle show #{$1} }.strip
      FileUtils.mkdir_p "#{target_dir}/vendor/gems"
      sh "cp -R '#{gem_dir}' '#{target_dir}/vendor/gems'"
    end
  end.compact
end

def assemble_ruby(target_dir)
  Dir.mktmpdir do |t|
    Dir.chdir t do
      sh %{ curl http://heroku-toolbelt.s3.amazonaws.com/ruby.pkg -o ruby.pkg }
      sh %{ pkgutil --expand ruby.pkg ruby }
      mv "ruby/ruby-1.9.3-p194.pkg", "#{target_dir}/pkg/ruby.pkg"
    end
  end
end

task 'pkg:build' do
  pkg
end
