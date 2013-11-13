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

  c.desc 'Export customers as CSV'
  c.long_desc 'TODO'
  c.command :export do |export|
    export.action do |global_options, options, args|
      project_key = get_project_key options
      sphere.ensureLoggedIn
      sphere_customers = Sphere::Customers.new project_key
      sphere_customers.export_to_csv
    end
  end

  c.desc 'Import customers from CSV'
  c.long_desc 'TODO'
  c.arg_name 'cvsFile'
  c.command :import do |import|
    import.action do |global_options, options, args|
      project_key = get_project_key options
      input = get_file_input args
      sphere.ensureLoggedIn
      sphere_customers = Sphere::Customers.new project_key
      sphere_customers.import input
    end
  end

  c.default_command :list
end
