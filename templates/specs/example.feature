# Example BDD feature — copy and rename for each PRD journey
# Linked PRD: .factory/context/PRD.md → J001
# Filename: J001-example-journey.feature

@J001
Feature: Example user journey
  As a [persona]
  I want to [goal]
  So that [outcome from PRD J001]

  Background:
    Given the application is running
    And I am logged in as a test user

  Scenario: Happy path through the journey
    Given I am on the home page
    When I [user action from PRD step 1]
    And I [user action from PRD step 2]
    Then I should see [expected outcome from PRD goal]

  Scenario: Validation error is shown early
    Given I am on the [relevant page]
    When I submit invalid input
    Then I see a clear error message
    And I remain on the same page

  # @wip — add edge cases as journeys mature
