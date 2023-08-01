module Main where

import Isbike

main :: IO ()
main = do
  putStrLn "Hello, Haskell!"
  -- https://data.ibb.gov.tr/dataset/isbike-stations-status-web-service
  putStrLn "Getting data from İsbike Open Data API..."
  getIsbikeData
  putStrLn "Converting data to GeoJSON..."
  processIsbike
