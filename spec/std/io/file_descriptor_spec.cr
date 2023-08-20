require "../spec_helper"
require "../../support/finalize"

class IO::FileDescriptor
  include FinalizeCounter
end

private def shell_command(command)
  {% if flag?(:win32) %}
    "cmd.exe /c #{Process.quote(command)}"
  {% else %}
    "/bin/sh -c #{Process.quote(command)}"
  {% end %}
end

describe IO::FileDescriptor do
  it "reopen STDIN with the right mode", tags: %w[slow] do
    code = %q(puts "#{STDIN.blocking} #{STDIN.info.type}")
    compile_source(code) do |binpath|
      `#{shell_command %(#{Process.quote(binpath)} < #{Process.quote(binpath)})}`.chomp.should eq("true File")
      `#{shell_command %(echo "" | #{Process.quote(binpath)})}`.chomp.should eq("#{{{ flag?(:win32) }}} Pipe")
    end
  end

  it "closes on finalize" do
    pipes = [] of IO::FileDescriptor
    assert_finalizes("fd") do
      a, b = IO.pipe
      pipes << b
      a
    end

    expect_raises(IO::Error) do
      pipes.each do |p|
        p.puts "123"
      end
    end
  end

  it "opens STDIN in binary mode", tags: %w[slow] do
    code = %q(print STDIN.gets_to_end.includes?('\r'))
    compile_source(code) do |binpath|
      io_in = IO::Memory.new("foo\r\n")
      io_out = IO::Memory.new
      Process.run(binpath, input: io_in, output: io_out)
      io_out.to_s.should eq("true")
    end
  end

  it "opens STDOUT in binary mode", tags: %w[slow] do
    code = %q(puts "foo")
    compile_source(code) do |binpath|
      io = IO::Memory.new
      Process.run(binpath, output: io)
      io.to_s.should eq("foo\n")
    end
  end

  it "opens STDERR in binary mode", tags: %w[slow] do
    code = %q(STDERR.puts "foo")
    compile_source(code) do |binpath|
      io = IO::Memory.new
      Process.run(binpath, error: io)
      io.to_s.should eq("foo\n")
    end
  end

  it "does not close if close_on_finalize is false" do
    pipes = [] of IO::FileDescriptor
    assert_finalizes("fd") do
      a, b = IO.pipe
      a.close_on_finalize = false
      pipes << b
      a
    end

    pipes.each do |p|
      p.puts "123"
    end
  end

  {% if flag?(:win32) %}
    describe "Windows console handle", focus: true do
      it do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.write "zażółć gęślą jaźń\n".to_utf16.unsafe_slice_of(UInt8)
          fd.gets.should eq "zażółć gęślą jaźń"
        end
      end
      it "empty" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.close
          fd.gets.should eq nil
        end
      end

      it "read 1/2 byte" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.write "ż".to_utf16.unsafe_slice_of(UInt8)
          fd.gets(1).should eq "\xC5"
        end
      end

      it "read 2/2 bytes" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.write "ż".to_utf16.unsafe_slice_of(UInt8)
          fd.gets(2).should eq "ż"
        end
      end

      it "read 3/4 bytes" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.write "\u{10000}".to_utf16.unsafe_slice_of(UInt8)
          fd.gets(3).should eq "\xF0\x90\x80"
        end
      end

      it "read 4/4 bytes" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.write "\u{10000}".to_utf16.unsafe_slice_of(UInt8)
          fd.gets(4).should eq "\u{10000}"
        end
      end

      it "read 3/3 bytes" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          write.write "\u{10000}".to_utf16.unsafe_slice_of(UInt8)[0, 3]
          fd.gets(3).should eq "�"
        end
      end

      it "small buffer" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          fd.buffer_size = 12
          write.write "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".to_utf16.unsafe_slice_of(UInt8)
          fd.gets(15).should eq "abcdefghijklmno"
        end
      end

      it "full buffer" do
        IO.pipe do |read, write|
          fd = Win32ConsoleFileDescriptor.new(read.fd)
          fd.buffer_size = 32
          write.write "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".to_utf16.unsafe_slice_of(UInt8)
          fd.gets(40).should eq "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN"
          fd.gets(12).should eq "OPQRSTUVWXYZ"
        end
      end
    end
  {% end %}
end

{% if flag?(:win32) %}
  class Win32ConsoleFileDescriptor < IO::FileDescriptor
    private def console_mode?(handle)
      true
    end

    private def read_console(hConsoleInput, lpBuffer, nNumberOfCharsToRead, lpNumberOfCharsRead, pInputControl)
      bytesBuffer = lpBuffer[0, nNumberOfCharsToRead].unsafe_slice_of(UInt8)
      bytes_read = blocking_read(bytesBuffer)
      p! nNumberOfCharsToRead, bytes_read
      lpNumberOfCharsRead.value = bytes_read.to_u32 // 2
      p! bytesBuffer[0, bytes_read]
      1
    rescue
      0
    end
  end
{% end %}
