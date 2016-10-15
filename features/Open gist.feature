Feature: Open gist
  Scenario: Trying to open a non-existent gist
    When I visit '/gist-fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff/this-gist-does-not-exist'
    Then I should see 'we can’t find the gist you’ve asked for' in a toast

  Scenario: A mistyped URL
    When I visit '/a-weird-url'
    Then I should see 'we can’t find anything at that URL' in a toast

  Scenario: Opening a gist by URL
    When I visit '/gist-4b459504bd36fbbd9cbf73d694eff47b/circle-with-params'
    And I wait until I see a 'saved – click to view' icon button
    Then the source should be
      """
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:parametric="//parametric-svg.js.org/v1" viewBox="0 0 400 462" width="400" height="462">
        <defs>
          <param name="a" value="30"/>
        </defs>
        <circle parametric:r="a * 10" r="300"/>
      </svg>
      """
    And the first parameter should be named 'a' and be set to '30'
    And I should see a circle with a radius of '300' on the canvas

    When I change the value of the first parameter to '50'
    Then I should see a circle with a radius of '500' on the canvas
    And I should see an 'enable gist integration' icon button
