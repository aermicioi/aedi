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
module aermicioi.aedi.test.factory.wrapping_factory;

import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.factory.wrapping_factory;
import aermicioi.aedi.storage.wrapper;
import std.exception;
import aermicioi.aedi.exception.invalid_cast_exception;

import aermicioi.aedi.test.fixture;

unittest {
    SingletonContainer container = new SingletonContainer;
    MockValueFactory!MockStruct fact = new MockValueFactory!MockStruct;
    WrappingFactory!(MockValueFactory!MockStruct) wrapper = new WrappingFactory!(MockValueFactory!MockStruct)(fact);
    
    wrapper.locator = container;
    
    assert(wrapper.type == typeid(MockStruct));
    assert(wrapper.factory.classinfo == typeid(WrapperImpl!MockStruct));
}

unittest {
    MockValueFactory!MockStruct fact = new MockValueFactory!MockStruct;
    MockFactory!MockObject oFact = new MockFactory!MockObject;
    RuntimeWrappingFactory!(MockValueFactory!MockStruct) wrapper = new RuntimeWrappingFactory!(MockValueFactory!MockStruct)(fact);
    RuntimeWrappingFactory!(MockFactory!MockObject) oWrapper = new RuntimeWrappingFactory!(MockFactory!MockObject)(oFact);
    
    assert(wrapper.type == typeid(MockStruct));
    assert(wrapper.factory.classinfo == typeid(WrapperImpl!MockStruct));
    
    assert(oWrapper.type == typeid(MockObject));
    assert(oWrapper.factory.classinfo == typeid(MockObject));
}

unittest {
    SingletonContainer container = new SingletonContainer;
    MockValueFactory!MockStruct fact = new MockValueFactory!MockStruct;
    WrappingFactory!(MockValueFactory!MockStruct) wrapper = new WrappingFactory!(MockValueFactory!MockStruct)(fact);
    UnwrappingFactory!MockStruct unwrapper = new UnwrappingFactory!MockStruct(wrapper);
    unwrapper.locator = container;
    
    assert(unwrapper.type == typeid(MockStruct));
    assert(unwrapper.factory is MockStruct());
    
    MockFactory!MockObject wrong = new MockFactory!MockObject;

    assertThrown!InvalidCastException(unwrapper.decorated = wrong);
}

unittest {
    SingletonContainer container = new SingletonContainer;
    MockValueFactory!MockObject fact = new MockValueFactory!MockObject;
    WrappingFactory!(MockValueFactory!MockObject) wrapper = new WrappingFactory!(MockValueFactory!MockObject)(fact);
    ClassUnwrappingFactory!MockInterface unwrapper = new ClassUnwrappingFactory!MockInterface(wrapper);
    unwrapper.locator = container;
    
    assert(unwrapper.type == typeid(MockObject));
    import std.stdio;
    assert(unwrapper.factory.classinfo == typeid(MockInterface).info);
    
    MockFactory!MockObjectFactoryMethod wrong = new MockFactory!MockObjectFactoryMethod;
    assertThrown!InvalidCastException(unwrapper.decorated = wrong);
}
