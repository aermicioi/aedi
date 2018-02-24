/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Aedi does provide basic containers singleton and prototype, which can be combined into some-
thing more complex. Though, on top of their behavior additional one can be built, such as a container
that can be enabled/disabled, or a container that adds observer pattern. Out of the box framework does provide
following decorating containers:

$(UL
    $(LI aliasing - provides aliasing functions)
    $(LI gc rigistered - registers instantiated components with gc, when other that gc allocator are used)
    $(LI subscribable - provides observable pattern on container events)
    $(LI typed - serves components based on their implemented interfaces)
    $(LI proxy - serves component proxies instead of original ones)
    $(LI deffered - provides deffered construction of components)
)

Each decorating container listed below will be explained in detail, followed by a short explanation of what current example does.

Aliasing:

The aliasing container decorator adds ability to add aliases to existing components in container. Therefore
a "foo" component can have multiple aliases "moo", "boo" etc. Each alias will resolve to same component in container.
Such feature is useful when an existing component in container for compatibility reasons should have another identity as
well. To use aliasing container simply wrap any container in $(D_INLINECODE aliasing) method which will decorate existing one.
UFCS syntax is desired for fluent like style.

-----------------
auto cont = aggregate(
    singleton, "singleton",
    prototype, "prototype",
    values, "parameters",
    gasoline, "gasoline",
    electric, "electric",
    diesel, "diesel"
).aliasing;
-----------------

GcRegistered:

GC registered decorating container registers any created component with global gc available in D. Since any component can have customized
memory allocation strategy through std.experimental.allocator, were one of strategy is to use garbage collector, and each component
can have dependencies to other components, in some cases, gc on collection cycle could deallocate a component (which technically isn't
referenced by anyone) even if it is still referenced by other component of which gc is not aware of. GC registered container aims to register
all public components provided by underlying container into GC in order to avoid the case from above. To use it, just suffix any container with $(D_INLINECODE gcRegistered).

-----------------
auto cont = aggregate(
    singleton, "singleton",
    prototype, "prototype",
    values, "parameters",
    gasoline, "gasoline",
    electric, "electric",
    diesel, "diesel"
).aliasing.gcRegistered;
-----------------

Subscribable:

Subscribable container offers a list of events to which a listener can subscribe and perform operations on. Currently only two events are provided:
$(OL
    $(LI instantiation pre event - fired before instantiation of container)
    $(LI instantiation post event - fired after instantiation of container)
)
An example of such listeners can be like in listing below, which will enable a container before instantiation based on profile argument
-----------------
cont.subscribable.subscribe(
    ContainerInstantiationEventType.pre,
    {
        if (cont.has(cont.locate!string("profile"))) {
            cont.locate!Switchable(cont.locate!string("profile")).enabled = true;
            return;
        }

        throw new Exception("No engine profile selected. Specify it with -p");
    }
);
-----------------

Typed:

Typed container decorates underlying container with ability to provide a component based on interface it implements.
Code using typed container attempts to get a component by an interface such as $(D_INLINECODE Engine) in this example,
typed container will check if underlying container has a component identified by provided interface. If yes it will give
the component from decorated container. If not, it will search for all registered components that implement the required interface
and use first found component to serve it. Notice that in this example, no $(D_INLINECODE Engine) was registered in container by
$(D_INLINECODE Engine) interface. Each instance $(D_INLINECODE GasolineEngine), $(D_INLINECODE ElectricEngine), and $(D_INLINECODE DieselEngine)
are registered by their type only. No attempt to alias one of them to $(D_INLINECODE Engine) is done, yet when Car is instantiated, a component
implementing $(D_INLINECODE Engine) interface is supplied. This magic is done by typed container, which supplied first available component implementing
$(D_INLINECODE Engine) interface.

Proxy:

A proxy container proxies all components supplied by decorated container. It will supply proxy objects instead of real components, which in turn
will on each public call of a proxy will redirect it to component in redirected container, and return a value from it. The proxy container
alone is not much useful. It is intended to be used along with containers that are dependendet on some global state to provide components.
An example of such containers could be containers that provide different instances of same component per thread or fiber, or in case of
web application, a container that gives new instances of same component for each new available request web application receives.

Deffered:

Deffered container, executes delayed components construction and configuration. Construction and configuration of a component can occur in cases
when there is a circular dependency between a set of components. In such case to resolve it, injection of one dependency can be delayed.
Delaying of construction or configuration is left to component factory, while execution of delayed action is enforced upon Deffered container.
To enable circular dependency resolution, decorate container with $(D_INLINECODE deffered) decorator, and register components using $(D_INLINECODE withConfigurationDefferring)
configuration context (simply append it after $(D_INLINECODE container.configure) method). This exampe shows a typical example of circular
dependency. A car has a dependency on four tires, while each tire has a dependency on a car instance, resulting in a circular dependency.
Removing $(D_INLINECODE deffered) or $(D_INLINECODE withConfigurationDefferring) will result in circular dependency exception thrown by container.

Example:
Such behavior can be useful, like in car company example, that at certian point of time decided that their application should provide
upon start cars with different engines, electric/diesel/gasoline.

The workflow needed to implement in application in order to allow 3 different configurations is
shown below and consists of following steps:
$(OL
    $(LI read profile argument from command line or environment )
    $(LI switch on it, and register diesel/gasoline/electric engine by Engine interface depending on selected profile )
)

Following snippet of code shows all decorating containers in use except of proxy one.

------------------
auto decorated() {
    auto gasoline = singleton.typed.switchable.enabled(false);
    auto electric = singleton.typed.switchable.enabled(false);
    auto diesel = singleton.typed.switchable.enabled(false);

    auto cont = aggregate(
        singleton, "singleton",
        prototype, "prototype",
        values, "parameters",
        gasoline, "gasoline",
        electric, "electric",
        diesel, "diesel"
    ).aliasing.gcRegistered.deffered;

    return cont.subscribable.subscribe(
        ContainerInstantiationEventType.pre,
        {
            if (cont.has(cont.locate!string("profile"))) {
                cont.locate!Switchable(cont.locate!string("profile")).enabled = true;
                return;
            }

            throw new Exception("No engine profile selected. Specify it with -p");
        }
    );
}
------------------

The profile based container is assembled from 3 typed and switchable containers, and a subscribable
composite container with gc component registration and construction of deffered components.
When the application is booted up, the code from $(D_INLINECODE main(string[] args)) loads into container
"profile" argument. Afterwards components are registered into container, and for each profile,
the right engine is registered in respective gasoline, electric, diesel containers. Once this
is finished, the container is instantiated using $(D_INLINECODE intantiate) method. During instantiation phase,
subscribable composite container fires an pre-instantiation event on which, a delegate is attached, that
checks for "profile" argument, and enables the container identified by value in profile container.
Afterwards construction of components proceeds. When car is constructed typed container jumps in and
provides an implenentation of $(D_INLINECODE Engine) for car depending on enabled container. When
construction arrives at a Tire, a circular dependency is detected, and construction of a component is
deffered at later stage in order to break dependency chain. Once component is constructed, it is registered
with global gc instance in order to avoid destruction of gc managed components while they are still referenced
by non-managed components. Once instantiation is finished, car is fetched from container and displayed in console.

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
import std.experimental.allocator.mallocator;
import std.experimental.allocator;

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
        Car car_;
    }

    public @property {
        @autowired
        Tire car(Car car) {
            this.car_ = car;
            return this;
        }

        Car car() {
            return this.car_;
        }

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
    writeln("Uuh, what a nice ", name," car, with following specs:");
    writeln("Size:\t", car.size);
    writeln("Color:\t", car.color);
    writeln("Engine:\t", car.engine);
    writeln("Tire front left:\t", car.frontLeft, "\t located at memory ", cast(void*) car.frontLeft());
    writeln("Tire front right:\t", car.frontRight, "\t located at memory ", cast(void*) car.frontRight());
    writeln("Tire back left: \t", car.backLeft, "\t located at memory ", cast(void*) car.backLeft());
    writeln("Tire back right:\t", car.backRight, "\t located at memory ", cast(void*) car.backRight());
}

auto decorated() {
    auto gasoline = singleton.typed.switchable.enabled(false);
    auto electric = singleton.typed.switchable.enabled(false);
    auto diesel = singleton.typed.switchable.enabled(false);

    auto cont = aggregate(
        singleton, "singleton",
        prototype, "prototype",
        values, "parameters",
        gasoline, "gasoline",
        electric, "electric",
        diesel, "diesel"
    ).aliasing.gcRegistered.deffered;

    return cont.subscribable.subscribe(
        ContainerInstantiationEventType.pre,
        {
            if (cont.has(cont.locate!string("profile"))) {
                cont.locate!Switchable(cont.locate!string("profile")).enabled = true;
                return;
            }

            throw new Exception("No engine profile selected. Specify it with -p");
        }
    );
}

void main(string[] args) {

    auto cont = decorated();
    scope(exit) container.terminate();

    import std.getopt;
    string profile;

    auto help = getopt(args,
        "p|profile", &profile
    );

    with (cont.locate!ValueContainer("parameters").configure) {

        register(profile, "profile");
    }

    with (cont.configure("singleton", Mallocator.instance.allocatorObject)) {
        register!Color;

        register!Size
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

    with (cont.configure("prototype").withConfigurationDefferring) {
        register!Tire
            .autowire!"car"
            .set!"size"(17)
            .set!"pressure"(3.0)
            .set!"vendor"("divine tire");
    }

    cont.configure("diesel").register!DieselEngine;
    cont.configure("gasoline").register!GasolineEngine;
    cont.configure("electric").register!ElectricEngine;

    cont.link("electric", "ecological");

    cont.instantiate();

    cont.locate!Car.drive(profile);
}