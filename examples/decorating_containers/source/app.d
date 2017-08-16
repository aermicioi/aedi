/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Aedi does provide basic containers singleton and prototype, which can be combined into some-
thing more complex. Yet, in some cases the features they provide is not enough. An example of
such feature is containers that are enabled only when a specific profile is present. For example, car
simulation app at start should allow user to select from 3 different cars to simulate. Each of those
cars have a specific engine:

$(OL
    $(LI electric )
    $(LI gasoline ) 
    $(LI diesel )
)

The workflow needed to implement in application in order to allow 3 different configurations is
shown below and consists of following steps:
$(OL
    $(LI read profile argument from command line or environment )
    $(LI switch on it, and register diesel/gasoline/electric engine by Engine interface depending on selected profile )
)

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

Quite straitforward implementation is shown here. The application takes argument from command line,
switches on it, and registers different set of components for car, based on argument of
command line. Though for simplistic usage, the approach is quite useful, yet in cases when the
control over container instantiation is not handled by the client code, but by a third party container,
such a straightforward approach becomes quite complicated. For such cases the framework does pro-
vide a solution by the ability of decorating existing containers, and third party ones with additional
logic. In case of car simulation app, with 3 different car profiles for startup, the framework provides
two types of containers, through which profiling feature is implemented. Example below shows the
powerfullness of framework in adding additional behavior to existing container, thereby extending it.
------------------
auto containerWithProfiles() {
    auto container = new ApplicationContainer; // A composite container with singleton, prototype built in.
    
    auto electricProfileContainer = singleton.switchable(); // creating a singleton, and decorating it with switchable container
    auto gasolineProfileContainer = singleton.switchable(); // creating a singleton, and decorating it with switchable container
    auto dieselProfileContainer = singleton.switchable(); // creating a singleton, and decorating it with switchable container
    auto subscribableContainer = container.subscribable(); // decorating joint container with subscribable container
    
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
------------------

The profile based container is assembled from 3 switchable containers, and a subscribable
composite container. When the application is booted up, the code from $(D_INLINECODE main(string[] args)) loads into container
"profile" argument. Afterwards components are registered into container, and for each profile,
the profiled components are registered in respective gasoline, electric, diesel containers. Once this
is finished, the container is instantiated using $(D_INLINECODE intantiate) method. During instantiation phase,
subscribable composite container fires an pre-instantiation event on which, a delegate is attached, that
checks for "profile" argument, and enables the container identified by value in profile container.
In such a way most of conditional chains such as switch or if are avoided, furthermore the approach
could be scaled indefinitely without hindering the expressibility of implementation.

Both subscribable and switchable containers, are decorators over more basic ones, and can be
used with all containers present from framework. They can be nested in any order desired, by the
implementor.

Try running this example, pass as argument $(D_INLINECODE --profile) with value of 
$(D_INLINECODE gasoline), $(D_INLINECODE electric), $(D_INLINECODE diesel).
Experiment with it, to understand decorating containers.

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
    
    auto electricProfileContainer = singleton.switchable(); // creating a singleton, and decorating it with switchable container
    auto gasolineProfileContainer = singleton.switchable(); // creating a singleton, and decorating it with switchable container
    auto dieselProfileContainer = singleton.switchable(); // creating a singleton, and decorating it with switchable container
    auto subscribableContainer = container.subscribable(); // decorating joint container with subscribable container
    
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

    with (container.locate!ValueContainer("parameters").configure()) {

        register(profiles, "profile");
    }

    with (container.configure("singleton")) {
        register!Color; // Let's register a default implementation of Color
        
        register!Size // Let's register default implementation of a Size
            .set!"width"(200UL) 
            .set!"height"(150UL)
            .set!"length"(300UL);
        
        
            
        register!Car
            .autowire
            .autowire!"color"
            .set!"frontLeft"(lref!Tire)
            .set!"frontRight"(lref!Tire)
            .set!"backLeft"(lref!Tire)
            .set!"backRight"(lref!Tire);
    }

    with (container.configure("prototype")) {
        register!Tire
            .set!"size"(17)
            .set!"pressure"(3.0)
            .set!"vendor"("divine tire");
    }

    with (container.configure("diesel")) {
        register!(Engine, DieselEngine);
    }

    with (container.configure("gasoline")) {
        register!(Engine, GasolineEngine);
    }

    with (container.configure("electric")) {
        register!(Engine, ElectricEngine);
    }
    
    container.instantiate();
    
    container.locate!Car.drive("");
}