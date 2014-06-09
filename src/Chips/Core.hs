{-# LANGUAGE TemplateHaskell, NoMonomorphismRestriction #-}
module Chips.Core where
import Chips.Types
import Chips.Utils
import Chips.Common
import qualified Data.ByteString.Lazy as B
import Chips.Globals

chipsLeft gs = length $ filter isChip (_tiles gs)
  where isChip (Chip _) = True
        isChip _        = False

tileSize = 32
soundDir = "sounds/"

levelNames = [
  "LESSON 1",
  "LESSON 2",
  "LESSON 3",
  "LESSON 4",
  "LESSON 5",
  "LESSON 6",
  "LESSON 7",
  "LESSON 8",
  "NUTS AND BOLTS",
  "BRUSHFIRE",
  "TRINITY",
  "HUNT",
  "SOUTHPOLE",
  "TELEBLOCK",
  "ELEMENTARY",
  "CELLBLOCKED",
  "NICE DAY",
  "CASTLE MOAT",
  "DIGGER",
  "TOSSED SALAD"
  ]

passwords = [
  "BDHP",
  "JXMJ",
  "ECBQ",
  "YMCJ",
  "TQKB",
  "WNLD",
  "FXQO",
  "NHAG",
  "KCRE",
  "UVWS",
  "CNPE",
  "WVHI",
  "OCKS"
  ]


oof :: GameMonad ()
oof = liftIO $ playSound (soundDir ++ "oof.wav") False

win :: GameMonad ()
win = liftIO $ playSound (soundDir ++ "win.wav") False

bummer :: GameMonad ()
bummer = liftIO $ playSound (soundDir ++ "bummer.wav") False

die :: GameMonad ()
die = do
  gs <- get
  when (not $ gs ^. godMode) $ do
    bummer >> put (gameState (gs ^. level))

-- given a number, returns the 2-d array that represents the tilemap for
-- that level.
tileMap :: Int -> IO [[Int]]
tileMap i = do
    contents <- B.readFile $ "maps/" ++ (show i) ++ ".json"
    let decoded = eitherDecode contents :: Either String [[Int]]
    case decoded of
      Left err -> error err
      Right map -> return map

boardW = 32 -- length . head $ tileMap
boardH = 32 -- length tileMap

playerCoords :: GameState -> (Int, Int)
playerCoords gs = ((floor (p ^. x)) // tileSize, (((boardH * tileSize) - (floor (p ^. y))) // tileSize)-1)
    where p = _player gs
          ts = _tiles gs

currentIdx :: GameState -> Int
currentIdx gs = y_ * boardW + x_
    where (x_,y_) = playerCoords gs

-- given a tile position, gives you the index
-- of that tile in the tiles array.
tilePosToIndex :: TilePos -> GameMonad Int
tilePosToIndex pos = do
    gs <- get
    let playerIdx = currentIdx gs
    return $ case pos of
      Current   -> playerIdx
      TileLeft  -> playerIdx - 1
      TileRight -> playerIdx + 1
      TileAbove -> playerIdx - boardW
      TileBelow -> playerIdx + boardW
      Arbitrary i -> i

tilePosToTile :: TilePos -> GameMonad Tile
tilePosToTile pos = do
    gs <- get
    i <- tilePosToIndex pos
    return $ (gs ^. tiles) !! i

setTile :: TilePos -> Tile -> GameMonad ()
setTile pos tile = do
    gs <- get
    i <- tilePosToIndex pos
    -- TODO refactor this -v
    let attrs_ = ((gs ^. tiles) !! i) ^. attrs
    tiles.(ix i) .= (attrs .~ attrs_ $ tile)

-- Given a tilemap (gotten with the `tileMap` function),
-- returns a list of all the tiles
renderedTiles :: [[Int]] -> [Tile]
renderedTiles tmap = renderTileMap tmap f (tileSize, tileSize)
    where f 0  = Empty def -- 0 == where chip will be
          f 1  = Empty def
          f 2  = Wall def
          f 3  = Chip def
          f 4  = KeyYellow def
          f 5  = KeyRed def
          f 6  = KeyGreen def
          f 7  = KeyBlue def
          f 8  = LockYellow def
          f 9  = LockRed def
          f 10 = LockGreen def
          f 11 = LockBlue def
          f 12 = Gate def
          f 13 = GateFinal def
          f 14 = Help def
          f 15 = Amoeba def
          f 16 = Bee DirUp (Empty def) def
          f 17 = Bomb def
          f 18 = FFDown def
          f 19 = FFLeft def
          f 20 = FFRight def
          f 21 = FFUp def
          f 22 = FFRandom def
          f 23 = FFShoes def
          f 24 = FireBoots def
          f 25 = Fire def
          f 26 = Flippers def
          f 27 = Frog DirUp (Empty def) def
          f 28 = IceBottomLeft def
          f 29 = IceBottomRight def
          f 30 = IceSkates def
          f 31 = IceTopLeft def
          f 32 = IceTopRight def
          f 33 = Ice def
          f 34 = Sand (Empty def) def
          f 35 = Spy def
          f 36 = Tank DirUp (Empty def) def
          f 37 = WaterSplash def
          f 38 = Water def
          f 39 = Worm DirUp (Empty def) def
          f 40 = Sand (Chip def) def
          f 41 = Sand (Fire def) def
          f 42 = ButtonBlue def
          f 43 = ButtonBrown def
          f 44 = ButtonRed def
          f 45 = ButtonGreen def
          f 46 = ToggleDoor True def
          f 47 = ToggleDoor False def
          f 48 = BallPink DirRight (Empty def) def
          f 49 = BallPink DirLeft (Empty def) def
          f 50 = BallPink DirUp (Empty def) def
          f 51 = BallPink DirDown (Empty def) def
          f 52 = Rocket DirUp (Empty def) def
          f 53 = Rocket DirDown (Empty def) def
          f 54 = Rocket DirLeft (Empty def) def
          f 55 = Rocket DirRight (Empty def) def
          f 56 = Fireball DirUp (Empty def) def
          f 57 = Fireball DirDown (Empty def) def
          f 58 = Fireball DirLeft (Empty def) def
          f 59 = Fireball DirRight (Empty def) def
          f 60 = GeneratorFireball DirUp def
          f 61 = GeneratorFireball DirDown def
          f 62 = GeneratorFireball DirLeft def
          f 63 = GeneratorFireball DirRight def
          f 64 = Trap (Empty def) def

-- Given a level number, returns the starting game state for that level
gameState :: Int -> GameState
gameState i = x .~ startX $ y .~ startY $ gs
  where player_ = (Player Standing (Empty def) def)
        tmap = unsafePerformIO $ tileMap i
        gs = GameState
              (renderedTiles tmap)
              (x .~ ((fst chipStart)*tileSize) $ y .~ ((snd chipStart)*tileSize) $ player_)
              i
              0 0 0 False
              False False False False False
              False
              def
        startX = (4 - fst chipStart) * tileSize -- "4" is (9 - 1)/2. 9 is the width of the game screen
        startY = (4 - snd chipStart) * tileSize
        -- | (x, y) of chip's start position (marked as a 0 on the tile map)
        chipStart :: (Float, Float)
        chipStart =
          case findIndex (\xs -> 0 `elem` xs) tmap of
            Nothing -> error "You need to mark where chip will stand in the tilemap. Mark it with a zero (0)."
            Just y -> (fromIntegral . fromJust $ findIndex (==0) (tmap !! y), boardH - 1 - (fromIntegral y))

isButton (ButtonRed _)   = True
isButton (ButtonBlue _)  = True
isButton (ButtonGreen _) = True
isButton (ButtonBrown _) = True
isButton _               = False

-- move a tile from one location to another. Generally
-- used to move tanks, frogs, other enemies. If the enemy
-- had a special tile under them (like a button, for example),
-- that special tile won't be erased.
-- When the item gets moved to a location with a button,
-- that button will get pressed. If there's a trap there,
-- the item will now be in the trap.
moveTile :: Int -> Int -> GameMonad ()
moveTile from to = do
  gs <- get
  let fromTile = (gs ^. tiles) !! from
      toTile = (gs ^. tiles) !! to
      tileUnder = 
        case fromTile of
          Tank _ t _ -> t
          Bee _ t _ -> t
          Frog _ t _ -> t
          Sand t _ -> t
          Worm _ t _ -> t
          BallPink _ t _ -> t
          Rocket _ t _ -> t
          Fireball _ t _ -> t
          _ -> Empty def
      newToTile =
        case fromTile of
          Tank dir _ _ -> Tank dir toTile def
          Bee dir _ _ -> Bee dir toTile def
          Frog dir _ _ -> Frog dir toTile def
          Sand _ _ -> Sand toTile def
          Worm dir _ _ -> Worm dir toTile def
          BallPink dir _ _ -> BallPink dir toTile def
          Rocket dir _ _ -> Rocket dir toTile def
          Fireball dir _ _ -> Fireball dir toTile def
          _ -> fromTile
  setTile (Arbitrary from) tileUnder
  case toTile of
    Trap _ _ -> setTile (Arbitrary to) (Trap fromTile def)
    _ -> setTile (Arbitrary to) newToTile
  when (isButton toTile) $ checkCurTile toTile

-- given a tile and a direction, move it in that direction
-- if there are no walls or anything. Used to move enemies.
-- The last param is a function that takes a tile type and
-- returns the appropriate action. This is because some
-- enemies respond differently to different tiles.
maybeMoveTile :: Int -> Direction -> ((Tile, Int) -> GameMonad ()) -> GameMonad ()
maybeMoveTile i dir func = do
  gs <- get
  let moveIfEmpty moveI = do
        case (gs ^. tiles) !! moveI of
          Empty _ -> moveTile i moveI
          ButtonRed _ -> moveTile i moveI
          ButtonBrown _ -> moveTile i moveI
          ButtonBlue _ -> moveTile i moveI
          ButtonGreen _ -> moveTile i moveI
          ToggleDoor True _ -> moveTile i moveI
          Trap _ _ -> moveTile i moveI
          x -> func (x, moveI)
  case dir of
    DirLeft  -> moveIfEmpty (i - 1)
    DirRight -> moveIfEmpty (i + 1)
    DirUp    -> moveIfEmpty (i - boardW)
    DirDown  -> moveIfEmpty (i + boardW)

moveEnemies :: GameMonad ()
moveEnemies = do
  gs <- get
  forM_ (withIndices (gs ^. tiles)) $ \(tile, i) -> do
    case tile of
      Tank dir _ _   -> maybeMoveTile i dir $ \_ -> return ()
      Rocket dir _ _ -> maybeMoveTile i dir $ \_ -> return ()
      BallPink dir tileUnder _ -> maybeMoveTile i dir $ \_ -> do
                                    setTile (Arbitrary i) (BallPink (opposite dir) tileUnder def)
      Fireball dir _ _ -> maybeMoveTile i dir $ \(tile, moveI) ->
                            case tile of
                              Fire _ -> moveTile i moveI
                              Water _ -> setTile (Arbitrary i) (Empty def)
                              _ -> return ()
      Bee _ _ _ -> moveBee i
      _       -> return ()
  return ()

-- Move this bee counter-clockwise around an object.
moveBee :: Int -> GameMonad ()
moveBee i = do
    gs <- get
    let bee = (gs ^. tiles) !! i
        goLeft  = moveIfEmpty (i - 1) DirLeft
        goRight = moveIfEmpty (i + 1) DirRight
        goUp    = moveIfEmpty (i - boardW) DirUp
        goDown  = moveIfEmpty (i + boardW) DirDown
        moveIfEmpty moveI dir = do
          case (gs ^. tiles) !! moveI of
            Empty _ -> do
              setTile (Arbitrary i) (_tileUnderBee bee)
              setTile (Arbitrary moveI) (Bee dir (Empty def) def)
              when (isButton (_tileUnderBee bee)) $ checkCurTile (_tileUnderBee bee)
              return True
            _ -> return False
    case _beeDirection bee of
      DirUp    -> goLeft  <||> goUp    <||> goRight <||> goDown
      DirLeft  -> goDown  <||> goLeft  <||> goUp    <||> goRight
      DirDown  -> goRight <||> goDown  <||> goLeft  <||> goUp
      DirRight -> goUp    <||> goRight <||> goDown  <||> goLeft
    return ()

(<||>) :: GameMonad Bool -> GameMonad Bool -> GameMonad Bool
a <||> b = do
  res <- a
  if res
    then return True
    else b

opposite DirUp = DirDown
opposite DirDown = DirUp
opposite DirLeft = DirRight
opposite DirRight = DirLeft

checkCurTile :: Tile -> GameMonad ()
checkCurTile (Chip _) = do
  liftIO $ playSound (soundDir ++ "collect_chip.wav") False
  setTile Current (Empty def)
checkCurTile (Gate _) = do
  liftIO $ playSound (soundDir ++ "door.wav") False
  setTile Current (Empty def)
checkCurTile (KeyYellow _) = do
  yellowKeyCount += 1
  setTile Current (Empty def)
checkCurTile (KeyBlue _) = do
  blueKeyCount += 1
  setTile Current (Empty def)
checkCurTile (KeyGreen _) = do
  hasGreenKey .= True
  setTile Current (Empty def)
checkCurTile (KeyRed _) = do
  redKeyCount += 1
  setTile Current (Empty def)
checkCurTile (LockYellow _) = do
  liftIO $ playSound (soundDir ++ "door.wav") False
  yellowKeyCount -= 1
  setTile Current (Empty def)
checkCurTile (LockBlue _) = do
  liftIO $ playSound (soundDir ++ "door.wav") False
  blueKeyCount -= 1
  setTile Current (Empty def)
checkCurTile (LockGreen _) = do
  liftIO $ playSound (soundDir ++ "door.wav") False
  setTile Current (Empty def)
checkCurTile (LockRed _) = do
  liftIO $ playSound (soundDir ++ "door.wav") False
  redKeyCount -= 1
  setTile Current (Empty def)
checkCurTile (GateFinal _) = do
  win
  gs <- get
  put $ gameState (gs ^. level + 1)
checkCurTile (Water _) = do
  gs <- get
  when (not . _hasFlippers $ gs) die
checkCurTile (Fire _) = do
  gs <- get
  when (not . _hasFireBoots $ gs) die
checkCurTile (Ice _) = do
  gs <- get
  when (not $ _hasIceSkates gs || _godMode gs) $ do
    case gs ^. player.direction of
      DirLeft  -> do
          player.x -= tileSize
          x += tileSize
      DirRight -> do
          player.x += tileSize
          x -= tileSize
      DirUp    -> do
          player.y += tileSize
          y -= tileSize
      DirDown  -> do
          player.y -= tileSize
          y += tileSize
      _ -> return ()
checkCurTile (IceBottomLeft _) = do
  gs <- get
  when (not $ _hasIceSkates gs || _godMode gs) $ do
    case gs ^. player.direction of
      DirLeft -> do
        player.direction .= DirUp
        player.y += tileSize
        y -= tileSize
      DirDown -> do
        player.direction .= DirRight
        player.x += tileSize
        x -= tileSize
      _ -> return ()
checkCurTile (IceTopLeft _) = do
  gs <- get
  when (not $ _hasIceSkates gs || _godMode gs) $ do
    case gs ^. player.direction of
      DirLeft -> do
        player.direction .= DirDown
        player.y -= tileSize
        y += tileSize
      DirUp -> do
        player.direction .= DirRight
        player.x += tileSize
        x -= tileSize
      _ -> return ()
checkCurTile (IceTopRight _) = do
  gs <- get
  when (not $ _hasIceSkates gs || _godMode gs) $ do
    case gs ^. player.direction of
      DirRight -> do
        player.direction .= DirDown
        player.y -= tileSize
        y += tileSize
      DirUp -> do
        player.direction .= DirLeft
        player.x -= tileSize
        x += tileSize
      _ -> return ()
checkCurTile (IceBottomRight _) = do
  gs <- get
  when (not $ _hasIceSkates gs || _godMode gs) $ do
    case gs ^. player.direction of
      DirRight -> do
        player.direction .= DirUp
        player.y += tileSize
        y -= tileSize
      DirDown -> do
        player.direction .= DirLeft
        player.x -= tileSize
        x += tileSize
      _ -> return ()
checkCurTile (FFLeft _) = do
  gs <- get
  when (not $ _hasFFShoes gs || _godMode gs) $ do
    player.x -= tileSize
    x += tileSize
checkCurTile (FFRight _) = do
  gs <- get
  when (not $ _hasFFShoes gs || _godMode gs) $ do
    player.x += tileSize
    x -= tileSize
checkCurTile (FFUp _) = do
  gs <- get
  when (not $ _hasFFShoes gs || _godMode gs) $ do
    player.y += tileSize
    y -= tileSize
checkCurTile (FFDown _) = do
  gs <- get
  when (not $ _hasFFShoes gs || _godMode gs) $ do
    player.y -= tileSize
    y += tileSize
checkCurTile (FFShoes _) = do
  hasFFShoes .= True
  setTile Current (Empty def)
checkCurTile (FireBoots _) = do
  hasFireBoots .= True
  setTile Current (Empty def)
checkCurTile (Flippers _) = do
  hasFlippers .= True
  setTile Current (Empty def)
checkCurTile (IceSkates _) = do
  hasIceSkates .= True
  setTile Current (Empty def)
checkCurTile (Sand (Water _) _) = setTile Current (Empty def)
checkCurTile (Sand _ _) = do
  gs <- get
  case gs ^. player.direction of
    Standing -> error "standing on sand?"
    DirLeft  -> moveSand TileLeft
    DirRight -> moveSand TileRight
    DirUp    -> moveSand TileAbove
    DirDown  -> moveSand TileBelow
checkCurTile (ButtonGreen _) = do
  once $ do
    gs <- get
    forM_ (withIndices (gs ^. tiles)) $ \(tile, i) -> do
      case tile of
        ToggleDoor x _ -> setTile (Arbitrary i) (ToggleDoor (not x) def)
        _       -> return ()
checkCurTile (ButtonBlue _) = do
  once $ do
    gs <- get
    forM_ (withIndices (gs ^. tiles)) $ \(tile, i) -> do
      case tile of
        Tank dir tileUnder _ -> setTile (Arbitrary i) (Tank (opposite dir) tileUnder def)
        _       -> return ()
checkCurTile (ButtonRed _) = do
  once $ do
    gs <- get
    forM_ (withIndices (gs ^. tiles)) $ \(tile, i) -> do
      case tile of
        GeneratorFireball dir _ -> do
          let genAt loc = do
                let oldTile = (gs ^. tiles) !! loc
                setTile (Arbitrary loc) (Fireball dir oldTile def)
          case dir of
            DirLeft  -> genAt (i - 1)
            DirRight -> genAt (i + 1)
            DirUp    -> genAt (i - boardW)
            DirDown  -> genAt (i + boardW)
        _       -> return ()
    return ()

checkCurTile (ButtonBrown _) = do
  gs <- get
  forM_ (withIndices (gs ^. tiles)) $ \(tile, i) -> do
    case tile of
      Trap t _ ->
        case t of
          Rocket dir _ _ -> setTile (Arbitrary i) (Rocket dir (Trap (Empty def) def) def)
          _ -> return ()
      _ -> return ()
checkCurTile (Bee _ _ _) = die
checkCurTile (Frog _ _ _) = die
checkCurTile (Tank _ _ _) = die
checkCurTile (Worm _ _ _) = die
checkCurTile (Bomb _) = die
checkCurTile (BallPink _ _ _) = die
checkCurTile (Rocket _ _ _) = die
checkCurTile (Fireball _ _ _) = die
checkCurTile _ = return ()

-- moveSand :: Int -> GameState -> IO GameState
moveSand destPos = do
    destTile <- tilePosToTile destPos
    curTile <- tilePosToTile Current
    case curTile of
      Sand t _ -> do
        setTile Current t
        setTile destPos (Sand destTile def)
        player.standingOn .= t
        checkCurTile t
      _ -> error "current tile isn't a sand tile. How did you get here?"

once :: GameMonad () -> GameMonad ()
once action = do
    cur <- liftIO . readIORef $ curLocation
    prev <- liftIO . readIORef $ prevLocation
    when (cur /= prev) action
