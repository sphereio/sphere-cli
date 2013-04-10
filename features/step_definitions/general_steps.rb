Then /^the stdout from "([^"]*)" should match \/([^\/]*)\/$/ do |cmd, expected|
  stdout_from(cmd).should match expected
end

Then /^the stdout from "([^"]*)" should be (pretty|raw) json$/ do |cmd, kind|
  o = stdout_from cmd
  expect{ JSON.parse o }.to_not raise_error
  o.strip.should match /\n/ if kind == 'pretty'
  o.strip.should_not match /\n/ if kind == 'raw'
end

Then /^the stdout from "([^"]*)" should not be json$/ do |cmd|
  expect{ JSON.parse stdout_from cmd }.to raise_error
end
