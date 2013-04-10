@noautosignup
Feature: I can login to Sphere and I keep logged in to process further commands.

# TODO: Those scenarios work only when the account 'cli@commercetools.de' exists.

  Scenario: Interactive login stores my credentails
    When I run `sphere login` interactively
    When I type "cli@commercetools.de"
    When I type "secret"
    Then the exit status should be 0
    And I should be logged in as "cli@commercetools.de"

  Scenario: Login stores my credentails
    When I run `sphere -u cli@commercetools.de -p secret login`
    Then the exit status should be 0
    And I should be logged in as "cli@commercetools.de"

  Scenario: Interactive login works with user name as command-line argument
    When I run `sphere -u cli@commercetools.de login` interactively
    When I type "secret"
    Then the exit status should be 0
    And I should be logged in as "cli@commercetools.de"

  Scenario: Logout deletes my credentials
    When I run `sphere -u cli@commercetools.de -p secret login`
    When I run `sphere logout`
    Then the exit status should be 0
    And I should not be logged in

  Scenario: Login fails with incorrect password
    When I run `sphere -u cli@commercetools.de -p secret_wrong login`
    Then the exit status should be 1
    And I should not be logged in

  Scenario: Login fails with incorrect user
    When I run `sphere -u cli-wrong@commercetools.de -p secret login`
    Then the exit status should be 1
    And I should not be logged in

  Scenario: Interactive login fails with incorrect password
    When I run `sphere login` interactively
    When I type "cli@commercetools.de"
    When I type "secret_wrong"
    Then the exit status should be 1
    And I should not be logged in

  Scenario: Interactive login fails with incorrect user
    When I run `sphere login` interactively
    When I type "cli-wrong@commercetools.de"
    When I type "secret"
    Then the exit status should be 1
    And I should not be logged in
