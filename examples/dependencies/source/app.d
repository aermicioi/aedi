/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:
The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

This tutorial will show how to register several components, and reference them
as dependencies.

Just registering a component with predefined data, is not enough even in smallest applications,
since an application is an amalgamation of interconnected components. Therefore the framework does
allow client code to register components that have dependencies, and reference them in configuration
of those components.

For example, in application that simulates cars, a car clearly is not a single god object. It is a
set of interconnected components, represented by objects in application. Though as seen in listing,
the car has it’s color and size hard-coded to specific values, and modifications to them aren’t
possible to do. Having a car simulator such code is not desired, since a simulator should be able
to simulate multiple types of cars with different sizes and colors.

------------------
class Car {
    private Color color_;
    private Size size;

    public this() {
        color_ = Color(255, 255, 100);
        sizes = Size(200, 150, 500);
    }
}
------------------

In improvement to the defined car in application (above), could be done by exposing color and size of
car to configuration from exterior environment

------------------
class Car {
    private Color color_;
    private Size size;

    public this(Size size) {
        this.size = size;
    }

    public @property void color(Color color) {
        this.color_ = color;
    }
}

void main() {
    Car myCar = new Car(Size(200, 150, 500));
    myCar.color = Color(0, 255, 0);
}
------------------

Having the ability to change color and size of a car it is possible to have now multiple instances
of a car, with different sizes and colors, though with increase of different types cars, the amount
of code required to instantiate and configure them with right sizes increases tremendously, and in
the end can become complex, and cumbersome to understand. Not to mention, the importance of
micromanaging the order of how cars component instantiate. A car cannot be instantiated before, her
components. Clearly the solution is more flexible, yet at a cost of increased amount of code.

A DI framework aims to lessen the burden of writing wiring code, and will eliminate the need
of micromanaging the order component creation. It will do instead of developers, just like in following
example

------------------
SingletonContainer container = singleton(); // Creating container that will manage a color

with (container.configure) {

    register!Color // Register color into container.
        .set!"r"(cast(ubyte) 0) // Set red color to 0
        .set!"g"(cast(ubyte) 255) // Set green color to 255
        .set!"b"(cast(ubyte) 0); // Set blue color to 0

    register!Size // Register a size into container
        .set!"width"(200UL) // As for color set width to 150.
        .set!"height"(150UL)
        .set!"length"(500UL);

    register!Car // Register a car in container
        .construct(lref!Size) // Construct car using size present in container
        .set!"color"(lref!Color); // Set car color to color present in container.
}

container.instantiate(); // Boot container (or prepare managed code/data).

container.locate!Car.print;
------------------

Referencing a dependency in a Car can be done using $(D_INLINECODE lref!Type) notation, that allows
framework to detect that a dependency is actually required to pass, and not a simple value. Therefore
the framework will search for a value of a type $(D_INLINECODE Type) and pass it as a dependency to Car.
The result of a container can be seen by fetching a car from container and printing it to the
stdout

At end we should see the car:
------------------
You bought a new car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 255, 0)
------------------

Try example in this module. Modify it, play with it to understand how to configure dependencies
between components.

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
A class representing a car.
**/
class Car {

    private {
        Color color_; // Car color
        Size size_; // Car size
    }

    public {

        /**
        Constructor of car.

        Constructs a car with a set of sizes. A car cannot of course have
        undefined sizes, so we should provide it during construction.

        Params:
            size = size of a car.
        **/
        this(Size size) {
            this.size_ = size;
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
        }
    }
}

void print(Car car) {
    "You bought a new car with following specs:".writeln;
    writeln("Size:\t", car.size());
    writeln("Color:\t", car.color());
}

void main() {
    SingletonContainer container = singleton(); // Creating container that will manage a color
    scope(exit) container.terminate();

    with (container.configure) {

        register!Color // Register color into container.
            .set!"r"(cast(ubyte) 0) // Set red color to 0
            .set!"g"(cast(ubyte) 255) // Set green color to 255
            .set!"b"(cast(ubyte) 0); // Set blue color to 0

        register!Size // Register a size into container
            .set!"width"(200UL) // As for color set width to 150.
            .set!"height"(150UL)
            .set!"length"(500UL);

        register!Car // Register a car in container
            .construct(lref!Size) // Construct car using size present in container
            .set!"color"(lref!Color); // Set car color to color present in container.
    }

    container.instantiate(); // Boot container (or prepare managed code/data).

    container.locate!Car.print; // Get color from container and print it.
}