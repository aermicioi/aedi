/**
Contains factories that are used for decorational purposes like tagging with additional
 information, or wrapping result of a factory in some container.

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
module aermicioi.aedi.factory.decorating_factory;

import aermicioi.aedi.factory.factory;
import aermicioi.aedi.storage.allocator_aware;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.exception.invalid_cast_exception;
import aermicioi.aedi.exception.di_exception;

alias ObjectFactoryDecorator = Decorator!ObjectFactory;

/**
A base class for generic factory decorators that channels calls
to decorated generic factory.
**/
abstract class DecoratableGenericFactory(T) : GenericFactory!T, MutableDecorator!(GenericFactory!T) {

	mixin AllocatorAwareDecoratorMixin!(typeof(this));
	mixin DestructDecoratorMixin!(typeof(this));

    private {
        Locator!() locator_;
        GenericFactory!T decorated_;
    }

    public {
        @property {

			/**
				Set locator

				Params:
					locator = locator used to search for created object dependencies
				Returns:
					typeof(this)
			**/
        	DecoratableGenericFactory!T locator(Locator!() locator) @safe nothrow {
        		this.locator_ = locator;

        		return this;
        	}

			/**
				Get locator

				Returns:
					Locator!()
			**/
        	Locator!() locator() {
        		return this.locator_;
        	}

			/**
            Set the decorated object for decorator.

            Params:
                decorated = decorated component

            Returns:
            	this
            **/
        	DecoratableGenericFactory!T decorated(GenericFactory!T decorated) @safe nothrow {
        		this.decorated_ = decorated;

        		return this;
        	}

			/**
            Get the decorated object.

            Returns:
            	GenericFactory!T decorated object
            **/
        	GenericFactory!T decorated() @safe nothrow {
        		return this.decorated_;
        	}

			/**
            Sets the constructor of new object.

            Params:
            	factory = a factory of objects of type T.

        	Returns:
    			The GenericFactoryInstance
            **/
        	GenericFactory!T setInstanceFactory(InstanceFactory!T factory) {
        	    this.decorated.setInstanceFactory(factory);

        	    return this;
        	}

			/**
            Set destructor

            Params:
                destructor = the destructor used to destruct components created by this factory.

            Returns:
                typeof(this)
            **/
            typeof(this) setInstanceDestructor(InstanceDestructor!T destructor) {
                this.decorated.setInstanceDestructor(destructor);

                return this;
            }
        }

		/**
		Instantiates something of type T.

		Returns:
			T instantiated component of type T.
		**/
        T factory() {
            return this.decorated.factory();
        }

		/**
		Get the type info of T that is created.

		Returns:
			TypeInfo object of created object.
		**/
        TypeInfo type() {
            return this.decorated.type();
        }

		/**
        Adds an configurer to the GenericFactory.

        Params:
        	configurer = a configurer that will be invoked after factory of an object.

    	Returns:
    		The GenericFactoryInstance
        **/
        GenericFactory!T addPropertyConfigurer(PropertyConfigurer!T configurer) {
            this.decorated.addPropertyConfigurer(configurer);

            return this;
        }
    }
}

/**
An object that can be tagged with some information.
**/
interface Taggable(T) {
    import std.range.interfaces : InputRange;
    public {

        /**
        Tag object with some information

        Params:
        	tag = information that object should be tagged with.

        Returns:
        	this
        **/
        Taggable!T tag(T tag);

        /**
        Remove tagged information from object.

        Params:
        	tag = tagged information that should be removed

        Returns:
        	this
        **/
        Taggable!T untag(T tag);

        /**
        Get all tagged information from this object.

        Returns:
        	T[] a list of tags.
        **/
        T[] tags();
    }
}

/**
Decorates a factory with tagging functionality.
**/
class TaggableFactoryDecorator(T, Z) : Factory!T, Taggable!Z, Decorator!(Factory!T) {

    mixin AllocatorAwareDecoratorMixin!(typeof(this));
    mixin DestructDecoratorMixin!(typeof(this));

    private {
        Factory!T decorated_;

        Z[] tags_;
    }

    public {
        @property {

			/**
            Set the decorated object for decorator.

            Params:
                decorated = decorated component

            Returns:
            	this
            **/
        	TaggableFactoryDecorator!(T, Z) decorated(Factory!T decorated) @safe nothrow {
            	this.decorated_ = decorated;

            	return this;
            }

			/**
            Get the decorated object.

            Returns:
            	GenericFactory!T decorated object
            **/
            Factory!T decorated() @safe nothrow {
            	return this.decorated_;
            }

			/**
				Set tags

				Params:
					tags = set all tags for this factory
				Returns:
					typeof(this)
			**/
            TaggableFactoryDecorator tags(Z[] tags) @safe nothrow {
            	this.tags_ = tags;

            	return this;
            }

			/**
			Get all tagged information from this object.

			Returns:
				T[] a list of tags.
			**/
            Z[] tags() @safe nothrow {
            	return this.tags_;
            }

			/**
				Set locator

				Params:
					locator = locator used to search for created object dependencies
				Returns:
					typeof(this)
			**/
            TaggableFactoryDecorator locator(Locator!() locator) {
            	this.decorated.locator = locator;

            	return this;
            }

			/**
			Get the type info of T that is created.

			Returns:
				TypeInfo object of created object.
			**/
            TypeInfo type() {
                return this.decorated.type;
            }
        }

		/**
        Tag object with some information

        Params:
        	tag = information that object should be tagged with.

        Returns:
        	this
        **/
        TaggableFactoryDecorator tag(Z tag) {
            this.tags_ ~= tag;

            return this;
        }

		/**
        Remove tagged information from object.

        Params:
        	tag = tagged information that should be removed

        Returns:
        	this
        **/
        TaggableFactoryDecorator untag(Z tag) {
            import std.algorithm : filter;
            import std.array : array;

            this.tags_ = this.tags_.filter!(t => t != tag).array;

            return this;
        }

		/**
		Instantiates something of type T.

		Returns:
			T instantiated component of type T.
		**/
        T factory() {
            return this.decorated.factory;
        }
    }
}

/**
Interface for object that can provide some location in
code/file that is associated with some kind of registration event
**/
interface RegistrationLocation {
    public {
        @property {

        	/**
        	Get file in which registration occurred.

        	Returns:
            	string file in which a registration occured
        	**/
        	string file() @safe nothrow;

        	/**
        	Get line in file on which registration occurred.

        	Returns:
            	size_t line in file on which registration occurred.
        	**/
        	size_t line() @safe nothrow;
        }
    }
}

/**
A decorating factory, that adds component registration information
when decorated factory threws some kind of exception.
**/
class RegistrationAwareDecoratingFactory(T) : Factory!T, MutableDecorator!(Factory!T), RegistrationLocation {

	mixin AllocatorAwareDecoratorMixin!(typeof(this));

	private {

        Factory!T decorated_;

        string file_;
        size_t line_;
    }

    public {

        @property {

            /**
        	Set file in which registration occurred.

        	Params:
            	file = file in which a registration occured

        	Returns:
            	this
        	**/
        	RegistrationAwareDecoratingFactory!T file(string file) @safe nothrow {
        		this.file_ = file;

        		return this;
        	}

        	/**
        	Get file in which registration occurred.

        	Returns:
            	string file in which a registration occured
        	**/
        	string file() @safe nothrow {
        		return this.file_;
        	}

        	/**
        	Set line in file on which registration occurred.

        	Params:
            	line = line in file on which registration occurred.

        	Returns:
            	this
        	**/
        	RegistrationAwareDecoratingFactory!T line(size_t line) @safe nothrow {
        		this.line_ = line;

        		return this;
        	}

        	/**
        	Get line in file on which registration occurred.

        	Returns:
            	size_t line in file on which registration occurred.
        	**/
        	size_t line() @safe nothrow {
        		return this.line_;
        	}

        	/**
            Set the decorated factory for decorator.

            Params:
                decorated = decorated factory

            Returns:
            	this
            **/
        	RegistrationAwareDecoratingFactory!T decorated(Factory!T decorated) @safe nothrow {
        		this.decorated_ = decorated;

        		return this;
        	}

        	/**
            Get the decorated object.

            Returns:
            	Factory!T decorated factory
            **/
        	Factory!T decorated() @safe nothrow {
        		return this.decorated_;
        	}

        	/**
    		Get the type info of T that is created.

    		Returns:
    			TypeInfo object of created object.
    		**/
        	TypeInfo type() {
        	    return this.decorated.type;
        	}

        	/**
    		Set a locator for depedencies.

    		Params:
    			locator = the locator that is set to oject.

    		Returns:
    			this
    		**/
        	RegistrationAwareDecoratingFactory!T locator(Locator!() locator) {
        	    this.decorated.locator = locator;

        	    return this;
        	}
        }

        /**
		Instantiates component of type T.

		Instantiates component of type T. In case of some thrown exception,
		it will chain any thrown exception with an exception that has information
        about location where component was registered.

		Throws:
    		AediException when another exception occurred during construction

		Returns:
			T instantiated component of type T.
		**/
        T factory() {

            try {
                return this.decorated.factory;
            } catch (Exception e) {
                import std.conv;
                throw new AediException(
                    "An error occured during instantiation of component registered in file: " ~
                    this.file ~
                    " at line " ~
                    this.line.to!string,
                    this.file,
                    this.line,
                    e
                );
            }
        }

		/**
		Destructs a component of type T.

		Params:
			component = component that is to be destroyed.
		**/
		void destruct(ref T component) {

			try {

				this.decorated.destruct(component);
			} catch (Exception e) {
				import std.conv;

				throw new AediException(
                    "An error occured during destruction of component registered in file: " ~
                    this.file ~
                    " at line " ~
                    this.line.to!string,
                    this.file,
                    this.line,
                    e
                );
			}
		}

    }
}