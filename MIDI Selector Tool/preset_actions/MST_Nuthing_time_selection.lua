local name = 'Nuthing'
-- @noindex
local path = ""


--Load UI Library
function reaperDoFile(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaperDoFile('../libs/gui.lua')
reaperDoFile('../libs/cf.lua')

----------------------------------
--Window Mngmt & Settings --------
----------------------------------
--Get current midi window so it can refocus on it when script terminates
local lastWindow = reaper.JS_Window_GetFocus()

--Load settings
local function update_settings(path, filename)
	beatPresets = {}
	dockOnStart, floatAtPos, floatAtPosX, floatAtPosY, floatAtMouse, floatAtMouseX, floatAtMouseY = get_settings(path, filename, beatPresets) 
	if dockOnStart == "1" then dockOnStart = true
	elseif floatAtPos == "1" then 
		floatAtPos = true
		floatAtMouse = false
		dockOnStart = false
		window_xPos = floatAtPosX
		window_yPos = floatAtPosY
	elseif floatAtMouse == "1" then 
		floatAtMouse = true
		floatAtPos = false
		dockOnStart = false
		local mouse_x, mouse_y = reaper.GetMousePosition()
		window_xPos = mouse_x + floatAtMouseX
		window_yPos = mouse_y + floatAtMouseY
	end
end
update_settings(path, '../lament.config')


local presets = get_presets('../' .. path) 



-------------------------------
--Midi Note and BeatsThangs---
-------------------------------
note_midi_n = {0,1,2,3,4,5,6,7,8,9,10,11}			--Covers all 12 notes (pitch%12)
note_names 	= {'C','C#', 'D', 'D#', 'E',				--Note names for notes_list
				'F','F#', 'G', 'G#', 'A', 
				'A#','B'}

local scaleName = {"Major", "Minor", "Harmonic Minor", "Melodic Minor", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Locrian", "Phrygian Dominant", "Major Pentatonic", "Minor Pentatonic", "Blues"}
local scales = {}
scales[1] 	= {1,0,1,0,1,1,0,1,0,1,0,1}
scales[2] 	= {1,0,1,1,0,1,0,1,1,0,1,0}
scales[3] 	= {1,0,1,1,0,1,0,1,1,0,0,1}
scales[4] 	= {1,0,1,1,0,1,0,1,0,1,0,1}
scales[5] 	= {1,0,1,1,0,1,0,1,0,1,1,0}
scales[6] 	= {1,1,0,1,0,1,0,1,1,0,1,0}
scales[7] 	= {1,0,1,0,1,0,1,1,0,1,0,1}
scales[8] 	= {1,0,1,0,1,1,0,1,0,1,0,1}
scales[9] 	= {1,1,0,1,0,1,1,0,1,0,1,0}
scales[10] 	= {1,1,0,0,1,1,0,1,1,0,1,0}
scales[11] 	= {1,0,1,0,1,0,0,1,0,1,0,0}
scales[12] 	= {1,0,0,1,0,1,0,1,0,0,1,0}
scales[13] 	= {1,0,0,1,0,1,1,1,0,0,1,0}

lengths_in_ppq 	= {3840, 1920, 960, 480, 240, 120, 60, -1}
lengths_in_ppq_triplets = {7680/3, 3840/3, 1920/3, 960/3, 480/3, 240/3, 120/3, 60/3, -1}
lengths_txt 	= {"1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "T"}
lengths 		= {0,0,0,0,0,0,0,0,0}

function default_vars()
	selectedNotes 	= {1,1,1,1,1,1,1,1,1,1,1,1}
	beats 			= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}	
end

default_vars()

local wait = 0

--PPQ values for 16th notes
beats_in_ppq = {0,240,480,720,960,1200,1440,1680,1920,2160,2400,2640,2880,3120,3360,3600}
beats_as_ppq = {}



----------------------
--MAIN PROGRAM--------
----------------------
reaper.Undo_BeginBlock()

----------------------
--Create Elements-----
----------------------


--General Frame
local frm_general = Frame:Create(10, 12, 227, 90, "GENERAL       ")

local btn_select = Button:Create(frm_general.x+10, frm_general.y+30, "Select", htSelect, 64)
local btn_capture = Button:Create(btn_select.x + btn_select.w + 7, btn_select.y, "Capture", htCapture, btn_select.w)
local btn_clear = Button:Create(btn_capture.x + btn_capture.w+7, btn_select.y, "Clear", htClear, btn_capture.w)

btn_select.hide = true
btn_clear.hide = true
btn_capture.hide = true

local tgl_dockOnStart = Toggle:Create(frm_general.x +10, frm_general.y + 25, "", htDockOnStart, dockOnStart, 10, 10)
local txt_dockOnStart = Text:Create(tgl_dockOnStart.x+20, tgl_dockOnStart.y, "Dock on start", htDockOnStart)

local tgl_floatAtPos = Toggle:Create(frm_general.x +10, frm_general.y + 42, "", htFloatAtPos, floatAtPos, 10, 10)
local txt_floatAtPos = Text:Create(tgl_floatAtPos.x+20, tgl_floatAtPos.y, "Float at pos: ", htFloatAtPos)
local ib_floatAtPosX = InputBox:Create(frm_general.w-74, txt_floatAtPos.y-2, tonumber(floatAtPosX), htFloatAtPos,34, 17)
local ib_floatAtPosY = InputBox:Create(frm_general.w-34, txt_floatAtPos.y-2, tonumber(floatAtPosY), htFloatAtPos,34, 17)

local tgl_floatAtMouse = Toggle:Create(frm_general.x +10, frm_general.y + 59, "", htFloatAtMouse, floatAtMouse, 10, 10)
local txt_floatAtMouse = Text:Create(tgl_floatAtMouse.x+20, tgl_floatAtMouse.y, "Float at mouse: ", htFloatAtMouse)
local ib_floatAtMouseX = InputBox:Create(frm_general.w-74, txt_floatAtMouse.y-2, tonumber(floatAtMouseX), htFloatAtMouse, 34, 17)
local ib_floatAtMouseY = InputBox:Create(frm_general.w-34, txt_floatAtMouse.y-2, tonumber(floatAtMouseY), htFloatAtMouse, 34, 17)

local btn_save = Button:Create(frm_general.x+12, frm_general.h+frm_general.y-10, "Save", htSaveSettings, frm_general.w-20, 20)


--Pitch frame
local frm_pitch = Frame:Create(10, frm_general.y + frm_general.h + 27, 227, 120, "PITCH")

local ib_maxNote = InputBox:Create(frm_pitch.x + 10, frm_pitch.y + 41, "G10", htMaxNote)
local ib_minNote = InputBox:Create(frm_pitch.x + 10, frm_pitch.y + 70, "C0", htMinNote, ib_maxNote.w)
group_noteRange ={ib_minNote, ib_maxNote}

local lbl_minNote = Text:Create(ib_minNote.x+4, ib_minNote.y + 24, "MIN")
local lbl_maxNote = Text:Create(ib_maxNote.x+4, ib_maxNote.y -13, "MAX")



local tgl_pitch = {}
local pitchTglOffset = frm_pitch.x+42
group_pitchToggles = {}

for pe = 1, 6 do
	 tgl_pitch[pe] = Toggle:Create(frm_pitch.x + pitchTglOffset, frm_pitch.y+41, note_names[pe], htPitchTgl, true, 25, nil)
	 pitchTglOffset = pitchTglOffset + 28
	 table.insert(group_pitchToggles, tgl_pitch[pe])
end

pitchTglOffset = frm_pitch.x+42
for pe = 7, 12 do
	 tgl_pitch[pe] = Toggle:Create(frm_pitch.x + pitchTglOffset, frm_pitch.y+67, note_names[pe], htPitchTgl, true, 25, nil)
	 pitchTglOffset = pitchTglOffset + 28
	 table.insert(group_pitchToggles, tgl_pitch[pe])
end




--Velocity Frame
local frm_velocity = Frame:Create(10, frm_pitch.y + frm_pitch.h + 27, 227,90, "VELOCITY")

local sldr_minVel = H_slider:Create(frm_velocity.x + 10, frm_velocity.y + 30, frm_velocity.w - 20, nil,"Min Velocity", htVelSlider, 0, 127, 0, false)
local sldr_maxVel = H_slider:Create(sldr_minVel.x, sldr_minVel.y + sldr_minVel.h + 10, sldr_minVel.w, nil,  "Max Velocity", htVelSlider, 0, 127, 127, true)
group_velSliders = {sldr_minVel, sldr_maxVel}



--Beats fFrame
local frm_time = Frame:Create(10, frm_velocity.y + frm_velocity.h + 27, 227, 162, "TIME")


local tgl_beats = {}
local beatsTglOffset = frm_time.x+97
group_beatsToggles = {}

for be = 1, 4 do
	 tgl_beats[be] = Toggle:Create(frm_time.x + beatsTglOffset, frm_time.y+30, be, htbeatsTgl,false, 25)
	 beatsTglOffset = beatsTglOffset + 28
	 table.insert(group_beatsToggles, tgl_beats[be])
	 beats[be] = 0
end

beatsTglOffset = frm_time.x+97
for be = 5, 8 do
	 tgl_beats[be] = Toggle:Create(frm_time.x + beatsTglOffset, frm_time.y+56, be, htbeatsTgl, false, 25)
	 beatsTglOffset = beatsTglOffset + 28
	 table.insert(group_beatsToggles, tgl_beats[be])
	 beats[be] = 0
end

beatsTglOffset = frm_time.x+97
for be = 9, 12 do
	 tgl_beats[be] = Toggle:Create(frm_time.x + beatsTglOffset, frm_time.y+82, be, htbeatsTgl, false, 25)
	 beatsTglOffset = beatsTglOffset + 28
	 table.insert(group_beatsToggles, tgl_beats[be])
	 beats[be] = 0
end

beatsTglOffset = frm_time.x+97

for be = 13, 16 do
	 tgl_beats[be] = Toggle:Create(frm_time.x + beatsTglOffset, frm_time.y+108, be, htbeatsTgl,false, 25)
	 beatsTglOffset = beatsTglOffset + 28
	 table.insert(group_beatsToggles, tgl_beats[be])
	 beats[be] = 0
end

local tgl_length = {}
local lengthTglOffset = frm_time.y + 30
group_lengthToggles = {}

for te = 1, 4 do
	tgl_length[te] = Toggle:Create(frm_time.x+10, lengthTglOffset, lengths_txt[te], htLengthTgle, false, 40)
	lengthTglOffset = lengthTglOffset + 26
	table.insert(group_lengthToggles, tgl_length[te])
end

local lengthTglOffset = frm_time.y + 30

for te = 5, 8 do
	tgl_length[te] = Toggle:Create(frm_time.x+53, lengthTglOffset, lengths_txt[te], htLengthTgle, false, 40)
	lengthTglOffset = lengthTglOffset + 26
	table.insert(group_lengthToggles, tgl_length[te])
end

sldr_timeThreshold = H_slider:Create(frm_time.x + 10, frm_time.y+frm_time.h - 20, frm_time.w - 20, nil,"PPQ Threshold", htTimeThreshold, 0, 100, 30, false)


--Status bar
--For now status needs to be global
status = Status:Create(10, frm_time.y + frm_time.h + 27, 227, 60, "INFO", nil, nil, "Hover over a control for more info!")

ddwn_scaleName = Dropdown:Create(frm_pitch.x+52, frm_pitch.y+frm_pitch.h-15, frm_pitch.w-62 , nil, scaleName, 1, 1, htDdwnScales)


local ddwn_presets = Dropdown:Create(frm_general.x+10, btn_select.y+43, frm_general.w-20, nil, presets, 1, 1, htDdwnPresets, load_preset, path)


---Handle tabs

local tab_main = Tabs:AddTab("Main", true, htMainTab)
tab_main_elements = {btn_select, btn_clear, btn_capture, ddwn_presets}
frm_general:AttatchTab(tab_main)
tab_main:AttatchElements(tab_main_elements)

local tab_settings = Tabs:AddTab("Settings", false, htSettingsTab)
tab_settings_elements = {tgl_dockOnStart, txt_dockOnStart, tgl_floatAtMouse, tgl_floatAtPos, txt_floatAtPos, 
						txt_floatAtMouse, ib_floatAtPosX, ib_floatAtPosY, ib_floatAtMouseX, ib_floatAtMouseY, btn_save}
frm_general:AttatchTab(tab_settings)
tab_settings:AttatchElements(tab_settings_elements)



function main()

	load_preset(path .. '..', name)

	--update selected pitch toggles
	for p, pp in ipairs(group_pitchToggles) do

		if pp.state then selectedNotes[p] = 1 else selectedNotes[p] = 0 end

	end

	--update selected length toggles
	for p, pp in ipairs(group_lengthToggles) do
		if pp.state == true then lengths[p] = 1 else lengths[p] = 0 end
	
	end

	--update beat toggles
	for p, pp in ipairs(group_beatsToggles) do
		if pp.state == true then beats[p] = 1 else beats[p] = 0 end
	end
	-------------------------------
	--SELECT-----------------------
	-------------------------------
	select_notes(true, true, sldr_minVel.value, sldr_maxVel.value, ib_minNote.value, ib_maxNote.value, sldr_timeThreshold.value)


end


main()

reaper.Undo_EndBlock(name .. "", -1)
reaper.atexit(reaper.JS_Window_SetFocus(lastWindow))



