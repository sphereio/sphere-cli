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
