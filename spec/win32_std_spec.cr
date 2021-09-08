# This file is autogenerated by `spec/generate_windows_spec.sh`
# 2021-11-11 18:02:01+08:00

require "./std/array_spec.cr"
require "./std/atomic_spec.cr"
require "./std/base64_spec.cr"
require "./std/benchmark_spec.cr"
# require "./std/big/big_decimal_spec.cr" (failed linking)
# require "./std/big/big_float_spec.cr" (failed linking)
# require "./std/big/big_int_spec.cr" (failed linking)
# require "./std/big/big_rational_spec.cr" (failed linking)
# require "./std/big/number_spec.cr" (failed linking)
require "./std/bit_array_spec.cr"
require "./std/bool_spec.cr"
require "./std/box_spec.cr"
require "./std/channel_spec.cr"
require "./std/char/reader_spec.cr"
require "./std/char_spec.cr"
require "./std/class_spec.cr"
require "./std/colorize_spec.cr"
require "./std/comparable_spec.cr"
require "./std/complex_spec.cr"
require "./std/compress/deflate/deflate_spec.cr"
require "./std/compress/gzip/gzip_spec.cr"
require "./std/compress/zip/zip_file_spec.cr"
require "./std/compress/zip/zip_spec.cr"
require "./std/compress/zlib/reader_spec.cr"
require "./std/compress/zlib/stress_spec.cr"
require "./std/compress/zlib/writer_spec.cr"
require "./std/concurrent/select_spec.cr"
require "./std/concurrent_spec.cr"
require "./std/crypto/bcrypt/base64_spec.cr"
require "./std/crypto/bcrypt/password_spec.cr"
require "./std/crypto/bcrypt_spec.cr"
require "./std/crypto/blowfish_spec.cr"
require "./std/crypto/subtle_spec.cr"
require "./std/crystal/compiler_rt/divmod128_spec.cr"
require "./std/crystal/compiler_rt/mulodi4_spec.cr"
require "./std/crystal/compiler_rt/mulosi4_spec.cr"
# require "./std/crystal/compiler_rt/muloti4_spec.cr" (failed to run)
require "./std/crystal/digest/md5_spec.cr"
require "./std/crystal/digest/sha1_spec.cr"
require "./std/crystal/hasher_spec.cr"
require "./std/crystal/pointer_linked_list_spec.cr"
require "./std/csv/csv_build_spec.cr"
require "./std/csv/csv_lex_spec.cr"
require "./std/csv/csv_parse_spec.cr"
require "./std/csv/csv_spec.cr"
require "./std/deque_spec.cr"
require "./std/digest/adler32_spec.cr"
require "./std/digest/crc32_spec.cr"
# require "./std/digest/io_digest_spec.cr" (failed codegen)
# require "./std/digest/md5_spec.cr" (failed codegen)
# require "./std/digest/sha1_spec.cr" (failed codegen)
# require "./std/digest/sha256_spec.cr" (failed codegen)
# require "./std/digest/sha512_spec.cr" (failed codegen)
require "./std/dir_spec.cr"
require "./std/double_spec.cr"
require "./std/ecr/ecr_lexer_spec.cr"
require "./std/ecr/ecr_spec.cr"
require "./std/enum_spec.cr"
require "./std/enumerable_spec.cr"
require "./std/env_spec.cr"
require "./std/errno_spec.cr"
require "./std/exception/call_stack_spec.cr"
require "./std/exception_spec.cr"
require "./std/file/tempfile_spec.cr"
require "./std/file_spec.cr"
require "./std/file_utils_spec.cr"
require "./std/float_printer/diy_fp_spec.cr"
require "./std/float_printer/grisu3_spec.cr"
require "./std/float_printer/ieee_spec.cr"
require "./std/float_printer_spec.cr"
require "./std/float_spec.cr"
require "./std/gc_spec.cr"
require "./std/hash_spec.cr"
require "./std/html_spec.cr"
require "./std/http/chunked_content_spec.cr"
# require "./std/http/client/client_spec.cr" (failed codegen)
require "./std/http/client/response_spec.cr"
require "./std/http/cookie_spec.cr"
require "./std/http/formdata/builder_spec.cr"
require "./std/http/formdata/parser_spec.cr"
require "./std/http/formdata_spec.cr"
require "./std/http/headers_spec.cr"
require "./std/http/http_spec.cr"
require "./std/http/params_spec.cr"
require "./std/http/request_spec.cr"
require "./std/http/server/handlers/compress_handler_spec.cr"
require "./std/http/server/handlers/error_handler_spec.cr"
require "./std/http/server/handlers/handler_spec.cr"
require "./std/http/server/handlers/log_handler_spec.cr"
require "./std/http/server/handlers/static_file_handler_spec.cr"
# require "./std/http/server/handlers/websocket_handler_spec.cr" (failed codegen)
require "./std/http/server/request_processor_spec.cr"
require "./std/http/server/response_spec.cr"
# require "./std/http/server/server_spec.cr" (failed codegen)
require "./std/http/status_spec.cr"
# require "./std/http/web_socket_spec.cr" (failed codegen)
require "./std/humanize_spec.cr"
require "./std/indexable/mutable_spec.cr"
require "./std/indexable_spec.cr"
require "./std/ini_spec.cr"
require "./std/int_spec.cr"
require "./std/io/argf_spec.cr"
require "./std/io/buffered_spec.cr"
require "./std/io/byte_format_spec.cr"
require "./std/io/delimited_spec.cr"
require "./std/io/file_descriptor_spec.cr"
require "./std/io/hexdump_spec.cr"
require "./std/io/io_spec.cr"
require "./std/io/memory_spec.cr"
require "./std/io/multi_writer_spec.cr"
require "./std/io/sized_spec.cr"
require "./std/io/stapled_spec.cr"
require "./std/iterator_spec.cr"
require "./std/json/any_spec.cr"
require "./std/json/builder_spec.cr"
require "./std/json/lexer_spec.cr"
require "./std/json/parser_spec.cr"
require "./std/json/pull_parser_spec.cr"
require "./std/json/serializable_spec.cr"
require "./std/json/serialization_spec.cr"
# require "./std/kernel_spec.cr" (failed codegen)
require "./std/levenshtein_spec.cr"
# require "./std/llvm/aarch64_spec.cr" (failed linking)
# require "./std/llvm/arm_abi_spec.cr" (failed linking)
# require "./std/llvm/llvm_spec.cr" (failed linking)
# require "./std/llvm/type_spec.cr" (failed linking)
# require "./std/llvm/x86_64_abi_spec.cr" (failed linking)
# require "./std/llvm/x86_abi_spec.cr" (failed linking)
require "./std/log/broadcast_backend_spec.cr"
require "./std/log/builder_spec.cr"
require "./std/log/context_spec.cr"
require "./std/log/dispatch_spec.cr"
require "./std/log/env_config_spec.cr"
require "./std/log/format_spec.cr"
require "./std/log/io_backend_spec.cr"
require "./std/log/log_spec.cr"
require "./std/log/main_spec.cr"
require "./std/log/metadata_spec.cr"
require "./std/log/spec_spec.cr"
require "./std/match_data_spec.cr"
require "./std/math_spec.cr"
require "./std/mime/media_type_spec.cr"
require "./std/mime/multipart/builder_spec.cr"
require "./std/mime/multipart/parser_spec.cr"
require "./std/mime/multipart_spec.cr"
require "./std/mime_spec.cr"
# require "./std/mutex_spec.cr" (failed codegen)
require "./std/named_tuple_spec.cr"
# require "./std/number_spec.cr" (failed linking)
# require "./std/oauth/access_token_spec.cr" (failed codegen)
# require "./std/oauth/authorization_header_spec.cr" (failed codegen)
# require "./std/oauth/consumer_spec.cr" (failed codegen)
# require "./std/oauth/params_spec.cr" (failed codegen)
# require "./std/oauth/request_token_spec.cr" (failed codegen)
# require "./std/oauth/signature_spec.cr" (failed codegen)
# require "./std/oauth2/access_token_spec.cr" (failed codegen)
# require "./std/oauth2/client_spec.cr" (failed codegen)
# require "./std/oauth2/session_spec.cr" (failed codegen)
require "./std/object_spec.cr"
# require "./std/openssl/cipher_spec.cr" (failed codegen)
# require "./std/openssl/digest_spec.cr" (failed codegen)
# require "./std/openssl/hmac_spec.cr" (failed codegen)
# require "./std/openssl/pkcs5_spec.cr" (failed codegen)
# require "./std/openssl/ssl/context_spec.cr" (failed codegen)
# require "./std/openssl/ssl/hostname_validation_spec.cr" (failed codegen)
# require "./std/openssl/ssl/server_spec.cr" (failed codegen)
# require "./std/openssl/ssl/socket_spec.cr" (failed codegen)
# require "./std/openssl/x509/certificate_spec.cr" (failed codegen)
# require "./std/openssl/x509/name_spec.cr" (failed codegen)
require "./std/option_parser_spec.cr"
# require "./std/overflow_spec.cr" (failed linking)
require "./std/path_spec.cr"
require "./std/pointer_spec.cr"
require "./std/pp_spec.cr"
require "./std/pretty_print_spec.cr"
require "./std/proc_spec.cr"
require "./std/process/find_executable_spec.cr"
require "./std/process_spec.cr"
require "./std/raise_spec.cr"
require "./std/random/isaac_spec.cr"
require "./std/random/pcg32_spec.cr"
require "./std/random/secure_spec.cr"
require "./std/random_spec.cr"
require "./std/range_spec.cr"
require "./std/record_spec.cr"
require "./std/reference_spec.cr"
require "./std/regex_spec.cr"
require "./std/semantic_version_spec.cr"
require "./std/set_spec.cr"
# require "./std/signal_spec.cr" (failed codegen)
require "./std/slice_spec.cr"
require "./std/socket/address_spec.cr"
require "./std/socket/addrinfo_spec.cr"
require "./std/socket/socket_spec.cr"
require "./std/socket/tcp_server_spec.cr"
require "./std/socket/tcp_socket_spec.cr"
require "./std/socket/udp_socket_spec.cr"
# require "./std/socket/unix_server_spec.cr" (failed codegen)
# require "./std/socket/unix_socket_spec.cr" (failed codegen)
require "./std/spec/context_spec.cr"
require "./std/spec/expectations_spec.cr"
require "./std/spec/filters_spec.cr"
require "./std/spec/helpers/iterate_spec.cr"
require "./std/spec/hooks_spec.cr"
require "./std/spec/junit_formatter_spec.cr"
require "./std/spec/tap_formatter_spec.cr"
require "./std/spec_spec.cr"
require "./std/static_array_spec.cr"
require "./std/string/utf16_spec.cr"
require "./std/string_builder_spec.cr"
require "./std/string_pool_spec.cr"
require "./std/string_scanner_spec.cr"
require "./std/string_spec.cr"
require "./std/struct_spec.cr"
require "./std/symbol_spec.cr"
# require "./std/system/group_spec.cr" (failed codegen)
# require "./std/system/user_spec.cr" (failed codegen)
require "./std/system_error_spec.cr"
require "./std/system_spec.cr"
# require "./std/thread/condition_variable_spec.cr" (failed codegen)
# require "./std/thread/mutex_spec.cr" (failed codegen)
# require "./std/thread_spec.cr" (failed codegen)
require "./std/time/custom_formats_spec.cr"
require "./std/time/format_spec.cr"
require "./std/time/location_spec.cr"
require "./std/time/span_spec.cr"
require "./std/time/time_spec.cr"
require "./std/tuple_spec.cr"
require "./std/uint_spec.cr"
require "./std/uri/params_spec.cr"
require "./std/uri/punycode_spec.cr"
require "./std/uri_spec.cr"
require "./std/uuid/json_spec.cr"
require "./std/uuid/yaml_spec.cr"
require "./std/uuid_spec.cr"
# require "./std/va_list_spec.cr"
require "./std/weak_ref_spec.cr"
require "./std/winerror_spec.cr"
require "./std/xml/builder_spec.cr"
require "./std/xml/html_spec.cr"
require "./std/xml/reader_spec.cr"
require "./std/xml/xml_spec.cr"
require "./std/xml/xpath_spec.cr"
require "./std/yaml/any_spec.cr"
require "./std/yaml/builder_spec.cr"
require "./std/yaml/nodes/builder_spec.cr"
require "./std/yaml/schema/core_spec.cr"
require "./std/yaml/schema/fail_safe_spec.cr"
require "./std/yaml/serializable_spec.cr"
require "./std/yaml/serialization_spec.cr"
require "./std/yaml/yaml_pull_parser_spec.cr"
require "./std/yaml/yaml_spec.cr"
