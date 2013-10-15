desc 'Manage your customers'
long_desc %(
  Import and export your customers from CSV.
)
command [:customer, :customers] do |c|

  c.arg_name 'key'
  c.flag [:p,:project], :desc => 'Project key to use', :type => String

  c.desc 'List number of customers'
  c.long_desc 'Prints the number of customers in a project'
  c.command [:list] do |list|
    list.action do |global_options,options,args|
      project_key = get_project_key options
      sphere.ensureLoggedIn
      sphere_customers = Sphere::Customers.new project_key
      sphere_customers.list
   end
  end

  c.desc 'Export categories into CSV'
  c.long_desc ''
  c.command :export do |import|
    import.action do |global_options, options, args|
      project_key = get_project_key options
      sphere.ensureLoggedIn
      sphere_customers = Sphere::Customers.new project_key
      sphere_customers.export_to_csv
    end
  end

  c.default_command :list

end
