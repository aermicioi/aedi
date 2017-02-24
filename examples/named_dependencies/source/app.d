/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

$(BIG $(B Aim ))

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

$(BIG $(B Usage ))

Sometimes except of basic component, we'd want to have same component but
with other configuration of dependencies. Let's say that we'd like to have multiple
configurations of a car. Not just one like in previous example were we learned how to 
configure container to construct our components. We'd like to have a car
of sedan sizes of color green and blue, and a car of smart car sizes with blue
color. Taking a small peek into previous chapter, we'd see that it's possible to
register only one Car, since it's implicitly identified by it's type. Trying
to register another in it, will simply replace it with newly registered one.
Let's try this. Take previous example and right after we register first Car
register another one:
-----------------
    container.register!Car
        .construct(lref!Size)
        .set!"color"(Color(0, 0, 0));
-----------------

Let's run modified example. Well see the following output:
-----------------
You bought a new car with following specs:
Size:	Size(200, 150, 500)
Color:	Color(0, 0, 0)
-----------------

We can conclude that we can identify only one car in container by it's type.
In case, when another configuration of Car is needed, we will have to name that
configuration. Same problem with only one Color and Size possible to store by
type is resolved by naming custom variants. Let's take it sequentially, first
let's register two colors into container:
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

As in example we can see that it's quite simple to name a component in container.
Just pass name as a string as first argument to register method, and it will be
saved as "color.green" or any other name/identity. Same process is done 
when defining two types of sizes (smart, and sedan):
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

Cool, now having needed types of sizes, and colors we can define our configurations of cars:
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

Now we have three new and shining cars!
Though, you'll ask yourself: In previous example we used `lref!<Type>` notation to
reference Car's size and color in container, won't we reference same Color and Size
if we use that notation, for our all three cars? Yes, it's true, when we reference a component by `lref!<Type>`
it's basically like saying that "Hey in order to construct our new and shining car, we
need a color or size identified by it's type!". So in order to reference a color or size
component by name rather than it's type, we'd use following notation `"my_super_duper_car_color_name".lref`.
Actually little thing at the end of string ".lref" says that the string passed to configuration
is actually the name of a component present in container, rather than a simple string.

Let's print the specifications of our newly built cars:
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