{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

{-
  virtual-dom bindings demo, rendering a large pixel grid with a bouncing red
  square. the step and patch are calculated asynchronously, the update is
  batched in an animation frame
 -}

module Main (main) where

import           Prelude hiding (div)


import           Control.Applicative
import           Control.Concurrent        (threadDelay)
import           Control.Concurrent.MVar
import           Control.Exception         (evaluate, bracket)
import           Control.Monad

import           Data.Time             (getCurrentTime)

import           GHCJS.Types           (JSRef, JSString, JSFun, JSObject)
import qualified GHCJS.Foreign         as Foreign
import           GHCJS.Foreign.QQ      (js, js_)
import qualified GHCJS.Prim            as Prim

import           Safe                  (readMay)

import           System.IO             (fixIO)

import           TodoApp (App(..), DOMEvent(..), todoApp)

import qualified Text.Blaze.Renderer.ReactJS    as Blaze.ReactJS


------------------------------------------------------------------------------
-- Our main function
------------------------------------------------------------------------------

main :: IO ()
main = runApp todoApp


------------------------------------------------------------------------------
-- Generic 'runApp' function based on reactjs
------------------------------------------------------------------------------


-- ISSUES:
--   * 'this' in callbacks
--   * how to return a value from a sync callback


-- | A type-tag for an actual Browser DOM node.
data DOMNode_
data ReactJSApp_

foreign import javascript unsafe
    "h$reactjs.mountApp($1, $2)"
    mountReactApp
        :: JSRef DOMNode_                          -- ^ Browser DOM node
        -> JSFun (JSObject Blaze.ReactJS.ReactJSNode -> IO ())
           -- ^ render callback that stores the created nodes in the 'node'
           -- property of the given object.
        -> IO (JSRef ReactJSApp_)

foreign import javascript unsafe
    "h$reactjs.syncRedrawApp($1)"
    syncRedrawApp :: JSRef ReactJSApp_ -> IO ()


runApp :: (Show eh, Read eh, Show act) => App st act eh -> IO ()
runApp (App initialState _apply renderAppState _handleEvent) = do
    -- create root element in body for the app
    root <- [js| document.createElement('div') |]
    [js_| document.body.appendChild(`root); |]

    -- create render callback for initialState
    let mkRenderCb :: IO (JSFun (JSObject Blaze.ReactJS.ReactJSNode -> IO ()))
        mkRenderCb = do
            Foreign.syncCallback1 Foreign.AlwaysRetain False $ \objRef -> do
                node <- Blaze.ReactJS.renderHtml (renderAppState initialState)
                Foreign.setProp ("node" :: JSString) node objRef


    -- mount and redraw app
    bracket mkRenderCb Foreign.release $ \renderCb -> do
        app <- mountReactApp root renderCb
        syncRedrawApp app

{-
atAnimationFrame :: IO () -> IO ()
atAnimationFrame io = do
    cb <- fixIO $ \cb ->
        Foreign.syncCallback Foreign.AlwaysRetain
                             False
                             (Foreign.release cb >> io)
    [js_| window.requestAnimationFrame(`cb); |]

lookupEventHandlerName :: JSRef () -> IO (Maybe String)
lookupEventHandlerName eventRef = do
    mbNameRef <- js_lookupEventHandlerName eventRef
    return $
        if Prim.isNull mbNameRef
          then Nothing
          else Just (Prim.fromJSString mbNameRef)

foreign import javascript unsafe
  "$1.target.getAttribute(\"data-on-blaze-event\")"
  js_lookupEventHandlerName :: JSRef () -> IO JSString

runApp :: (Show eh, Read eh, Show act) => App st act eh -> IO ()
runApp (App initialState apply renderAppState handleEvent) = do
    -- create root element in body for the app
    root <- [js| document.createElement('div') |]
    [js_| document.body.appendChild(`root); |]

    -- create virtual DOM node corresponding to the empty root div
    rootVNode <- VirtualDom.vnode "div"
                   <$> VirtualDom.newProperties
                   <*> VirtualDom.newChildren

    -- create global state variable
    stateVar <- newMVar (False, initialState, rootVNode)

    -- setup event handlers
    let redraw :: IO ()
        redraw = modifyMVar_ stateVar $ \(_requestedRedraw, state, oldVNode) -> do
            newVNode <- Blaze.VirtualDom.renderHtml (renderAppState state)
            patch <- evaluate (VirtualDom.diff oldVNode newVNode)
            VirtualDom.applyPatch root patch
            return (False, state, newVNode)


        installEventHandler :: JSString -> IO DOMEvent -> IO ()
        installEventHandler jsDomEventName mkDomEvent = do
          cb <- Foreign.syncCallback1 Foreign.AlwaysRetain False $ \event -> do
                  mbEventHandlerName <- lookupEventHandlerName event
                  case mbEventHandlerName of
                    Nothing -> putStrLn "No event handler found."
                    Just eventHandlerName -> case readMay eventHandlerName of
                      Nothing -> putStrLn $
                          "Could not parse event handler name: " ++ eventHandlerName
                      Just eventHandler -> do
                        t        <- getCurrentTime
                        domEvent <- mkDomEvent
                        case handleEvent t domEvent eventHandler of
                          Nothing -> putStrLn $
                            "Event handler '" ++ show eventHandler ++ "' rejected '" ++ show domEvent ++ "."
                          Just action -> do
                            putStrLn $ "Event handler '" ++ show (t, domEvent, eventHandler) ++
                                       "' generated action: " ++ show action
                            modifyMVar_ stateVar $ \(requestedRedraw, state, oldVNode) -> do
                                unless requestedRedraw $ atAnimationFrame redraw
                                return (True, apply action state, oldVNode)

          [js_| `root.addEventListener(`jsDomEventName, `cb, false)|]

    -- install click event handler on the root
    installEventHandler "click"    (return OnClick)
    installEventHandler "dblclick" (return OnDoubleClick)

    -- request a redraw for the initial state
    atAnimationFrame redraw

    putStrLn "Started app"

    -- FIXME (SM): it seems as if we need to keep the main thread running to
    -- ensure that the callbacks still work. This is suboptimal.
    forever $ threadDelay 10000000

-}