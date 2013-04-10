require 'excon'

require "net/http"
require "net/https"
require "uri"
require "cgi"
require 'net/http/post/multipart'

module Sphere

  class Client

    USER_AGENT = "Sphere-CLI/#{Sphere::VERSION} (#{RbConfig::CONFIG['arch']}) ruby #{RUBY_VERSION}"
    SESSION_COOKIE_NAME = "PLAY_SESSION"
    FLASH_COOKIE_NAME = "PLAY_FLASH"

    def initialize(connection)
      @connection = connection
      @error_message = ""
      @response = nil
    end

    def error_message
      @error_message
    end

    def response
      @response
    end

    def username
      folder.user_info
    end

    def mc_token
      folder.credentials
    end

    def delete_credentials
      folder.delete_credentials
      folder.delete_user_info
    end

    def checkLoginSignupResponse (username)
      if @response.status != 303
        msg = 'An account with this email address already exists.'
        if @response.body.include? msg
          @error_message = msg
        else
          @error_message = "Unknown error with HTTP code #{@response.status}"
        end
        return false
      end
      cookies = @response.headers['Set-Cookie']
      res = cookies.match /#{SESSION_COOKIE_NAME}=(.*?);/
      if res
        folder.save_credentials res[1]
        folder.save_user_info username
        return true
      end
      res = cookies.match /#{FLASH_COOKIE_NAME}=(.*?);/
      if res and res[1].include? '%00'
        @error_message = URI.decode(res[1].split('%00')[1]).gsub(/\+/, ' ').slice('error:'.size()..-1)
      else
        @error_message = "Unknown error"
      end
      return false
    end

    def signup (name, username, password)
      @response = @connection.post( :path => signup_url,
                                    :headers => {
                                      'User-Agent' => USER_AGENT,
                                      'Content-Type' => 'application/x-www-form-urlencoded'
                                    },
                                    :body => "name=#{CGI::escape(name)}&email=#{CGI::escape(username)}&password=#{CGI::escape(password)}")

      return checkLoginSignupResponse username
    end

    def login (username, password)
      @response = @connection.post( :path => login_url,
                                    :headers => {
                                      'User-Agent' => USER_AGENT,
                                      'Content-Type' => 'application/x-www-form-urlencoded'
                                    },
                                    :body => "email=#{CGI::escape(username)}&password=#{CGI::escape(password)}")
      return checkLoginSignupResponse username
    end

    def ensureLoggedIn
      raise 'Not logged in' unless loggedIn?
    end

    def loggedIn?
      not folder.credentials.nil?
    end

    def logout
      @response = @connection.get( :path => logout_url,
                                   :headers => {
                                     'User-Agent' => USER_AGENT,
                                     'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                                   })
      delete_credentials
    end

    def get(url)
      @response = @connection.get( :path => url,
                                   :headers => {
                                     'User-Agent' => USER_AGENT,
                                     'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                                   })
      return @response.body
    end

    def post(url, body)
      @response = @connection.post( :path => url,
                                    :headers => {
                                      'User-Agent' => USER_AGENT,
                                      'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                                    },
                                    :body => body)
      return @response.body
    end

    def post_image(url, image_url)
      file = download.download_binary(image_url, true)

      uri = URI.parse(@serverUrl + url)
      File.open(file) do |jpg|
        req = Net::HTTP::Post::Multipart.new uri.path, "file" => UploadIO.new(jpg, "image/jpeg", "image.jpg") # TODO: set mime-type and name according to file
        req['User-Agent'] = USER_AGENT
        req['Cookie'] = "#{SESSION_COOKIE_NAME}=#{mc_token}"

        http = Net::HTTP.new uri.host, uri.port
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        res = http.request req
        return res
      end
      return nil
    end

    def put(url, body)
      @response = @connection.put( :path => url,
                                   :headers => {
                                     'User-Agent' => USER_AGENT,
                                     'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                                   },
                                   :body => body)
      return @response.body
    end

    def delete(url)
      @response = @connection.delete( :path => url,
                                      :headers => {
                                        'User-Agent' => USER_AGENT,
                                        'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                                      })
      return @response.body
    end

    def is2XX
      @response.status / 100 == 2
    end

    def is2XX3XX
      @response.status / 100 == 2 || response.status / 100 == 3
    end

    def ensure2XX(errorMessage = 'Communitcation problem')
      e = ''
      begin
        e = parse_JSON response.body
      rescue
        if response.body.nil? or response.body.empty?
          e = 'No further information available'
        else
          e = "Response body: #{response.body}"
        end
      end
      raise "#{errorMessage}: server returned with status '#{@response.status}':\n  #{e}" unless is2XX
    end

    def ensure2XX3XX(errorMessage="Server returned #{@response.status}")
      raise errorMessage unless is2XX3XX
    end
  end
end
