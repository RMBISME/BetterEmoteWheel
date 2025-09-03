#Requires AutoHotkey v2.0

/*
 * BetterEmoteWheel v1.2.0 by RMBISME
 * "An AutoHotkey script for managing and using Roblox emotes, because 8 slots just isn't enough."
 *
 * I don't expect you to understand any of this.
 *
 * If you encounter an error, please let me know.
 * Send a screenshot of the error with the expanded details.
 * 
 * If you have any suggestions or feedback, I would love to hear it.
 *
 * GitHub repository: https://github.com/RMBISME/BetterEmoteWheel
 */

/* ### CHANGELOGS ###
 *
 * ADDITIONS
 * + Created a GitHub repository.
 *   + Added a link to the repository in the about window.
 * + Added an option to clear chat (default is off).
 * + Added buttons to play the most recent or random emote.
 * 
 * REMOVALS
 * - Removed right click functionality from the play button.
 */

/*
 * MODIFIER KEYS
 * ^ = Control
 * ! = Alt
 * + = Shift
 * # = Win
 */

; PANIC BUTTON
+Escape::ExitApp

; Reload script
#+R::Reload

; Create folder
If !DirExist(A_WorkingDir . "\BetterEmoteWheel") {
	DirCreate A_WorkingDir . "\BetterEmoteWheel"
}

; Emote list location
EmoteDir := A_WorkingDir . "\BetterEmoteWheel\emotes.csv"

; Settings location
SettingsDir := A_WorkingDir . "\BetterEmoteWheel\settings.csv"

; Get settings
/* ### SETTING ORDER ###
 * - Always on top?
 * - Allow duplicates?
 * - Most recent emote
 * - Emote list width (in pixels)
 * - Emote list height (in rows)
 * - Keep open?
 * - Theme # (unused)
 * - Disable startup popup?
 * - Match case?
 * - Sound effects?
 * - Clear chat?
 */
DefaultSettings := "0,1,Dance,320,16,1,0,0,0,1,0" ; Changes with every update
SettingsGet() {
	If !FileExist(SettingsDir) {
		SettingsReset()
	}
	
	NewSettings := StrSplit(FileRead(SettingsDir), ",")
	DefaultSettingsArray := StrSplit(DefaultSettings, ",")
	
	If NewSettings.Length < DefaultSettingsArray.Length {
		MissingCount := DefaultSettingsArray.Length - NewSettings.Length
		Offset := 1
		
		Loop MissingCount {
			FileAppend("," . DefaultSettingsArray[DefaultSettingsArray.Length - MissingCount + Offset], SettingsDir)
			Offset++
		}
		
		Return SettingsGet()
	} Else {
		Return NewSettings
	}
}

; Save settings
SettingsSave(Settings) {
	If !FileExist(SettingsDir) {
		SettingsReset()
	}
	
	FileDelete SettingsDir
	FileAppend ArrayToString(Settings), SettingsDir
}

; Reset settings
SettingsReset() {
	If FileExist(SettingsDir) {
		FileDelete SettingsDir
	}
	
	FileAppend DefaultSettings, SettingsDir
}

; Check if emote list exists
ListExists() {
	Return FileExist(EmoteDir)
}

; Create emote list
ListCreate() {
	DirCreate A_WorkingDir . "\BetterEmoteWheel"
	FileAppend "Dance,Dance1,Dance2,Dance3,Laugh,Cheer,Point", EmoteDir
}

; Add to emote list
ListAdd(NewEmote) {
	FileAppend "," . NewEmote, EmoteDir
}

; Remove from emote list
ListRemove(Emote) {
	Emotes := ListGet()
	
	Loop Emotes.Length {
		If Emotes[A_Index] == Emote {
			Emotes.RemoveAt(A_Index)
			Break
		}
	}
	
	FileDelete EmoteDir
	FileAppend ArrayToString(Emotes), EmoteDir
}

; Get emote list
ListGet() {
	Return StrSplit(FileRead(EmoteDir), ",")
}

; Reset emote list
ListReset() {
	FileDelete EmoteDir
	ListCreate()
} 

; Display emote list
Global Settings := SettingsGet()
Global SearchTerm := ""
ListOpen() {
	Emotes := ListGet()
	;Themes := ["&Light", "&Dark", "Terminal"]
	IsSearching := False
	
	Global EmotePicker := Gui()
	EmotePicker.Title := "Emote List"
	EmotePicker.OnEvent("Close", ClosePicker)
	EmotePicker.OnEvent("Escape", ClosePicker)
	
	ScriptMenu := Menu()
	ScriptMenu.Add("&Edit", ScriptMenuEdit)
	ScriptMenu.Add("&Reload", ScriptMenuReload)
	ScriptMenu.Add("E&xit", ScriptMenuExit)
	
	SettingsMenu := Menu()
	SettingsMenu.Add("&Always on Top", SettingsMenuAOT)
	If Settings[1] == "1" {
		SettingsMenu.Check("&Always on Top")
		EmotePicker.Opt("+AlwaysOnTop")
	}
	SettingsMenu.Add("List &Size...", SettingsMenuSize)
	SettingsMenu.Add("Allow &Duplicates", SettingsMenuDupe)
	If Settings[2] == "1" {
		SettingsMenu.Check("Allow &Duplicates")
	}
	SettingsMenu.Add("&Keep Open", SettingsMenuPersist)
	If Settings[6] == "1" {
		SettingsMenu.Check("&Keep Open")
	}
	SettingsMenu.Add("Disable Startup &Popup", SettingsMenuPopup)
	If Settings[8] == "1" {
		SettingsMenu.Check("Disable Startup &Popup")
	}
	SettingsMenu.Add("&Match Case", SettingsMenuCase)
	If Settings[9] == "1" {
		SettingsMenu.Check("&Match Case")
	}
	SettingsMenu.Add("&Sound Effects", SettingsMenuSounds)
	If Settings[10] == "1" {
		SettingsMenu.Check("&Sound Effects")
	}
	SettingsMenu.Add("&Clear Chat", SettingsMenuClear)
	If Settings[11] == "1" {
		SettingsMenu.Check("&Clear Chat")
	}
	SettingsMenu.Add()
	SettingsMenu.Add("&Reset Settings...", SettingsMenuReset)
	/*
	ThemeMenu := Menu()
	ThemeMenu.Add("&Light", ThemeMenuRadio, "Radio")
	ThemeMenu.Add("&Dark", ThemeMenuRadio, "Radio")
	ThemeMenu.Add()
	ThemeMenu.Add("Terminal", ThemeMenuRadio, "Radio")
	ThemeMenu.Add()
	ThemeMenu.Add("&Sync", ThemeMenuRadio, "Radio")
	ThemeMenu.Check(Settings[7] == "0" ? "&Sync" : Themes[Integer(Settings[7])])
	*/
	HelpMenu := Menu()
	HelpMenu.Add("View &Help...", HelpMenuHelp)
	HelpMenu.Add("View FA&Q...", HelpMenuFAQ)
	HelpMenu.Add()
	HelpMenu.Add("&About...", HelpMenuAbout)
	HelpMenu.Add("Give &Feedback...", HelpMenuFeedback)
	
	EmotePickerMenuBar := MenuBar()
	EmotePickerMenuBar.Add("&Script", ScriptMenu)
	EmotePickerMenuBar.Add("Se&ttings", SettingsMenu)
	;EmotePickerMenuBar.Add("&Theme", ThemeMenu)
	EmotePickerMenuBar.Add("&Help", HelpMenu)
	EmotePicker.MenuBar := EmotePickerMenuBar
	
	EmotePicker.Add("Edit", "vSearchBar w" . Settings[4], SearchTerm).OnEvent("Change", SearchEmotes)
	
	EmoteList := EmotePicker.Add("ListBox", "xm w" . Settings[4] . " r" . Settings[5])
	EmoteList.OnEvent("Change", Click1)
	EmoteList.OnEvent("DoubleClick", Click2)
	EmoteList.OnEvent("DoubleClick", PlayEmote)
	EmoteList.OnEvent("ContextMenu", DeleteEmote)
	
	EmotePicker.Add("Button", "vPlay", "&Play").OnEvent("Click", PlayEmote)
	EmotePicker.Add("Button", "x+m", "Play R&ecent").OnEvent("Click", PlayLast)
	EmotePicker.Add("Button", "x+m", "Play Ra&ndom").OnEvent("Click", PlayRandom)
	EmotePicker.Add("Button", "vDelete xm", "&Delete").OnEvent("Click", DeleteEmote)
	EmotePicker.Add("Button", "vAdd x+m", "&Add").OnEvent("Click", AddEmotes)
	EmotePicker.Add("Button", "vReset x+m", "&Reset").OnEvent("Click", ResetEmotes)
	
	SearchStatus := EmotePicker.Add("StatusBar")
	SearchStatus.SetParts(Settings[4] / 5, 0)
	SearchStatus.SetText(Settings[3], 3)
	If SearchTerm != "" {
		SearchEmotes()
	} Else {
		For _, Emote in Emotes {
			EmoteList.Add([Emote])
		}
	}
	SearchStatus.SetText(Emotes.Length . " emotes.", 1)
	
	EmotePicker.Show("AutoSize")
	
	; Play Windows Navigation Start.wav
	Click1(*) {
		If Settings[10] == "1" {
			SoundPlay A_WinDir . "\Media\Windows Navigation Start.wav"
		}
	}
	
	; Play Windows Navigation Command.wav
	Click2(*) {
		If Settings[10] == "1" {
			SoundPlay A_WinDir . "\Media\Windows Menu Command.wav"
		}
	}
	
	; Play Windows Default.wav
	Beep(*) {
		If Settings[10] == "1" {
			SoundPlay A_WinDir . "\Media\Windows Default.wav"
		}
	}
	
	; Destroy picker when closed
	ClosePicker(*) {
		Global Open := False
		EmotePicker.Destroy()
	}
	
	; Enable and show emote picker
	RestorePicker(*) {
		EmotePicker.Opt("-Disabled")
		EmotePicker.Show()
	}
	
	; Searches emotes
	SearchEmotes(*) {
		Global SearchTerm := EmotePicker["SearchBar"].Text
		IsSearching := EmotePicker["SearchBar"].Text != ""
		
		EmoteList.Delete()
		EmoteList.Opt("-Redraw")
		
		Results := 0
		If SearchTerm != "" {
			SearchStatus.SetParts(Settings[4] / 5, Settings[4] / 5)
			
			For _, Emote in Emotes {
				If InStr(Emote, SearchTerm, Settings[9] == "1" ? 1 : 0) {
					EmoteList.Add([Emote])
					Results++
				}
			}
		} Else {
			SearchStatus.SetParts(Settings[4] / 5, 0)
			
			For _, Emote in Emotes {
				EmoteList.Add([Emote])
			}
		}
		
		EmoteList.Opt("+Redraw")
		
		If Results == 1 {
			SearchStatus.SetText("1 result.", 2)
		} Else If Results {
			SearchStatus.SetText(Results . " results.", 2)
		} Else If SearchTerm ?? "" != "" {
			Beep()
			
			SearchStatus.SetText("No results.", 2)
		} Else {
			SearchStatus.SetText("", 2)
		}
	}
	
	; Play given emote
	ChatEmote(Name) {
		SetTitleMatchMode 3
		
		If WinExist("Roblox") {
			Click2()
			
			WinActivate "Roblox"
			
			OldClipboard := ClipboardAll()
			A_Clipboard := "/e " . Name
			
			Send "/"
			Sleep 50
			If Settings[11] == "1" {
				Send "^a"
				Sleep 50
				Send "{Backspace}"
				Sleep 50
			}
			Send "^v"
			Sleep 50
			Send "{Enter}"
			
			Settings[3] := Name
			SearchStatus.SetText(Settings[3], 3)
			SettingsSave(Settings)
			A_Clipboard := OldClipboard
			
			If Settings[6] == "0" {
				EmotePicker.Destroy()
				Global Open := False
			}
		} Else {
			MsgBox "Could not find Roblox. Make sure Roblox is open and properly working.", , 16
		}
	}
	
	; Play selected emote
	PlayEmote(*) {
		If EmoteList.Text != "" {
			ChatEmote(EmoteList.Text)
		} Else {
			Beep()
		}
	}
	
	; Play last played emote
	PlayLast(*) {
		ChatEmote(Settings[3])
	}
	
	; Play random emote
	PlayRandom(*) {
		If Emotes.Length {
			ChatEmote(Emotes[Random(1, Emotes.Length)])
		} Else {
			Beep()
		}
	}
	
	; Delete selected emote
	DeleteEmote(*) {
		If EmoteList.Text != "" {
			If GetKeyState("Shift") {
				Click2()
				
				ListRemove(EmoteList.Text)
				Emotes := ListGet()
				EmoteList.Delete(EmoteList.Value)
				SearchEmotes()
				SearchStatus.SetText(Emotes.Length . " emotes.", 1)
			} Else {
				EmotePicker.Opt("+Disabled")
				
				Click1()
				
				If MsgBox("Are you sure you want to delete " EmoteList.Text "?`n(Hold shift to skip this prompt.)", "Delete Emote", "292 Owner" . EmotePicker.Hwnd) == "Yes" {
					Click2()
					
					ListRemove(EmoteList.Text)
					Emotes := ListGet()
					EmoteList.Delete(EmoteList.Value)
					SearchEmotes()
					SearchStatus.SetText(Emotes.Length . " emotes.", 1)
				}
				
				RestorePicker()
			}
		} Else {
			Beep()
		}
	}
	
	; Add emote
	AddEmotes(*) {
		Click1()
		
		EmoteAdder := Gui()
		EmoteAdder.Title := "Add Emotes"
		EmoteAdder.Opt("-MinimizeBox +Owner" EmotePicker.Hwnd)
		If Settings[1] == "1" {
			EmoteAdder.Opt("+AlwaysOnTop")
		}
		
		EmoteAdder.OnEvent("Escape", CloseAdder)
		EmoteAdder.OnEvent("Close", RestorePicker)
		
		EmoteAdder.Add("Text", , "Separate emote names with a comma (,).")
		EmoteAdder.Add("Edit", "vEmoteNames w320")
		EmoteAdder.Add("Button", , "&Add").OnEvent("Click", ProcessEmotes)
		EmoteAdder.Add("Button", "x+m", "&Cancel").OnEvent("Click", CloseAdder)
		
		EmoteAdder.Show()
		
		EmotePicker.Opt("+Disabled")
		
		ProcessEmotes(*) {
			Saved := EmoteAdder.Submit()
			
			If Saved.EmoteNames != "" {
				EmoteList.Opt("-Redraw")
				
				; WORK IN PROGRESS
				/*
				If Settings[2] == "0" {
					Hash := {}
					
					For _, Emote in StrSplit(Saved.EmoteNames, ",") {
						If !Hash.Haskey(Trim(Emote)) {
							Hash[(Trim(Emote))] := 1
							Emotes.Push(Trim(Emote))
							ListAdd(Trim(Emote))
							EmoteList.Add([Trim(Emote)])
						}
					}
				} Else {
					
					For _, Emote in StrSplit(Saved.EmoteNames, ",") {
						Emotes.Push(Trim(Emote))
						ListAdd(Trim(Emote))
						EmoteList.Add([Trim(Emote)])
					}
				}
				*/
				
				For _, Emote in StrSplit(Saved.EmoteNames, ",") {
						Emotes.Push(Trim(Emote))
						ListAdd(Trim(Emote))
						EmoteList.Add([Trim(Emote)])
					}
				
				Click2()
				
				EmoteList.Opt("+Redraw")
				SearchEmotes()
				SearchStatus.SetText(Emotes.Length . " emotes.", 1)
			} Else {
				Click1()
			}
			
			RestorePicker()
		}
		
		CloseAdder(*) {
			Click1()
			
			EmoteAdder.Destroy()
			RestorePicker()
		}
	}
	
	; Reset emote list
	ResetEmotes(*) {
		Click1()
		
		EmotePicker.Opt("+Disabled")
		
		If MsgBox("Are you sure you want to reset your emote list?", "Reset Emotes", "292 Owner" . EmotePicker.Hwnd) == "Yes"
		&& MsgBox("Are you really sure you want to reset your emote list?", "Reset Emotes", "292 Owner" . EmotePicker.Hwnd) == "Yes"
		&& MsgBox("Resetting your emote list cannot be undone. Reset anyway?", "Reset Emotes", "308 Owner" . EmotePicker.Hwnd) == "Yes" {
			EmoteList.Opt("-Redraw")
			ListReset()
			
			Click2()
			
			EmotePicker.Destroy()
			ListOpen()
			Return
		}
		
		RestorePicker()
	}
	
	; Edit script
	ScriptMenuEdit(*) {
		Edit
	}
	
	; Reload script
	ScriptMenuReload(*) {
		Reload
	}
	
	; Terminate script
	ScriptMenuExit(*) {
		ExitApp
	}
	
	; Toggle always on top
	SettingsMenuAOT(*) {
		If Settings[1] == "0" {
			Settings[1] := "1"
			SettingsMenu.Check("&Always on Top")
			EmotePicker.Opt("+AlwaysOnTop")
		} Else {
			Settings[1] := "0"
			SettingsMenu.Uncheck("&Always on Top")
			EmotePicker.Opt("-AlwaysOnTop")
		}
		
		SettingsSave(Settings)
	}
	
	; Adjust list size
	SettingsMenuSize(*) {
		SizeWindow := Gui()
		SizeWindow.Title := "Adjust List Size"
		SizeWindow.Opt("-MinimizeBox +Owner" . EmotePicker.Hwnd)
		If Settings[1] == "1" {
			SizeWindow.Opt("+AlwaysOnTop")
		}
		
		SizeWindow.OnEvent("Escape", CloseWindow)
		SizeWindow.OnEvent("Close", RestorePicker)
		
		SizeWindow.Add("Text", , "List width (in pixels):")
		SizeWindow.Add("Text", , "List height (in rows):")
		
		WidthEdit := SizeWindow.Add("Edit", "vWidth ym", "###")
		WidthEdit.Opt("+Number")
		WidthEdit.OnEvent("LoseFocus", LimitWidth)
		
		HeightEdit := SizeWindow.Add("Edit", "vHeight", "###")
		HeightEdit.Opt("+Number")
		HeightEdit.OnEvent("LoseFocus", LimitHeight)
		
		SizeWindow.Add("Button", "xm", "&Save").OnEvent("Click", Save)
		SizeWindow.Add("Button", "x+m", "&Reset").OnEvent("Click", Reset)
		SizeWindow.Add("Button", "x+m", "&Cancel").OnEvent("Click", CloseWindow)
		
		SizeWindow["Width"].Value := Settings[4]
		SizeWindow["Height"].Value := Settings[5]
		
		SizeWindow.Show()
		
		EmotePicker.Opt("+Disabled")
		
		LimitWidth(*) {
			If WidthEdit.Value < 320 {
				WidthEdit.Value := 320
			}
		}
		
		LimitHeight(*) {
			If HeightEdit.Value < 8 {
				HeightEdit.Value := 8
			} Else If HeightEdit.Value > 64 {
				HeightEdit.Value := 64
			}
		}
		
		Save(*) {
			Size := SizeWindow.Submit()
			
			Settings[4] := Size.Width
			Settings[5] := Size.Height
			SettingsSave(Settings)
			
			EmotePicker.Destroy()
			ListOpen()
		}
		
		Reset(*) {
			SizeWindow["Width"].Value := 320
			SizeWindow["Height"].Value := 16
		}
		
		CloseWindow(*) {
			SizeWindow.Destroy()
			RestorePicker()
		}
	}
	
	; Toggle duplicate emotes ### WORK IN PROGRESS
	SettingsMenuDupe(*) {
		MsgBox "This setting is a work in progress, and does nothing at this time.", "Work in Progress", "64 Owner" . EmotePicker.Hwnd
		
		If Settings[2] == "0" {
			SettingsMenu.Check("Allow &Duplicates")
			Settings[2] := "1"
			SettingsSave(Settings)
		} Else {
			If GetKeyState("Shift") {
				SettingsMenu.Uncheck("Allow &Duplicates")
				Settings[2] := "0"
				SettingsSave(Settings)
			} Else {
				EmotePicker.Opt("+Disabled")
				
				If MsgBox("Turning off this setting can cause performance issues. Disable duplicates?", "Disable Duplicates", "308 Owner" . EmotePicker.Hwnd) == "Yes" {
					SettingsMenu.Uncheck("Allow &Duplicates")
					Settings[2] := "0"
					SettingsSave(Settings)
				}
				
				RestorePicker()
			}
		}
	}
	
	; Toggle persistence
	SettingsMenuPersist(*) {
		If Settings[6] == "0" {
			SettingsMenu.Check("&Keep Open")
			Settings[6] := "1"
		} Else {
			SettingsMenu.Uncheck("&Keep Open")
			Settings[6] := "0"
		}
		
		SettingsSave(Settings)
	}
	
	; Toggle startup popup
	SettingsMenuPopup(*) {
		If Settings[8] == "0" {
			SettingsMenu.Check("Disable Startup &Popup")
			Settings[8] := "1"
		} Else {
			SettingsMenu.Uncheck("Disable Startup &Popup")
			Settings[8] := "0"
		}
		
		SettingsSave(Settings)
	}
	
	; Toggle case sensitivity
	SettingsMenuCase(*) {
		If Settings[9] == "0" {
			SettingsMenu.Check("&Match Case")
			Settings[9] := "1"
		} Else {
			SettingsMenu.Uncheck("&Match Case")
			Settings[9] := "0"
		}
		
		If IsSearching {
			SearchEmotes()
		}
		
		SettingsSave(Settings)
	}
	
	; Toggle sound effects
	SettingsMenuSounds(*) {
		If Settings[10] == "0" {
			SettingsMenu.Check("&Sound Effects")
			Settings[10] := "1"
		} Else {
			SettingsMenu.Uncheck("&Sound Effects")
			Settings[10] := "0"
		}
		
		SettingsSave(Settings)
	}
	
	; Toggle clearing chat
	SettingsMenuClear(*) {
		If Settings[11] == "0" {
			SettingsMenu.Check("&Clear Chat")
			Settings[11] := "1"
		} Else {
			SettingsMenu.Uncheck("&Clear Chat")
			Settings[11] := "0"
		}
		
		SettingsSave(Settings)
	}
	; Reset settings
	SettingsMenuReset(*) {
		EmotePicker.Opt("+Disabled")
		
		If MsgBox("Are you sure you want to reset your settings? This does not affect your emotes.", "Reset Settings", "308 Owner" . EmotePicker.Hwnd) == "Yes" {
			SettingsReset()
			EmotePicker.Destroy()
			ListOpen()
		} Else {
			RestorePicker()
		}
	}
	/*
	ThemeMenuRadio(*) {
		ThemeMenu.Check("&Dark")
	}
	*/
	; Show help screen
	HelpMenuHelp(*) {
		HelpWindow := Gui()
		HelpWindow.Title := "Help"
		HelpWindow.Opt("-MinimizeBox +Owner" . EmotePicker.Hwnd)
		If Settings[1] == "1" {
			HelpWindow.Opt("+AlwaysOnTop")
		}
		
		HelpWindow.OnEvent("Escape", CloseWindow)
		HelpWindow.OnEvent("Close", RestorePicker)
		
		HelpWindow.Add("Text", "w320", "Press F1 to open and close the emote list. Pressing F1 while the window is not focused will bring the window to the top. You cannot close the emote list while a popup is active.")
		HelpWindow.Add("Text", "w320", "Click an emote in the list to select it, and press the play button to play the emote, or press the delete button to remove the emote. Alternatively, double click an emote to quickly play it and right click an emote to delete it.")
		HelpWindow.Add("Text", "w320", "Hold shift to skip all confirmations. This does not apply to the reset button.")
		HelpWindow.Add("Text", "w320", "Right click the play button to play your last used emote.")
		HelpWindow.Add("Text", "w320", "Press Win + Shift + R to restart the script.")
		HelpWindow.Add("Text", "w320", "Press Shift + Escape to terminate the script.")
		
		HelpWindow.Show()
		
		EmotePicker.Opt("+Disabled")
		
		CloseWindow(*) {
			HelpWindow.Destroy()
			RestorePicker()
		}
	}
	
	; Show FAQ screen
	HelpMenuFAQ(*) {
		FAQWindow := Gui()
		FAQWindow.Title := "Frequently Asked Questions"
		FAQWindow.Opt("-MinimizeBox Owner" . EmotePicker.Hwnd)
		If Settings[1] == "1" {
			FAQWindow.Opt("+AlwaysOnTop")
		}
		
		FAQWindow.OnEvent("Escape", CloseWindow)
		FAQWindow.OnEvent("Close", RestorePicker)
		
		Q1 := FAQWindow.Add("Text", "w320", "Q1: Why did you make this?")
		Q1.SetFont("w700")
		FAQWindow.Add("Text", "w320", "A: I have way too many emotes for that dinky little wheel. I needed something bigger, plus I needed an excuse to script something for the first time in months.")
		
		Q2 := FAQWindow.Add("Text", "w320", "Q2: Can I make contributions?")
		Q2.SetFont("w700")
		FAQWindow.Add("Text", "w320", "A: If you know what you're doing, then you can send some revisions to me and I'll review them.")
		
		Q3 := FAQWindow.Add("Text", "w320", "Q3: Why use AutoHotkey?")
		Q3.SetFont("w700")
		FAQWindow.Add("Text", "w320", "A: AutoHotkey is a powerful and user-friendly scripting language and program that allows for complex macros that can be run with a single key combo. I chose AutoHotkey because of that and the fact that it's simple to set up.")
		
		Q4 := FAQWindow.Add("Text", "w320", "Q4: What's up with the version naming?")
		Q4.SetFont("w700")
		FAQWindow.Add("Text", "w320", "The version naming scheme I use is called SemVer, where the version numbers are MAJOR.MINOR.PATCH.")
		
		Q5 := FAQWindow.Add("Text", "w320", "Q5: How does the emote playing work?")
		Q5.SetFont("w700")
		FAQWindow.Add("Text", "w320", "A: It focuses the Roblox window, saves any old clipboard information to a temporary variable, copys the selected emote into an emote command (e.g. `"/e dance`"), activates chat, pastes in the command, and presses enter. It then replaces the clipboard information with the previously saved data from the temporary variable.")
		
		FAQWindow.Show()
		
		EmotePicker.Opt("+Disabled")
		
		CloseWindow(*) {
			FAQWindow.Destroy()
			RestorePicker()
		}
	}
	
	; Show about screen
	HelpMenuAbout(*) {
		AboutWindow := Gui()
		AboutWindow.Title := "BetterEmoteWheel v1.2.0"
		AboutWindow.Opt("-MinimizeBox Owner" . EmotePicker.Hwnd)
		If Settings[1] == "1" {
			AboutWindow.Opt("+AlwaysOnTop")
		}
		
		AboutWindow.OnEvent("Escape", CloseWindow)
		AboutWindow.OnEvent("Close", RestorePicker)
		
		Title := AboutWindow.Add("Text", "w320 h35 Center", "BetterEmoteWheel")
		Title.SetFont("s25 w700")
		Author := AboutWindow.Add("Text", "w320 h25 Center", "By RMBISME")
		Author.SetFont("s15")
		Summary := AboutWindow.Add("Text", "w320 h40 Center", "An AutoHotkey script for managing and using Roblox emotes, because 8 slots just isn't enough.")
		Summary.SetFont("s10")
		AboutWindow.Add("Link", "w320 Center", "View on <a href=`"https://github.com/RMBISME/BetterEmoteWheel`">GitHub</a>")
		
		AboutWindow.Show()
		
		EmotePicker.Opt("+Disabled")
		
		CloseWindow(*) {
			AboutWindow.Destroy()
			RestorePicker()
		}
	}
	
	; Show how to give feedback
	HelpMenuFeedback(*) {
		FeedbackWindow := Gui()
		FeedbackWindow.Title := "Give Feedback"
		FeedbackWindow.Opt("-MinimizeBox Owner" . EmotePicker.Hwnd)
		If Settings[1] == "1" {
			FeedbackWindow.Opt("+AlwaysOnTop")
		}
		
		FeedbackWindow.OnEvent("Escape", CloseWindow)
		FeedbackWindow.OnEvent("Close", RestorePicker)
		
		FeedbackWindow.Add("Text", "w320", "Have any suggestions, questions, or other feedback? Let me know on Discord at RMBISME_2.0.")
		FeedbackWindow.Add("Text", "w320", "If you would like to report an issue, make sure to send a screenshot if possible and explain the steps you took for the issue to occur.")
		
		FeedbackWindow.Show()
		
		EmotePicker.Opt("+Disabled")
		
		CloseWindow(*) {
			FeedbackWindow.Destroy()
			RestorePicker()
		}
	}
}

; Convert an array to a string
ArrayToString(arr, sep := ",") {
	str := ""
	
	For k, v in arr {
		str .= v
		If A_Index < arr.Length {
			str .= sep
		}
	}
	
	Return str
}

; Start/Focus/Close emote menu
Global Open := False
FileEncoding "UTF-8"
#MaxThreadsPerHotkey 2
F1::{
	If IsSet(EmotePicker) && Open {
		If (EmotePicker.FocusedCtrl) {
			Global Open := False
		} Else {
			EmotePicker.Show()
			Return
		}
	} Else {
		Global Open := True
	}
	
	If !Open {
		EmotePicker.Destroy()
	} Else {
		If !ListExists() {
			Result := MsgBox("The emote list does not exist. Create it?", "List Not Found", 52)
			
			If Result == "Yes" {
				ListCreate()
				ListOpen()
			}
				
		} Else {
			ListOpen()
		}
	}
}
#MaxThreadsPerHotkey 1w

If Settings[8] == "0" {
	MsgBox "Press F1 at any time to open, focus, or close the emote list. Refer to the help menu for more information.`n`nYou can disable this message in Settings.", "BetterEmoteWheel", "64 T10"
}
