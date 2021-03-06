Feature: Parametric SVG editor
  Scenario: Creating raw SVG
    When I visit '/'
    And I type '<circle r="150" />' into the source panel
    Then I should see a circle with a radius of '150' on the canvas

  Scenario: Creating parametric SVG
    When I visit '/'
    And I type '<circle parametric:r="20 * 5 + 30" />' into the source panel
    Then I should see a circle with a radius of '130' on the canvas

  Scenario: Creating parametric SVG with parameters
    When I visit '/'
    And I type '<circle parametric:r="a * 5 + b" />' into the source panel
    And I add a parameter named 'a' with a value of '10'
    And I add a parameter named 'b' with a value of '40'
    Then I should see a circle with a radius of '90' on the canvas
