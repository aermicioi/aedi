module aermicioi.aedi.util.formatting;
import std.conv : text;

/**
A formatting utility for a list of arguments that adds separator between arguments.

Params:
    separator = separator used to separe arguments
    first = first argument
    leftover = remaining arguments
Throws:

Returns:
    a string with all arguments converted to string.
**/
string separated(First, Leftover...)(string separator, First first, Leftover leftover) {
    static if (Leftover.length > 0) {
        return text(first) ~ separator ~ separated(separator, leftover);
    } else {
        return text(first);
    }
}

string separated(string separator) {
    return "";
}

/**
Wrap a string into a pair for bracers / prefix & suffix.

Params:
    content = content to be wrapped
    prefix = prefix to prepend
    suffix = suffix to append

Returns:
    wrapped content
**/
string wrapped(string content, string prefix = "{[ ", string suffix = " ]}") {
    return prefix ~ content ~ suffix;
}