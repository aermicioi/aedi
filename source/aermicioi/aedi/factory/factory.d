/**


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
	Alexandru Ermicioi
**/
module aermicioi.aedi.factory.factory;

import aermicioi.aedi.storage.locator_aware;

/**
Interface for objects that create objects.

It is used to store different types of object factories in DI containers. 
Any factory extending this interface will encapsulate logic required to construct an object that will be 
setd by DI container to client application.
If there is need to implement custom logic for creation of some kind of objects, a client should encapsulate
factory logic into a class which inherits Factory interface, afterwards, this factory will be acceptable by all
DI containers, and DI containers will call this factory when a new object is required.
**/
interface Factory : LocatorAware!() {
	
	public {
		
		/**
		Factories an object of a certain type.
		
		This method is used to call factory logic of a new Object. Any DI container that is in need of new object
		will call this method to get it.
		
		Throws:
			InProgressException when some DI container, or something else is trying to factory an object, while the factory is already in building process. It is used to detect circular reference errors.
		
		Returns:
			Object newly constructed, of some type.
		**/
		Object factory();
		
		@property {
		    
		    /**
    		Get the type info of object that is created.
    		
    		Returns:
    			TypeInfo object of created object.
    		**/
    		TypeInfo type();
		    
		    /**
		    Checks if the factory is currently building an object.
		    
		    This method is used by DI containers, in order to check circular reference errors. Ex of usage is when
		    a factory in building process can require additional dependencies from a DI container, which in turn can reference
		    to the instance which the factory is currently building. Since it's a circular reference, it is practically impossible
		    to solve it, so the DI will throw an circular error exception.
		    **/
			bool inProcess();
		}
	}
}

/**
Represents a reference to an object in a locator/container.

Any object of this type encountered in factories should be treated as a declaration that required argument for
object construction/configuration is located into a locator/container, and should be fetched and used instead
of LocatorReference.
**/
class LocatorReference {
	private {
		string id_;
	}
	
	public {
		
		this(string id) {
			this.id = id;
		}
		
		@property {
			
			string id() {
				return this.id_;
			}
			
			LocatorReference id(string id) {
				this.id_ = id;
				
				return this;
			}
		}
	}
}

import std.traits : fullyQualifiedName;
alias name = fullyQualifiedName;

/**
A convenience function that wraps creation of reference to object.
**/
auto lref(string id) {
    return new LocatorReference(id);
}

/**
ditto
**/
auto lref(T)() {
    import std.traits;
    
    return name!T.lref;
}

/**
ditto
**/
auto lref(string name)() {
    return name.lref;
}

template toLref(Type) {
    auto toLref() {
        return name!Type.lref;
    }
}

template toLrefType(Type) {
    alias toLrefType = LocatorReference;
}
