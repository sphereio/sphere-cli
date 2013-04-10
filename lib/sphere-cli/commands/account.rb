desc 'Sphere account management'
long_desc %(
  With this subcommand you can manage your account.
)
command [:account] do |c|

  c.desc 'Display details of the currently logged in user\'s account'
  c.command [:details] do |details|
    details.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Account.new.details
    end
  end

  c.desc 'Display the currently logged in user\'s account'
  c.command [:whoami] do |details|
    details.action do |global_options,options,args|
      sphere.ensureLoggedIn
      puts "Logged in as #{sphere.username}"
    end
  end

  c.desc 'Log in with a sphere user account'
  c.command :login do |login|
    login.action do |global_options,options,args|
      Sphere::Account.new.login global_options[:u], global_options[:p]
    end
  end

  c.desc 'Log out the currently logged-in user'
  c.command :logout do |logout|
    logout.action do |global_options,options,args|
      Sphere::Account.new.logout
    end
  end

  c.desc 'Sign up for a new sphere account'
  c.command :signup do |signup|
    signup.action do |global_options,options,args|
      Sphere::Account.new.signup args[0], args[1], args[2]
    end
  end

  c.desc 'Permanently delete the currently logged-in user\'s account'
  c.command :delete do |delete|
    delete.action do |global_options,options,args|
      sphere.ensureLoggedIn
      Sphere::Account.new.delete global_options
    end
  end

  c.default_command :details
end

# Shortcut commands

desc 'Log in with a sphere user account'
command :login do |login|
  login.action do |global_options,options,args|
    Sphere::Account.new.login global_options[:u], global_options[:p]
  end
end

desc 'Log out the currently logged-in user'
command :logout do |logout|
  logout.action do |global_options,options,args|
    Sphere::Account.new.logout
  end
end

desc 'Sign up for a new sphere account'
command :signup do |signup|
  signup.action do |global_options,options,args|
    Sphere::Account.new.signup args[0], args[1], args[2]
  end
end
