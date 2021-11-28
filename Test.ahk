#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include ChildProc.ahk

STEAM_CLASS := "CUIEngineWin32"
STEAM_EXE := "steam.exe"
CurrentlyRunningGame := ""


DetectAndUpdateGame() { 
    global CurrentlyRunningGame
    WinGet, SteamProcPID, PID, ahk_exe steam.exe

    ChildProc := GetChildProcessName(SteamProcPID)

    tempProc := ""
    for each, proc in ChildProc {
        if (proc != "steamwebhelper.exe") && (proc != "steamservice.exe") && (proc != "GameOverlayUi.exe") {
            tempProc := proc
            MsgBox, %tempProc%
        }
            

    }

    if (tempProc != "") {
        WinGetClass, tempProcClass, ahk_exe tempProc
        CurrentlyRunningGame = tempProcClass

    }

    return

}

dummy := ""
k::
WinActivate, ahk_class %dummy%
return