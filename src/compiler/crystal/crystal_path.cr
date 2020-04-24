require "./config"
require "./exception"

module Crystal
  struct CrystalPath
    class Error < LocationlessException
    end

    def self.default_path
      ENV["CRYSTAL_PATH"]? || Crystal::Config.path
    end

    @crystal_paths : Array(::Path)

    def initialize(path = CrystalPath.default_path, codegen_target = Config.default_target)
      @crystal_paths = path.split(Process::PATH_DELIMITER).compact_map do |path|
        ::Path.new(path) unless path.empty?
      end
      add_target_path(codegen_target)
    end

    private def add_target_path(codegen_target)
      target = "#{codegen_target.architecture}-#{codegen_target.os_name}"

      @crystal_paths.each do |path|
        path = path.join("lib_c", target)
        if Dir.exists?(path)
          @crystal_paths << path unless @crystal_paths.includes?(path)
          return
        end
      end
    end

    def find(filename, relative_to = nil) : Array(String)?
      relative_to = ::Path.new(relative_to) if relative_to.is_a?(String)

      if filename.to_s.starts_with? '.'
        if relative_to
          result = find_in_path_relative_to_dir(filename, relative_to.parent)
        end
      else
        result = find_in_crystal_path(filename)
      end

      case result
      when Array
        result.map(&.to_s)
      when ::Path
        [result.to_s]
      when Nil
        cant_find_file filename, relative_to
      else raise "unreachable"
      end
    end

    private def find_in_path_relative_to_dir(filename, relative_to : ::Path)
      path = ::Path.posix(filename)
      basename = path.basename
      # Check if it's a wildcard.
      if basename == "*" || (recursive = basename == "**")
        relative_dir = relative_to.join(path.parent)

        if File.exists?(relative_dir)
          files = [] of ::Path
          gather_dir_files(relative_dir.to_native, files, recursive)
          return files
        else
          return nil
        end
      end

      relative_filename = relative_to.join(filename)

      # Check if .cr file exists.
      if relative_filename.extension == ".cr"
        relative_filename_cr = relative_filename
      else
        relative_filename_cr = ::Path.posix("#{relative_filename}.cr")
      end

      if File.exists?(relative_filename_cr)
        return relative_filename_cr.to_native.expand
      end

      filename_is_relative = filename.starts_with?('.')

      if !filename_is_relative && (slash_index = filename.index('/'))
        lib_name, after_slash = filename.split('/', 2)
        lib_path = relative_to.join(lib_name, "src")
        relative_path_cr = "#{after_slash}.cr"

        # If it's "foo/bar/baz", check if "foo/src/bar/baz.cr" exists (for a shard, non-namespaced structure)
        absolute_path = lib_path.join(relative_path_cr).expand
        return absolute_path if File.exists?(absolute_path)

        # Then check if "foo/src/foo/bar/baz.cr" exists (for a shard, namespaced structure)
        absolute_path = lib_path.join(lib_name, relative_path_cr).expand
        return absolute_path if File.exists?(absolute_path)

        # If it's "foo/bar/baz", check if "foo/bar/baz/baz.cr" exists (std, nested)
        absolute_path = relative_to.join(filename, relative_filename_cr.basename).expand
        return absolute_path if File.exists?(absolute_path)

        # If it's "foo/bar/baz", check if "foo/src/foo/bar/baz/baz.cr" exists (shard, non-namespaced, nested)
        absolute_path = lib_path.join(after_slash, relative_path_cr).expand
        return absolute_path if File.exists?(absolute_path)

        # If it's "foo/bar/baz", check if "foo/src/foo/bar/baz/baz.cr" exists (shard, namespaced, nested)
        absolute_path = lib_path.join(lib_name, after_slash, relative_path_cr).expand
        return absolute_path if File.exists?(absolute_path)

        return nil
      end

      # If it's "foo", check if "foo/foo.cr" exists (for the std, nested)
      absolute_path = relative_filename.join("#{basename}.cr").expand
      return absolute_path if File.exists?(absolute_path)

      unless filename_is_relative
        # If it's "foo", check if "foo/src/foo.cr" exists (for a shard)
        absolute_path = relative_filename.join("src", "#{basename}.cr").expand
        return absolute_path if File.exists?(absolute_path)
      end

      nil
    end

    private def gather_dir_files(dir, files_accumulator, recursive)
      files = [] of ::Path
      dirs = [] of ::Path

      Dir.each_child(dir) do |filename|
        path = dir.join(filename)

        if File.directory?(path)
          if recursive
            dirs << path
          end
        else
          if path.extension == ".cr"
            files << path
          end
        end
      end

      files.sort!
      dirs.sort!

      files.each do |file|
        files_accumulator << ::Path.new(file).expand
      end

      dirs.each do |subdir|
        gather_dir_files(subdir, files_accumulator, recursive)
      end
    end

    private def find_in_crystal_path(filename)
      @crystal_paths.each do |path|
        required = find_in_path_relative_to_dir(filename, path)
        return required if required
      end

      nil
    end

    private def cant_find_file(filename, relative_to)
      error = "can't find file '#{filename}'"

      if filename.starts_with? '.'
        error += " relative to '#{relative_to}'" if relative_to
      else
        error = <<-NOTE
          #{error}

          If you're trying to require a shard:
          - Did you remember to run `shards install`?
          - Did you make sure you're running the compiler in the same directory as your shard.yml?
          NOTE
      end

      raise Error.new(error)
    end
  end
end
