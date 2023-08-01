{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}

module Isbike where

import Network.Wreq

-- Operators such as (&) and (.~).
import Control.Lens

-- Conversion of Haskell values to JSON.
import Data.Aeson ( Value, decode )

-- Easy traversal of JSON data.
import Data.Aeson.Lens --(key, nth)

import OpenSSL.Session (context)
import Network.HTTP.Client.OpenSSL
    ( opensslManagerSettings, withOpenSSL )

import           Data.Text (Text)
import Data.Maybe

import qualified Network.Wreq.Session as Sess

import qualified Data.ByteString.Lazy as BL
import qualified Data.Text.Lazy.Encoding as LE (decodeUtf8, encodeUtf8)
import qualified Data.Text.Lazy as L

import Data.List
import qualified Data.Text as T

import Data.Aeson.Encode.Pretty

import GeoJson


datasetFileName = "isbike.json"
outputFileName = "isbike.geojson"

isbikeData = BL.readFile datasetFileName

getIsbikeData = do
  res <- runApi

  maybe (putStrLn "No data to write") (BL.writeFile datasetFileName) res
  -- mapM (BL.writeFile datasetFileName) res

isbikeToGeo dataset = do
  v <- decode dataset :: Maybe Value
  okCode <- do
    code <- v ^? key "serviceCode" . _Integer
    if code == 0 then return code
                 else fail "Invalid API response code"
  stations <- v ^? key "dataList" . _Value
  return $ jsonValueToGeoFeatureCollection ("lon", "lat") stations

processIsbike = do
  dataset <- isbikeData

  let geoJson = isbikeToGeo dataset

  maybe (putStrLn "No data to write – conversion failed")
        (BL.writeFile outputFileName . encodePretty)
        geoJson


runApi = do
  sess <- Sess.newSession
  let opts = defaults & manager .~ Left (opensslManagerSettings context)

  getAllStationsStatus opts sess
  -- getStationStatus opts sess 457

-- getStationStatus
-- POST https://api.ibb.gov.tr/ispark-bike/GetStationStatus

getStationStatus opts sess stationId = do
  let moreHeaders = []
  let endpointUrl = "https://api.ibb.gov.tr/ispark-bike/GetStationStatus"
  r <- withOpenSSL $ Sess.postWith (opts & headers .~ moreHeaders)
                     sess endpointUrl
                     [ "guid" := show stationId ]
  return $ r ^? responseBody -- . key "form" . key "num"


-- GetAllStationStatus
-- POST https://api.ibb.gov.tr/ispark-bike/GetAllStationStatus
-- <empty>

getAllStationsStatus opts sess = do
  let moreHeaders = []
  let endpointUrl = "https://api.ibb.gov.tr/ispark-bike/GetAllStationStatus"
  r <- withOpenSSL $ Sess.postWith (opts & headers .~ moreHeaders)
                     sess endpointUrl
                     BL.empty
--   let rBody = r ^? responseBody
--   print rBody
--   return $ rBody >>= decode
  return $ r ^? responseBody -- . key "form" . key "num"
