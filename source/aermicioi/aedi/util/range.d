module aermicioi.aedi.util.range;

import std.range.primitives;

/**
Buffering output range into a static array

Parameters:
    T = static array buffer.
**/
struct BufferSink(T : Z[N], Z, size_t N) {
    import std.range;

    private T buffer;
    private size_t fillage;

    void put(R)(ref R range)
        if (isInputRange!R && is(ElementType!R == Z)){

        if (range.empty) {
            return;
        }

        foreach (index, ref slot; buffer) {
            if (range.empty) {
                break;
            }

            slot = range.front;
            range.popFront;
            fillage = index;
        }

        ++fillage;
    }

    /**
    Get buffered data.

    Returns:
        Z[] a slice of static array
    **/
    Z[] slice() {
        return buffer[0 .. fillage];
    }
}

/**
A forward range representing an exception chain.

Params:
    throwable = starting point of exception chain

Returns:
    a forward range of exceptions
**/
auto exceptions(Throwable throwable) {
    return ExceptionChain(throwable);
}

/**
ditto
**/
@safe struct ExceptionChain {

    private Throwable current;

    public {
        this(Throwable exception) {
            this.current = exception;
        }

        private this(ref ExceptionChain chain) {
            this.current = chain.current;
        }

        Throwable front() {
            return current;
        }

        bool empty() {
            return current is null;
        }

        void popFront() {
            if (!empty) {
                current = current.next;
            }
        }

        typeof(this) save() {
            return ExceptionChain(this);
        }
    }
}

/**
Given a range of objects filter them by Interface they are implementing.

Params:
	Interface = interface by which to filter the range
	range = range of objects to filter

Returns:
	InterfaceFilter!(Range, Interface) a range of filtered objects by Interface
**/
InterfaceFilter!(Range, Interface) filterByInterface(Interface, Range)(auto ref Range range) {
	return InterfaceFilter!(Range, Interface)(range);
}

/**
ditto
**/
@safe struct InterfaceFilter(Range, Interface)
if (isForwardRange!Range && (is(ElementType!Range == class) || is(ElementType!Range == interface))) {

	Range range;
	Interface current;

	this(this) {
		range = range.save;
	}

	this(ref Range range) {
		this.range = range.save;
		this.popFront;
	}

	private this(ref Range range, Interface current) {
		this.range = range.save;
		this.current = current;
	}

	bool empty() {
		return current is null;
	}

	Interface front() {
		return current;
	}

	void popFront() @trusted {
		while (!range.empty) {
			auto front = range.front;
			range.popFront;

			current = cast(Interface) front;

			if (current !is null) {
				return;
			}
		}

		current = null;
	}

	typeof(this) save() {
		return typeof(this)(range, current);
	}
}