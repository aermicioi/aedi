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
module aermicioi.aedi.configurer.register.context;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.wrapping_factory;
import std.traits;

import aermicioi.aedi.configurer.register.generic_factory_metadata_decorator;

/**
A component registration interface for storage.

Registration context registers components into storage,
and uses a locator as a source of dependencies for components.

Params:
	ObjectWrappingFactory = factory used to wrap components that are not
	derived from Object.
**/
struct RegistrationContext(
    alias ObjectWrappingFactory = WrappingFactory
) {
    public {
        
        /**
        Storage into which to store components;
        **/
        Storage!(ObjectFactory, string) storage;
        
        /**
        Locator used for fetching components dependencies;
        **/
        Locator!(Object, string) locator;
        
        this(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator) {
            this.storage = storage;
            this.locator = locator;
        }
        
        /**
        Register a component of type T by identity, type, or interface it implements.
        
        Register a component of type T by identity, type, or interface it implements.
        
        Params:
            Interface = interface of registered component that it implements
        	T = type of registered component
        	identity = identity by which component is stored in storage
        
        Returns:
        	GenericFactory!T factory for component for further configuration
        **/
        MetadataDecoratedGenericFactory!T register(T)(string identity) {
            MetadataDecoratedGenericFactory!T factory = new MetadataDecoratedGenericFactory!T();
            
            GenericFactoryImpl!T implementation = new GenericFactoryImpl!T(locator);
            ObjectWrappingFactory!(GenericFactory!T) wrapper = new ObjectWrappingFactory!(GenericFactory!T)(implementation);
            
            factory.decorated = implementation;
            factory.wrapper = wrapper;
            factory.locator = locator;
            factory.storage = storage;
            factory.identity = identity;
            
            storage.set(wrapper, identity);
            return factory;
        }
        
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(T)() {
            return register!T(fullyQualifiedName!T);
        }
        
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(Interface, T : Interface)()
            if (!is(T == Interface)) {
            return register!T(fullyQualifiedName!Interface);
        }
        
        /**
        Register a component of type T by identity, type, or interface it implements with a default value.
        
        Register a component of type T by identity, type, or interface it implements with a default value.
        
        Params:
            Interface = interface of registered component that it implements
        	T = type of registered component
        	identity = identity by which component is stored in storage
        	value = initial value of component;
        
        Returns:
        	GenericFactory!T factory for component for further configuration
        **/
        MetadataDecoratedGenericFactory!T register(T)(auto ref T value, string identity) {
            import aermicioi.aedi.configurer.register.factory_configurer;
            
            MetadataDecoratedGenericFactory!T factory = register!T(identity);
            
            factory.value(value);
            
            return factory;
        }
        
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(T)(auto ref T value)
            if (!is(T == string)) {
            
            return register(value, fullyQualifiedName!T);
        }
            
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(Interface, T : Interface)(auto ref T value)
            if (!is(T == Interface)) {
            
            return register(value, fullyQualifiedName!Interface);
        }
    }
}

/**
Start registering components using a storage and a locator.

Start registering components using a storage and a locator.

Params:
	storage = store registered components into it.
	locator = locator of dependencies for registered components

Returns:
	RegistrationContext context with registration interface used to register components.
**/
RegistrationContext!ObjectWrappingFactory configure(alias ObjectWrappingFactory = WrappingFactory)(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator) {
    return RegistrationContext!ObjectWrappingFactory(storage, locator);
}

/**
ditto
**/
RegistrationContext!ObjectWrappingFactory configure(alias ObjectWrappingFactory = WrappingFactory)(Locator!(Object, string) locator, Storage!(ObjectFactory, string) storage) {
    return RegistrationContext!ObjectWrappingFactory(storage, locator);
}

/**
Start registering components using a container.

Start registering components using a container.

Params:
	container = storage and locator of components.

Returns:
	RegistrationContext context with registration interface used to register components.
**/
RegistrationContext!ObjectWrappingFactory configure(T, alias ObjectWrappingFactory = WrappingFactory)(T container)
    if (is(T : Storage!(ObjectFactory, string)) && is(T : Locator!(Object, string))) {
    
    return configure(cast(Locator!(Object, string)) container, container);
}

/**
Start registering components using a storage and a locator.

Start registering components using a storage and a locator.

Params:
	storage = identity of a storage located in locator used by registration context to store components.
	locator = locator of dependencies for registered components

Returns:
	RegistrationContext context with registration interface used to register components.
**/
RegistrationContext!ObjectWrappingFactory configure(alias ObjectWrappingFactory = WrappingFactory)(Locator!(Object, string) locator, string storage) {
    return configure!ObjectWrappingFactory(locator, locator.locate!(Storage!(ObjectFactory, string))(storage));
}

/**
Use locator or storage as basis for registering components.

Use locator or storage as basis for registering components.

Params:
    registrationContext = context for which to set new configured storage, or used locator
	storage = store registered components into it.
	locator = locator of dependencies for registered components

Returns:
	RegistrationContext context with registration interface used to register components.
**/
Context along(Context : RegistrationContext!T, alias T)(Context registrationContext, Storage!(ObjectFactory, string) storage) {
    registrationContext.storage = storage;
    
    return registrationContext;
}

/**
ditto
**/
Context along(Context : RegistrationContext!T, alias T)(Context registrationContext, Locator!(Object, string) locator) {
    registrationContext.locator = locator;
    
    return registrationContext;
}

/**
Use locator or storage as basis for registering components.

Use locator or storage as basis for registering components.

Params:
    registrationContext = context for which to set new configured storage, or used locator
	storage = identity of a storage located in locator that should be used by registrationContext to store components.
	locator = locator of dependencies for registered components

Returns:
	RegistrationContext context with registration interface used to register components.
**/
Context along(Context : RegistrationContext!T, alias T)(Context registrationContext, string storage) {
    registrationContext.storage = registrationContext.locator.locate!(Storage!(ObjectFactory, string))(storage);
    
    return registrationContext;
}

/**
A registration interface for components already created.

Value registration context, provides a nice registration
api over Object containers, to store already instantiated
components into container.
**/
struct ValueRegistrationContext {
    
    public {
        /**
        Storage for already instantiated components.
        **/
        Storage!(Object, string) storage;
    
        /**
        Register a component into value container by identity, type or interface.
        
        Register a component into value container by identity, type or interface.
        
        Params:
        	value = component to be registered in container
        	identity = identity of component in container
        	T = type of component
        	Interface = interface that T component implements
        
        Returns:
        	ValueRegistrationContext
        **/
        ref ValueRegistrationContext register(T)(auto ref T value, string identity) {
            static if (is(T : Object)) {
                storage.set(value, identity);
            } else {
                import aermicioi.aedi.storage.wrapper;
                
                storage.set(new WrapperImpl!T(value), identity);
            }
            
            return this;
        }
        
        /**
        ditto
        **/
        ref ValueRegistrationContext register(T)(auto ref T value) {
            return register!T(value, fullyQualifiedName!T);
        }
        
        /**
        ditto
        **/
        ref ValueRegistrationContext register(Interface, T : Interface)(auto ref T value) {
            return register!T(value, fullyQualifiedName!Interface);
        }
    }
}

/**
Start registering instantiated components into a value container.

Start registering instantiated components into a value container.
Description

Params:
	storage = value container used to store instantiated components

Returns:
	ValueRegistrationContext context that provides register api, using storage to store registered components.
**/
ValueRegistrationContext configure(Storage!(Object, string) storage) {
    return ValueRegistrationContext(storage);
}

/**
Adds registration location information in component's factory for easier debugging.

Params:
    context = original preconfigured registration context to use as basis.
**/
struct RegistrationInfoTaggedRegistrationContext(T : RegistrationContext!Z, alias Z) {
    import aermicioi.aedi.factory.decorating_factory : RegistrationAwareDecoratingFactory;
    
    public {
        
        T context;
        
        alias context this;
        
        this(T context) {
            this.context = context;
        }
        
        /**
        Register a component of type T by identity, type, or interface it implements.
        
        Register a component of type T by identity, type, or interface it implements.
        
        Params:
            Interface = interface of registered component that it implements
        	T = type of registered component
        	identity = identity by which component is stored in storage
        
        Returns:
        	GenericFactory!T factory for component for further configuration
        **/
        MetadataDecoratedGenericFactory!T register(T, string file = __FILE__, size_t line = __LINE__)(string identity) {
            auto factory = this.context.register!T(identity);
            
            this.inject(factory, file, line);
            return factory;
        }
        
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(T, string file = __FILE__, size_t line = __LINE__)() {
            auto factory = this.context.register!T();
            
            this.inject(factory, file, line);
            return factory;
        }
        
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(Interface, T : Interface, string file = __FILE__, size_t line = __LINE__)()
            if (!is(T == Interface)) {
            auto factory = this.context.register!(Interface, T)();
            
            this.inject(factory, file, line);
            return factory;
        }
        
        /**
        Register a component of type T by identity, type, or interface it implements with a default value.
        
        Register a component of type T by identity, type, or interface it implements with a default value.
        
        Params:
            Interface = interface of registered component that it implements
        	T = type of registered component
        	identity = identity by which component is stored in storage
        	value = initial value of component;
        
        Returns:
        	GenericFactory!T factory for component for further configuration
        **/
        MetadataDecoratedGenericFactory!T register(T, string file = __FILE__, size_t line = __LINE__)(auto ref T value, string identity) {
            auto factory = this.context.register!T(value, identity);
            
            this.inject(factory, file, line);
            return factory;
        }
        
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(T, string file = __FILE__, size_t line = __LINE__)(auto ref T value)
            if (!is(T == string)) {
            auto factory = this.context.register!T(value);
            
            this.inject(factory, file, line);
            return factory;
        }
            
        /**
        ditto
        **/
        MetadataDecoratedGenericFactory!T register(Interface, T : Interface, string file = __FILE__, size_t line = __LINE__)(auto ref T value)
            if (!is(T == Interface)) {
            auto factory = this.context.register!(Interface, T)(value);
            
            this.inject(factory, file, line);
            return factory;
        }
    }
    
    private {
        void inject(T)(MetadataDecoratedGenericFactory!T factory, string file, size_t line) {
            RegistrationAwareDecoratingFactory!Object wrapper = new RegistrationAwareDecoratingFactory!Object();
            wrapper.file = file;
            wrapper.line = line;
            
            wrapper.decorated = factory.wrapper;
            factory.wrapper = wrapper;
            
            factory.storage.set(factory.wrapper, factory.identity);
        }
    }
}

/**
ditto
**/
auto withRegistrationInfo(T : RegistrationContext!Z, alias Z)(auto ref T context) {
    return RegistrationInfoTaggedRegistrationContext!T(context);
}