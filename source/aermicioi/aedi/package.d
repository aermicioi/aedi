/**
Aedi, a dependency injection library.

$(BIG $(B Why should it be used: ))
$(UL
    $(LI Eases the development of applications by taking the task of wiring the 
    interdependent code (objects). )
    $(LI Helps in decopling of different components of application. )
    $(LI Eases the management of dependencies between application components. )
    )
    
$(BIG $(B When should it be used: ))
$(UL
    $(LI When a project has a high number of interdependent components. )
    )
    
$(BIG $(B How should it be used: ))

It's simple:

$(OL 
    $(LI Spawn a container. )
    $(LI Register an object. )
    $(LI Configure object. )
    $(LI Repeat 2-3, if another object needs to be in container. )
    $(LI Done )
    )

Here is an example:
--------------
class D {

	public {
		int i_;

		this(int i) {
			this.i_ = i;
		}
	}
}

class O {
	public {
		D dependency_;

		void setDependency(D dep) {
			this.dependency_ = dep;
		}
		
	}
}

auto singleton = new SingletonInstantiator;

singleton.register!O
	.set!"setDependency"(
		lref!D
	);
	
singleton.register!D
	.construct(10);
	
singleton.instantiate();

auto o = singleton.locate!O;
--------------

Instead of configuring by code, it is possible to configure by annotation.

Here are basic annotations that can be used out of the box:
$(OL
    $(LI component -> Denotes that class shoud be registered in container. )
    $(LI constructor -> Calls annotated constructor, with arguments passed in it. )
    $(LI setter -> Calls annotated method, with arguments passed in it. )
    $(LI autowired -> Calls annotated constructor or method, with arguments being references to arguments in annotated list. )
    )
An example of annotation based configuration:
--------------
@component
class D {

	public {
		int i_;
//        Uncomment one of it to apply it
//        @constructor(20)
//        @autowire
		this(int i) {
			this.i_ = i;
		}
	}
}

@component
class O {
	public {
		D dependency_;
//        Uncomment one of it to apply it
//        @setter(lref!D)
//        @autowire
		void setDependency(D dep) {
			this.dependency_ = dep;
		}
		
	}
}

auto singleton = new SingletonInstantiator;

singleton.componentScan!(D, O); // We can pass a list of classes that are annotated with @component
singleton.componentScan!(app); // Or we just can pass, a module that contains @component annotated classes.
	
singleton.instantiate();

auto o = singleton.locate!O;
--------------

Currently the library provides 2 containers:
$(OL
    $(LI singleton -> Serve same object, during it's lifetime. )
    $(LI prototype -> Serve new object, on each access. )
    )
    
We can use on both of them, annotation based, as well as code based configuration, just do not forget instantiating both of them.

$(BIG $(B Container for parameters, or already instantiated data: ))

Aedi provides an implementation of a container that can store already instatiated data.
Be it, a string, object, int, double, or even function, the ObjectStorage!() and code api
is able to handle it nicely.

Here is an example of how to fill in the container: 
--------------
ObjectStorage!() parameters = new ObjectStorage!();

parameters.register(new D(10));
parameters.register(new D(10), "custom identity");
parameters.register(10);	// The container will store this int by its type, hence the id will be just "int"
parameters.register(10, "custom int");
parameters.register(delegate () {
    import std.stdio;
    writeln("hello world");
});

parameters.locate!D; // Returns first object
parameters.locate!D("custom identity"); // Returns second object
parameters.locate!int; // Returns the first int.
parameters.locate!(void delegate ()); // When, locating a function, specify it's inferred atrributes as well. Failing to do so will generate an exception.
--------------

Any instantiated data saved using register function, can be fetched only by it's type. 
No implicit conversion from one type to another type is possible at the moment 
(ex: locating a int while casting it to long will raise an exception)

For already instantiated data, no annotation based api is available at the moment.

$(BIG $(B Composition of multiple containers: ))

Sometimes, it is required, to use objects that have, prototype scope, along with singleton scope, or a set of parameters.
Aedi, does allow to compose a set of containers into one. 

Here is an example:
--------------
PrototypeInstantiator prototype = new PrototypeInstantiator;
SingletonInstantiator singleton = new SingletonInstantiator;
ObjectStorage!() parameters = new ObjectStorage!();
AggregateLocator!() locator = new AggregateLocatorImpl!();

locator.set("prototype", prototype);
locator.set("singleton", singleton);
locator.set("parameters", parameters);

// Use registerInto to register object by it's type into a container, on composite container.
locator.registerInto!O
	.set!"setDependency"(
		lref!D
	);
	
locator.registerInto!D("prototype")
	.construct(10);
	
locator.register("Some string", "id");
locator.register(10, "an int by id");
	
prototype.instantiate;
singleton.instantiate;

assert(locator.locate!D != locator.locate!D);
assert(locator.locate!O == locator.locate!O);
assert(locator.locate!string == "Some string");
assert(locator.locate!int("an int by id") == 10);
--------------

From example we can see that register api, works well with composited containers.
The difference between composited and single containers is, that when registering
an object, pass the name of underlying container (where to save the object). 
By default on registering, it is assumed that a "singleton" container is available
in composite one. If there is no such container, an exception is raised, due to
inability to find underlying container.
When registering, already instantiated data (ints, strings, etc.), register api
assumes that a container named "parameters" is available in composite one.
If not an exception is raised.

For annotation based registering in composite container, additional annotations are
available that control how, and where the components will be stored:
$(OL
    $(LI @qualifier -> denotes how a component will be named in container )
    $(LI @instantiator -> specifies in which container should be component stored )
)
Same convention, as with code api, is available in annotation api. By not
specifying @instantiator annotation, container by "singleton" id will be searched
in composite container, and the object will be registered in that container. Failing
to provide a "singleton" container in composite one, while a class (object), does not
have @instantiator annotation, an exception will be raised.

$(B Note:)
As a convenience, a composite container called ApplicationInstantiator is available,
containing singleton, prototype and parameters containers. It's usually enough for
basic usage.

$(BIG $(B Extending: ))

Aedi does allow, two directions in where to extend the library:
$(OL
    $(LI Container extension. )
    $(LI Factory extension. )
)
    
$(BIG $(B Container extending: ))

In aedi, a container serves not only as a holder of objects. It does manage
the lifetime of the objects contained in them. For a singleton container
this implies that it will store objects as long as it itself is alive,
while prototype container, will spawn as many objects as requested, and forget
them.

Implement a new container, when more complex logic is required in handling
the lifetime of contained objects.

To implement a new container, it has to implement Instantiator interface
(see aermicioi.aedi.instantiator.instantiator.d). Implementing this interface
allows your container to interact with rest of aedi library, except of configurer
package of aedi library. To allow a container to interact with configurer package
implement in your container ConfigurableInstantiator interface, or Storage!(Factory, string)
(ConfigurableInstantiator extends AliasAware interface to allow aliasing of contained objects).

$(BIG $(B Factory extending: ))

While container, is used to manage and contain, objects, factories in aedi are used
to instantiate, and dispose (note: not at the moment, but in next release) objects.
Singleton, and prototype containers actually, accept factories, for registered objects,
and when they are instantiated, or objects are accessed, they use, factories, to actually
instantiate objects that are requested. Therefore, under the hood, the register api, as well
as annotation api, are actually spawning factories for each registered object in container,
and container uses them to create contained objects.

Implement a new factory when, a different instantiation logic is required than the provided ones
in aedi (See: aermicioi.aedi.factory.factory.d for basic interface).

$(BIG $(B Note: )) 

implemented factories in aedi, use LocatorReference objects, to identify that, an argument is
actually a reference in container. Implement additional logic, for recognizing LocatorReferences, in case
when, factory may accept lref arguments (ex: lref!Object, "id".lref).

Aedi does provide on top Factory interface (located in aermicioi.aedi.factory.factory.d), a GenericFactory
that splits up the instantiation process into two steps:
$(OL
    $(LI Object creation )
    $(LI Object configuration )
) 

Each building step is encapsulated in objects that extend InstanceFactory interface (1),
and PropertyConfigurer (2). InstanceFactories, are used to instantiate the object,
and constructor call, in examples above does actually create a InstanceFactory,
that calls objects constructor with arguments passed in. GenericFactory
should use InstanceFactory to instantiate the object, while PropertyConfigurers
should be used to configure further the spawned object.
PropertyConfigurer objects, are used by GenericFactory to configure spawned object.
The set call, or setter annotation, in examples above do create a PropertyConfigurer, 
that calls the method, with passed arguments.
GenericFactory will call a InstanceFactory first, and then will invoke underlying
PropertyConfigurers to configure the object, and return it once it is finished.

Implement a InstanceFactory, or PropertyConfigurer, when only a part of instantiation
process is required to change (ex: register a controller in URLRouter of vibe.d library,
or deserialize an object from some source).

$(BIG $(B Extending configurer package: ))

Both, code api, and annotation api are based, on GenericFactory factories. Therefore
register, or @component actually spawns a GenericFactory implementation, that is
configured further with custom InstanceFactory and PropertyConfigurers.

Once a new factory is implemented, it's recommended to wrap creation of such factory
into a function of such form:
------------
GenericFactory!T factoryName(T)(GenericFactory!T factory, Args....)
------------

Such format will allow seamless integration with code api, and will allow
function chaining (as in examples above).

It is possible to extend annotation api as well. To do so, create an annotation
that implements one of the following static interfaces:
$(UL
    $(LI canFactoryGenericFactory -> Struct, will be treated as a source of GenericFactory )
    $(LI canFactoryInstanceFactory -> Struct, will be treated as a source of InstanceFactory )
    $(LI canFactoryPropertyConfigurer -> Struct, will be treated as a source of PropertyConfigurer )
)

Any of interfaces from the list, have a method that returns one type of factory, a GenericFactory,
a InstanceFactory, or a PropertyConfigurer. Returned factories, are used to spawn the object.
Once annotation implements one of following interfaces, annotation system, will use it to spawn
the object. @component implements canFactoryGenericFactory interface while @constructor and @setter
annotation implement canFactoryInstanceFactory and canFactoryPropertyConfigurer respectively.
$(B See: ) aermicioi.aedi.configurer.annotation.d for provided interfaces.
 
$(BIG $(B Features to be implemented: ))
$(OL
    $(LI A way to allow, singleton objects to access objects that are in instantiators with a narrower scope. )
    $(LI More unit tests. )
    $(LI More thorough type check of passed arguments to constructors and methods. )
    $(LI Support for yaml based configuration. )
    $(LI Better Extensibility. )
    $(LI Stable api. )
    $(LI Usage of allocators. )
)

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
module aermicioi.aedi;

public import aermicioi.aedi.exception;
public import aermicioi.aedi.configurer;
public import aermicioi.aedi.factory;
public import aermicioi.aedi.instantiator;
public import aermicioi.aedi.storage;