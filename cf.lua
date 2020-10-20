function is_note_in_time_selection(n)
	ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
	ts_start_ppq  = reaper.MIDI_GetPPQPosFromProjTime( take, ts_start )
	ts_end_ppq = reaper.MIDI_GetPPQPosFromProjTime( take, ts_end )

	if n >= ts_start_ppq and n <= ts_end_ppq then return true else return false end

end

function matches_selected_beats(startppqpos)
	threshold = 30

	for bbb = 16, 1, -1 do

		if beats[bbb] == 1 and startppqpos%(3840) >= beats_in_ppq[bbb] - threshold and startppqpos%(3840) <= beats_in_ppq[bbb] + threshold then
			--cons("\n\nBBB: " .. bbb .. "\nSPPQ:" .. startppqpos .. "beatsinppq: " .. beats_in_ppq[bbb] .. "\nSTARTMODPPQ: " .. startppqpos % beats_in_ppq[bbb], false) 	
			return true
		end
	end
	return false
end

function midi_to_note(n)

	return tostring(note_names[note_midi_n[(n%12)+2]]) .. "4"

end


function note_to_midi(str)

	--separate the octave and note name
	o = tonumber(str.match(str, '%d%d')) or tonumber(str.match(str, '%d'))
	n = str.match(str, '%u%p') or str.match(str, '%u')

	for i = 1, 12 do
		--cons("Note name: " .. note_names[i] .. "\nNote list:" .. note_midi_n[i], false)
		if n == note_names[i] then return (note_midi_n[i] + (o*12)) end
	end

	cons(midi_n-1, true)
end

function update_active()

	active_midi_editor = reaper.MIDIEditor_GetActive()
	take = reaper.MIDIEditor_GetTake(active_midi_editor)
	notes = reaper.MIDI_CountEvts(take)

end

function notes_list_not_empty()
	
	for i = 1, 12 do
		--reaper.ShowConsoleMsg(notes_list[i])
		if notes_list[i] == 1 then return true end
	end
	return false

end

function is_note_in(n)
	for i = 1, 12 do
		if notes_list[i] == 1  and note_midi_n[i] == n then return true
		end
	end
	return false
end

function select_notes(clear, min_vel, max_vel, time_selection_select)

	--Make sure we are working on the active midi item
	update_active()
	selected_notes = 0
	--If clear is flagged we first clear the selection

	if clear then reaper.MIDI_SelectAll(take, false) end

	for b = 1, 16 do
		if beats[b] == 1 then there_are_beats_selected = true
			break
		else
			there_are_beats_selected = false
		end
	end


	--Run through midi notes in take 
	--If they are witin the velocity and note range then select them (according to the parameters of the pitch frame)
	for i = 0, notes-1 do
		retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

		if time_selection_select and is_note_in_time_selection(startppqpos) == false then goto pass end

		if vel >= min_vel and vel <= max_vel and pitch >= note_to_midi(min_note) and pitch <= note_to_midi(max_note) then 
			if there_are_beats_selected and matches_selected_beats(startppqpos) == false then goto pass end
	

			reaper.MIDI_SetNote(take, i, is_note_in(pitch%12), false, startppqpos, endppqpos, chan, pitch, vel, true)

		end
		::pass::
	end



	reaper.MIDI_Sort(take)
end

function set_from_selected()
	update_active()
	retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, 0)
	min_vel = vel
	max_vel = vel
	temp_min_note = pitch
	temp_max_note = pitch

	for i = 0, notes-1 do
		retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
		if selected then
			if vel < min_vel then min_vel = vel
			elseif vel > max_vel then max_vel = vel
			elseif pitch < temp_min_note then 
				cons("here")
				temp_min_note = pitch
				
			elseif pitch > temp_max_note then 
				temp_max_note = pitch
			end
		end
	end
	min_note = midi_to_note(temp_min_note)
	max_note = midi_to_note(temp_max_note)

	cons(temp_min_note .. "         " .. midi_to_note(pitch%12), false)

end



function cons(text, p)
	if p == true then reaper.ClearConsole() end
	reaper.ShowConsoleMsg(text)
end