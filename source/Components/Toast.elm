module Components.Toast exposing
  ( getHelp, takeMeHome, pleaseReportThis
  , custom, basic, toasts
  )

import Html exposing (Html, node, a, text)
import Html.Attributes exposing (attribute, href, target)

import Types exposing (ToastContent)
import Components.Link exposing (link)




-- UTILS

getHelp : String -> ToastContent
getHelp message =
  { message = message
  , buttonText = "get help"
  , buttonUrl =
    "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
  , openInNewTab = True
  }

takeMeHome : String -> ToastContent
takeMeHome message =
  { message = message
  , buttonText = "take me home"
  , buttonUrl = "/"
  , openInNewTab = False
  }

pleaseReportThis : ToastContent
pleaseReportThis =
  { message =
    ( "Booo, our bad. Things ended up in a weird state. If you have "
    ++ "a spare five minutes, please help us resolve this problem "
    ++ "by reporting it in a github issue."
    )
  , buttonText = "see issues"
  , buttonUrl =
    "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
  , openInNewTab = True
  }




-- VIEW

toasts : {a | toasts : List ToastContent} -> List (Html b)
toasts componentModel =
  List.reverse componentModel.toasts
  |> List.map custom

custom : ToastContent -> Html a
custom toast =
  node "paper-toast"
    [ attribute "duration" "10000"
    , attribute "opened" ""
    , attribute "text" toast.message
    ]
    [ link
      ( [ href toast.buttonUrl
        ]
        ++ if toast.openInNewTab
          then [target "_blank"]
          else []
      )
      [ node "paper-button" []
        [ text toast.buttonText
        ]
      ]
    ]

basic : String -> Html a
basic = custom << getHelp
