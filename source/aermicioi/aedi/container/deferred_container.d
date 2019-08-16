module aermicioi.aedi.container.deferred_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.factory.deferring_factory;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.factory.reference : RuntimeReference, resolve;

import std.meta;
import std.traits;
import aermicioi.aedi.util.traits;

/**
Decorating container that executes deffered tasks after a request is served from exterior.
This decorated will inherit following interfaces only and only if the
T also implements them:
  $(OL
      $(LI Storage!(ObjectFactory, string))
      $(LI AliasAware!string)
      $(LI FactoryLocator)
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
template DeferredContainer(T)
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
        Decorator!Container
    );

    @safe class DeferredContainer : InheritanceSet
    {
        private
        {
            DeferralContext context;
            const string contextIdentity;
        }

        public
        {

            /**
            Default constructor for DefferedContainer
            **/
            this(T container)
            {
                this.decorated = container;
                context = new DeferralContext();
                contextIdentity = typeid(DeferralContext).toString();
            }

            this(T container, string contextIdentity) {
                this.decorated = container;
                context = new DeferralContext();
                this.contextIdentity = contextIdentity;
            }

            mixin MutableDecoratorMixin!T;

            static if (is(T : Storage!(Type, Id), Type, Id)) {

                mixin StorageMixin!(typeof(this));
            }

            static if (is(T : AliasAware!(X), X)) {

                mixin AliasAwareMixin!(typeof(this));
            }

            static if (is(T : FactoryLocator!(Z), Z)) {

                mixin FactoryLocatorMixin!(typeof(this));
            }

            /**
            Get object created by a factory identified by key

            Params:
                key = identity of factory
            Returns:
           	Object
            **/
            Object get(string key)
            {
                if (key == contextIdentity) {
                    return context;
                }

                Object result = this.decorated.get(key);

                if (context.pending) {
                    context.execute;
                }

                return result;
            }

            /**
            Check if an object factory for it exists in container.

            Params:
                key = identity of factory
            Returns:
                bool
            **/
            bool has(in string key) inout
            {
                if (key == this.contextIdentity) {
                    return true;
                }

                return this.decorated_.has(key);
            }

            mixin ContainerMixin!(typeof(this));
        }
    }
}
