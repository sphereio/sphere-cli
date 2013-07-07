def exec_cmd(cmd, expected_output, invert_output=false)
  steps %Q{
    When I run `#{cmd}`
    Then the exit status should be 0
    And the output from "#{cmd}" should #{"not " if invert_output}contain "#{expected_output}"
  }
end

def signup_with_secret(username)
  run_simple "sphere signup #{username} #{username} secret", true, @aruba_timeout_seconds
end

def login_with_secret(username)
  run_simple "sphere --user #{username} --password secret login", true, @aruba_timeout_seconds
end

def create_product(product, pt)
  command="sphere -J types"
  run_simple command, true, @aruba_timeout_seconds
  data = JSON.parse stdout_from command
  id = nil
  data.each do |item|
    if item['name'] == pt
      id = item['id']
    end
  end
  raise 'No product type id found.' unless id
  json = '\'{"name":{"en":"%s"},"slug":{"en":"some-slug"},"productType":{"id":"%s","typeId":"product-type"},"attributes":[]}\'' % [ product, id ]
  run_simple "sphere products create #{json}", true, @aruba_timeout_seconds
  number_of_products? 1
end

def number_of_products? number
  cmd = "sphere -j products list"
  end_time = Time.now + 30
  until Time.now > end_time
    begin
      run_simple cmd, true, @aruba_timeout_seconds
      next unless stdout_from(cmd).include? "\"total\": #{number}," # TODO: get number of products before and increase.
    rescue
    end
    sleep 1
  end
end
