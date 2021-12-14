GetApp() {
    ;Get either Steam Big Picture or the Game name

    if(SteamBigPictureExist()) && (IsGameExist()) {
        GameClass := GetGame()
        return GameClass
    }
    else if (SteamBigPictureExist()) {
        SteamClass := "CUIEngineWin32"
        return SteamClass
    }
    return 0
}

SteamBigPictureExist() {
    if WinExist("ahk_class CUIEngineWin32") and WinExist("ahk_exe steam.exe")
        return 1
    return 0 
}

IsGameExist() {
    global CurrentlyRunningGame

    if (CurrentlyRunningGame != "")
        return 1

    return 0    
}

GetGame() {
    global CurrentlyRunningGame

    if (CurrentlyRunningGame != "")
        return CurrentlyRunningGame

    return 0
}

GetRunningGame() { 
    WinGet, SteamProcPID, PID, ahk_exe steam.exe

    SteamChildProc := GetChildProcessName(SteamProcPID)

    GameProc := ""
    for each, proc in SteamChildProc {
        
        if (proc != "steamwebhelper.exe") && (proc != "steamservice.exe") && (proc != "GameOverlayUi.exe") && (proc != "steamerrorreporter.exe") {
            GameProc := proc
        }
            
    }

    if (GameProc == "") {
        ; No game is running or detected
        return 0
    }

    WinGetClass, ProcClass, ahk_exe %GameProc%

    ; If fail to get class name from process, get its child class. Goes only one level down
    if (ProcClass == "") { 

        ;Get Pid of Parent process, and then get its child processes
        ProcPID := GetProcessID(GameProc)
        ChildProcNames := GetChildProcessName(ProcPID)
        
        ;Get the first process of child processes, then get its class name
        GameProc := ChildProcNames[1]

    }

    return GameProc
}