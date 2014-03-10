# Twitter feed reader in Haskell

This program reads the twitter feed of another user and extracts all the links
from it.

# Installation

You will need the following packages

    cabal install http-conduit aeson authenticate-oauth

Note: `http-conduit` will take a while.

# Configuration

twitter-feed.hs expects a config file with the name `config.json` and the
following structure:

    data Config = Config {
      apiKey :: String,
      apiSecret :: String,
      consumerKey :: String,
      consumerSecret :: String
    }

The first two parameters are properties of your application, while the second
two are generated for a user-app pair. You can generate all by creating an app
at https://apps.twitter.com/ then going to the "API Keys" tab and generating an
API key there.

Note: Twitter call the consumerKey an "access token" and the consumer secret
an "access token secret"

# Running

You can compile this script before running it, but its probably best to use
`runhaskell`:

    runhaskell twitter-feed.hs <username>


