import Html exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Dict


baseUrl = "http://localhost:5000"

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Model =
  { maildirs : List String
  , status : Status
  , currentMaildir : Maybe.Maybe String
  , mails : List Mail
  }

type Status = Fine | Error Http.Error

type alias Mail =
    { subject : String
    , from : String
    }


init : (Model, Cmd Msg)
init =
  (Model [] Fine Maybe.Nothing [], getMaildirs (Model [] Fine Maybe.Nothing []))


-- UPDATE

type Msg
    = Display
    | NewMaildirsList (Result Http.Error (List String))
    | NewMaildirEmails (Result Http.Error (List Mail))
    | UpdateMaildirsList
    | OpenMaildir String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Display ->
            (model, Cmd.none)

        UpdateMaildirsList ->
            (model, getMaildirs model)

        NewMaildirsList (Ok newMaildirs) ->
            ({ model | maildirs = newMaildirs, status = Fine, currentMaildir = Maybe.Nothing }, Cmd.none)


        NewMaildirsList (Err err) ->
            ({ model | status = Error err} , Cmd.none)

        OpenMaildir maildir ->
            ({ model | currentMaildir = Just maildir }, openMaildir maildir)

        NewMaildirEmails (Ok mails) ->
             ({ model | mails = mails }, Cmd.none)

        NewMaildirEmails (Err err) ->
             ({ model | status = Error err}, Cmd.none)


-- VIEW
view : Model -> Html Msg
view model =
  case model.currentMaildir of
    Nothing ->
      renderMaildirs model
    Just currentMaildir ->
      renderMails model


renderMaildirs : Model -> Html Msg
renderMaildirs model =
  let
    maildirItem maildir = li [] [button [onClick (OpenMaildir maildir)] [text maildir]]
  in
      div []
        [ ul [] (List.map maildirItem model.maildirs)
        , p [] [text (case model.status of
                  Fine -> "Everything is fine"
                  Error err -> "We have some errors")]
        ]


renderMails : Model -> Html Msg
renderMails model =
  ul [] (List.map (\x -> li [] [text x.from, br [] [], text x.subject]) model.mails)


-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


getMaildirs : Model -> Cmd Msg
getMaildirs model =
    let
        url = baseUrl ++ "/maildir"
        request = Http.get url decodeMaildirs
    in
        Http.send NewMaildirsList request


decodeMaildirs : Decode.Decoder (List String)
decodeMaildirs =
    Decode.list Decode.string


openMaildir : String -> Cmd Msg
openMaildir maildir =
    let
        url = baseUrl ++ "/maildir/" ++ maildir
        request = Http.get url decodeMailsOfAMaildir
    in
        Http.send NewMaildirEmails request

decodeMailsOfAMaildir : Decode.Decoder (List Mail)
decodeMailsOfAMaildir =
  let
    dataToMail = List.map (\subject from -> Mail subject from)
  in
    Decode.list
      (Decode.map2 Mail
        (Decode.at ["headers", "Subject"] Decode.string)
        (Decode.at ["headers", "From"]    Decode.string))
