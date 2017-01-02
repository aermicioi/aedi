# Aedi, a dependency injection library.

## Why should it be used

- Eases the development of applications by taking the task of wiring the interdependent code (objects).
- Helps in decopling of different components of application.
- Eases the management of dependencies between application components.
    
## When should it be used

- When a project has a high number of interdependent components.
    
## How should it be used

**It's simple:**

1. Spawn a container.
2. Register an object.
3. Configure object.
4. Repeat 2-3, if another object needs to be in container.
5. Done

**Here is an example**

```D
@component
struct Color {
    @setter(cast(ubyte) 200)
    ubyte r;
    
    @setter(cast(ubyte) 200)
    ubyte g;
    
    @setter(cast(ubyte) 200)
    ubyte b;
}

@component
struct Size {
    
    @setter(295)
    ulong width;
    
    @setter(210)
    ulong height;
}

@component // mark an aggregate as a component managed by di container.
@qualifier("page.paper") // use it, to name a component other that by it's type.
class Paper {
    public {
        enum Quality {
            low,
            medium,
            high
        }
    }
    
    private {
        Quality quality_;
        Color color_;
    }
    
    public {
        
        @constructor(lref!(Paper.Quality), "color.white".lref) // Use constructor annotation to denote that component is buildable using a constructor.
        this(Quality q, Color c) {
            this.quality(q);
            this.color(c);
        }
        
        Paper quality(Quality quality) @safe nothrow pure {
        	this.quality_ = quality;
        
        	return this;
        }
        
        Quality quality() @safe nothrow pure {
        	return this.quality_;
        }
        
        Paper color(Color color) @safe nothrow pure {
        	this.color_ = color;
        
        	return this;
        }
        
        Color color() @safe nothrow pure {
        	return this.color_;
        }
    }
}

@component
@fact(// An aggregate can be annotated with a custom factory.
    (Locator!() loc) {
        auto paper = new HardenedPaper(Paper.Quality.high, loc.locate!Color);
        paper.color = loc.locate!Color;
        
        return paper; 
})

@component
@qualifier!Paper() // It's possible to name an aggregate by some Type FQN's.
class HardenedPaper : Paper {
    
    this(Quality q, Color c) {
        super(q, c);
    }
}

@component
@contained("prototype") // If di container consists of more than one container, use contained to denote which sub-container should manage/contian component.
class Page {
    private {
        Paper paper_;
        string text_;
        Color textColor_;
        Color foreground_;
    }
    
    public {
        
        @setter(lref!Size) // Set the field to a component identified by Size's FQN (fully qualified name).
        Size size;
        
        @setter("page.paper".lref) // Set the field to a component identified by a custom name.
        Page paper(Paper paper) @safe nothrow pure {
        	this.paper_ = paper;
        
        	return this;
        }
        
        @autowired // Wire the field by type's FQN
        Color textColor;
        
        @autowired // Wire the field by arguments FQN's. Multiple arguments can be automatically wired.
        Page foreground(Color foreground) @safe nothrow pure {
        	this.foreground_ = foreground;
        
        	return this;
        }
        
        @autowired
        Page text(string text) @safe nothrow pure {
        	this.text_ = text;
        
        	return this;
        }
        
        Color foreground() @safe nothrow pure {
        	return this.foreground_;
        }
        
        Paper paper() @safe nothrow pure {
        	return this.paper_;
        }
        
        string text() @safe nothrow pure {
        	return this.text_;
        }
    }
}

@component
class Cover {
    private {
        Paper material_;
        string title_;
    }
    
    public {
        
        @setter(lref!Paper)
        Cover material(Paper material) @safe nothrow pure {
        	this.material_ = material;
        
        	return this;
        }
        
        @setter("book.title".lref)
        Cover title(string title) @safe nothrow pure {
        	this.title_ = title;
        
        	return this;
        }
        
        Paper material() @safe nothrow pure {
        	return this.material_;
        }
        
        string title() @safe nothrow pure {
        	return this.title_;
        }
    }
}

@component
@callback((Locator!() loc, Book book) { // Use it, when object is required to be configured in way that is not possible to do by means of library annotations.
    Page[] pages;
    foreach (i; 0 .. 99) {
        import std.conv;
        
        pages ~= loc.locate!Page;
        pages[$ - 1].text("Some text on page " ~ i.to!string);
    }
    
    book.pages(pages);
})
class Book {
    private {
        Cover cover_;
        Page[] pages_;
    }
    
    public {
        
        @autowired
        Book cover(Cover cover) @safe nothrow pure {
        	this.cover_ = cover;
        
        	return this;
        }
        
        Cover cover() @safe nothrow pure {
        	return this.cover_;
        }
        
        Book pages(Page[] pages) @safe nothrow pure {
        	this.pages_ = pages;
        
        	return this;
        }
        
        Page[] pages() @safe nothrow pure {
        	return this.pages_;
        }
    }
}

@component
class Bookshelf {
    
    public {
        
        Book getABook() {
            return new Book;
        }
    }
}

unittest {
    SingletonContainer container = new SingletonContainer; // Container that will hold our objects.
    
    container.register!Bookshelf; // Register Bookshelf as a component in container.
    
    container.register!Color // Register Color struct as a component in container.
        .set!"r"(cast(ubyte) 200)
        .set!"g"(cast(ubyte) 201)	// Set field g to ubyte 201.
        .set!"b"(cast(ubyte) 202);
    container.link(name!Color, "color.white");
        
    container.register!Size // Register Size struct as a component in container.
        .set!"width"(295)
        .set!"height"(210); // Set field height to ubyte 210.
        
    container.register!Paper("page.paper") // Register paper by page.paper identity.
        .construct( // instantiate Paper using it's constructor.
            Paper.Quality.high,
            "color.white".lref
        );
        
    container.register!Page() // store component in Prototype container
        .autowire!"size"
        .set!"paper"("page.paper".lref) // set paper to an object located in container.
        .autowire!"textColor"
        .autowire!"foreground";
        
    container.instantiate(); // prepare container for serving objects.
    
    assert(container.locate!Bookshelf !is null); // Check if instantiated
    assert(container.locate!Color == Color(200, 201, 202)); // Checking if Color was properly set.
    assert(container.locate!Size == Size(295, 210));
    assert(container.locate!Paper("page.paper").quality == Paper.Quality.high); // Checking if quality of page.paper is same as for Paper.Quality in container 
    assert(container.locate!Page.size == container.locate!Size); // Check if page's size was set correctly.
}
```

As seen in example, the first step is to create the container that will hold objects.
Once container is spawned, we proceed to registering into container object that it will wire.

The third line from unittest is the most simple variant to use:
```D
container.register!Bookshelf; // Register Bookshelf as a component in container.
```
It adds Bookshelf to container to be managed by it.

Once the object is added to container, a factory for this object will be returned.
This factory can be further configured, on how to construct the object.
On fifth line we can see a way on how to configure the factory:
```D
container.register!Color // Register Color struct as a component in container.
    .set!"r"(cast(ubyte) 200)
    .set!"g"(cast(ubyte) 201)	// Set field g to ubyte 201.
    .set!"b"(cast(ubyte) 202);
```
Color struct is added to container, and afterwards the set method is used to 
configure factory to set r,g,b fields of Color to their respective value.

Since the task of container is to wire objects between them, it should know
what should be wired, and what should not. To tell the container which dependencies
it should wire use lref to indicate that an argument is a reference to a dependency
in container, just like on line 45:
```D
container.register!Paper("page.paper") // Register paper by page.paper identity.
    .construct( // instantiate Paper using it's constructor.
        Paper.Quality.high,
        "color.white".lref
    );
```
We've told container that second argument of constructor is actually a reference to
something in container.

Following lines of code do basically the same, they add a struct/object to
container, and configure their factories on how to instantiate them.

Following methods are available to configure a struct/object's factory:

- construct - construct object using provided arguments)
- fact - use delegate/function to construct object)
- factoryMethod - use factory method pattern to create an object)
- set - set a field, call a method with passed arguments)
- autowire - construct/set with passed arguments)
- callback - call function/delegate to do some stuff on object)

A full example can be seen in aermicioi.aedi.test.example module. It shows almost
everything implemented in library.

An alternative to configuration of container by writing register commands, is using of 
annotations on object/structs that are managed by container.

Here is an example of annotation based configuration (annotations are present on objects from previous example):
```D
unittest {
    ApplicationContainer container = new ApplicationContainer;
    
    container.register(Color(255, 255, 255), "color.white"); //Save a struct in storage of values, identified by color.white.
    container.register("Aedi tutorial.", "book.title"); //Same as with Color struct.
    container.registerInto("A value saved by it's type FQN"); //Save a value in storage, identified by it's type FQN.
    container.registerInto(Paper.Quality.medium);
    container.register("Book title", "book.title");
    
    container.componentScan!Color; // scan struct component and save it in container.
    container.componentScan!Size;
    container.componentScan!Paper; // scan object component and save it in container. Use parameters container to fetch it's dependencies
    container.componentScan!(Paper, HardenedPaper); // scan object and save it by Paper's type FQN. Use parameters container to fetch it's dependencies
    container.componentScan!(Page, Cover, Book, Bookshelf); // scan several aggregates and save them in container. An object prefixed with one of it's interfaces will be registered by it in container.

    container.instantiate;
    
    assert(container.locate!Bookshelf !is null); // Check if instantiated
    assert(container.locate!Color == Color(200, 200, 200)); // Checking if Color was properly set.
    assert(container.locate!Size == Size(295, 210));
    assert(container.locate!Paper("page.paper").quality == container.locate!(Paper.Quality)); // Checking if quality of page.paper is same as for Paper.Quality in container 
    assert(container.locate!Cover.material is container.locate!Paper); // Checking if cover material is from a hardened paper.
}
```

As we can see, the process is almost like in example where register is used to add objects to container.
the difference is that, the container will fetch all required information about object's dependency from
annotations present on it. Furthermore, it's possible to specify a list of components to be registered instead
of one per componentScan. It's possible to pass one or more modules in componentScan, to scan them for 
objects or structs that should be managed by container. Here is an example on how to do it:
```D
container.componentScan!(aermicioi.aedi.test.example);
```
Pass one, or more modules. Container will scan them for components (objects/structs etc.).

Following annotations can be used to configure a container:

-  component -> Marks a struct or object as manageable by container. )
-  constructor -> Marks constructor to be called. )
-  setter -> Call, or set the annotated field. )
-  autowired -> Depending what is annotated with autowired annotation, it will construct, set a field, or call a method, using FQN of argument type to search for dependencies in container).
-  fact -> Use a function to construct object)
-  callback -> Use a function to manipulate object somehow)
-  @qualifier -> denotes how a component will be named in container )

Currently the library provides 2 containers:

-  singleton -> serves same object, during it's lifetime. )
-  prototype -> serves new object, on each request. )
    
Both of them support either way of configuring. 

## Container for values

In some cases, it is needed to store some data, that does not have any dependency on other elements
in container, and can be entirely stored. For such cases, there is a special container, that accepts
such data. To store data in it use register as in example below:
```D
unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    
    storage.register(Color(255, 255, 255), "color.white"); //Save a struct in storage of values, identified by color.white.
    storage.register("Aedi tutorial.", "book.title"); //Same as with Color struct.
    storage.register("A value saved by it's type FQN"); //Save a value in storage, identified by it's type FQN.
    
    assert(storage.locate!Color("color.white") == Color(255, 255, 255));
    assert(storage.locate!string("book.title") == "Aedi tutorial.");
    assert(storage.locate!string == "A value saved by it's type FQN");
}
```
Usage is pretty simple, call register, pass the value, and identity to it. If no identity is passed to register, it is implied that the value has as identity FQN of it's type.
One important remark is, that data saved in container, cannot be implicitly casted to some other compatible type. For example, we stored an ubyte by id "uby", and at some point we try to fetch it as an int. Such attempt  will generate only not found exception.

## Composition of multiple containers

In many cases it is required to have not a single container, but several, that implement different
behavior, like Singleton or Prototype. In such cases it possible to compose them into one bigger
container, and use it for wiring dependencies. Most flexible way to compose them is to use 
AggregateLocator container (see aermicioi.aedi.storage.aggregate_locator), but for simpler cases
there is ApplicationContainer, that by default contains a singleton, prototype and value container.
The syntax for composite containers differs only a little in comparison with examples above.
Here is an example: 
```D
unittest {
    ApplicationContainer container = new ApplicationContainer; // A composite container that consists of Singleton, Prototype, containers and a value storage. 
    
    container.register(Color(255, 255, 255), "color.white"); //Save a struct in storage of values, identified by color.white.
    container.register("Aedi tutorial.", "book.title"); //Same as with Color struct.
    container.registerInto("A value saved by it's type FQN"); //Save a value in storage, identified by it's type FQN.
    container.registerInto(Paper.Quality.medium);
    
    container.registerInto!Bookshelf; // Register Bookshelf as a component in container.
    
    container.registerInto!Color // Register Color struct as a component in container.
        .set!"r"(cast(ubyte) 200)
        .set!"g"(cast(ubyte) 201)	// Set field g to ubyte 201.
        .set!"b"(cast(ubyte) 202);
        
    container.registerInto!Size // Register Size struct as a component in container.
        .set!"width"(295)
        .set!"height"(210); // Set field g to ubyte 210.
        
    container.register!Paper("page.paper")
        .construct( // instantiate Paper using it's constructor.
            lref!(Paper.Quality), // lref is used to indicate that argument, is located in container. Check if it is of right type will be done at runtime.
            "color.white".lref
        );
        
    container.register!(Paper, HardenedPaper) // Register HardenedPaper in container with identity of Paper's FQN.
        .fact( // use the delegate to construct HardenedPaper. Useful to use when some special instantiation logic is required. 
            delegate(Locator!() loc) {
                return new HardenedPaper(Paper.Quality.high, loc.locate!Color);
            }
        );
        
    container.registerInto!Cover
        .autowire!"material" // autowire material. Searches a value for material field in container by it's type FQN.
        .set!"title"("Random title");
    
    container.registerInto!Page("prototype") // store component in Prototype container
        .autowire!"size"
        .set!"paper"("page.paper".lref) // set paper to an object located in container.
        .autowire!"textColor"
        .autowire!"foreground"
        .autowire!"text";
        
    container.registerInto!Book
        .factoryMethod!(Bookshelf, "getABook")(lref!Bookshelf) // Use Bookshelf's method getABook to create the Book.
        .callback(
            (Locator!() loc, Book book) { // Use it, when object is required to be configured in way that is not possible to do by means of library annotations.
                Page[] pages;
                foreach (i; 0 .. 99) {
                    import std.conv;
                    
                    pages ~= loc.locate!Page;
                    pages[$ - 1].text("Some text on page " ~ i.to!string);
                }
                
                book.pages(pages);
            }
        );

    container.instantiate(); // prepare container to serve objects in it (instantiates them, and performs other things).
    
    assert(container.locate!Bookshelf !is null); // Check if instantiated
    assert(container.locate!Color == Color(200, 201, 202)); // Checking if Color was properly set.
    assert(container.locate!Size == Size(295, 210));
    assert(container.locate!Paper("page.paper").quality == container.locate!(Paper.Quality)); // Checking if quality of page.paper is same as for Paper.Quality in container 
    assert(container.locate!Cover.material is container.locate!Paper); // Checking if cover material is from a hardened paper.
}
```

As seen above, nothing changes except for some register lines, like this one:
```D
container.registerInto!Color // Register Color struct as a component in container.
```
Instead of a simple register we see registerInto call. This is due to ambiguity
risen if we would use only register. Since ApplicationContainer is a composite
container, we should allow somehow to specify which of three containers would 
manage added component. To do so, register methods do allow additional argument
to be passed that is a path to container separated by dots (composite container
can consist of several levels of hierarchy) just like in example below:
```D
container.registerInto!Page("prototype") // store component in Prototype container
    .autowire!"size"
    .set!"paper"("page.paper".lref) // set paper to an object located in container.
    .autowire!"textColor"
    .autowire!"foreground"
    .autowire!"text";
```
We show that Page should be stored in prototype container instead of default one.
When we add a component to composite container without specifying where it should
be, it is implicitly defined that a "singleton" sub-container exists, and there it should
be stored.
The ambiguity mentioned before, is due to this additional argument passed to register
(path to sub-container). Just remember, use register to add a component to container with
some custom id, while registerInto with a default one.

So, what about annotation based configuration for composite containers?
It works the same as for simple containers, with some additional conventions
and annotations.
Since a composite container consists of multiple ones, there is an annotation that does
allow to specify in which container should reside component. It is:

-  @contained -> specifies in which container should be component stored )

As with register methods, when container is not specified, same convention applies to
annotation based configuration. By not defining @contained annotation on component,
it is implicitly defined that a sub-container by identity "singleton" is present in composite
and is available for storage. In both versions, if "singleton" container does not exists
not found exception is thrown stating that singleton container is not present.

In both configuration modes, a composite container should not accept any component to be
added. If allowed to do so, it will not be treated anymore as a composite container. 

## Extending

The library was designed with intent to be easily extendable, and 
does allow two directions of extending it:

-  Container extension.
-  Factory extension.

Following subchapters will tell in detail responsibilities of each component.

### Container extending

The intent behind containers, is to have something that stores objects in
it, and manages their lifetime, as well as serving them.

The storage mechanism is not defined by library. It can be basically 
a storage in memory, or objects can be stored in exterior of application
(Mysql, Redis etc.).

Another responsibility of containers is lifetime management.
A container is responsible to keep some track, of served objects, and
upon their lifetime end, free the occupied memory. By this definition
Singleton container will keep alive objects, until the container itself
will be destroyed. Same should be valid for Prototype container.

The last responsibility of containers, is how it does serve the objects.
Different behavior can be implemented. For example singleton container
will always serve same object which is identified by some id, say "page".
Prototype container, on each serve will give a perfect copy of configured
object.

Create/implement a new container, when logic behind storing, managing lifetime,
or serving differs from the ones provided by library and cannot be done using 
them. 

### Factory extending

Factories are like blueprints, for constructable objects/structs. A container
initially does not store the actual object, but a blueprint (factory) for it,
that is used to construct a version of object. Singleton will construct an object
once and serve it during it's lifetime, while Prototype will construct an object using
factory each time it is requested to serve.

Containers, accept a factory in it's entirety. They do not provide any means for 
factory configuration. Therefore, a factory should be configured before passing it to
container, or by saving a reference to it somewhere for further configuration. In this 
way register methods, and annotation configuration works. It creates a factory, configures it
and saves it in container.

By peeking at aermicioi.aedi.factory.factory, we can see that most basic interface for a 
factory provides only two methods, first is factory which will create the object, and type
which returns typeid of object. Though it does provide minimal interface for creating an
object it does not provide any means on how to configure a factory. For factories that can
be configured another interface that extends Factory is available in
aermicioi.aedi.factory.genericfactory which is GenericFactory(T).

The GenericFactory(T) interface, splits the process of object construction in two steps:

-  Object allocation, and construction
-  Object configuration

Instances of GenericFactory are used by register methods, as well as by annotation configuration.

**Note:** T argument used as template argument for GenericFactory or further, is the type of object instantiated
by the factory.

The logic of first step itself is encapsulated in an implementation InstanceFactory(T) object.
In some way an implementation of InstanceFactory is like a foundation bluepring for Object.
The task of it is to allocate memory, and initialize object in there. Methods used to configure
objects in example above like construct, fact, autowire, encapsulate their logic into 
an implementation of InstanceFactory(T) and pass it to GenericFactory(T).

The second step consists of a set of configuration steps that are performed on object
instantiated by the first step. Each configuration step itself is encapsulated in an implementation
of PropertyConfigurer(T) interface. Methods such as set, callback, autowire, or annotations like
setter, autowire, callback encapsulate their logic into PropertyConfigurer(T) implementations
and save them into GenericFactory(T) for future call.

In cases when, there is a need of custom creation logic, in application, and it 
is possible to encapsulate it in one of steps used by GenericFactory(T) it is recomended
to encapsulate in them instead of defining a full blown implementation of Factory.
Encapsulating in one those steps will, allow easier integration with provided api.
A full blown implementation of Factory should be used, when the logic doesn't fit in
one of these steps.

The last two imporant pieces to know in this chapter are the following:

- How can a Factory detect that a dependency is located in container? 
    From examples above, we saw that lref notation can be used to denote a reference. 
    The lref notation (it's a function actually, can be seen in aermicioi.aedi.storage.locator) 
    reduces itself to a LocatorReference instance that is used by InstanceFactories and
    PropertyConfigurers to detect, arguments that should be replaced with objects from
    container. LocatorReference itself does contain the identity of referenced object in container.
- While talking about Factory extending, no mentioning of struct construction, is ever mentioned.
    This is, because containers store objects, and not structs, or other data. So how we can
    implement a step, or an entire factory for structs, and possibly other type of data (unions, etc.)?
    It's simple. Any data that is not rooted in Object class, should be wrapped by Wrapper object
    that is present in aermicioi.aedi.storage.wrapper module. GenericFactories that return a struct, actually
    return a Wrapper!T where T is some structure. Any InstanceFactories, or PropertyConfigurers that should work
    on structs, should accept a Wrapper!T object, and configure the value stored in it.
    
## Extending configurer package

By reading previous two chapters, it becomes clear that register methods, and 
annotation configuration that is used to configure containers, are not actually defined
by their interfaces. Both configuration methods are build on top of interfaces provided by
containers, and factories. In both implementations, GenericFactory is used as basis for
micro-configurations. Each implementation can be extended, and it will be discussed in topics
below.

First of all, register methods, are set of overloaded functions that accept as input following arguments:

-  storage -> an object that implements Storage!(Factory, string), and defines methods
    to set or remove Factory from it. All containers should implement it, if it
    is expected to store some data.
-  locator -> an object that implements Locator!(Object, string), that is used to 
    locate possible dependencies of registered object. All containers should implement it.
    Withouth implementing it, there is no way how library will be able to know that 
    container can serve objects.
-  identity -> identity by which to store registered object. Some overloaded versions of register, will
    set identity to be registered Type's FQN, or of one interface that it implements.
-  storageId -> path to storage, which should store registered object. This argument is used by overload set
    working on composite locators, to find storage which will store object's factory.

Upon finishing, it will return a GenericFactory(T) implementation saved in storage that is possible to 
customize further, using set, autowire, construct, and so on.

As mentioned in previous chapter, any customization, or creation logic is encapsulated in
an implementation of InstanceFactory(T) or PropertyConfigurer(T). There for to allow, a flow
like syntax, it is recommended to define a helper function of following format:
```D
GenericFactory!T helperFunction(T, Args...)(GenericFactory!T fact, Args args);
```
Which will wrap creation of InstanceFactory(T) or PropertyConfigurer(T), and add
them to fact. In such format it will integrate seamlessly, with flow syntax provided
by set, callback, autowire (which themselves are wrapper functions) etc.

Annotation interface is also possible to extend to some extent. In order to be extendable
the scanning is performed for particular annotations, but instead it will search for
annotations that implement one of following static interfaces:

-  canFactoryGenericFactory -> annotation will be used to create an implementation of GenericFactory(T)
-  canFactoryInstanceFactory -> annotation will be used to create an implementation of InstanceFactory(T)
-  canFactoryPropertyConfigurer -> annotation will be used to create an implementation of PropertyConfigurer(T)

From description, of each interface, it is clearly that annotation itselves, are not used for sole purpose of
marking object being managed by container, or by marking that it does have a InstanceFactory. They do contain
logic required to spawn those implementations. In some way, they are similar to wrapper functions used with
register functions (set, autowire, etc.).
An annotation can implement from one to all three of them, there is aproximatively no limitation 
(though beware of subtle bugs). If there is need to extend annotation api, check 
aermicioi.aedi.configurer.annotation module. Interfaces defined above are defined in that module.

## Features to be implemented

-  A way to allow, singleton objects to access objects that are in containers with a narrower scope. )
-  Support for yaml based configuration. )
-  Stable api. )
-  Usage of allocators. )
