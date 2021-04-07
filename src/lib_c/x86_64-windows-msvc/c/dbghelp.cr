@[Link("dbghelp")]
lib LibC
  IMAGE_FILE_MACHINE_I386  = 0x014c
  IMAGE_FILE_MACHINE_IA64  = 0x0200
  IMAGE_FILE_MACHINE_AMD64 = 0x8664

  enum ADDRESS_MODE
    AddrMode1616 = 0
    AddrMode1632 = 1
    AddrModeReal = 2
    AddrModeFlat = 3
  end

  struct ADDRESS64
    offset : DWORD64
    segment : WORD
    mode : ADDRESS_MODE
  end

  struct KDHELP64
    thread : DWORD64
    thCallbackStack : DWORD
    thCallbackBStore : DWORD
    nextCallback : DWORD
    framePointer : DWORD
    kiCallUserMode : DWORD64
    keUserCallbackDispatcher : DWORD64
    systemRangeStart : DWORD64
    kiUserExceptionDispatcher : DWORD64
    stackBase : DWORD64
    stackLimit : DWORD64
    buildVersion : DWORD
    retpolineStubFunctionTableSize : DWORD
    retpolineStubFunctionTable : DWORD64
    retpolineStubOffset : DWORD
    retpolineStubSize : DWORD
    reserved0 : DWORD64[2]
  end

  struct STACKFRAME64
    addrPC : ADDRESS64
    addrReturn : ADDRESS64
    addrFrame : ADDRESS64
    addrStack : ADDRESS64
    addrBStore : ADDRESS64
    funcTableEntry : Void*
    params : DWORD64[4]
    far : BOOL
    virtual : BOOL
    reserved : DWORD64[3]
    kdHelp : KDHELP64
  end

  # (hProcess : HANDLE, qwBaseAddress : DWORD64, lpBuffer : Void*, nSize : DWORD, lpNumberOfBytesRead : DWORD*) -> Bool
  alias PREAD_PROCESS_MEMORY_ROUTINE64 = Proc(HANDLE, DWORD64, Void*, DWORD, DWORD*, Bool)

  alias PFUNCTION_TABLE_ACCESS_ROUTINE64 = Proc(HANDLE, DWORD64, Void*)
  fun SymFunctionTableAccess64(hProcess : HANDLE, addrBase : DWORD64) : Void*

  alias PGET_MODULE_BASE_ROUTINE64 = Proc(HANDLE, DWORD64, DWORD64)
  fun SymGetModuleBase64(hProcess : HANDLE, addrBase : DWORD64) : DWORD64

  # (hProcess : HANDLE, hThread : HANDLE, lpaddr : ADDRESS64) -> DWORD64
  alias PTRANSLATE_ADDRESS_ROUTINE64 = Proc(HANDLE, HANDLE, ADDRESS64*, DWORD64)

  fun StackWalk64(
    machineType : DWORD,
    hProcess : HANDLE,
    hThread : HANDLE,
    stackFrame : STACKFRAME64*,
    contextRecord : Void*,
    readMemoryRoutine : PREAD_PROCESS_MEMORY_ROUTINE64,
    functionTableAccessRoutine : PFUNCTION_TABLE_ACCESS_ROUTINE64,
    getModuleBaseRoutine : PGET_MODULE_BASE_ROUTINE64,
    translateAddress : PTRANSLATE_ADDRESS_ROUTINE64
  ) : BOOL

  fun SymInitializeW(
    hProcess : HANDLE,
    userSearchPath : WCHAR*,
    fInvadeProcess : BOOL
  ) : BOOL

  SYMOPT_LOAD_LINES = 0x00000010

  fun SymSetOptions(symOptions : DWORD) : DWORD

  struct IMAGEHLP_SYMBOL64
    sizeOfStruct : DWORD
    address : DWORD64
    size : DWORD
    flags : DWORD
    maxNameLength : DWORD
    name : CHAR[1]
  end

  fun SymGetSymFromAddr64(
    hProcess : HANDLE,
    qwAddr : DWORD64,
    pdwDisplacement : DWORD64*,
    symbol : IMAGEHLP_SYMBOL64*
  ) : BOOL

  struct IMAGEHLP_LINEW64
    sizeOfStruct : DWORD
    key : Void*
    lineNumber : DWORD
    fileName : WCHAR*
    address : DWORD64
  end

  fun SymGetLineFromAddrW64(
    hProcess : HANDLE,
    dwAddr : DWORD64,
    pdwDisplacement : DWORD*,
    line : IMAGEHLP_LINEW64*
  ) : BOOL

  fun SymCleanup(hProcess : HANDLE) : BOOL
end
