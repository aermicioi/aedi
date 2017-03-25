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
module aermicioi.aedi.test.container.aggregate_container;

import aermicioi.aedi.container.application_container;
import aermicioi.aedi.container.aggregate_container;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.container.value_container;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi.storage.locator;
import std.exception;
import std.algorithm;
import std.typecons;

unittest {
    AggregateContainer container = new AggregateContainer();
    container.set(new ApplicationContainer(), "app");
    container.set(new SingletonContainer(), "singleton");
    container.set(new ApplicationContainer(), "prototype");
    container.set(new ApplicationContainer(), "parameters");
    
    assertThrown(container.get("unknown"));
    assert(container.has("singleton"));
    assert(container.has("prototype"));
    assert(container.has("parameters"));
    assert(container.has("app"));
    assert(container.hasLocator("app"));
    
    container.locate!SingletonContainer("singleton").set(new MockFactory!Object(), "mock");
    assert(container.has("mock"));
    assert(!container.has("death_lord"));
    
    container.remove("app");
    assert(!container.has("app"));
    assert(!container.hasLocator("app"));
    
    assertNotThrown(container.getLocator("singleton"));
    assert(container.getLocators().map!(
        a => a.among(
                tuple(container.locate!(Locator!())("singleton"), "singleton"),
                tuple(container.locate!(Locator!())("prototype"), "prototype"),
                tuple(container.locate!(Locator!())("parameters"), "parameters"),
        )
    ).fold!((a, b) => (a == true) && (b > 0))(true));
}