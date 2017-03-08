# Aedi, a dependency injection library. 

[![Dub license](https://img.shields.io/dub/l/aedi.svg)]()
[![Travis CI](https://img.shields.io/travis/aermicioi/aedi/master.svg)](https://travis-ci.org/aermicioi/aedi)
[![Code cov](https://img.shields.io/codecov/c/github/aermicioi/aedi.svg)]()
[![Dub version](https://img.shields.io/dub/v/aedi.svg)](https://code.dlang.org/packages/aedi)
[![Dub downloads](https://img.shields.io/dub/dt/aedi.svg)](https://code.dlang.org/packages/aedi)

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

## Aim

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

## Why should it be used

1.  Decouples components in your application. 
2.  Decreases hassle with application components setup (wiring and creation) 
3.  Increases code reusability (since no dependencies are created in dependent objects.) 
4.  Allows easier to test code that is dependent on other components 
5.  Eases the implementation single responsibility principle in components

### Features

1. Configuration through code or annotations.
2. Documentation: usage tutorial as well api documentation is available (check Documentation section).
3. Unittested.
4. Easy to extend up to your needs (check extending tutorials in wiki).

## When should it be used

1.  When an application has to be highly configurable. 
2.  When an application has a high number of interdependent components. 
3.  When doing unit testing of highly dependent components. 
    
## How should it be used

### Install

Add Aedi library as a dependency to a dub project:

Json configuration:

```json
"aedi": "~>0.2.0"
```

SDL configuration:
```sdl
dependency "aedi" version="~>0.2.0"
```

### Quickstart

1. Create a container
2. Register an application component. Any data (struct, object, union, etc) is treated as application component.
3. Write a wiring configuration
4. Repeat process for other components.
5. Boot container

First of all a container should be created:

```D
    SingletonContainer container = new SingletonContainer;
```

Container is responsible for storing, and managing application's components.

Next, register component into container:

```D
    container.register!Color
```

Component is registered by calling .register method on container with type of component.
Note, that in example we do not end the statement. That's because component should be 
configured next:

```D
        .set!"r"(cast(ubyte) 250)
        .set!"g"(cast(ubyte) 210)
        .set!"b"(cast(ubyte) 255);
```

.set method configures component properties to specific values (setter injection in other words).
Note the example ends in `;` which means that it's end of statement and Color registration/configuration.
Once components are registered and configured, container needs to be booted (instantiated):

```D
    container.instantiate();
```

Container during boot operation, will do various stuff, including creation and wiring of components
between them. It's important to call `container.instantiate()` after all application's components 
have been registered into container, otherwise it is not guaranteed that application will work correctly.

Once container is booted, components in it are available for use. 
To fetch it use locate method like in following example:

```D
container.locate!Color.writeln;
```

Run example from [getting started](https://github.com/aermicioi/aedi/wiki/Getting-started) tutorial:

```D
Color is:	Color(250, 210, 255)
```

## Documentation

All public api documentation is available on [aermicioi.github.io/aedi/](https://aermicioi.github.io/aedi/).

For a more comprehensive understanding of how library should be used, a set of tutorials are available on
github [wiki](https://github.com/aermicioi/aedi/wiki).