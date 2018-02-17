# Aedi, a dependency injection framework.

[![Dub license](https://img.shields.io/dub/l/aedi.svg)]()
[![Travis CI](https://img.shields.io/travis/aermicioi/aedi/master.svg)](https://travis-ci.org/aermicioi/aedi)
[![Code cov](https://img.shields.io/codecov/c/github/aermicioi/aedi.svg)]()
[![Dub version](https://img.shields.io/dub/v/aedi.svg)](https://code.dlang.org/packages/aedi)
[![Dub downloads](https://img.shields.io/dub/dt/aedi.svg)](https://code.dlang.org/packages/aedi)

Aedi is a dependency injection framework. It provides a set of containers that do
IoC, and an interface to configure components (structs, objects, or any data possible in D).

## Aim

The aim of framework is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

## Features

- Configuration through code or annotations.
- Memory management based on std.experimental.allocator for components.
- Modular design.
- Documentation. Tutorials and api documentation in section below.
- Highly tested.

## Installation

Add Aedi as a dependency to a dub project:

Json configuration:

```json
"aedi": "~>0.4.0"
```

SDL configuration:

```sdl
dependency "aedi" version="~>0.4.0"
```

## Quickstart

1. Create a container.
2. Register an application component.
3. Bind dependencies to it.
4. Repeat process for other components.
5. Boot container, and use components from it.
6. Shutdown container.

Following code example shows how can a IoC container be configured and used using code or annotations:

```D
module app;

import aermicioi.aedi;
import std.stdio;

/**
A struct that should be managed by container.
**/
@component
struct Color {
    @setter(cast(ubyte) 255)
    ubyte r;

    @setter(cast(ubyte) 10)
    ubyte g;

    @setter(cast(ubyte) 10)
    ubyte b;
}

/**
Size of a car.
**/
@component // Register component using annotations
struct Size {

    @setter(200UL) // Set property to specific value
    ulong width;

    @setter(150UL)
    ulong height;

    @setter(500UL)
    ulong length;
}

/**
A class representing a car.
**/
@component
class Car {

    private {
        Color color_; // Car color
        Size size_; // Car size
    }

    public {

        @constructor(lref!Size) // Construct component using Size component from IoC container.
        this(Size size) {
            this.size_ = size;
        }

        @property {

            @autowired // Autowire property with a component from IoC container
            Car color(Color color) @safe nothrow {
            	this.color_ = color;

            	return this;
            }

            inout(Color) color() @safe nothrow pure inout {
                return this.color_;
            }

            inout(Size) size() @safe nothrow pure inout {
                return this.size_;
            }
        }
    }
}

class Mercedes : Car {
    this(Size s) {
        super(s);
    }
}

class Volkswagen : Car {
    this(Size s) {
        super(s);
    }
}

@component // Configuration component that creates components managed by container.
class Manufacturer {

    public {
        @component // Add component to container that is constructed by Manufacturer.
        Mercedes makeMercedes() {
            return new Mercedes(Size(201, 150, 501));
        }
    }
}

void print(Car car) {
    writeln("You bought a new ", car.classinfo.name, " with following specs:");
    writeln("Size:\t", car.size());
    writeln("Color:\t", car.color());
}

void main() {
    auto container = singleton(); // 1. Create container that will manage a color
    scope(exit) container.terminate(); // 6. Shutdown the container

    with (container.configure) {

        register!Volkswagen // 2. Register color into container.
            .construct(Size(100, 200, 500))
            .set!"color"("blue".lref); // 3. Bind blue color from container

        register!Color("blue")
            .set!"r"(cast(ubyte) 0)
            .set!"g"(cast(ubyte) 0)
            .set!"b"(cast(ubyte) 255);
    }

    container.scan!app; // 4. Scan app module, and register all annotated components.

    container.instantiate(); // 5. Start the IoC container.

    container.locate!Car.print; // 5. Use component from IoC container.
    container.locate!Mercedes.print;
    container.locate!Volkswagen.print;
}
```

## Documentation

All public api documentation is available on [aermicioi.github.io/aedi/](https://aermicioi.github.io/aedi/).

For a more comprehensive understanding of how framework should be used, a set of tutorials are available on
github [wiki](https://github.com/aermicioi/aedi/wiki).