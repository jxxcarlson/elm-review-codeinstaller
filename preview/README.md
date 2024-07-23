*Disclaimer:* The work descdribe below is in-progress.  Feedback welcomed.


# Intro


The ReviewConfig.elm file exposes a function to configure a rule for
installing magic-link authentication in a Lamdera app:

```
config = makeConfig REAL_NAME USER NAME EMAIL
```

# Setup

To try out the installer, clone or fork this repo and 
configure the rule as above.  When all is done, you will then be the adminstrator of the app.
Now look for the file `vendor-secret/Env.elm` If it is not there, create it.  Do not commit it a
nd make an entry for it in your `.gitignore` file.  It should read

```
module Env exposing (postmarkApiKey)

postmarkApiKey =
    "TOP_SECRET!"
```

where   TOP_SECRET is the API key you get from Postmark.com.  Postmark is the service
your app will use to send messages to users.


# Demo

1.  At the root level, say `make uninstall`.  This will ensure that you have a plain vanilla app to start with.

2. In the directory `counter` say `lamdera live`.  You should see a "pagified" version of the counter app.

3. Go back to the root of the repo and say `make install`.  Now look at the app.  It should have additional tabs including "Sign in."  Try to sign in per your setup above.  After doing so, the "Admin" page should be accessible.

4. Refresh the browser.  You should still be signed in.

5. Clck on the  sign-out button in the header, far right.  Then go to the "Sign in", click "Sign up" and sign up with one of your other email addresses.  After you sign in, the admin page should no longer be accessible.
