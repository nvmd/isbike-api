module GeoJson where

import Data.Geospatial

import qualified Data.Sequence as Seq

import Control.Lens
import Data.Aeson
import Data.Aeson.Lens

import Data.Maybe

mkGeoPoint :: Double -> Double -> GeoPoint
mkGeoPoint x y = GeoPoint $ GeoPointXY $ PointXY x y


jsonValueToGeoFeatureCollection keyNames es@(Array _) = GeoFeatureCollection boundingBox features
  where boundingBox = Nothing
        features = Seq.fromList $ map (jsonValueToGeoFeature keyNames) (es ^.. values)
jsonValueToGeoFeatureCollection _ _ = error "Shouldn't happen!"

jsonValueToGeoFeature (long,lat) value@(Object _) = GeoFeature boundingBox geometry properties featureId
  where boundingBox = Nothing
        geometry = Point $ extractCoord value
        -- filter out keys containing coordinates – they're now stored in geometry
        properties = value & atKey long .~ Nothing
                           & atKey lat  .~ Nothing
        featureId = Nothing --Just $ FeatureIDNumber $ read $ T.unpack $ stopCode stop
        extractCoord e = let extractVal keyName = fromMaybe 0.0 $ e ^? key keyName . _String . _Double
                         in mkGeoPoint (extractVal long) (extractVal lat)
jsonValueToGeoFeature _ _ = error "Shouldn't happen!"
