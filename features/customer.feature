Feature: Managing your customers

  @wip
  Scenario: List customers
    Given I am logged in and select a new project
    When I run `sphere customers list`
    Then the exit status should be 0
    And the output should match /^There are 0 customers in project with key '[a-z0-9-]'.$/

  Scenario: Import and export catalogs/categories from/to CSV
    Given I am logged in and select a new project
    When I run `sphere customers export`
    Then the exit status should be 0
    And the output should match /^id,email,firstName,middleName,lastName,title,defaultShippingAddressId,defaultBillingAddressId,isEmailVerified,customerGroup,id,title,salutation,firstName,lastName,streetName,streetNumber,additionalStreetInfo,postalCode,city,region,state,country,company,department,building,apartment,pOBox,phone,mobile,email$/
    And the output should match /Exporting customers... Done, 0 customers in [0-9.]+ seconds/
