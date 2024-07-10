module Name exposing
    ( Error(..)
    , Name(..)
    , fromString
    )


type Name
    = Name String


type Error
    = NameTooShort
    | NameTooLong


minLength : number
minLength =
    1


maxLength : number
maxLength =
    100


fromString : String -> Result Error Name
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed < minLength then
        Err NameTooShort

    else if String.length trimmed > maxLength then
        Err NameTooLong

    else
        Ok (Name trimmed)
