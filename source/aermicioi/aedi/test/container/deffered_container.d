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
module aermicioi.aedi.test.container.deffered_container;

import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi.exception.circular_reference_exception;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.factory.wrapping_factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.container.deffered_container;
import aermicioi.aedi.factory.reference;
import aermicioi.aedi.storage.locator;

import std.algorithm;
import std.exception;

unittest {
    SingletonContainer storage = new SingletonContainer();
    DefferedContainer!SingletonContainer deffered = new DefferedContainer!SingletonContainer(storage);

    GenericFactoryImpl!CircularMockObject first = new GenericFactoryImpl!CircularMockObject(storage);
    GenericFactoryImpl!CircularMockObject second = new GenericFactoryImpl!CircularMockObject(storage);
    first.executioner = deffered.executioner;
    second.executioner = deffered.executioner;

    storage.set(new WrappingFactory!(GenericFactory!CircularMockObject)(first), "first");
    storage.set(new WrappingFactory!(GenericFactory!CircularMockObject)(second), "second");

    first.addPropertyConfigurer(fieldConfigurer!("circularDependency_", CircularMockObject)(new LocatorReference("second")));
    second.addPropertyConfigurer(fieldConfigurer!("circularDependency_", CircularMockObject)(new LocatorReference("first")));

    CircularMockObject fObject = deffered.locate!CircularMockObject("first");
    CircularMockObject sObject = deffered.locate!CircularMockObject("second");

    assert(deffered.locate!(DefferredExecutioner) is deffered.executioner);
    assert(sObject.circularDependency_ !is null);
    assert(deffered.has(name!DefferredExecutioner));
    assert(deffered.has("first"));
}