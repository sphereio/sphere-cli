desc 'Manage countries in your project'
long_desc %(
  This command helps you to manage countries.
)
command [:country, :countries] do |c|

  c.arg_name 'countries'
  c.desc 'Set countries of a project'
  c.flag [:p,:project], :desc => 'Project key to use', :type => String
  c.command [:set] do |create|
    create.action do |global_options,options,args|
      raise "Please provide the countries to set!" if args.empty?
      sphere.ensureLoggedIn
      project_key = get_project_key options
      res = sphere.get projects_list_url
      performJSONOutput global_options, res do |data|
        if data.empty?
          puts 'There are no projects!'
        else
          found = false
          data.each do |d|
            next unless d['key'] == project_key
            found = true
            project_version = d['version']
            Sphere::Projects.new.add_country project_key, project_version, args[0]
            puts "Countries of project with key '#{project_key}' update."
          end
          raise "Project with key '#{project_key}' does not exist!" unless found
        end
      end

    end
  end

end
