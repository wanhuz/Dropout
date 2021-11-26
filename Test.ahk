#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include, ProcessInfo_LinearSpoon.ahk

s::
;scriptPID := GetCurrentProcess()
WinGet, scriptPID, PID, A
scriptEXE := GetProcessName(scriptPID)
while True {
    parentPID := GetParentProcess(scriptPID)
    parentEXE := GetProcessName(parentPID)
    WinGetClass, parentName, ahk_exe %parentEXE%
    Msgbox % "Script PID: " scriptPID "`nScript executable: " scriptEXE "`nParent PID: " parentPID "`nParent executable: " parentEXE
    Msgbox % "Parent name: " parentName
    scriptPID := parentPID
}

k::
WinGet, ChildProcessId, List , A
Loop, %ChildProcessId%
{
    this_id := ChildProcessId%A_Index%
    WinActivate, ahk_id %this_id%
    WinGetClass, this_class, ahk_id %this_id%
    WinGetTitle, this_title, ahk_id %this_id%
    MsgBox % "Process title: " this_title " Process Class: " this_class
}
