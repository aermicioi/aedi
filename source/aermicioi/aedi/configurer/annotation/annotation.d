/**
This module implements annotation based configuration of containers.

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
module aermicioi.aedi.configurer.annotation.annotation;

public import aermicioi.aedi.factory.reference : lref, anonymous;

import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.allocator_aware;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.container.container;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.reference;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.proxy_factory;
import aermicioi.aedi.exception;
import aermicioi.util.traits;

import std.traits;
import std.meta;
import std.typecons;
import std.conv : to;
import std.algorithm;
import std.experimental.allocator;

enum bool isComponentAnnotation(T) = is(T : ComponentAnnotation);
enum bool isComponentAnnotation(alias T) = isComponentAnnotation!(toType!T);

/**
Annotation used to denote an aggregate that should be stored into an container.
**/
struct ComponentAnnotation {

    /**
    Constructs a factory for aggregate of type T

    Params:
    	T = the aggregate type
    	locator = locator used to extract needed dependencies for T

    Returns:
    	GenericFactory!T for objects
    	GenericFactory!(Wrapper!T) for structs
    **/
    GenericFactory!T factory(T)(Locator!() locator) {
        return new GenericFactoryImpl!(T)(locator);
    }
}

enum bool isValueAnnotation(T) = is(T : ValueAnnotation!Value, Value);
enum bool isValueAnnotation(alias T) = isValueAnnotation!(toType!T);

/**
Notice:
beware of dragons, if used with a class instance, the value could be destroyed by container that manages it.
**/
struct ValueAnnotation(Value) {

    Value value;
}

ValueAnnotation!T value(T)(T value) {
    return ValueAnnotation!T(value);
}

enum bool isAllocatorAnnotation(T) = is(T : AllocatorAnnotation!X, X);
enum bool isAllocatorAnnotation(alias T) = isAllocatorAnnotation!(toType!T);

struct AllocatorAnnotation(T = IAllocator) {

    T allocator;

    /**
    Get iallocator

    Returns:
        IAllocator
    **/
    IAllocator iallocator() {
        return this.allocator.allocatorObject;
    }
}

AllocatorAnnotation!T allocator(T)(T allocator) {
    return AllocatorAnnotation!T(allocator);
}

/**
ditto
**/
alias component = ComponentAnnotation;

enum bool isConstructorAnnotation(T) = is(T : ConstructorAnnotation!Z, Z...);
enum bool isConstructorAnnotation(alias T) = isConstructorAnnotation!(toType!T);
/**
Annotation used to mark a constructor to be used for aggregate instantiation.

Params:
    Args = tuple of argument types for arguments to be passed into a constructor.
**/
struct ConstructorAnnotation(Args...) {
    Tuple!Args args;

    /**
    Constructor accepting a list of arguments, that will be passed to constructor.

    Params:
    	args = arguments passed to aggregate's constructor
    **/
    this(Args args) {
        this.args = args;
    }
}

/**
ditto
**/
auto constructor(Args...)(Args args) {
    return ConstructorAnnotation!Args(args);
}

enum bool isSetterAnnotation(T) = is(T : SetterAnnotation!Z, Z...);
enum bool isSetterAnnotation(alias T) = isSetterAnnotation!(toType!T);
/**
Annotation used to mark a member to be called or set (in case of fields), with args passed to setter.

Note: if an overloaded method is annotated with Setter, the method from overload set that matches argument list in Setter annotation
will be called.

Params:
    Args = the argument types of arguments passed to method
**/
struct SetterAnnotation(Args...) {
    Tuple!Args args;

    /**
    Constructor accepting a list of arguments, that will be passed to method, or set to a field.

    Params:
    	args = arguments passed to aggregate's constructor
    **/
    this(Args args) {
        this.args = args;
    }
}

/**
ditto
**/
auto setter(Args...)(Args args) {
    return SetterAnnotation!Args(args);
}

enum bool isCallbackFactoryAnnotation(T) = is(T : CallbackFactoryAnnotation!Z, Z...);
enum bool isCallbackFactoryAnnotation(alias T) = isCallbackFactoryAnnotation!(toType!T);
/**
Annotation that specifies a delegate to be used to instantiate aggregate.

Params:
	Z = the type of aggregate that will be returned by the delegate
	Args = type tuple of args that can be passed to delegate.
**/
struct CallbackFactoryAnnotation(Z, Dg, Args...)
    if ((is(Dg == Z delegate (IAllocator, Locator!(), Args)) || is(Dg == Z function (IAllocator, Locator!(), Args)))) {
    Tuple!Args args;
    Dg dg;

    /**
    Constructor accepting a factory delegate, and it's arguments.

    Params:
    	dg = delegate that will factory an aggregate
    	args = list of arguments passed to delegate.
    **/
    this(Dg dg, ref Args args) {
        this.dg = dg;
        this.args = tuple(args);
    }
}

/**
ditto
**/
auto fact(T, Args...)(T delegate(IAllocator, Locator!(), Args) dg, Args args) {
    return CallbackFactoryAnnotation!(T, T delegate(IAllocator, Locator!(), Args), Args)(dg, args);
}

/**
ditto
**/
auto fact(T, Args...)(T function(IAllocator, Locator!(), Args) dg, Args args) {
    return CallbackFactoryAnnotation!(T, T function(IAllocator, Locator!(), Args), Args)(dg, args);
}

enum bool isCallbackConfigurerAnnotation(T) = is(T : CallbackConfigurerAnnotation!Z, Z...);
enum bool isCallbackConfigurerAnnotation(alias T) = isCallbackConfigurerAnnotation!(toType!T);
/**
Annotation that specifies a delegate to be used to configure aggregate somehow.

Params:
	Z = the type of aggregate that will be returned by the delegate
	Args = type tuple of args that can be passed to delegate.
**/
struct CallbackConfigurerAnnotation(Z, Dg, Args...)
    if (
        is(Dg == void delegate (Locator!(), Z, Args)) ||
        is(Dg == void function (Locator!(), Z, Args)) ||
        is(Dg == void delegate (Locator!(), ref Z, Args)) ||
        is(Dg == void function (Locator!(), ref Z, Args))
    ){
    Tuple!Args args;
    Dg dg;

    /**
    Constructor accepting a configurer delegate, and it's arguments.

    Params:
    	dg = delegate that will be used to configure an aggregate
    	args = list of arguments passed to delegate.
    **/
    this(Dg dg, ref Args args) {
        this.dg = dg;
        this.args = tuple(args);
    }
}

/**
ditto
**/
auto callback(T, Args...)(void delegate (Locator!(), ref T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void delegate (Locator!(), ref T, Args), Args)(dg, args);
}

/**
ditto
**/
auto callback(T, Args...)(void function (Locator!(), ref T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void function (Locator!(), ref T, Args), Args)(dg, args);
}

/**
ditto
**/
auto callback(T, Args...)(void delegate (Locator!(), T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void delegate (Locator!(), T, Args), Args)(dg, args);
}

/**
ditto
**/
auto callback(T, Args...)(void function (Locator!(), T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void function (Locator!(), T, Args), Args)(dg, args);
}

enum bool isAutowiredAnnotation(T) = is(T : AutowiredAnnotation);
enum bool isAutowiredAnnotation(alias T) = isAutowiredAnnotation!(toType!T);
/**
Annotation used to mark constructor or method for auto wiring.

Marking a method/constructor with autowired annotation will make container to call it with arguments fetched from
locator by types of them.

Note: even if a method/constructor from an overloaded set is marked with autowired annotation, the first method from overload set
will be used. Due to that autowired annotation is recommended to use on methods/constrcutors that are not overloaded.

**/
struct AutowiredAnnotation {

}

/**
ditto
**/
alias autowired = AutowiredAnnotation;

enum bool isQualifierAnnotation(T) = is(T : QualifierAnnotation);
enum bool isQualifierAnnotation(alias T) = isQualifierAnnotation!(toType!T);
/**
An annotation used to provide custom identity for an object in container.
**/
struct QualifierAnnotation {
    string id;
}

/**
An annotation used to provide custom identity for an object in container.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    id = identity of object in container
**/
auto qualifier(string id) {
    return QualifierAnnotation(id);
}

/**
ditto
**/
QualifierAnnotation qualifier(string id)() {
    return QualifierAnnotation(id);
}

/**
An annotation used to provide custom identity for an object in container by some interface.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    I = identity of object in container
**/
QualifierAnnotation qualifier(I)() {
    return QualifierAnnotation(name!I);
}

enum bool isContainedAnnotation(T) = is(T : ContainedAnnotation);
enum bool isContainedAnnotation(alias T) = isContainedAnnotation!(toType!T);
/**
When objects are registered into an aggregate container, this annotation marks in which sub-container it is required to store.
**/
struct ContainedAnnotation {
    string id;
}

/**
When objects are registered into an aggregate container, this annotation marks in which sub-container it is required to store.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    id = identity of container where to store the object.
**/
auto contained(string id) {
    return ContainedAnnotation(id);
}


enum bool isDefaultDestructor(T) = is(T) && is(T == DefaultDestructor);
enum bool isDefaultDestructor(alias T) = is(typeof(T));

struct DefaultDestructor {

}

DefaultDestructor defaultDestructor() {
    return DefaultDestructor();
}

enum bool isCallbackDestructor(T) = is(T) && is(T == DefaultDestructor);
enum bool isCallbackDestructor(alias T) = is(typeof(T));

struct CallbackDestructor(T, Dg : void delegate(IAllocator, ref T destructable, Args), Args...) {
    Dg dg;
    Args args;
}

CallbackDestructor callbackDestructor(T, Dg : void delegate(IAllocator, ref T destructable, Args), Args...)(Dg dg, Args args) {
    return CallbackDestructor(dg, args);
}

enum bool isDestructorMethod(T) = is(T) && is(T == DefaultDestructor);
enum bool isDestructorMethod(alias T) = is(typeof(T));

struct DestructorMethod(string method, T, Z, Args...) {
    Dg dg;
    Args args;
}

CallbackDestructor destructorMethod(string method, T, Z, Args...)(Dg dg, Args args) {
    return DestructorMethod(dg, args);
}