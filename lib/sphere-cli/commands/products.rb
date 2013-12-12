desc 'Manage products for a project'
long_desc %(
  The product[s] subcommand allows to manage your products by importing and exporting them as CSV.
)
command [:product, :products] do |c|

  c.arg_name 'key'
  c.flag [:p,:project], :desc => "Project key to use", :type => String

  c.desc 'List products'
  c.long_desc 'List the products (run in a configured code folder or provide the project key)'
  c.command [:list] do |list|
    list.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Products.new(nil, nil).list options, global_options
   end
  end

  c.desc 'Create a product'
  c.long_desc 'Create a product (run in a configured code folder or provide the project key)'
  c.arg_name 'JSON/filename'
  c.command :create do |create|
    create.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Products.new(nil, nil).create args, options
   end
  end

  c.desc 'Export products'
  c.long_desc 'Export the products into a CSV file (run in a configured code folder or provide the project key)'
  c.command [:export] do |export|
    export.action do |global_options,options,args|
      sphere.ensureLoggedIn
      project_key = get_project_key options
      sphere_products = Sphere::Products.new project_key, global_options
      sphere_products.fetch_all
      sphere_products.export_all
    end
  end

  c.desc 'Import products'
  c.long_desc 'Import products from a CSV file (run in a configured code folder or provide the project key)'
  c.arg_name 'filename'
  c.command [:import] do |import|
    import.arg_name 'lang'
    import.flag [:lang], :desc => "Default language for import", :type => String, :default_value => 'en'

    import.action do |global_options,options,args|
      sphere.ensureLoggedIn
      project_key = get_project_key options
      set_language options
      input = get_input args
      sphere_products = Sphere::Products.new project_key, global_options
      sphere_products.fetch_all
      sphere_products.import input
    end
  end

  c.desc 'Delete products'
  c.long_desc 'Delete all products in your prodject. Can not be undone'
  c.command [:delete] do |delete|
    delete.action do |global_options,options,args|
      sphere.ensureLoggedIn
      project_key = get_project_key options
      sphere_products = Sphere::Products.new project_key, global_options
      sphere_products.delete_all
    end
  end

  c.default_command :list

end
