
math.randomseed(os.time())

SW, SH = Good.GetWindowSize()
local MAP_W, MAP_H = 12, 8
TILE_W, TILE_H = 45, 82
local TW, TH = 15, 7
local FONT_W, FONT_H = 16, 32
local INIT_BLOCK_COUNT = 12
local NEXT_BLOCK_COUNT = 10
local COUNT_DOWN_TIME = 7
local MAX_CARD = 60

local mx, my = (SW - MAP_W * TILE_W) / 2, (SH - MAP_H * TILE_H) / 2
local idTexRes = Resource.GetTexId('font')
local QuitGameClock
local ClearCount
local TimeModeClock
local TimeModeClockObj
TimeMode = true
HiScore = 0

local idBkgnd = nil

AnimSandGlass = {}

AnimSandGlass.OnStep = function(param)
  if (nil == param.k) then
    Good.SetAnchor(param._id, 0.5, 0.5)
    local loop1 = ArAddLoop(nil)
    ArAddMoveBy(loop1, 'Rot', 0.5, 360).ease = ArEaseOut
    ArAddCall(loop1, 'UpdateTimeClock', 0.5)
    param.k = ArAddAnimator({loop1})
    TimeModeClockObj = nil
  elseif (Game.OnStep ~= OnStepOver) then
    ArStepAnimator(param, param.k)
  end
end

function AcKillAnimObj(param)
  Good.KillObj(param._id)
end

AnimClearChar = {}

AnimClearChar.OnStep = function(param)
  if (nil == param.k) then
    local loop1 = ArAddLoop(nil)
    ArAddMoveTo(loop1, 'Alpha', 0.15, 0)
    ArAddCall(loop1, 'AcKillAnimObj', 0)
    param.k = ArAddAnimator({loop1})
  else
    ArStepAnimator(param, param.k)
  end
end

function UpdateTimeClock(param)
  if (nil ~= TimeModeClockObj) then
    Good.KillObj(TimeModeClockObj)
    TimeModeClockObj = nil
  end
  if (0 < TimeModeClock) then
    TimeModeClock = TimeModeClock - 60
    local s = math.floor(TimeModeClock / 60)
    if (0 < s) then
      TimeModeClockObj = GenCharObj(-1, string.byte(tostring(s), 1) - 32)
      Good.SetScale(TimeModeClockObj, 1, 1)
      Good.SetPos(TimeModeClockObj, (SW - 30)/2 + TILE_W, my + 4)
    end
  end
end

function GenBkgndObj()
  if (nil == idBkgnd) then
    GenBkgndTex()
  end
  local o = Good.GenObj(-1, idBkgnd)
  Good.SetPos(o, (SW - (MAP_W-2) * TILE_W) / 2, (SH - (MAP_H-2) * TILE_H) / 2)
end

function GenBkgndTex()
  local idCanvas = Graphics.GenCanvas((MAP_W-2) * TILE_W, (MAP_H-2) * TILE_H)
  local clr = {[true]=0x30ffffff, [false]=0x70ffffff}
  local clridx = true
  for i = 0, MAP_H - 1 do
    for j = 0, MAP_W - 1 do
      Graphics.FillRect(idCanvas, j * TILE_W, i * TILE_H, TILE_W, TILE_H, clr[clridx])
      clridx = not clridx
    end
    clridx = not clridx
  end
  idBkgnd = Resource.GenTex(idCanvas)
  Graphics.KillCanvas(idCanvas)
end

function GenCharObj(parent, p)
  local o = GenTexObj(parent, idTexRes, FONT_W, FONT_H, FONT_W * (p % TW), FONT_H * math.floor(p / TW))
  Good.SetScale(o, TILE_W/FONT_W, TILE_H/FONT_H)
  return o
end

function GenBlock(param, i, p)
  param.p[i] = p
  local o = GenCharObj(param._id, p)
  local c1 = i % MAP_W
  local r1 = math.floor(i / MAP_W)
  Good.SetPos(o, mx + c1 * TILE_W, my + r1 * TILE_H)
  param.o[i] = o
end

function GenRandBlock(param, p)
  for try = 1, 256 do
    local i = math.random(MAP_W * MAP_H) - 1
    local c1 = i % MAP_W
    local r1 = math.floor(i / MAP_W)
    if (0 ~= c1 and 0 ~= r1 and MAP_W - 1 ~= c1 and MAP_H - 1 ~= r1 and -1 == param.p[i]) then
      GenBlock(param, i, p)
      return true
    end
  end
  return false
end

function UpdateScore(param, add)
  if (nil == param.score) then
    param.score = 0
  end
  param.score = param.score + add
  if (param.score > HiScore) then
    HiScore = param.score
    SaveHiScore()
    Stge.RunScript('fx_hit', math.floor(9.5 * FONT_W), FONT_H, 0)
  end
  local slv = string.format('Hi-Score:%d Score:%d', HiScore, param.score)
  if (nil ~= param.scoreo) then
    Good.KillObj(param.scoreo)
  end
  param.scoreo = GenStrObj(-1, 0, 0, slv)
end

function InitBlockCount()
  local c = INIT_BLOCK_COUNT
  if (TimeMode) then
    c = c + 10
  end
  return c
end

function InitPuzzle(param, idMapRes)
  local i = 0
  for y = 0, MAP_H - 1 do
    for x = 0, MAP_W - 1 do
      param.p[i] = -1
      param.o[i] = nil
      i = i + 1
    end
  end

  param.c = InitBlockCount()
  if (1 == (param.c % 2)) then
    Good.Trace('Tile mask should be times of 2!')
    return
  end

  for i = 1, param.c/2 do
    local p = math.random(MAX_CARD)
    for j = 1, 2 do
      GenRandBlock(param, p)
    end
  end

  QuitGameClock = 0
  ClearCount = 0
  TimeModeClock = COUNT_DOWN_TIME * 60
end

Game = {}

Game.OnCreate = function(param)

  -- Init level state.

  param.p = {}                          -- The game state.
  param.o = {}                          -- The tile objects.

  param.timer = 0
  param.link = {}

  param.c = 0                           -- Total cards need to clear.
  param.p1 = -1
  param.p2 = -1

  param.level = Good.GetLevelId(param._id)

  -- Init puzzle

  GenBkgndObj()

  if (TimeMode) then
    local g = Good.GenObj(-1, 8, 'AnimSandGlass')
    Good.SetPos(g, (SW - 30)/2, my)
  end

  InitPuzzle(param, mid)
  UpdateScore(param, 0)

  -- Gen selection mask.

  local o = GenColorObj(param._id, TILE_W, TILE_H, 0xaaff0000)
  Good.SetPos(o, mx, my)
  Good.SetVisible(o, 0)
  param.s = o
end

function isFlowVert(p, p1, p2, c, r1, r2)

  if (r1 == r2) then
    return true
  end

  if (r1 > r2) then
    local tmp = r1
    r1 = r2
    r2 = tmp
  end

  local r
  for r = r1, r2 do
    local idx = c + r * MAP_W
    if (-1 ~= p[idx] and idx ~= p1 and idx ~= p2) then
      return false
    end
  end

  return true
end

function isFlowHorz(p, p1, p2, r, c1, c2)
  if (c1 == c2) then
    return true
  end

  if (c1 > c2) then
    local tmp = c1
    c1 = c2
    c2 = tmp
  end

  local c
  for c = c1, c2 do
    local idx = c + r * MAP_W
    if (-1 ~= p[idx] and idx ~= p1 and idx ~= p2) then
      return false
    end
  end

  return true
end

function CheckLink(p, p1, p2)
  if (-1 == p2) then
    return false
  end

  local c1 = p1 % MAP_W
  local r1 = math.floor(p1 / MAP_W)
  local c2 = p2 % MAP_W
  local r2 = math.floor(p2 / MAP_W)
  local link = {}

  -- Parallel row condition.

  local ShortPath = nil
  local r
  for r = 0, MAP_H - 1 do
    if (isFlowVert(p, p1, p2, c1, r1, r) and
        isFlowVert(p, p1, p2, c2, r, r2) and
        isFlowHorz(p, p1, p2, r, c1, c2)) then
      local path = math.abs(c1 - c2) + math.abs(r1 - r) + math.abs(r - r2)
      if (nil == ShortPath or path < ShortPath) then
        link[0] = p1
        link[1] = c1 + MAP_W * r
        link[2] = c2 + MAP_W * r
        link[3] = p2
        ShortPath = path
      end
    end
  end

  -- Parallel column condition.

  local c
  for c = 0, MAP_W - 1 do
    if (isFlowHorz(p, p1, p2, r1, c1, c) and
        isFlowHorz(p, p1, p2, r2, c, c2) and
        isFlowVert(p, p1, p2, c, r1, r2)) then
      local path = math.abs(r1 - r2) + math.abs(c1 - c) + math.abs(c - c2)
      if (nil == ShortPath or path < ShortPath) then
        link[0] = p1
        link[1] = c + MAP_W * r1
        link[2] = c + MAP_W * r2
        link[3] = p2
        ShortPath = path
      end
    end
  end

  if (nil ~= ShortPath) then
    return link
  else
    return nil
  end
end

function GenLinkObj(p1, p2)
  if (p1 == p2) then
    return -1
  end
  local c1 = p1 % MAP_W
  local r1 = math.floor(p1 / MAP_W)
  local c2 = p2 % MAP_W
  local r2 = math.floor(p2 / MAP_W)
  local c, r = c1, r1
  local o
  if (c1 == c2) then
    o = GenColorObj(-1, 1, TILE_H * math.abs(r1 - r2), 0xffff0000)
    if (r1 > r2) then
      r = r2
    end
  else
    o = GenColorObj(-1, TILE_W * math.abs(c1 - c2), 1, 0xffff0000)
    if (c1 > c2) then
      c = c2
    end
  end
  local x = mx + TILE_W * c + TILE_W/2
  local y = my + TILE_H * r + TILE_H/2
  if (0 == c) then
    x = x + TILE_W/4
  elseif (MAP_W - 1 == c) then
    x = x - TILE_W/4
  end
  if (0 == r) then
    y = y + TILE_H/4
  elseif (MAP_W - 1 == r) then
    y = y - TILE_H/4
  end
  Good.SetPos(o, x, y)
  return o
end

function FindLink(p)
  for i = 0, MAP_H * MAP_W - 2 do
    if (-1 ~= p[i]) then
      for j = i + 1, MAP_H * MAP_W - 1 do
        if (p[i] == p[j]) then
          local link = CheckLink(p, i, j)
          if (nil ~= link) then
            link[4] = i
            link[5] = j
            return link
          end
        end
      end
    end
  end
  return nil
end

function AddNewLink(param, link)
  param.link = link
  param.timer = 10
  Game.OnStep = OnStepClearLink

  param.ol = {}
  if (param.link[1] ~= param.link[2]) then
    param.ol[0] = GenLinkObj(param.link[0], param.link[1])
    param.ol[1] = GenLinkObj(param.link[1], param.link[2])
    param.ol[2] = GenLinkObj(param.link[2], param.link[3])
  else
    param.ol[0] = GenLinkObj(param.link[0], param.link[3])
  end
end

function GenCenterStrObj(y, msg)
  return GenStrObj(-1, (SW - 16 * string.len(msg)) / 2, y, msg)
end

function GameOver(param, msg)
  if (nil ~= param.quitmsg) then
    Good.KillObj(param.quitmsg)
    param.quitmsg = nil
  end
  local mask = GenColorObj(-1, MAP_W * TILE_W, MAP_H * TILE_H, 0xaa000000)
  Good.SetPos(mask, mx, my)
  GenCenterStrObj(SH - FONT_H, msg)
  GenCenterStrObj(SH - 82, '[OK]')
  Game.OnStep = OnStepOver
end

function OnStepOver(param)
  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local x, y = Input.GetMousePos()
    if (PtInRect(x, y, 0, SH - 120, SW, SH)) then
      Good.GenObj(-1, 4)                -- Back to title level.
      Game.OnStep = OnStepDefault
    end
  end
end

function CheckGenNewBlock(param)
  ClearCount = ClearCount + 1
  if ((TimeMode and 0 >= TimeModeClock) or (not TimeMode and 3 == ClearCount)) then
    if ((MAP_W - 2) * (MAP_H - 2) - param.c >= 10) then
      local n = NEXT_BLOCK_COUNT/2
      if (0 >= param.c) then
        n = InitBlockCount() / 2
      end
      for i = 1, n do
        local p = math.random(MAX_CARD)
        if (GenRandBlock(param, p) and GenRandBlock(param, p)) then
          param.c = param.c + 2
        end
      end
    else
      GameOver(param, 'Game over! No more space')
      return
    end
    ClearCount = 0
    TimeModeClock = COUNT_DOWN_TIME * 60
  end
end

function OnStepClearLink(param)
  if (0 < param.timer) then
    param.timer = param.timer - 1
    if (0 == param.timer) then
      Good.SetScript(param.o[param.p1], 'AnimClearChar')
      Good.SetScript(param.o[param.p2], 'AnimClearChar')
      for i = 0,2 do
        if (nil ~= param.ol[i]) then
          Good.KillObj(param.ol[i])
        end
      end
      param.p[param.p1] = -1
      param.p[param.p2] = -1
      param.p1 = -1
      param.p2 = -1
      param.link = {}
      param.c = param.c - 2
      Good.SetVisible(param.s, 0)

      UpdateScore(param, 2)

      -- Gen new block.

      if (not TimeMode) then
        CheckGenNewBlock(param)
      end

      -- Game over?

      if (0 < param.c and nil == FindLink(param.p)) then
        GameOver(param, 'Game over! No more move')
        return
      end
    end
  else
    Game.OnStep = OnStepDefault
  end
end

function OnStepDefault(param)

  -- Test

  if (Input.IsKeyPushed(Input.BTN_A)) then
    local link = FindLink(param.p)
    if (nil ~= link) then
      param.p1 = link[4]
      param.p2 = link[5]
      AddNewLink(param, link)
      return
    end
  end

  -- Check quit.

  QuitGameClock = QuitGameClock + 1
  if (120 < QuitGameClock and nil ~= param.quitmsg) then
    Good.KillObj(param.quitmsg)
    param.quitmsg = nil
  end

  if (Input.IsKeyPressed(Input.ESCAPE)) then
    if (120 > QuitGameClock and nil ~= param.quitmsg) then
      Good.GenObj(-1, 4)                -- Back to title.
      return
    elseif (nil == param.quitmsg) then
      param.quitmsg = GenCenterStrObj(SH - FONT_H, 'Press again to quit')
      QuitGameClock = 0
    end
  end

  -- Handle mouse down.

  if (Input.IsKeyPushed(Input.LBUTTON)) then

    -- Is mouse click in the puzzle?

    local x, y = Input.GetMousePos()
    if (nil ~= param.cur) then
      Good.KillObj(param.cur)
      param.cur = nil
    end

    if (not PtInRect(x, y, mx, my, mx + TILE_W * MAP_W, my + TILE_H * MAP_H)) then
      return
    end

    -- Check click tile.

    local c = math.floor((x - mx) / TILE_W)
    local r = math.floor((y - my) / TILE_H)
    local pi = c + r * MAP_W
    if (-1 == param.p[pi]) then
      return
    end

    -- Check and update first and second selection tile.

    if (param.p1 == pi) then
      return
    elseif (-1 == param.p1) then
      param.p1 = pi
      Good.SetPos(param.s, mx + TILE_W * c, my + TILE_H * r)
      Good.SetVisible(param.s, 1)
    elseif (-1 == param.p2) then
      if (param.p[param.p1] == param.p[pi]) then
        param.p2 = pi
      else
        param.p1 = pi
        Good.SetPos(param.s, mx + TILE_W * c, my + TILE_H * r)
        Good.SetVisible(param.s, 1)
      end
    end

    if (-1 == param.p1 or -1 == param.p2) then
      return
    end

    -- Check link.

    local link = CheckLink(param.p, param.p1, param.p2)
    if (nil == link) then
      param.p1 = pi
      param.p2 = -1
      Good.SetPos(param.s, mx + TILE_W * c, my + TILE_H * r)
      Good.SetVisible(param.s, 1)
      return
    end

    AddNewLink(param, link)
  end

  -- TimeMode check.

  if (TimeMode) then
    CheckGenNewBlock(param)
  end
end

Game.OnNewParticle = function(param, particle)
  local o = GenColorObj(-1, 2, 2, 0xffffffff)
  Stge.BindParticle(particle, o)
end

Game.OnKillParticle = function(param, particle)
  Good.KillObj(Stge.GetParticleBind(particle))
end

Game.OnStep = OnStepDefault
