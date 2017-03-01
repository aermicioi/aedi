/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

In this tutorial, we will talk about design loosely coupled components and
how Aedi can help in doing this. This tutorial will teach how to register
components by their interface.

Taking previous example, where we learned how to
name components in container, you probably asked yourself: How, can a car be without
an engine? No it can't, a car must have an engine. So let's improve previous example
by adding a gasoline engine to it:
------------------
class GasolineEngine {
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

class Car {
    private {
        Color color_; // Car color
        Size size_; // Car size
        GasolineEngine engine_; // Car engine
    }
    public {
        this(Size size, GasolineEngine engine) {
            this.size_ = size;
            this.engine = engine;
        }
        @property {
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
            Car engine(GasolineEngine engine) @safe nothrow {
            	this.engine_ = engine;
            	return this;
            }
            GasolineEngine engine() @safe nothrow {
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
------------------

Now, car can use an engine to propel itself.

Yet, at some point in time, it is decided to put in a diesel engine
instead of a gasoline one, since it's performance is higher, and
it's usually more powerful. Since till now we were using a gasoline
engine, to allow a diesel one, we could subclass gasoline engine
and implement a diesel engine:
------------------
class DieselEngine : GasolineEngine {
    public {
        override void turnOn() {
            writeln("pururukVruumVrrr");
        }
        override void run() {
            writeln("vruum");
        }
        override void turnOff() {
            writeln("vrrrPft");
        }
    }
}
------------------

Now a diesel engine can be installed into car instead of gasoline one.
It's a workable solution to do such subclassing in order to implement another behavior,
yet it's not desired to do in such a way, since we subclass a concrete implementation
that itself can change over time. For example, we could add option to fuel it with 
a certain amount of gasoline:
------------------
    public void fuel(Gasoline gasoline) {...}
------------------

The desing used previously can only lead to solutions that use workarounds, to allow
both gasoline and diesel engine work. It is like treating the symptom instead
of the cause, which in our case is that car can accept only gasoline engine.

A better solution, would be to redesing car to accept engines that are implementing
some interface, through which it can interact with engines: 

------------------
interface Engine {
    public {
        void turnOn();
        void run();
        void turnOff();
    }
}

class Car {
    private {
        Color color_; // Car color
        Size size_; // Car size
        Engine engine_; // Car engine
    }
    
    public {
        
        this(Size size, Engine engine) {
            this.size_ = size;
            this.engine = engine;
        }
        
        @property {
            
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
------------------

Once car accepts Engine implementations, both gasoline and diesel engine should
implement the interface:
------------------
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
------------------

The current solution won't suffer from consequences presented before, since
diesel implementation and gasoline one are not dependent between each other.

The purpose of the tutorial up to this point is to show basic principle on
how to design loosely coupled components, which is to model components
to interact with rest of them by their interfaces instead of direct interaction.
The DI pattern itself it's a particular implementation of inversion of control principle,
where a client instead of managing it's dependencies itself, delegates this 
responsibility to a third party (the injector, or container in our case). By doing
so, client code won't need to hassle with construction of it's dependencies, or
what dependency it should use for a particular case, and so on. It has to know
only how it can interface with it's dependency just like we did with Engine interface
in last example, and that's all. Therefore, such design encourages highly decoupled components,
allows us to follow single responsibility principle quite easily.

Yet, up to this point, we didn't talk anything about Aedi library, and how it can help us
in such case. First of all, with help of it, we can define a default implementation of an interface
that can be used by dependent components. We can register a concrete implementation
by it's interface like so:
------------------
    container.register!(Engine, GasolineEngine);
------------------

Next let's define our car that uses this engine:
------------------
    container.register!Car("sedan.engine.default") // Register a car with a default engine
        .construct("size.sedan".lref, lref!Engine)
        .set!"color"("color.green".lref);
------------------

Take a look, here we pass to constructor of a car, a reference to an implementation of 
Engine interface present in container. Once container will try to construct car, it will
see use implementation of Engine that was registered by Engine interface.

Sometimes though, we'd like to have cars that are not with default implementation of interface
but with some other concrete implementation. Let's define two concrete implementations of Engine:
------------------
    container.register!GasolineEngine; // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
    container.register!DieselEngine; 
------------------

We can now define two cars, one with gasoline, and other with diesel engine:
------------------
    container.register!Car("sedan.engine.gasoline") // Register a car with gasoline engine
        .construct("size.sedan".lref, lref!GasolineEngine)
        .set!"color"("color.green".lref);
    
    container.register!Car("sedan.engine.diesel") // Register a car with diesel engine
        .construct("size.sedan".lref, lref!DieselEngine)
        .set!"color"("color.green".lref);
------------------

The remaining parts of our tutorial is to boot container and drive created cars:
------------------
    container.instantiate();
    
    container.locate!Car("sedan.engine.default").drive("Default car");
    container.locate!Car("sedan.engine.gasoline").drive("Gasoline car");
    container.locate!Car("sedan.engine.diesel").drive("Diesel car");
------------------

Upon driving, we'd see the following output:
------------------
Uuh, what a nice car, Default car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 255, 0)
Let's turn it on
pururukVrooomVrrr
What a nice sound! We should make a test drive!
vrooom
Umm the test drive was awesome, let's get home and turn it off.
vrooom
vrrrPrrft

Uuh, what a nice car, Gasoline car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 255, 0)
Let's turn it on
pururukVrooomVrrr
What a nice sound! We should make a test drive!
vrooom
Umm the test drive was awesome, let's get home and turn it off.
vrooom
vrrrPrrft

Uuh, what a nice car, Diesel car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 255, 0)
Let's turn it on
pururukVruumVrrr
What a nice sound! We should make a test drive!
vruum
Umm the test drive was awesome, let's get home and turn it off.
vruum
vrrrPft
------------------

Try example below. Modify it, play with to get the gist of DI pattern.

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
    writeln("Size:\t", car.size());
    writeln("Color:\t", car.color());
    
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
    
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
    
    container.register!(Engine, GasolineEngine); // Register a gasoline engine as default implementation of an engine
    container.register!GasolineEngine; // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
    container.register!DieselEngine; // Register a diesel engine
    
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