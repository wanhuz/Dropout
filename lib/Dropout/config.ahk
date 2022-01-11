
LoadHotkeyConfig(ByRef EnableSteamOverlayHotkey, ByRef EnableSteamControllerResetHotkey, ByRef EnableExitGameHotkey) {
    confFilePath := A_ScriptDir "\Dropout.cfg"

    if !FileExist(confFilePath) {
	MsgBox % "Configuration file does not exist at " confFilePath ". Create from the template config_template.cfg or make sure the settings are correct."
        return
    }


    Loop, read, %confFilePath% 
    {
        Line := A_LoopReadLine
        Set := StrSplit(Line, " ")
        if (Set[1] == "enablesteamoverlayhotkey")
            Set[3] == "true" ? EnableSteamOverlayHotkey := True : EnableSteamOverlayHotkey := False
        else if (Set[1] == "enablesteamcontrollerresethotkey")
            Set[3] == "true" ? EnableSteamControllerResetHotkey := True : EnableSteamControllerResetHotkey := False
        else if (Set[1] == "enableexitgamehotkey")
            Set[3] == "true" ? EnableExitGameHotkey := True : EnableExitGameHotkey := False
    }
}

LoadVirtualizationConfig(ByRef EnableDefaultTaskbar, ByRef EnableDefaultDesktopIcon, ByRef MonitorOnlyHaveSteamAndGame, ByRef EnableAudioSeperation, ByRef IconDuration) {
    confFilePath := A_ScriptDir "\Dropout.cfg"

    if !FileExist(confFilePath) {
	MsgBox % "Configuration file does not exist at " confFilePath ". Create from the template config_template.cfg or make sure the settings are correct."
        return
    }


    Loop, read, %confFilePath% 
    {
        Line := A_LoopReadLine
        Set := StrSplit(Line, " ")

        if (Set[1] == "enabledefaulttaskbar")
            Set[3] == "true" ? EnableDefaultTaskbar := True : EnableDefaultTaskbar := False
        else if (Set[1] == "enabledefaultdesktopicon")
            Set[3] == "true" ? EnableDefaultDesktopIcon := True : EnableDefaultDesktopIcon := False
        else if (Set[1] == "monitoronlyhavesteamandgame")
            Set[3] == "true" ? MonitorOnlyHaveSteamAndGame := True : MonitorOnlyHaveSteamAndGame := False
        else if (Set[1] == "enableaudioseperation")
            Set[3] == "true" ? EnableAudioSeperation := True : EnableAudioSeperation := False
        else if (Set[1] == "savedesktopiconeverysecs") {
            if (Set[3] < 100000) ; Integer check
                IconDuration := Set[3]
            else
                IconDuration := 60
        }
    }
}