lib LibC
  alias BOOLEAN = BYTE
  alias LONG = Int32

  alias CHAR = UChar
  alias WCHAR = UInt16
  alias LPSTR = CHAR*
  alias LPWSTR = WCHAR*
  alias LPWCH = WCHAR*

  alias HANDLE = Void*
  alias HMODULE = Void*

  INVALID_FILE_ATTRIBUTES      = DWORD.new!(-1)
  FILE_ATTRIBUTE_DIRECTORY     =  0x10
  FILE_ATTRIBUTE_READONLY      =   0x1
  FILE_ATTRIBUTE_REPARSE_POINT = 0x400

  FILE_READ_ATTRIBUTES  =   0x80
  FILE_WRITE_ATTRIBUTES = 0x0100

  # Memory protection constants
  PAGE_READWRITE = 0x04

  PROCESS_QUERY_LIMITED_INFORMATION =     0x1000
  SYNCHRONIZE                       = 0x00100000

  DUPLICATE_CLOSE_SOURCE = 0x00000001
  DUPLICATE_SAME_ACCESS  = 0x00000002

  {% if flag?(:x86_64) %}
    CONTEXT_AMD64    = 0x00100000i64

    CONTEXT_CONTROL         = CONTEXT_AMD64 | 0x00000001i64
    CONTEXT_INTEGER         = CONTEXT_AMD64 | 0x00000002i64
    CONTEXT_SEGMENTS        = CONTEXT_AMD64 | 0x00000004i64
    CONTEXT_FLOATING_POINT  = CONTEXT_AMD64 | 0x00000008i64
    CONTEXT_DEBUG_REGISTERS = CONTEXT_AMD64 | 0x00000010i64

    CONTEXT_FULL            = CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_FLOATING_POINT
  {% elsif flag?(:i386) %}
    CONTEXT_i386   = 0x00010000i64
    CONTEXT_i486   = 0x00010000i64

    CONTEXT_CONTROL             = CONTEXT_i386 | 0x00000001i64
    CONTEXT_INTEGER             = CONTEXT_i386 | 0x00000002i64
    CONTEXT_SEGMENTS            = CONTEXT_i386 | 0x00000004i64
    CONTEXT_FLOATING_POINT      = CONTEXT_i386 | 0x00000008i64
    CONTEXT_DEBUG_REGISTERS     = CONTEXT_i386 | 0x00000010i64
    CONTEXT_EXTENDED_REGISTERS  = CONTEXT_i386 | 0x00000020i64

    CONTEXT_FULL = CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS
  {% end %}


  union CONTEXTU
    # fltSave : XMM_SAVE_AREA32
    #        q : NEON128[16]
    #      d : ULONGLONG[32]
    #      # struct
    s : DWORD[32]
  end

  struct M128A
    low : UInt64
    high : Int64
  end

  struct CONTEXT
    p1Home : DWORD64
    p2Home : DWORD64
    p3Home : DWORD64
    p4Home : DWORD64
    p5Home : DWORD64
    p6Home : DWORD64
    contextFlags : DWORD
    mxCsr : DWORD
    segCs : WORD
    segDs : WORD
    segEs : WORD
    segFs : WORD
    segGs : WORD
    segSs : WORD
    eFlags : DWORD
    dr0 : DWORD64
    dr1 : DWORD64
    dr2 : DWORD64
    dr3 : DWORD64
    dr6 : DWORD64
    dr7 : DWORD64
    rax : DWORD64
    rcx : DWORD64
    rdx : DWORD64
    rbx : DWORD64
    rsp : DWORD64
    rbp : DWORD64
    rsi : DWORD64
    rdi : DWORD64
    r8 : DWORD64
    r9 : DWORD64
    r10 : DWORD64
    r11 : DWORD64
    r12 : DWORD64
    r13 : DWORD64
    r14 : DWORD64
    r15 : DWORD64
    rip : DWORD64
    u : CONTEXTU
    vectorRegister : M128A[26]
    vectorControl : DWORD64
    debugControl : DWORD64
    lastBranchToRip : DWORD64
    lastBranchFromRip : DWORD64
    lastExceptionToRip : DWORD64
    lastExceptionFromRip : DWORD64
  end

  fun RtlCaptureContext(contextRecord : CONTEXT*) : Void
  fun __current_exception_context : CONTEXT

  union RUNTIME_FUNCTIONU
    unwindInfoAddress : DWORD
    unwindData : DWORD
  end

  struct RUNTIME_FUNCTION
    beginAddress : DWORD
    endAddress : DWORD
    u : RUNTIME_FUNCTIONU
  end

  struct UNWIND_HISTORY_TABLE
    imageBase : DWORD64
    functionEntry : RUNTIME_FUNCTION*
  end

  fun RtlLookupFunctionEntry(controlPc : DWORD64, imageBase : DWORD64*, historyTable : UNWIND_HISTORY_TABLE*) : RUNTIME_FUNCTION*
end
