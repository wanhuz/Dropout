#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#Include ChildProc.ahk
#Include EnumProc.ahk
#Include %A_ScriptDir%\lib\SoundVolumeView\SoundVolumeView.ahk

/*
Version History:
15/11/21 - Improved moving taskbar
18/11/21 - Fix existing folder explorer starting at Monitor 3
19/11/21 - Add Tray menu to exit Steam Big Picture and Game from Desktop
19/11/21 - Save and load original monitor desktop icon location

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

Key Mapping for iPega 9083s Android Mode

      _=====_                               _=====_
     / __7__ \                             / __8__ \
   +.-'__5__'-.---------------------------.-'__6__'-.+
  /   |     |  '.        iPEGA          .'  |  _  |   \
 / ___| /|\ |___ \                     / ___| /4\ |___ \
/ |      |      | ;  __           _   ; | _         _ | ;
| | <---   ---> | | |14|         |10| | ||1|       (3)| |
| |___   |   ___| ;SELECT       START ; |___       ___| ;
|\    | \|/ |    /  _     ___      _   \    | (2) |    /|
| \   |_____|  .','" "', |___|  ,'" "', '.  |_____|  .' |
|  '-.______.-' /       \ANALOG/       \  '-._____.-'   |
|               |       |------|       |                |
|              /\       /      \       /\               |
|             /  '.___.'        '.___.'  \              |
|            /                            \             |
 \          /                              \           /
  \________/                                \_________/

*/
STEAM_CLASS := "CUIEngineWin32"
CurrentlyRunningGame := ""
CurrentlyRunningGameProcess := ""

DesktopIconData := DesktopIcons()
Menu, Tray, Add , &Exit Steam, ExitSteam
AlreadyMoved := False
SteamStarted := False
GameStarted := False
DefaultOutputDevice := """Realtek High Definition Audio\Device\Speakers\Render"""
TargetOutputDevice := """VB-Audio Virtual Cable\Device\CABLE Input\Render"""

;SetTimer, SwitchPrimaryTaskbarToFirstDisplay, 3000
SetTimer, SaveDesktopIcon, 180000
SetTimer, UpdateGame, 3000

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

; Building block function
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

ProcessExist(Name){
	Process,Exist,%Name%
	return Errorlevel
}

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
DisableAllHotkey() {
    Hotkey, Joy1, Off
    Hotkey, Joy2, Off
    Hotkey, Joy3, Off
    Hotkey, Joy4, Off
}

EnableAllHotkey() {
    Hotkey, Joy1, On
    Hotkey, Joy2, On
    Hotkey, Joy3, On
    Hotkey, Joy4, On
    Gosub, EnableHotkey
}

ResetExplorer() {
    
    ; Get a list of all opened explorer windows:
    If WinExist("ahk_class CabinetWClass") ; explorer
    {
        list := ""
        ; https://autohotkey.com/boards/viewtopic.php?p=28751#p28751
        for window in ComObjCreate("Shell.Application").Windows
        {
            explorer_path := ""
            try explorer_path := window.Document.Folder.Self.Path 
            list .= explorer_path ? explorer_path "`n" : "" 
        }
        list := trim(list, "`n")
    }

    RunWait, %comspec% /c taskkill /f /im explorer.exe ,,hide
    Process, WaitClose, explorer.exe

    ; We can now restart the Explorer.exe Process:
    Run, explorer.exe
    
    ; open all explorer windows we had open previously:
    If (list != "")
    {
        Process, wait, explorer.exe
        Loop, parse, list, "`n" 
        {
            Run %A_LoopField% 
	        SplitPath, A_LoopField, name
            WinWaitActive, %name%
            SendCtrlWinRight()
        }
    }
}

SendCtrlWinRight() {
    Send, {LWin down}{LShift down}{Right down}
	Send, {LWin up}{LShift up}{Right up}
    Sleep, 100
}

SendWinShiftLeft() {
    Send {LWin down}{LShift down}
    Send {Left}
    Send {LWin up}{LShift up}
    Sleep, 100
}

DesktopIcons(coords="") {
   ;Return desktop icon location if no parameter is given. Else, restore using parameter data.
   ;Credit to Rolz on AHK forum

   Critical
   static MEM_COMMIT := 0x1000, PAGE_READWRITE := 0x04, MEM_RELEASE := 0x8000
   static LVM_GETITEMPOSITION := 0x00001010, LVM_SETITEMPOSITION := 0x0000100F, WM_SETREDRAW := 0x000B
   
   ControlGet, hwWindow, HWND,, SysListView321, ahk_class Progman
   if !hwWindow ; #D mode
      ControlGet, hwWindow, HWND,, SysListView321, ahk_class WorkerW
   IfWinExist ahk_id %hwWindow% ; last-found window set
      WinGet, iProcessID, PID
   hProcess := DllCall("OpenProcess"   , "UInt",   0x438         ; PROCESS-OPERATION|READ|WRITE|QUERY_INFORMATION
                              , "Int",   FALSE         ; inherit = false
                              , "UInt",   iProcessID)
   if hwWindow and hProcess
   {   
      ControlGet, list, list, Col1 ; Icons names
      ControlGet, list2, list, Col2 ; Icons types
      ControlGet, list5, list, Col5 ; Icons creation dates
      Loop, Parse, list2, `n
         filetype_%A_Index% := A_LoopField
      Loop, Parse, list5, `n
         cr_date_%A_Index% := A_LoopField
      if !coords
      {
         VarSetCapacity(iCoord, 16)
         pItemCoord := DllCall("VirtualAllocEx", "UInt", hProcess, "UInt", 0, "UInt", 8, "UInt", MEM_COMMIT, "UInt", PAGE_READWRITE)
         Loop, Parse, list, `n
         {
            SendMessage, %LVM_GETITEMPOSITION%, % A_Index-1, %pItemCoord%
            DllCall("ReadProcessMemory", "UInt", hProcess, "UInt", pItemCoord, "UInt64", &iCoord, "UInt", 16, "UIntP", cbReadWritten)
            iconid := A_LoopField . "(" . filetype_%A_Index% . "," . cr_date_%A_Index% . ")"
            ret .= iconid ":" (NumGet(iCoord) & 0xFFFF) | ((Numget(iCoord, 4) & 0xFFFF) << 16) "`n"
         }
         DllCall("VirtualFreeEx", "UInt", hProcess, "UInt", pItemCoord, "UInt", 0, "UInt", MEM_RELEASE)
      }
      else
      {
         SendMessage, %WM_SETREDRAW%,0,0
         Loop, Parse, list, `n
         {
            iconid := A_LoopField . "(" . filetype_%A_Index% . "," . cr_date_%A_Index% . ")"
            If RegExMatch(coords,"\Q" iconid "\E:\K.*",iCoord_new)
               SendMessage, %LVM_SETITEMPOSITION%, % A_Index-1, %iCoord_new%
         }
         SendMessage, %WM_SETREDRAW%,1,0
         ret := true
      }
   }
   DllCall("CloseHandle", "UInt", hProcess)
   return ret
}

DetectRunningGame() { 
    WinGet, SteamProcPID, PID, ahk_exe steam.exe

    SteamChildProc := GetChildProcessName(SteamProcPID)

    GameProc := ""
    for each, proc in SteamChildProc {
        
        if (proc != "steamwebhelper.exe") && (proc != "steamservice.exe") && (proc != "GameOverlayUi.exe") && (proc != "steamerrorreporter.exe") {
            GameProc := proc
        }
            
    }

    if (GameProc == "") {
        ;MsgBox % "DropOut: Error in retrieving game process: " GameProc "." 
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

GetProcessClass(ProcName) {
        WinGetClass, ProcClass, ahk_exe %ProcName%

        if (ProcClass == "") { 
            ;MsgBox % "DropOut: Error in retrieving game class: " ProcName "." 
            return ""
        }

        return ProcClass
}


UpdateGame:
    if (SteamBigPictureExist()) {

        if (SteamStarted == False) {
            steamProcess := "steam.exe"

            SetDefaultPlaybackOutput(DefaultOutputDevice)
            SetProcessOutput(TargetOutputDevice, steamProcess)
            SteamStarted := True
        }
        ;
        TempCurrentlyRunningGameProcess := DetectRunningGame()

        if (TempCurrentlyRunningGameProcess == 0)
            return

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
        if (SteamStarted == True) {
            steamProcess := "steam.exe"

            SetDefaultPlaybackOutput(DefaultOutputDevice)
            SetDefaultProcessOutput(steamProcess)
            SteamStarted := False
        }

        CurrentlyRunningGame := ""
        CurrentlyRunningGameProcess := ""
        
    }
        
    
    return
;
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

; QOL Function
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

MovePrimaryTaskbar() {
    ThreeMonitorFirstDisplayTaskbarKey := "30000000FEFFFFFF02800000030000003E00000028000000F0F1FFFF1004000070F9FFFF380400006000000001000000"
    RegWrite, REG_BINARY, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3, Settings, %ThreeMonitorFirstDisplayTaskbarKey%

    Sleep, 100
    ResetExplorer()
}

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
;
