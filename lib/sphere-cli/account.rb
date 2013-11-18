module Sphere

  class Account

    def login(user = nil, pass = nil)
      user, pass = get_login_info user, pass

      sphere.delete_credentials # delete old credentials
      err = sphere.login user, pass
      if err.nil?
        printMsg "Successfully logged in as '#{user}'."
      else
        raise "Failed to log in as '#{user}': #{err}"
      end
    end

    def logout
      sphere.ensureLoggedIn
      sphere.logout
      #sphere.ensure2XX3XX
      printMsg 'Successfully logged out. Stored credentials are deleted.'
    end

    def signup(name, user, pass)
      if name.nil? or name.empty?
        print "Name: "
        name = ask
      end
      raise 'Please provide a name.' if name.empty?
      user, pass = get_login_info user, pass

      err = sphere.signup name, user, pass
      if err.nil?
        printMsg "Successfully signed up as '#{user}'."
      else
        raise "Failed to sign up as '#{user}': #{err}"
      end
    end

    def details(global_options)
      res = sphere.get account_details_url
      #sphere.ensure2XX "Can't get details for your account"
      performJSONOutput global_options, res do |a|
        puts "First name: #{a['firstName']}"
        puts "Last name: #{a['lastName']}"
        puts "Email: #{a['email']}"
        puts "Id: #{a['id']}"
      end
    end

    def delete(global_options)
      if not global_options[:force]
        puts 'WARNING: this action can not be undone.'
        print 'Type the user email to verify: '
        verify_user = ask
        raise 'User account was NOT deleted.' unless verify_user == sphere.username
      end
      sphere.delete account_delete_url
      #sphere.ensure2XX "Failed to delete user account"
      sphere.delete_credentials
      printMsg "Successfully deleted user account."
    end

    private

    def get_login_info(user, pass)
      if user.nil? or user.empty?
        print 'Email: '
        user = ask
      end
      raise 'Please provide a username.' if user.empty?
      if pass.nil? or pass.empty?
        print 'Password (typing will be hidden): '
        pass = running_on_windows? ? ask_for_password_on_windows : ask_for_password
      end
      raise 'Please provide a password.' if pass.empty?
      return user, pass
    end

  end
end
