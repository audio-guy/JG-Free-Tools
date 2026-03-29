-- JG_TrackHeight_Full.lua
-- Set all tracks to full visible track area height, scroll to selected track

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Measure arrange height and ruler offset first
local arrange = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
local _, _, arr_top, _, arr_bottom = reaper.JS_Window_GetClientRect(arrange)
local arrange_h = math.abs(arr_top - arr_bottom)

-- Need to set some height first, scroll to top, measure ruler
local num_tracks = reaper.CountTracks(0)
for i = 0, num_tracks - 1 do
  local track = reaper.GetTrack(0, i)
  reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 100)
end

reaper.TrackList_AdjustWindows(true)

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.JS_Window_SetScrollPos(arrange, "SB_VERT", 0)
reaper.UpdateArrange()
local ruler_offset = reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, 0), "I_TCPY")

-- Full track height = arrange height minus ruler
local full_h = math.floor(arrange_h - ruler_offset)
if full_h <= 0 then full_h = 800 end

reaper.PreventUIRefresh(1)

for i = 0, num_tracks - 1 do
  local track = reaper.GetTrack(0, i)
  reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", full_h)
end

reaper.TrackList_AdjustWindows(true)

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

-- Scroll to selected track
local sel_track = reaper.GetSelectedTrack(0, 0)
if sel_track then
  local sel_idx = math.floor(reaper.GetMediaTrackInfo_Value(sel_track, "IP_TRACKNUMBER") - 1)
  reaper.JS_Window_SetScrollPos(arrange, "SB_VERT", sel_idx * full_h)
  reaper.UpdateArrange()
end

-- Horizontal zoom: Razor Edit > Time Selection > Selected Item
local hz_start, hz_end

for i = 0, num_tracks - 1 do
  local track = reaper.GetTrack(0, i)
  local _, razor = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if razor ~= "" then
    for rs, re in razor:gmatch("([%d%.]+) ([%d%.]+)") do
      local s, e = tonumber(rs), tonumber(re)
      if s and e then
        if not hz_start or s < hz_start then hz_start = s end
        if not hz_end or e > hz_end then hz_end = e end
      end
    end
  end
end

if not hz_start then
  local ts_start, ts_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if ts_end > ts_start then
    hz_start = ts_start
    hz_end = ts_end
  end
end

if not hz_start then
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item then
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    hz_start = pos
    hz_end = pos + len
  end
end

if hz_start and hz_end then
  local dur = hz_end - hz_start
  reaper.GetSet_ArrangeView2(0, true, 0, 0, hz_start - dur * 0.05, hz_end + dur * 0.05)
end

reaper.Undo_EndBlock("Set all track heights to full arrange height", -1)
