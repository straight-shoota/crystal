require "c/dlfcn"

class DL
  def self.dlopen(path, mode = LibC::RTLD_LAZY | LibC::RTLD_GLOBAL) : DL
    handle = LibC.dlopen(path, mode)

    unless handle
      message = String.new(LibC.dlerror)
      raise "Error loading dynamic library: #{message}"
    end

    new(handle)
  end

  protected def initialize(@handle : LibC::DL)
  end

  def finalize
    LibC.dlclose(@handle)
  end

  def symbol_address(symbol)
    LibC.dlsym(@handle, symbol)
  end

  def symbol?(symbol)
    ! symbol_address(symbol).null?
  end
end
