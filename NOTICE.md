# Crystal Programming Language

Copyright 2012-2022 Manas Technology Solutions.

This product includes software developed at Manas Technology Solutions (<https://manas.tech/>).

The Crystal language is licensed under the *Apache License v2.0* license (see [`LICENSE`](/LICENSE)).
This license applies to all works in this project unless stated otherwise.

## External libraries information

### Compiler

The Crystal compiler links to the following libraries, which have their own licenses:

* [LLVM][] - since LLVM 9: [Apache-2.0-LLVM][Apache 2.0 with exceptions]; earlier: [BSD-3, effectively][]
* [PCRE][] - [BSD-3][]
* [libevent2][] - [BSD-3][]
* [libiconv][] - [LGPLv3][]
* [bdwgc][] - [MIT][]
* [libc][] - depending on system library (statically linked linux binaries use musl libc: [MIT][])
* [libpthread][] - depending on system library, usually identical with libc

The following libraries are linked when the compiler is built with interpreter support (`-Dinterpreter`):

* [libffi][] - [MIT][]

The following libraries are linked unless the compiler is built without TLS support (`-Dwithout_ssl`):

Either one of the following, depending on availability:

* [OpenSSL][] - [Apache-2.0][]
* [LibreSSL][] - [BSD][]

The following libraries are linked unless the compiler is built without Zlib support (`-Dwithout_zlib`):

* [Zlib][] - [Zlib][Zlib-license]

The Crystal playground (`crystal play`) includes the following libraries, which have their own licenses.
(There are these files under [/src/compiler/crystal/tools/playground/public/vendor](/src/compiler/crystal/tools/playground/public/vendor)):

* [jQuery][] - [MIT][]
  `Copyright JS Foundation and other contributors, https://js.foundation/`
* [Octicons][] - [MIT][] (for codes) or [OFL-1.1][] (for fonts) `(c) 2012-2016 GitHub, Inc.`
* [Materialize][] - [MIT][] `Copyright (c) 2014-2015 Materialize`
* [CodeMirror][] - [MIT][] `Copyright (C) 2016 by Marijn Haverbeke <marijnh@gmail.com> and others`
* [ansi\_up][] - [MIT][] `Copyright (c) 2011 Dru Nelson`

These libraries are distributed with the compiler unless it was built without playground support (`-Dwithout_playground`).
### Standard Library

The Crystal standard library uses the following libraries, which have their own licenses.

The following libraries provide part of the core runtime and are linked by any Crystal program using the standard library.

* [PCRE][] - [BSD-3][]
* [libevent2][] - [BSD-3][]
* [libiconv][] - [LGPLv3][]
* [bdwgc][] - [MIT][]
* [libunwind][] - since LLVM 9: [Apache-2.0-LLVM][Apache 2.0 with exceptions]; earlier: [BSD-3, effectively][]
* [libm][] -

The following libraries are linked when specific components of the standard library are used:

`LLVM`:

* [LLVM][] - since LLVM 9: [Apache-2.0-LLVM][Apache 2.0 with exception]; earlier: [BSD-3, effectively][]

`Comress::Zlib`:

* [Zlib][] - [Zlib][Zlib-license]

`OpenSSL`, `Digest::MD5`, `Digest::SHA1`, `Digest::SHA512`, `HTTP::Client`, `HTTP::Server`:

Either one of the following, depending on availability:

* [OpenSSL][] - [Apache-2.0][]
* [LibreSSL][] - [BSD][]

`XML`:

* [Libxml2][] - [MIT][]

`YAML`:

* [LibYAML][] - [MIT][]

`BigInt`, `BigRational`, `BigDecimal`, `BigFloat`:

* [GMP][] - [LGPLv3][]

<!-- licenses -->
[Apache-2.0]: https://www.openssl.org/source/apache-license-2.0.txt
[BSD-3]: https://opensource.org/licenses/BSD-3-Clause
[BSD-3, effectively]: http://releases.llvm.org/2.8/LICENSE.TXT
[GPLv3]: https://www.gnu.org/licenses/gpl-3.0.en.html
[LGPLv3]: https://www.gnu.org/licenses/lgpl-3.0.en.html
[MIT]: https://opensource.org/licenses/MIT
[OFL-1.1]: https://opensource.org/licenses/OFL-1.1
[Zlib-license]: https://opensource.org/licenses/Zlib
<!-- libraries -->
[ansi\_up]: https://github.com/drudru/ansi\_up
[bdwgc]: http://www.hboehm.info/gc/
[CodeMirror]: https://codemirror.net/
[jQuery]: https://jquery.com/
[GMP]: https://gmplib.org/
[libevent2]: http://libevent.org/
[libiconv]: https://www.gnu.org/software/libiconv/
[Libxml2]: http://xmlsoft.org/
[LibYAML]: http://pyyaml.org/wiki/LibYAML
[LLVM]: http://llvm.org/
[Materialize]: http://materializecss.com/
[Octicons]: https://octicons.github.com/
[OpenSSL]: https://www.openssl.org/
[PCRE]: http://pcre.org/
[readline]: https://tiswww.case.edu/php/chet/readline/rltop.html
[Zlib]: http://www.zlib.net/
