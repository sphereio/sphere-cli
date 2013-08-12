Feature: Import product data via CSV files

  Scenario: Try to use as many import features as possible.
    Given I am logged in and select a new project
    And a file named "pt.json" with:
    """
    {
      "name":"myPT"
      ,"description":"Some more information"
      ,"attributes":[
        { "name":"size","label":{"en":"size"},"type":"text","isVariant":true,"isRequired":true,"inputHint":"SingleLine" }
      ]
    }
    """
    And I run `sphere type create @pt.json`
    And the exit status should be 0
    And a file named "cat.csv" with:
    """
    rootCategory,Cat1
    Men,Shoes
    ,Shirts
    """
    And I run `sphere categories import cat.csv`
    And the exit status should be 0
    When I run `sphere tax create`
    Then the exit status should be 0
    And a file named "prods.csv" with:
    """
    productType,name,categories,tax,variantId,size,images
    myPT,x,Shoes;Shirts,myTax,1,XL,https://www.google.com/images/errors/logo_sm.gif
    ,,,,2,L,
    ,,,,3,S,
    myPT,y,Shirts,myTax,1,S,https://fbcdn-dragon-a.akamaihd.net/cfs-ak-ash4/84979/417/388809427820169_484552950.png
    """
    When I run `sphere products import prods.csv`
    Then the exit status should be 0
    And the output should match /Done, created 2 products and 2 variants in [0-9\.]+ seconds/
    And I wait for the backend to have 2 products stored
    When I run `sphere products export`
    Then the exit status should be 0
    And the stdout from "sphere products export" should match /^action,id,productType,name,slug,categories,variantId,size,images$/
    And the stdout from "sphere products export" should match /^"",[a-z0-9-]+,[a-z0-9-]+,x,x,[a-z0-9-]+;[a-z0-9-]+,1,XL,http.*gif$/
    And the stdout from "sphere products export" should match /^"","","","","","",2,L,""$/
    And the stdout from "sphere products export" should match /^"","","","","","",3,S,""$/
    And the stdout from "sphere products export" should match /^"",[a-z0-9-]+,[a-z0-9-]+,y,y,[a-z0-9-]+,1,S,http.*png$/
