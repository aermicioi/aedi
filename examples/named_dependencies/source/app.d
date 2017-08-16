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

Except of a single implementation of a component, in some occurrences of an application,
multiple instances of same type of component, but with varying dependencies, are required. In case
of car simulation application, the simulator should not be limited to only a single car, it should be
able to have multiple cars with varying parameters, like cars of sedan or smart sizes with blue and
green colors.

Previous section showed how to register only one version for each component including the car
itself. Attempting to add another car to container like in example below, will fail due to simple problem:
Both cars are identified in container by their type.

-----------------
    register!Car
        .construct(lref!Size)
        .set!"color"(lref!Color);
        
    register!Car
        .construct(lref!Size)
        .set!"color"(Color(0, 0, 0));
-----------------

Running in modified container configuration in context of previous tutorial's example will end
in output from below, were last registered instance of Car component overrides the previously
defined.

-----------------
You bought a new car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 0, 0)
-----------------

Each registered component in a container is associated with an identity in it. In case with
car for previous examples, the Car component is associated with identity representing it’s Type. To
avoid associating a component by it’s type during registration, pass it’s identity as an argument to
$(D_INLINECODE register) method, like in example below. A component can also be associated with an interface it
implements by inserting desired interface before the type of registered component.

-----------------
with (container.configure) {
    register!Color("color.green") // Register "green" color into container.
        .set!"r"(cast(ubyte) 0) 
        .set!"g"(cast(ubyte) 255)
        .set!"b"(cast(ubyte) 0);
    
    register!Color("color.blue") // Register "blue" color into container.
        .set!"r"(cast(ubyte) 0)
        .set!"g"(cast(ubyte) 0)
        .set!"b"(cast(ubyte) 255);
        
    register!Size("size.sedan") // Register a size of a generic "sedan" into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(500UL);
        
    register!Size("size.smart_car") // Register a size of a generic smart car into container
        .set!"width"(200UL) 
        .set!"height"(150UL)
        .set!"length"(300UL);
    
    register!Car("sedan.green") // Register a car with sedan sizes and of green color.
        .construct("size.sedan".lref)
        .set!"color"("color.green".lref);
    
    register!Car("smarty.blue") // Register a car with smart car sizes and of a blue color.
        .construct("size.smart_car".lref) 
        .set!"color"("color.blue".lref);
    
    register!Car("sedan.blue") // Register a car with sedan car sizes and of a blue color.
        .construct("size.sedan".lref) 
        .set!"color"("color.blue".lref);
}
-----------------

To reference a component that has custom identity, in a configuration or reliant component,
use $(D_INLINECODE lref("custom-associated-identity")) notation. Seeing this type of reference, framework
will attempt to search component by this identity, and serve it to component that is in con-
struction. Thanks to unified function call syntax (UFCS) available in D programming language,
lref("custom-associated-identity") can be rewritten into a more pleasant view $(D_INLINECODE "custom-associated-identity".lref).
To extract manually a component with custom identity pass the identity to $(D_INLINECODE locate)
method as first argument, along with type of component.

Running fixed version of configuration, will yield in printing all three cars from code above into
stdout in output below. To be sure that all modifications done in this tutorial are working, run the
application to see following output:

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
    SingletonContainer container = singleton(); // Creating container that will manage a color
    
    with (container.configure) {
        register!Color("color.green") // Register "green" color into container.
            .set!"r"(cast(ubyte) 0) 
            .set!"g"(cast(ubyte) 255)
            .set!"b"(cast(ubyte) 0);
        
        register!Color("color.blue") // Register "blue" color into container.
            .set!"r"(cast(ubyte) 0)
            .set!"g"(cast(ubyte) 0)
            .set!"b"(cast(ubyte) 255);
            
        register!Size("size.sedan") // Register a size of a generic "sedan" into container
            .set!"width"(200UL) 
            .set!"height"(150UL)
            .set!"length"(500UL);
            
        register!Size("size.smart_car") // Register a size of a generic smart car into container
            .set!"width"(200UL) 
            .set!"height"(150UL)
            .set!"length"(300UL);
        
        register!Car("sedan.green") // Register a car with sedan sizes and of green color.
            .construct("size.sedan".lref)
            .set!"color"("color.green".lref);
        
        register!Car("smarty.blue") // Register a car with smart car sizes and of a blue color.
            .construct("size.smart_car".lref) 
            .set!"color"("color.blue".lref);
        
        register!Car("sedan.blue") // Register a car with sedan car sizes and of a blue color.
            .construct("size.sedan".lref) 
            .set!"color"("color.blue".lref);
    }
    
    
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Car("sedan.green").print("sedan green");
    container.locate!Car("sedan.blue").print("sedan blue");
    container.locate!Car("smarty.blue").print("smarty blue");
}