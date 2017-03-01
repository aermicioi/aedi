/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

This tutorial will show how to register a component with custom identity in container, and
how to reference components with custom identities. The tutorial is based on car 
simulation presented in previous example, and will continue to improve it.

Sometimes except of a single implementation of a component, some variations of it
are desired. In context of car simulation example, imagine that besides
a car with default parameters, several other are desired with different colors
or sizes. For example two cars of sedan size with green/blue color, and one car of smart
sizes of green color. Previous example, explained how to register components
in container by their type, yet it didn't show how to add multiple instances of same
component with various dependencies (or how to register a component by custom identity). 
Trying to register a variation of component by it's type will just overwrite previous one,
just like in example below: 

-----------------
    container.register!Car
        .construct(lref!Size)
        .set!"color"(lref!Color);
        
    container.register!Car
        .construct(lref!Size)
        .set!"color"(Color(0, 0, 0));
-----------------

Trying to run previous example with another car added, will print only the last one:
-----------------
You bought a new car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 0, 0)
-----------------

Components registered in containers of are identified by a string 
identifier, which is implicitly assigned to the fully qualified name of a component,
when no explicit identity is provided. To register a component by custom identity,
pass the identity as an argument to .register method. Check example 
below to see how to register a component with custom identity:

-----------------
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.register!Color("color.blue") // Register "blue" color into container.
        .set!"r"(cast(ubyte) 0)
        .set!"g"(cast(ubyte) 0)
        .set!"b"(cast(ubyte) 255);
-----------------

As with green and blue color, same procedure is done with size component:
-----------------
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
        
    container.register!Size("size.smart_car") // Register a size of a generic smart car into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(300UL);
-----------------

Once components used by cars are present in container, it is time to register car's variations
in container:
-----------------
    container.register!Car("sedan.green") // Register a car with sedan sizes and of green color.
        .construct("size.sedan".lref)
        .set!"color"("color.green".lref);
    
    container.register!Car("smarty.blue") // Register a car with smart car sizes and of a blue color.
        .construct("size.smart_car".lref) 
        .set!"color"("color.blue".lref);
    
    container.register!Car("sedan.blue") // Register a car with sedan car sizes and of a blue color.
        .construct("size.sedan".lref) 
        .set!"color"("color.blue".lref);
-----------------

Take a look at the configuration of those three cars. In previous example to reference
a dependcy present in container `lref!(Type)` was used to do it. `lref!(Type)`
denotes a reference to a component present in container which is identified by fully qualified name (FQN)
of Type. To reference a component which has other identity from type's FQN, 
use `lref("<identity>")` or `"<identity>".lref` which is in UFCS (unified function call syntax) notation. 
Container during build will understand that it is a reference, and pass referenced component instead 
of actual reference to constructor or method.

To get a component that has custom identity, pass the identity as an argument to locate method:

-----------------
container.locate!Car("sedan.green").print("sedan green");
-----------------

To be sure that all modifications done in this tutorial are working, run the application to see
following output:
-----------------
You bough a new car sedan green with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 255, 0)
You bough a new car sedan blue with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 0, 255)
You bough a new car smarty blue with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 255)
-----------------

Check example below. Play with it, to get the gist of named components.

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

void print(Car car, string name) {
    writeln("You bought a new car ", name," with following specs:");
    writeln("Size:\t", car.size());
    writeln("Color:\t", car.color()); 
}

void main() {
    SingletonContainer container = new SingletonContainer; // Creating container that will manage a color
    
    container.register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    container.register!Color("color.blue") // Register "blue" color into container.
        .set!"r"(cast(ubyte) 0)
        .set!"g"(cast(ubyte) 0)
        .set!"b"(cast(ubyte) 255);
        
    container.register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
        
    container.register!Size("size.smart_car") // Register a size of a generic smart car into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(300UL);
    
    container.register!Car("sedan.green") // Register a car with sedan sizes and of green color.
        .construct("size.sedan".lref)
        .set!"color"("color.green".lref);
    
    container.register!Car("smarty.blue") // Register a car with smart car sizes and of a blue color.
        .construct("size.smart_car".lref) 
        .set!"color"("color.blue".lref);
    
    container.register!Car("sedan.blue") // Register a car with sedan car sizes and of a blue color.
        .construct("size.sedan".lref) 
        .set!"color"("color.blue".lref);
    
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car("sedan.green").print("sedan green");
    container.locate!Car("sedan.blue").print("sedan blue");
    container.locate!Car("smarty.blue").print("smarty blue");
}