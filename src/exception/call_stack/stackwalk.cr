require "c/dbghelp"

struct Exception::CallStack
  skip(__FILE__)

  @@history_table : LibC::UNWIND_HISTORY_TABLE = LibC::UNWIND_HISTORY_TABLE.new

  def self.unwind
    {% begin %}
    LibC.RtlCaptureContext(out context)

    # configure stackframe
    stackframe = LibC::STACKFRAME64.new
    stackframe.addrPC.mode      = LibC::ADDRESS_MODE::AddrModeFlat
    stackframe.addrFrame.mode   = LibC::ADDRESS_MODE::AddrModeFlat
    stackframe.addrStack.mode   = LibC::ADDRESS_MODE::AddrModeFlat

    {% if flag?(:x86_64) %}
      machine_type = LibC::IMAGE_FILE_MACHINE_AMD64

      stackframe.addrPC.offset = context.rip
      stackframe.addrFrame.offset = context.rsp
      stackframe.addrStack.offset = context.rsp
    {% elsif flag?(:i386) %}
      machine_type = LibC::IMAGE_FILE_MACHINE_I386

      stackframe.addrPC.offset = context.eip
      stackframe.addrFrame.offset = context.ebp
      stackframe.addrStack.offset = context.esp
    {% else %}
      {% raise "architecture not supported" %}
    {% end %}

    process = LibC.GetCurrentProcess
    thread = LibC.GetCurrentThread

    # initialize dbghelp symbol API
    if 0 == LibC.SymInitializeW(process, nil, 1)
      puts "loool"
      raise RuntimeError.from_errno("SymInitializeW")
    end

    stacktrace = [] of Void*
    loop do
      LibC.SetLastError(0)
      ret = LibC.StackWalk64(
        machine_type, process, thread,
        pointerof(stackframe), pointerof(context),
        nil, nil, nil, nil)
        # nil, ->(hProcess, addrBase) do
        #   LibC.RtlLookupFunctionEntry(addrBase, out image_base, pointerof(@@history_table)).try(&.as(Pointer(Void))) ||
        #     LibC.SymFunctionTableAccess64(hProcess, addrBase)
        # end, ->(hProcess, dwAddr) do
        #   if LibC.RtlLookupFunctionEntry(dwAddr, out image_base, pointerof(@@history_table))
        #     image_base
        #   else
        #     LibC.SymGetModuleBase64(hProcess, dwAddr)
        #   end
        # end, nil)
      break if ret.zero?

      function_address = stackframe.addrPC.offset
      break if function_address.zero? || function_address == stackframe.addrReturn.offset || stackframe.addrReturn.offset.zero?
      # TODO: Rust subtracts 1, don't know why
      stacktrace << (function_address - 1).unsafe_as(Pointer(Void))
    end

    stacktrace
    {% end %}
  end

  def decode_backtrace
    process = LibC.GetCurrentProcess
    thread = LibC.GetCurrentThread

    if 0 == LibC.SymSetOptions(LibC::SYMOPT_LOAD_LINES)
      raise RuntimeError.from_errno("SymSetOptions")
    end

    backtrace = [] of String

    @callstack.each do |function_address|
      module_base = LibC.SymGetModuleBase64(process, function_address.address)
      module_buffer = uninitialized UInt16[128]
      name_size = LibC.GetModuleFileNameW(module_base.unsafe_as(LibC::HMODULE), module_buffer, module_buffer.size)
      if module_base != 0 && name_size != 0
        module_name = Path.new(String.from_utf16(module_buffer.to_slice[0, name_size])).basename
      end

      symbol_buffer = uninitialized UInt8[287] # sizeof(LibC::IMAGEHLP_SYMBOL64) + 255
      symbol = symbol_buffer.unsafe_as(LibC::IMAGEHLP_SYMBOL64)
      symbol.sizeOfStruct = symbol_buffer.size
      symbol.maxNameLength = 254

      if 0 != LibC.SymGetSymFromAddr64(process, function_address.address, nil, pointerof(symbol))
        function_name = String.new(symbol.name.to_unsafe)
      end

      offset = 0_u32
      line = LibC::IMAGEHLP_LINEW64.new
      line.sizeOfStruct = sizeof(LibC::IMAGEHLP_LINEW64)
      if 0 != LibC.SymGetLineFromAddrW64(process, function_address.address, pointerof(offset), pointerof(line))
        file_name = String.from_utf16(line.fileName)[0]
        line_number = line.lineNumber
      end

      backtrace << "0x#{function_address.address.to_s(16).rjust(12, '0')} #{module_name || "???"}: #{function_name || "???"} in #{file_name || "???" }:#{line_number || 0}"
    end

    LibC.SymCleanup(process)

    backtrace
  end
end
