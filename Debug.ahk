
PrintAppInMonitorThree() {
    WinGet, id, list

    Loop, %id% {
        this_ID := id%A_Index%
        WinGetPos, X, Y, Width, Height, ahk_id %this_ID%
        WinGetClass, AppClass, ahk_id %this_ID%
        
        If (X>3600 and Y>-40)
        ;If (X > -40 and Y > - 40)  ; Coordinate changes if primary monitor changes, see Autohotkey Spy. X and Y < 0 because fullscreen apps coordinate starts at 0,0
            MsgBox, %AppClass%
	    
    }

    return 0
}

Print(function) {
    varToPrint := function
    MsgBox, %varToPrint%
}