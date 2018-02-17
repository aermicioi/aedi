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
module aermicioi.aedi.container.tuple_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.exception.not_found_exception;
import std.range.interfaces;
import std.typecons;
import std.container;

/**
An aggregate container with knowledge of concrete types of aggregated containers.
It delegates the task of serving an object to contained containers.
**/
class TupleContainer(T...) : Container {

    public {
        /**
        List of containers that Tuple container uses.
        **/
        T containers;

        /**
        Aliasing to containers for unboxing and index based access.
        **/
        alias containers this;

        /**
        Construct tuple container with a set of aggregate containers.

        Params:
            containers = a sequence of containers
        **/
        this(T containers) {
            this.containers = containers;
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

        	foreach (container; this.containers) {
        	    if (container.has(identity)) {
        	        return container.get(identity);
        	    }
        	}

        	throw new NotFoundException("Component by id " ~ identity ~ " not found.");
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

            foreach (container; this.containers) {
                if (container.has(identity)) {
                    return true;
                }
            }

            return false;
        }

        /**
        Finalize all unfinished initialization work in containers.

        Finalize all unfinished initialization work in containers.

        Returns:
        	TupleContainer
        **/
        TupleContainer instantiate() {

            foreach (container; this.containers) {
                container.instantiate;
            }

            return this;
        }

        /**
        Destruct all managed components.

        Destruct all managed components. The method denotes the end of container lifetime, and therefore destruction of all managed components
        by it.
        **/
        Container terminate() {
            foreach (container; this.containers) {
                container.terminate;
            }

            return this;
        }
    }
}