/**
Contains factories and primitives used for building proxy objects.

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
module aermicioi.aedi.factory.proxy_factory;

import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.exception.di_exception;
import aermicioi.aedi.storage.locator_aware;

import aermicioi.aedi.util.traits;

import std.algorithm;
import std.meta;
import std.range;
import std.traits;
import std.typecons : AutoImplement;

/**
Creates a proxy to an object or interface of type T,
that is located in source locator by some identity.
**/
@safe class ProxyFactory(T) : Factory!T
    if (
        (
            is(T == class) &&
            !isFinalClass!T &&
            !isAbstractClass!T
        ) ||
        (is(T == interface))
    ) {

    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin, make, dispose, theAllocator;
    mixin AllocatorAwareMixin!(typeof(this));

    private {
        string identity_;
        Locator!() source_;
    }

    public {
        /**
            Constructor for ProxyFactory!(T)

            Params:
                identity = identity of original object stored in a locator
                original = locator that contains original object that a proxy should proxy.
        **/
        this(string identity, Locator!() original) {
            this.identity = identity;
            this.source = original;
            this.allocator = theAllocator;
        }

        /**
		Instantiates component of type T.

		Returns:
			T instantiated component of type T.
		**/
        Proxy!T factory() @trusted {
            auto proxy = this.allocator.make!(Proxy!T);
            proxy.__id__ = this.identity;
            proxy.__locator__ = this.source;

            return proxy;
        }

        /**
        Destructs a component of type T.

        Params:
            component = component that is to ve destroyed.

        Returns:

        **/
        void destruct(ref T component) @trusted {
            Proxy!T proxy = cast(Proxy!T) component;

            if (proxy !is null) {

                this.allocator.dispose(proxy);
                return;
            }

            import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;
            throw new InvalidCastException(
                "Cannot destruct component ${identity} because it is not a proxied object. Expected ${expected} while got ${actual}",
                null,
                typeid(Proxy!T),
                typeid(T)
            );
        }

        @property {
            /**
            Set the identity of proxied object

            Params:
            	identity = the identity of proxied object

            Returns:
            	this
            **/
            ProxyFactory!T identity(string identity) @safe nothrow {
            	this.identity_ = identity;

            	return this;
            }

            /**
            Get the identity of proxied object.

            Returns:
            	string identity
            **/
            string identity() @safe nothrow {
            	return this.identity_;
            }

            /**
            Set the source of proxied object.

            Params:
            	source = source locator where proxied object resides.

            Returns:
            	this
            **/
            ProxyFactory!T source(Locator!() source) @safe nothrow {
            	this.source_ = source;

            	return this;
            }

            /**
            Get the source of proxied object.

            Returns:
            	Locator!() source
            **/
            Locator!() source() @safe nothrow {
            	return this.source_;
            }

            /**
            Set locator

            Params:
                locator = locator or source of original component proxied by proxy
            Returns:
                typeof(this)
            **/
            LocatorAware!(Object, string) locator(Locator!(Object, string) locator) @safe nothrow {
                this.source = locator;

                return this;
            }

            /**
            Get locator

            Returns:
                Locator!()
            **/
            Locator!() locator() @safe nothrow {
                return this.source;
            }

            /**
    		Get the type info of T that is created.

    		Returns:
    			TypeInfo object of created component.
    		**/
            TypeInfo type() @safe nothrow const {
                return typeid(Proxy!T);
            }

        }
    }
}

/**
Auto implements a proxy for object or interface of type T which
is not a final or abstract class.

Warning:
    Current implmentation uses AutoImplement from phobos which
    has some unfixed bugs.
**/
template ProxyImpl(T)
    if (
        (
            is(T == class) &&
            !isFinalClass!T &&
            !isAbstractClass!T
        ) ||
        is(T == interface)
    ) {

    class ProxyImpl : T {
        private {

            Locator!() __locator_;
            string __id_;
        }

        public {

            this() {
                super();
            }
        }

        @property public {
            ProxyImpl!T __locator__(Locator!() locator) @safe nothrow @nogc {
            	this.__locator_ = locator;

            	return this;
            }

            Locator!() __locator__() @safe nothrow @nogc {
            	return this.__locator_;
            }

            ProxyImpl!T __id__(string id) @safe nothrow @nogc {
            	this.__id_ = id;

            	return this;
            }

            string __id__() @safe nothrow @nogc {
            	return this.__id_;
            }
        }
    }
}

template how(T) {
    static string how(C, alias fun)() {
        static if (identifier!fun == "__ctor") {
            pragma(msg, "here");
            return q{super(args)};
        } static if (identifier!fun == "__dtor") {
            return q{};
        } else {

            string stmt = q{
                import aermicioi.aedi.storage.locator;
                import aermicioi.aedi.exception.di_exception;
                import aermicioi.aedi.factory.proxy_factory;
                } ~ fullyQualifiedName!T ~ " original;
                try {
                    original = this.__locator__.locate!(" ~ fullyQualifiedName!T ~ ")(this.__id__);
                } catch (Exception e) {
                    assert(false, \"Failed to fetch \" ~ __id__ ~ \" in proxy object.\");
                }
            ";

            static if (!is(ReturnType!fun == void)) {
                stmt ~= "
                    return original." ~ __traits(identifier, fun) ~ "(args);
                ";
            } else {
                stmt ~= "
                    original." ~ __traits(identifier, fun) ~ "(args);
                ";
            }

            return stmt;
        }

    }
}

alias Proxy(T) = AutoImplement!(ProxyImpl!T, how!T, templateAnd!(
        templateNot!isFinalFunction
));

/**
A ProxyObjectFactory instantiates a proxy to some type of object located in source locator.
**/
@safe interface ProxyObjectFactory : ObjectFactory {

    @property {

        /**
        Get the identity of original object that proxy factory will intantiate proxy object.

        Returns:
        	string the original object identity
        **/
        string identity() @safe nothrow;

        /**
        Get the original locator that is used by proxy to fetch the proxied object.

        Returns:
        	Locator!() original locator containing the proxied object.
        **/
        Locator!() source() @safe nothrow;
    }
}

/**
Proxy factory decorator, that conforms to requirements of a container, exposing as well the ability
to set proxied object's identity and locator.
**/
@safe class ProxyObjectWrappingFactory(T) : ProxyObjectFactory, MutableDecorator!(ProxyFactory!T)
    if (is(T : Object) && !isFinalClass!T) {

    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin;
    mixin AllocatorAwareMixin!(typeof(this));

    private {
        ProxyFactory!T decorated_;

    }

    public {

        /**
        Constructor for ProxyObjectWrappingFactory!T

        Params:
            factory = proxy factory that is decorated
        **/
        this(ProxyFactory!T factory) {
            this.decorated = factory;
        }

        @property {
            /**
            Get the identity of original object that proxy factory will intantiate proxy object.

            Returns:
                string the original object identity
            **/
            ProxyObjectWrappingFactory!T identity(string identity) @safe nothrow {
            	this.decorated.identity = identity;

            	return this;
            }

            /**
            Get identity

            Returns:
                string
            **/
            string identity() @safe nothrow {
            	return this.decorated.identity;
            }

            /**
            Get the original locator that is used by proxy to fetch the proxied object.

            Returns:
                Locator!() original locator containing the proxied object.
            **/
            ProxyObjectWrappingFactory!T source(Locator!() source) @safe nothrow {
            	this.decorated.source = source;

            	return this;
            }

            /**
            Get source

            Returns:
                Locator!()
            **/
            Locator!() source() @safe nothrow {
            	return this.decorated.source;
            }

            mixin MutableDecoratorMixin!(ProxyFactory!T);

            /**
            Set a locator to object.

            Params:
                locator = the locator that is set to oject.

            Returns:
                LocatorAware.
            **/
            ProxyObjectWrappingFactory!T locator(Locator!() locator) @safe nothrow {
            	this.decorated.locator = locator;

            	return this;
            }

            /**
            Get locator

            Returns:
                Locator!()
            **/
            Locator!() locator() @safe nothrow {
            	return this.decorated.locator;
            }

            /**
    		Get the type info of T that is created.

    		Returns:
    			TypeInfo object of created component.
    		**/
            TypeInfo type() @safe nothrow const {
                return this.decorated.type;
            }
        }
        /**
		Instantiates component of type Object.

		Returns:
			Object instantiated component.
		**/
        Object factory() @safe {
            return this.decorated.factory();
        }

        /**
        Destructs a component of type T.

        Params:
            component = component that is to ve destroyed.

        Returns:

        **/
        void destruct(ref Object component) @safe
        in (component !is null, "Cannot destroy a null component, expected component of type " ~ typeid(T).toString) {
            T proxy = cast(T) component;

            if (proxy !is null) {

                this.decorated.destruct(proxy);
                return;
            }

            import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;
            throw new InvalidCastException(
                "Cannot destruct component ${identity} because it is not managed by this proxy factory. Expected ${expected} while got ${actual}",
                null,
                typeid(Proxy!T),
                component.classinfo
            );
        }
    }
}
