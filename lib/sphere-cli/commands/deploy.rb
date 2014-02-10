desc 'Dploy your SPHERE.IO frontend to one of the cloud providers'
command :deploy do |c|

  c.desc 'Deploy to heroku'
  c.command :heroku do |run|
    run.action do |global_options,options,args|
      unless File.exist? '.git'
        system('git init -q')
      end
      content = File.read '.git/config'
      unless content.match /heroku/  
        identifier = "#{Time.now.strftime('%Y%m%d%H%M%S')}-#{Random.new.rand(10..99)}"
        system("heroku apps:create sphereio-#{identifier}")
      end
      system('git push heroku master')
    end
  end

  c.default_command :heroku

end
