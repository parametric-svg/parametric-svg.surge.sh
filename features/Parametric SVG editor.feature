Feature: Parametric SVG editor
  Scenario: Creating raw SVG
    Given I visit '/'

    When I type '<circle r="150" />' into the source panel
    Then I should see a circle with a radius of '150' on the canvas


  Scenario: Creating parametric SVG
    Given I visit '/'

    When I type '<circle parametric:r="20 * 5 + 30" />' into the source panel
    Then I should see a circle with a radius of '130' on the canvas
