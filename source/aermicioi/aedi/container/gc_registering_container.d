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
module aermicioi.aedi.container.gc_registering_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.container.decorating_mixin;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.util.traits;
import std.meta;
import std.traits;

import std.range.interfaces;
import std.typecons;

/**
Decorating container that will decorate all passed factories with gc registering factory.
This decorated will inherit following interfaces only and only if the
T also implements them:
  $(OL
      $(LI Storage!(ObjectFactory, string))
      $(LI Container)
      $(LI AliasAware!string)
  )
Decorated container must implement following interfaces:
    $(OL
        $(LI Container)
        $(LI MutableDecorator!T)
        $(LI Subscribable!ContainerInstantiationEventType)
        $(LI Decorator!Container)
    )

Params:
    T = The decorated that switchable decorated will decorate.
**/
template GcRegisteringContainer(T)
{

    /**
    Set which the switchable container will decorate for T. By default
    Locator!() and Subscribable!ContainerInstantiationEventType is included.
    **/
    alias InheritanceSet = NoDuplicates!(Filter!(
        templateOr!(
            partialSuffixed!(
                isDerived,
                Storage!(ObjectFactory, string)
            ),
            partialSuffixed!(
                isDerived,
                AliasAware!string
            ),
            partialSuffixed!(
                isDerived,
                FactoryLocator!ObjectFactory
            )
        ),
        InterfacesTuple!T),
        Container,
        MutableDecorator!T,
        Decorator!Container
    );

    class GcRegisteringContainer : InheritanceSet
    {
        private
        {
            T decorated_;
        }

        public
        {

            /**
            Default constructor for GcRegisteringContainer
            **/
            this()
            {
            }

            mixin MutableDecoratorMixin!(T);
            mixin LocatorMixin!(typeof(this));
            mixin ContainerMixin!(typeof(this));

            static if (is(T : Storage!(ObjectFactory, string)))
            {

                /**
                Set object factory

                Params:
                    element = factory for a object that is to be managed by prototype container.
                    identity = identity of factory
                Returns:
                    typeof(this)
                **/
                GcRegisteringContainer!T set(ObjectFactory element, string identity)
                {
                    decorated.set(new GcRegisteringFactoryDecorator(element), identity);

                    return this;
                }

                /**
                Remove an object factory from container.

                Params:
                    identity = identity of factory to be removed
                Returns:
                    typeof(this)
                **/
                GcRegisteringContainer!T remove(string identity)
                {
                    decorated.remove(identity);

                    return this;
                }
            }

            static if (is(T : AliasAware!string))
            {

                mixin AliasAwareMixin!(typeof(this));
            }

            static if (is(T : FactoryLocator!ObjectFactory))
            {

                mixin FactoryLocatorMixin!(typeof(this));
            }
        }
    }
}

private class GcRegisteringFactoryDecorator : Factory!Object {
    import aermicioi.aedi.storage.locator_aware;
    import aermicioi.aedi.storage.allocator_aware;

    mixin LocatorAwareMixin!GcRegisteringFactoryDecorator;
    mixin AllocatorAwareMixin!GcRegisteringFactoryDecorator;
    mixin MutableDecoratorMixin!(Factory!Object);

    public {
        this(Factory!Object decorated) {
            this.decorated = decorated;
        }

        /**
		Instantiates component of type Object.

		Returns:
			Object instantiated component.
		**/
		Object factory() {
            import core.memory;

            Object object = this.decorated.factory();
            GC.addRange(cast(void*) object, this.type.initializer.length, object.classinfo);

            return object;
        }

        /**
        Destructs a component of type T.

        Params:
            component = component that is to ve destroyed.
        **/
        void destruct(ref Object component) {
            import core.memory;
            GC.removeRange(cast(void*) component);

            this.decorated.destruct(component);
        }

		@property {

		    /**
    		Get the type info of T that is created.

    		Returns:
    			TypeInfo object of created component.
    		**/
    		TypeInfo type() {
                return this.decorated.type();
            }
		}
    }
}