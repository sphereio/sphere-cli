Feature: Export product data into CSV files

  Scenario: Export single product from project.
    Given I am logged in and select a new project
    And I have a product type called "cliPt"
    And I create a product called "product1" based on "cliPt"
    When I run `sphere products export`
    Then the exit status should be 0
    And the output should match /^action,id,productType,name,slug,categories,variantId,images$/
    And the output should match /,[a-z0-9-]+,[a-z0-9-]+,product1,some-slug,"",1,""$/
