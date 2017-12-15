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
5. Boot container, and start using registered components.
6. Finish and cleanup container.

Following code example shows the fastest way to create and use an IoC container.

```D
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

    public {
        Color color; // Car color
        Size size; // Car size
    }
}

void print(Car car) {
    "You bought a new car with following specs:".writeln;
    writeln("Size:\t", car.size;
    writeln("Color:\t", car.color);
}

void main() {
    SingletonContainer container = singleton(); // 1. Create a container.
    scope(exit) container.terminate(); // 6. Finish and cleanup container.

    with (container.configure) {

        register!Car // 2. Register an application component.
            .construct(lref!Size) // 3. Bind dependencies to it.
            .set!"color"(lref!Color);

        register!Color // 4. Repeat process for other components.
            .set!"r"(cast(ubyte) 0)
            .set!"g"(cast(ubyte) 255)
            .set!"b"(cast(ubyte) 0);

        register!Size
            .set!"width"(200UL)
            .set!"height"(150UL)
            .set!"length"(500UL);
    }

    container.instantiate(); // 5. Boot container.

    container.locate!Car.print; // 5. Start using registered components.
}
```

## Documentation

All public api documentation is available on [aermicioi.github.io/aedi/](https://aermicioi.github.io/aedi/).

For a more comprehensive understanding of how framework should be used, a set of tutorials are available on
github [wiki](https://github.com/aermicioi/aedi/wiki).