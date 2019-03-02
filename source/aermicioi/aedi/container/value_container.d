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
module aermicioi.aedi.container.value_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.exception.not_found_exception;

/**
Value container for instantiated components.

**/
@safe class ValueContainer : Container, Storage!(Object, string) {

    private {
        ObjectStorage!(Object, string) values;
    }

    public {

		/**
			Default constructor for ValueContainer
		**/
        this() {
            this.values = new ObjectStorage!(Object, string);
        }

        /**
		Save an object in ValueContainer by identity.

		Params:
			identity = identity of element in Storage.
			object = element which is to be saved in Storage.

		Return:
			ValueContainer
		**/
        ValueContainer set(Object object, string identity) {
        	this.values.set(object, identity);

        	return this;
        }

        /**
        Remove an object from ValueContainer with identity.

        Remove an object from ValueContainer with identity. If there is no element by provided identity, then no action is performed.

        Params:
        	identity = the identity of element to be removed.

    	Return:
    		ValueContainer
        **/
        ValueContainer remove(string identity) {
        	this.values.remove(identity);

        	return this;
        }

        /**
		Get an Object that is associated with identity.

		Params:
			identity = the object id.

		Throws:
			NotFoundException in case if the element wasn't found.

		Returns:
			Object element if it is available.
		**/
        Object get(string identity) {

            if (this.values.has(identity)) {
                return this.values.get(identity);
            }

            throw new NotFoundException("Component by ${identity} not found.", identity);
        }

        /**
        Check if an object is present in Locator by identity.

        Note:
        	This check should be done for elements that locator actually contains, and
        	not in chained locator.
        Params:
        	identity = identity of element.

    	Returns:
    		bool true if an element by key is present in Locator.
        **/
        bool has(in string identity) inout {

            return this.values.has(identity);
        }

		/**
        Sets up the internal state of container.

        Sets up the internal state of container (Ex, for singleton container it will spawn all objects that locator contains).
		In case of value container it does nothing.
        **/
        ValueContainer instantiate() {

           	// We do nothing since all components is already instantiated.
            return this;
        }

		/**
        Destruct all managed components.

        Destruct all managed components. The method denotes the end of container lifetime, and therefore destruction of all managed components
        by it.
        **/
        ValueContainer terminate() {

			// We do nothing since none of contained are instantiated by container.
			return this;
		}
    }
}