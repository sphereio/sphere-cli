Feature: Projects commands

  Scenario: Projects list works
    Given I am logged in and select a new project
    When I run `sphere projects`
    Then the exit status should be 0
    And the stdout from "sphere projects" should match /cli-testing-[0-9]{14}-[0-9]{2} \(Name: cli-testing-[0-9]{14}-[0-9]{2}\)/
    And the stdout from "sphere projects" should not be json

  Scenario: Projects list with pretty json output works
    Given I am logged in and select a new project
    When I run `sphere -j projects`
    Then the exit status should be 0
    And the stdout from "sphere -j projects" should match /cli-testing-[0-9]{14}-[0-9]{2}/
    And the stdout from "sphere -j projects" should be pretty json

  Scenario: Projects list with raw json output works
    Given I am logged in and select a new project
    When I run `sphere -J projects`
    Then the exit status should be 0
    And the stdout from "sphere -J projects" should match /cli-testing-[0-9]{14}-[0-9]{2}/
    And the stdout from "sphere -J projects" should be raw json

  Scenario: Project details works
    Given I am logged in and select a new project
    When I run `sphere projects details`
    Then the exit status should be 0
    And the output should match /id: [a-z0-9-]+/
    And the output should match /Name: cli-testing-[0-9]{14}-[0-9]{2}/
    And the output should match /Key: cli-testing-[0-9]{14}-[0-9]{2}/
    And the stdout from "sphere projects details" should not be json

  Scenario: Project details with pretty json output works
    Given I am logged in and select a new project
    When I run `sphere -j projects details`
    Then the exit status should be 0
    And the output should match /cli-testing-[0-9]{14}-[0-9]{2}/
    And the output should contain "key"
    And the output should contain "name"
    And the output should contain "id"
    And the stdout from "sphere -j projects details" should be pretty json

  Scenario: Project details with raw json output works
    Given I am logged in and select a new project
    When I run `sphere -J projects details`
    Then the exit status should be 0
    And the output should match /cli-testing-[0-9]{14}-[0-9]{2}/
    And the output should contain "key"
    And the output should contain "name"
    And the output should contain "id"
    And the stdout from "sphere -J projects details" should be raw json
