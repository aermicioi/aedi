module aermicioi.aedi.factory.deferring_factory;

import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.factory.decorating_factory : DecoratableGenericFactory;
import aermicioi.aedi.util.range : exceptions, filterByInterface;
import aermicioi.aedi.util.typecons : AllArgsConstructor, ArgsConstructor;
import aermicioi.aedi.exception.circular_reference_exception : CircularReferenceException;
import aermicioi.aedi.exception.di_exception : AediException;

/**
Context for configuration actions that were delayed. Automatically will run them once the original component requested is fetched back.
**/
@safe class DeferralContext
{

    private
    {

        /**
        A list of deffered configuration actions.
        **/
        void delegate() @safe[] deferred;

        /**
        Amount of nested requests for components. Used to track when deffered actions are required to run.
        **/
        size_t requests;
    }

    public
    {
        @property bool pending() inout {
            import std.range : empty;

            return requests == 0 && !deferred.empty;
        }

        void track()
        {
            ++this.requests;
        }

        void release()
        in(requests > 0, "Cannot decrease component request count since it is already at 0.")
        {
            --this.requests;
        }

        void execute()
        in (requests == 0, "Cannot execute deferred actions while construction of components involved in circular dependency chain is in progress.") {
            import std.algorithm : reverse;
            auto pending = this.deferred.reverse;
            deferred = null;

            foreach (action; pending)
            {
                action();
            }
        }

        typeof(this) register(void delegate() @safe deferred)
        {
            this.deferred ~= deferred;

            return this;
        }
    }
}

@safe class DeferringFactory(T) : DecoratableGenericFactory!T
{

    this(
        GenericFactory!T decorated,
        DeferralContext context,
    ) {
        this.decorated = decorated;
        this.context = context;
    }

    private DeferralContext context;

    public
    {
        /**
		Instantiates something of type T.

		Returns:
			T instantiated component of type T.
		**/
        override T factory() @safe {
            this.context.track;
            scope(exit) this.context.release;
            return super.factory();
        }

        /**
        Adds an configurer to the PropertyConfigurersAware.

        Params:
        	configurer = a configurer that will be invoked after factory of an object.

    	Returns:
    		The PropertyConfigurersAware instance
        **/
        override GenericFactory!T addPropertyConfigurer(PropertyConfigurer!T configurer) @safe
        {
            super.addPropertyConfigurer(new DeferringPropertyConfigurer!T(configurer, this.context));

            return this;
        }
    }
}

@safe class DeferringPropertyConfigurer(T) : PropertyConfigurer!T, Decorator!(PropertyConfigurer!T) {
    import aermicioi.aedi.storage.locator : Locator;
    mixin MutableDecoratorMixin!(PropertyConfigurer!T);
    private DeferralContext context;

    this (
        PropertyConfigurer!T configurer,
        DeferralContext context
    ) {
        this.decorated = configurer;
        this.context = context;
    }

    public {

        /**
        Accepts a reference to an object that is to be configured by the configurer.

        Params:
        	object = An object of type T, that will be configured
        **/
        void configure(ref T object) @safe {
            try {
                this.decorated.configure(object);
            } catch (AediException e) {
                if (context !is null) {
                    foreach (CircularReferenceException exception; e.exceptions.filterByInterface!CircularReferenceException) {
                        T closure = object;
                        context.register(() => this.decorated.configure(closure));
                    }
                }
            }
        }

        /**
		Set a locator to object.

		Params:
			locator = the locator that is set to oject.

		Returns:
			LocatorAware.
		**/
		@property typeof(this) locator(Locator!() locator) @safe nothrow {
            this.decorated.locator = locator;

            return this;
        }
    }
}