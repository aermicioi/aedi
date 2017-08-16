/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Extending factories tutorial explained that library can be extended in two ways, 
factory direction and container direction. In AEDI framework containers have at least 
two responsibilities. The first one is to serve components, and the second one is to 
manage life time of served components.

Due to the first responsibility, AEDI has two basic containers, singleton and prototype. The
behavior of those two containers can be refound in other implementations of DIF like Spring frame-
work. Singleton container will serve same component no matter how many times a caller asks
it for a component associated with desired identity. Prototype container will serve new instance of
component each time it is asked by caller. Switchable decorating container presented decorated containers tutorial
limits in some sense the lifetime of it’s components only to the period when it is enabled.

A custom container should be implemented, only when existing ones are not providing features
required by the third party code (code that uses the framework). As stated, the purpose of a container
is to serve and manage components, and therefore a new implementation of a container should be
concerned with those tasks.

Compared to implementing a factory component, implementing a new container, requires it
to implement several interfaces. Each interface provides some functionality that can be used by
framework to enable some additional features related to container functionality. Implementation of
those interfaces is not imposed. The only requirement is to implement the basic Container interface
that exposes component serving abilities, along with option to instantiate them before their actual
usage. The following interfaces are allowed to be implemented by custom container:

$(UL
    $(LI $(D_INLINECODE Container) – exposes serving component features.)
    $(LI $(D_INLINECODE Storage) – exposes component factory storing capabilities.)
    $(LI $(D_INLINECODE FactoryLocator) – exposes component factory locating capabilities)
    $(LI $(D_INLINECODE AliasAware) – exposes aliasing of component’s identity to another identity)
    $(LI $(D_INLINECODE ConfigurableContainer) – exposes component factory storing capabilities along FactoryLocator and AliasAware)
)

Container:

Container interface is the minimal requirement for a custom container to implement, since it
offers component serving capabilities. Listing below presents the interface that is to be implemented
by custom containers. It is meaningful to implement only this interface when, container will not
integrate with any standard features that framework provides.

------------------
interface Container : Locator!(Object, string) {

    public {
        
        Container instantiate();
    }
}
------------------

Storage:

By implementing Storage interface, a container declares it’s ability to store component
factories in it. Listing below displays abilities required to be implemented by container. Once a
container implements the interface, the component registration system can use the container to store
factories in it. In other words it is possible to use $(D_INLINECODE register) method on custom container. The
interface does not enforce, how stored components are used internally by container. They can never
be used, or used for other purposes, rather than serving created components to caller. Though,
by convention it is assumed that stored factory components are used for right purpose of creating
components served by container, and deviating from this convention, will lead in ambiguity in code
api that must be documented exhaustive.

------------------
interface Storage(Type, KeyType) {
    
    public {
        
        Storage set(Type element, KeyType identity);
        
        Storage remove(KeyType identity);
    }
}
------------------

FactoryLocator:

FactoryLocator interface, implemented by a container, exposes ability for exterior code to
access stored factory components in a container. Listing below shows the abilities that a container must implement.

Such functionality is useful for postprocessing of component factories after they are registered
into container, for various purposes. One of them, is dynamically register tagged components as a
dependency to an event emmiter component. The FactoryLocator functionality allows for third party
library developers, to implement more complicated and useful features based on postprocessing of
factory components.

------------------
interface FactoryLocator(T : Factory!Z, Z) {
    import std.range.interfaces;
    import std.typecons;
    
    public {
        
        T getFactory(string identity);
        
        InputRange!(Tuple!(T, string)) getFactories();
    }
}
------------------

AliasAware:

AliasAware implemented by a containers, exposes an interface to exterior by which aliasing
of identities becomes possible. Listing below shows the methods that a container should implement.
The aliasing of component identities can become handy, when a library provides a container with
components, and another third party code is reliant on a component from this container, yet the
dependency is referenced with another identity. Aliasing will allow the referenced identity to be
aliased to right identity of component. Such cases can occur when a component from a library is
deprecated and removed, and it’s functionality is provided by another one identified differently. In
the end the aliasing mechanism allows a component from container to be associated with multiple
identities.

------------------
interface AliasAware(Type) {
    
    public {
        
        AliasAware link(Type identity, Type alias_);
        
        AliasAware unlink(Type alias_);
        
        const(Type) resolve(in Type alias_) const;
    }
}
------------------

ConfigurableContainer:

ConfigurableContainer interface is amalgation of previosly defined interfaces. Instead of
declaring entire list of interfaces a container should implement, it is easier to replace it with ConfigurableCo
interface. Listing below shows the abilities that a container must implement

------------------
interface ConfigurableContainer : Container, Storage!(ObjectFactory, string), AliasAware!(string), FactoryLocator!ObjectFactory {
	
}
------------------

Try to run example. Modify it, run it again to understand how to implement
your own container.

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
import std.range;
import std.typecons;

class MySingletonContainer : ConfigurableContainer {
    import std.stdio;
    private {
        
        Object[string] singletons;
        ObjectFactory[string] factories;
        
        string[string] aliasings;
        size_t levels;
    }
    
    public {
        
        MySingletonContainer set(ObjectFactory object, string key) {
            
            write("Registering component by ", key, " of type ", object.type.toString(), ": ");
            this.factories[key] = object;
            writeln("[..OK..]");
            
            return this;
        }
        
        MySingletonContainer remove(string key) {
            this.factories.remove(key);
            this.singletons.remove(key);
            
            return this;
        }
        
        Object get(string key) {
            writeln('\t'.repeat(levels), "Serving ", key, " component.");
            
            if ((this.resolve(key) in this.singletons) is null) {
                writeln('\t'.repeat(levels), key, " component not found.");
            
                if ((this.resolve(key) in this.factories) is null) {
                    throw new NotFoundException("Object with id " ~ key ~ " not found.");
                }
                
                writeln('\t'.repeat(levels), "Instantiating ", key, " component {");
                levels++;
            
                this.singletons[this.resolve(key)] = this.factories[this.resolve(key)].factory();
                levels--;
                writeln('\t'.repeat(levels), "}");
            }
            
            return this.singletons[key];
        }
        
        bool has(in string key) inout {
            return (key in this.factories) !is null;
        }
        
        MySingletonContainer instantiate() {
            import std.algorithm : filter;
            
            writeln("Booting container");
            foreach (pair; this.factories.byKeyValue.filter!((pair) => (pair.key in this.singletons) is null)) {
                
                writeln("Instantiating component ", pair.key, " {");
                levels++;
                this.singletons[pair.key] = pair.value.factory;
                levels--;
                writeln("}");
            }
            
            return this;
        }
        
        MySingletonContainer link(string key, string alias_) {
            this.aliasings[alias_] = key;
            
            return this;
        }
        
        MySingletonContainer unlink(string alias_) {
            this.remove(alias_);
            
            return this;
        }
        
        const(string) resolve(in string alias_) const {
            import std.typecons : Rebindable;
            Rebindable!(const(string)) aliased = alias_;
            
            while ((aliased in this.aliasings) !is null) {
                writeln("Resolving alias ", aliased, " to ", this.aliasings[aliased]);
                aliased = this.aliasings[aliased];
            }
            
            return aliased;
        }
        
        
        ObjectFactory getFactory(string identity) {
            return this.factories[identity];
        }
        
        InputRange!(Tuple!(ObjectFactory, string)) getFactories() {
            import std.algorithm;
            
            return this.factories.byKeyValue.map!(
                a => tuple(a.value, a.key)
            ).inputRangeObject;
        }
    }
}

/**
A struct that should be managed by container.
**/
struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
}

/**
Size of a car.
**/
struct Size {
    
    ulong width;
    ulong height;
    ulong length;
}

/**
Interface for engines.

An engine should implement it, in order to be installable in a car.
**/
interface Engine {
    
    public {
        
        void turnOn();
        void run();
        void turnOff();
        @property string vendor();
    }
}

/**
A concrete implementation of Engine that uses gasoline for propelling.
**/
class GasolineEngine : Engine {
    
    private {
        string vendor_;
    }
    
    public {
        @property {
        	GasolineEngine vendor(string vendor) @safe nothrow {
        		this.vendor_ = vendor;
        	
        		return this;
        	}
        	
        	string vendor() @safe nothrow {
        		return this.vendor_;
        	}
        }
        
        void turnOn() {
            writeln("pururukVrooomVrrr");
            
        }
        
        void run() {
            writeln("vrooom");
        }
        
        void turnOff() {
            writeln("vrrrPrrft");
        }
    }
}

/**
A concrete implementation of Engine that uses diesel for propelling.
**/
class DieselEngine : Engine {
    
    private {
        string vendor_;
    }
    
    public {
        @property {
        	DieselEngine vendor(string vendor) @safe nothrow {
        		this.vendor_ = vendor;
        	
        		return this;
        	}
        	
        	string vendor() @safe nothrow {
        		return this.vendor_;
        	}
        }
        
        void turnOn() {
            writeln("pururukVruumVrrr");
            
        }
        
        void run() {
            writeln("vruum");
        }
        
        void turnOff() {
            writeln("vrrrPft");
        }
    }
}

/**
A class representing a car.
**/
class Car {
    
    private {
        Color color_; // Car color
        Size size_; // Car size
        Engine engine_; // Car engine
    }
    
    public {
        
        /**
        Constructor of car.
        
        Constructs a car with a set of sizes. A car cannot of course have 
        undefined sizes, so we should provide it during construction.
        
        Params:
            size = size of a car.
        **/
        this(Size size, Engine engine) {
            this.size_ = size;
            this.engine = engine;
        }
        
        @property {
            
            /**
            Set color of car
            
            Set color of car. A car can live with undefined color (physics allow it).
            
            Params:
            	color = color of a car.
            
            Returns:
            	Car
            **/
            Car color(Color color) @safe nothrow {
            	this.color_ = color;
            
            	return this;
            }
            
            Color color() @safe nothrow {
            	return this.color_;
            }
            
            Size size() @safe nothrow {
            	return this.size_;
            }
            
            /**
            Set engine used in car.
            
            Params:
            	engine = engine used in car to propel it.
            
            Returns:
            	Car
            **/
            Car engine(Engine engine) @safe nothrow {
            	this.engine_ = engine;
            
            	return this;
            }
            
            Engine engine() @safe nothrow {
            	return this.engine_;
            }
        }
        
        void start() {
            engine.turnOn();
        }
        
        void run() {
            engine.run();
        }
        
        void stop() {
            engine.turnOff();
        }
    }
}

void drive(Car car, string name) {
    writeln("Uuh, what a nice car, ", name," with following specs:");
    writeln("Size:", car.size());
    writeln("Color:", car.color());
    
    writeln("Let's turn it on");
    car.start();
    
    writeln("What a nice sound! We should make a test drive!");
    car.run();
    
    writeln("Umm the test drive was awesome, let's get home and turn it off.");
    car.run();
    car.stop();
}

void main() {
    
    MySingletonContainer container = new MySingletonContainer;
    
    with (container.configure) {

        register!Color("color.green") // Register "green" color into container.
            .set!"r"(cast(ubyte) 0) 
            .set!"g"(cast(ubyte) 255)
            .set!"b"(cast(ubyte) 0);
        
        register!Size("size.sedan") // Register a size of a generic "sedan" into container
            .set!"width"(200UL) 
            .set!"height"(150UL)
            .set!"length"(500UL);
        
        register!(Engine, GasolineEngine)
            .set!"vendor"("Mundane motors"); // Register a gasoline engine as default implementation of an engine
        register!GasolineEngine
            .set!"vendor"("Elite motors"); // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
        register!DieselEngine
            .set!"vendor"("Hardcore motors"); // Register a diesel engine
        
        register!Car("sedan.engine.default") // Register a car with a default engine
            .construct("size.sedan".lref, lref!Engine)
            .set!"color"("color.green".lref);
            
        register!Car("sedan.engine.gasoline") // Register a car with gasoline engine
            .construct("size.sedan".lref, lref!GasolineEngine)
            .set!"color"("color.green".lref);
        
        register!Car("sedan.engine.diesel") // Register a car with diesel engine
            .construct("size.sedan".lref, lref!DieselEngine)
            .set!"color"("color.green".lref);
        
    }
    
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car("sedan.engine.default").drive("Default car");
    container.locate!Car("sedan.engine.gasoline").drive("Gasoline car");
    container.locate!Car("sedan.engine.diesel").drive("Diesel car");
}