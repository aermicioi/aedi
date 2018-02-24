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
module aermicioi.aedi.storage.locator_aware;

import aermicioi.aedi.storage.locator;

/**
Interface for objects that are aware about an locator, and accept one of them.
**/
interface LocatorAware(Type = Object, KeyType = string) {

	public {

		/**
		Set a locator to object.

		Params:
			locator = the locator that is set to oject.

		Returns:
			LocatorAware.
		**/
		@property LocatorAware locator(Locator!(Type, KeyType) locator) @safe nothrow;
	}
}

/**
Denotes a Locator that can delegate resource/object location to another Locator if it is available.

Denotes a Locator that can delegate resource/object location to another Locator if it is available.
It is used to denote that a Locator when it doesn't contain the requested object will try to search it in another
Locator if it is available, and if it doesn't contain the resource it will throw NotFoundException.

Note:
	A locator when delegates the task of resource location it should first check if locator in chain contains the
	object first, and fetch it afterwards. Such method is used to avoid an infinite loop when several DelegatingLocator are
	chained in a loop.
**/
alias DelegatingLocator = LocatorAware;

/**
Mixin implementing LocatorAware interface for a component of type T.
**/
mixin template LocatorAwareMixin(T : LocatorAware!(Z, X), Z, X) {
    mixin LocatorAwareMixin!(Z, X);
}

/**
ditto
**/
mixin template LocatorAwareMixin(Type = Object, KeyType = string) {
    import aermicioi.aedi.storage.locator;
    private {
        Locator!(Type, KeyType) locator_;
    }

    @property {
        /**
        Set locator

        Params:
            locator = the locator used somehow by locator aware component

        Returns:
            typeof(this)
        **/
        typeof(this) locator(Locator!(Type, KeyType) locator) {
            this.locator_ = locator;

            return this;
        }

        /**
        Get locator

        Returns:
            Locator!(Type, KeyType)
        **/
        inout(Locator!(Type, KeyType)) locator() @safe nothrow inout {
            return this.locator_;
        }
    }
}