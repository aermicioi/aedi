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
	aermicioi
**/
module aermicioi.aedi.storage.wrapper;

import std.traits;
import std.meta : staticMap;

interface Wrapper(T) {
    public {
        @property ref T value();

        alias value this;
    }
}

interface Castable(T) {
    public {
        @property T casted();

        alias casted this;
    }
}

/**
Wrapper over some component of type T.

Wraps up a value of type T, and aliases itself to it. This object is used
wrap any component that is not of reference type (class or interface),
in order to be saveable into an object storage.
Also thanks to alias value this semantics, in D is possible to do automatic
unboxing of values, just like Java does with simple values :P.
**/
class WrapperImpl(T) : Wrapper!T {
    mixin WrapperMixin!T;
}

/**
ditto
**/
class CastableWrapperImpl(T, Castables...) : Wrapper!T, staticMap!(toCastable, Castables) {
    import std.meta;
    import aermicioi.util.traits;
    mixin WrapperMixin!T;

    mixin CastableMixin!(Castables);
}

private {

    mixin template WrapperMixin(T) {
        private {
            T value_;
        }

        public {

            this() @disable;

            this(ref T value) {
                this.value_ = value;
            }

            this(T value) {
                this.value_ = value;
            }

            @property ref T value() {
                return this.value_;
            }
        }
    }

    mixin template CastableMixin() {

    }

    mixin template CastableMixin(Type) {
        @property {
            Type casted() {
                return cast(Type) this.value;
            }
        }
    }

    mixin template CastableMixin(Type, Second, More...) {

        mixin CastableMixin!(Type);

        mixin CastableMixin!(Second);

        mixin CastableMixin!(More);
    }

    template toCastable(T) {
        alias toCastable = Castable!T;
    }
}
