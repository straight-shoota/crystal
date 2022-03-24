class Time::Location
  @@location_cache = {} of String => NamedTuple(time: Time, location: Location)

  # `InvalidTZDataError` is raised if a zoneinfo file contains invalid
  # time zone data.
  #
  # Details on the exact cause can be found in the error message.
  class InvalidTZDataError < Exception
    def self.initialize(message : String? = "Malformed time zone information", cause : Exception? = nil)
      super(message, cause)
    end
  end

  # :nodoc:
  def self.load?(name : String, sources : Enumerable(String)) : Time::Location?
    if source = find_zoneinfo_file(name, sources)
      load_from_dir_or_zip(name, source)
    end
  end

  # :nodoc:
  def self.load(name : String, sources : Enumerable(String)) : Time::Location?
    if source = find_zoneinfo_file(name, sources)
      load_from_dir_or_zip(name, source) || raise InvalidLocationNameError.new(name, source)
    end
  end

  # :nodoc:
  def self.load_from_dir_or_zip(name : String, source : String) : Time::Location?
    if source.ends_with?(".zip")
      open_file_cached(name, source) do |file|
        read_zip_file(name, file) do |io|
          p! source
          read_zoneinfo(name, io)
        end
      end
    else
      path = File.join(source, name)
      open_file_cached(name, path) do |file|
        read_zoneinfo(name, file)
      end
    end
  end

  private def self.open_file_cached(name : String, path : String)
    return nil unless File.exists?(path)

    mtime = File.info(path).modification_time
    if (cache = @@location_cache[name]?) && cache[:time] == mtime
      return cache[:location]
    else
      File.open(path) do |file|
        location = yield file
        if location
          @@location_cache[name] = {time: mtime, location: location}

          return location
        end
      end
    end
  end

  # :nodoc:
  def self.find_zoneinfo_file(name : String, sources : Enumerable(String)) : String?
    sources.each do |source|
      if source.ends_with?(".zip")
        path = source
      else
        path = File.join(source, name)
      end

      return source if File.exists?(path) && File.file?(path) && File.readable?(path)
    end
  end

  # Parse "zoneinfo" time zone file.
  # This is the standard file format used by most operating systems.
  # See https://data.iana.org/time-zones/tz-link.html, https://github.com/eggert/tz, tzfile(5)

  # :nodoc:
  def self.read_zoneinfo(location_name : String, io : IO) : Time::Location
    magic = uninitialized UInt8[4]
    io.read(magic.to_slice)

    raise InvalidTZDataError.new unless magic.to_slice == "TZif".to_slice

    # 1-byte version
    version = case io.read_byte
      when 0x00 then 1 # Version 1: only 32-bits format
      when 0x32 then 2 # Version 2 ('2'): 32-bits and 64-bits format
      when 0x33 then 3 # Version 3 ('3'): 32-bits and 64-bits format
      else raise InvalidTZDataError.new
      end

    io.skip(15) # 15 bytes padding

    # Read 32-bit header
    num_utc_local = read_int32(io) #	number of UTC/local indicators
    num_std_wall = read_int32(io) #	number of standard/wall indicators
    num_leap_seconds = read_int32(io) #	number of leap seconds
    num_transitions = read_int32(io) #	number of transition times
    num_local_time_zones = read_int32(io) #	number of local time zones
    abbrev_length = read_int32(io) #	number of characters of time zone abbrev strings

    if version > 1
      # In versions 2 and 3 the header and data are repeated in 64-bit format after
      # the 32-bit format header and data.
      # We skip the 32-bit parts and read only 64-bit.

      io.skip(
        num_transitions * 4 +
        num_transitions +
        num_local_time_zones * 6 +
        abbrev_length +
        num_leap_seconds * 8 +
        num_std_wall +
        num_utc_local +
        4 + # TZif header
        16  # version and padding
      )

      # Read 64-bit header
      num_utc_local = read_int32(io)
      num_std_wall = read_int32(io)
      num_leap_seconds = read_int32(io)
      num_transitions = read_int32(io)
      num_local_time_zones = read_int32(io)
      abbrev_length = read_int32(io)

      size = 8
    else
      size = 4
    end

    p! version, size, num_transitions, location_name
    transitionsdata = read_buffer(io, num_transitions * size)

    # Time zone indices for transition times.
    transition_indexes = Bytes.new(num_transitions)
    io.read_fully(transition_indexes)

    zonedata = read_buffer(io, num_local_time_zones * 6)

    abbreviations = read_buffer(io, abbrev_length)

    io.skip(num_leap_seconds * (size + 4))

    isstddata = Bytes.new(num_std_wall)
    io.read_fully(isstddata)

    isutcdata = Bytes.new(num_utc_local)
    io.read_fully(isutcdata)

    # TODO: extend

    zones = Array(Zone).new(num_local_time_zones) do
      offset = read_int32(zonedata)
      is_dst = zonedata.read_byte != 0_u8
      name_idx = zonedata.read_byte
      raise InvalidTZDataError.new unless name_idx && name_idx < abbreviations.size
      abbreviations.pos = name_idx
      name = abbreviations.gets(Char::ZERO, chomp: true)
      raise InvalidTZDataError.new unless name
      Zone.new(name, offset, is_dst)
    end

    transitions = Array(ZoneTransition).new(num_transitions) do |transition_id|
      if size == 8
        time = transitionsdata.read_bytes(Int64, IO::ByteFormat::BigEndian)
      else
        time = read_int32(transitionsdata).to_i64
      end
      zone_idx = transition_indexes[transition_id]
      raise InvalidTZDataError.new unless zone_idx < zones.size

      isstd = !isstddata[transition_id]?.in?(nil, 0_u8)
      isutc = !isstddata[transition_id]?.in?(nil, 0_u8)

      ZoneTransition.new(time, zone_idx, isstd, isutc)
    end

    new(location_name, zones, transitions)
  rescue exc : IO::Error
    raise InvalidTZDataError.new(cause: exc)
  end

  private def self.read_int32(io : IO)
    io.read_bytes(Int32, IO::ByteFormat::BigEndian)
  end

  private def self.read_buffer(io : IO, size : Int)
    buffer = Bytes.new(size)
    io.read_fully(buffer)
    IO::Memory.new(buffer)
  end

  # :nodoc:
  CENTRAL_DIRECTORY_HEADER_SIGNATURE = 0x02014b50
  # :nodoc:
  END_OF_CENTRAL_DIRECTORY_HEADER_SIGNATURE = 0x06054b50
  # :nodoc:
  ZIP_TAIL_SIZE = 22
  # :nodoc:
  LOCAL_FILE_HEADER_SIGNATURE = 0x04034b50
  # :nodoc:
  COMPRESSION_METHOD_UNCOMPRESSED = 0_i16

  # This method loads an entry from an uncompressed zip file.
  # See http://www.onicos.com/staff/iz/formats/zip.html for ZIP format layout
  private def self.read_zip_file(name : String, file : File)
    file.seek -ZIP_TAIL_SIZE, IO::Seek::End

    if file.read_bytes(Int32, IO::ByteFormat::LittleEndian) != END_OF_CENTRAL_DIRECTORY_HEADER_SIGNATURE
      raise InvalidTZDataError.new("Corrupt ZIP file #{file.path}")
    end

    file.skip 6
    num_entries = file.read_bytes(Int16, IO::ByteFormat::LittleEndian)
    file.skip 4

    file.pos = file.read_bytes(Int32, IO::ByteFormat::LittleEndian)

    num_entries.times do
      break if file.read_bytes(Int32, IO::ByteFormat::LittleEndian) != CENTRAL_DIRECTORY_HEADER_SIGNATURE

      file.skip 6
      compression_method = file.read_bytes(Int16, IO::ByteFormat::LittleEndian)
      file.skip 12
      uncompressed_size = file.read_bytes(Int32, IO::ByteFormat::LittleEndian)
      filename_length = file.read_bytes(Int16, IO::ByteFormat::LittleEndian)
      extra_field_length = file.read_bytes(Int16, IO::ByteFormat::LittleEndian)
      file_comment_length = file.read_bytes(Int16, IO::ByteFormat::LittleEndian)
      file.skip 8
      local_file_header_pos = file.read_bytes(Int32, IO::ByteFormat::LittleEndian)
      filename = file.read_string(filename_length)

      unless filename == name
        file.skip extra_field_length + file_comment_length
        next
      end

      unless compression_method == COMPRESSION_METHOD_UNCOMPRESSED
        raise InvalidTZDataError.new("Unsupported compression in ZIP file: #{file.path}")
      end

      file.pos = local_file_header_pos

      unless file.read_bytes(Int32, IO::ByteFormat::LittleEndian) == LOCAL_FILE_HEADER_SIGNATURE
        raise InvalidTZDataError.new("Invalid ZIP file: #{file.path}")
      end
      file.skip 4
      unless file.read_bytes(Int16, IO::ByteFormat::LittleEndian) == COMPRESSION_METHOD_UNCOMPRESSED
        raise InvalidTZDataError.new("Invalid ZIP file: #{file.path}")
      end
      file.skip 16
      unless file.read_bytes(Int16, IO::ByteFormat::LittleEndian) == filename_length
        raise InvalidTZDataError.new("Invalid ZIP file: #{file.path}")
      end
      extra_field_length = file.read_bytes(Int16, IO::ByteFormat::LittleEndian)
      unless file.gets(filename_length) == name
        raise InvalidTZDataError.new("Invalid ZIP file: #{file.path}")
      end

      file.skip extra_field_length

      return yield file
    end
  end
end
