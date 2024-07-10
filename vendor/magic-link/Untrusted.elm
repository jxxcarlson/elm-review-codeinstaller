module Untrusted exposing
    ( Untrusted(..)
    , untrust
    )

{-| We can't be sure a value we got from the frontend hasn't been tampered with.
In cases where an opaque type uses code to give some kind of guarantee (for example
MaxAttendees makes sure the max number of attendees is at least 2) we wrap the value in Unstrusted to
make sure we don't forget to validate the value again on the backend.
-}


type Untrusted a
    = Untrusted a


untrust : a -> Untrusted a
untrust =
    Untrusted
