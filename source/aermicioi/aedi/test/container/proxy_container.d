module aermicioi.aedi.test.container.proxy_container;

import aermicioi.aedi.container.proxy_container;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.factory.proxy_factory;
import aermicioi.aedi.test.fixture;
import std.range;
import std.algorithm;

unittest
{
    SingletonContainer container = new SingletonContainer();
    ProxyContainerImpl!(SingletonContainer) proxyContainer = new ProxyContainerImpl!(
            SingletonContainer);
    proxyContainer.decorated = container;
    assert(proxyContainer.decorated is container);

    proxyContainer.set(new MockFactory!MockObject, "mock.object");

    assert(!proxyContainer.has("mock.object"));
    
    auto proxyFactory = new ProxyObjectWrappingFactory!MockObject(
            new ProxyFactory!MockObject("mock.object", container)
        );
    proxyContainer.set(
        proxyFactory,
        "mock.object"
    );

    proxyContainer.link("mock.object", "mockable");
    assert(proxyContainer.has("mockable"));
    assert(proxyContainer.resolve("mockable") == "mock.object");
    
    proxyContainer.unlink("mockable");
    assert(!proxyContainer.has("mockable"));

    assert(proxyContainer.getFactory("mock.object") !is null);
    assert(proxyContainer.getFactories.count > 0);

    assert((cast(Proxy!MockObject) proxyContainer.get("mock.object")) !is null);

    proxyContainer.remove("mock.object");
    assert(!proxyContainer.has("mock.object"));
}
