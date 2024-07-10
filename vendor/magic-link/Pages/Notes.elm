module Pages.Notes exposing (view)

import Element exposing (Element)
import Types exposing (LoadedModel)
import View.MarkdownThemed as MarkdownThemed


view : LoadedModel -> Element msg
view _ =
    """
#  Notes

This app demonstrates the use of magic link authentication for Lamdera. Here is how it works:

1. The user signs up, giving username, real name, and email address.

2. Once this is done, the user can sign in by entering their email.  The
system sends an eight-digit signin code to the user's email account.

3. The user enters the signin code, the system verifies it, and the user is
signed in.  The sign-in remains active for one month unless the user
signs out.


## Setting up magic link authentication

To set up magic link authentication for your Lamdera app,
you will need an account on [Postmark](https://postmarkapp.com/)
and add the Postmark API key to your settings in the Lamdera dashboard.
Postmark is the service used to send emails to users.

"""
        |> MarkdownThemed.renderFull
