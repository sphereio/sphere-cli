module Sphere

  class Folder

    SPHERE_FOLDER = '.sphere'
    USER_FILE = 'username'
    PROJECT_FILE = 'project'
    CREDENTIALS_FILE = 'credentials'

    def initialize
      @current_folder = Dir.pwd
      @sphere_folder = File.join @current_folder, SPHERE_FOLDER
      @user_file = File.join @sphere_folder, USER_FILE
      @project_file = File.join @sphere_folder, PROJECT_FILE
      @credentials_file = File.join @sphere_folder, CREDENTIALS_FILE
      ensure_sphere_folder
    end

    def ensure_sphere_folder
      FileUtils.mkdir_p @sphere_folder unless Dir.exists? @sphere_folder
    end

    def save_user_info user_name
      save_to_file @user_file, user_name
    end

    def user_info
      read_from_file @user_file
    end

    def save_project_key project_key
      save_to_file @project_file, project_key
    end

    def delete_user_info
      delete @user_file
    end

    def project_key
      read_from_file @project_file
    end

    def save_credentials credentials
      save_to_file @credentials_file, credentials
    end

    def credentials
      read_from_file @credentials_file
    end

    def delete_credentials
      delete @credentials_file
    end

    private

    def save_to_file n, c
      File.open n, 'w' do |f|
        f.write c
      end
    end

    def read_from_file n
      return nil unless File.file? n
      user_name = File.read n
    end

    def delete n
      File.delete n if File.exists? n
    end
  end
end
