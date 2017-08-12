module aermicioi.aedi.test.factory.proxy_factory;

import aermicioi.aedi.storage.locator : locate;
import aermicioi.aedi.factory.proxy_factory;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.test.fixture;

unittest {
    auto container = new ObjectStorage!();
    auto container2 = new ObjectStorage!();
    container.set(new MockObject(), "mock.object");
    container2.set(new MockObject(), "mock.object.the_second");
    
    auto proxyFactory = new ProxyFactory!(MockObject)("mock.object", container);
    
    assert((cast(Proxy!MockObject) proxyFactory.factory()) !is null);

    proxyFactory.factory().imethod(10, 5);
    assert(container.locate!MockObject("mock.object").property == 5);

    auto wrapper = new ProxyObjectWrappingFactory!MockObject(proxyFactory);
    wrapper.identity = "mock.object.the_second";
    wrapper.locator = container2;
    wrapper.source = container2;

    (cast(MockObject) wrapper.factory()).imethod(10, 4);
    assert(container2.locate!MockObject("mock.object.the_second").property == 6);
    assert((cast(Proxy!MockObject) wrapper.factory()) !is null);
    assert(wrapper.type is typeid(Proxy!MockObject));
    assert(wrapper.locator is container2);
    assert(wrapper.source is container2);
    assert(wrapper.identity == "mock.object.the_second");
}