module Chips.UserInput where
import Chips.Types
import Chips.Utils
import Chips.Common
import Chips.Core
import Chips.Globals

-- if a user is holding a key down, move
-- this fast (currently every 1/4 of a second)
moveSpeed = -0.15

-- used in some logic that lets a user hold a key down.
resetMoveTime :: IO ()
resetMoveTime = modifyIORef lastPress (addUTCTime moveSpeed)

on :: Event -> GameMonad ()
on (EventKey (SpecialKey KeyLeft) Down _ _) = do
  gs <- get
  when (not $ gs ^. disableInput) $ do
    liftIO resetMoveTime
    player.direction .= DirLeft

on (EventKey (SpecialKey KeyRight) Down _ _) = do
  gs <- get
  when (not $ gs ^. disableInput) $ do
    liftIO resetMoveTime
    player.direction .= DirRight

on (EventKey (SpecialKey KeyUp) Down _ _) = do
  gs <- get
  when (not $ gs ^. disableInput) $ do
    liftIO resetMoveTime
    player.direction .= DirUp

on (EventKey (SpecialKey KeyDown) Down _ _) = do
  gs <- get
  when (not $ gs ^. disableInput) $ do
    liftIO resetMoveTime
    player.direction .= DirDown

on (EventKey (SpecialKey KeySpace) Down _ _) = godMode .= True
on (EventKey (Char '1') Down _ _) = put $ gameState 1
on (EventKey (Char '2') Down _ _) = put $ gameState 2
on (EventKey (Char '3') Down _ _) = put $ gameState 3
on (EventKey (Char '4') Down _ _) = put $ gameState 4
on (EventKey (Char '5') Down _ _) = put $ gameState 5
on (EventKey (Char '6') Down _ _) = put $ gameState 6
on (EventKey (Char '7') Down _ _) = put $ gameState 7

on _ = do
    gs <- get
    when (not $ gs ^. disableInput) $ do
      player.direction .= Standing

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
          ToggleDoor False _ -> oof
          BlueWall True _ -> do
            setTile tilePos (Wall def)
            oof
          BlueWall False _ -> do
            setTile tilePos (Empty def)
            newGs
          InvisibleWall True _ -> do
            setTile tilePos (Wall def)
            oof
          InvisibleWall False _ -> oof
          LockRed _    -> if _redKeyCount gs > 0 || gs ^. godMode
                            then newGs
                            else oof
          LockBlue _   -> if _blueKeyCount gs > 0 || gs ^. godMode
                            then newGs
                            else oof
          LockGreen _  -> if _hasGreenKey gs || gs ^. godMode
                            then newGs
                            else oof
          LockYellow _ -> if _yellowKeyCount gs > 0 || gs ^. godMode
                            then newGs
                            else oof
          Gate _       -> if chipsLeft gs == 0 || gs ^. godMode
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
