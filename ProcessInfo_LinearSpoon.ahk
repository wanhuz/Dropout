; scriptPID := GetCurrentProcess()
; scriptEXE := GetProcessName(scriptPID)
; parentPID := GetParentProcess(scriptPID)
; parentEXE := GetProcessName(parentPID)
; Msgbox % "Script PID: " scriptPID "`nScript executable: " scriptEXE "`nParent PID: " parentPID "`nParent executable: " parentEXE


GetParentProcess(PID)
{
  static function := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "kernel32.dll", "ptr"), "astr", "Process32Next" (A_IsUnicode ? "W" : ""), "ptr")
  if !(h := DllCall("CreateToolhelp32Snapshot", "uint", 2, "uint", 0))
    return
  VarSetCapacity(pEntry, sz := (A_PtrSize = 8 ? 48 : 36)+(A_IsUnicode ? 520 : 260))
  Numput(sz, pEntry, 0, "uint")
  DllCall("Process32First" (A_IsUnicode ? "W" : ""), "ptr", h, "ptr", &pEntry)
  loop
  {
    if (pid = NumGet(pEntry, 8, "uint") || !DllCall(function, "ptr", h, "ptr", &pEntry))
      break
  }
  DllCall("CloseHandle", "ptr", h)
  return Numget(pEntry, 16+2*A_PtrSize, "uint")
}

GetProcessName(PID)
{
  static function := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "kernel32.dll", "ptr"), "astr", "Process32Next" (A_IsUnicode ? "W" : ""), "ptr")
  if !(h := DllCall("CreateToolhelp32Snapshot", "uint", 2, "uint", 0))
    return
  VarSetCapacity(pEntry, sz := (A_PtrSize = 8 ? 48 : 36)+260*(A_IsUnicode ? 2 : 1))
  Numput(sz, pEntry, 0, "uint")
  DllCall("Process32First" (A_IsUnicode ? "W" : ""), "ptr", h, "ptr", &pEntry)
  loop
  {
    if (pid = NumGet(pEntry, 8, "uint") || !DllCall(function, "ptr", h, "ptr", &pEntry))
      break
  }
  DllCall("CloseHandle", "ptr", h)
  return StrGet(&pEntry+28+2*A_PtrSize, A_IsUnicode ? "utf-16" : "utf-8")
}

GetCurrentProcess()
{
  return DllCall("GetCurrentProcessId")
}
