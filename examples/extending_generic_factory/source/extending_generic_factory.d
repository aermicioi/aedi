/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

The interface presented in previous tutorial is a minimalistic interface, and does not provide any ability to
customize the component that is created. It is practically a black box, that is convenient to use by
containers, and not by client code that needs to configure components registered in container.

To support better configuration, without loosing black boxiness of presented $(D_INLINECODE Factory) interface,
the process of creating and configuring a component was split into three distinct steps below:
$(OL
    $(LI Allocation and construction of component )
    $(LI Configuration of component )
    $(LI Destruct and deallocation of component)
    )

The following steps are formalized into a set of interfaces shown below, where each step
itself is encapsulated into objects implementing presented interfaces.

--------------------
interface PropertyConfigurer(T) : LocatorAware!() {

    public {

        void configure(ref T object);
    }
}

interface InstanceFactory(T) : LocatorAware!(), AllocatorAware!() {

    public {

        T factory();
    }
}

interface InstanceDestructor(T) : LocatorAware!(), AllocatorAware!() {

    public {

        void destruct(ref T destructable);
    }
}

interface GenericFactory(T) : Factory!T, InstanceFactoryAware!T, PropertyConfigurersAware!T {

    public {

        @property {

            alias locator = Factory!T.locator;

            Locator!() locator();
        }
    }
}

interface InstanceFactoryAware(T) {
    public {

        @property {
            InstanceFactoryAware!T setInstanceFactory(InstanceFactory!T factory);
        }
    }
}

interface InstanceDestructorAware(T) {
    public {

        @property {
            InstanceDestructorAware!T setInstanceDestructor(InstanceDestructor!T destructor);
        }
    }
}

interface PropertyConfigurersAware(T) {
    public {
        PropertyConfigurersAware!T addPropertyConfigurer(PropertyConfigurer!T configurer);
    }
}
--------------------

The methods used to configure components in examples up to this point are actually wrappers
over building blocks that implement interfaces presented above. $(D_INLINECODE register) method is a
wrapper over an implementation of $(D_INLINECODE GenericFactory) interface.

When instantiation or configuration of a component is not possible to implement in terms of
existing tools and interfaces provided by the framework, it is recommended to implement one of
building block interface, depending on what stage the problem resides. For car simulation app, with-
out reason the company decided that tires, should be instantiated using their own implementation of
instance building block. Same with inflating a tire they've decided to use their own implementation,
along with tire recycling, making a closed production cycle.

Next example shows a custom implementation of tire manufacturing process. By implementing
$(D_INLINECODE InstanceFactory) interface, the building block can be used along the rest of components already
present in framework, such as $(D_INLINECODE GenericFactory). The only hinder is that what remains is the ugliness, and
verbosity, due to need to manually instantiate the building block, and pass to generic factory. Instead
of manually doing it, wrapping instantiator into a function will lessen the verbosity (check $(D_INLINECODE makeTire)
definition and usage), and increase the readability of configuration code, thanks to UFCS feature of
D programming language.

--------------------
auto makeTire(T : GenericFactory!Z, Z : Tire)(auto ref T factory, int size) {
    factory.setInstanceFactory(new TireConstructorInstanceFactory(size));

    return factory;
}

class TireConstructorInstanceFactory : InstanceFactory!Tire {

    private {
        int size;

        Locator!(Object, string) locator_;
        RCIAllocator allocator_;
    }

    public {
        this(int size) {
            this.size = size;
        }

        @property {
            TireConstructorInstanceFactory locator(Locator!(Object, string) locator) {
                this.locator_ = locator;

                return this;
            }

            TireConstructorInstanceFactory allocator(RCIAllocator allocator) pure nothrow @safe {
                this.allocator_ = allocator;

                return this;
            }
        }

        Tire factory() {
            Tire tire;

            import std.stdio;

            write("Creating a tire of ", size, " inches: ");
            tire = this.allocator_.make!Tire;
            tire.size = size;
            writeln("\t[..OK..]");

            return tire;
        }
    }
}
--------------------

The code for tire inflator configurer can be seen in examples from source code. The difference
from $(D_INLINECODE TireConstructorInstanceFactory) is that implementation should extend $(D_INLINECODE PropertyConfigurer).
Same can be said about tire destructor, it implements $(D_INLINECODE InstanceDestructor) to provide
destruction mechanisms for generic factory.

Once the custom implementation and their wrapper are implemented, it is possible to use them
as any other built-in building blocks from framework. Next example shows how implemented building
blocks can be used along with other configuration primitives.
--------------------
void main() {

    SingletonContainer container = new SingletonContainer;
    scope (exit) container.terminate();

    with (container.configure) {

        register!Tire("logging.tire")
            .makeTire(17)
            .inflateTire(3.0)
            .set!"vendor"("hell tire")
            .destroyTire;
    }

    container.instantiate();

    container.locate!Tire("logging.tire").writeln;
}
--------------------

Running it, produces following result:
--------------------
Creating a tire of 17 inches: 	[..OK..]
Inflating tire to 3 atm: 	[..OK..]
Tire(17 inch, 3 atm, hell tire)
Destroying tire:        [..OK..]
--------------------

Try to implement your own instance factory or property configurer, wrap them
in a function, and use in component configuration. Try to do this for $(D_INLINECODE Car)
component from previous examples.

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

module extending_generic_factory;

import aermicioi.aedi;
import std.stdio;
import std.experimental.allocator;

class TireConstructorInstanceFactory : InstanceFactory!Tire {

    private {
        int size;

        Locator!(Object, string) locator_;
        RCIAllocator allocator_;
    }

    public {
        this(int size) {
            this.size = size;
        }

        @property {
            TireConstructorInstanceFactory locator(Locator!(Object, string) locator) {
                this.locator_ = locator;

                return this;
            }

            TireConstructorInstanceFactory allocator(RCIAllocator allocator) pure nothrow @safe {
                this.allocator_ = allocator;

                return this;
            }
        }

        Tire factory() @trusted {
            Tire tire;

            import std.stdio;

            write("Creating a tire of ", size, " inches: ");
            tire = this.allocator_.make!Tire;
            tire.size = size;
            writeln("\t[..OK..]");

            return tire;
        }
    }
}

class TireInflatorConfigurer : PropertyConfigurer!Tire {

    private {
        float atmospheres;
        Locator!() locator_;
    }

    public {

        this(float atmospheres = 3.0) {
            this.atmospheres = atmospheres;
        }

        @property {
            TireInflatorConfigurer locator(Locator!(Object, string) locator) {
                this.locator_ = locator;

                return this;
            }
        }

        void configure(ref Tire tire) {

            import std.stdio;

            write("Inflating tire to ", atmospheres, " atm: ");
            tire.pressure = atmospheres;
            writeln("\t[..OK..]");
        }
    }
}

class TireInstanceDestructor : InstanceDestructor!Tire {
    mixin LocatorAwareMixin!TireInstanceDestructor;
    mixin AllocatorAwareMixin!TireInstanceDestructor;

    public {
        void destruct(ref Tire destructable) @trusted {
            write("Destroying tire: ");
            this.allocator.dispose(destructable);
            writeln("\t[..OK..]");
        }
    }
}

auto makeTire(T : GenericFactory!Z, Z : Tire)(auto ref T factory, int size) {
    factory.setInstanceFactory(new TireConstructorInstanceFactory(size));

    return factory;
}

auto inflateTire(T : GenericFactory!Z, Z : Tire)(auto ref T factory, float pressure) {
    factory.addPropertyConfigurer(new TireInflatorConfigurer(pressure));

    return factory;
}

auto destroyTire(T : GenericFactory!Z, Z : Tire)(auto ref T factory) {
    factory.setInstanceDestructor(new TireInstanceDestructor());

    return factory;
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

void main() {

    SingletonContainer container = new SingletonContainer;
    scope (exit) container.terminate();

    with (container.configure) {

        register!Tire("logging.tire")
            .makeTire(17)
            .inflateTire(3.0)
            .set!"vendor"("hell tire")
            .destroyTire;
    }

    container.instantiate();

    container.locate!Tire("logging.tire").writeln;
}