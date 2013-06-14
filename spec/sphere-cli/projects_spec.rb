require 'spec_helper'

module Sphere
  describe Projects do
    before do
      @proj = Sphere::Projects.new
    end
    describe '#select' do
      it 'project_key is nil or empty' do
        expect { @proj.select [], {} }.to raise_error "No project key provided."
        expect { @proj.select [''], {} }.to raise_error "No project key provided."
      end
      it 'stores project_key' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[{"key":"some-project"}]' })

        expect { @proj.select ['some-project'], {} }.to_not raise_error
        File.should be_file File.join '.sphere', 'project'
      end
      it 'fails if there are no projects' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[]' })

        expect { @proj.select ['project-xyz'], {} }.to raise_error "Project with key 'project-xyz' does not exist."
      end
      it 'fails if given project_key does not exists' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[{},{},{}]' })

        expect { @proj.select ['project-xyz'], {} }.to raise_error "Project with key 'project-xyz' does not exist."
      end
    end
    describe '#details' do
      it 'project_key is nil or empty' do
        expect { @proj.details [], {} }.to raise_error "No project key provided."
        expect { @proj.details [''], {} }.to raise_error "No project key provided."
      end
      it 'no project' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[]' })

        expect { @proj.details ['some-project'], {} }.to raise_error "Project with key 'some-project' does not exist."
      end
      it 'just works' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[{"id":"1","key":"p","name":"P"}]' })

        expect { @proj.details ['p'], {} }.to_not raise_error
      end
    end
    describe '#list' do
      it 'no projects' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[]' })

        o, e = capture_outs { @proj.list({}) }
        o.should match /^There are no projects.$/
      end
      it 'just works' do
        Excon.stub(
          { :method => :get, :path => '/api/projects' },
          { :status => 200, :body => '[{"key":"p"},{"key":"q"}]' })

        expect { @proj.list({}) }.to_not raise_error
      end
    end
    describe '#create' do
      it 'project_key is nil or empty' do
        expect { @proj.create [], {}, {} }.to raise_error "No project key provided."
        expect { @proj.create [''], {}, {} }.to raise_error "No project key provided."
      end
      it 'no orgs' do
        Excon.stub(
          { :method => :get, :path => '/api/organizations' },
          { :status => 200, :body => '[]' })

        o, e = capture_outs { @proj.create ['p'], {}, {} }
        o.should match /^You are not a member of any organizations.$/
      end
      it 'too many orgs' do
        Excon.stub(
          { :method => :get, :path => '/api/organizations' },
          { :status => 200, :body => '[{},{}]' })

        expect { @proj.create ['p'], {}, {} }.to raise_error 'There are more than one organization. Please specify which organization to create the new project for.'
      end
      it 'my org does not exists' do
        Excon.stub(
          { :method => :get, :path => '/api/organizations' },
          { :status => 200, :body => '[{"name":"SomeOrg"},{"name":"NotMyOrg"}]' })

        expect { @proj.create ['p'], { :org => 'myOrg' }, {} }.to raise_error "Organization 'myOrg' does not exist."
      end
      it 'just works' do
        Excon.stub(
          { :method => :get, :path => '/api/organizations' },
          { :status => 200, :body => '[{"id":"org"}]' })
        Excon.stub(
          { :method => :post, :path => '/api/projects', :body => '{"name":"p","key":"p","owner":{"typeId":"organization","id":"org"},"languages":["de","en"],"currencies":["YEN"],"plan":"Medium"}' },
          { :status => 200, :body => '{"project":{"key":"p","version":1},"client":{"id":"123","secret":"geheim"}}' })
        Excon.stub(
          { :method => :put, :path => '/api/projects/p', :body => '{"key":"p","version":1,"actions":[{"action":"setCountries","countries":["DE"]}]}' },
          { :status => 200 })
        Excon.stub(
          { :method => :post, :path => '/api/p/sample-data' },
          { :status => 200 })

        expect { @proj.create ['p'], { :l => 'de,en', :m => 'YEN', :c => 'DE', :'sample-data' => true }, { } }.not_to raise_error
      end
    end
    describe '#delete' do
      it 'no project key' do
        expect { @proj.delete [], {} }.to raise_error "No project key provided."
        expect { @proj.delete [''], {} }.to raise_error "No project key provided."
      end
      it 'just works' do
        Excon.stub(
          { :method => :delete, :path => '/api/projects/old-proj' },
          { :status => 200 })

        expect { @proj.delete ['old-proj'], { :force => true } }.to_not raise_error
      end
    end
  end
end
