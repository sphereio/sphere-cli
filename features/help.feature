@nobackend
Feature: Provide help for command line tool

  Scenario: no argument should display hint
    When I run `sphere`
    Then the output should contain "sphere - A sphere CLI tool"
    Then the exit status should be 0

  Scenario: usage text on help
    When I run `sphere help`
    Then the output should contain "sphere - A sphere CLI tool"
    Then the exit status should be 0

  Scenario: usage text on unknown command
    When I run `sphere asdfgh`
    Then the output should contain "error: Unknown command 'asdfgh'"
    Then the exit status should not be 0

  Scenario: version
    When I run `sphere --version`
    Then the output should match /0\.\d+\.\d+/
    Then the exit status should be 0

  Scenario: All options have proper argument names and there is no TODO
    When I run `sphere help`
    When I run `sphere help account`
    When I run `sphere help catalogs`
    When I run `sphere help code`
    When I run `sphere help types`
    When I run `sphere help products`
    When I run `sphere help projects`
    Then the output should not match /=arg/
    Then the output should not match /arg\]/
    Then the output should not match /TODO/
