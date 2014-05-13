Feature: Country commands

  Scenario: Add countries
    Given I am logged in and select a new project
    When I run `sphere country DE,AT`
    Then the exit status should be 0
