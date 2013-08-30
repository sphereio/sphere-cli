module Sphere
  class Projects

    def select(args, global_options)
      project_key = get_project_key args, false
      res = sphere.get projects_list_url
      sphere.ensure2XX "Can't select project with key '#{project_key}'"
      project_selected = false
      performJSONOutput global_options, res do |data|
        data.each do |p|
          if p['key'] == project_key
            folder.save_project_key p['key']
            project_selected = true
            printMsg "Project with key '#{project_key}' permanently selected. You can omit -p/--project now."
            break
          end
        end
      end
      raise "Project with key '#{project_key}' does not exist." unless project_selected
    end

    def details(args, global_options)
      project_key = get_project_key args
      res = sphere.get projects_list_url
      sphere.ensure2XX "Can't get details of project with key '#{project_key}'"
      performJSONOutput global_options, res do |data|
        data.each do |d|
          next unless d['key'] == project_key
          puts "id: #{d['id']}"
          puts "name: #{d['name']}"
          puts "key: #{d['key']}"
          puts "clientId: #{d['clients'][0]['id']}"
          puts "clientSecret: #{d['clients'][0]['secret']}"
          return d
        end
        raise "Project with key '#{project_key}' does not exist."
      end
    end

    def list(global_options)
      res = sphere.get projects_list_url
      sphere.ensure2XX "Can't get list of projects"
      performJSONOutput global_options, res do |data|
        if data.empty?
          puts 'There are no projects.'
          return
        end
        data.each do |project|
          puts "#{project['key']} (Name: #{project['name']})"
        end
      end
    end

    def create(args, options, global_options)
      project_key = get_project_key args

      printStatusLine 'Getting organizations... '
      res = sphere.get organizations_list_url
      sphere.ensure2XX "Can't get list of organizations"
      org_id = nil
      org_name = nil
      performJSONOutput global_options, res do |data|
        if data.empty?
          puts 'You are not a member of any organizations.'
          return
        end
        index = -1
        if (options[:o])
          # explicitly passed organization name as an argument, let's check if it exists
          index = data.index { |o| o['name'] == options[:o] }
          raise "Organization '#{options[:o]}' does not exist." unless index
        else
          if (data.length == 1)
            # just one organization, let's use it
            index = 0
          else
            puts 'There are more than one organization:'
            data.each do |o|
              puts "  name: #{o['name']}, id: #{o['id']}"
            end
            raise 'Please specify which organization to create the new project for.'
          end
        end
        org = data[index]
        org_id = org['id']
        org_name = org['name']
      end
      printMsg "Done"

      printStatusLine "Creating project '#{project_key}' for organization '#{org_name}'... "
      d = { :name => project_key, :key => project_key, :owner => { :typeId => 'organization', :id => org_id } }
      d[:languages] = get_list options[:l]
      d[:currencies] = get_list options[:m]
      d[:plan] = 'Medium' # TODO: specify via command line arg
      url = project_create_url
      res = sphere.post url, d.to_json
      sphere.ensure2XX "Project creation failed"
      j = parse_JSON res

      add_country j['project']['key'], j['project']['version'], options[:c]

      printMsg "Done"
      performJSONOutput global_options, res do |data|
        puts "key: #{data['project']['key']}"
        puts "clientId: #{data['client']['id']}"
        puts "clientSecret: #{data['client']['secret']}"
      end

      return unless options[:'sample-data']
      printStatusLine "Creating sample data... "
      res = sphere.post project_sample_data_url(project_key), ''
      sphere.ensure2XX "Adding sample data to new project failed"
      printMsg "Done, enjoy!"
    end

    def get_list(string)
      string.split ','
    end

    def add_country(project_key, project_version, countries)
      c = get_list countries
      printStatusLine "Add countries to project... "
      d = { :key => project_key, :version => project_version, :actions => [{ :action => 'setCountries', :countries => c }] }
      url = project_add_countries_url project_key
      res = sphere.put url, d.to_json
      sphere.ensure2XX "Add countries to project with key '#{project_key}' failed"
    end

    def delete(args, global_options)
      project_key = get_project_key args

      if not global_options[:force]
        puts 'WARNING: this action can not be undone'
        print 'Type the project key to verify: '
        verify_key = ask
        raise 'Cancelled, no action performed.' if verify_key != project_key
      end

      res = sphere.delete project_delete_url project_key
      sphere.ensure2XX "Failed to delete project with key '#{project_key}'"
      printMsg "Project '#{project_key}' deleted."
    end

  end
end
