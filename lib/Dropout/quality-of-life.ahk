#Include %A_ScriptDir%\lib\Dropout\script-helper.ahk

SteamOverlay() {

    while GetKeyState("Joy14", "P") {
        Send {Shift Down}{Tab Down}
        Sleep, 100
        Send {Shift Up}{Tab Up}
        Sleep, 1000
    }

    return
}

KillGame(game) {

    while GetKeyState("Joy14", "P") {
        MsgBox % "Trying to kill "  game
        WinKill, ahk_class %game%
        Sleep, 1000

        ; Terminate if game failed to close
        WinGet, GamePID, PID, ahk_class %game%
        if (ProcessExist(%GamePID%))
           Process, Close, %GamePID%

        Sleep, 1000
    }

    return
}

ActivateApp(app) {
    WinActivate, ahk_class %app%
    return
}

ResetController(game) {
    ; Consider not using Steam Overlay if game has problem

    while GetKeyState("Joy14", "P") {
        WinActivate, ahk_class CUIEngineWin32   
        Sleep, 5000
        WinActivate, ahk_class %game%
    }
    return
}