/**
Contains a specific implementation of generic factory used solely in conjunction
with register api.

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
module aermicioi.aedi.configurer.register.configuration_context_factory;

import aermicioi.aedi.factory.decorating_factory;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.storage.storage;

package {

    /**
    A decorator over generic factory, that sole purpose is to contain
    additional metadata usable for register api primitives.
    **/
    @safe class ConfigurationContextFactory(T) : DecoratableGenericFactory!T {

        private {
            Storage!(ObjectFactory, string) storage_;
            ObjectFactory wrapper_;
            GenericFactory!T decorated_;
            string identity_;
            string storageIdentity_;
        }

        public {
            @property {
            	ConfigurationContextFactory!T storage(Storage!(ObjectFactory, string) storage) @safe nothrow {
            		this.storage_ = storage;

            		return this;
            	}

            	Storage!(ObjectFactory, string) storage() @safe nothrow {
            		return this.storage_;
            	}

            	ConfigurationContextFactory!T identity(string identity) @safe nothrow {
            		this.identity_ = identity;

            		return this;
            	}

            	string identity() @safe nothrow {
            		return this.identity_;
            	}

            	ConfigurationContextFactory!T storageIdentity(string storageIdentity) @safe nothrow {
            		this.storageIdentity_ = storageIdentity;

            		return this;
            	}

            	string storageIdentity() @safe nothrow {
            		return this.storageIdentity_;
            	}

            	ConfigurationContextFactory!T wrapper(ObjectFactory wrapper) @safe nothrow {
            		this.wrapper_ = wrapper;

            		return this;
            	}

            	ObjectFactory wrapper() @safe nothrow {
            		return this.wrapper_;
            	}
            }
        }
    }
}