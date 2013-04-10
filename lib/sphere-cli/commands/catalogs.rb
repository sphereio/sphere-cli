desc 'Manage categories of a project'
long_desc %(
  Using the category/ies subcommand you can create and list categories and im- and export them from/to CSV.
)
command [:category, :categories] do |c|

  c.arg_name 'key'
  c.flag [:p,:project], :desc => 'Project key to use', :type => String

  c.desc 'List root categories'
  c.long_desc 'List root categories of a project'
  c.command [:list] do |list|
    list.action do |global_options,options,args|
      project_key = get_project_key options
      sphere.ensureLoggedIn
      sphere_catalogs = Sphere::Catalogs.new project_key
      sphere_catalogs.list global_options
   end
  end

  c.desc 'Import categories from CSV'
  c.long_desc ''
  c.arg_name 'cvsFile'
  c.command :import do |import|
    import.action do |global_options, options, args|
      project_key = get_project_key options
      input = get_file_input args
      sphere.ensureLoggedIn
      sphere_catalogs = Sphere::Catalogs.new project_key
      sphere_catalogs.import input
    end
  end

  c.desc 'Export categories into CSV'
  c.long_desc ''
  c.command :export do |import|
    import.action do |global_options, options, args|
      project_key = get_project_key options
      sphere.ensureLoggedIn
      sphere_catalogs = Sphere::Catalogs.new project_key
      sphere_catalogs.export
    end
  end

  c.default_command :list

end
