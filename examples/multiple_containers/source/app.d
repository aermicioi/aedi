/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

In this tutorial, we're going to learn more about containers, and how we
can use them together to build a more sophisticated construction/wiring logic.

Let's start by improving previous example. If we think a little, a car that
has wheels without tires, won't work at full capacity. It's possible to break
wheel's rim if used without a tire. Then let's add tires to our car. 
To improve our example, we'll have to add a Tire class that represents a tire,
and patch our car to allow it to install tires for each wheel it does have:
----------------
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

class Car {
    
    private {
//        ..........check full example..........
        Tire frontLeft_;
        Tire frontRight_;
        Tire backLeft_;
        Tire backRight_;
    }
    
    public {
        
        this(Size size, Engine engine) {
            this.size_ = size;
            this.engine = engine;
        }
        
        @property {
            
//            ..........check full example..........
            
            Car frontLeft(Tire frontLeft) @safe nothrow {
            	this.frontLeft_ = frontLeft;
            
            	return this;
            }
            
            Tire frontLeft() @safe nothrow {
            	return this.frontLeft_;
            }
            
            Car frontRight(Tire frontRight) @safe nothrow {
            	this.frontRight_ = frontRight;
            
            	return this;
            }
            
            Tire frontRight() @safe nothrow {
            	return this.frontRight_;
            }
            
            Car backLeft(Tire backLeft) @safe nothrow {
            	this.backLeft_ = backLeft;
            
            	return this;
            }
            
            Tire backLeft() @safe nothrow {
            	return this.backLeft_;
            }
            
            Car backRight(Tire backRight) @safe nothrow {
            	this.backRight_ = backRight;
            
            	return this;
            }
            
            Tire backRight() @safe nothrow {
            	return this.backRight_;
            }
            
        }
        
//        ..........check full example..........
    }
}
----------------

Nice now we're able to install tires onto our car. Let's do it using Aedi library:
----------------
//	..........code from example..........
    container.registerInto!Tire
        .set!"size"(17)
        .set!"pressure"(3.0)
        .set!"vendor"("divine tire");
        
    container.registerInto!Car
        .autowire
        .autowire!"color"
        .set!"frontLeft"(lref!Tire)
        .set!"frontRight"(lref!Tire)
        .set!"backLeft"(lref!Tire)
        .set!"backRight"(lref!Tire);
//	..........code from example..........
----------------

Now we can instantiate our container and run our car! But wait, won't we try to
install same tire on all wheels of our car, if we configured Aedi like in example
above? Try to run example, and to be sure assert that wheels are different
after container has booted. Just like this:
----------------
    assert(
        container.locate!Car.frontLeft !is
        container.locate!Car.frontRight
    );
----------------

We will fail, since Aedi will install same tire for all wheels, which is not
a desired result in our case. Each tire in our car, can have it's own pressure,
size, and vendor, it's not possible for all four to have same parameters. Yet
we are doing so, using above configuration. Then, how we should solve this problem?
A bright idea could come to your mind: "Let's just create for each wheel a new tire, and
that's all. But how we can do it using Aedi?". First of all let's take a look at 
type of our container:
----------------
    SingletonContainer container = new SingletonContainer;
---------------- 

Notice that type, contains `Singleton` in it's name. If your familiar with Singleton pattern
(please familiarize yourself with Singleton pattern before proceeding with example) you'll 
understand that `SingletonContainer` will create your component only once, and give that component
each time it is asked to do this. Now we know what to do. We should build another container
that will give new Tire each time it we ask to! And here jumps in PrototypeContainer
which will give you a new instance of a component each time you ask it (see Prototype pattern).
Let's try to create a prototype container, and put in our tire:
----------------
    PrototypeContainer prototype = new PrototypeContainer;
    container.registerInto!Tire("prototype") // Registering Tire into "prototype" container used by aggregate container
        .set!"size"(17)
        .set!"pressure"(3.0)
        .set!"vendor"("divine tire");
----------------

Now, let's boot prototype container, and to be sure that container will give
us new tire each time is asked, let's assert this:
----------------
    prototype.isntantiate();
    assert(
        prototype.locate!Tire !is
        prototype.locate!Tire
    );
----------------

Cool new we can create new Tire each time we ask it for our car's construction!
Though other problem arises: How can we tell our car configuration that resides 
in singleton container, to use our tire that resides in a prototype container?
The answer, is that up to this point we can't tell car's configuration to look up
tires in prototype container. Instead will do something else. We'll join our singleton
and prototype container into one! Just like here:
----------------
    AggregateLocatorImpl!() container = new AggregateLocatorImpl!(); // An aggregate container that will fetch components from it's containers.
    SingletonContainer singleton = new SingletonContainer; 
    PrototypeContainer prototype = new PrototypeContainer;
    
    container.set(singleton, "singleton"); // Let's add singleton container as a source for aggregate container
    container.set(prototype, "prototype"); // Let's add prototype container as a source for aggregate container
----------------

Here we can see that we have an aggregate container, that uses singleton 
and prototype containers to construct/wire our compontents. Now we should proceed to component
registration and configuration. Yet, we'd ask ourselves another question: since our container
is a composite one, how we can register into singleton or into prototype container?
The answer is simple. Register method, in case for composite containers, accepts
additional parameter, which is a string that identifies our container, in composite
one. So in order to register our car into singleton, or register our tires
into prototype container, we'd pass name of sub-container into register method.
Let's do this:
----------------
    container.registerInto!Tire("prototype") // Registering Tire into "prototype" container used by aggregate container
        .set!"size"(17)
        .set!"pressure"(3.0)
        .set!"vendor"("divine tire");
        
    container.registerInto!Car
        .autowire
        .autowire!"color"
        .set!"frontLeft"(lref!Tire)
        .set!"frontRight"(lref!Tire)
        .set!"backLeft"(lref!Tire)
        .set!"backRight"(lref!Tire);
----------------

Cool, we have registered our Tire in prototype container, yet you'd see that
for Car configuration we didn't pass identity of singleton container. That is
because Aedi will default to a contaiener named "singleton" when no  
identity is passed with register method, and use it to register our component. 
Another thing, you might've noticed, is that we use registerInto instead of register.
That's because, if we'd only use register method there would be ambiguity in register
overload set present in library between overloads with component name, 
and with container name as arguments. Just think like that: If I want to register a component 
by name into a container or by interface use register, and when you'd like to register by
type into a container use registerInto.

Note : the current situation is scheduled for a resolution in future versions of library.

Enough talk! Let's boot both of containers (for now each container should be booted
separately), and see the specs of our cars:
-----------------
    prototype.instantiate(); // Boot container (or prepare managed code/data).
    singleton.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car.drive("Electric car");
----------------- 

We'd see following output:
-----------------
Uuh, what a nice car, Electric car with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 0)
Engine:	app.ElectricEngine
Tire front left:	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C31180
Tire front right:	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C311C0
Tire back left: 	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C31200
Tire back right:	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C31240
-----------------

Notice that each tire is a different object, hence everything is working as we
expected!

Try this example, modify it, play with it to understand how compositing can 
help in designing your application.

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
    }
}

/**
A concrete implementation of Engine that uses gasoline for propelling.
**/
class GasolineEngine : Engine {
    
    public {
        
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
    
    public {
        
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
A concrete implementation of Engine that uses electricity for propelling.
**/
class ElectricEngine : Engine {
    public {
        
        void turnOn() {
            writeln("pzt");
            
        }
        
        void run() {
            writeln("vvvvvvvvv");
        }
        
        void turnOff() {
            writeln("tzp");
        }
    }
}

/**
Tire, what it can represent else?
**/
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

/**
A class representing a car.
**/
class Car {
    
    private {
        Color color_; // Car color
        Size size_; // Car size
        Engine engine_; // Car engine
        
        Tire frontLeft_;
        Tire frontRight_;
        Tire backLeft_;
        Tire backRight_;
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
            
            Car frontLeft(Tire frontLeft) @safe nothrow {
            	this.frontLeft_ = frontLeft;
            
            	return this;
            }
            
            Tire frontLeft() @safe nothrow {
            	return this.frontLeft_;
            }
            
            Car frontRight(Tire frontRight) @safe nothrow {
            	this.frontRight_ = frontRight;
            
            	return this;
            }
            
            Tire frontRight() @safe nothrow {
            	return this.frontRight_;
            }
            
            Car backLeft(Tire backLeft) @safe nothrow {
            	this.backLeft_ = backLeft;
            
            	return this;
            }
            
            Tire backLeft() @safe nothrow {
            	return this.backLeft_;
            }
            
            Car backRight(Tire backRight) @safe nothrow {
            	this.backRight_ = backRight;
            
            	return this;
            }
            
            Tire backRight() @safe nothrow {
            	return this.backRight_;
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

/**
A manufacturer of cars.
**/
class CarManufacturer {
    
    public {
        Car manufacture(Size size) { 
            return new Car(size, new DieselEngine()); // Manufacture a car.
        }
    }
}

void drive(Car car, string name) {
    writeln("Uuh, what a nice car, ", name," with following specs:");
    writeln("Size:\t", car.size());
    writeln("Color:\t", car.color());
    writeln("Engine:\t", car.engine());
    writeln("Tire front left:\t", car.frontLeft(), "\t located at memory ", cast(void*) car.frontLeft());
    writeln("Tire front right:\t", car.frontRight(), "\t located at memory ", cast(void*) car.frontRight());
    writeln("Tire back left: \t", car.backLeft(), "\t located at memory ", cast(void*) car.backLeft());
    writeln("Tire back right:\t", car.backRight(), "\t located at memory ", cast(void*) car.backRight());
}

void main() {
    AggregateLocatorImpl!() container = new AggregateLocatorImpl!(); // An aggregate container that will fetch components from it's containers.
    SingletonContainer singleton = new SingletonContainer; 
    PrototypeContainer prototype = new PrototypeContainer;
    
    container.set(singleton, "singleton"); // Let's add singleton container as a source for aggregate container
    container.set(prototype, "prototype"); // Let's add prototype container as a source for aggregate container
    
    container.registerInto!Color; // Let's register a default implementation of Color
    
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.registerInto!Size // Let's register default implementation of a Size
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(300UL);
    
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
        
    container.register!(Engine, ElectricEngine);
    
    container.registerInto!Tire("prototype") // Registering Tire into "prototype" container used by aggregate container
        .set!"size"(17)
        .set!"pressure"(3.0)
        .set!"vendor"("divine tire");
        
    container.registerInto!Car
        .autowire
        .autowire!"color"
        .set!"frontLeft"(lref!Tire)
        .set!"frontRight"(lref!Tire)
        .set!"backLeft"(lref!Tire)
        .set!"backRight"(lref!Tire);
    
    prototype.instantiate(); // Boot container (or prepare managed code/data).
    singleton.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car.drive("Electric car");
}