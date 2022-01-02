#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include %A_ScriptDir%\lib\SoundVolumeView\SoundVolumeViewWrapper.ahk

TargetOutputDevice := """Realtek High Definition Audio\Device\Speakers\Render"""
DefaultOutputDevice := """VB-Audio Virtual Cable\Device\CABLE Input\Render"""

F2::
WinGet, CurrentlyRunningGameProcess, ProcessName , A

;MsgBox, %CurrentlyRunningGameProcess%

SetDefaultPlaybackOutput(TargetOutputDevice)
Sleep, 5000 ; Workaround for some games
SetAppOutputThenSwitchDefaultOutput(TargetOutputDevice, CurrentlyRunningGameProcess, DefaultOutputDevice)
;SetDefaultPlaybackOutput(DefaultOutputDevice)
MsgBox, Done
return

F3::
MsgBox, test
return