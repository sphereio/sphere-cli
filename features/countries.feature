Feature: Country commands

  Scenario: Set countries on a project
    Given I am logged in and select a new project
    When I run `sphere country set DE,AT`
    Then the exit status should be 0
