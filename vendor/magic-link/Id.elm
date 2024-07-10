module Id exposing
    ( Id(..)
    , fromString
    , toString
    )


type Id a
    = Id String


toString : Id a -> String
toString (Id hash) =
    hash


fromString : String -> Id a
fromString =
    Id
