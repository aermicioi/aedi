/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Code api, offers a rich set of functionality, and flexibility. Though alternatives to
configuring a container with components should be provided along with their strengths
and disadvantages. For this purpose as an alternative to code api, the framework implements
annotation based configuration of components.

The main idea of annotation based configuration of components is that,
information about component's dependencies and configuration properties are
stored in form of annotations right in it. The framework does provide
annotation based counterparts of almost all configuration primitives available
in code api. Example below shows a component configured using annotation based information:

--------------------
@component // Mark component to be registered in container
@qualifier("custom.identity") // Specify custom identity for component in container instead of it's type as identity
class Car {

    // ...

    public {

        @constructor(lref!Size, lref!Engine) // Construct this component using arguments passed to constructor annotation
        this(Size size, Engine engine) {
            this.size_ = size;
            this.engine = engine;
        }

        @property {

            @setter("color.green".lref) // Set the property to arguments passed in setter
            Car color(Color color) @safe nothrow {
            	this.color_ = color;

            	return this;
            }

            // ...

            @setter(lref!Engine) // Set the property to arguments passed in setter
            Car engine(Engine engine) @safe nothrow {
            	this.engine_ = engine;

            	return this;
            }

            // ...

            @autowired // Automatically wire property using components from container identified by their types
            Car frontLeft(Tire frontLeft) @safe nothrow {
            	this.frontLeft_ = frontLeft;

            	return this;
            }

            // ...

            @callback(
                function (Locator!() locator, ref Car configured) {
                    configured.frontRight = locator.locate!Tire;
                }
            ) // Use a callback to configure the property, or entire object. Can be attached anywhere on component
            Car frontRight(Tire frontRight) @safe nothrow {
            	this.frontRight_ = frontRight;

            	return this;
            }

            // ...

            @autowired // Automatically wire property using components from container identified by their types
            Car backLeft(Tire backLeft) @safe nothrow {
            	this.backLeft_ = backLeft;

            	return this;
            }

            // ...

            @autowired // Automatically wire property using components from container identified by their types
            Car backRight(Tire backRight) @safe nothrow {
            	this.backRight_ = backRight;

            	return this;
            }

            // ...

        }

        // ...
    }
}
--------------------

As seen above describing a component using annotation consists of
annotating it with $(D_INLINECODE @component), optionally specyfing
an identity using $(D_INLINECODE @qualifier), and annotating it
with construction and configuration annotations such as:
$(UL
    $(LI $(D_INLINECODE @constructor ) (only on constructors) - annotates component with it's construction dependencies )
    $(LI $(D_INLINECODE @setter ) (only on setters) - annotates component with it's setter based dependencies )
    $(LI $(D_INLINECODE @autowired ) (not on constructors) - annotates component with it's setter based dependencies automatically )
    $(LI $(D_INLINECODE @autowired ) (on constructors) - annotates component with it's construction dependencies automatically )
    $(LI $(D_INLINECODE @callback ) (not on constructors) - annotates component with a custom function used to configure component )
    $(LI $(D_INLINECODE @callback ) (on constructors) - annotates component with a custom function used to create component )
    $(LI $(D_INLINECODE @factoryMethod) (anywhere) - annotates component with information about factory used to construct it )
    $(LI $(D_INLINECODE @contained) (on component) - annotates component with information about container that manages it in a composite/joint container)
 )

Though annotations provide information about a component for framework, it does not
automatically register them into container. To add annotated components to a container
use $(D_INLINECODE componentScan ) family of functions. Example below shows how it is
possible to register an entire module using just one line of code:

-------------------
container.componentScan!(app); // load all annotated components from module "app"
-------------------

Other forms of componentScan exists. Check api documentation to see alternatives of module
based component registration if needed.

The result of running example, will yield into following output:
-------------------
Uuh, what a nice car, Electric car with following specs:
Size:   Size(200, 150, 500)
Color:  Color(0, 255, 0)
Engine: app.ElectricEngine
Tire front left:        Tire(17 inch, 3 atm, divine tire)        located at memory 7FCC35376100
Tire front right:       Tire(17 inch, 3 atm, divine tire)        located at memory 7FCC35376140
Tire back left:         Tire(17 inch, 3 atm, divine tire)        located at memory 7FCC35376180
Tire back right:        Tire(17 inch, 3 atm, divine tire)        located at memory 7FCC353761C0
-------------------

Check example below. Modify it, run it to understand annotation based configuration.

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
@component // Mark component to be registered in container
struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
}

/**
Size of a car.
**/
@component // Mark component to be registered in container
struct Size {

    @setter(200UL) // Set the property to arguments passed in setter
    ulong width;

    @setter(150UL) // Set the property to arguments passed in setter
    ulong height;

    @setter(500UL) // Set the property to arguments passed in setter
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
@component // Mark component to be registered in container
@qualifier("gasoline")
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
@component // Mark component to be registered in container
@qualifier("diesel")
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
@component // Mark component to be registered in container
@qualifier!Engine()
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
@component // Mark component to be registered in container
@contained("prototype")
class Tire {
    private {
        int size_;
        float pressure_;
        string vendor_;
    }

    public @property {
        @setter(17) // Set the property to arguments passed in setter
        Tire size(int size) @safe nothrow {
        	this.size_ = size;

        	return this;
        }

        int size() @safe nothrow {
        	return this.size_;
        }

        @setter(3.0) // Set the property to arguments passed in setter
        Tire pressure(float pressure) @safe nothrow {
        	this.pressure_ = pressure;

        	return this;
        }

        float pressure() @safe nothrow {
        	return this.pressure_;
        }

        @setter("tire.vendor".lref) // Set the property to arguments passed in setter
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
@component // Mark component to be registered in container
@qualifier("custom.identity")
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
        @constructor(lref!Size, lref!Engine) // Construct this component using arguments passed to constructor annotation
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
            @setter("color.green".lref) // Set the property to arguments passed in setter
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
            @setter(lref!Engine) // Set the property to arguments passed in setter
            Car engine(Engine engine) @safe nothrow {
            	this.engine_ = engine;

            	return this;
            }

            Engine engine() @safe nothrow {
            	return this.engine_;
            }

            @autowired // Automatically wire property using components from container identified by their types
            Car frontLeft(Tire frontLeft) @safe nothrow {
            	this.frontLeft_ = frontLeft;

            	return this;
            }

            Tire frontLeft() @safe nothrow {
            	return this.frontLeft_;
            }

            @callback(
                function (Locator!() locator, ref Car configured) {
                    configured.frontRight = locator.locate!Tire;
                }
            ) // Use a callback to configure the property, or entire object. Can be attached anywhere on component
            Car frontRight(Tire frontRight) @safe nothrow {
            	this.frontRight_ = frontRight;

            	return this;
            }

            Tire frontRight() @safe nothrow {
            	return this.frontRight_;
            }

            @autowired // Automatically wire property using components from container identified by their types
            Car backLeft(Tire backLeft) @safe nothrow {
            	this.backLeft_ = backLeft;

            	return this;
            }

            Tire backLeft() @safe nothrow {
            	return this.backLeft_;
            }

            @autowired // Automatically wire property using components from container identified by their types
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
    auto container = aggregate( // Create a joint container hosting other two containers
        singleton(), "singleton", // Create singleton container, and store it in joint container by "singleton" identity
        prototype(), "prototype", // Create prototype container, and store it in joint container by "prototype" identity
        values(), "parameters"  // Create value container, and store it in joint container by "prototype" identity
    );
    scope(exit) container.terminate();

    container.componentScan!(app); // load all annotated components from module "app"

    with (container.configure("singleton")) {

        register(Color(0, 255, 0), "color.green");
        register("divine tire", "tire.vendor");
    }

    with (container.locate!ValueContainer("parameters").configure) {

        values.register(Size(200, 150, 300), "size.smarty");
    }

    container.instantiate(); // Boot container (or prepare managed code/data).

    container.locate!Car("custom.identity").drive("Electric car");
}