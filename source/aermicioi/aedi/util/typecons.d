module aermicioi.aedi.util.typecons;

import std.string : stripRight;

@safe:

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
Optional!T optional(T)(return ref T optional) {
    return Optional!T(optional);
}

/**
ditto
**/
Optional!T optional(T)(return T optional) {
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
    this(ref T payload) return {
        static if (is(T : Z*, Z) || is(T == class) || is(T == interface)) {
            this.isNull = payload is null;
        } else {
            this.isNull = false;
        }

        this.payload_ = payload;
    }

    /**
    Return a const version of this optional.

    Returns:
        Optional!(const T) a constant version.
    **/
    Optional!(const T) opCast(X : const T)() {
        return Optional!(const T)(payload);
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
    Get the payload if exists or provide an alternative.

    Params:
        alternative = alternative to supply

    Returns:
        Always a payload to use.
    **/
    ref inout(T) orElse(return ref scope inout(T) alternative) inout pure nothrow @nogc @safe {

        if (this == null) {
            return alternative;
        }

        return this.payload_;
    }

    void orElseThrow(T : Exception)(lazy T exception) inout pure @safe {
        if (this == null) {
            throw exception;
        }
    }

    /**
    Check whether optional is null or not.

    Params:
        term = null term to accept.

    Returns:
        true if null, false otherwise
    **/
    bool opEquals(inout typeof(null) term) inout pure nothrow @nogc @safe {
        return this.isNull;
    }

    bool opEquals()(inout lazy T value) inout {
        if (this == null) {
            return false;
        }

        return this.payload == value;
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

/**
Interface for objects that can be subscribed to specific events emmited by them.

Params:
    EventType = type of events for which implementor will call subscribers.
    Args = list of arguments accepted by subscriber
**/
@safe interface Subscribable(EventType, Callback)
{

    public
    {

        /**
        Subscribe a delegate to a particular event emmited by object

        Params:
        	type = type of event emmited by object
            subscriber = the callback to be called on event emmited
        Returns:
        	typeof(this)
        **/
        Subscribable subscribe(EventType type, Callback subscriber);
    }
}

/**
A default mixin implementing storage logic for subscribers.
**/
mixin template SubscribableMixin(EventType, Callback) {
    private {
        Callback[][EventType] subscribers;
    }

    @safe public
    {

        /**
        Subscribe a delegate to a particular event emmited by object

        Params:
        	type = type of event emmited by object
            subscriber = the callback to be called on event emmited
        Returns:
        	typeof(this)
        **/
        typeof(this) subscribe(EventType type, Callback subscriber)
        in (subscriber !is null, "Cannot subcribe to event, when no subscriber is passed(null).")
        {
            subscribers[type] ~= subscriber;

            return this;
        }
    }

    @safe private {
        /**
        Share subscribers with another subscribable.

        Params:
            subscribable = subscribable that wil receive subscribers

        Returns:
            this
        **/
        inout(typeof(this)) transfer(Subscribable!(EventType, Callback) subscribable) inout {
            foreach (key, subscribers; subscribers) {
                foreach (subscriber; subscribers) {
                    subscribable.subscribe(key, subscriber);
                }
            }

            return this;
        }

        /**
        Get subscribers for particular event.

        Params:
            type = event type

        Returns:
            List of subscribers
        **/
        inout(Callback)[] subscribersOfEvent(EventType type) inout {
            if (type in subscribers) {
                return subscribers[type];
            }

            return [];
        }

        private alias Params = Parameters!Callback;

        /**
        Invokes all subscribers for an event with arguments.

        Params:
            type = event type
            args = list of arguments to subscriber
        **/
        ReturnType!Callback invoke(EventType type, Params params) const {
            import std.range : empty;
            static if (!is(ReturnType!Callback == void)) {
                ReturnType result;
            }

            auto subscribers = subscribersOfEvent(type);

            if (subscribers.empty) {
                static if (!is(ReturnType!Callback == void)) {
                    return result;
                } else {
                    return;
                }
            }

            foreach (subscriber; subscribers[0 .. $ - 1]) {
                subscriber(params);
            }

            static if (!is(ReturnType!Callback == void)) {
                return subscribers[$ - 1](params);
            } else {
                subscribers[$ - 1](params);
            }
        }

        static if (!is(ReturnType!Callback == void) && (Params.length > 0)) {
            /**
            Invokes all subscribers for an event with arguments.

            Compared to invoke method, this method will pass return value of
            subscribers to subsequent invoked ones, if possible.

            Params:
                at = at which argument position to replace argument from args with return value of precedent value;
                type = event type
                args = list of arguments to subscriber
            **/
            ReturnType transform(size_t at)(EventType type, Params args) const
                if ((at < args.length) && is(ReturnType : Args[at])) {
                ReturnType result = args[at];

                foreach (subscriber; subscribersOfEvent(type)) {
                    result = subscriber(args[0 .. at], result, args[at + 1 .. $]);
                }

                static if (!is(ReturnType == void)) {
                    return result;
                }
            }
        }
    }
}

/**
Mix in an all args constructor
**/
mixin template AllArgsConstructor() {

    /**
    Generated constructor accepting all defined fields.

    Params:
        args = list of fields as arguments to constructor

    Returns:
        Fully constructed typeof(this) instance
    **/
    this()(auto ref inout typeof(this.tupleof) args) inout {

        this.tupleof = args;
    }
}

mixin template ArgsConstructor(Args...) {

    debug pragma(msg, typeof(Args));

    /**
    Generated constructor accepting a list of defined fields.

    Params:
        args = list of fields as arguments to constructor

    Returns:
        Fully constructed typeof(this) instance
    **/
    this()(auto ref inout scope typeof(Args) args) {
        static foreach (index, arg; Args) {
            arg = args[index];
        }
    }
}

/**
Mix in a copy constructor
**/
mixin template CopyConstructor() {

    /**
    Generated copy constructor.

    Params:
        copyable = copyable instance

    Returns:
        Fully constructed typeof(this) instance
    **/
    this()(auto ref scope typeof(this) copyable) {
        this.tupleof = copyable.tupleof;
    }
}