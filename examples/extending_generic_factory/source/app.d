/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

This tutorial, will explain how to separate component construction in two
distinct steps with builtin primitives:
$(OL
    $(LI Allocation and construction of component )
    $(LI Configuration of component )
    )
It will explain how to integrate those steps in fluent manner to be used
along with Aedi api for configuring components.

Tutorial on extending component factory, did show the ground on which
component construction is built in Aedi. On top of it, in order to allow
more modular and easier configuration, the process of constructing a component
was split in two steps shown above. It was done so by defining an interface
(and implementation) for factories that allows to configure those steps:
--------------------
interface GenericFactory(T) : Factory!T {
    
    public {
        
        @property {
            
            GenericFactory!T setInstanceFactory(InstanceFactory!T factory);
            
            Locator!() locator();
        }
        
        GenericFactory!T addPropertyConfigurer(PropertyConfigurer!T configurer);
    }
}
-------------------- 

GenericFactory interface provides two methods for configuring those steps:
$(OL
    $(LI setInstanceFactory -> set instance factory which encapsulates allocation and construction logic. )
    $(LI addPropertyConfigurer -> adds a configurer that performs some operations on created component. )
    )

From method definition we can see that, each step is encapsulated in an object implementing
following interfaces:
--------------------
interface InstanceFactory(T) {
    
    public {
        
        T factory();
    }
}

interface PropertyConfigurer(T) {
    
    public {
        
        void configure(ref T object);
    }
}
--------------------

The first interface is used to implement objects that encapsulate allocation and construction
logic. The second one is used to implement objects that encapsulate configuration logic on components.

For tutorial purposes, we will implement two objects (one for instantiation, and other for configuration)
which will create and inflate a tire for us. It will log performed actions as well.
Let's define those implementations:
--------------------
class TireConstructorInstanceFactory : InstanceFactory!Tire {
    
    private {
        int size;
    }
    
    public {
        this(int size) {
            this.size = size;
        }
        
        Tire factory() {
            Tire tire;
            
            import std.stdio;
            
            write("Creating a tire of ", size, " inches: ");
            tire = new Tire();
            tire.size = size;
            writeln("\t[..OK..]");
            
            return tire;
        }
    }
}

class TireInflatorConfigurer : PropertyConfigurer!Tire {
    
    private {
        float atmospheres;
    }
    
    public {
        
        this(float atmospheres = 3.0) {
            this.atmospheres = atmospheres;
        }
        
        void configure(ref Tire tire) {
            
            import std.stdio;
            
            write("Inflating tire to ", atmospheres, " atm: ");
            tire.pressure = atmospheres;
            writeln("\t[..OK..]");
        }
    }
}
--------------------

The implementation of those interfaces for Tire is straightforward, yet
inserting them into generic factory would look something like:
--------------------
genericFactory.setInstanceFactory(new TireConstructorInstanceFactory(17));
genericFactory.addPropertyConfigurer(new TireInflatorConfigurer(3.0));
--------------------
which is not quite readable.
D language has a nice feature which is called UFCS (unified function call syntax)
which allows us to call functions as like they are methods of their first argument.
Let's implement wrapper functions that do this:
--------------------
auto makeTire(T : GenericFactory!Z, Z : Tire)(auto ref T factory, int size) {
    factory.setInstanceFactory(new TireConstructorInstanceFactory(size));
    
    return factory;
}

auto inflateTire(T : GenericFactory!Z, Z : Tire)(auto ref T factory, float pressure) {
    factory.addPropertyConfigurer(new TireInflatorConfigurer(pressure));
    
    return factory;
}
--------------------

Now it is possible to set our implented objects in generic factory like that:
--------------------
genericFactory
    .makeTire(17)
    .infateTire(3.0);
--------------------

Wrapper version is more readable, comparing to setting them directly. We can chain configuration commands,
and it is possible to use autodetection of types based on arguments passed in 
function, which leverages us from writing them manually when creating instance 
factory or property configurer in case when they have template arguments.
Notice that we do interact directly with implementation of GenericFactory (T type argument),
and not through interface. It is done so, because some parts of
configuration api can work only with concrete implementation, and we should
return original implementation in order to use that api in command chaining.
Returning only the interface can disable some configuration features present in Aedi.

The configuration api used in all tutorials up to this point, actually use generic 
factory to build a factory consisting of constructor, and configuration steps.
The .register method actually creates an implementation of generic factory, that
is set in container, and returned afterwards for configuration. Methods used like
.constructor or .set on registered component, are actually wrapper functions just like
examples shown above, that set in generic factory, instance factories or 
configurers. They are used for chaining commands (which is why wrappers should
return concrete implementation of generic factory, since some parts of configuration api
works only with implementation returned from .register method), as well as autodetecting argument's
type, when needed. Template arguments are not deduced from templated class constructor, that's why
using wrappers over instance factories or property configurers is desired.

Now knowing that a .register method actually returns a generic factory implementation
and having wrapper functions over TireConstructorInstanceFactory and TireInflatorConfigurer,
it is possible to write following nice configuration:
--------------------
    SingletonContainer container = new SingletonContainer;
    
    container.register!Tire("logging.tire")
        .makeTire(17)
        .inflateTire(3.0)
        .set!"vendor"("hell tire");
    
    container.instantiate();
    
    container.locate!Tire("logging.tire").writeln;
--------------------

Running it, produces following result:
--------------------
Creating a tire of 17 inches: 	[..OK..]
Inflating tire to 3 atm: 	[..OK..]
Tire(17 inch, 3 atm, hell tire)
--------------------

Try to implement your own instance factory or property configurer, wrap them
in a function, and use in component configuration. Try to do this for Car
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

module app;

import aermicioi.aedi;
import std.stdio;

class TireConstructorInstanceFactory : InstanceFactory!Tire {
    
    private {
        int size;
    }
    
    public {
        this(int size) {
            this.size = size;
        }
        
        Tire factory() {
            Tire tire;
            
            import std.stdio;
            
            write("Creating a tire of ", size, " inches: ");
            tire = new Tire();
            tire.size = size;
            writeln("\t[..OK..]");
            
            return tire;
        }
    }
}

class TireInflatorConfigurer : PropertyConfigurer!Tire {
    
    private {
        float atmospheres;
    }
    
    public {
        
        this(float atmospheres = 3.0) {
            this.atmospheres = atmospheres;
        }
        
        void configure(ref Tire tire) {
            
            import std.stdio;
            
            write("Inflating tire to ", atmospheres, " atm: ");
            tire.pressure = atmospheres;
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
    
    container.register!Tire("logging.tire")
        .makeTire(17)
        .inflateTire(3.0)
        .set!"vendor"("hell tire");
    
    container.instantiate();
    
    container.locate!Tire("logging.tire").writeln;
}