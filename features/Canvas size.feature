Feature: Automatic canvas size
  Scenario: Default canvas size
    When I visit '/'
    Then the SVG canvas should be just as large as the display

  Scenario: Canvas size in a simple drawing
    When I visit '/'
    And I type '<circle r="50" />' into the source panel
    Then the SVG canvas should be just as large as the display

  Scenario: Canvas size when SVG drawing has no defined size
    When I visit '/'
    And I type '<svg></svg>' into the source panel
    Then the SVG canvas should be just as large as the display

  Scenario: Canvas size when SVG is smaller than the display
    When I visit '/'
    And I create a blank '5' by '7' SVG drawing
    Then the size of the SVG drawing should be '5' px by '7' px
    And the display should be '7' px high

  Scenario: Canvas size when SVG is larger and taller than the display
    When I visit '/'
    And I create a blank '500' by '2000' SVG drawing
    Then the size of the SVG drawing should be '500' px by '2000' px
    And the SVG should be scaled down to fit the 'height' of the display

  Scenario: Canvas size when SVG is larger and wider than the display
    When I visit '/'
    And I create a blank '3000' by '500' SVG drawing
    Then the size of the SVG drawing should be '3000' px by '500' px
    And the SVG should be scaled down to fit the 'width' of the display
    And the display should shrink to fit the height of the scaled-down SVG
