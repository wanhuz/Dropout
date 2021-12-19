GetApp(CurrentlyRunningGame) {
    ;Get either Steam Big Picture or the Game name

    if(SteamBigPictureExist()) && (IsGameExist(CurrentlyRunningGame)) {
        GameClass := GetGame(CurrentlyRunningGame)
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

IsGameExist(CurrentlyRunningGame) {
    if (CurrentlyRunningGame != "")
        return 1

    return 0    
}

GetGame(CurrentlyRunningGame) {

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

MoveGameToLeft(AppListPath, AppClass) {
    PathToAppList := AppListPath
    WinGet, AppExe, ProcessName, ahk_class %AppClass%

    if !FileExist(PathToAppList)
        return

    Loop, read, %PathToAppList% 
    {
        if (AppExe == A_LoopReadLine) {
            WinActivate, ahk_class %AppClass%
            SendWinShiftLeft()
        }
    }

}