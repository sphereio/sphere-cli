Feature: Signup to Sphere using the command line tool

  @noautosignup
  Scenario: Signup and delete of account interactivly works
    When I run `sphere signup` interactively
    When I type "Horst mal wieder"
    When I type "webtests+cli-testing-signup@commercetools.de"
    When I type "secret123"
    Then the exit status should be 0
    And I should be logged in as "webtests+cli-testing-signup@commercetools.de"
    When I run `sphere account delete` interactively
    When I type "webtests+cli-testing-signup@commercetools.de"
    Then the exit status should be 0
    And I should not be logged in

  @nobackend
  Scenario: No name on signup
    When I run `sphere signup` interactively
    When I type ""
    When I type ""
    When I type ""
    Then the exit status should be 1
    And the output should contain "Please provide a name."

  @nobackend
  Scenario: No email on signup
    When I run `sphere signup` interactively
    When I type "Foo"
    When I type ""
    When I type ""
    Then the exit status should be 1
    And the output should contain "Please provide a username."

  @nobackend
  Scenario: No name on signup
    When I run `sphere signup` interactively
    When I type "Foo"
    When I type "Bar"
    When I type ""
    Then the exit status should be 1
    And the output should contain "Please provide a password."
