module aermicioi.aedi.util.range;

import std.range.primitives;

/**
Buffering output range into a static array

Parameters:
    T = static array buffer.
**/
struct BufferSink(T : Z[N], Z, size_t N) {
    private T buffer;
    private size_t fillage;

    /**
    Pull elements out of range and save them in buffer

    Params:
        range = range from which to pull out elements.
    **/
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
        /**
        Constructor for exception chain

        Params:
            exception = initial exception in chain of exceptions
        **/
        this(Throwable exception) {
            this.current = exception;
        }

        private this(ref ExceptionChain chain) {
            this.current = chain.current;
        }

        /**
        Get current throwable in exception chain

        Returns:
            current throwable
        **/
        Throwable front() {
            return current;
        }

        /**
        Check if exception chain exhausted or not.

        Returns:
            true if exausted false otherwise
        **/
        bool empty() {
            return current is null;
        }

        /**
        Move to next exception in chain
        **/
        void popFront() {
            if (!empty) {
                current = current.next;
            }
        }

        /**
        Save exception chain at current point.

        Returns:
            A copy of current exception chain
        **/
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

	private Range range;
	private Interface current;

	this(this) {
		range = range.save;
	}

    /**
    Constructor for interface filtering range

    Params:
        range = range to filter out.
    **/
	this(ref Range range) {
		this.range = range.save;
		this.popFront;
	}

	private this(ref Range range, Interface current) {
		this.range = range.save;
		this.current = current;
	}

    /**
    Whether there are more elements that implement interface or not.

    Returns:
        true if there are no more elements implementing interface
    **/
	bool empty() {
		return current is null;
	}

    /**
    Get current implementing element

    Returns:
        current element that implements interface
    **/
	Interface front() {
		return current;
	}

    /**
    Move to next element implementing interface.
    **/
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

    /**
    Save range at current point.

    Returns:
        A copy of current range.
    **/
	typeof(this) save() {
		return typeof(this)(range, current);
	}
}

/**
Create a range of all base classes and interfaces a component implements.

Warning no order of inherited interfaces and classes is guaranteed.

Params:
    classinfo = typeinfo of component for which to create inheritance chain.

Returns:
    A range of ClassInfo elements.
**/
auto inheritance(ClassInfo classinfo) {
    return InheritanceRange(classinfo);
}

/**
ditto
**/
@safe struct InheritanceRange {
    import std.container : RedBlackTree;
    private {
        RedBlackTree!(ClassInfo, (f, s) => (f is null ? "" : f.name) < (s is null ? "" : s.name)) stack;
        RedBlackTree!(ClassInfo, (f, s) => (f is null ? "" : f.name) < (s is null ? "" : s.name)) processed;
    }

    /**
    Constructor for inheritance range

    Params:
        component = component for which to create inheritance range.
    **/
    this(ClassInfo component) {
        stack = new typeof(this.stack)(component);
        processed = new typeof(this.processed)();
    }

    private this(ref InheritanceRange range) {
        this.stack = range.stack.dup;
        this.processed = range.processed.dup;
    }

    /**
    Get current element in range.

    Returns:
        Current type that component inherits.
    **/
    ClassInfo front() {
        return stack.front;
    }

    /**
    Whether there are more inherited types or not.

    Returns:
        true if not.
    **/
    bool empty() {
        return stack.empty;
    }

    /**
    Move to next inherited type.
    **/
    void popFront() {
        import std.algorithm.iteration : map, filter;
        ClassInfo removed = stack.front;
        stack.removeFront;
        processed.insert(removed);

        stack.insert(removed.interfaces.map!(iface => iface.classinfo).filter!(iface => iface !in processed));
        if ((removed.base !is null) && (removed.base !in processed)) {

            stack.insert(removed.base);
        }
    }

    /**
    Save range at current state.

    Returns:
        A copy of range.
    **/
    InheritanceRange save() {
        return InheritanceRange(this);
    }
}