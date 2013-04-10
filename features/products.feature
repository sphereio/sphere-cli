Feature: Managing products works

  Scenario: Create a product
    Given I am logged in and select a new project
    And I have a product type called "cliPt"
    When I create a product called "cliProd" based on "cliPt"
    And I run `sphere products list`
    Then the output should match /There is 1 product in project with key 'cli-testing[0-9-]+'/
