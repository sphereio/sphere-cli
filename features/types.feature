Feature: Managing product types works

  Scenario: Create a product type
    Given I am logged in and select a new project
    And a file named "product-type.json" with:
    """
    {
      "name":"cli-product-type1"
      ,"description":"My Long Description1"
    }
    """
    When I run `sphere types create @product-type.json`
    Then the exit status should be 0
    And  a product type named "cli-product-type1" should exist

  Scenario: Create all kind of attribute types and import an example product
    Given I am logged in and select a new project
    And a file named "pt.json" with:
    """
    {
      "name":"all-types",
      "description":"Blabla",
      "attributes":[
        { "name":"a1","label":{ "en":"a1" },"type":"text",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a2","label":{ "en":"a2" },"type":"enum",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine",
          "values":[{"key":"a","label":"A"},{"key":"b","label":"B"}] },
        { "name":"a3","label":{ "en":"a3" },"type":"number",  "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a4","label":{ "en":"a4" },"type":"money",   "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a5","label":{ "en":"a5" },"type":"date",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a6","label":{ "en":"a6" },"type":"time",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a7","label":{ "en":"a7" },"type":"datetime","isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a8","label":{ "en":"a8" },"type":"text",    "isVariant":true,"isRequired":true,"inputHint":"MultiLine" },
        { "name":"a9","label":{ "en":"a9" },"type":"ltext",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a10","label":{ "en":"a10" },"type":"lenum",   "isVariant":true,"isRequired":true,"inputHint":"SingleLine",
          "values":[{"key":"o","label":{"de":"Eins","en":"One"}},{"key":"t","label":{"de":"Zwei","en":"Two"}}] }
      ]
    }
    """
    And a file named "p.csv" with:
    """
    productType,name,tax,variantId,a1,a2,a3,a4,a5,a6,a7,a8,a9.de,a9.en,a10
    all-types,Product,myTax,0,text,a,3,"GBP 899",1970-01-01,11:11,1970-01-01T11:11:11,"multi\nline\ntext","Hallo",Hello,t
    """
    When I run `sphere types create @pt.json`
    Then the exit status should be 0
    When I run `sphere tax create`
    Then the exit status should be 0
    When I run `sphere products import p.csv`
    Then the exit status should be 0
    When I run `sphere products export`
    Then the exit status should be 0
    And the stdout from "sphere products export" should match /^action,id,productType,name,slug,categories,variantId,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,images$/
    And the stdout from "sphere products export" should match /^"",[a-z0-9-]+,[a-z0-9-]+,Product,product,"",1,text,a,3,GBP 899,1970-01-01,11:11,1970-01-01T11:11:11,multi\\nline\\ntext,Hello,t,""$/

  Scenario: Create two product types and export products only of one
    Given I am logged in and select a new project
    And a file named "product-type1.json" with:
    """
    {
      "name":"cli-product-type1"
      ,"description":"My Long Description1"
    }
    """
    And a file named "p1.csv" with:
    """
    productType,name,tax,variantId
    cli-product-type1,P1,myTax,0
    """
    And a file named "product-type2.json" with:
    """
    {
      "name":"cli-product-type2"
      ,"description":"My Long Description1"
    }
    """
    And a file named "p2.csv" with:
    """
    productType,name,tax,variantId
    cli-product-type2,P2,myTax,0
    """
    When I run `sphere types create @product-type1.json`
    Then the exit status should be 0
    And a product type named "cli-product-type1" should exist
    When I run `sphere types create @product-type2.json`
    Then the exit status should be 0
    And  a product type named "cli-product-type2" should exist
    When I run `sphere tax create`
    Then the exit status should be 0
    When I run `sphere products import p1.csv`
    Then the exit status should be 0
    When I run `sphere products import p2.csv`
    Then the exit status should be 0
    When I run `sphere products --product_type=cli-product-type1 export`
    Then the exit status should be 0
    And the output from "sphere products --product_type=cli-product-type1 export" should not contain "P2"
    When I run `sphere products --product_type=cli-product-type2 export`
    Then the exit status should be 0
    And the output from "sphere products --product_type=cli-product-type1 export" should not contain "P1"
