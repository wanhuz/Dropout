SendWinShiftRight() {
    Send, {LWin down}{LShift down}{Right down}
	Send, {LWin up}{LShift up}{Right up}
    Sleep, 100
}

SendWinShiftLeft() {
    Send {LWin down}{LShift down}
    Send {Left}
    Send {LWin up}{LShift up}
    Sleep, 100
}

DisableAllHotkey() {
    Hotkey, Joy1, Off
    Hotkey, Joy2, Off
    Hotkey, Joy3, Off
    Hotkey, Joy4, Off
}

EnableAllHotkey() {
    Hotkey, Joy1, On
    Hotkey, Joy2, On
    Hotkey, Joy3, On
    Hotkey, Joy4, On
}

GetProcessClass(ProcName) {
        WinGetClass, ProcClass, ahk_exe %ProcName%

        if (ProcClass == "") { 
            return 0
        }

        return ProcClass
}

ProcessExist(Name){
	Process, Exist, %Name%
	return Errorlevel
}

GrabAllAppAt(xcoord, ycoord) {
    ;Grab all application at given above coordinate, ignoring Steam Big Picture, shell tray and secondary shell tray
    AllApp := []
    WinGet, id, list

    Loop, %id% {
        this_ID := id%A_Index%
        WinGetPos, X, Y, Width, Height, ahk_id %this_ID%
        WinGetClass, AppClass, ahk_id %this_ID%
        
        if (AppClass == "CUIEngineWin32") ; Ignore Steam Big Picture
            Continue
        else if (AppClass == "Shell_TrayWnd") ; Ignore Shell Tray
            Continue
        else if (AppClass == "Shell_SecondaryTrayWnd")
            Continue
        else if (AppClass == "Internet Explorer_Hidden")
            Continue

        If (X>xcoord and Y>ycoord)  ; Coordinate changes if primary monitor changes, see Autohotkey Spy. X and Y < 0 because fullscreen apps coordinate starts at 0,0
            AllApp.Push(AppClass)        
            
    }

    if (not (AllApp.Count() == 0))
        return AllApp

    return 0
}

NumAppAt(Xcoord, Ycoord) {
    AppMonitorThree = 0
    WinGet, id, list

    Loop, %id% {
        this_ID := id%A_Index%
        WinGetPos, X, Y, Width, Height, ahk_id %this_ID%
        WinGetClass, AppClass, ahk_id %this_ID%

        if (AppClass == "CUIEngineWin32") ; Ignore Steam Big Picture
            Continue
        else if (AppClass == "Shell_TrayWnd") ; Ignore Shell Tray
            Continue
        else if (AppClass == "Shell_SecondaryTrayWnd")
            Continue

        If (X > Xcoord and Y > Ycoord)  ; Coordinate changes if primary monitor changes, see Autohotkey Spy
            AppMonitorThree += 1

    }

    return AppMonitorThree
}

MoveAppOut(x, y, exceptionClass) {
    TempAppsClasses := GrabAllAppAt(x,y)

    if (exceptionClass != 0) ; If game exist, also compare it with apps process
    	WinGet, exceptionProcess, ProcessName, ahk_class %exceptionClass%
    
    for index, TempAppClass in TempAppsClasses {

        if (exceptionClass != 0)
            WinGet, TempAppClassProcess, ProcessName, ahk_class %TempAppClass%

        if (TempAppClass == exceptionClass) {
            Continue
        }   
        else if (exceptionClass != 0) and (TempAppClassProcess == exceptionProcess) {
            Continue
        }
            
        WinActivate, ahk_class %TempAppClass%
        SendWinShiftRight()
    }

    return
}