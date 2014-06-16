{-# LANGUAGE TemplateHaskell, NoMonomorphismRestriction #-}
module Chips.Types where
import Chips.Imports

data Direction = DirUp | DirDown | DirLeft | DirRight | Standing deriving (Show, Eq)
opposite DirUp = DirDown
opposite DirDown = DirUp
opposite DirLeft = DirRight
opposite DirRight = DirLeft

data TilePos = Current | TileAbove | TileBelow | TileLeft | TileRight | Ix Int | Coords (Int, Int) deriving (Show, Eq)

data Tile = Empty Attributes
          | Wall  Attributes
          | Chip  Attributes
          | KeyYellow Attributes
          | KeyRed Attributes
          | KeyGreen Attributes
          | KeyBlue Attributes
          | LockYellow Attributes
          | LockRed Attributes
          | LockGreen Attributes
          | LockBlue Attributes
          | Gate Attributes
          | GateFinal Attributes
          | Help Attributes
          | Amoeba Attributes
          | Bee { _beeDirection :: Direction, _tileUnderBee :: Tile, _beeAttrs :: Attributes }
          | Bomb Attributes
          | FFDown Attributes
          | FFLeft Attributes
          | FFRight Attributes
          | FFUp Attributes
          | FFRandom Attributes
          | FFShoes Attributes
          | FireBoots Attributes
          | Fire Attributes
          | Flippers Attributes
          | Frog { _frogDirection :: Direction, _tileUnderFrog :: Tile, _frogAttrs :: Attributes }
          | IceBottomLeft Attributes
          | IceBottomRight Attributes
          | IceSkates Attributes
          | IceTopLeft Attributes
          | IceTopRight Attributes
          | Ice Attributes
          | Sand { _tileUnderSand :: Tile, _sandAttrs :: Attributes }
          | Spy Attributes
          | Tank { _tankDirection :: Direction, _tileUnderTank :: Tile, _tankAttrs :: Attributes }
          | WaterSplash Attributes
          | Water Attributes
          | Worm { _wormDirection :: Direction, _tileUnderWorm :: Tile, _wormAttrs :: Attributes }
          | ButtonBlue Attributes
          | ButtonBrown { _trapLocation :: TilePos, _bbAttrs :: Attributes }
          | ButtonRed Attributes
          | ButtonGreen Attributes
          | ToggleDoor { _open :: Bool, _tdAttrs :: Attributes }
          | Trap { _inTrap :: Tile, _tdAttrs :: Attributes }
          | BallPink { _ballDirection :: Direction, _tileUnderBall :: Tile, _tdAttrs :: Attributes }
          | Rocket   { _rocketDirection :: Direction, _tileUnderRocket :: Tile, _tdAttrs :: Attributes }
          | Fireball { _fireballDirection :: Direction, _tileUnderFireball :: Tile, _tdAttrs :: Attributes }
          | GeneratorFireball { _generatorDir :: Direction, _gfAttrs :: Attributes }
          | InvisibleWall { _showOnTouch :: Bool, _hwAttrs :: Attributes }
          | BlueWall { _real :: Bool, _blueWallAttrs :: Attributes }
          | Gravel Attributes
          | FakeChip Attributes
          | Teleporter { _upDest :: TilePos, _downDest :: TilePos, _leftDest :: TilePos, _rightDest :: TilePos, _teleAttrs :: Attributes }
          | RecessedWall Attributes
          | ThinWall { _dir :: Direction, _thinWallAttrs :: Attributes }
          | Dirt Attributes
          | PlayerInTrap Attributes
          deriving (Show, Eq)

getTileUnder :: Tile -> Tile
getTileUnder tile = 
  case tile of
    Tank _ t _ -> t
    Bee _ t _ -> t
    Frog _ t _ -> t
    Sand t _ -> t
    Worm _ t _ -> t
    BallPink _ t _ -> t
    Rocket _ t _ -> t
    Fireball _ t _ -> t
    Trap t _ -> t
    _ -> Empty def

setTileUnder :: Tile -> Tile -> Tile
setTileUnder tile under = 
  case tile of
    Tank d t a -> Tank d under a
    Bee d t a -> Bee d under a
    Frog d t a -> Frog d under a
    Sand t a -> Sand under a
    Worm d t a -> Worm d under a
    BallPink d t a -> BallPink d under a
    Rocket d t a -> Rocket d under a
    Fireball d t a -> Fireball d under a
    Trap _ a -> Trap under a
    x -> x

tileUnder = lens getTileUnder setTileUnder

getDirection :: Tile -> Maybe Direction
getDirection tile = 
  case tile of
    Tank d _ _ -> Just d
    Bee d _ _ -> Just d
    Frog d _ _ -> Just d
    Worm d _ _ -> Just d
    BallPink d _ _ -> Just d
    Rocket d _ _ -> Just d
    Fireball d _ _ -> Just d
    GeneratorFireball d _ -> Just d
    ThinWall d _ -> Just d
    _ -> Nothing

setDirection :: Tile -> Direction -> Tile
setDirection tile d =
  case tile of
    Tank _ t a -> Tank d t a
    Bee _ t a -> Bee d t a
    Frog _ t a -> Frog d t a
    Worm _ t a -> Worm d t a
    BallPink _ t a -> BallPink d t a
    Rocket _ t a -> Rocket d t a
    Fireball _ t a -> Fireball d t a
    GeneratorFireball _ a -> GeneratorFireball d a
    ThinWall _ a -> ThinWall d a
    x -> x

dir = lens getDirection setDirection

deriveMC ''Tile

instance Renderable Tile where
    render (Empty _)            = image "images/empty.png"
    render (Wall _)             = image "images/wall.png"
    render (Chip _)             = image "images/chip.png"
    render (KeyYellow _)        = image "images/key_yellow.png"
    render (KeyRed _)           = image "images/key_red.png"
    render (KeyGreen _)         = image "images/key_green.png"
    render (KeyBlue _)          = image "images/key_blue.png"
    render (LockYellow _)       = image "images/lock_yellow.png"
    render (LockRed _)          = image "images/lock_red.png"
    render (LockGreen _)        = image "images/lock_green.png"
    render (LockBlue _)         = image "images/lock_blue.png"
    render (Gate _)             = image "images/gate.png"
    render (GateFinal _)        = image "images/gate_final1.png"
    render (Help _)             = image "images/help.png"
    render (Amoeba _)           = image "images/amoeba.png"
    render (Bee DirUp _ _)        = image "images/bee_up.png"
    render (Bee DirDown _ _)      = image "images/bee_down.png"
    render (Bee DirLeft _ _)      = image "images/bee_left.png"
    render (Bee DirRight _ _)     = image "images/bee_right.png"
    render (Bomb _)             = image "images/bomb.png"
    render (FFDown _)           = image "images/ff_down.png"
    render (FFLeft _)           = image "images/ff_left.png"
    render (FFRight _)          = image "images/ff_right.png"
    render (FFUp _)             = image "images/ff_up.png"
    render (FFRandom _)         = image "images/ff_random.png"
    render (FFShoes _)          = image "images/ff_shoes.png"
    render (FireBoots _)        = image "images/fire_boots.png"
    render (Fire _)             = image "images/fire.png"
    render (Flippers _)         = image "images/flippers.png"
    render (Frog DirUp _ _)       = image "images/frog_up.png"
    render (Frog DirDown _ _)     = image "images/frog_down.png"
    render (Frog DirLeft _ _)     = image "images/frog_left.png"
    render (Frog DirRight _ _)    = image "images/frog_right.png"
    render (IceBottomLeft _)    = image "images/ice_bottom_left.png"
    render (IceBottomRight _)   = image "images/ice_bottom_right.png"
    render (IceSkates _)        = image "images/ice_skates.png"
    render (IceTopLeft _)       = image "images/ice_top_left.png"
    render (IceTopRight _)      = image "images/ice_top_right.png"
    render (Ice _)              = image "images/ice.png"
    render (Sand _ _)           = image "images/sand.png"
    render (Spy _)              = image "images/spy.png"
    render (Tank DirUp _ _)       = image "images/tank_up.png"
    render (Tank DirDown _ _)     = image "images/tank_down.png"
    render (Tank DirLeft _ _)     = image "images/tank_left.png"
    render (Tank DirRight _ _)    = image "images/tank_right.png"
    render (WaterSplash _)      = image "images/water_splash.png"
    render (Water _)            = image "images/water.png"
    render (Worm DirUp _ _)       = image "images/worm_up.png"
    render (Worm DirDown _ _)     = image "images/worm_down.png"
    render (Worm DirLeft _ _)     = image "images/worm_left.png"
    render (Worm DirRight _ _)    = image "images/worm_right.png"
    render (ButtonBlue _)       = image "images/button_blue.png"
    render (ButtonBrown _ _)      = image "images/button_brown.png"
    render (ButtonRed _)        = image "images/button_red.png"
    render (ButtonGreen _)      = image "images/button_green.png"
    render (ToggleDoor True _)  = image "images/toggle_door_open.png"
    render (ToggleDoor False _) = image "images/toggle_door_closed.png"
    render (Trap tile _)        =
      case tile of
        Empty _ -> image "images/trap.png"
        _ -> render tile
    render (BallPink _ _ _)       = image "images/ball_pink.png"
    render (Rocket DirUp _ _)     = image "images/rocket_up.png"
    render (Rocket DirDown _ _)   = image "images/rocket_down.png"
    render (Rocket DirLeft _ _)   = image "images/rocket_left.png"
    render (Rocket DirRight _ _)  = image "images/rocket_right.png"
    render (Fireball _ _ _)       = image "images/fireball.png"
    render (GeneratorFireball _ _) = image "images/generator_fireball.png"
    render (InvisibleWall _ _)    = image "images/empty.png"
    render (BlueWall _ _)         = image "images/blue_wall.png"
    render (Gravel _)             = image "images/gravel.png"
    render (FakeChip _)           = image "images/chip.png"
    render (Teleporter _ _ _ _ _) = image "images/teleporter.png"
    render (RecessedWall _)       = image "images/recessed_wall.png"
    render (ThinWall dir _)       =
      case dir of
        DirUp -> image "images/thin_wall_up.png"
        DirDown -> image "images/thin_wall_down.png"
        DirLeft -> image "images/thin_wall_left.png"
        DirRight -> image "images/thin_wall_right.png"
        Standing -> error "theres no such thing as a 'standing' thin wall"
    render (Dirt _)               = image "images/dirt.png"
    render (PlayerInTrap _)       = image "images/trap.png"
    
data Player = Player {
                _direction :: Direction,
                _standingOn :: Tile,
                _ar :: Attributes
} deriving Show

makeLenses ''Player
deriveMC ''Player

instance Renderable Player where
    render p = case p ^. standingOn of
                 Water _          -> image $ "images/player_swim_" ++ dir ++ ".png"
                 Ice _            -> image $ "images/player_ice_" ++ dir ++ ".png"
                 IceTopLeft _     -> image $ "images/player_ice_top_left_" ++ dir ++ ".png"
                 IceTopRight _    -> image $ "images/player_ice_top_right_" ++ dir ++ ".png"
                 IceBottomLeft _  -> image $ "images/player_ice_bottom_left_" ++ dir ++ ".png"
                 IceBottomRight _ -> image $ "images/player_ice_bottom_right_" ++ dir ++ ".png"
                 FFLeft _         -> image $ "images/player_ff_left_" ++ dir ++ ".png"
                 FFRight _        -> image $ "images/player_ff_right_" ++ dir ++ ".png"
                 FFUp _           -> image $ "images/player_ff_up_" ++ dir ++ ".png"
                 FFDown _         -> image $ "images/player_ff_down_" ++ dir ++ ".png"
                 Fire _           -> image $ "images/player_fire_" ++ dir ++ ".png"
                 Gravel _         -> image $ "images/player_gravel_" ++ dir ++ ".png"
                 _                -> image $ "images/player_" ++ dir ++ ".png"
          where dir = case p ^. direction of
                        DirUp -> "up"
                        DirDown -> "down"
                        DirLeft -> "left"
                        DirRight -> "right"
                        Standing -> "down"

data GameState = GameState {
                    _tiles :: [Tile],
                    _player :: Player,
                    _level :: Int,
                    _redKeyCount :: Int,
                    _blueKeyCount :: Int,
                    _yellowKeyCount :: Int,
                    _hasGreenKey :: Bool,
                    _hasFFShoes :: Bool,
                    _hasFireBoots :: Bool,
                    _hasFlippers :: Bool,
                    _hasIceSkates :: Bool,
                    _godMode :: Bool,
                    _disableInput :: Bool,
                    _tick :: (Bool, Int),
                    _ga :: Attributes
               }

makeLenses ''GameState
deriveMC ''GameState

instance Renderable GameState where
    -- render (LevelComplete _ _) = translate 0 200 $ scale 0.1 0.1 $ text "Level Complete! Press space to go onward!"
    render gs = displayAll (_tiles gs) <> display (_player gs) <> godMode_
      where godMode_ = case gs ^. godMode of
                         True -> translate (0 - gs ^. x) (0 - gs ^. y) $ scale 0.1 0.1 $ color red $ text "god mode"
                         False -> blank

type GameMonad a = StateT GameState IO a
