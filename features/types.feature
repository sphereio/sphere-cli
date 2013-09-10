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
        { "name":"a2","label":{ "en":"a2" },"type":"enum",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine","values":[{"key":"a","label":"A"},{"key":"b","label":"B"}] },
        { "name":"a3","label":{ "en":"a3" },"type":"number",  "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a4","label":{ "en":"a4" },"type":"money",   "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a5","label":{ "en":"a5" },"type":"date",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a6","label":{ "en":"a6" },"type":"time",    "isVariant":true,"isRequired":true,"inputHint":"SingleLine" },
        { "name":"a7","label":{ "en":"a7" },"type":"datetime","isVariant":true,"isRequired":true,"inputHint":"SingleLine" },

        { "name":"a8","label":{ "en":"a8" },"type":"text",    "isVariant":true,"isRequired":true,"inputHint":"MultiLine" }
      ]
    }
    """
    And a file named "p.csv" with:
    """
    productType,name,tax,variantId,a1,a2,a3,a4,a5,a6,a7,a8
    all-types,product,myTax,0,text,a,3,"GBP 899",1970-01-01,11:11,1970-01-01T11:11:11,"multi\nline\ntext"
    """
    When I run `sphere types create @pt.json`
    Then the exit status should be 0
    When I run `sphere tax create`
    Then the exit status should be 0
    When I run `sphere products import p.csv`
    Then the exit status should be 0
