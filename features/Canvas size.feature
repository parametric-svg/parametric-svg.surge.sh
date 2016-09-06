Feature: Automatic canvas size
  Scenario: Default canvas size
    When I visit '/'
    Then the SVG canvas should be just as large as the display

  Scenario: Canvas size in a simple drawing
    When I visit '/'
    And I type '<circle r="50" />' into the source panel
    Then the SVG canvas should be just as large as the display
