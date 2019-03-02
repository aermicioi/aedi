module aermicioi.aedi.test.configurer.annotation.component_scan;

import aermicioi.aedi.configurer.annotation.annotation;
import aermicioi.aedi.configurer.annotation.component_scan;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.test.fixture;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.exception;

@component
class MockComponent {

}

@component
class AnotherMockComponent {

}

class MockNotComponent {

}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    assert(GenericFactoryPolicy.createFactory!MockComponent(storage) !is null);
    assert(GenericFactoryPolicy.createFactory!MockNotComponent(storage) is null);
}

@fact((RCIAllocator allocator, Locator!() locator) => allocator.make!CallbackFactoryMock(10))
class CallbackFactoryMock {

    public {
        int i;

        this(int i) {
            this.i = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!CallbackFactoryMock mock = new GenericFactoryImpl!CallbackFactoryMock(storage);
    CallbackFactoryConfiguratorPolicy.configure(mock, storage);

    assert(mock.factory.i == 10);
}

@value(new ValueFactoryMock(10))
class ValueFactoryMock {

    public {
        int i;

        this(int i) {
            this.i = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!ValueFactoryMock mock = new GenericFactoryImpl!ValueFactoryMock(storage);
    ValueFactoryConfiguratorPolicy.configure(mock, storage);

    assert(mock.factory.i == 10);
}

class ConstructorFactoryMock {

    public {
        int i;

        @constructor(20)
        this(int i) {
            this.i = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!ConstructorFactoryMock mock = new GenericFactoryImpl!ConstructorFactoryMock(storage);
    ConstructorMethodConfiguratorPolicy.configureMethod!"__ctor"(mock, storage);

    assert(mock.factory.i == 20);
}

class AutowiredConstructorFactoryMock {

    public {
        int i;

        @autowired
        this(int i) {
            this.i = i;
        }
    }
}

class AutowiredByNameConstructorFactoryMock {

    public {
        int i;

        @autowired
        this(int otter) {
            this.i = otter;
        }
    }
}

class AutowiredByQualifierConstructorFactoryMock {

    public {
        int i;

        @autowired
        this(@qualifier("qualified") int i) {
            this.i = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(22), "int");
    storage.set(new WrapperImpl!int(23), "otter");
    storage.set(new WrapperImpl!int(24), "qualified");
    GenericFactory!AutowiredConstructorFactoryMock mock = new GenericFactoryImpl!AutowiredConstructorFactoryMock(storage);
    AutowiredConstructorMethodConfiguratorPolicy.configureMethod!"__ctor"(mock, storage);
    GenericFactory!AutowiredByNameConstructorFactoryMock mockByName = new GenericFactoryImpl!AutowiredByNameConstructorFactoryMock(storage);
    AutowiredConstructorMethodConfiguratorPolicy.configureMethod!"__ctor"(mockByName, storage);
    GenericFactory!AutowiredByQualifierConstructorFactoryMock mockByQualifier = new GenericFactoryImpl!AutowiredByQualifierConstructorFactoryMock(storage);
    AutowiredConstructorMethodConfiguratorPolicy.configureMethod!"__ctor"(mockByQualifier, storage);

    assert(mock.factory.i == 22);
    assert(mockByName.factory.i == 23);
    assert(mockByQualifier.factory.i == 24);
}

class SetterFieldMockFactory {

    public {
        @setter(10)
        int i;
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!SetterFieldMockFactory mock = new GenericFactoryImpl!SetterFieldMockFactory(storage);
    SetterFieldConfiguratorPolicy.configureField!"i"(mock, storage);

    assert(mock.factory.i == 10);
}

class CallbackFieldMockFactory {

    public {
        @callback(function void(Locator!(), ref CallbackFieldMockFactory f) {f.i = 111;})
        int i;
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!CallbackFieldMockFactory mock = new GenericFactoryImpl!CallbackFieldMockFactory(storage);
    CallbackFieldConfiguratorPolicy.configureField!"i"(mock, storage);

    assert(mock.factory.i == 111);
}

class AutowiredSetterFieldMockFactory {

    public {
        @autowired
        int i;
    }
}

class AutowiredByNameSetterFieldMockFactory {

    public {
        @autowired
        int otter;
    }
}

class AutowiredSetterByQualifierFieldMockFactory {

    public {
        @autowired
        @qualifier("qualified")
        int i;
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(112), "int");
    storage.set(new WrapperImpl!int(113), "otter");
    storage.set(new WrapperImpl!int(114), "qualified");
    GenericFactory!AutowiredSetterFieldMockFactory mock = new GenericFactoryImpl!AutowiredSetterFieldMockFactory(storage);
    AutowiredFieldConfiguratorPolicy.configureField!"i"(mock, storage);
    GenericFactory!AutowiredByNameSetterFieldMockFactory mockByName = new GenericFactoryImpl!AutowiredByNameSetterFieldMockFactory(storage);
    AutowiredFieldConfiguratorPolicy.configureField!"otter"(mockByName, storage);
    GenericFactory!AutowiredSetterByQualifierFieldMockFactory mockByQualifier = new GenericFactoryImpl!AutowiredSetterByQualifierFieldMockFactory(storage);
    AutowiredFieldConfiguratorPolicy.configureField!"i"(mockByQualifier, storage);

    assert(mock.factory.i == 112);
    assert(mockByName.factory.otter == 113);
    assert(mockByQualifier.factory.i == 114);
}

class SetterMethodMockFactory {

    public {
        int i_;

        @setter(113)
        @property void i(int i) {
            this.i_ = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(112), "int");
    GenericFactory!SetterMethodMockFactory mock = new GenericFactoryImpl!SetterMethodMockFactory(storage);
    SetterMethodConfiguratorPolicy.configureMethod!"i"(mock, storage);

    assert(mock.factory.i_ == 113);
}

class CallbackMethodMockFactory {

    public {
        int i_;

        @callback(function void(Locator!() locator, ref CallbackMethodMockFactory f) {f.i = 114;})
        @property void i(int i) {
            this.i_ = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(112), "int");
    GenericFactory!CallbackMethodMockFactory mock = new GenericFactoryImpl!CallbackMethodMockFactory(storage);
    CallbackMethodConfiguratorPolicy.configureMethod!"i"(mock, storage);

    assert(mock.factory.i_ == 114);
}

class AutowiredSetterMethodMockFactory {

    public {
        int i_;

        @autowired
        @property void i(int i) {
            this.i_ = i;
        }
    }
}

class AutowiredSetterByNameMethodMockFactory {

    public {
        int i_;

        @autowired
        @property void i(int otter) {
            this.i_ = otter;
        }
    }
}

class AutowiredSetterByQualifierMethodMockFactory {

    public {
        int i_;

        @autowired
        @property void i(@qualifier("qualified") int i) {
            this.i_ = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(115), "int");
    storage.set(new WrapperImpl!int(116), "otter");
    storage.set(new WrapperImpl!int(117), "qualified");
    GenericFactory!AutowiredSetterMethodMockFactory mock = new GenericFactoryImpl!AutowiredSetterMethodMockFactory(storage);
    AutowiredMethodConfiguratorPolicy.configureMethod!"i"(mock, storage);
    GenericFactory!AutowiredSetterByNameMethodMockFactory mockByName = new GenericFactoryImpl!AutowiredSetterByNameMethodMockFactory(storage);
    AutowiredMethodConfiguratorPolicy.configureMethod!"i"(mockByName, storage);
    GenericFactory!AutowiredSetterByQualifierMethodMockFactory mockByQualifier = new GenericFactoryImpl!AutowiredSetterByQualifierMethodMockFactory(storage);
    AutowiredMethodConfiguratorPolicy.configureMethod!"i"(mockByQualifier, storage);

    assert(mock.factory.i_ == 115);
    assert(mockByName.factory.i_ == 116);
    assert(mockByQualifier.factory.i_ == 117);
}

class AutowiredMethodScannerMock {

    private int doe;

    public {
        int i_;

        @autowired
        @property void i(int i) {
            this.i_ = i;
        }
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(116), "int");
    GenericFactory!AutowiredMethodScannerMock mock = new GenericFactoryImpl!AutowiredMethodScannerMock(storage);
    MethodScanningConfiguratorPolicy!(AutowiredMethodConfiguratorPolicy).configure(mock, storage);

    assert(mock.factory.i_ == 116);
}

class AutowiredFieldScannerMock {
    private int doe;

    public {
        @autowired
        int i_;
    }
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    storage.set(new WrapperImpl!int(117), "int");
    GenericFactory!AutowiredFieldScannerMock mock = new GenericFactoryImpl!AutowiredFieldScannerMock(storage);
    FieldScanningConfiguratorPolicy!(AutowiredFieldConfiguratorPolicy).configure(mock, storage);

    assert(mock.factory.i_ == 117);
}

@component
@value(new ValueComponentMock)
class ValueComponentMock {

}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();

    alias Transformer = TypeTransformer!(
        GenericFactoryPolicy,
        ValueFactoryConfiguratorPolicy
    );

    auto mock = Transformer.transform!ValueComponentMock(storage);

    assert(mock.factory !is null);
}

@component
@value(ValueComponentWithWrappingMock())
struct ValueComponentWithWrappingMock {

}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();

    alias Transformer = ObjectFactoryTransformer!(
        TypeTransformer!(
            GenericFactoryPolicy,
            ValueFactoryConfiguratorPolicy
        )
    );

    auto mock = Transformer.transform!ValueComponentWithWrappingMock(storage);

    assert(mock.factory !is null);
    assert(mock.factory.classinfo == typeid(WrapperImpl!ValueComponentWithWrappingMock));
}

@component
@value(new ValueComponentAddedMock(10))
class ValueComponentAddedMock {

    public {
        int i;

        this(int i) {
            this.i = i;
        }
    }
}

unittest {
    import std.traits;
    ObjectStorage!() locator = new ObjectStorage!();
    SingletonContainer container = new SingletonContainer();

    alias Adder =
        TypeContainerAdder!(
            ObjectFactoryTransformer!(
                TypeTransformer!(
                    GenericFactoryPolicy,
                    ValueFactoryConfiguratorPolicy
                )
            )
        );

    Adder.scan!ValueComponentAddedMock(locator, container);

    assert(container.locate!ValueComponentAddedMock !is null);
    assert(container.locate!ValueComponentAddedMock.i == 10);
}

class InnerValueComponentAddedMock {

    public {

        @component
        @value(new InnerComponentMock(20))
        static class InnerComponentMock {
            public {
                int x;

                this(int x) {
                    this.x = x;
                }
            }
        }
    }
}

unittest {
    import std.traits;
    ObjectStorage!() locator = new ObjectStorage!();
    SingletonContainer container = new SingletonContainer();

    alias Adder =
        InnerTypeContainerAdder!(
            TypeContainerAdder!(
                ObjectFactoryTransformer!(
                    TypeTransformer!(
                        GenericFactoryPolicy,
                        ValueFactoryConfiguratorPolicy
                    )
                )
            )
        );

    Adder.scan!InnerValueComponentAddedMock(locator, container);

    assert(container.locate!(InnerValueComponentAddedMock.InnerComponentMock) !is null);
    assert(container.locate!(InnerValueComponentAddedMock.InnerComponentMock).x == 20);
}

unittest {
    import std.traits;
    ObjectStorage!() locator = new ObjectStorage!();
    SingletonContainer container = new SingletonContainer();

    alias Adder =
        ModuleContainerAdder!(
            TypeContainerAdder!(
                ObjectFactoryTransformer!(
                    TypeTransformer!(
                        GenericFactoryPolicy,
                        ValueFactoryConfiguratorPolicy
                    )
                )
            )
        );

    Adder.scan!(aermicioi.aedi.test.configurer.annotation.component_scan)(locator, container);

    assert(container.locate!(ValueComponentAddedMock) !is null);
    assert(container.locate!(ValueComponentAddedMock).i == 10);
    assertThrown(container.locate!(InnerValueComponentAddedMock) !is null);
    assert(container.locate!ValueComponentMock !is null);
}

unittest {
    import std.traits;
    ObjectStorage!() locator = new ObjectStorage!();
    SingletonContainer container = new SingletonContainer();

    ContainerAdderImpl!().scan!(aermicioi.aedi.test.configurer.annotation.component_scan)(locator, container);

    assert(container.locate!(ValueComponentAddedMock) !is null);
    assert(container.locate!(ValueComponentAddedMock).i == 10);
    assertThrown(container.locate!(InnerValueComponentAddedMock) !is null);
    assert(container.locate!ValueComponentMock !is null);
}

@allocator!Mallocator()
class CustomAllocatorMock {


}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactoryImpl!CustomAllocatorMock mock = new GenericFactoryImpl!CustomAllocatorMock(storage);
    AllocatorConfiguratorPolicy.configure(mock, storage);

    assert(!mock.allocator.isNull);
}

@component
class StaticFactoryMethodCreatedMock {
    int property;

    this(int i) {
        this.property = i;
    }
}

@component
class FactoryMethodCreatedMock {
    int property;


    this(int i) {
        this.property = i;
    }
}

@component
class MethodFactoryComponent {
    int property;

    @component
    FactoryMethodCreatedMock factoryMock(int integer) {
        return new FactoryMethodCreatedMock(integer);
    }

    @component
    static StaticFactoryMethodCreatedMock factoryMockStatic() {
        return new StaticFactoryMethodCreatedMock(int.max);
    }
}

unittest {
    import std.traits : fullyQualifiedName;

    ObjectStorage!() storage = new ObjectStorage!();
    SingletonContainer container = new SingletonContainer();
    storage.set(new MethodFactoryComponent, fullyQualifiedName!MethodFactoryComponent);
    storage.set(new WrapperImpl!int(10), fullyQualifiedName!int);

    FactoryMethodContainerAdder!().scan!MethodFactoryComponent(storage, container);
    assert(container.locate!FactoryMethodCreatedMock.property == 10);
    assert(container.locate!StaticFactoryMethodCreatedMock.property == int.max);
}

unittest {
    import std.traits : fullyQualifiedName;
    import aermicioi.aedi.exception.not_found_exception : NotFoundException;
    import aermicioi.aedi.container.prototype_container : PrototypeContainer;

    ObjectStorage!() storage = new ObjectStorage!();
    SingletonContainer container = new SingletonContainer();
    PrototypeContainer prototype = new PrototypeContainer();
    scope(exit) {container.terminate; prototype.terminate;}

    storage.set(container, "container");
    storage.set(container, fullyQualifiedName!(Storage!(Factory!Object, string)));
    storage.set(container, fullyQualifiedName!SingletonContainer);
    storage.set(prototype, fullyQualifiedName!PrototypeContainer);

    scan!MockComponent(container, storage);
    assert(container.locate!MockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);

    scan!MockComponent("container", storage);
    assert(container.locate!MockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);

    scan!MockComponent(cast(Locator!()) storage);
    assert(container.locate!MockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);

    scan!MockNotComponent(container, storage);
    assertThrown!NotFoundException(container.locate!MockNotComponent);

    scan!MockNotComponent("container", storage);
    assertThrown!NotFoundException(container.locate!MockNotComponent);

    scan!MockNotComponent(cast(Locator!()) storage);
    assertThrown!NotFoundException(container.locate!MockNotComponent);

    scan!(MockComponent, AnotherMockComponent)(container, storage);
    assert(container.locate!MockComponent !is null);
    assert(container.locate!AnotherMockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);
    container.remove(fullyQualifiedName!AnotherMockComponent);

    scan!(MockComponent, AnotherMockComponent)("container", storage);
    assert(container.locate!MockComponent !is null);
    assert(container.locate!AnotherMockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);
    container.remove(fullyQualifiedName!AnotherMockComponent);

    scan!(MockComponent, AnotherMockComponent)(cast(Locator!()) storage);
    assert(container.locate!MockComponent !is null);
    assert(container.locate!AnotherMockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);
    container.remove(fullyQualifiedName!AnotherMockComponent);

    scan!(MockComponent, PrototypeContainer, AnotherMockComponent, PrototypeContainer, AnotherMockComponent, MockComponent, SingletonContainer)(cast(Locator!()) storage);
    assert(container.locate!MockComponent !is null);
    assert(container.locate!AnotherMockComponent !is null);
    assert(prototype.locate!AnotherMockComponent !is null);
    assert(prototype.locate!MockComponent !is null);
    container.remove(fullyQualifiedName!MockComponent);
    container.remove(fullyQualifiedName!AnotherMockComponent);
    prototype.remove(fullyQualifiedName!AnotherMockComponent);
    prototype.remove(fullyQualifiedName!MockComponent);
}

struct MockAnnotationConfigurer {

    static bool run;

    static void configure(T : GenericFactory!Z, Z)(T instantiator, Locator!() locator) {
        run = true;
    }
}

@MockAnnotationConfigurer()
class GenericConfigurerAnnotatedComponent {

}

unittest {
    scope(exit) MockAnnotationConfigurer.run = false;

    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactoryImpl!GenericConfigurerAnnotatedComponent mock = new GenericFactoryImpl!GenericConfigurerAnnotatedComponent(storage);

    GenericConfigurerConfiguratorPolicy.configure(mock, storage);

    assert(MockAnnotationConfigurer.run);
}

struct MockAnnotationFactory {

    static bool run;

    static GenericFactory!T createFactory(T)(Locator!() locator) {
        run = true;

        return new GenericFactoryImpl!T(locator);
    }
}

@MockAnnotationFactory()
@component
class GenericFactoryAnnotatedComponent {

}

@component
@MockAnnotationFactory()
class GenericFactoryAnnotatedComponentReversed {

}

unittest {
    scope(exit) MockAnnotationFactory.run = false;

    ObjectStorage!() storage = new ObjectStorage!();

    assert(GenericFactoryAnnotationPolicy.createFactory!GenericFactoryAnnotatedComponent(storage) !is null);

    assert(MockAnnotationFactory.run);
}

unittest {
    scope(exit) MockAnnotationFactory.run = false;

    ObjectStorage!() storage = new ObjectStorage!();

    alias FallbackFactoryPolicyImpl = FallbackFactoryPolicy!(
        GenericFactoryPolicy,
        GenericFactoryAnnotationPolicy
    );

    assert(FallbackFactoryPolicyImpl.createFactory!GenericFactoryAnnotatedComponentReversed(storage) !is null);

    assert(!MockAnnotationFactory.run);
}