#Include %A_ScriptDir%\lib\Dropout\script-helper.ahk

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
            WinWaitActive, %name%,, 2
            if ErrorLevel
            {
                MoveAppOut(-40,-40, 0)
                Continue
            }
            SendWinShiftRight() ; Hacks, but this works so I guess keep it until it breaks or smth
        }
    }
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

MovePrimaryTaskbar() {
    ThreeMonitorFirstDisplayTaskbarKey := "30000000FEFFFFFF02800000030000003E00000028000000F0F1FFFF1004000070F9FFFF380400006000000001000000"
    RegWrite, REG_BINARY, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3, Settings, %ThreeMonitorFirstDisplayTaskbarKey%

    Sleep, 100
    ResetExplorer()
}
