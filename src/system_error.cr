# This module can be included in any `Exception` subclass that is
# used to wrap some system error (`Errno` or `WinError`)
#
# When included it provides a `from_errno` method (and `from_winerror` on Windows)
# to create exception instances with a description of the original error. It also
# adds an `os_error` property that contains the original system error.
#
# For example:
# ```
# class MyError < Exception
#   include SystemError
# end
#
# MyError.from_errno("Something happened")
# ```
module SystemError
  macro included
    extend ::SystemError::ClassMethods
  end

  # The original system error wrapped by this exception
  getter os_error : Errno | WinError | Nil

  # :nodoc:
  protected def os_error=(@os_error)
  end

  module ClassMethods
    # Builds an instance of the exception from an *os_error* value.
    #
    # The system message corresponding to the OS error value amends the *message*.
    # Additional keyword arguments are forwarded to the exception initializer.
    def from_os_error(message : String?, os_error : Errno | WinError | Nil, **opts)
      message = self.build_message(message, **opts)
      message =
        if message
          "#{message}: #{os_error_string(os_error)}"
        else
          os_error_string(os_error)
        end

      self.new_from_os_error(message, os_error, **opts).tap do |e|
        e.os_error = os_error
      end
    end

    protected def os_error_string(os_error : Errno | WinError | Nil)
      os_error.try &.message
    end

    # Builds an instance of the exception from a `Errno`.
    #
    # By default it takes the current `errno` value (see `Errno.value`).
    # The system message corresponding to the OS error value amends the *message*.
    # Additional keyword arguments are forwarded to the exception initializer.
    def from_errno(message : String, **opts)
      from_os_error(message, Errno.value, **opts)
    end

    @[Deprecated("Use `.from_os_error` instead")]
    def from_errno(message : String? = nil, errno : Errno = nil, **opts)
      from_os_error(message, errno, **opts)
    end

    # Prepare the message that goes before the system error description
    #
    # By default it returns the original message unchanged. But that could be
    # customized based on the keyword arguments passed to `from_errno` or `from_winerror`.
    protected def build_message(message, **opts)
      message
    end

    # Create an instance of the exception that wraps a system error
    #
    # This is a factory method and by default it creates an instance
    # of the current class. It can be overridden to generate different
    # classes based on the `errno` or keyword arguments.
    protected def new_from_os_error(message : String, os_error, **opts)
      self.new(message, **opts)
    end

    # Builds an instance of the exception from a `WinError`
    #
    # By default it takes the current `WinError` value (see `WinError.value`).
    # The system message corresponding to the OS error value amends the *message*.
    # Additional keyword arguments are forwarded to the exception initializer.
    def from_winerror(message : String?, **opts)
      from_os_error(message, WinError.value, **opts)
    end

    {% if flag?(:win32) %}
      @[Deprecated("Use `.from_os_error` instead")]
      def from_winerror(message : String? = nil, winerror : WinError = WinError.value, **opts)
        from_os_error(message, winerror, **opts)
      end
    {% end %}
  end
end
