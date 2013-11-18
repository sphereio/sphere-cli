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

    def checkLoginSignupResponse (username, response)
      error_message = nil
      if response.status != 303
        msg = 'An account with this email address already exists.'
        if response.body.include? msg
          error_message = msg
        else
          error_message = "Unknown error with HTTP code #{response.status}"
        end
        return error_message
      end
      cookies = response.headers['Set-Cookie']
      res = cookies.match /#{SESSION_COOKIE_NAME}=(.*?);/
      if res
        folder.save_credentials res[1]
        folder.save_user_info username
        return error_message
      end
      res = cookies.match /#{FLASH_COOKIE_NAME}=(.*?);/
      if res and res[1].include? '%00'
        error_message = URI.decode(res[1].split('%00')[1]).gsub(/\+/, ' ').slice('error:'.size()..-1)
      else
        error_message = "Unknown error"
      end
      error_message
    end

    def signup (name, username, password)
      res = @connection.post( :path => signup_url,
                              :headers => {
                                'User-Agent' => USER_AGENT,
                                'Content-Type' => 'application/x-www-form-urlencoded'
                              },
                              :body => "name=#{CGI::escape(name)}&email=#{CGI::escape(username)}&password=#{CGI::escape(password)}&browser=sphere")

      return checkLoginSignupResponse username, res
    end

    def login (username, password)
      res = @connection.post( :expects => [303],
                              :path => login_url,
                              :headers => {
                                'User-Agent' => USER_AGENT,
                                'Content-Type' => 'application/x-www-form-urlencoded'
                              },
                              :body => "email=#{CGI::escape(username)}&password=#{CGI::escape(password)}&browser=sphere")
      return checkLoginSignupResponse username, res
    end

    def ensureLoggedIn
      raise 'Not logged in' unless loggedIn?
    end

    def loggedIn?
      not folder.credentials.nil?
    end

    def logout
      res = @connection.get( :expects => [200, 303],
                             :path => logout_url,
                             :headers => {
                               'User-Agent' => USER_AGENT,
                               'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                             })
      delete_credentials
    end

    def get(url, expects=[200])
      res = @connection.get( :expects => expects,
                             :path => url,
                             :headers => {
                               'User-Agent' => USER_AGENT,
                               'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                             })
      return res.body
    end

    def post(url, body, expects=[200, 201])
      res = @connection.post( :expects => expects,
                              :path => url,
                              :headers => {
                                'User-Agent' => USER_AGENT,
                                'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                              },
                              :body => body)
      return res.body
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

    def put(url, body, expects=[200])
      res = @connection.put( :expects => expects,
                             :path => url,
                             :headers => {
                               'User-Agent' => USER_AGENT,
                               'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                             },
                             :body => body)
      return res.body
    end

    def delete(url, expects=[200])
      res = @connection.delete( :expects => expects,
                                :path => url,
                                :headers => {
                                  'User-Agent' => USER_AGENT,
                                  'Cookie' => "#{SESSION_COOKIE_NAME}=#{mc_token}",
                                })
      return res.body
    end

  end
end
