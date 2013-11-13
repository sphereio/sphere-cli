desc 'Manage sphere projects'
long_desc %(
  The project[s] subcommand allows you to manage your projects in sphere.
)
command [:project, :projects] do |c|

  c.desc 'List all projects for the current user'
  c.command [:"list"] do |list|
    list.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Projects.new.list global_options
    end
  end

  c.desc 'Create a new project with the given name'
  c.arg_name 'project-key'
  c.command :create do |create|
    create.flag [:o], :desc => "Name of organization to use", :arg_name => 'organization'
    create.flag [:c], :desc => 'Countries to add to project', :arg_name => 'country,country', :default_value => 'DE'
    create.flag [:m], :desc => 'Currencies to add to project', :arg_name => 'currency,currency', :default_value => 'EUR'
    create.flag [:l], :desc => 'Languages to add to project', :arg_name => 'lang,lang', :default_value => 'en'
    create.switch [:'sample-data'], :desc => 'Add some sample data to new project', :negatable => false
    create.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Projects.new.create args, options, global_options
    end
  end

  c.desc 'Show details for the project'
  c.long_desc 'Show details for the project (run in a configured code folder or provide the project key)'
  c.arg_name 'project-key', :optional
  c.command :details do |details|
    details.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Projects.new.details args, global_options
    end
  end

  c.desc 'Delete a project'
  c.long_desc 'Delete a project (run in a configured code folder or provide the project key)'
  c.arg_name 'project-key', :optional
  c.command :delete do |delete|
    delete.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Projects.new.delete args, global_options
    end
  end

  c.desc 'Select a project'
  c.long_desc 'Pre-select a project in order to omit the parameter project-key in subsequent commands'
  c.arg_name 'project-key', :optional
  c.command :select do |select|
    select.action do |global_options, options, args|
      sphere.ensureLoggedIn
      Sphere::Projects.new.select args, global_options
    end
  end

  c.default_command :list
end
