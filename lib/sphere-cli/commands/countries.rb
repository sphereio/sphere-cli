desc 'Manage countries in your project'
long_desc %(
  This command helps you to manage countries.
)
command [:country, : countries] do |c|

  c.arg_name 'countries'
  c.desc 'Create countries'
  c.command [:"create"] do |create|
    create.action do |global_options,options,args|
      sphere.ensureLoggedIn
      project_key = get_project_key args, false
      res = sphere.get projects_list_url
      #GET  VERSION
      performJSONOutput global_options, res do |data|
        if data.empty?
          puts 'There are no projects.'
          return
        end
        data.each do |d|
          next unless d['key'] == project_key
          project_version = d['version']
          Sphere::Projects.new.add_country project_key project_version args
          puts "countries update"
          return
        end
        raise "Project with key '#{project_key}' does not exist."
      end

    end
  end

  # TODO: import tax rates via csv
end
