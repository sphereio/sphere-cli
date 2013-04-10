# More info at https://github.com/guard/guard#readme

guard 'rspec', :cli => '--color --tag ~skip' do
  watch(%r{(.+)\.rb$}) { 'spec' }
end

guard 'cucumber', :cli => '--no-profile --color --format progress --strict --tags @nobackend' do
  watch(%r{(.+)\.rb$})      { 'features' }
  watch(%r{(.+)\.feature$}) { 'features' }
end
