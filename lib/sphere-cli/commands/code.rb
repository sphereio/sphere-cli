desc 'Manage the source code of your applications'
long_desc %(
  Allows to create a sample frontend for SPHERE.IO, configure its settings and run it locally.
)
command :code do |c|

  c.desc 'Create a new sphere code folder using one of the provided templates'
  c.flag [:t, :template], :arg_name => 'name', :desc => 'Name of SPHERE.IO frontend template', :type => String, :must_match => /snowflake|fedora|donut/
  c.command [:new, :get] do |new|
    new.action do |global_options,options,args|
      folder.delete_empty_folder
      raise 'Please use an empty directory to create a new SPHERE.IO frontend!' unless Dir.entries('.').size == 2
      raise 'You need git in order to get the template code!' unless command? 'git'
      unless options[:template]
        msg =
'''
We provide 3 frontend templates for SPHERE.IO.

  1 snowflake: http://snowflake.sphere.io
  2 fedora: http://fedora.sphere.io
  3 donut: http://iwantdonuts.com

Please choose the number:
'''
        puts msg
        while true
          choice = ask
          if ['1','2','3'].include? choice
            options[:template] = case choice
              when '1' then 'snowflake'
              when '2' then 'fedora'
              when '3' then 'donut'
            end
            break
          end
        end
      end
      puts "Getting template #{options[:template]}..."
      system("git clone https://github.com/commercetools/sphere-#{options[:template]}.git .")
    end
  end

  c.arg_name 'key'
  c.flag [:p,:project], :desc => 'Project key to use', :type => String
  c.desc 'Configure the application with your project. This will store the project key and you do not have to pass it as argument any longer as long as you are in this folder.'
  c.command :configure do |configure|
    configure.action do |global_options,options,args|
      project_key = get_project_key options
      json = Sphere::Projects.new.details args, { :quiet => true }
      code.configure json
    end
  end

  c.desc 'Run the code'
  c.command :run do |run|
    run.action do |global_options,options,args|
      system('./sbt run')
    end
  end

  c.default_command :run

end
