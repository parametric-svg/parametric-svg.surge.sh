Feature: Gist integration
  Scenario: First-time authentication
    When I visit '/' for the first time
    And I click the 'enable gist integration' icon button
    Then a new tab should open at 'https://github.com/login/oauth/authorize'
    And the tab should close after authorization
    And I should see a 'signing in with github…' spinner
    And eventually I should see a 'save as gist' icon button

  Scenario: Authentication with cached token
    When I visit '/'
    Then I should see a 'save as gist' icon button

  Scenario: Uploading the drawing to gist
    When I visit '/'
    And I type '<circle parametric:r="20 * 5" />' into the source panel
    And I click the 'save as gist' icon button
    Then I should see an 'enter a file name' prompt
    And I should see a 'save to gist' button

    When I type 'e2e-test' into the 'enter a file name' prompt
    And I click the 'save as gist' button
    Then I should see a 'creating gist…' spinner
    And eventually I should see a 'saved – click to view' icon button
    And clicking the button should lead to a new tab at 'https://gist.github.com/<user>/<gist id>'

    When I look at the gist under that id
    Then there should be one file inside
    And the file should be named 'e2e-test.parametric.svg'
    And the file should contain '<circle parametric:r="20 * 5" r="100"/>'
    And the file should contain the attribute 'xmlns="http://www.w3.org/2000/svg"' on the SVG tag
    And the file should contain the attribute 'xmlns:parametric="//parametric-svg.js.org/v1"' on the SVG tag
    And the file should contain the attribute 'width' on the SVG tag
    And the file should contain the attribute 'height' on the SVG tag
    And the file should contain the attribute 'viewBox' on the SVG tag
