{-# LANGUAGE OverloadedStrings #-} 
{-# LANGUAGE DeriveDataTypeable #-}

-- Overloaded strings is just for "api.twitter.com"
-- The other

import Data.Data;
import System.Environment;
import Web.Authenticate.OAuth;

import qualified Data.ByteString.Lazy  as BL;
import qualified Data.ByteString       as B;
import qualified Data.ByteString.UTF8  as BUTF8;
import qualified Network.HTTP.Conduit  as HTTP;
import qualified Data.Aeson.Generic    as JSON;

-- Program to extract youtube links from a user's twitter feed
-- Takes a twitter username outputs list of link to console.


-- JSON structure: [Tweet]
data Tweet = Tweet { entities:: Entities } deriving (Data, Typeable)
data Entities = Entities { urls :: [Url] } deriving (Data, Typeable)
data Url = Url { expanded_url :: String } deriving (Data, Typeable)

-- Extracts links from the JSON structure
extractLinks :: [Tweet] -> [String]
extractLinks tweets =
  let ents = map entities tweets
      urllist = ents >>= urls
  in map expanded_url urllist;


-- Builds a twitter API endpoint link
-- https://api.twitter.com/1.1/statuses/user_timeline.json
-- GET parameter: screen_name=username
buildTimelineLink :: String -> String
buildTimelineLink user =
  "https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=" ++ user;

-- Configuration file format. Contains api and consumer keys/secrets
data Config = Config {
  apiKey :: String,
  apiSecret :: String,
  consumerKey :: String,
  consumerSecret :: String
} deriving (Data, Typeable, Show)

-- Prepares OAuth credentials from the configuration
-- which can then be used to sign the request
prepareCredentials :: Config -> (Credential, OAuth)
prepareCredentials config =
  -- TODO: Isn't there a better way to do this?
  -- Unfortunately, I can't use ByteString properties, JSON.decode fails
  (newCredential
   (BUTF8.fromString $ apiKey config)
   (BUTF8.fromString $ apiSecret config),
   newOAuth { oauthServerName     = "api.twitter.com",
              oauthConsumerKey    = BUTF8.fromString $ consumerKey config,
              oauthConsumerSecret = BUTF8.fromString $ consumerSecret config})

-- Read configuration, then display tweets of user
main :: IO ()
main = do
  configData <- BL.readFile "config.json"
  [user] <- getArgs
  let mConfig = JSON.decode configData :: Maybe Config
  case mConfig of
    Nothing -> do
      putStrLn("Unable to parse config.json:");
      BL.putStr(configData)
    Just config -> displayWith config user;

-- using configuration, display tweets for user to stdout
displayWith :: Config -> String -> IO ()
displayWith config user = do
  let (myCredential, myOauthApp) = prepareCredentials config;
  req <- HTTP.parseUrl $ buildTimelineLink user
  signedReq <- signOAuth myOauthApp myCredential req;
  resp <- HTTP.withManager $ \m -> HTTP.httpLbs signedReq m
  let body = HTTP.responseBody resp
  let maybeTweets = JSON.decode body :: Maybe [Tweet]
  case maybeTweets of
    Nothing -> putStrLn "No tweets found"
    Just tweets -> mapM_ putStrLn $ extractLinks tweets

