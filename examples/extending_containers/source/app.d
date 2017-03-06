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
with rest of framework. Aedi was designed with purpose of extending it in two 
directions:

$(OL
    $(LI Containers -> responsible for created components. )
    $(LI Component factories -> responsible for creating components )
    )
    
This tutorial will show how to create your own container that can be easily 
integrated with rest of library and serve components using your own devised logic.

Containers in Aedi have two purposes:
$(OL
    $(LI Instantiate and serve components )
    $(LI Manage how long they live )
    )

From those two properties, it becomes clear why there are two basic containers in
Aedi, singleton and prototype one. First one serves same instance over it's entire
life (components lifetime is equal to containers lifetime), and
for second one it does serve new component version each time it is requested
(components in prototype container live as long as container lives as well).
Therefore, when custom lifetime management is needed or, custom logic on serving
and construction is needed, implement a brand new container for this.

Minimal requirements on a container in order to be used, is to implement 
Container interface:
------------------
interface Container : Locator!(Object, string) {

    public {
        
        Container instantiate();
    }
}
------------------

It consists of:
$(OL
    $(LI instantiate -> used to finish component instantiation/loading. Note container
    MUST be able to serve objects even before instantiate is called. )
    $(LI Locator!(Object, string) -> an interface for object providers which consists of following methods:
        $(OL
            $(LI get -> get an object. )
            $(LI has -> check if it has an object)
        ) 
    )
    )

By implementing it, your container can be used for serving components to the client, or
to other components that require dependencies stored in your container.
Yet, it does not provide a way to store component factories in it, or provide
additional capabilities that can be used to integrate even further with library
(and with .register api).

To allow your container to store component factories (which should be used to instantiate
components and not just store) in it, implement following interface:

------------------
interface ConfigurableContainer : Container, Storage!(ObjectFactory, string), AliasAware!(string), FactoryLocator!ObjectFactory {
	
}
------------------

Besides extending basic Container interface, it implements as well following interfaces:

$(OL
    $(LI Storage!(ObjectFactory, string) allows component factories to be stored in container )
    $(LI AliasAware!(string) allows identity aliasing )
    $(LI FactoryLocator!ObjectFactory provides methods to get component factories )
    )

The most important one for ability to store component factories is the first interface from
list:

------------------
interface Storage(Type, KeyType) {
    
    public {
        
        Storage set(Type element, KeyType identity);
        
        Storage remove(KeyType identity);
    }
}
------------------

The second interface allows user code to alias a component:

------------------
interface AliasAware(Type) {
    
    public {
        
        AliasAware link(Type identity, Type alias_);
        
        AliasAware unlink(Type alias_);
        
        const(Type) resolve(in Type alias_) const;
    }
}
------------------

A container implementing alias aware interface during serving,
should resolve identity of requested component, since the identity
can actually be an alias.

The third interface is used to provide access to stored factories:

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

Such capability can be useful in cases when some preproessors over containers
are run. A preprocessor knowing that container implements FactoryLocator!ObjectFactory
can navigate through entire set of factories, and perform some modifications
over them, or other stuff, like enabling another container if a component is
present etc.

For example purposes we'll implement our own singleton container that does
logging of get and instantiate actions. The container will implement ConfigurableContainer
interface since it provides all capabilities that can be used by rest of 
library and it's for example purposes to show how all four interface
implementations.

First of all we have to define our container:
------------------
class MySingletonContainer : ConfigurableContainer {
}
------------------

Second, it's important to define container fields that store
factories, aliasings and ofcourse instantiated components:
------------------
    private {
        
        Object[string] singletons;
        ObjectFactory[string] factories;
        
        string[string] aliasings;
        size_t levels;
    }
------------------
For aesthetic purposes levels variable was defined that will store identation
level used to print activity logs.

Once we have defined container's fields it's time for implementing methods from
ConfigurableContainer interface. Let's start with easiest ones which are set, and
remove:

------------------
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
------------------

You can encapsulate component factory in ExceptionChainingObjectFactory and 
InProcessObjectFactoryDecorator in order to print a stack of dependency 
errors, and detect circular reference errors. They are used by default in
all containers from Aedi.

Next we should implement has and get methods:
------------------
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
------------------

The get method checks first if component was already instantiated,
and if not, checks if a factory for it is present. If not it will
throw NotFoundException. If yes a component is created using respective
factory, and saved into singletons associative array from which it is returned.
Notice that at each step, the key is resolved to original identity, since
it can be actually an alias and not original identity by which component was
registered.

Once most important methods are implemented it's time to implement
instantiate method, which has the purpose of finishing component
instantiaton and well, other finishing stuff like freezing container
if needed:

------------------
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
------------------

It will simply instantiate all components that haven't been instantiated already.
The finishing touch is to add alias related functionality, and factory locator one:

------------------
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
------------------

Now we have a fully functional container. Let's store some components in it:
------------------
    MySingletonContainer container = new MySingletonContainer;
    
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
    
    container.register!(Engine, GasolineEngine)
        .set!"vendor"("Mundane motors"); // Register a gasoline engine as default implementation of an engine
    container.register!GasolineEngine
        .set!"vendor"("Elite motors"); // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
    container.register!DieselEngine
        .set!"vendor"("Hardcore motors"); // Register a diesel engine
    
    container.register!Car("sedan.engine.default") // Register a car with a default engine
        .construct("size.sedan".lref, lref!Engine)
        .set!"color"("color.green".lref);
        
    container.register!Car("sedan.engine.gasoline") // Register a car with gasoline engine
        .construct("size.sedan".lref, lref!GasolineEngine)
        .set!"color"("color.green".lref);
    
    container.register!Car("sedan.engine.diesel") // Register a car with diesel engine
        .construct("size.sedan".lref, lref!DieselEngine)
        .set!"color"("color.green".lref);
    
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car("sedan.engine.default").drive("Default car");
    container.locate!Car("sedan.engine.gasoline").drive("Gasoline car");
    container.locate!Car("sedan.engine.diesel").drive("Diesel car");
------------------

Running example will yield following output:

------------------
Registering component by color.green of type app.Color: [..OK..]
Registering component by size.sedan of type app.Size: [..OK..]
Registering component by app.Engine of type app.GasolineEngine: [..OK..]
Registering component by app.GasolineEngine of type app.GasolineEngine: [..OK..]
Registering component by app.DieselEngine of type app.DieselEngine: [..OK..]
Registering component by sedan.engine.default of type app.Car: [..OK..]
Registering component by sedan.engine.gasoline of type app.Car: [..OK..]
Registering component by sedan.engine.diesel of type app.Car: [..OK..]
Booting container
Instantiating component size.sedan {
}
Instantiating component sedan.engine.default {
	Serving size.sedan component.
	Serving app.Engine component.
	app.Engine component not found.
	Instantiating app.Engine component {
	}
	Serving color.green component.
	color.green component not found.
	Instantiating color.green component {
	}
}
Instantiating component app.GasolineEngine {
}
Instantiating component app.DieselEngine {
}
Instantiating component sedan.engine.diesel {
	Serving size.sedan component.
	Serving app.DieselEngine component.
	Serving color.green component.
}
Instantiating component sedan.engine.gasoline {
	Serving size.sedan component.
	Serving app.GasolineEngine component.
	Serving color.green component.
}
Serving sedan.engine.default component.
Uuh, what a nice car, Default car with following specs:
Size:Size(200, 150, 500)
Color:Color(0, 255, 0)
Let's turn it on
pururukVrooomVrrr
What a nice sound! We should make a test drive!
vrooom
Umm the test drive was awesome, let's get home and turn it off.
vrooom
vrrrPrrft
Serving sedan.engine.gasoline component.
Uuh, what a nice car, Gasoline car with following specs:
Size:Size(200, 150, 500)
Color:Color(0, 255, 0)
Let's turn it on
pururukVrooomVrrr
What a nice sound! We should make a test drive!
vrooom
Umm the test drive was awesome, let's get home and turn it off.
vrooom
vrrrPrrft
Serving sedan.engine.diesel component.
Uuh, what a nice car, Diesel car with following specs:
Size:Size(200, 150, 500)
Color:Color(0, 255, 0)
Let's turn it on
pururukVruumVrrr
What a nice sound! We should make a test drive!
vruum
Umm the test drive was awesome, let's get home and turn it off.
vruum
vrrrPft
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
    
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
    
    container.register!(Engine, GasolineEngine)
        .set!"vendor"("Mundane motors"); // Register a gasoline engine as default implementation of an engine
    container.register!GasolineEngine
        .set!"vendor"("Elite motors"); // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
    container.register!DieselEngine
        .set!"vendor"("Hardcore motors"); // Register a diesel engine
    
    container.register!Car("sedan.engine.default") // Register a car with a default engine
        .construct("size.sedan".lref, lref!Engine)
        .set!"color"("color.green".lref);
        
    container.register!Car("sedan.engine.gasoline") // Register a car with gasoline engine
        .construct("size.sedan".lref, lref!GasolineEngine)
        .set!"color"("color.green".lref);
    
    container.register!Car("sedan.engine.diesel") // Register a car with diesel engine
        .construct("size.sedan".lref, lref!DieselEngine)
        .set!"color"("color.green".lref);
    
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car("sedan.engine.default").drive("Default car");
    container.locate!Car("sedan.engine.gasoline").drive("Gasoline car");
    container.locate!Car("sedan.engine.diesel").drive("Diesel car");
}