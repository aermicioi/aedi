/**
License:
    Boost Software License - Version 1.0 - August 17th, 2003

    Permission is hereby granted, free of charge, to any person or organization
    obtaining a copy of the software and accompanying documentation covered by
    this license (the "Software") to use, reproduce, display, distribute,
    execute, and transmit the Software, and to prepare derivative works of the
    Software, and to permit third-parties to whom the Software is furnished to
    do so, all subject to the following:

    The copyright notices in the Software and this entire statement, including
    the above license grant, this restriction and the following disclaimer,
    must be included in all copies of the Software, in whole or in part, and
    all derivative works of the Software, unless such copies or derivative
    works are solely in the form of machine-executable object code generated by
    a source language processor.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
    SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
    FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.

Authors:
    Alexandru Ermicioi
**/
module aermicioi.aedi.storage.allocator_aware;

public import std.experimental.allocator : IAllocator, make, dispose, theAllocator;
import aermicioi.aedi.storage.decorator : MutableDecorator, Decorator;

/**
Interface for components that are aware of a memory allocator and are using it for some purpose, such as allocating storage for other components, or data.
**/
interface AllocatorAware(AllocatorType = IAllocator) {

    public {
        @property {

            /**
            Set allocator

            Params:
                allocator = ${param-description}

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(AllocatorType allocator) @safe nothrow pure;
        }
    }
}

/**
Convienience mixin that implmenets allocator aware interface by delegating it to decorated AllocatorAware component.
**/
mixin template AllocatorAwareMixin(T : AllocatorAware!Z, Z) {
    mixin AllocatorAwareMixin!Z;
}

/**
ditto
**/
mixin template AllocatorAwareMixin(Z) {
    import std.experimental.allocator : IAllocator, make, theAllocator;
    private {
        Z allocator_;
    }

    public {
        @property {
            /**
            Set allocator

            Params:
                allocator = allocator used to create components

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(Z allocator) @safe nothrow pure
            in {
                static if (is(Z == class) || is(Z == interface)) {

                    assert(allocator !is null);
                }
            }
            body {
                this.allocator_ = allocator;

                return this;
            }

            /**
            Get allocator

            Returns:
                Z
            **/
            Z allocator() @safe nothrow pure
            out(allocator) {
                assert(allocator !is null);
            }
            body {
                return this.allocator_;
            }
        }
    }
}

/**
Mixin containing default forwarding allocator properties for decorating components.
**/
mixin template AllocatorAwareDecoratorMixin(T : AllocatorAware!Z, Z)
    if (is(T : Decorator!X, X)) {
    import aermicioi.util.traits;
    import std.meta;
    import std.traits;

    public {
        @property {
            /**
            Set allocator

            Params:
                allocator = allocator to pass to decorated.

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(Z allocator) @safe nothrow pure {
                this.decorated.allocator = allocator;

                return this;
            }


            static if (is(T : Decorator!X, X) &&
                Filter!(
                eq!0,
                staticMap!(arity, __traits(getOverloads, X, "allocator"))
            ).length == 1) {

                /**
                Get allocator

                Returns:
                    IAllocator
                **/
                Z allocator() @safe nothrow pure {
                    return this.decorated.allocator;
                }
            }
        }
    }
}