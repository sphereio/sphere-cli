desc 'Manage product types in a project'
long_desc %(
  With the product-type[s] you are able to create, delete and list product types as well as getting details of a product type.
)
command [:type, :types] do |c|

  c.arg_name 'key'
  c.flag [:p,:project], :desc => 'Project key to use', :type => String

  c.desc 'List product types'
  c.long_desc 'List product types of a project.'
  c.command [:list] do |list|
    list.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::ProductTypes.new.list options, global_options
   end
  end

  c.desc 'Create a product type'
  c.long_desc 'Create a product type in a project using JSON - direct or in a file.'
  c.arg_name 'json or @jsonFile'
  c.command :create do |create|
    create.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::ProductTypes.new.create args, options
   end
  end

  c.desc 'Show details for a product type'
  c.long_desc 'Show information of a product type using its id and the project key it is contained in.'
  c.arg_name 'id'
  c.command :details do |details|
    details.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::ProductTypes.new.details args, options, global_options
    end
  end

  c.desc 'Delete a product type'
  c.long_desc 'Delete a product type usin its id and the project key it is contained in.'
  c.arg_name 'id'
  c.command :delete do |delete|
    delete.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::ProductTypes.new.delete args, options
    end
  end

  c.default_command :list

end
