{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Web.Stripe.Client.Internal
    ( callAPI
    , runStripe
    , config
    , Stripe             (..)
    , StripeRequest      (..)
    , StripeError      (..)
    , StripeConfig       (..)
    , StripeDeleteResult (..)
    , Method             (..)
    , module Web.Stripe.Client.Util 
    ) where

import           Control.Applicative             ((<$>), (<*>))
import           Control.Monad.IO.Class          (MonadIO (liftIO))
import           Control.Monad.Reader            (ReaderT, ask, runReaderT)
import           Data.Aeson                      (FromJSON, Value (Object),
                                                  decodeStrict, parseJSON, (.:))
import           Data.ByteString                 (ByteString)
import           Data.Maybe                      (fromMaybe, fromJust)
import           Data.Monoid                     (mempty)
import           Data.Text                       (Text)
import           Network.Http.Client             (Method(..), baselineContextSSL,
                                                  buildRequest, getStatusCode,
                                                  http, inputStreamBody,
                                                  openConnectionSSL,
                                                  receiveResponse, sendRequest,
                                                  setAuthorizationBasic,
                                                  setContentType, setHeader, closeConnection)
import           OpenSSL                         (withOpenSSL)
import           Web.Stripe.Client.Error         (StripeError (..),
                                                  StripeErrorHTTPCode (..))
import           Web.Stripe.Client.Util          
import           Web.Stripe.Client.Types 

import qualified Data.ByteString                 as S
import qualified Data.ByteString.Lazy            as BL
import qualified Data.ByteString.Lazy.Char8      as BL8
import qualified Data.Text                       as T
import qualified Data.Text.Encoding              as T
import qualified System.IO.Streams               as Streams

config :: StripeConfig
config = StripeConfig "sk_test_BQokikJOvBiI2HlWgH4olfQ2" "2014-08-20"

runStripe :: FromJSON a => StripeConfig -> Stripe a -> IO (Either StripeError a)
runStripe = flip runReaderT

callAPI :: FromJSON a => StripeRequest -> Stripe a
callAPI request = ask >>= \config ->
  liftIO $ sendStripeRequest config request

sendStripeRequest :: FromJSON a =>
                     StripeConfig ->
                     StripeRequest ->
                     IO (Either StripeError a)
sendStripeRequest StripeConfig{..} StripeRequest{..} = withOpenSSL $ do
  ctx <- baselineContextSSL
  con <- openConnectionSSL ctx "api.stripe.com" 443
  req <- buildRequest $ do
          http method $ "/v1" </> T.encodeUtf8 url
          setAuthorizationBasic secretKey mempty
          setContentType "application/x-www-form-urlencoded"
          setHeader "Stripe-Version" apiVersion
  body <- Streams.fromByteString $ paramsToByteString params
  sendRequest con req $ inputStreamBody body
  resp <- receiveResponse con $ 
          \response inputStream -> do
              -- Streams.connect inputStream Streams.stdout
              Streams.read inputStream >>= \res -> do
                  print (fromJust res)
                  maybeStream response res
  closeConnection con
  return resp
    where
    maybeStream response = maybe (error "Couldn't read stream") (handleStream response)
    handleStream p x = do
        return $ case getStatusCode p of
                   200 -> maybe (error "Parse failure") Right (decodeStrict x)
                   code | code >= 400 ->
                     do let json = fromMaybe (error "Parse Failure") (decodeStrict x :: Maybe StripeError)
                        Left $ case code of
                                 400 -> json { errorHTTP = Just BadRequest }
                                 401 -> json { errorHTTP = Just UnAuthorized }
                                 402 -> json { errorHTTP = Just RequestFailed }
                                 404 -> json { errorHTTP = Just NotFound }
                                 500 -> json { errorHTTP = Just StripeServerError }
                                 502 -> json { errorHTTP = Just StripeServerError }
                                 503 -> json { errorHTTP = Just StripeServerError }
                                 504 -> json { errorHTTP = Just StripeServerError }
                                 _   -> json { errorHTTP = Just UnknownHTTPCode }