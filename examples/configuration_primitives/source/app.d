/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

Examples up to this point used only `.constructor` and `.set` methods to configure
a component from container. Beside those two methods Aedi does provide other ways
to configure your component. Those are present in following list:

$(OL
    $(LI .autowire )
    $(LI .factoryMethod )
    $(LI .callback )
    )
    
Lets start with first one from list, which is `.autowire` method.
From it's name we can deduce that it automates wiring of components somehow.
But how does it do this? Let's register a car using old .set and .construct methods:
----------------
    container.register!Car("sedan.engine.default")
        .construct(lref!Size, lref!Engine)
        .set!"color"(lref!Color);
----------------

In this example, we construct car using references to default implementations in 
container. Having to write such configurations can become quite tedious, so why 
not automate it, since the information about accepted types in constructors and 
methods is already present there? That's what .autowire does. It takes type 
information from constructor's arguments, or from method's arguments, and searches 
default implementations based on them. Just like in this example:
-----------------
    container.register!Car("sedan.engine.default") // Register a car with a default engine.
        .autowire() // Construct Car using default implementation of a size, and engine.
        .autowire!"color"(); // Inject default implementation of a Color.
-----------------

Just be warned, autowire is not working quite good with overloaded constructors
or methods. When autowire will be applied on such overloaded constructor or method, 
it will just select first constructor/method from overload set and use it to 
construct/configure component.

Next configuration primitive is factoryMethod. This primitive implements factory 
method pattern. In other words it tells container to use a method from some third 
party component to construct our component, instead of using component's constructor 
for example. Usage of it is quite simple:
------------------
    container.register!Car("car_manufacturer.product.sedan") // Register a car with gasoline engine
        .factoryMethod!(CarManufacturer, "manufacture")(lref!CarManufacturer, "size.sedan".lref);
------------------

Take a look at factoryMethod call. We pass the type of third party component, and method
that is used to construct our component. Though you'll ask yourself: Then why we pass a reference
to CarManufacturer, if we already identified it in template arguments? Taking a peek in
CarManufacturer implementation, we'd see that `manufacture` method is not static
therefore we should run this method on some instance of CarManufacturer. That's why
we pass as first argument a reference in container to CarManufacturer. The CarManufacturer referenced
in first argument will be used to construct our new car. It is possible as well to pass
an implementation directly. For static methods that are used to construct our component
no instance of third party component is required.

The last configuration primitive is `.callback` primitive. It uses a callback for
construction of component or for it's configuration. Let's look at following example:
------------------
    container.register!Car("sedan.engine.electric") // Register a car with electric engine
        .callback(
            delegate (Locator!() loc) { // Let's construct our car using some custom logic that isn't possible to express with a simple construct method call.
                Car car = new Car(loc.locate!Size, new ElectricEngine());
                
                return car; 
            }
        ).callback( // Let's configure newly built car with a custom color.
            delegate (Locator!() loc, Car car) {
                car.color = loc.locate!Color;
            }
        );
-------------------
Though it's quite a simple primitive, it is as well powerful one. It is possible to define your own
custom configuration primitives just by using under the hood the .callback primitive.

Putting all primitives in one example, booting the container, we will see following output:
-------------------
Uuh, what a nice car, Gasoline car with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 0)
Engine:	app.GasolineEngine
Let's turn it on
pururukVrooomVrrr
What a nice sound! We should make a test drive!
vrooom
Umm the test drive was awesome, let's get home and turn it off.
vrooom
vrrrPrrft

Uuh, what a nice car, Manufactured car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 0, 0)
Engine:	app.DieselEngine
Let's turn it on
pururukVruumVrrr
What a nice sound! We should make a test drive!
vruum
Umm the test drive was awesome, let's get home and turn it off.
vruum
vrrrPft

Uuh, what a nice car, Electric car with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 0)
Engine:	app.ElectricEngine
Let's turn it on
pzt
What a nice sound! We should make a test drive!
vvvvvvvvv
Umm the test drive was awesome, let's get home and turn it off.
vvvvvvvvv
tzp
-------------------

If you are puzzled from where is this output, take a look at the source code of
this example. Modify it, play with it to understand these configuration primitives.

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
    
    writeln("Let's turn it on");
    car.start();
    
    writeln("What a nice sound! We should make a test drive!");
    car.run();
    
    writeln("Umm the test drive was awesome, let's get home and turn it off.");
    car.run();
    car.stop();
}

void main() {
    SingletonContainer container = new SingletonContainer; // Creating container that will manage a color
    
    container.register!Color; // Let's register a default implementation of Color
    
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.register!Size // Let's register default implementation of a Size
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(300UL);
    
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
    
    container.register!(Engine, GasolineEngine); // Register a gasoline engine as default implementation of an engine
    container.register!GasolineEngine; // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
    container.register!DieselEngine; // Register a diesel engine
    
    container.register!CarManufacturer; // Let's register a car manufacturer in our container.
    
    container.register!Car("sedan.engine.default") // Register a car with a default engine.
        .autowire() // Construct Car using default implementation of a size, and engine.
        .autowire!"color"(); // Inject default implementation of a Color.
        
    container.register!Car("car_manufacturer.product.sedan") // Register a car with gasoline engine
        .factoryMethod!(CarManufacturer, "manufacture")(lref!CarManufacturer, "size.sedan".lref);
    
    container.register!Car("sedan.engine.electric") // Register a car with electric engine
        .callback(
            delegate (Locator!() loc) { // Let's construct our car using some custom logic that isn't possible to express with a simple construct method call.
                Car car = new Car(loc.locate!Size, new ElectricEngine());
                
                return car; 
            }
        ).callback( // Let's configure newly built car with a custom color.
            delegate (Locator!() loc, Car car) {
                car.color = loc.locate!Color;
            }
        );
    
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car("sedan.engine.default").drive("Gasoline car");
    container.locate!Car("car_manufacturer.product.sedan").drive("Manufactured car");
    container.locate!Car("sedan.engine.electric").drive("Electric car");
}