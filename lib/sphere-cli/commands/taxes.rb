desc 'Manage taxes in your project'
long_desc %(
  This command helps you to setup a tax category with on tax rate - currently with fixed values.
)
command [:tax, :taxes] do |c|

  c.arg_name 'key'
  c.flag [:p,:project], :desc => 'Project key to use'

  c.desc 'Create a simple tax category'
  c.command [:"create"] do |list|
    list.action do |global_options,options,args|
      sphere.ensureLoggedIn
      taxes = Sphere::Taxes.new get_project_key options
      j = taxes.add_tax_category 'myTax', 'more info'
      taxes.add_tax_rate j['id'], j['version'], 'myRate', 0.19, 'DE', true
    end
  end

  # TODO: import tax rates via csv
end
