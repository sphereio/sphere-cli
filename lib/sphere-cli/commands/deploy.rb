desc 'Dploy your SPHERE.IO frontend to one of the cloud providers'
command :deploy do |c|

  c.desc 'Deploy to heroku'
  c.command :heroku do |run|
    run.action do |global_options,options,args|
      git_config = '.git/config'
      raise "Folder does not contain a valid git project" unless File.exist? git_config
      content = File.read git_config
      unless content.match /heroku/  
        identifier = "#{Time.now.strftime('%Y%m%d%H%M%S')}-#{Random.new.rand(10..99)}"
        system("heroku apps:create sphereio-#{identifier}")
      end
      system('git push heroku master')
    end
  end

  c.default_command :heroku

end
