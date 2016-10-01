Feature: Open gist
  Scenario: Uploading the drawing to gist
    When I visit '/gist-4b459504bd36fbbd9cbf73d694eff47b/circle-with-params'
    Then I should see a 'saved – click to view' icon button
    And the source should be '<svg xmlns="http://www.w3.org/2000/svg" xmlns:parametric="//parametric-svg.js.org/v1">\n  <defs>\n    <param name="a" value="10"/>\n  </defs>\n  <circle parametric:r="a * 10" r="300"/>\n</svg>'
    And I should see parameter 'a' set to '30'
    And I should see a circle with a radius of '300' on the canvas

    When I change the parameter 'a' to '50'
    Then I should see a circle with a radius of '500'
    And I should see an 'unsaved changes – click to save' icon button
