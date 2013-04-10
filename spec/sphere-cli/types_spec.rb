require 'spec_helper'

module Sphere
  describe 'ProductTypes' do
    before do
      @pt = Sphere::ProductTypes.new
    end
    describe '#list' do
      it 'no project key' do
        expect { @pt.list({}, {})}.to raise_error 'No project key provided.'
      end
      it 'no product types' do
        Excon.stub(
          { :method => :get, :path => '/api/pro/products/types' },
          { :status => 200, :body => '[]' })

        o, e = capture_outs { @pt.list({ :project => 'pro' }, {}) }
        o.should match /^The project with key 'pro' has no product types.$/
      end
      it 'just works' do
        Excon.stub(
          { :method => :get, :path => '/api/p/products/types' },
          { :status => 200, :body => '[{}]' })

        expect { @pt.list({ :project => 'p' }, {}) }.to_not raise_error
      end
    end
    describe '#create' do
      it 'no project key' do
        expect { @pt.create [], {} }.to raise_error 'No project key provided.'
      end
      it 'invalid input' do
        expect { @pt.create ['NO JSON'], { :project => 'some-project' } }.to raise_error /^Can't parse JSON:/
      end
      it 'bad response' do
        Excon.stub(
          { :method => :post, :path => '/api/some-project/products/types' },
          { :status => 401, :body => '{}' })

        expect { @pt.create ['{}'], { :project => 'some-project' } }.to raise_error /^Can't create product type: server returned with status '401'/
      end
      it 'just works' do
        Excon.stub(
          { :method => :post, :path => '/api/p/products/types' },
          { :status => 200, :body => '{}' })

        expect { @pt.create ['{}'], { :project => 'p' } }.to_not raise_error
      end
    end
    describe '#details' do
      it 'no id' do
        expect { @pt.details [], { :project => 'p' }, {} }.to raise_error "No product type id provided."
      end
      it 'just works' do
        Excon.stub(
          { :method => :get, :path => '/api/p/products/types/123' },
          { :status => 200, :body => '{"attributes":[{}]}' })

        expect { @pt.details ['123'], { :project => 'p' }, {} }.to_not raise_error
      end
    end
    describe '#delete' do
      it 'no id' do
        expect { @pt.delete [], { :project => 'p' }, {} }.to raise_error "No product type id provided."
      end
      it 'deletion failed' do
        Excon.stub(
          { :method => :delete, :path => '/api/p/products/types/123' },
          { :status => 500, :body => '{}' })

        expect { @pt.delete ['123'], { :project => 'p' }, {} }.to raise_error /Failed to delete product type with id '123' from project with key 'p': server returned with status '500'/
      end
      it 'just works' do
        Excon.stub(
          { :method => :delete, :path => '/api/my-p/products/types/abc' },
          { :status => 200, :body => '{}' })

        expect { @pt.delete ['abc'], { :project => 'my-p' }, {} }.to_not raise_error
      end
    end
  end
end
