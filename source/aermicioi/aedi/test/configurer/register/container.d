module aermicioi.aedi.test.configurer.register.container;

import aermicioi.aedi.configurer.register.container;
import aermicioi.aedi.container;

unittest
{
    auto container = singleton();

    assert(typeid(container) is typeid(SingletonContainer));
}

unittest
{
    auto container = prototype();

    assert(typeid(container) is typeid(PrototypeContainer));
}

unittest
{
    auto container = values();

    assert(typeid(container) is typeid(ValueContainer));
}

unittest
{
    auto container = switchable(values());

    assert(typeid(container) is typeid(SwitchableContainer!(ValueContainer)));
}

unittest
{
    auto container = subscribable(values());

    assert(typeid(container) is typeid(SubscribableContainer!ValueContainer));
}

unittest
{
    auto container = typed(singleton());

    assert(typeid(container) is typeid(TypeBasedContainer!SingletonContainer));
}

unittest
{
    auto container = aliasing(values());

    assert(typeid(container) is typeid(AliasingContainer!ValueContainer));
}

unittest
{
    auto container = container(values(), values());

    assert(typeid(container) is typeid(TupleContainer!(ValueContainer, ValueContainer)));
}

unittest
{
    auto container = aggregate(values(), "first.one", values(), "second.one");

    assert(typeid(container) is typeid(AggregateContainer));
}