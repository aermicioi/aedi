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
	aermicioi
**/
module aermicioi.aedi.container.aggregate_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.util.typecons : Pair, pair;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.util.range;
import std.range.interfaces;
import std.range : chain;
import std.algorithm : filter, map;

/**
Aggregate container, that delegates the task of locating to containers
managed by it.

**/
@safe class AggregateContainer : Container, Storage!(Container, string), AggregateLocator!(Object, string) {

    private {
        alias Entry = Pair!(Container, string);

        Entry[] containers;
    }

    public {

        /**
        Set a container into aggregate container

        Set a container into aggregate container
        Description

        Params:
        	container = container that is added to aggregate container
        	identity = identity by which container is identified in aggregate container

        Returns:
        	AggregateContainer
        **/
        AggregateContainer set(Container container, string identity) {
        	this.containers ~= Entry(container, identity);

        	return this;
        }

        /**
        Remove a container from aggregate container.

        Remove a container from aggregate container.

        Params:
        	identity = identity of container to be removed

        Returns:
        	AggregateContainer
        **/
        AggregateContainer remove(string identity) {
            import std.array : array;
        	this.containers = this.containers.filter!(entry => entry.key != identity).array;

        	return this;
        }

        /**
        Get a container, or an object that is contained by managed containers.

        Get a container, or an object that is contained by managed containers.

        Params:
        	identity = identity of object that is to be supplied.

        Throws:
        	NotFoundException when no requested object by identity is present in container

        Returns:
        	Object the object contained in one of containers or a container itself.
        **/
        Object get(string identity) {
            foreach (entry; this.containers.filter!(entry => entry.key == identity)) {
                Object container = (() scope @trusted => cast(Object) entry.value)();

                if (container !is null) {
                    return container;
                }
            }

            foreach (container; this.containers.map!(entry => entry.value)) {
                foreach (type; typeid(container).inheritance.chain(
                    typeid((() @trusted => cast(Object) container)()).inheritance)
                ) {
                    if (type.name == identity) {
                        return (() scope @trusted => cast(Object) container)();
                    }
                }
            }

        	foreach (container; this.containers.map!(entry => entry.value)) {
        	    if (container.has(identity)) {
        	        return container.get(identity);
        	    }
        	}

        	throw new NotFoundException("Component ${identity} not found.", identity);
        }

        /**
        Check if an object is present in one of containers, or it is a container itself.

        Check if an object is present in one of containers, or it is a container itself.

        Params:
        	identity = identity of object to be checked

        Returns:
        	bool true if exists, false otherwise
        **/
        bool has(in string identity) inout {
            foreach (entry; this.containers) {
                if (entry.key == identity) {
                    return true;
                }
            }

            foreach (entry; this.containers) {
                foreach (type; typeid(entry.value).inheritance.chain(
                    typeid((() @trusted => cast(Object) entry.value)()).inheritance)
                ) {
                    if (type.name == identity) {
                        return true;
                    }
                }
            }

            foreach (entry; this.containers) {
                if (entry.value.has(identity)) {
                    return true;
                }
            }

            return false;
        }

        /**
        Finalize all unfinished initialization work in containers.

        Finalize all unfinished initialization work in containers.

        Returns:
        	AggregateContainer
        **/
        AggregateContainer instantiate() {

            foreach (container; this.containers.map!(entry => entry.value)) {
                container.instantiate;
            }

            return this;
        }

        /**
        Destruct all managed components.

        Destruct all managed components. The method denotes the end of container lifetime, and therefore destruction of all managed components
        by it.
        **/
        AggregateContainer terminate() {
            foreach (container; this.containers.map!(entry => entry.value)) {
                container.terminate;
            }

            return this;
        }

        /**
        Get a specific container.

        Params:
            identity = the container identity.
        **/
        Locator!(Object, string) getLocator(string identity) {

            return this.containers.filter!(entry => entry.key == identity).front.value;
        }

        /**
        Get all containers in aggregate container

        Returns:
        	InputRange!(Tuple!(Locator!(Object, string), string)) a range of container => identity
        **/
        InputRange!(Pair!(Locator!(), string)) getLocators() {
            import std.algorithm : map;

            return this.containers.map!(entry => Pair!(Locator!(), string)(entry.value, entry.key)).inputRangeObject;
        }

        /**
        Check if aggregate container contains a specific container.

        Params:
        	key = the identity of container in aggregate container
        **/
        bool hasLocator(string identity) inout {

            foreach (entry; this.containers) {
                if (entry.key == identity) {
                    return true;
                }
            }

            return false;
        }
    }
}