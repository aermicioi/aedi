/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Besides $(D_INLINECODE set) , $(D_INLINECODE construct) , methods used in all above examples, framework offers several
other configuration methods, that allow greater manipulation, or less verbosity. Additional configu-
ration primitives are listed below:

$(OL
    $(LI $(D_INLINECODE autowire) )
    $(LI $(D_INLINECODE factoryMethod) )
    $(LI $(D_INLINECODE callback) )
    $(LI $(D_INLINECODE value))
    $(LI $(D_INLINECODE destructor))
)

Lets start with first one from list, which is $(D_INLINECODE autowire) method.
From it's name we can deduce that it automates wiring of components somehow.
But how does it do this? Let's register a car using old $(D_INLINECODE set) and $(D_INLINECODE construct) methods:
----------------
    register!Car("sedan.engine.default")
        .construct(lref!Size, lref!Engine)
        .set!"color"(lref!Color);
----------------

Autowire:

Even with more structured instantiation code present using framework, sometimes, even this
code is too verbose. Some components for example have a set of dependencies defined by some
interface, and having for each dependency to reference it using $(D_INLINECODE lref!Type) is quite cumbersome,
and painfull.

And here comes into play $(D_INLINECODE autowire) configuration method, which handles referencing of
component by type on behalf of developer that creates the configuration, like in example below:

-----------------
register!Car("sedan.engine.default") // Register a car with a default engine.
    .autowire() // Construct Car using default implementation of a size, and engine.
    .autowire!"color"(); // Inject default implementation of a Color.
-----------------

In current implementation of autowired due to limitations of current compiler’s compile time
introspection, $(D_INLINECODE autowire) cannot work well with overloaded methods or constructors. In such cases,
$(D_INLINECODE autowire) cannot know which version of method/constructor to overload, and will default to the
first one from the list of overloads.

FactoryMethod:

Frequently in applications that use third party code, components from that third party code,
are instantiated using factories or other entities from that third party code, and the client code of
those libraries simply are not allowed to manually create those types. To aleviate this problem, when
such a component is registered in a container, framework allows such components to be instantiated
by using third party code responsible for this task.

Supposedly, the car simulation application introduced previously, is upgraded with a car man-
ufacturing simulation, and new cars that are needed to be registered as components into container
are required to be instantiated using car manufacturing component. $(D_INLINECODE factoryMethod) method
instructs framework to use a third party component to instantiate registered component, using static
method of a factory, or by using an instance of a factory. In example usage of $(D_INLINECODE factoryMethod)
is shown:

-----------------
register!Car("car_manufacturer.product.sedan") // Register a car with gasoline engine
    .factoryMethod!(CarManufacturer, "manufacture")(lref!CarManufacturer, "size.sedan".lref);
-----------------

Callback:
While just by configuring a component with simple values or references, in some cases during
construction of a component some custom logic must be run, that is or not related to instantiation
process. $(D_INLINECODE callback) configuration method can be used to pass a function or a delegate that
constructs or configures the component, according to some custom logic, not expressable by already
available configuration primitives. Example below shows how a callback can be used as a constructor or
as a configuration primitive.

------------------
    register!Car("sedan.engine.electric") // Register a car with electric engine
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
custom configuration primitives just by using under the hood the $(D_INLINECODE callback) primitive.

Value:
The value primitive instructs container to use as basis an already constructed component. The component itself
can be further configured using primitives specified above. The only specific case that should be taken into accout
is the fact that using same value that is a reference type (a pointer, or class) in multiple components, will result into
having same component with multiple identities in container. The container itself won't be aware of the relationship, as in case
with aliasing. It is recommended that $(D_INLINECODE value) to be used only once per reference value.

-------------------
register!GasolineEngine
    .value(new GasolineEngine(15)); // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
-------------------

Destructor:
When container is shut down, the default behavior is to destroy all constructed components. The default destruction logic is to run destructor and
deallocate the component. Sometimes, the default behavior is not desired, or additional logic should be run. In such cases $(D_INLINECODE destructor)
primitive can be used to either pass a delegate, or factory method to be used to destroy the component.

-------------------
register!Car("car_manufacturer.product.sedan") // Register a car with gasoline engine
    .factoryMethod!(CarManufacturer, "manufacture")(lref!CarManufacturer, "size.sedan".lref)
    .destructor((RCIAllocator alloc, ref Car car) {
        write("Crushing the car. ");
        alloc.dispose(car);
        writeln("Done");
    });
-------------------

Those additional primitives are quite handy to use, with libraries that are usign factories,
dependencies by interface, or when some custom behavior has to be run during construction of a
component. Output below is the result of using those primitives, to run.

-------------------
Uuh, what a nice car, Gasoline car with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 0)
Engine:	app.GasolineEngine
Let`s turn it on
pururukVrooomVrrr
What a nice sound! We should make a test drive!
vrooom
Umm the test drive was awesome, let`s get home and turn it off.
vrooom
vrrrPrrft

Uuh, what a nice car, Manufactured car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 0, 0)
Engine:	app.DieselEngine
Let`s turn it on
pururukVruumVrrr
What a nice sound! We should make a test drive!
vruum
Umm the test drive was awesome, let`s get home and turn it off.
vruum
vrrrPft

Uuh, what a nice car, Electric car with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 0)
Engine:	app.ElectricEngine
Let`s turn it on
pzt
What a nice sound! We should make a test drive!
vvvvvvvvv
Umm the test drive was awesome, let`s get home and turn it off.
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

module configuration_primitives;

import aermicioi.aedi;
import std.experimental.allocator;
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

    private double consume;
    public {
        this(double consume) {
            this.consume = consume;
        }

        void turnOn() {
            writeln("pururukVrooomVrrr");

        }

        void run() {
            writeln("munch ", consume, " of litres vroom");
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
    SingletonContainer container = singleton(); // Creating container that will manage a color
    scope(exit) container.terminate();

    with (container.configure) {
        register!Color; // Let's register a default implementation of Color

        register!Color("color.green") // Register "green" color into container.
            .set!"r"(cast(ubyte) 0)
            .set!"g"(cast(ubyte) 255)
            .set!"b"(cast(ubyte) 0);

        register!Size // Let's register default implementation of a Size
            .set!"width"(200UL)
            .set!"height"(150UL)
            .set!"length"(300UL);

        register!Size("size.sedan") // Register a size of a generic "sedan" into container
            .set!"width"(200UL)
            .set!"height"(150UL)
            .set!"length"(500UL);

        register!(Engine, GasolineEngine)
            .construct(10.0); // Register a gasoline engine as default implementation of an engine
        register!GasolineEngine
            .value(new GasolineEngine(15)); // Register a gasoline engine. Note: this engine is not the same gasoline engine from default implementation.
        register!DieselEngine; // Register a diesel engine

        register!CarManufacturer; // Let's register a car manufacturer in our container.

        register!Car("sedan.engine.default") // Register a car with a default engine.
            .autowire() // Construct Car using default implementation of a size, and engine.
            .autowire!"color"(); // Inject default implementation of a Color.

        register!Car("car_manufacturer.product.sedan") // Register a car with gasoline engine
            .factoryMethod!(CarManufacturer, "manufacture")(lref!CarManufacturer, "size.sedan".lref)
            .destructor((RCIAllocator alloc, ref Car car) {
                write("Crushing the car with ", typeid(car.engine), " engine: ");
                alloc.dispose(car);
                writeln("Done");
            });

        register!Car("sedan.engine.electric") // Register a car with electric engine
            .callback(
                delegate (RCIAllocator allocator, Locator!() loc) { // Let's construct our car using some custom logic that isn't possible to express with a simple construct method call.
                    Car car = allocator.make!Car(loc.locate!Size, new ElectricEngine());

                    return car;
                }
            ).callback( // Let's configure newly built car with a custom color.
                delegate (Locator!() loc, Car car) {
                    car.color = loc.locate!Color;
                }
            );
    }

    container.instantiate(); // Boot container (or prepare managed code/data).

    container.locate!Car("sedan.engine.default").drive("Gasoline car");
    container.locate!Car("car_manufacturer.product.sedan").drive("Manufactured car");
    container.locate!Car("sedan.engine.electric").drive("Electric car");
}