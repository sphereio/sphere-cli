Feature: Managing catalogs

  Scenario: Import and export catalogs/categories from/to CSV
    Given I am logged in and select a new project
    And a file named "im.csv" with:
    """
    rootCategory,Category-Level1,Categtory-Level2,Gategory-Level3
    Winter,,,
    ,Men,,CategoryWithoutParent
    ,Women,Gloves,
    ,,Jackets,Blue Jackets
    Sommer,Women,Shoes,Slipper
    Fall,,CategoryWithoutParent,
    """
    When I run `sphere categories import im.csv`
    Then the exit status should be 0
    And the output should match /Importing categories... Done, 11 categories created and 0 categories updated and in [0-9.]+ seconds/
    When I run `sphere category export`
    Then the exit status should be 0
    And the output should match /^action,id,rootCategory,category,category,category$/
    And the output should match /^"",[a-z0-9-]+,Winter$/
    And the output should match /^"",[a-z0-9-]+,"",Men$/
    And the output should match /^"",[a-z0-9-]+,"",Women$/
    And the output should match /^"",[a-z0-9-]+,"","",Gloves$/
    And the output should match /^"",[a-z0-9-]+,"","",Jackets$/
    And the output should match /^"",[a-z0-9-]+,"","","",Blue Jackets$/
    And the output should match /^"",[a-z0-9-]+,Sommer$/
    And the output should match /^"",[a-z0-9-]+,"",Women$/
    And the output should match /^"",[a-z0-9-]+,"","",Shoes$/
    And the output should match /^"",[a-z0-9-]+,"","","",Slipper$/
    And the output should match /^"",[a-z0-9-]+,Fall$/
    And the output should match /Exporting categories... Done, 11 categories in [0-9.]+ seconds/
    When I run `sphere categories`
    Then the exit status should be 0
    And the output should match /^Winter:\ [a-z0-9-]+$/
    And the output should match /^Sommer:\ [a-z0-9-]+$/
    And the output should match /^Fall:\ [a-z0-9-]+$/
    When I write the output from "sphere category export" to file "update.csv"
    And I change /""(,[a-z0-9-]+,"","",)Gloves/ to "changeName\1Handschuhe" in file "update.csv"
    And I run `sphere categories import update.csv`
    Then the exit status should be 0
    When I run `sphere categories export`
    Then the exit status should be 0
    And the stdout from "sphere categories export" should contain "Handschuhe"

  Scenario: Import categories with slug and description
    Given I am logged in and select a new project
    And a file named "im.csv" with:
    """
    slug,description,rootCategory,subCategory
    winter,It's so cold,Winter,
    shoes,Nice shoes and other stuff,,Shoes
    """
    When I run `sphere categories import --lang=it im.csv`
    Then the exit status should be 0
    And the output should match /Importing categories... Done, 2 categories created and 0 categories updated and in [0-9.]+ seconds/
    When I run `sphere -j category export`
    Then the exit status should be 0
    And the output should match /Exporting categories... Done, 2 categories in [0-9.]+ seconds/
