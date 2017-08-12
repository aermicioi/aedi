module aermicioi.aedi.test.container.aliasing_container;

import aermicioi.aedi.container.aliasing_container;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.test.fixture;
import std.algorithm : count;

unittest
{
    SingletonContainer container = new SingletonContainer();
    AliasingContainer!(SingletonContainer) aliasingContainer = new AliasingContainer!(
            SingletonContainer);
    aliasingContainer.decorated = container;
    assert(aliasingContainer.decorated is container);

    aliasingContainer.set(new MockFactory!MockObject, "mock.object");
    assert(aliasingContainer.has("mock.object"));

    aliasingContainer.link("mock.object", "mockable");
    assert(aliasingContainer.has("mockable"));
    assert(aliasingContainer.resolve("mockable") == "mock.object");

    aliasingContainer.unlink("mockable");
    assert(!aliasingContainer.has("mockable"));

    assert(aliasingContainer.getFactory("mock.object") !is null);
    assert(aliasingContainer.getFactories.count > 0);

    assert((cast(MockObject) aliasingContainer.get("mock.object")) !is null);

    aliasingContainer.remove("mock.object");
    assert(!aliasingContainer.has("mock.object"));
}
