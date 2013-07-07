require 'spec_helper'

module Sphere
  describe Catalogs do
    before do
      @cat = Sphere::Catalogs.new "myProject"
    end
    describe '#create_json_data' do
      it 'catalog should have no parent' do
        t = @cat.create_json_data 'foo', [], 0, 0
        j = JSON.parse t
        j['name']['en'].should eq 'foo'
      end
      it 'category should have parent' do
        p = ['123']
        t = @cat.create_json_data 'bar', p, 1, 0
        j = JSON.parse t
        j['parent']['id'].should eq '123'
        j['parent']['typeId'].should eq 'category'
      end
    end
    describe '#update_json_data' do
      it 'changeName name of category' do
        t = @cat.update_json_data 'abc', 3, 'myCat'
        j = JSON.parse t
        j['id'].should eq 'abc'
        j['version'].should eq 3
        j['actions'].size.should eq 1
        j['actions'][0]['action'].should eq 'changeName'
        j['actions'][0]['name']['en'].should eq 'myCat'
      end
    end
    describe '#validate_rows' do
      it 'no rootCategory header' do
        csv = CSV.parse("action,id,cat\n,,")
        r = @cat.validate_rows csv
        r[:errors][0].should eq "[header row] There is no 'rootCategory' column."
      end
      it 'no root category in first row' do
        csv = CSV.parse("rootCategory,\n,")
        r = @cat.validate_rows csv
        r[:errors][0].should eq "[row 2] There is no root category."
      end
      it 'unknown action' do
        csv = CSV.parse("action,rootCategory\nfoo,myRoot")
        r = @cat.validate_rows csv
        r[:errors][0].should eq "[row 2] Unknown action 'foo'."
      end
      it 'changeName actions needs an id' do
        csv = CSV.parse("action,id,rootCategory\nchangeName,,bar")
        r = @cat.validate_rows csv
        r[:errors][0].should eq "[row 2] Update not possible: Missing id."
      end
      it 'validate id on changeName actions' do
        csv = CSV.parse("action,id,rootCategory\nchangeName,123,bar")
        r = @cat.validate_rows csv
        r[:errors][0].should eq "[row 2] Update not possible: There is no existing item with id '123'."
      end
      it 'create with id does not make sense' do
        csv = CSV.parse("action,id,rootCategory\ncreate,123,myRoot")
        r = @cat.validate_rows csv
        r[:errors][0].should eq "[row 2] Create not possible: The sphere backend will assign an id to the element, please remove the id."
      end
    end
    describe 'with backend stub' do
      describe '#list' do
        it 'problems in getting categories' do
          Excon.stub(
            { :method => :get, :path => '/api/myProject/categories' },
            { :status => 500, :body => '[]' })

          expect { @cat.list nil }.to raise_error /Can't get categories for project with id 'myProject'/
        end
        it 'no categories' do
          Excon.stub(
            { :method => :get, :path => '/api/myProject/categories' },
            { :status => 200, :body => '[]' })

          o, e = capture_outs{ @cat.list({}) }
          o.should match /^Project with key 'myProject' has no categories./
        end
        it 'just works' do
          Excon.stub(
            { :method => :get, :path => '/api/myProject/categories' },
            { :status => 200, :body => '[{"name":{"en":"myCat"},"id":"123"}]' })

          o, e = capture_outs{ @cat.list({}) }
          o.should match /^myCat: 123/
        end
      end
      it 'root category creation' do
        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"myRoot"}}' },
          { :status => 200, :body => '{"id":"123","rootCategory":{"id":"abc"}}' })

        r = <<-eos
rootCategory,
myRoot,
        eos
        c = CSV.parse(r)
        d = @cat.validate_rows c
        d[:errors].size.should eq 0
        cr, up = @cat.import_data d
        cr.should eq 1
        up.should eq 0
      end
      it 'create with empty id and action column' do
        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":"myRoot"}' },
          { :status => 200, :body => '{"id":"123","rootCategory":{"id":"abc"}}' })

        r = <<-eos
action,id,rootCategory,subCategory,
,,myRoot,,
        eos
        c = CSV.parse(r)
        d = @cat.validate_rows c
        d[:errors].size.should eq 0
        cr, up = @cat.import_data d
        cr.should eq 1
        up.should eq 0
      end
      it 'create with explicit create action' do
        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":"myRoot"}' },
          { :status => 200, :body => '{"id":"123","rootCategory":{"id":"abc"}}' })

        r = <<-eos
action,id,rootCategory,subCat,
create,,myRoot,,
        eos
        c = CSV.parse(r)
        d = @cat.validate_rows c
        d[:errors].size.should eq 0
        cr, up = @cat.import_data d
        cr.should eq 1
        up.should eq 0
      end
      it 'change a category name' do
        Excon.stub(
          { :method => :get, :path => '/api/myProject/categories' },
          { :status => 200, :body => '[{"subCategories":[{"subCategories":[],"id":"123","version":7,"name":{"en":"bar"},"parent":{"id":"abc"}}]}]' })
        @cat.fetch_all

        Excon.stub(
          { :method => :put, :path => '/api/myProject/categories/123', :body => '{"id":"123","version":7,"actions":[{"action":"changeName","name":{"en":"foo"}}]}' },
          { :status => 200, :body => '{}' })

        r = <<-eos
action,id,rootCategory,subCat,
,abc,myRoot,,
changeName,123,,foo,
        eos
        c = CSV.parse(r)
        d = @cat.validate_rows c
        d[:errors].size.should eq 0
        d[:rows].size.should eq 2
        cr, up = @cat.import_data d
        cr.should eq 0
        up.should eq 1
      end
      it 'catalog with some categories' do
        Excon.stub(
          { :method => :get, :path => '/api/myProject/categories' },
          { :status => 200, :body => '[]' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Winter"}}' },
          { :status => 200, :body => '{"id":"1"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Men"},"parent":{"id":"1","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"2"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Sommer"}}' },
          { :status => 200, :body => '{"id":"3"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Women"},"parent":{"id":"3","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"4"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Shirts"},"parent":{"id":"4","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"5"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"T-Shirts"},"parent":{"id":"5","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"6"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Hats"},"parent":{"id":"4","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"7"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Shoes"},"parent":{"id":"4","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"8"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Girls"},"parent":{"id":"3","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"9"}' })

        Excon.stub(
          { :method => :post, :path => '/api/myProject/categories', :body => '{"name":{"en":"Shoes"},"parent":{"id":"9","typeId":"category"}}' },
          { :status => 200, :body => '{"id":"10"}' })

        r = <<-eos
rootCategory,Category,SubCategory
Winter,
,Men,
Sommer,Women,Shirts,T-Shirts,
,,Hats,
,,Shoes,
,Girls,Shoes,
        eos
        c = CSV.parse r
        d = @cat.validate_rows c
        d[:errors].size.should eq 0
        cr, up = @cat.import_data d
        cr.should eq 10
        up.should eq 0
      end
      describe '#export and fill maps' do
        it 'no categories' do
          Excon.stub(
            { :method => :get, :path => '/api/myProject/categories' },
            { :status => 200, :body => '{}' })

          h, r = @cat.export
          h.size.should be 3
          r.size.should be 0
        end
        it 'some categories' do
          Excon.stub(
            { :method => :get, :path => '/api/myProject/categories' },
            { :status => 200, :body => '[{"subCategories":[],"id":"1","name":{"en":"myRoot"}},{"subCategories":[{"subCategories":[],"id":"2-1","name":{"en":"subcategory"}}],"id":"2","name":{"en":"myRoot-2"}}]' })

          h, r = @cat.export
          h.size.should be 4
          h.to_csv.should eq "action,id,rootCategory,category\n"
          r.size.should be 3
          r[0].to_csv.should match /"",1,myRoot/
          r[1].to_csv.should match /"",2,myRoot-2/
          r[2].to_csv.should match /"",2-1,"",subcategory/

          @cat.fill_maps
          @cat.id2version.size.should be 3
          @cat.name2id.size.should be 3
          @cat.name2id['myRoot'].should eq '1'
          @cat.name2id['subcategory'].should eq '2-1'
          @cat.name2id['myRoot-2'].should eq '2'
          @cat.duplicate_names.size.should be 0
          @cat.fq_cat2id.size.should be 3
          @cat.fq_cat2id[['myRoot']].should eq '1'
          @cat.fq_cat2id[['myRoot-2']].should eq '2'
          @cat.fq_cat2id[["myRoot-2", "subcategory"]].should eq '2-1'
        end
      end
    end
  end
end
