require 'spec_helper'

module Sphere
  describe 'Account' do
    before do
      Excon.stubs.clear
      @account = Sphere::Account.new
    end
    describe '#login' do
      it 'unknown error' do
        Excon.stub(
          { :method => :post, :path => '/login' },
          { :status => 500 })

        expect { @account.login 'someone@example.com', 'secret' }.to raise_error
      end
      it 'decoding of failure feedback works' do
        Excon.stub(
          { :method => :post, :path => '/login' },
          { :status => 303, :headers => { 'Set-Cookie' => 'PLAY_FLASH=email%3Asomeone%40example.com%00error%3ASomething+wierd+happend.;' } })

        expect { @account.login 'someone@example.com', 'secret' }.to raise_error "Failed to log in as 'someone@example.com': Something wierd happend."
      end
      it 'just works' do
        Excon.stub(
          { :method => :post, :path => '/login', :body => 'email=someone%40example.com&password=secret&browser=sphere' },
          { :status => 303, :headers => { 'Set-Cookie' => 'PLAY_SESSION=123;' } })

        expect { @account.login 'someone@example.com', 'secret' }.to_not raise_error
      end
    end
    describe '#signup' do
      it 'account already exists' do
        Excon.stub(
          { :method => :post, :path => '/signup', :body => 'name=me+and+i&email=someone%2B123%40example.com&password=secret&browser=sphere' },
          { :status => 200, :body => '<html>An account with this email address already exists.</html>' })

        expect { @account.signup 'me and i', 'someone+123@example.com', 'secret' }.to raise_error "Failed to sign up as 'someone+123@example.com': An account with this email address already exists."
      end
    end
  end
end
