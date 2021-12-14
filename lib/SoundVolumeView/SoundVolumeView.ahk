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
    RunWait, %ComSpec% /c %path% /SetAppDefault %outputDevice% all %targetProcess%, , Hide
}

