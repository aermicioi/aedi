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

module aermicioi.aedi.storage.locator;

import aermicioi.aedi.storage.storage;

/**
 Interface for objects that can serevr Type elements.
**/
interface Locator(Type = Object, KeyType = string) {

    public {

		/**
		Get a Type that is associated with key.

		Params:
			identity = the element id.

		Throws:
			NotFoundException in case if the element wasn't found.

		Returns:
			Type element if it is available.
		**/
        Type get(KeyType identity);

        /**
        Check if an element is present in Locator by key id.

        Note:
        	This check should be done for elements that locator actually contains, and
        	not in chained locator.
        Params:
        	identity = identity of element.

    	Returns:
    		bool true if an element by key is present in Locator.
        **/
        bool has(in KeyType identity) inout;
    }
}

/**
Exposes the list of locators contained in it.
**/
interface AggregateLocator(Type = Object, KeyType = string, LocatorKeyType = KeyType) :
    Locator!(Type, KeyType) {

    import std.range.interfaces : InputRange;
    import std.typecons : Tuple;

    public {

        /**
        Get a specific locator.

        Params:
            key = the locator identity.
        **/
        Locator!(Type, KeyType) getLocator(LocatorKeyType key);

        /**
        Get all locators in aggregate locator

        Returns:
        	InputRange!(Tuple!(Locator!(Type, KeyType), LocatorKeyType)) a range of locator => identity
        **/
        InputRange!(Tuple!(Locator!(Type, KeyType), LocatorKeyType)) getLocators();

        /**
        Check if aggregate locator contains a specific locator.

        Params:
        	key = the identity of locator in aggregate locator
        **/
        bool hasLocator(LocatorKeyType key) inout;
    }
}

/**
Exposes, and allows to set a list of containers into it.
**/
interface MutableAggregateLocator(Type = Object, KeyType = string, LocatorKeyType = KeyType) :
    AggregateLocator!(Type, KeyType, LocatorKeyType), Storage!(Locator!(Type, KeyType), LocatorKeyType) {

}

/**
Given a locator, locates an object and attempts to convert to T type.

Given a locator, locates an object and attempts to convert to T type.
When an object of T type is located, it is simply casted to T type.
When an value of T type is located, the func attempts to cast the requested object to
Wrapper!T, and will return it, instead of T directly.
In case of failure an InvalidCastException is thrown in debug environment.

Params:
	locator = the locator that contains the component with id as identity
	id = identity of object contained in locator

Throws:
	InvalidCastException in debug mode when actual type of object is not of type that is requested.

Returns:
	Object casted to desired type.
**/
@trusted auto ref locate(T : Object)(Locator!(Object, string) locator, string id) {
    import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;

    auto result = cast(T) locator.get(id);

    if (result is null) {
        throw new InvalidCastException("Requested object " ~ id ~ " is not of type " ~ typeid(T).toString());
    }

    return result;
}

/**
ditto
**/
@trusted auto ref locate(T)(Locator!(Object, string) locator, string id)
    if (is(T == interface)) {
    import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;
    import aermicioi.aedi.storage.wrapper : Wrapper, Castable;

    auto obj = locator.get(id);

    {
        auto result = cast(T) obj;

        if (result !is null) {
            return result;
        }
    }

    {
        auto result = cast(Wrapper!T) obj;

        if (result !is null) {
            return result.value;
        }
    }

    {
        auto result = cast(Castable!T) obj;

        if (result !is null) {

            return result.casted;
        }
    }

    throw new InvalidCastException("Requested object " ~ id ~ " is not of type " ~ typeid(T).toString());
}

/**
ditto
**/
@trusted auto ref locate(T)(Locator!(Object, string) locator, string id)
    if(!is(T == interface)) {
    import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;
    import aermicioi.aedi.storage.wrapper : Wrapper, Castable;

    auto obj = locator.get(id);
    {
        auto result = cast(Wrapper!T) obj;

        if (result !is null) {

            return result.value;
        }
    }

    {
        auto result = cast(Castable!T) obj;

        if (result !is null) {

            return result.casted;
        }
    }

    throw new InvalidCastException("Requested object " ~ id ~ " is not of type " ~ typeid(T).toString());
}

/**
ditto
**/
@trusted auto ref locate(T)(Locator!(Object, string) locator) {
    import aermicioi.aedi.factory.reference : name;

    return locate!T(locator, name!T);
}