/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

$(BIG $(B Aim ))

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

$(BIG $(B Usage ))

As previously stated, Aedi implements dependency injection pattern, and is used to
construct your application's components and wire between them.

The process of configuring your components using Aedi consists of following steps:

$(UL
    $(LI Create a container )
    $(LI Register an application component. By components, we define any objects, structs, etc. )
    $(LI Write a wiring configuration )
    $(LI Repeat process for other components. )
    $(LI Boot container )
)

First of all we should create a container:
---------------
    SingletonContainer container = new SingletonContainer;
---------------

Container is responsible for storing, and managing our application's components.

Next we register a component into container:
---------------
    container.register!Color
---------------

We register a component by calling .register method on container with type of component.
Note, that in example we do not end the statement. That's because we have to configure it next:
---------------
        .set!"r"(cast(ubyte) 250)
        .set!"g"(cast(ubyte) 210)
        .set!"b"(cast(ubyte) 255);
---------------

As we, see here we configured rgb colors to specific values. Take a look at end of example.
We see that it ends in `;` hence it states that it's end of statement and Color registration.
Once we have registered and configured our components, we need to boot our container:
---------------
    container.instantiate();
---------------

Container during boot operation, will do various stuff, including creation and wiring of your components
between them. It's important to call `container.instantiate()` after all of your application's components 
are registered into container, otherwise it is not guaranteed that your application will work correctly.

Once container is booted, we can use components that are stored in it. 
To fetch it use locate method like in following example:
--------------- 
container.locate!Color.print;
---------------

Try running the example, and you'll see in output the Color that was registered in container.
---------------
Color is:	Color(250, 210, 255)
---------------

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

void print(Color color) {
    writeln("Color is:\t", color);
}

void main() {
    SingletonContainer container = new SingletonContainer; // Creating container that will manage a color
    
    container.register!Color // Register color into container.
        .set!"r"(cast(ubyte) 250) // Set red color to 250
        .set!"g"(cast(ubyte) 210) // Set green color to 210
        .set!"b"(cast(ubyte) 255); // Set blue color to 255
        
    container.instantiate(); // Boot container (or prepare managed code/data).
    
    container.locate!Color.print; // Get color from container and print it.
}