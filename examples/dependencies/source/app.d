/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

$(BIG $(B Aim ))

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

$(BIG $(B Usage ))

Minimal example, showed us the simplest case of usage. A Color struct that is
registered in container and printed afterwards. Clearly the example didn't show
true purpose of a dependency injection pattern, which is to wire your application's
components between themselves. In this example we will show how we can do it using
Aedi library.

Suppose we have a car, and we want to construct it. Suppose it has three sizes, and
a color. The most dumbest way to construct such a car is to instantiate it's
sizes and color right in car's constructor, just like in following example:
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

Though such solution is working, we will encounter a big problem, when say we will
want a car that is not of color that we defined in constructor, but say green color.
The solution to the problem is to allow color and size to be passed from outside
into car through constructor or setters.
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

New version is nicer, we can now configure our car to our needs, yet we'd have tons of such
code when, our application will grow, and at some point it will become clunky and hard
to maintain construction and configuration of our components. A DI library will eliminate such
problems, since it will do construction and configuration of components instead of us.
Let's see how with help of Aedi we can construct a Car. First of all, we have to create our container:
------------------
SingletonContainer container = new SingletonContainer;
------------------

Next, we will register Color and Size into container:
------------------
    container.register!Color
        .set!"r"(cast(ubyte) 0)
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
        
    container.register!Size
        .set!"width"(200UL)
        .set!"height"(150UL)
        .set!"length"(500UL);
------------------

So currently we have all needed components for Car construction. Next we should define how Car can be
constructed.
------------------
    container.register!Car
        .construct(lref!Size)
        .set!"color"(lref!Color);
------------------

Nice, we've defined how a car can be constructed.
$(UL
    $(LI Note first line in example, tells container to register a car into it. )
    $(LI On second line we tell it, that car should be constructed using Size struct 
        present in same container. Note that a special notation `lref!(Type)` is 
        used to denote that argument should be searched in container, 
        and passed afterwards as argument to constructor, or a method. ) 
     $(LI On third line just like on second one, we tell container that 
        color should be assigned to Color struct present in container. )

Ok, now we have defined blueprints for Color, Size, and Car. Now we need
to boot up the container.
------------------
    container.instantiate();
------------------

Good, seems we have encountered no problems. We can now get newly car from
container, and print it's specs:
------------------
container.locate!Car.print;
------------------

At end we should see our newly greeny car:
------------------
You bought a new car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 255, 0)
------------------

Try example in this module. Modify it, play with it to understand the dependency configuration.

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
    SingletonContainer container = new SingletonContainer; // Creating container that will manage a color
    
    container.register!Color // Register color into container.
        .set!"r"(cast(ubyte) 0) // Set red color to 0
        .set!"g"(cast(ubyte) 255) // Set green color to 255
        .set!"b"(cast(ubyte) 0); // Set blue color to 0
        
    container.register!Size // Register a size into container
        .set!"width"(200UL) // As for color set width to 150.
        .set!"height"(150UL)
        .set!"length"(500UL);
        
    container.register!Car // Register a car in container
        .construct(lref!Size) // Construct car using size present in container
        .set!"color"(lref!Color); // Set car color to color present in container.
        
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car.print; // Get color from container and print it.
}