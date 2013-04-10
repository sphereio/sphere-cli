Given /^I am logged in and select a new project$/ do
  $project = "cli-testing-#{$unique_id}"
  run_simple "sphere project create #{$project}", true, @aruba_timeout_seconds*3
  run_simple "sphere project select #{$project}", true, @aruba_timeout_seconds
end

Given /^I have a product type called "([^"]*)"$/ do |pt|
  jsonCommand = '\'{"name":"%s","description":"My Long Description"}\'' % [ pt ]
  run_simple "sphere types create #{jsonCommand}", true, @aruba_timeout_seconds
end

When /^I create a product called "([^"]*)" based on "([^"]*)"$/ do |product, pt|
  create_product product, pt
end

When(/^I write the output from "(.*?)" to file "(.*?)"$/) do |cmd, file|
  write_file file, stdout_from(cmd)
end

When(/^I change \/([^\/]*)\/ to "(.*?)" in file "(.*?)"$/) do |from, to, file|
  in_current_dir do
    c = File.read file
    c = c.gsub /#{from}/, to
    File.open(file, 'w') { |f| f << c }
  end
end

Then /^I wait for the backend to have (\d+) product(?:s)? stored$/ do |number|
  number_of_products? number
end

Then /^I should be logged in as "(.*?)"$/ do |username|
  check_directory_presence [".sphere"], true
  check_file_presence [".sphere/username"], true
  check_file_presence [".sphere/credentials"], true
  check_file_content ".sphere/username", username, true
end

Then /^I should not be logged in$/ do
  check_file_presence [".sphere/username"], false
  check_file_presence [".sphere/credentials"], false
end

Then /^a project named "(.*?)" should exist$/ do |name|
  exec_cmd "sphere projects", name
end

Then /^a project named "(.*?)" should not exist$/ do |name|
  exec_cmd "sphere projects", name, true
end

Then /^a product type named "(.*?)" should exist$/ do |name|
  exec_cmd "sphere types", name
end

Then /^a catalog named "(.*?)" should exist$/ do |name|
  exec_cmd "sphere catalogs", name
end

