/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

This tutorial will show how it is possible to implement profiled containers
which are enabled based on some condition (ex: command line argument).
It will introduce decorating containers available in Aedi.

Aedi does provide basic containers singleton and prototype, which can be
combined into something more complex. Yet, in some cases the features they
provide is not enough. An example of such feature is containers that are
enabled only when a specific profile is present. For example, car simulator
(tutorial's example) should have 3 profiles:
$(OL
    $(LI electric )
    $(LI gasoline ) 
    $(LI diesel )
)

The simplest and easiest way to enable application to serve 3 different profiles
is to:
$(OL
    $(LI read profile argument from command line or environment )
    $(LI switch on it, and register diesel/gasoline/electric engine by Engine interface depending on argument value )
)
Just like in this snippet:
------------------
//    ..............car example code..............

    import std.getopt;
    string profile;
    
    auto help = getopt(args,
        "p|profile", &profile
    );
    
    switch (profiles) {
        case "diesel": {
            container.register!(Engine, DieselEngine);
            break;
        }
        
        case "electric": {
            container.register!(Engine, ElectricEngine);
            break;
        }
        
        case "gasoline": {
            container.register!(Engine, GasolineEngine);
            break;
        }
        
        default: {
            assert(0, "No profile selected");
        }
    }
    
//    ..............car example code..............    
------------------

Easy, simple, no problems. Yet as, car example grows, the each profile can include
additional components that are specific to it. With more components, switch used
in example will become quite big, and hard to maintain, and will become quite problematic
to hot plug for example additional containers with their components.

Another solution using Aedi library, is to create a container for each profile, configure
it, and enable it when certain profile is passed as argument:
------------------
auto containerWithProfiles() {
    auto container = new ApplicationContainer; // A composite container with singleton, prototype built in.
    
    auto electricProfileContainer = (new SwitchableContainer!SingletonContainer).decorated(new SingletonContainer);
    auto gasolineProfileContainer = (new SwitchableContainer!SingletonContainer).decorated(new SingletonContainer);
    auto dieselProfileContainer = (new SwitchableContainer!SingletonContainer).decorated(new SingletonContainer);
    auto subscribableContainer = (new SubscribableContainer!ApplicationContainer).decorated(container);
    
    container.set(electricProfileContainer, "electricProfile"); // Added container for green technology
    container.set(gasolineProfileContainer, "gasolineProfile"); // Added container for pollution technology
    container.set(dieselProfileContainer, "dieselProfile"); // Added container for pollution technology
    
    subscribableContainer.subscribe(
        ContainerInstantiationEventType.pre,
        {
            foreach (element; container.locate!(string[])("profile")) {
                if (container.has(element)) {
                    try {
                        
                        container.locate!Switchable(element).enabled = true;
                    } catch (InvalidCastException e) {
                        
                    }
                }
            }
        }
    );
    
    return subscribableContainer;
}

void main(string[] args) {
    auto container = containerWithProfiles();
    
    import std.getopt;
    string[] profiles;
    
    auto help = getopt(args,
        "p|profile", &profiles
    );
    container.register(profiles, "profile");
//    ..............car example code..............

    container.register!(Engine, ElectricEngine)("electricProfile");
    container.register!(Engine, GasolineEngine)("gasolineProfile");
    container.register!(Engine, DieselEngine)("dieselProfile");
    
//    ..............car example code..............
}
------------------

Now, the configuration for each profile can be separated in it's own config file.
No worries should occurr with components identity collisions, etc. since all
components particular to a profile are contained in one container.

"Profiled containers" in code snippet above, are implemented using 2 decorating containers:
$(OL
    $(LI SwitchableContainer - Adds switching capability. This container will boot, and serve objects only
        if it has been enabled. Note, storing and removing components from it is possible even when it is
        disabled. )
    $(LI SubscribableContainer - Adds subscribing capability to container. This container will fire two events:
        $(OL
            $(LI ContainerInstantiationEventType.pre - runs all subscribers prior to container boot ) 
            $(LI ContainerInstantiationEventType.post - runs all subscribers after container booted )
        )
    )
)

With help of them it is possible to customize behavior of container (and not only). It is possible
for example to scan all components in a container, select some of them, and them to other component,
and so on.

Try running this example. Experiment with it, to understand decorating containers.

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
import std.algorithm;

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

auto containerWithProfiles() {
    auto container = new ApplicationContainer; // A composite container with singleton, prototype built in.
    
    auto electricProfileContainer = (new SwitchableContainer!SingletonContainer).decorated(new SingletonContainer);
    auto gasolineProfileContainer = (new SwitchableContainer!SingletonContainer).decorated(new SingletonContainer);
    auto dieselProfileContainer = (new SwitchableContainer!SingletonContainer).decorated(new SingletonContainer);
    auto subscribableContainer = (new SubscribableContainer!ApplicationContainer).decorated(container);
    
    container.set(electricProfileContainer, "electric");
    container.set(gasolineProfileContainer, "gasoline");
    container.set(dieselProfileContainer, "diesel");
    
    subscribableContainer.subscribe(
        ContainerInstantiationEventType.pre,
        {
            foreach (element; container.locate!(string[])("profile")) {
                if (container.has(element)) {
                    try {
                        
                        container.locate!Switchable(element).enabled = true;
                    } catch (InvalidCastException e) {
                        
                    }
                }
            }
        }
    );
    
    return subscribableContainer;
}

void main(string[] args) {
    
    auto container = containerWithProfiles();
    
    import std.getopt;
    string[] profiles;
    
    auto help = getopt(args,
        "p|profile", &profiles
    );
    container.register(profiles, "profile");
    
    container.register!(Engine, ElectricEngine)("electric");
    container.register!(Engine, GasolineEngine)("gasoline");
    container.register!(Engine, DieselEngine)("diesel");
    
    container.registerInto!Color; // Let's register a default implementation of Color
    
    container.registerInto!Size // Let's register default implementation of a Size
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(300UL);
    
    container.registerInto!Tire("prototype")
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
    
    container.instantiate();
    
    container.locate!Car.drive("");
}