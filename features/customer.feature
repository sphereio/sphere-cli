Feature: Managing your customers

  Scenario: List and export customers of empty project
    Given I am logged in and select a new project
    When I run `sphere customers list`
    Then the exit status should be 0
    And the output should match /^There are 0 customers in project with key '[a-z0-9-]+'.$/
    When I run `sphere customers export`
    Then the exit status should be 0
    And the output should match /^id,email,firstName,middleName,lastName,title,defaultShippingAddressId,defaultBillingAddressId,isEmailVerified,customerGroup,id,title,salutation,firstName,lastName,streetName,streetNumber,additionalStreetInfo,postalCode,city,region,state,country,company,department,building,apartment,pOBox,phone,mobile,email$/
    And the output should match /Exporting customers... Done, 0 customers in [0-9.]+ seconds/

  Scenario: Import and export customers from/to CSV
    Given I am logged in and select a new project
    And a file named "c.csv" with:
    """
    email,firstName,lastName
    jon@example.com,Jon,Doe
    """
    When I run `sphere customers import c.csv`
    Then the exit status should be 0
    When I run `sphere customers export`
    Then the exit status should be 0
