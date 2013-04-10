desc 'Manage the source code of your applications'
long_desc %(
  Allows to create sample stores for sphere and configure its settings.
)
command :code do |c|

  c.desc 'Create a new sphere code folder using one of the provided templates'
  c.command [:new, :get] do |new|
    new.action do |global_options,options,args|
      t = download.download_snowflake_template # TODO: let user decide between which template to download
      code.useTemplate t
    end
  end

  c.arg_name 'key'
  c.flag [:p,:project], :desc => "Project key to use", :type => String
  c.desc 'Configure the application with your project. This will store the project key and you do not have to pass it as argument any longer as long as you are in this folder.'
  c.command :configure do |configure|
    configure.action do |global_options,options,args|
      project_key = get_project_key options
      sphere.ensureLoggedIn
      url = project_details_url project_key
      res = sphere.get url
      sphere.ensure2XX
      code.configure parse_JSON(res)
    end
  end

  c.desc 'Run the code'
  c.command :run do |run|
    run.action do |global_options,options,args|
      system('play run')
    end
  end

  c.default_command :run

end
