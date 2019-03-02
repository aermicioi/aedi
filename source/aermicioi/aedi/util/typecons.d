module aermicioi.aedi.util.typecons;

/**
Creates a lightweight tuple of values.

Params:
    args = list of arguments to pack in a tuple.
Returns:
    Tuple!Args a tuple of arguments, probably auto expandable thx to alias this.
**/
auto tuple(Args...)(auto ref Args args) {
    return Tuple!Args(args);
}

/**
ditto
**/
struct Tuple(Args...) {

    /**
    The packed arguments.
    **/
    Args args;

    /**
    Alias this to args, for possible auto expansion.
    **/
    alias args this;

    /**
    Compatibility alias to expand functionality of std.typecons.Tuple
    **/
    alias expand = args;
}

/**
Pseudo immutable optional with a value or not.

Params:
    optional = value to contain in the optional itself.

Returns:
    An optional filled or not with value.
**/
Optional!T optional(T)(auto ref T optional) {
    return Optional!T(optional);
}

/**
ditto
**/
Optional!T optional(T)() {
    return Optional!T();
}

/**
ditto
**/
struct Optional(T) {
    private T payload_;
    immutable bool isNull = true;

    /**
    Constructor for pseudo immutable optional.

    Params:
        payload = payload to hold onto.
    **/
    this(ref T payload) {
        this.isNull = false;
        this.payload_ = payload;
    }

    /**
    ditto
    **/
    this(T payload) {
        this(payload);
    }

    /**
    Get the payload hosted in this optional.

    Returns:
        T payload that is hosted.
    **/
    ref inout(T) payload() inout pure nothrow @nogc @safe
    out (; !isNull, "Cannot provide a value out of optional when it is null.") {
        return this.payload_;
    }

    /**
    Convenience subtyping.
    **/
    alias payload this;
}

/**
Pair a key and a value toghether.

Params:
    value = value to pair with key
    key = key associated to value

Returns:
    Pair!(ValueType, KeyType) a pair of key => value.
**/
Pair!(ValueType, KeyType) pair(ValueType, KeyType)(auto ref ValueType value, auto ref KeyType key) {
    return Pair!(ValueType, KeyType)(value, key);
}

/**
ditto
**/
alias paired = pair;

/**
ditto
**/
struct Pair(ValueType, KeyType) {

    /**
    Value in pair
    **/
    ValueType value;

    /**
    Key in pair
    **/
    KeyType key;
}
