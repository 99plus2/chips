module Chips.UserInput where
import Chips.Types
import Chips.Utils
import Chips.Common
import Chips.Core

-- this keeps track of when we last moved.
-- So if the user is holding a key down, we
-- don't want to move too fast.
lastPress :: IORef UTCTime
lastPress = unsafePerformIO $ do
  now <- getCurrentTime
  newIORef now

-- This is a game clock that keeps
-- track of when to move a bee, a frog,
-- etc.
lastTick :: IORef UTCTime
lastTick = unsafePerformIO $ do
  now <- getCurrentTime
  newIORef now

-- if a user is holding a key down, move
-- this fast (currently every 1/4 of a second)
moveSpeed = -0.25

-- used in some logic that lets a user hold a key down.
resetMoveTime :: IO ()
resetMoveTime = modifyIORef lastPress (addUTCTime moveSpeed)

on (EventKey (SpecialKey KeyLeft) Down _ _) gs = do
    if gs ^. disableInput
      then return gs
      else do
        resetMoveTime
        return $ player.direction .~ DirLeft $ gs

on (EventKey (SpecialKey KeyRight) Down _ _) gs = do
    if gs ^. disableInput
      then return gs
      else do
        resetMoveTime
        return $ player.direction .~ DirRight $ gs

on (EventKey (SpecialKey KeyUp) Down _ _) gs = do
    if gs ^. disableInput
      then return gs
      else do
        resetMoveTime
        return $ player.direction .~ DirUp $ gs

on (EventKey (SpecialKey KeyDown) Down _ _) gs = do
    if gs ^. disableInput
      then return gs
      else do
        resetMoveTime
        return $ player.direction .~ DirDown $ gs

on (EventKey (SpecialKey KeySpace) Down _ _) gs = do
    return $ godMode .~ True $ gs
on (EventKey (Char '1') Down _ _) gs = return $ gameState 1
on (EventKey (Char '2') Down _ _) gs = return $ gameState 2
on (EventKey (Char '3') Down _ _) gs = return $ gameState 3

on _ gs = do
    if gs ^. disableInput
      then return gs
      else return $ player.direction .~ Standing $ gs

maybeMove :: TilePos -> GameMonad () -> GameMonad ()
maybeMove tilePos newGs = do
    cur <- liftIO getCurrentTime
    last <- liftIO $ readIORef lastPress
    -- if we are holding a key down, we would move very fast.
    -- but in the game, there is a bit of a delay, chip doesn't ZOOM
    -- across the screen. This code slows chip down...so if the last 
    -- time we moved was too recently, don't move. Just return the
    -- same gameState.
    --
    -- This "lastPress" time gets reset every time you press a key,
    -- so if you keep pumping a direction key, you can move as fast
    -- as you can keep jamming on the key. But if you hold a key down,
    -- you will move as fast as `moveSpeed`.
    if diffUTCTime last cur > moveSpeed
      then return ()
      else do
        liftIO $ lastPress $= cur
        tile <- tilePosToTile tilePos
        gs <- get
        case tile of
          Wall _ -> oof
          LockRed _    -> if _redKeyCount gs > 0
                            then newGs
                            else oof
          LockBlue _   -> if _blueKeyCount gs > 0
                            then newGs
                            else oof
          LockGreen _  -> if _hasGreenKey gs
                            then newGs
                            else oof
          LockYellow _ -> if _yellowKeyCount gs > 0
                            then newGs
                            else oof
          Gate _       -> if chipsLeft gs == 0
                            then newGs
                            else oof
          Sand _ _ -> do
            i <- tilePosToIndex tilePos
            -- the index of the tile that this block
            -- of sand would be pushed to, if we allow the user to move
            let moveIdx =
                  case tilePos of
                    TileLeft -> i - 1
                    TileRight -> i + 1
                    TileAbove -> i - boardW
                    TileBelow -> i + boardW
            let moveTile = (gs ^. tiles) !! moveIdx
            case moveTile of
              Empty _ -> newGs
              Water _ -> newGs
              _ -> oof
          _ -> newGs
