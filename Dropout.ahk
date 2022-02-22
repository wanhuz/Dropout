#NoEnv 
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Force

#Include %A_ScriptDir%\lib\Dropout\process.ahk
#Include %A_ScriptDir%\lib\Dropout\apps.ahk
#Include %A_ScriptDir%\lib\Dropout\script-helper.ahk
#Include %A_ScriptDir%\lib\Dropout\virtualization.ahk
#Include %A_ScriptDir%\lib\Dropout\quality-of-life.ahk
#Include %A_ScriptDir%\lib\Dropout\custom-option.ahk
#Include %A_ScriptDir%\lib\Dropout\config.ahk
#Include %A_ScriptDir%\lib\SoundVolumeView\SoundVolumeViewWrapper.ahk

Menu, Tray, Icon, %A_ScriptDir%\res\dropout.ico

/*
. This script is a best-effort approach to virtualize third virtual monitor. 
. Best-effort means it will try it best to seperate third monitor from the rest of the system, but it will not be perfect due to Windows limitation
. This script works with assumption that Big Picture is used on rightmost monitor, which is primary monitor when launched
. There is only three Apps running on rightmost monitor, first is Steam Big Picture, Windows Tray and the game

Script work:
	- When script activated before starting Big Picture
	- When script activated after starting Big Picture
	- Changed default USB controller to iPega
    - Script doesn't work if default Windows Controller is not iPega before starting Big Picture
    - KillApp will work better if the script is run as admin (terminate hanging game if issue happens)

*/

STEAM_CLASS := "CUIEngineWin32"
STEAM_PROCESS := "steam.exe"

EnableSteamOverlayHotkey := False
EnableSteamControllerResetHotkey := False
EnableExitGameHotkey := False
EnableDefaultTaskbar := False
EnableDefaultDesktopIcon := False
MonitorOnlyHaveSteamAndGame := False
EnableAudioSeperation := False
ReopenFolder := True
SaveDesktopIconEverySecs = 60
DefaultOutputDevice := ""
TargetOutputDevice := ""

LoadHotkeyConfig(EnableSteamOverlayHotkey, EnableSteamControllerResetHotkey, EnableExitGameHotkey)
LoadVirtualizationConfig(EnableDefaultTaskbar, EnableDefaultDesktopIcon, MonitorOnlyHaveSteamAndGame, EnableAudioSeperation, SaveDesktopIconEverySecs, ReopenFolder)
;LoadDisplayConfig(DefaultDisplayNum)
if (EnableAudioSeperation)
    LoadAudioConfig(DefaultOutputDevice, TargetOutputDevice)

CurrentlyRunningGameClass := ""
CurrentlyRunningGameProcess := ""
SteamLaunched := False
TaskbarAlreadyMoved := False
SteamAudioSwitch := False
UpdateNewGameAudio := False
UpdateNewGameSetting := False

DesktopIconData := DesktopIcons()
SaveDesktopIconEveryMs := SaveDesktopIconEverySecs * 1000
Menu, Tray, Add , &Exit Steam, ExitSteam

SetTimer, UpdateApps, 100, 3
SetTimer, UpdateTaskbar, 1000, 2
SetTimer, UpdateGameSetting, 1000, 3
SetTimer, UpdateAudio, 100, 3 ; Need to be fast because some game set default audio at launch time and cannot be changed
SetTimer, SaveDesktopIcon, %SaveDesktopIconEveryMs%

if (not EnableDefaultTaskbar)
    SetTimer, UpdateTaskbar, Delete 
if (not EnableAudioSeperation)
    SetTimer, UpdateAudio, Delete 
if (not EnableDefaultDesktopIcon)
    SetTimer, SaveDesktopIcon, Delete 

return

EnableHotkey:

Joy1::
App := GetApp(CurrentlyRunningGameClass)
ActivateApp(App)
if (EnableSteamOverlayHotkey)
    SteamOverlay()
return 

Joy2::
App := GetApp(CurrentlyRunningGameClass)
ActivateApp(App)
if (EnableSteamControllerResetHotkey)
    ResetController(App)
return 

Joy3::
App := GetApp(CurrentlyRunningGameClass)
ActivateApp(App)
if (EnableExitGameHotkey)
    KillGame(App)
return 

Joy4::
Joy5::
Joy6::
Joy7::
Joy8::
Joy9::
Joy10::
App := GetApp(CurrentlyRunningGameClass)
ActivateApp(App)
return

UpdateTaskbar:

    If (SteamBigPictureExist()) && (TaskbarAlreadyMoved == False) {
        BlockInput, On
        SetTimer, UpdateApps, Off
        DisableAllHotkey()
	    Sleep, 200

        MovePrimaryTaskbar(ReopenFolder)
        TaskbarAlreadyMoved := True
        if (EnableDefaultDesktopIcon)
            DesktopIcons(DesktopIconData)
        ActivateApp(STEAM_CLASS)

        EnableAllHotkey()
        Gosub, EnableHotkey
        SetTimer, UpdateApps, On
        BlockInput, Off
    }
    else if (Not (SteamBigPictureExist())) && (TaskbarAlreadyMoved == True)
        TaskbarAlreadyMoved := False

    return
;
UpdateGameSetting:
    if (UpdateNewGameSetting) {
        PathToAppList := A_ScriptDir "\AppList.txt"
        UpdateGameSettings(PathToAppList, CurrentlyRunningGameClass)
        UpdateNewGameSetting := False
    }

    return
;
UpdateAudio:
    if (SteamBigPictureExist()) {

        if (SteamAudioSwitch == False) {

            SetDefaultPlaybackOutput(DefaultOutputDevice)
            SetProcessOutput(TargetOutputDevice, STEAM_PROCESS)
            SteamAudioSwitch := True
        }

        if (UpdateNewGameAudio) {
            ; Set default playback to target first, change the app playback, then set to default playback output. It works this way because idk Windows.
            SetDefaultPlaybackOutput(TargetOutputDevice)

            Sleep, 7000 ; Workaround for some games
            SetAppOutputThenSwitchDefaultOutput(TargetOutputDevice, CurrentlyRunningGameProcess, DefaultOutputDevice)

            UpdateNewGameAudio := False
        }

    }
    else {
        if (SteamAudioSwitch == True) {

            Sleep, 10000
            SetDefaultPlaybackOutput(DefaultOutputDevice)
            SetDefaultProcessOutput(STEAM_PROCESS)
            SteamAudioSwitch := False
        }
    }
    return
;
UpdateGame:
    ; Detect new game

    TempCurrentlyRunningGameProcess := GetRunningGame()

    if (TempCurrentlyRunningGameProcess == 0) {
        CurrentlyRunningGameClass := ""
        CurrentlyRunningGameProcess := ""
        return
    }
        
    TempCurrentlyRunningGameClass := GetProcessClass(TempCurrentlyRunningGameProcess)

    if (TempCurrentlyRunningGameClass == 0)
        return

    if (TempCurrentlyRunningGameClass != CurrentlyRunningGameClass) { ;Check if new game is launched
        CurrentlyRunningGameProcess := TempCurrentlyRunningGameProcess
        CurrentlyRunningGameClass := TempCurrentlyRunningGameClass
        UpdateNewGameAudio := True
        UpdateNewGameSetting := True
    }

    return

;
UpdateApps:
    if (not (SteamBigPictureExist())) && (NumAppAt(3560,-40) > 0) {
        if (MonitorOnlyHaveSteamAndGame)
            MoveAppOut(3560, -40, 0)
    }
    else if (SteamBigPictureExist())  {
        if (not (SteamLaunched))
            SteamLaunched := True

        if (NumAppAt(-40,-40) > 0) {
            Gosub, UpdateGame
            if (MonitorOnlyHaveSteamAndGame)
                MoveAppOut(-40,-40, CurrentlyRunningGameClass)
        }
        else
            Gosub, UpdateGame

    }
    else if (not (SteamBigPictureExist())) && (SteamLaunched) {
	WinClose, ahk_exe %STEAM_PROCESS%
        SteamLaunched := False
        CurrentlyRunningGameClass := ""
        CurrentlyRunningGameProcess := ""
        UpdateNewGameAudio := False
        UpdateNewGameSetting := False
    }

    return
;
;
ExitSteam:
    if (SteamBigPictureExist()) {

        if (IsGameExist(CurrentlyRunningGameClass)) {
            Game := GetGame(CurrentlyRunningGameClass)
            WinKill, ahk_class %Game%
        }

        WinKill, ahk_class %STEAM_CLASS%
        return
    }
    

;
SaveDesktopIcon:
    ;Renew desktop icon coordinate every x minutes (default: 3 min)
    DesktopIconData := DesktopIcons()

    return
