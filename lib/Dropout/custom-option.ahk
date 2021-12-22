#Include %A_ScriptDir%\lib\Dropout\script-helper.ahk

UpdateGameSettings(AppClass) {
    PathToAppList := A_ScriptDir "\AppList.txt"

    WinGet, AppExe, ProcessName, ahk_class %AppClass%

    if !FileExist(PathToAppList)
        return

    Loop, read, %PathToAppList% 
    {
        Line := A_LoopReadLine
        
        if (SubStr(Line, 1, 1) == "") or (SubStr(Line, 1, 1) == ";") { ; Ignore comments and whitespace line
            Continue
        }
        else {
            AppAndCommand := StrSplit(Line, "," , " ")
            if (AppExe == AppAndCommand[1]) and WinExist("ahk_class " AppClass) {
                ExecuteCommands(AppExe, AppAndCommand)
            }
        }
    }
}


ExecuteCommands(AppExe, CmdList) {

    for index, cmd in CmdList {

        if (cmd == "sendtoleftscreen") {

            WinActivate, ahk_exe %AppExe%
            MoveToLeftScreen()
        }
        else if (cmd == "Sleep") {
            
            TimeSleep := CmdList[index + 1]
            Wait(TimeSleep)
        }
        else if (cmd == "SendKey") {

            KeyToSend := CmdList[index + 1]
            SendKeyTo(AppExe, KeyToSend)
        }
        else if (cmd == "borderless") {

            WinActivate, ahk_exe %AppExe%
            MakeBorderless()
        }

    }
}



MoveToLeftScreen() {
    SendWinShiftLeft()
}

ManualDetection() {

}

; Custom AHK commands

Wait(ms) {
    secs := ms * 1000
    Sleep secs
}

SendKeyTo(AppExe, key) {
    WinActivate, ahk_exe %AppExe%
    Send {%key%}
}

; Borderless

MakeBorderless() {
    Toggle_Window(WinExist("A"))
}

Toggle_Window(Window:="") {
	static A := Init()
	if (!Window)
		MouseGetPos,,, Window
	WinGet, S, Style, % (i := "_" Window) ? "ahk_id " Window :  ; Get window style
	if (S & +0xC00000) {                                        ; If not borderless
		WinGet, IsMaxed, MinMax,  % "ahk_id " Window
		if (A[i, "Maxed"] := IsMaxed = 1 ? true : false)
			WinRestore, % "ahk_id " Window
		WinGetPos, X, Y, W, H, % "ahk_id " Window               ; Store window size/location
		for k, v in ["X", "Y", "W", "H"]
			A[i, v] := %v%
		Loop, % A.MCount {                                      ; Determine which monitor to use
			if (X >= A.Monitor[A_Index].Left
				&&  X <  A.Monitor[A_Index].Right
				&&  Y >= A.Monitor[A_Index].Top
				&&  Y <  A.Monitor[A_Index].Bottom) {
			WinSet, Style, -0xC00000, % "ahk_id " Window    	; Remove borders
			WinSet, Style, -0x40000, % "ahk_id " Window    		; Including the resize border
			WinSet, ExStyle, -0x00000200, % "ahk_id " Window 	;Also WS_EX_CLIENTEDGE
			
			; The following lines are the x,y,w,h of the maximized window
			; ie. to offset the window 10 pixels up: A.Monitor[A_Index].Top - 10
			WinMove, % "ahk_id " Window,
			, A.Monitor[A_Index].Left                               ; X position
			, A.Monitor[A_Index].Top                                ; Y position
			, A.Monitor[A_Index].Right - A.Monitor[A_Index].Left    ; Width
			, A.Monitor[A_Index].Bottom - A.Monitor[A_Index].Top    ; Height
			break
			}
		}
	}
	else if (S & -0xC00000) {                                           ; If borderless
		WinSet, Style, +0x40000, % "ahk_id " Window    					; Reapply borders
		WinSet, Style, +0xC00000, % "ahk_id " Window
		WinSet, ExStyle, +0x00000200, % "ahk_id " Window 				;Also WS_EX_CLIENTEDGE
		WinMove, % "ahk_id " Window,, A[i].X, A[i].Y, A[i].W, A[i].H    ; Return to original position
		if (A[i].Maxed)
			WinMaximize, % "ahk_id " Window
		A.Remove(i)
	}
}

Init() {
	A := {}
	SysGet, n, MonitorCount

	Loop, % A.MCount := n {
		SysGet, Mon, Monitor, % i := A_Index
		for k, v in ["Left", "Right", "Top", "Bottom"]
			A["Monitor", i, v] := Mon%v%
	}
	return A
}
