#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include  %A_WorkingDir%\lib\Dropout\custom-option.ahk

F3::
    WinGetClass, CurrentlyRunningGameClass, A
    MsgBox % CurrentlyRunningGameClass
    PathToAppList := A_ScriptDir "\AppList.txt"
    UpdateGameSettings(PathToAppList, CurrentlyRunningGameClass)

    return
