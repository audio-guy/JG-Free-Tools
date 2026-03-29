-- @description Smart Insert Track (insert track or folder for selection)
-- @author JG
-- @version 1.0.0
-- @about
--   Inserts a new track like action 40001. If multiple tracks are selected,
--   offers to create a folder track containing the selected tracks instead.

function main()
    local sel_count = reaper.CountSelectedTracks(0)

    -- 0 or 1 track selected: just insert new track
    if sel_count <= 1 then
        reaper.Main_OnCommand(40001, 0) -- Insert new track
        return
    end

    -- Multiple tracks selected: ask about folder
    local ret = reaper.MB(
        "Create a folder track for the " .. sel_count .. " selected tracks?\n\n(Cancel = insert normal track)",
        "Smart Insert Track",
        1 -- OK / Cancel
    )

    -- Cancel (2) or closed (0): just insert new track
    if ret ~= 1 then
        reaper.Main_OnCommand(40001, 0)
        return
    end

    -- Create folder track for selected tracks
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    -- Find first and last selected track indices (0-based)
    local first_idx = math.huge
    local last_idx = -1

    for i = 0, sel_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local idx = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")) - 1
        if idx < first_idx then first_idx = idx end
        if idx > last_idx then last_idx = idx end
    end

    -- Insert new track above the first selected track
    reaper.InsertTrackAtIndex(first_idx, true)
    local folder_track = reaper.GetTrack(0, first_idx)

    -- Set as folder parent
    reaper.SetMediaTrackInfo_Value(folder_track, "I_FOLDERDEPTH", 1)

    -- Close folder on the last selected track (shifted by +1 due to insertion)
    local last_track = reaper.GetTrack(0, last_idx + 1)
    local cur_depth = reaper.GetMediaTrackInfo_Value(last_track, "I_FOLDERDEPTH")
    reaper.SetMediaTrackInfo_Value(last_track, "I_FOLDERDEPTH", cur_depth - 1)

    -- Select only the new folder track so user can rename it
    reaper.SetOnlyTrackSelected(folder_track)

    reaper.PreventUIRefresh(-1)
    reaper.TrackList_AdjustWindows(false)
    reaper.Undo_EndBlock("Smart Insert Track: Create folder", -1)
end

main()
