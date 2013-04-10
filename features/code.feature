Feature: With the CLI you can build a shop in some minutes

  Scenario: Configure code with my project settings
    Given I am logged in and select a new project
    When I run `sphere code get`
    Then the exit status should be 0
    And the following directories should exist:
      | app     |
      | conf    |
      | project |
      | public  |
      | test    |
    When I run `sphere code configure`
    Then the exit status should be 0
    And the file "conf/application.conf" should match /^sphere.project="cli-testing-[0-9]{14}-[0-9]{2}"$/
