/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

$(BIG $(B Aim ))

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

$(BIG $(B Usage ))

Examples, like examples, but if take the previous one, where we learned how to
name components in container, you'd ask yourself: How, how can a car be without
an engine? No it can't, a car must have an engine. Se let's improve previous example
by adding an engine to it. So let's add a gasoline engine to it:
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


Ok, now we can drive our car! It has an engine and therefore it
can burn gasoline to propel the car.

Yet, at some point in time, you'd like to put in a diesel engine
instead of a gasoline one, since it's performance is higher, and
it's usually more powerful. But what a bummer, we have designed
our car only with a gasoline engine. We cannot put other type
of engine, only gasoline one. But since we're in OOP world
a bright idea have appeared to us! Let's subclass our gasoline
engine, and make diesel engine from it. Let's add another class
that subclasses gasoline engine, and defines it's own way of running:
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

Nice, we can now put a diesel engine into our car instead of gasoline one.
It's a workable solution to do such subclassing in order to implement another behavior,
yet it's not desired to do in such a way, since a gasoline engine, can change.
For example, we could add option to fuel it with a certain amount of gasoline:
------------------
    public void fuel(Gasoline gasoline) {...}
------------------

And in this case, we have to think: "ok, a gasoline engine can accept gasoline fuel
but what about diesel engine that we have subclassed from gasoline one?" It can't
work on gasoline, it should work on diesel instead. It's a problem, that can occur
quite often with such designs like above. Anyway we have tried to solve a symptom
and not the cause of symptom. 

So which is the cause of symptom? Clearly its the fact that car accepts only 
gasoline engine. If we think in depth, wy does a car need to know what kind
of engine it has installed into? Gasoline or Diesel one? A car should only
know that an engine can be started, it can run, and it can be stopped. Other
stuff is implementation details of an engine. Therefore instead of defining our
car to accept a gasoline engine only, we'd design an interface for engine, through
which a car can interact with different types of engines. Let's implement the interface:
------------------
interface Engine {
    public {
        void turnOn();
        void run();
        void turnOff();
    }
}
------------------

Now, having an interface for engines, instead of specifing a gasoline engine in
car, wed put there an interface to engine:
------------------
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

Now let's redesing our gasoline and diesel engines. They should implement now
Engine interface:
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

We can now easily substitue diesel engine with gasoline engine, and vice versa.

Actually entire example presented up to this point talks about the principles
of dependency injection, and how it should be used, to gain full power from it.
The di pattern itself it's a particular implementation of inversion of control principle,
where a client instead of managing it's dependencies itself, delegates this 
responsibility to a third party (the injector, or container in our case). By doing
so, client code won't need to hassle with construction of it's dependencies, or
what dependency it should use for a particular case, and so on. It has to know
only how it can interface with it's dependency just like we did with Engine interface
in last example, and that's all. Therefore, such design encourages highly decoupled components,
allows us to follow single responsibility principle quite easily.
During design phase of our applications's components, we design them not to use
concrete implementations of dependent components, but design them to use interfaces
implemented by those components.

Yet, up to this point, we didn't talk anything about Aedi library, and how it can help us
in such case. So let's talk how can Aedi help us to implement seamlessly our example.
First of all, with help of it, we can define a default implementation of an interface
that can be used by dependent components. We can register a concrete implementation
by it's interface like so:
------------------
    container.register!(Engine, GasolineEngine);
------------------

Here we state that, a GasolineEngine implementation of Engine interface should be
registered by it's Engine interface, and used everywhere were a component requires
an Engine implementation. Next let's define our car that uses this engine:
------------------
    container.register!Car("sedan.engine.default") // Register a car with a default engine
        .construct("size.sedan".lref, lref!Engine)
        .set!"color"("color.green".lref);
------------------

Take a look, here we pass to constructor of a car, a reference to an implementation of 
Engine interface present in container. Once container will instantiate a Car, it will
see that an implementation of Engine is required, and therefore will pass it to constructor
of Car.

Sometimes though, we'd like to have cars that are not with default implementation of interface
but with some other concrete implementation. Let's define two concrete implementations of Engine:
------------------
    container.register!GasolineEngine; // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
    container.register!DieselEngine; 
------------------

Now, let's define two cars, one with gasoline, and other with diesel engine:
------------------
    container.register!Car("sedan.engine.gasoline") // Register a car with gasoline engine
        .construct("size.sedan".lref, lref!GasolineEngine)
        .set!"color"("color.green".lref);
    
    container.register!Car("sedan.engine.diesel") // Register a car with diesel engine
        .construct("size.sedan".lref, lref!DieselEngine)
        .set!"color"("color.green".lref);
------------------

See? We've just referenced concrete implementations instead of Engine's default implementation.
That's all. Now we can boot our container:
------------------
container.instantiate();
------------------

Now let's try to drive those three cars:
------------------
    container.locate!Car("sedan.engine.default").drive("Default car");
    container.locate!Car("sedan.engine.gasoline").drive("Gasoline car");
    container.locate!Car("sedan.engine.diesel").drive("Diesel car");
------------------

We'd see the following output:
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