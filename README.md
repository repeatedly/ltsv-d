# LTSV for D

ltsv-d is a LTSV implementation for D

# Usage

## Parse LTSV format

* fromLTSV

Returns an associative array by default:

```d
import ltsv;

immutable apacheLog = "host:127.0.0.1\tident:-\tuser:foo\ttime:[10/Oct/2000:13:55:36 -0700]\treq:GET /apache.gif HTTP/1.0\tstatus:200\tsize:777\treferer:http://www.example.com/start.html\tua:Mozilla/4.08 [en] (Win98; I ;Nav)";

auto record = fromLTSV(apacheLog);
assert(record["host"] == "127.0.0.1");
assert(record["size"] == "700");
```

Can returns a struct or class:

```d
struct ApacheLog
{
    string host, ident, user, time, req, referer, ua;
    size_t size, status;
}

/// convert into struct or class directly
auto record = fromLTSV!ApacheLog(apacheLog);
assert(record.host == "127.0.0.1");
assert(record.size == 777);
```

## Dump D object into LTSV format

```d
/// foo:bar\thoge:fuga\tpiyo:puyo
auto line = ["foo":"bar", "hoge":"fuga", "piyo":"puyo"].toLTSV();
```

struct or class:

```d
struct Test
{
    string a = "D";
    size_t b = 1999;
    double c = 10.0;
}

/// a:D b:1999 c:10.0
auto line = Test().toLTSV();
```

# Test

```sh
% rdmd -unittest --main src/ltsv.d
```

# Link

* [LTSV](http://ltsv.org/)

  LTSV official site

* [ltsv-d repository](https://github.com/repeatedly/ltsv-d)

  Github repository

# Copyright

<table>
  <tr>
    <td>Author</td><td>Masahiro Nakagawa <repeatedly@gmail.com></td>
  </tr>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2013- Masahiro Nakagawa</td>
  </tr>
  <tr>
    <td>License</td><td>Boost Software License, Version 1.0</td>
  </tr>
</table>
