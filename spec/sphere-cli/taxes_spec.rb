require 'spec_helper'

module Sphere
  describe Taxes do
    before do
      @taxes = Sphere::Taxes.new 'p'
    end
    it 'fetch and fill maps' do
      Excon.stub(
        { :method => :get, :path => '/api/p/tax-categories' },
        { :status => 200, :body => '[{"id":"1","name":"t1","version":7},{"id":"2","name":"t2","version":1},{"id":"3","name":"t2","version":99}]' })
      @taxes.fetch_all
      @taxes.fill_maps

      @taxes.id2version.size.should be 3
      @taxes.id2version['1'].should eq 7
      @taxes.id2version['2'].should eq 1
      @taxes.id2version['3'].should eq 99
      @taxes.name2id.size.should be 2
      @taxes.name2id['t1'].should eq '1'
      @taxes.name2id['t2'].should eq '2'
      @taxes.duplicate_names.size.should be 1
      @taxes.duplicate_names['t2'].size.should be 2
      @taxes.duplicate_names['t2'][0].should eq '2'
      @taxes.duplicate_names['t2'][1].should eq '3'
    end
    it '#add_tax_category' do
      Excon.stub(
        { :method => :post, :path => '/api/p/tax-categories', :body => '{"name":"myTax","description":"more info"}' },
        { :status => 200, :body => '{}' })
      @taxes.add_tax_category 'myTax', 'more info'
    end
    it '#add_tax_rate' do
      Excon.stub(
        { :method => :put, :path => '/api/p/tax-categories/123', :body => '{"id":"123","version":7,"actions":[{"action":"addTaxRate","taxRate":{"name":"myRate","amount":0.19,"country":"DE","includedInPrice":true}}]}' },
        { :status => 200, :body => '{}' })
      @taxes.add_tax_rate '123', 7, 'myRate', 0.19, 'DE', true
    end
  end
end
