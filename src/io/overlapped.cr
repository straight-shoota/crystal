{% skip_file unless flag?(:win32) %}
require "c/handleapi"
require "crystal/system/thread_linked_list"

module IO::Overlapped
end
