#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force

#Include %A_ScriptDir%\lib\Dropout\process.ahk
#Include %A_ScriptDir%\lib\Dropout\apps.ahk
#Include %A_ScriptDir%\lib\Dropout\script-helper.ahk
#Include %A_ScriptDir%\lib\Dropout\virtualization.ahk
#Include %A_ScriptDir%\lib\Dropout\quality-of-life.ahk
#Include %A_ScriptDir%\lib\SoundVolumeView\SoundVolumeView.ahk

/*
. This script is a best-effort approach to virtualize third virtual monitor. 
. Best-effort means it will try it best to seperate third monitor from the rest of the system, but it will not be perfect due to WinApi limitation
. This script works with assumption that Big Picture is used on rightmost monitor, which is primary monitor when launched
. There is only three Apps running on rightmost monitor, first is Steam Big Picture, Windows Tray and the game

Script work:
	- When script activated before starting Big Picture
	- When script activated after starting Big Picture
	- Changed default USB controller to iPega
    - Script doesn't work if default Windows Controller is not iPega before starting Big Picture

Note:
    - KillApp will work better if the script is run as admin (terminate hanging game if issue happens)

*/
STEAM_CLASS := "CUIEngineWin32"
CurrentlyRunningGame := ""
CurrentlyRunningGameProcess := ""
AlreadyMoved := False
SteamStarted := False

DesktopIconData := DesktopIcons()
Menu, Tray, Add , &Exit Steam, ExitSteam

DefaultOutputDevice := """Realtek High Definition Audio\Device\Speakers\Render"""
TargetOutputDevice := """VB-Audio Virtual Cable\Device\CABLE Input\Render"""

SetTimer, SwitchPrimaryTaskbarToFirstDisplay, 3000
SetTimer, SaveDesktopIcon, 180000
SetTimer, MoveOtherAppToPrimary, 1000
SetTimer, UpdateAudio, 3000

return

EnableHotkey:

Joy1::
App := GetApp()
ActivateApp(App)
SteamOverlay()
return 

Joy2::
App := GetApp()
ActivateApp(App)
ResetController(App)
return 

Joy3::
App := GetApp()
ActivateApp(App)
KillGame(App)
return 

Joy4::
App := GetApp()
ActivateApp(App)
return

SwitchPrimaryTaskbarToFirstDisplay:

    If (SteamBigPictureExist()) && (AlreadyMoved == False) {
        Steam := "CUIEngineWin32"

        BlockInput, On
        DisableAllHotkey()
	    Sleep, 200

        MovePrimaryTaskbar()
        AlreadyMoved := True
        DesktopIcons(DesktopIconData)
        ActivateApp(Steam)

        EnableAllHotkey()
        BlockInput, Off
    }
    else if (Not (SteamBigPictureExist())) && (AlreadyMoved == True)
        AlreadyMoved := False

    return
;
UpdateAudio:
    if (SteamBigPictureExist()) {
        if (SteamStarted == False) {
            steamProcess := "steam.exe"

            SetDefaultPlaybackOutput(DefaultOutputDevice)
            SetProcessOutput(TargetOutputDevice, steamProcess)
            SteamStarted := True
        }
    }
    else {
        if (SteamStarted == True) {
            steamProcess := "steam.exe"

            Sleep, 5000
            SetDefaultPlaybackOutput(DefaultOutputDevice)
            SetDefaultProcessOutput(steamProcess)
            SteamStarted := False
        }
    }
    return

UpdateGame() {
    ; Detect and return game class if launched, also move the game to the left if specified in Applist.txt
    global SteamStarted
    global CurrentlyRunningGame
    global CurrentlyRunningGameProcess
    global TargetOutputDevice
    global DefaultOutputDevice

    if (SteamBigPictureExist()) {

        TempCurrentlyRunningGameProcess := GetRunningGame()

        if (TempCurrentlyRunningGameProcess == 0) {
            CurrentlyRunningGame := ""
            CurrentlyRunningGameProcess := ""
            return
        }
            

        TempCurrentlyRunningGame := GetProcessClass(TempCurrentlyRunningGameProcess)

        if (TempCurrentlyRunningGame != CurrentlyRunningGame) {
            
            if (CurrentlyRunningGame != "") { ; Reset old app audio
                SetDefaultProcessOutput(CurrentlyRunningGameProcess)
            }

            CurrentlyRunningGameProcess := TempCurrentlyRunningGameProcess
            CurrentlyRunningGame := TempCurrentlyRunningGame
            
            MoveAppToLeft(CurrentlyRunningGame)

            ;Set audio
            SetDefaultPlaybackOutput(TargetOutputDevice)
            SetProcessOutput(TargetOutputDevice, CurrentlyRunningGameProcess)
            SetDefaultPlaybackOutput(DefaultOutputDevice)
        }
        ;
    } 
    else {
        CurrentlyRunningGame := ""
        CurrentlyRunningGameProcess := ""
    }
        
    
    return
}

MoveAppToLeft(AppClass) {
    PathToAppList := A_ScriptDir "\AppList.txt"
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


MoveOtherAppToPrimary:

    if (NumAppAt(3560,-40) > 0) && (not (SteamBigPictureExist())) {
        TempAppsClasses := GrabAllAppAt(3560,-40)
        
        for index, TempAppClass in TempAppsClasses {
            
            WinActivate, ahk_class %TempAppClass%
            SendWinShiftRight()
        }
    }
    else if (SteamBigPictureExist()) {
        TempAppsClass := GrabAllAppAt(-40,-40)
        UpdateGame()

        if (TempAppsClass == 0)
            return
        
        TempGameClass := GetGame() 

        for index, TempAppClass in TempAppsClass
        {
            if (TempAppClass == TempGameClass) {
                Continue
            }
                
            WinActivate, ahk_class %TempAppClass%
            SendWinShiftRight()
        }
    }

    return


ExitSteam:
    if (SteamBigPictureExist()) {

        if (IsGameExist()) {
            Game := GetGame()
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
