local TITLE_GX, TITLE_GY = (SW - 30)/2, SH - 90
local SAV_FILE_NAME = "charlink.sav"

local idBkgnd = nil

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

function GenTimeModeIndicator(param)
  param.sandglasso = GenCharObj(-1, string.byte('/', 1) - 32)
  Good.SetBgColor(param.sandglasso, 0xffff0000)
  Good.SetPos(param.sandglasso, TITLE_GX, TITLE_GY - 20)
end

function SaveHiScore()
  local outf = io.open(SAV_FILE_NAME, "w")
  outf:write(HiScore)
  outf:close()
end

function LoadHiScore()
  local inf = io.open(SAV_FILE_NAME, "r")
  if (nil == inf) then
    HiScore = 0
  else
    HiScore = inf:read("*number")
    inf:close()
  end
end

Title = {}

Title.OnCreate = function(param)
  -- Mask tilemap.
  GenBkgndObj()
  -- Title.
  local TitlePos = {
    Char = 14,
    Link = 30,
    Push = 62,
    Start = 78
  }
  param.p = {}
  param.o = {}
  for key, value in pairs(TitlePos) do
    for i = 1, string.len(key) do
      GenBlock(param, value + i - 1, string.byte(key, i) - 32)
    end
  end
  -- Sand glass.
  local g = Good.GenObj(-1, 8)
  Good.SetPos(g, TITLE_GX, TITLE_GY)
  if (not TimeMode) then
    GenTimeModeIndicator(param)
  end
  -- Hi score.
  LoadHiScore()
  GenStrObj(-1, 0, 0, string.format('Hi-Score:%d', HiScore))
end

Title.OnStep = function(param)
  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local x, y = Input.GetMousePos()
    if (PtInRect(x, y, TITLE_GX - TILE_W/2, TITLE_GY - TILE_H/2, TITLE_GX + 2 * TILE_W, TITLE_GY + 2 * TILE_H)) then
      if (TimeMode) then
        TimeMode = false
        GenTimeModeIndicator(param)
      else
        TimeMode = true
        Good.KillObj(param.sandglasso)
      end
    else
      Good.GenObj(-1, 0)                  -- Start game level.
    end
  end
end
