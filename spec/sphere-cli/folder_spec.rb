require 'spec_helper'

module Sphere
  describe Folder do
    it 'creates sphere folder' do
      File.should be_directory $sphere_folder
    end
    describe 'user info' do
      it 'default value' do
        folder.user_info.should be nil
      end
      it 'valid user info returned' do
        folder.save_user_info 'me@example.com'
        File.should be_file File.join $sphere_folder, 'username'
        folder.user_info.should eq 'me@example.com'
      end
      it 'delete user info' do
        folder.save_user_info 'you@example.com'
        folder.delete_user_info
        File.should_not be_file File.join $sphere_folder, 'username'
      end
    end
    describe 'project key' do
      it 'default value' do
        folder.project_key.should be nil
      end
      it 'store and read project key' do
        folder.save_project_key 'my-project'
        File.should be_file File.join $sphere_folder, 'project'
        folder.project_key.should eq 'my-project'
      end
    end
    describe 'credentials' do
      it 'default value' do
        folder.credentials.should be nil
      end
      it 'store and read credentials' do
        folder.save_credentials 'super secret'
        File.should be_file File.join $sphere_folder, 'credentials'
        folder.credentials.should eq 'super secret'
      end
      it 'delete credentials' do
        folder.save_credentials 'something'
        folder.delete_credentials
        File.should_not be_file File.join $sphere_folder, 'credentials'
      end
    end
  end
end
