module Tests exposing (all)

import Test exposing
  ( describe
  , Test
  )

import OpenGist


all : Test
all =
  describe "parametric-svg.surge.sh"
    [ OpenGist.all
    ]
