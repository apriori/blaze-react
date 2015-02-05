{-# LANGUAGE OverloadedStrings #-}

module Blaze2.ReactJS.Examples.Clock
    ( renderState
    , handleRequest
    ) where

import           Blaze2.Core.Examples.Clock
import           Blaze2.ReactJS.Base

import           Control.Concurrent (threadDelay)
import           Control.Monad (forever)

import           Data.Monoid ((<>))
import           Data.Time (getCurrentTime)

import qualified Text.Blaze.Html5 as H

renderState :: ClockS -> WindowState ClockA
renderState (ClockS mbTime) = WindowState
    { _wsPath = ""
    , _wsBody = case mbTime of
        Just time -> "The time is: " <> H.toHtml (show time)
        Nothing   -> "Loading..."
    }

handleRequest :: (ClockA -> IO ()) -> [ClockR] -> IO ()
handleRequest chan = mapM_ $ \req ->
    case req of
      StartHeartbeat -> forever $ do
        time <- getCurrentTime
        chan $ TickA time
        threadDelay 1000000

