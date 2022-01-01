/* 
Example usage

Device := """NVIDIA High Definition Audio\Device\PHL 241V8\Render"""
TestApp := """Discord.exe"""
SetProcessOutput(Device, TestApp)
*/

GetSoundViewPath() {
    Path := "\lib\SoundVolumeView\SoundVolumeView.exe"
    Path := A_ScriptDir Path
    ;verify program exist
    return Path
}

SetDefaultPlaybackOutput(outputDevice) {
    path := GetSoundViewPath()
    RunWait, %ComSpec% /c %path% /SetDefault %outputDevice% all, , Hide
}

SetDefaultProcessOutput(targetProcess) {
    path := GetSoundViewPath()
    RunWait, %ComSpec% /c %path% /SetAppDefault DefaultRenderDevice all %targetProcess%, , Hide
}

SetProcessOutput(outputDevice, targetProcess) {
    path := GetSoundViewPath()
    cmd := path " /Unmute " targetProcess " /WaitForItem 12 && " path " /SetAppDefault " outputDevice " all " targetProcess
    Run, %ComSpec% /k %cmd%, , Hide
}

SetAppOutputThenSwitchDefaultOutput(outputDevice, targetProcess, switchDevice) {
    path := GetSoundViewPath()
    WaitCmd := path " /Unmute " targetProcess " /WaitForItem 12 && " 
    DefaultCmd := path " /SetAppDefault " outputDevice " all " targetProcess " && "
    SwitchCmd := path " /SetDefault " switchDevice " all "
    cmd := WaitCmd DefaultCmd SwitchCmd

    Run, %ComSpec% /k %cmd%, , Hide
}


DisableOutputDevice(outputDevice) {
    path := GetSoundViewPath()
    RunWait, %ComSpec% /c %path% /Disable %outputDevice%, , Hide
}

EnableOutputDevice(outputDevice) {
    path := GetSoundViewPath()
    RunWait, %ComSpec% /c %path% /Enable %outputDevice%, , Hide
}
