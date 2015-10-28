{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Control.Exception (throw)
import Control.Monad (forM_, liftM)
import Control.Monad.IO.Class (liftIO)

import Data.Conduit
import Data.Monoid ((<>))
import qualified Data.HashMap.Strict as HM
import qualified Data.ByteString.Char8 as BS
import qualified Data.Text as T
import qualified Data.Text.IO as T

import System.Environment (getArgs)

import GDAL
import OGR

main :: IO ()
main = withGDAL $ liftM (either throw id) $ runGDAL $ do
  [fname, nameStr] <- liftIO getArgs
  let name = T.pack nameStr
  ds <- OGR.openReadOnly fname
  l <- getLayerByName name ds
  schema <- layerFeatureDef l
  extent <- layerExtent l
  liftIO $ do
    T.putStrLn "Extent:"
    print  extent
    T.putStrLn "Schema:"
    print schema

  sourceLayer (getLayerByName name ds) $$ awaitForever $ \(mFid, Feature{..}) ->
    liftIO $ do
      T.putStrLn ""
      T.putStrLn ""
      putStrLn ("FID: " <> maybe ("<unknown>") show mFid)
      T.putStrLn "Fields:"
      forM_ (HM.toList fFields) $ \(name, value) -> do
        T.putStrLn ("  " <> name <> ":")
        putStrLn ("    " <> show value)
      T.putStrLn ("Geometry:")
      BS.putStrLn (maybe "" (("  "<>) . exportToWkt) fGeom)
