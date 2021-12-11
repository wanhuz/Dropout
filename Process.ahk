
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

/*
    Retrieves a list with information of all the active processes in the system.
    Return:
        -2 = An error occurred while trying to retrieve a list of the active processes on the system.
        -1 = An error occurred while trying to retrieve information from the processes.
        [array] = Returns an Array with all processes if it was successful. Each index has an object with the following keys:
            ProcessId = The unique identifier of the process.
            ParentProcessId = The unique identifier of the parent process of this process, if it has one.
            ProcessName = The name of the process.
            Threads = The number of Threads started by this process.
    Example:
        For Each, Obj In EnumerateProcesses()
            List .= Obj.ProcessName . " [" . Obj.ProcessId . "]`n"
        MsgBox(List)
*/

GetProcessID(ProcessName) {
        For Each, Obj In EnumerateProcesses() 
        {
		List .= Obj.ProcessName . " [" . Obj.ProcessId . "]`n"
		if (Obj.ProcessName == ProcessName)
			return Obj.ProcessId
        }
}

EnumerateProcesses()
{
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms682489(v=vs.85).aspx
    Local hSnapshot := 0
    If ((hSnapshot := DLLCall("Kernel32.dll\CreateToolhelp32Snapshot", "UInt", 2, "UInt", 0, "Ptr")) == -1)    ; TH32CS_SNAPPROCESS = 2 | INVALID_HANDLE_VALUE = -1
        Return -1
    
    Local PROCESSENTRY32
    NumPut(VarSetCapacity(PROCESSENTRY32, A_PtrSize == 4 ? 556 : 568), &PROCESSENTRY32, "UInt")
    
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms684834(v=vs.85).aspx
    Local OutputVar := []
    If (DllCall("Kernel32.dll\Process32FirstW", "Ptr", hSnapshot, "UPtr", &PROCESSENTRY32))
        Loop
            OutputVar[A_Index] := {       ProcessId: NumGet(&PROCESSENTRY32 +                          8,   "UInt")
                                  , ParentProcessId: NumGet(&PROCESSENTRY32 + (A_PtrSize == 4 ? 24 : 32),   "UInt")
                                  ,     ProcessName: StrGet(&PROCESSENTRY32 + (A_PtrSize == 4 ? 36 : 44), "UTF-16")
                                  ,         Threads: NumGet(&PROCESSENTRY32 + (A_PtrSize == 4 ? 20 : 28),   "UInt") }
        ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms684836(v=vs.85).aspx
        Until (!DllCall("Kernel32.dll\Process32NextW", "Ptr", hSnapshot, "UPtr", &PROCESSENTRY32))
    
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms724211(v=vs.85).aspx
    DllCall("Kernel32.dll\CloseHandle", "Ptr", hSnapshot)

    Return ObjLength(OutputVar) ? OutputVar : FALSE
} ;https://msdn.microsoft.com/en-us/library/windows/desktop/ms684834(v=vs.85).aspx





/*
    typedef struct tagPROCESSENTRY32W
    {
        DWORD   dwSize;
        DWORD   cntUsage;
        DWORD   th32ProcessID;          // this process
        ULONG_PTR th32DefaultHeapID;
        DWORD   th32ModuleID;           // associated exe
        DWORD   cntThreads;
        DWORD   th32ParentProcessID;    // this process's parent process
        LONG    pcPriClassBase;         // Base priority of process's threads
        DWORD   dwFlags;
        WCHAR   szExeFile[MAX_PATH];    // Path
    } PROCESSENTRY32W;
    
    MAX_PATH = 260 bytes (520 bytes UTF-16)
    32-bit
        -- TYPE -    ------ NAME -------    -- SIZE -    - TOTAL -
            DWORD                 dwSize      4 bytes      4 bytes    #1
            DWORD               cntUsage      4 bytes      8 bytes    #2
            DWORD          th32ProcessID      4 bytes     12 bytes    #3
        ULONG_PTR      th32DefaultHeapID      4 bytes     16 bytes    #4
            DWORD           th32ModuleID      4 bytes     20 bytes    #5
            DWORD             cntThreads      4 bytes     24 bytes    #6
            DWORD    th32ParentProcessID      4 bytes     28 bytes    #7
             LONG         pcPriClassBase      4 bytes     32 bytes    #8
            DWORD                dwFlags      4 bytes     36 bytes    #9
            WCHAR    szExeFile[MAX_PATH]    520 bytes    556 bytes
    64-bit
        -- TYPE -    ------ NAME -------    -- SIZE -    - TOTAL -
            DWORD                 dwSize      4 bytes      4 bytes    #1
            DWORD               cntUsage      4 bytes      8 bytes    #1
            DWORD          th32ProcessID      4 bytes     12 bytes    #2
          PADDING                             4 bytes     16 bytes    #2
        ULONG_PTR      th32DefaultHeapID      8 bytes     24 bytes    #3
            DWORD           th32ModuleID      4 bytes     28 bytes    #4
            DWORD             cntThreads      4 bytes     32 bytes    #4
            DWORD    th32ParentProcessID      4 bytes     36 bytes    #5
             LONG         pcPriClassBase      4 bytes     40 bytes    #5
            DWORD                dwFlags      4 bytes     44 bytes    #6
          PADDING                             4 bytes     48 bytes    #6
            WCHAR    szExeFile[MAX_PATH]    520 bytes    568 bytes
*/


