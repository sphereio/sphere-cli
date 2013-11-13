require 'spec_helper'

module Sphere
  describe Customers do
    before do
      @c = Sphere::Customers.new "proj-key"
    end
    describe '#fill_maps' do
      it 'no customers' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"results":[]}' })

        @c.fetch_all
        @c.fill_maps
        @c.email2id.size.should eq 0
        @c.id2version.size.should eq 0
      end
      it 'some customers' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"results":[{"id":"123","email":"a@example.com"},{"id":"abc","email":"b@example.com"}]}' })

        @c.fetch_all
        @c.fill_maps
        @c.email2id.size.should eq 2
        @c.id2version.size.should eq 2
      end
    end
    describe '#export_to_csv' do
      it 'no customers' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"results":[]}' })

        h, r = @c.export_to_csv
        h.should eq ["id", "email", "firstName", "middleName", "lastName", "title", "defaultShippingAddressId", "defaultBillingAddressId", "isEmailVerified", "customerGroup", "id", "title", "salutation", "firstName", "lastName", "streetName", "streetNumber", "additionalStreetInfo", "postalCode", "city", "region", "state", "country", "company", "department", "building", "apartment", "pOBox", "phone", "mobile", "email"]
        r.size.should eq 0
      end
      it 'simple customers without addresses' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"results":[{"id":"123","title":"Dr.","addresses":[]}]}' })

        h, r = @c.export_to_csv
        r.size.should eq 1
        r[0].should eq ["123", "", "", "", "", "Dr.", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
      end
    end
    describe '#list' do
      it 'no customers' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"total":0}' })

        @c.list.should eq "There are 0 customers in project with key 'proj-key'."
      end
      it 'one customers' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"total":1}' })

        @c.list.should eq "There is 1 customer in project with key 'proj-key'."
      end
      it 'several customers' do
        Excon.stub(
          { :method => :get, :path => '/api/proj-key/customers' },
          { :status => 200, :body => '{"total":7}' })

        @c.list.should eq "There are 7 customers in project with key 'proj-key'."
      end
    end
  end
end
