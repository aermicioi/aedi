module aermicioi.aedi.container.deffered_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.container.decorating_mixin;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;

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
template DefferedContainer(T)
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

    @safe class DefferedContainer : InheritanceSet
    {
        private
        {
            DefferredExecutioner executioner_;
            string identity_;
            size_t depth;
        }

        public
        {

            /**
            Default constructor for DefferedContainer
            **/
            this(string identity = typeid(DefferredExecutioner).toString())
            {
                this.identity = identity;
                this.executioner = new DefferredExecutionerImpl;
            }

            this(T decorated, string identity = typeid(DefferredExecutioner).toString()) {
                this(identity);

                this.decorated = decorated;
            }

            @property
            {
                /**
                Set executioner

                Params:
                    executioner = the executioner that stores and executed deffered actions.

                Returns:
                    typeof(this)
                **/
                typeof(this) executioner(DefferredExecutioner executioner) @safe nothrow pure {
                    this.executioner_ = executioner;

                    return this;
                }

                /**
                Get executioner

                Returns:
                    DefferredExecutioner
                **/
                DefferredExecutioner executioner() @safe nothrow pure {
                    return this.executioner_;
                }

                /**
                Set identity

                Params:
                    identity = identity of executioner identified in container.

                Returns:
                    typeof(this)
                **/
                typeof(this) identity(string identity) @safe nothrow pure {
                    this.identity_ = identity;

                    return this;
                }

                /**
                Get identity

                Returns:
                    string
                **/
                string identity() @safe nothrow pure {
                    return this.identity_;
                }
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
                if (key == this.identity) {
                    return (() @trusted => cast(Object) this.executioner)();
                }

                ++this.depth;
                Object result = this.decorated.get(key);
                --this.depth;

                if (this.depth == 0) {
                    this.executioner.execute;
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
                if (key == this.identity_) {
                    return true;
                }

                return this.decorated_.has(key);
            }

            mixin ContainerMixin!(typeof(this));
        }
    }
}
