module LocalUUID exposing
    ( Data
    , extractUUIDAsString
    , initFrom4List
    , randomNumberUrl
    , step
    )

import Random
import UUID


{-| maxDigits < 10
-}
randomNumberUrl : Int -> Int -> String
randomNumberUrl n maxDigits =
    let
        maxNumber =
            10 ^ maxDigits

        prefix =
            "https://www.random.org/integers/?num="

        suffix =
            "&col=" ++ String.fromInt n ++ "&base=10&format=plain&rnd=new"
    in
    prefix ++ String.fromInt n ++ "&min=1&max=" ++ String.fromInt maxNumber ++ suffix



-- UUID


type alias Data =
    ( UUID.UUID, UUID.Seeds )


extractUUIDAsString : Data -> String
extractUUIDAsString ( uuid, _ ) =
    UUID.toString uuid


initFrom4List : List Int -> Maybe Data
initFrom4List list =
    case list of
        [ s1, s2, s3, s4 ] ->
            Just (init s1 s2 s3 s4)

        _ ->
            Nothing


init : Int -> Int -> Int -> Int -> Data
init s1 s2 s3 s4 =
    step_ (init_ s1 s2 s3 s4)


step : Data -> Data
step ( uuid, ss ) =
    let
        ( newUuid, newSs ) =
            step_ ss
    in
    ( newUuid, newSs )


init_ : Int -> Int -> Int -> Int -> UUID.Seeds
init_ s1 s2 s3 s4 =
    UUID.Seeds (Random.initialSeed s1) (Random.initialSeed s2) (Random.initialSeed s3) (Random.initialSeed s4)


step_ : UUID.Seeds -> ( UUID.UUID, UUID.Seeds )
step_ ss =
    UUID.step (UUID.Seeds ss.seed1 ss.seed2 ss.seed3 ss.seed4)
