/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:

For an end consumer of Aedi library, it is rarely needed to extend it's logic
with something new. But for a developer that wants to integrate Aedi library
with his/her framework, sometimes it is required to extend library to integrate it
with rest of framework. Aedi was designed with purpose of extending it in two 
directions:

$(OL
    $(LI Containers -> responsible for created components. )
    $(LI Component factories -> responsible for creating components )
    )
    
This tutorial will show the most basic (yet not easiest) version
of extending library's factories with new custom ones. 

A component factory, as name states is responsible for creation and
assembly of components registered in container. Containers are using
them to instantiate components, that are requested. In all examples
up to this point, when we registered components in container, we actually
registered factories for those components (this is not true for value container and
registered data in it). So, when default implementations of factories present in
library are not enough, extend it with new factory implementing desired
behavior. 

All factories present in Aedi library are extending Factory(T) interface:
------------------
interface Factory(T) : LocatorAware!() {
	public {
		T factory();
		@property {
    		TypeInfo type();
		}
	}
}
------------------

Therefore if there is need for example to create some component, and configure it using
information from external source (db, config file, etc.) define a factory that implements
Factory!(YourComponent) interface which will do all dirty job for you.

For example purposes, we'll design custom factory which logs start of component's creation
and end of it. The creation logic is simple, just new it or allocate on stack:
------------------
class LoggingFactory(T) : Factory!T {
    private {
        Locator!() locator_;
    }
    
    public {
        T factory() {
            import std.experimental.logger;
            
            info("Creating our little component");
            static if (is(T : Object)) {
                auto t = new T;
            } else {
                auto t = T();
            }
            info("Ended creation of component");
            
            return t;
        }
        
        TypeInfo type() {
            return typeid(T);
        }
        
        LoggingFactory!T locator(Locator!() locator) @safe nothrow {
        	this.locator_ = locator;
        
        	return this;
        }
    }
}
------------------

Notice, that a factory can accept optionally a locator of components. You can
use it to locate required components if needed. If not just ignore it.

For aesthetic purposes, we'll wrap the newing the factory in a wrapper:
------------------
auto registerLogged(Type)(Storage!(ObjectFactory, string) container, string identity) {
    auto factory = new LoggingFactory!Type;
    container.set(new WrappingFactory!(LoggingFactory!Type)(factory), identity);
    
    return factory;
}
------------------

Inspecting the code, you'll notice that LoggingFactory isn't passed directly to container,
yet it is wrapped in some WrappingFactory, and after that saved in container.
This is due to the fact that containers can accept only Factory!Object implementaions,
which WrappingFactory is implementing. It is designed so with the purpose of erasing 
the type of component while it is stored in container. WrappingFactory wraps up the 
real factory, and when container asks it to create component it will use wrapped
factory to do the job. It will wrap in a `Wrapper` object results that do not inherit
Object class. The type of component is restored during locate!(Type) phase which
uses RTTI to cast erased component to desired type or to Wrapper!Type if the component type
does not inherit Object class. If type of component mismatches type passed in locate
method, an exception is thrown denoting a bug in program logic.

Let's create a container, pass to it LoggingFactory and print the result of LoggingFactory
creation:
------------------
void main() {
    
    SingletonContainer container = new SingletonContainer;
    
    container.registerLogged!Tire("logging.tire");
    container.registerLogged!int("logging.int");
    
    container.instantiate();
    
    container.locate!Tire("logging.tire").writeln;
    container.locate!int("logging.int").writeln;
}
------------------

Running the container we will get following result:
------------------
2017-03-04T00:34:33.401:app.d:factory:161 Creating our little component
2017-03-04T00:34:33.401:app.d:factory:167 Ended creation of component
2017-03-04T00:34:33.401:app.d:factory:161 Creating our little component
2017-03-04T00:34:33.401:app.d:factory:167 Ended creation of component
Tire(0 inch, nan atm, )
0
------------------

As we can see our logging factory is doing designed job.
Try to implement your own factory, to understand how Aedi works behind the scenes.

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

class LoggingFactory(T) : Factory!T {
    private {
        Locator!() locator_;
    }
    
    public {
        T factory() {
            import std.experimental.logger;
            
            info("Creating our little component");
            static if (is(T : Object)) {
                auto t = new T;
            } else {
                auto t = T();
            }
            info("Ended creation of component");
            
            return t;
        }
        
        TypeInfo type() {
            return typeid(T);
        }
        
        LoggingFactory!T locator(Locator!() locator) @safe nothrow {
        	this.locator_ = locator;
        
        	return this;
        }
    }
}

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

auto registerLogged(Type)(Storage!(ObjectFactory, string) container, string identity) {
    auto factory = new LoggingFactory!Type;
    container.set(new WrappingFactory!(LoggingFactory!Type)(factory), identity);
    
    return factory;
}

void main() {
    
    SingletonContainer container = new SingletonContainer;
    
    container.registerLogged!Tire("logging.tire");
    container.registerLogged!int("logging.int");
    
    container.instantiate();
    
    container.locate!Tire("logging.tire").writeln;
    container.locate!int("logging.int").writeln;
}