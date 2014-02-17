// Written in the D programming language

/**
 * Implements functionality to parse and dump LTSV
 *
 * See_Also:
 *  $(LINK2 http://ltsv.org/, Labeled Tab-separated Values)
 *
 * Copyright: Copyright Masahiro Nakagawa 2013-.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Masahiro Nakagawa
 */
module ltsv;

import std.conv : to;
import std.string : split, indexOf, format;
import std.traits;

///
class LTSVException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

/**
 * Parses the LTSV.
 */
auto fromLTSV(RecordType = void, String)(String line) if (isSomeString!(String))
{
    alias LTSVResult!(RecordType, String) Result;

    Result result;
    static if(is(RecordType == class))
        result = new Result();

    foreach (record; line.split("\t")) {
        size_t index = record.indexOf(":");
        if (index == -1)
            throw new LTSVException("':' separator not found");

        String key = record[0..index];
        String val = record[index + 1..$];

        static if (isAssociativeArray!Result) {
            alias KeyType!Result K;
            alias ValueType!Result V;

            result[to!K(key)] = to!V(val);
        } else {
            switch (key) {
            mixin(genetateCaseBody!(Result));
            }
        }
    }

    return result;
}

unittest
{
    static struct ApacheLog
    {
        string host, ident, user, time, req, referer, ua;
        size_t size, status;
    }

    static class ApacheLogClass
    {
        string host, ident, user, time, req, referer, ua;
        size_t size, status;
    }

    immutable str = "host:127.0.0.1\tident:-\tuser:foo\ttime:[10/Oct/2000:13:55:36 -0700]\treq:GET /apache.gif HTTP/1.0\tstatus:200\tsize:777\treferer:http://www.example.com/start.html\tua:Mozilla/4.08 [en] (Win98; I ;Nav)";

    foreach (S; std.typetuple.TypeTuple!(string, wstring, dstring)) {
        { // AA
            auto record = fromLTSV(to!S(str));
            assert(record.length == 9);
            assert(record[to!S("host")] == to!S("127.0.0.1"));
            assert(record[to!S("size")] == to!S("777"));
            assert(record[to!S("time")] == to!S("[10/Oct/2000:13:55:36 -0700]"));
        }
        { // struct
            auto record = fromLTSV!ApacheLog(str);
            assert(record.host == "127.0.0.1");
            assert(record.size == 777);
            assert(record.time == "[10/Oct/2000:13:55:36 -0700]");        
        }
        { // class
            auto record = fromLTSV!ApacheLogClass(str);
            assert(record.host == "127.0.0.1");
            assert(record.size == 777);
            assert(record.time == "[10/Oct/2000:13:55:36 -0700]");        
        }
    }
}

/**
 * Dumps $(D_PARAM record) into LTSV
 */
string toLTSV(Record)(Record record)
{
    auto result = std.array.appender!(string)();

    static if (isAssociativeArray!Record) {
        foreach (k, v; record)
            result.put(to!string(k) ~ ":" ~ to!string(v) ~ "\t");
    } else {
        foreach (i, ref f ; record.tupleof)
            result.put(getFieldName!(Record, i) ~ ":" ~ to!string(f) ~ "\t");
    }

    return result.data[0..$ - 1];
}

unittest
{
    { // AA
        auto aa = ["foo":"bar", "a":"b"];
        auto line = toLTSV(aa);

        assert(line.length == "foo:bar\ta:b".length);
        assert(fromLTSV(line) == aa);
    }
    { // struct
        static struct Test
        {
            string a = "D";
            size_t b = 1999;
            double c = 10.0;

            bool opEquals(Test other)
            {
                return a == other.a && b == other.b && c == other.c;
            }
        }

        Test test;
        auto line = toLTSV(test);

        assert(line.split("\t").length == 3);
        assert(fromLTSV!Test(line) == test);
    }
}

private:

template LTSVResult(RecordType, String)
{
    static if (is(RecordType == void))
        alias String[String] LTSVResult;
    else static if (isAssociativeArray!RecordType)
        alias RecordType LTSVResult;
    else static if (is(RecordType == class) || is(RecordType == struct))
        alias RecordType LTSVResult;
    else
        static assert(false, "Result type must be an associative array, class or struct type: type = " ~ RecordType.stringof);
}

string genetateCaseBody(T)()
{
    string result;

    static if (is(T == class))
        T obj = new T();
    else
        T obj;

    foreach(i, v; obj.tupleof) {
        alias getFieldName!(T, i) name;

        result ~= q"CASE
case "%s":
result.%s = to!(%s)(val);
break;
CASE".format(name, name, typeof(v).stringof);
    }

    result ~= "default: break;";

    return result;
}

/**
 * Get a field name of class or struct.
 */
template getFieldName(Type, size_t i)
{
    import std.conv : text;

    static assert((is(Unqual!Type == class) || is(Unqual!Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    enum getFieldName = __traits(identifier, Type.tupleof[i]);
}
