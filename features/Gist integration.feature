Feature: Gist integration
  Scenario: First-time authentication
    When I visit '/' for the first time
    And I click the 'enable gist integration' icon button
    Then a new tab should open

    When I switch to the newly-opened tab
    Then the address bar should contain 'https://github.com/login'

    When I wait until I see 'Sign into GitHub'
    And I type 'tomekwi-e2e-tests' into the 'login' input
    And I type 'passw0rd' into the 'password' input
    And I click the 'commit' button
    Then the newly-opened tab should close
    And eventually I should see a 'signing in with github…' spinner
    And eventually I should see a 'save as gist' icon button

    When I look at the gist under that id
    Then there should be one file inside
    And the file should be named 'e2e-test.parametric.svg'
    And the file should contain '<circle parametric:r="20 * 5" r="100"/>'
    And the file should contain the attribute 'xmlns="http://www.w3.org/2000/svg"' on the SVG tag
    And the file should contain the attribute 'xmlns:parametric="//parametric-svg.js.org/v1"' on the SVG tag
    And the file should contain the attribute 'width' on the SVG tag
    And the file should contain the attribute 'height' on the SVG tag
    And the file should contain the attribute 'viewBox' on the SVG tag
