AEDI
====

------

A library that provides dependency injection containers (prototype, and singleton for now).
Preliminary version.
More description is available in library docs (you can generate them with `dub build --build=docs` or `dub build --build=ddox`).

#Installation

-----
Just add it as dependency in dub.json, or clone repository.
	
	"dependencies" : {
		"aermicioi/aedi" : "~master"
	}
	
#Usage
-----

Simply, create a container, and register objects into it.

	import aermicioi.aedi;
	
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
		.method!"setDependency"(
			lref!D
		);
		
	singleton.register!D
		.constructor(10);
		
	singleton.instantiate();
	
	auto o = singleton.locate!O;
	
It is possible to configure dependencies of objects through setter, and constructor injection.
For setter injection chain method!"methodName" after register operation.
For construction injection chain constructor after register operation.
Multiple setter and constructor injections calls can be done in chain.

If you want a prototype container, just use PrototypeInstantiator.

Also singleton and prototype containers supports aliasing of object identities to other identities.
Example:

	singleton.link("originalIdentity", "additionalIdentity");

#Constructor and setter injections

--------

Here is an example of more ways how constructor and injection can be used.

	import aermicioi.aedi;
	
	class Test {
	    
	}
	
	class MTest : MTestInterface {
	    
	}
	
	class Test1 {
	    
	    Test obj;
	    MTestInterface firstObj;
	    MTestInterface secondObj;
	    string id;
	    double d;
	    
	    this(
	        Test obj,
	        MTestInterface firstObj,
	        MTestInterface secondObj,
	        string id,
	        double d
	    ) {
	        this.obj = obj;
	        this.firstObj = firstObj;
	        this.secondObj = secondObj;
	        this.id = id;
	        this.d = d;
	//        Do some init stuff, and assigning dependencies
	    };
	    
	    void setTest(Test t) {
	//        Set t dependency
	    }
	}
	
	interface MTestInterface {
	    
	}
	
	void main(string[] args) {
		auto container = new SingletonInstantiator(); // Created a singleton container.
		
		container.register!Test();
		
		// It is possible to register an object, by it's type, interface or custom string. Registering by type or interface will result in registering an object with fully qualified name of Type or Interface.
		container.register!Test(
			"CustomId"
		);
		
		// In this case we registered, an object of type Moo by it's fully qualified type (ex. "app.Moo" if Moo class is located in app module.
		container.register!MTest();
		
		// Now registered a new instance of Moo object by MooInterface fully qualified name.
		container.register!(MTestInterface, MTest)(); 
		
		container.register!Test1
		.constructor(
			"CustomId".lref,
			lref!MTest, // Search by fully qualified type name,
			lref!MTestInterface,
			"A simple string passed as fourth argument",
			10.9, // A double/float passed as fourth argument.
		)
		.method!"setTest"(lref!Test); // Passing arguments to methods of object (Setter injection).
		
		// It is important to boot container before use of it. Failing to do so, will mean undefined behavior, if used.
		container.instantiate(); 
		
		// Will return a object casted to Foo, with id as fully qualified name of Foo.
		Test1 test1 = container.locate!Test1; 
		 // Will return a object casted to Test, with id as fully qualified name of Test.
		auto test = container.locate!Test();
		// Will return a object casted to Test, with id "CustomId".
		auto testCustom = container.locate!Test("CustomId");
		// Will return a object casted to MooInterface, with id as fully qualified name of MooInterface.
		auto mtestinterface = container.locate!MTestInterface;
		auto mtest = container.locate!MTest;
		
		assert (test1.obj == testCustom);
		assert (test1.obj != test);
		assert (test1.firstObj == mtest);
		assert (test1.secondObj == mtestinterface);
		assert (mtestinterface != mtest);
		assert (test1.id == "A simple string passed as fourth argument");
		assert (test1.d == 10.9);
	}

In this example, a singleton container is created and objects are loaded into it. To indicate that an argument from constructor or setter is a reference to another object in container use lref!(Dependency) or "some object id".lref.

## Register, constructor and method
The register call returns a factory object which is used to configure further the object in container. Further calls of constructor and method operate on it, and returns the factory object back, for a chained sequence of calls. This factory object is used internally by container to factory and configure object.

Example:

	// Return a configuration object for Test object
	auto conf = container.register!(Test) 
	// Set the arguments for constructor of this object.
	conf.constructor("some data");
	// Set the arguments for method setProp that will be called during construction of Test.
	conf.method!"setProp"("some data"); 
	
Note: singleton and prototype containers accept only factories for objects. Passing already instantiated object will end in a compiler error. For building a container with object already instantiated, see composing containers chapter.

##Getting an object from storage
If there is necessity to extract get an object from container use locate family of functions to do this.
Note if the object is present but it is not of type indicated in test, null will be returned. If it doesn't exist, an exception will be thrown.

Example:

	// Will search for Test object
	auto object = container.locate!Test();
	// Will search for Test object with customId identity
	auto customObject = container.locate!Test("customId"); 
	
## Registering non object type.

It is possible to register data that is not an Object with a container that accepts Objects instead of factories. All data that are not Objects will be wrapped into a object and stored in container.
To register a struct or int, just call register on container as done in examples above. 
Note: configuring structs as objects is not possible at the moment. Invoking constructor, or method will end in compiler error.

To fetch data from container call locate as with objects in example above. It will return wrapper object that encapsulates the data. The data is stored in value property of Wrapper which is also subtyped by Wrapper (`alias value this`). So before using the value, check if the data is returned (i.e. it is not null).

Example:

	auto objectStorage = new ObjectStorage!();
	
	objectStorage.register(10L, "a int");
	objectStorage.register(tuple(10L, "a"), "id");
	
	assert (objectStorage.locate!long("a int").value == 10);
	assert (objectStorage.locate!(Tuple!(long, string))("id").value == tuple(10L, "a"));
	
Note: it is possible to indicate as dependency non object types as well, using lref family of functions.

#Composition of multiple containers.

If singleton container is not enough for application, say prototype or a storage of data that are not objects (structs, strings, etc.) is needed. It is possible to compose a set of containers into one.

Here is an example of how to do it:

	import aermicioi.aedi;
	
	class Test {
	    
	}
	
	class MTest : MTestInterface {
	    
	}
	
	class Test1 {
	    
	    Test obj;
	    MTestInterface firstObj;
	    MTestInterface secondObj;
	    string id;
	    double d;
	    
	    this(
	        Test obj,
	        MTestInterface firstObj,
	        MTestInterface secondObj,
	        string id,
	        double d
	    ) {
	        this.obj = obj;
	        this.firstObj = firstObj;
	        this.secondObj = secondObj;
	        this.id = id;
	        this.d = d;
	//        Do some init stuff, and assigning dependencies
	    };
	    
	    void setTest(Test t) {
	//        Set t dependency
	    }
	}
	
	interface MTestInterface {
	    
	}
	
	void main(string[] args) {
		auto singleton = new SingletonInstantiator;
		auto prototype = new PrototypeInstantiator;
		auto parameters = new ObjectStorage!();
		
		AggregateLocator!() aggregateContainer = new AggregateLocatorImpl!();
		aggregateContainer.add("singleton", singleton);
		aggregateContainer.add("prototype", prototype);
		aggregateContainer.add("parameters", parameters);
	}
	
To compose a set of containers into one, create an aggregate locator that will be used to search for dependencies for objects, as well data for them.

Registering of objects for an aggregated container should be done for each subcontainer separately, with addition of supplying the aggregate locator as source of dependencies for contained object. Instantiaton for each container is done separately as well.

Example (insert code at end of previous example):

	prototype.register!Test(aggregateContainer);
	prototype.register!Test(
	    aggregateContainer,
		"CustomId"
	);
	parameters.register!string("A simple string passed as fourth argument");
	parameters.register!double(10.9, "param.id");
	
	singleton.register!MTest(aggregateContainer);
	singleton.register!(MTestInterface, MTest)(aggregateContainer);
	
	singleton.register!Test1(aggregateContainer)
	.constructor(
		"CustomId".lref,
		lref!MTest,
		lref!MTestInterface,
		lref!string,
		"param.id".lref,
	)
	.method!"setTest"(lref!Test);
	
	singleton.instantiate();
	prototype.instantiate();
	
	Test1 test1 = aggregateContainer.locate!Test1;
	auto test = aggregateContainer.locate!Test();
	auto testCustom = aggregateContainer.locate!Test("CustomId");
	auto mtestinterface = aggregateContainer.locate!MTestInterface;
	auto mtest = aggregateContainer.locate!MTest;
	
	assert (test1.obj != testCustom);
	assert (test1.obj != test);
	assert (test1.firstObj == mtest);
	assert (test1.secondObj == mtestinterface);
	assert (mtestinterface != mtest);
	assert (test1.id == "A simple string passed as fourth argument");
	assert (test1.d == 10.9);
	
Running the example, we can see that all tests pass, hence while constructing of Test1 object, factory was able to get the required dependencies (even the double and string from parameters storage). Register family of functions accepts additionally source of dependencies for constructed object. If source of dependencies is not passed to register function, it is assumed that the container in which an object is registered is a source of objects for dependencies.

## Eliminating need of passing locator on each register call.

Passing each time locator object to register function may be cumbersome. To eliminate the need of passing locator object, wrap instantiator into a Registerer struct which accepts a locator that will be passed to register function during container configuration.

Example:

	void main(string[] args) {
		auto singleton = new SingletonInstantiator;
		auto prototype = new PrototypeInstantiator;
		auto parameters = new ObjectStorage!();
		
		AggregateLocator!() aggregateContainer = new AggregateLocatorImpl!();
		aggregateContainer.add("singleton", singleton);
		aggregateContainer.add("prototype", prototype);
		aggregateContainer.add("parameters", parameters);
		
		auto registerer = new Registerer(singleton, aggregateContainer);
		
		registerer.register!MTest();
		registerer.register!(MTestInterface, MTest)();
	}
	
Configuring container through a registerer instance eliminates the need to pass "aggregateContainer" at each call of register function.

#Extending containers behavior

There a two ways to extend library logic.

1. Create a custom factory, that is responsible to construct a object for container.
2. Create a container, or extend existing one.

##Creating/extending containers.

The main role of containers is manipulation of with lifetime of contained objects (hence it should decide whether an object should live or die).

As reference let's show the chain of interfaces that SingletonInstantiator implements:
SingletonInstantiator -> ConfigurableInstantiator -> Instantiator -> Locator!(Object, String)
ConfigurableInstantiator -> Instantiator, Storage!(Factory, string), AliasAware!(string)


The minimal requirement for a container to work with the rest of application/library is implementation of Locator!(Object, string).
Hence, a container should provide means to check if it contains an object, and fetch it from container. How objects are stored in container is responsibility of implementor to define.


Instantiator interface defines an additional instantiate method over Locator interface, which is used to prepare container for future use by client code. Any container that requires an initial preparation before use, should implement this interface.


ConfigurableInstantiator as seen above, implements Storage!(Factory, string) interface additionally. For containers that are intended to be configurable through register function family, and require an instantiation phase before usage, ConfigurableInstantiator should be choosen as interface for implementation.

Note: register family of functions, work with Storage!(Factory, string) objects to store object factories, that are returned further for configuration. Any container implementing Storage!(Factory, string) interface will work with register function family.
Note: in future versions of library, configuration through annotation is planned, and it will use register family of functions to do it's job, so it's recommended that containers implement ConfigurableInstantiator if instantiaton phase is needed or, implement Storage!(Factory, string) as well.

##Creating/Extending object factories.

Singleton and prototype containers, use Factory objects to instantiate contained objects, hence a Factory objects encapsulates the logic required to create and configure contained object. Extending object factories is useful when it is required to modify/add the construction/configuration logic for an object contained in singleton or prototype containers (or any container implementing Storage!(Factory, string)).

To define points of extending let's look at interface chain of factory returned by register family of functions:

GenericFactoryImpl -> GenericFactory -> Factory

A minimal requirement for an object factory for it to be usable in singleton or prototype container is to implement a Factory interface, which defines a factory() method constructs an object (ex. singleton calls factory() method of factory object for respective object if object is not already instantiated).
For a total control of object construction and configuration, implement Factory interface.

It is not required to implement a new Factory, if it is required to add/modify only a part of instantiation process. It is enough to create objects implementing interfaces discussed below.
GenericFactory is a factory that splits the process instantiation into two configurable phases:

1. Construction of object (Allocation, and construction of object).
2. Configuration of object (Calls to methods/properties of object with data);

Each instantiation phase is encapsulated in a object implementing specific interface:

1. Construction phase is encapsulated in object implementing InstanceFactory(T) interface.
2. Configuration phase is encapsulated in object implementing PropertyConfigurer(T) interface.

So, if only a part of construction/configuration is required to modify or to add, it is enough to encapsulate it into objects implementing respective interface for phase.

Example of extending configuration phase of GenericFactory:
	
	import aermicioi.aedi;
	import vibe.http.router;
	import vibe.http.server;
	import vibe.web.web;
	
	/**
	Let's say that Test is a web interface for vibed library (if you are unfamiliar with vibed, check code.dlang.org for vibed).
	**/
	class Test {
	    
	    private {
	        int i;
	    }
	    
	    public {
	        this(int value) {
	            this.i = value;
	        }
	        
	        auto index() {
	            writeln("Have we get here?");
	    		render!("index.dt");
	        }
	    }
	}
	
	class RouteConfigurer(T) : PropertyConfigurer!T {
	    
	    private {
	        URLRouter router;
	    }
	    
	    public {
	        
	        this(URLRouter router) {
	            this.router = router;
	        }
	        
	        void configure(ref T object) {
	            this.router.registerWebInterface(object);
	        }
	    }
	}
	
	GenericFactory!T route(T)(GenericFactory!T factory, URLRouter router) {
	    factory.propertyFactory(new RouteConfigurer!T(router));
	    
	    return factory;
	}
	
	SingletonInstantiator singleton;
	
	shared static this()
	{
		auto router = new URLRouter;
		singleton = new SingletonInstantiator;
		singleton.register!Test()
		.constructor(10)
		.route(router);
		
		singleton.instantiate;
	
		auto settings = new HTTPServerSettings;
		settings.port = 8081;
		settings.sessionStore = new MemorySessionStore;
		listenHTTP(settings, router);
	}

Note: once configuration/creation logic is encapsulated, it is advised to define a function that creates custom factory, and inserts it into GenericFactory (see constructor, or method functions used after register function during configuration). It will allow your custom logic to be chained with constructor and method calls.

Note: the register, method, constructor set of family actually use GenericFactory, and it's phases to configure an object contained in a container. register family function family inserts into container a GenericFactory and returns it back. The returned factory, is used afterwards with constructor and method functions that injects InstantiationFactory and PropertyConfigurer objects into GenericFactory. 

#Planned development
- Unit tests.
- More thorough type check of passed arguments to constructors and methods.
- Support for annotation based configuration.
- Support for yaml based configuration.
- Better Extensibility.
- Stable api.
- Usage of allocators.
- A way to allow, singleton objects to access objects that are in instantiators with a narrower scope.