# Aedi, a dependency injection framework. 

[![Dub license](https://img.shields.io/dub/l/aedi.svg)]()
[![Travis CI](https://img.shields.io/travis/aermicioi/aedi/master.svg)](https://travis-ci.org/aermicioi/aedi)
[![Code cov](https://img.shields.io/codecov/c/github/aermicioi/aedi.svg)]()
[![Dub version](https://img.shields.io/dub/v/aedi.svg)](https://code.dlang.org/packages/aedi)
[![Dub downloads](https://img.shields.io/dub/dt/aedi.svg)](https://code.dlang.org/packages/aedi)

Aedi is a dependency injection framework. It provides a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) 

## Aim

The aim of framework is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

## Features

- Configuration through code or annotations.
- Modular design.
- Documentation. Usage tutorial as well api documentation is available (check Documentation section).
- Unittested.

## Installation

Add Aedi as a dependency to a dub project:

Json configuration:

```json
"aedi": "~>0.3.0"
```

SDL configuration:

```sdl
dependency "aedi" version="~>0.3.0"
```

## Quickstart

1. Create a container
2. Register an application component. Any data (struct, object, union, etc) is treated as application component.
3. Write a wiring configuration
4. Repeat process for other components.
5. Boot container

First of all a container should be created:

```D
	// Containers are responsible for storing, and managing application's components.
    SingletonContainer container = new SingletonContainer;
```

Next, register component into container:

```D
    container.register!Color
```

Component is registered by calling `.register` method on container with type of component.
Note, that in example we do not end the statement. That's because component should be 
configured next:

```D
        .set!"r"(cast(ubyte) 250)
        .set!"g"(cast(ubyte) 210)
        .set!"b"(cast(ubyte) 255);
```

`.set` method configures component properties to specific values (setter injection in other words).
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

For a more comprehensive understanding of how framework should be used, a set of tutorials are available on
github [wiki](https://github.com/aermicioi/aedi/wiki).