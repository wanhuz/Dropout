/* 
Example usage

Device := """NVIDIA High Definition Audio\Device\PHL 241V8\Render"""
TestApp := """Discord.exe"""
SetProcessOutput(Device, TestApp)
*/


SetDefaultPlaybackOutput(outputDevice) {
    RunWait, %ComSpec% /c SoundVolumeView.exe /SetDefault %outputDevice% all, , Hide
}

SetDefaultProcessOutput(targetProcess) {
    RunWait, %ComSpec% /c SoundVolumeView.exe /SetAppDefault DefaultRenderDevice all %targetProcess%, , Hide
}

SetProcessOutput(outputDevice, targetProcess) {
    RunWait, %ComSpec% /c SoundVolumeView.exe /SetAppDefault %outputDevice% all %targetProcess%, , Hide
}