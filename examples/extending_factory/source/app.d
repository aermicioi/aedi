/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

For an end consumer of Aedi library, it is rarely needed to extend it's logic
with something new. But for a developer that wants to integrate Aedi library
with his/her framework, sometimes it is required to extend library to integrate it
with rest of framework. Aedi was designed with purpose of extending it in two directions:

$(OL
    $(LI Containers -> responsible for created components. )
    $(LI Component factories -> responsible for creating components )
    )

A component factory, as name states is responsible for creation and assembly of components
registered in container, as well as destroying them. Containers are using them to instantiate components,
that are requested. In all tutorials up to this registering a component, was equivalent to creating a
factory for it, and registering it in container. Afterwards factory was returned to the client code, were it was
further configured, with construction and setter injections by code.

When the default features of framework are not enough, it is possible to extend it, in several
directions mentioned above. For defining a new way of creating components, a factory interface
in listing below is shown, which is minimal requirement for having the custom factories useable by
containers. A factory encapsulates the logic required as to create and destroy a component.

------------------
interface Factory(T) : LocatorAware!(), AllocatorAware!() {

	public {

		T factory();
        void destruct(ref T component);

		@property {
    		TypeInfo type();
		}
	}
}
------------------

For example purposes, during development of car simulation app, logging of car assembly
should be done. Example below shows a simple logging component factory that creates components
using zero argument constructor, and logs the construction using default logging facilities present in
D programming language.

------------------
class LoggingFactory(T) : Factory!T {
    private {
        Locator!() locator_;
        IAllocator allocator_;
    }

    public {
        @property {
            typeof(this) allocator(IAllocator allocator) @safe nothrow pure {
                this.allocator_ = allocator;

                return this;
            }

            IAllocator allocator() @safe nothrow pure {
                return this.allocator_;
            }
        }

        T factory() {
            import std.experimental.logger;

            info("Creating component");
            static if (is(T : Object)) {
                auto t = this.allocator.make!T;
            } else {
                auto t = T();
            }
            info("Ended component creation");

            return t;
        }

        void destruct(ref T component) {
            import std.experimental.logger;

            info("Destroying component");
            static if (is(T : Object)) {
                this.allocator.dispose(component);
                info("Done destroying component");
            } else {
                info("Value component nothing to destroy");
            }
        }

        TypeInfo type() {
            return typeid(T);
        }

        LoggingFactory!T locator(Locator!() locator) @safe nothrow {
        	this.locator_ = locator;

        	return this;
        }
    }
}
------------------

A design decision in framework was made, that all containers must store only objects rooted
in Object class. Since the language in which framework is developed supports not only object, but
structs, unions and a multitude of value based types, those types should be wrapped into an object
to be stored into containers. By convention, it is assumed that value based data is wrapped in an
implementation of $(D_INLINECODE Wrapper) interface which roots into Object class. Knowing this, factories that
attempt to supply value based dependencies to components, fetch the wrapped components from
container, extracts the component from wrapper and pass it to the component.

From the constraint that containers apply on accepted types (rooted in Object), the same requirements are propagated
to component factories which are stored in containers. To leverage this problem, framework
provides a decorating factory, that wraps up another factory, and exposes an compatible interface
for containers. It will automatically wrap any component that is not rooted in Object class into a
$(D_INLINECODE Wrapper) implementation and give it further to container.

For aesthetic purposes it is recommended any creation of a factory to be wrapped in a function,
which itself can serve as a facade to implementation, and be integrated seamlessly in code api.
Example below shows an example of such a wrapper, that handles creation of a component factory and
wrapping it in a compatible interface for containers.

------------------
auto registerLogged(Type)(Storage!(ObjectFactory, string) container, string identity) {
    auto factory = new LoggingFactory!Type;
    container.set(new WrappingFactory!(LoggingFactory!Type)(factory), identity);

    return factory;
}
------------------

To test custom component factory example below shows how it can be used seamlessly and
unknowingly from the point of view of a user of library.

------------------
void main() {

    SingletonContainer container = singleton();

    container.registerLogged!Tire("logging.tire");
    container.registerLogged!int("logging.int");

    container.instantiate();

    container.locate!Tire("logging.tire").writeln;
    container.locate!int("logging.int").writeln;
}
------------------

Running the container we will get following result:
------------------
2017-03-04T00:34:33.401:app.d:factory:161 Creating our little component
2017-03-04T00:34:33.401:app.d:factory:167 Ended creation of component
2017-03-04T00:34:33.401:app.d:factory:161 Creating our little component
2017-03-04T00:34:33.401:app.d:factory:167 Ended creation of component
Tire(0 inch, nan atm, )
0
------------------

As we can see our logging factory is doing designed job.
Try to implement your own factory, to understand how Aedi works behind the scenes.

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

module app;

import aermicioi.aedi;
import std.stdio;
import std.experimental.allocator;

class LoggingFactory(T) : Factory!T {
    private {
        Locator!() locator_;
        IAllocator allocator_;
    }

    public {
        @property {
            /**
            Set allocator

            Params:
                allocator = allocator that is used to allocate the component

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(IAllocator allocator) @safe nothrow pure {
                this.allocator_ = allocator;

                return this;
            }

            /**
            Get allocator

            Returns:
                IAllocator
            **/
            inout(IAllocator) allocator() @safe nothrow pure inout {
                return this.allocator_;
            }
        }

        T factory() {
            import std.experimental.logger;

            info("Creating component");
            static if (is(T : Object)) {
                auto t = this.allocator.make!T;
            } else {
                auto t = T();
            }
            info("Ended component creation");

            return t;
        }

        void destruct(ref T component) {
            import std.experimental.logger;

            info("Destroying component");
            static if (is(T : Object)) {
                this.allocator.dispose(component);
                info("Done destroying component");
            } else {
                info("Value component nothing to destroy");
            }
        }

        TypeInfo type() const {
            return typeid(T);
        }

        LoggingFactory!T locator(Locator!() locator) @safe nothrow {
        	this.locator_ = locator;

        	return this;
        }
    }
}

class Tire {
    private {
        int size_;
        float pressure_;
        string vendor_;
    }

    public @property {
        Tire size(int size) @safe nothrow {
        	this.size_ = size;

        	return this;
        }

        int size() @safe nothrow {
        	return this.size_;
        }

        Tire pressure(float pressure) @safe nothrow {
        	this.pressure_ = pressure;

        	return this;
        }

        float pressure() @safe nothrow {
        	return this.pressure_;
        }

        Tire vendor(string vendor) @safe nothrow {
        	this.vendor_ = vendor;

        	return this;
        }

        string vendor() @safe nothrow {
        	return this.vendor_;
        }
    }

    public override string toString() {
        import std.algorithm;
        import std.range;
        import std.conv;
        import std.utf;

        return only("Tire(", this.size.to!string, " inch, ", this.pressure.to!string, " atm, ", this.vendor, ")")
            .joiner
            .byChar
            .array;
    }
}

auto registerLogged(Type)(Storage!(ObjectFactory, string) container, string identity) {
    auto factory = new LoggingFactory!Type;
    container.set(new WrappingFactory!(LoggingFactory!Type)(factory), identity);

    return factory;
}

void main() {

    SingletonContainer container = singleton();
    scope (exit) container.terminate();

    container.registerLogged!Tire("logging.tire");
    container.registerLogged!int("logging.int");

    container.instantiate();

    container.locate!Tire("logging.tire").writeln;
    container.locate!int("logging.int").writeln;
}