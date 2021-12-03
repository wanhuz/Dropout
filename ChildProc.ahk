
/* Example
WinGet, ProcessID, PID, ahk_exe steam.exe

ChildProc := GetChildProcessName(ProcessID)

for each, proc in ChildProc {
    MsgBox % proc
}
*/

GetChildProcessName(ProcessID) {
    ChildProcessesName := []

    For Each, Obj In EnumerateChilds(ProcessID)  {
        Title := GetProcessName(Obj)
        ChildProcessesName.Push(Title)
    }

    return ChildProcessesName[1] ? ChildProcessesName : 0
}

GetChildProcessCount(ProcessID) {
    CountChild := 0

    For Each, Obj In EnumerateChilds(ProcessID)  {
        CountChild := CountChild + 1
    }

    return CountChild
}

EnumerateChilds(PID) {
   static MAX_PATH := 260
   childs := []
   hSnap := DllCall("CreateToolhelp32Snapshot", UInt, TH32CS_SNAPPROCESS := 2, UInt, 0, Ptr)
   VarSetCapacity(PROCESSENTRY32, sz := 4*7 + A_PtrSize*2 + MAX_PATH << !!A_IsUnicode, 0)
   NumPut(sz, PROCESSENTRY32, "UInt")
   DllCall("Process32First", Ptr, hSnap, Ptr, &PROCESSENTRY32)
   Loop {
      parentPID := NumGet(PROCESSENTRY32, 4*4 + A_PtrSize*2, "UInt")
      if (parentPID = PID)
         childs.Push( NumGet(PROCESSENTRY32, 4*2, "UInt") )
   } until !DllCall("Process32Next", Ptr, hSnap, Ptr, &PROCESSENTRY32)
   DllCall("CloseHandle", Ptr, hSnap)
   Return childs[1] ? childs : ""
}

GetProcessName(PID) {
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