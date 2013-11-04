require 'spec_helper'

module Sphere
  describe Products do
    before do
      @prod = Sphere::Products.new "myProject", nil
    end
    describe '#list' do
      it 'no products' do
        Excon.stub(
          { :method => :get, :path => '/api/p/products' },
          { :status => 200, :body => '{"total":0}' })

        o, e = capture_outs { @prod.list({ :project => 'p' }, {}) }
        o.should match /^No products found in project with key 'p'.$/
      end
      it 'just works' do
        Excon.stub(
          { :method => :get, :path => '/api/some-proj/products' },
          { :status => 200, :body => '{"total":2}' })

        expect { @prod.list({ :project => 'some-proj' }, {}) }.to_not raise_error
      end
    end
    describe '#create' do
      it 'just works' do
        Excon.stub(
          { :method => :post, :path => '/api/p/products' },
          { :status => 200, :body => '{}' })

        expect { @prod.create( ['{}'], { :project => 'p'} ) }.to_not raise_error
      end
    end
    describe 'json data' do
      it 'product' do
        rows = CSV.parse 'myProd,,'
        h2i = { 'name' => 0 }
        pt = { 'id' => 'abc', 'attributes' => [] }
        d = @prod.create_product_json_data rows[0], h2i, pt
        j = JSON.parse d.to_json
        j['name']['en'].should eq 'myProd'
        j['productType']['id'].should eq 'abc'
      end
      it 'variant' do
        rows = CSV.parse '123,a1Value,99,USD 999'
        h2i = { 'sku' => 0, 'a1' => 1, 'a2' => 2, 'a3' => 3 }
        pId = '123'
        pt = { 'attributes' => [{ 'name' => 'a1' }, { 'name' => 'a2', 'type' => 'number' }, {'name' => 'a3', 'type' => 'money' }] }
        d = @prod.variant_json_data rows[0], h2i, pt
        j = JSON.parse d.to_json
        j['sku'].should eq '123'
        j['attributes'].size.should eq 3
        j['attributes'][0]['name'].should eq 'a1'
        j['attributes'][0]['value'].should eq 'a1Value'
        j['attributes'][1]['name'].should eq 'a2'
        j['attributes'][1]['value'].should eq 99
        j['attributes'][2]['name'].should eq 'a3'
        j['attributes'][2]['value']['currencyCode'].should eq 'USD'
        j['attributes'][2]['value']['centAmount'].should eq 999
      end
      it 'publish' do
        d = @prod.publish_product_json_command('abc', 42)
        j = JSON.parse d
        j['id'].should eq 'abc'
        j['version'].should eq 42
        j['actions'].size.should eq 1
        j['actions'][0]['action'].should eq 'publish'
      end
      it 'image import' do
        rows = CSV.parse 'bar,"http://sphere.io/foo.jpg"'
        h2i = { 'imageLabels' => 0, 'images' => 1 }
        d = @prod.import_image_json_data rows[0], h2i
        j = JSON.parse d.to_json
        j['images'].size.should eq 1
        j['images'][0]['variantId'].should eq 1
        j['images'][0]['url'].should eq 'http://sphere.io/foo.jpg'
        j['images'][0]['label'].should eq 'bar'
        j['images'][0]['filename'].should eq 'bar'
      end
    end
    describe '#validate_categories' do
      it 'category with name does not exist' do
        cat_impl = Sphere::Catalogs.new nil
        row = CSV.parse 'myCategory;myCat'
        h2i = { 'categories' => 0 }
        d = { :errors => [] }
        cat_ids = @prod.validate_categories row[0], 3, h2i, d, cat_impl
        cat_ids.size.should eq 0
        d[:errors].size.should eq 2
        d[:errors][0].should eq "[row 3] Category with name 'myCategory' does not exist."
        d[:errors][1].should eq "[row 3] Category with name 'myCat' does not exist."
      end
      it 'category name is not unique' do
        Excon.stub(
          { :method => :get, :path => '/api/proj/categories' },
          { :status => 200, :body => '[{"subCategories":[{"subCategories":[{"subCategories":[],"id":"inner","name":{"en":"myCat"}}],"id":"middle","name":{"en":"myCat"}}],"id":"root","name":{"en":"rootCategory"}}]' })

        cat_impl = Sphere::Catalogs.new 'proj'
        cat_impl.fetch_all
        cat_impl.fill_maps
        rows = CSV.parse 'myCat'
        h2i = { 'categories' => 0 }
        d = { :errors => [] }
        cat_ids = @prod.validate_categories rows[0], 4, h2i, d, cat_impl
        cat_ids.should eq ''
        d[:errors].size.should eq 1
        d[:errors][0].should eq "[row 4] Category with name 'myCat' is not unique. Please use the category's id instead. One of middle, inner"

        rows = CSV.parse 'rootCategory>myCat;rootCategory>myCat>myCat;rootCategory;middle'
        d = { :errors => [] }
        cat_ids = @prod.validate_categories rows[0], 9, h2i, d, cat_impl
        d[:errors].size.should be 0
        cat_ids.should eq 'middle;inner;root;middle'
      end
    end
    describe '#validate_categories' do
      before do
        @tax_impl = Sphere::Taxes.new 'proj'
        @h2i = { 'tax' => 0 }
        @d = { :errors => [] }
      end
      it 'no tax' do
        row = CSV.parse ''
        id = @prod.validate_tax_category row, 3, @h2i, @d, @tax_impl
        id.should eq nil
        @d[:errors].size.should be 1
        @d[:errors][0].should eq "[row 3] There is no tax defined."
      end
      it 'error cases' do
        row = CSV.parse 'myTax'
        t = @prod.get_val row, 'tax', @h2i
        id = @prod.validate_tax_category row[0], 7, @h2i, @d, @tax_impl
        id.should eq nil
        @d[:errors].size.should be 1
        @d[:errors][0].should eq "[row 7] Tax category with name 'myTax' does not exist."
      end
      it 'duplicate tax name' do
        Excon.stub(
          { :method => :get, :path => '/api/proj/tax-categories' },
          { :status => 200, :body => '[{"id":"t1","name":"myTax"},{"id":"t2","name":"myTax"}]' })
        @tax_impl.fetch_all
        @tax_impl.fill_maps
        row = CSV.parse 'myTax'
        t = @prod.get_val row, 'tax', @h2i
        id = @prod.validate_tax_category row[0], 1, @h2i, @d, @tax_impl
        id.should eq nil
        @d[:errors].size.should be 1
        @d[:errors][0].should eq "[row 1] Tax category with name 'myTax' is not unique. Please use the tax category's id instead. One of t1, t2"
      end
    end
    describe '#validate_prices' do
      before do
        @group_impl = Sphere::CustomerGroups.new 'proj'
        @h2i = { 'prices' => 0 }
        @d = { :errors => [] }
      end
      it 'no prices header' do
        row = CSV.parse 'foo,bar'
        prices = @prod.validate_prices row, 7, {}, @d, @group_impl
        prices.should eq nil
        @d[:errors].size.should be 0
      end
      it 'no prices' do
        row = CSV.parse ''
        prices = @prod.validate_prices row, 3, @h2i, @d, @group_impl
        prices.should eq nil
        @d[:errors].size.should be 0
      end
      it 'simple single price' do
        row = CSV.parse 'EUR 100'
        prices = @prod.validate_prices row[0], 6, @h2i, @d, @group_impl
        prices[:prices].size.should eq 1
        prices[:prices][0][:value][:currencyCode].should eq 'EUR'
        prices[:prices][0][:value][:centAmount].should eq 100
        @d[:errors].size.should be 0
      end
      it 'price with unkown customer group' do
        row = CSV.parse 'EUR 100 B2B'
        prices = @prod.validate_prices row[0], 6, @h2i, @d, @group_impl
        @d[:errors].size.should be 1
        @d[:errors][0].should eq "[row 6] Customer group with name 'B2B' does not exist."
      end
      it 'invalid prices value' do
        row = CSV.parse 'EUR-100'
        prices = @prod.validate_prices row[0], 2, @h2i, @d, @group_impl
        @d[:errors].size.should be 1
        @d[:errors][0].should eq "[row 2] Invalid price value 'EUR-100' found."
      end
      it 'multiple prices' do
        row = CSV.parse 'YEN 1000;EUR 100;USD 3000'
        prices = @prod.validate_prices row[0], 2, @h2i, @d, @group_impl
        prices[:prices].size.should eq 3
        prices[:prices][0][:value][:currencyCode].should eq 'YEN'
        prices[:prices][0][:value][:centAmount].should eq 1000
        prices[:prices][1][:value][:currencyCode].should eq 'EUR'
        prices[:prices][1][:value][:centAmount].should eq 100
        prices[:prices][2][:value][:currencyCode].should eq 'USD'
        prices[:prices][2][:value][:centAmount].should eq 3000
        @d[:errors].size.should be 0
      end
    end
    describe 'Product import with existing type but without existing products' do
      before do
        Excon.stub(
          { :method => :get, :path => '/api/myProject/products/types' },
          { :status => 200, :body => '[{"id":"123","name":"pt","attributes":[]}]' })
        Excon.stub(
          { :method => :get, :path => '/api/myProject/products' },
          { :status => 200, :body => '{"count":0,"offset":0,"total":0,"results":[]}' })
        Excon.stub(
          { :method => :get, :path => '/api/myProject/categories' },
          { :status => 200, :body => '[]' })
        Excon.stub(
          { :method => :get, :path => '/api/myProject/tax-categories' },
          { :status => 200, :body => '[{"id":"t1","name":"T1"}]' })
        Excon.stub(
          { :method => :get, :path => '/api/myProject/customer-groups' },
          { :status => 200, :body => '[{"id":"cg1","name":"B2B"}]' })
        $force = true
        @prod.fetch_all
      end
      it 'simple product' do
        Excon.stub(
          { :method => :post, :path => '/api/myProject/products', :body => '{"productType":{"id":"123","typeId":"product-type"},"taxCategory":{"id":"t1","typeId":"tax-category"},"name":{"en":"myProd"},"slug":{"en":"myprod"},"masterVariant":{"attributes":[]},"variants":[]}' },
          { :status => 200, :body => '{"id":"abc","version":1}' })
        Excon.stub(
          { :method => :put, :path => '/api/myProject/products/abc', :body => '{"id":"abc","version":1,"actions":[{"action":"publish"}]}' },
          { :status => 200 })

        r = <<-eos
name,productType,tax,variantId,
myProd,pt,t1
        eos
        c = CSV.parse r
        d = @prod.validate_rows c
        d[:errors].size.should be 0
        @prod.import_data d
      end
      it 'product with multiple languages' do
        Excon.stub(
          { :method => :post, :path => '/api/myProject/products', :body => '{"productType":{"id":"123","typeId":"product-type"},"taxCategory":{"id":"t1","typeId":"tax-category"},"name":{"de":"meinProd","en":"myProd"},"slug":{"de":"meinprod","en":"myprod"},"description":{"de":"tolles Produkt","en":"awesome product"},"masterVariant":{"attributes":[]},"variants":[]}' },
          { :status => 200, :body => '{"id":"abc","version":1}' })
        Excon.stub(
          { :method => :put, :path => '/api/myProject/products/abc', :body => '{"id":"abc","version":1,"actions":[{"action":"publish"}]}' },
          { :status => 200 })

        r = <<-eos
name.de,name.en,description.de,description.en,productType,tax,variantId,
meinProd,myProd,tolles Produkt,awesome product,pt,t1
        eos
        c = CSV.parse r
        d = @prod.validate_rows c
        d[:errors].size.should be 0
        @prod.import_data d
      end
      it 'product with variants and prices' do
        body = '{"productType":{"id":"123","typeId":"product-type"},"taxCategory":{"id":"t1","typeId":"tax-category"},"name":{"en":"my Prod"},"slug":{"en":"my-prod"}'
        body << ',"masterVariant":{"prices":[{"country":"DE","value":{"currencyCode":"EUR","centAmount":100}}],"attributes":[]}'
        body << ',"variants":[{"prices":[{"value":{"currencyCode":"USD","centAmount":9999}}],"attributes":[]},{"prices":[{"customerGroup":{"typeId":"customer-group","id":"cg1"},"value":{"currencyCode":"GBP","centAmount":123}}],"attributes":[]}]'
        body << '}'
        Excon.stub(
          { :method => :post, :path => '/api/myProject/products', :body => body },
          { :status => 200, :body => '{"id":"abc","version":1}' })
        Excon.stub(
          { :method => :put, :path => '/api/myProject/products/abc', :body => '{"id":"abc","version":1,"actions":[{"action":"publish"}]}' },
          { :status => 200, :body => '{"id":"abc","version":2}' })

        r = <<-eos
action,id,name,productType,tax,variantId,prices
,,my Prod,pt,t1,1,DE-EUR 100
,,,,,2,USD 9999
,,,,,3,GBP 123 B2B
        eos
        c = CSV.parse r
        d = @prod.validate_rows c
        d[:errors].size.should be 0
        @prod.import_data d
      end
    end
    describe '#validate_rows' do
      it 'Error when no column for name' do
        csv = CSV.parse("productType,\n1,")
        d = @prod.validate_rows csv
        d[:errors].size.should be > 0
        d[:errors][0].should eq "Column with header 'name' missing."
      end
      it 'Duplicate header' do
        csv = CSV.parse("productType,name,attribX,attribX\n")
        d = @prod.validate_rows csv
        d[:errors].size.should be > 0
        d[:errors][0].should eq "Duplicate header column named 'attribX'."
      end
      it 'Error when action is unknown' do
        csv = CSV.parse("action,name,productType,variantId\nFOO,myProd,,,")
        d = @prod.validate_rows csv
        d[:errors].size.should be > 0
        d[:errors][0].should eq "[row 2] Unknown action 'FOO'."
      end
      it 'Error when delete action and no id given' do
        r = <<-eos
action,id,name,productType,variantId
delete,,myProd2,pt,1
        eos
        csv = CSV.parse r
        d = @prod.validate_rows csv
        d[:errors].size.should be 1
        d[:errors][0].should eq "[row 2] Delete not possible: missing product id."
      end
      it 'Error when delete action and there is no such product' do
        r = <<-eos
action,id,productType,name,variantId,
delete,abc,pt,myProd2,1,
        eos
        csv = CSV.parse r
        d = @prod.validate_rows csv
        d[:errors].size.should be 1
        d[:errors][0].should eq "[row 2] Delete not possible: product with id 'abc' does not exist."
      end
      it 'Errors on creation preparation' do
        r = <<-eos
action,id,name,productType,variantId
create,,myProd,,1
create,,myProd,pt,1
        eos
        csv = CSV.parse r
        d = @prod.validate_rows csv
        d[:errors].size.should be > 0
        d[:errors][0].should eq "[row 2] Create not possible: missing product type."
        d[:errors][1].should eq "[row 3] Create not possible: product type with name/id 'pt' does not exist."
      end
      it 'Errors on deletion preparation' do
        r = <<-eos
action,id,name,productType,variantId
delete,,,,
delete,123,,,
        eos
        csv = CSV.parse r
        d = @prod.validate_rows csv
        d[:errors].size.should be > 0
        d[:errors][0].should eq "[row 2] Delete not possible: missing product id."
        d[:errors][1].should eq "[row 3] Delete not possible: product with id '123' does not exist."
      end
    end
    describe '#export_csv' do
      it 'simple product' do
        Excon.stub(
          { :method => :get, :path => '/api/myProject/products' },
          { :status => 200, :body => '{"count":1,"offset":0,"total":1,"results":[{"id":"abc","productType":{"id":"pt"},"name":{"en":"myProd"},"masterVariant":{"attributes":[],"images":[]},"categories":[],"variants":[]}]}' })
        @prod.fetch_all
        h,r = @prod.export_csv
        h.size.should be 7
        h.to_csv.should eq "action,id,productType,name,categories,variantId,images\n"
        r.size.should be 1
        r[0].size.should be 7
        r[0].to_csv.should match /"",abc,pt,myProd,"","",/
      end
      it 'product with attributes' do
          body = <<-eos
{"offset":0, "count":1, "total":1, "results":[
    {
        "masterVariant":{
            "id":1,
            "sku":"sku_BMW_M7_2_door",
            "prices":[
                {
                    "value":{
                        "currencyCode":"EUR",
                        "centAmount":1900000
                    }
                }
            ],
            "images":[
                {
                    "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                    "label":"Sample image",
                    "dimensions":{
                        "w":400,
                        "h":300
                    }
                },
                {
                    "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                    "label":"Sample image",
                    "dimensions":{
                        "w":400,
                        "h":300
                    }
                }
            ],
            "attributes":[
                {
                    "name":"tags",
                    "value":"white two door"
                },
                {
                    "name":"fuel",
                    "value":"Petrol"
                }
            ]
        },
        "id":"7bdc0808-b7b5-44fe-a9b5-d2ccde2cc81e",
        "version":5,
        "productType":{
            "typeId":"product-type",
            "id":"2e7f452a-c428-42c1-90c5-9a90840b78b0"
        },
        "name":{
            "en":"BMW M7 2 door"
        },
        "description":"Some\\nMulti\\nLine\\nText",
        "categories":[
            {
                "typeId":"category",
                "id":"d44aa750-25dd-4857-b2b5-b7276f9e4aed"
            }
        ],
        "slug":"bmw-m7-2-door1363878603727",
        "variants":[
            {
                "id":2,
                "sku":"sku_BMW_M7_2_door_variant1",
                "prices":[
                    {
                        "value":{
                            "currencyCode":"EUR",
                            "centAmount":2000000
                        }
                    }
                ],
                "images":[
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    },
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    },
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    },
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    }
                ],
                "attributes":[
                    {
                        "name":"fuel",
                        "value":"Diesel"
                    },
                    {
                        "name":"tags",
                        "value":"M7 diesel variant"
                    }
                ],
                "availability":{
                    "isOnStock":true
                }
            },
            {
                "id":3,
                "sku":"sku_BMW_M7_2_door_variant2",
                "prices":[
                    {
                        "value":{
                            "currencyCode":"EUR",
                            "centAmount":2100000
                        }
                    }
                ],
                "images":[
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    },
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    },
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    },
                    {
                        "url":"http://www.whitegadget.com/attachments/pc-wallpapers/76848d1316083027-bmw-bmw-picture.jpg",
                        "label":"Sample image",
                        "dimensions":{
                            "w":400,
                            "h":300
                        }
                    }
                ],
                "attributes":[
                    {
                        "name":"fuel",
                        "value":"Diesel"
                    },
                    {
                        "name":"tags",
                        "value":"M7 4 door variant"
                    }
                ],
                "availability":{
                    "isOnStock":true
                }
            }
        ],
        "hasStagedChanges":false,
        "published":true
    }
], "facets":{}}
        eos
        Excon.stub(
            { :method => :get, :path => '/api/myProject/products' },
            { :status => 200, :body => body })
        @prod.fetch_all
        h,r = @prod.export_csv
        h.size.should be 12
        h.to_csv.should eq "action,id,productType,name,description,slug,categories,variantId,sku,tags,fuel,images\n"
        r.size.should be 3
        r[0].size.should be 12
        r[0].to_csv.should match /"",[a-z0-9-]+,[a-z0-9-]+,BMW M7 2 door,"Some\nMulti\nLine\nText",bmw-m7-2-door1363878603727,[a-z0-9-]+,1,sku_BMW_M7_2_door,white two door,Petrol,http.*jpg;http.*jpg/
        r[1].size.should be 12
        r[1].to_csv.should match /"","","","","","","",2,sku_BMW_M7_2_door_variant1,M7 diesel variant,Diesel,http.*jpg;http.*jpg;http.*jpg;http.*jpg/
        r[2].size.should be 12
        r[2].to_csv.should match /"","","","","","","",3,sku_BMW_M7_2_door_variant2,M7 4 door variant,Diesel,http.*jpg;http.*jpg;http.*jpg;http.*jpg/
      end
    end
  end
end
