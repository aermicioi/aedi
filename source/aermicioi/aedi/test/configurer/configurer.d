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
module aermicioi.aedi.test.configurer.configurer;

import aermicioi.aedi.test.fixture;
import aermicioi.aedi;

unittest {
    auto instantiator = new SingletonInstantiator;
    auto parameters = new ObjectStorage!();
    
    instantiator.register!(Employee)(parameters, "employee.custom");
    instantiator.register!(Person)("person.custom");
    instantiator.register!(Company)(parameters);
    instantiator.register!(Employee)();
    instantiator.register!(Person, Employee)(parameters);
    instantiator.register!(Identifiable!ulong, Employee)();
    
    assert(instantiator.locate!(Employee)("employee.custom") !is null);
    assert(instantiator.locate!(Person)("person.custom") !is null);
    assert(instantiator.locate!(Company) !is null);
    assert(instantiator.locate!(Employee)() !is null);
    assert(instantiator.locate!Employee(name!Person) !is null);
    assert(instantiator.locate!Employee(name!(Identifiable!ulong)) !is null);
}

unittest {
    import std.typecons;
    AggregateLocatorImpl!() locator = new AggregateLocatorImpl!();
    ObjectStorage!() storage = new ObjectStorage!();
    locator.set("parameters", storage);
    
    storage.register(new Job("Salesman", 20), "salesman");
    storage.register(new Job("Trader", 20));
    storage.register!(Person)(new Employee("Zack", cast(ubyte) 20));
    locator.register(new Job("Fishkeeper", 39), "fishkeeper", "parameters");
    locator.registerInto(new Employee("Nick", cast(ubyte) 21), "parameters");
    locator.register!(Identifiable!ulong)(new Person("Kick", 22), "parameters");
    
    assert(locator.locate!Job("salesman") !is null);
    assert(locator.locate!Job !is null);
    assert(locator.locate!Employee(name!Person) !is null);
    assert(locator.locate!Job("fishkeeper") !is null);
    assert(locator.locate!Employee !is null);
    assert(locator.locate!Person(name!(Identifiable!ulong)) !is null);

}
unittest {
    import std.typecons;
    AggregateLocatorImpl!() locator = new AggregateLocatorImpl!();
    ObjectStorage!() storage = new ObjectStorage!();
    locator.set("parameters", storage);
        
    storage.register(10);
    storage.register("A simple string");
    storage.register(tuple(10, "A simple string"));
    storage.register(10, "integer");
    storage.register("A simple string", "string.of.strings");
    storage.register(tuple(10, "A simple string"), "tuple");
    
    assert(storage.locate!int == 10);
    assert(storage.locate!string == "A simple string");
    assert(storage.locate!(Tuple!(int, string)) == tuple(10, "A simple string"));
    assert(storage.locate!int("integer") == 10);
    assert(storage.locate!string("string.of.strings") == "A simple string");
    assert(storage.locate!(Tuple!(int, string))("tuple") == tuple(10, "A simple string"));
    
}
unittest {
    import std.typecons;
    AggregateLocatorImpl!() locator = new AggregateLocatorImpl!();
    ObjectStorage!() storage = new ObjectStorage!();
    locator.set("parameters", storage);
    
    locator.registerInto(cast(int) 10, "parameters");
    locator.registerInto("A simple string", "parameters");
    locator.registerInto(tuple(cast(int) 10, "A simple string"), "parameters");
    locator.register(cast(int) 10, "integer", "parameters");
    locator.register("A simple string", "string.of.strings", "parameters");
    locator.register(tuple(cast(int) 10, "A simple string"), "tuple", "parameters");
    
    assert(storage.locate!int == 10);
    assert(storage.locate!string == "A simple string");
    assert(storage.locate!(Tuple!(int, string)) == tuple(10, "A simple string"));
    assert(storage.locate!int("integer") == 10);
    assert(storage.locate!string("string.of.strings") == "A simple string");
    assert(storage.locate!(Tuple!(int, string))("tuple") == tuple(10, "A simple string"));
}

unittest {
    auto instantiator = new ApplicationInstantiator;
    SingletonInstantiator singleton = instantiator.locate!SingletonInstantiator("singleton");
    PrototypeInstantiator prototype = instantiator.locate!PrototypeInstantiator("prototype");
    ObjectStorage!() parameters = instantiator.locate!(ObjectStorage!())("parameters");
    
    instantiator.register!(Employee)(parameters, "employee.custom", "singleton");
    instantiator.register!(Person)("person.custom", "singleton");
    instantiator.registerInto!(Company)(parameters, "singleton");
    instantiator.registerInto!(Employee)("singleton");
    instantiator.register!(Person, Employee)(parameters, "singleton");
    instantiator.register!(Identifiable!ulong, Employee)("singleton");
    
    assert(singleton.locate!(Employee)("employee.custom") !is null);
    assert(singleton.locate!(Person)("person.custom") !is null);
    assert(singleton.locate!(Company) !is null);
    assert(singleton.locate!(Employee)() !is null);
    assert(singleton.locate!Employee(name!Person) !is null);
    assert(singleton.locate!Employee(name!(Identifiable!ulong)) !is null);
    
    instantiator.register!(Employee)(parameters, "employee.custom", "prototype");
    instantiator.register!(Person)("person.custom", "prototype");
    instantiator.registerInto!(Company)(parameters, "prototype");
    instantiator.registerInto!(Employee)("prototype");
    instantiator.register!(Person, Employee)(parameters, "prototype");
    instantiator.register!(Identifiable!ulong, Employee)("prototype");
    
    assert(prototype.locate!(Employee)("employee.custom") !is null);
    assert(prototype.locate!(Person)("person.custom") !is null);
    assert(prototype.locate!(Company) !is null);
    assert(prototype.locate!(Employee)() !is null);
    assert(prototype.locate!Employee(name!Person) !is null);
    assert(prototype.locate!Employee(name!(Identifiable!ulong)) !is null);
}

unittest {
    auto instantiator = new SingletonInstantiator;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);

    instantiator.componentScan!Company(parameters, "company.custom");
    instantiator.componentScan!Employee(parameters);
    instantiator.componentScan!Job();
    instantiator.componentScan!(Identifiable!ulong, Person)();
    
    instantiator.instantiate();
    
    assert(instantiator.locate!Company("company.custom") !is null);
    assert(instantiator.locate!Employee !is null);
    assert(instantiator.locate!Job() !is null);
    assert(instantiator.locate!(Person)(name!(Identifiable!ulong)) !is null);
}

unittest {
    auto first = new SingletonInstantiator;
    auto second = new SingletonInstantiator;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(Company, Employee, Job, Person, Identifiable!ulong, Person)(parameters);
    second.componentScan!(Company, Employee, Job, Person, Identifiable!ulong, Person)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job != second.locate!Employee.job);
    assert(first.locate!Company.employees != second.locate!Company.employees);
}

unittest {
    
    auto first = new SingletonInstantiator;
    auto second = new SingletonInstantiator;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(aermicioi.aedi.test.fixture)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job != second.locate!Employee.job);
    assert(first.locate!Company.employees != second.locate!Company.employees);
}

unittest {
    
    auto first = new SingletonInstantiator;
    auto second = new SingletonInstantiator;
    auto parameters = new ObjectStorage!();
    
    import fixture_second = aermicioi.aedi.test.fixture_second;
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new fixture_second.Employee("Zack", cast(ubyte) 20));
    parameters.register(new fixture_second.Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(aermicioi.aedi.test.fixture, aermicioi.aedi.test.fixture_second)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture, aermicioi.aedi.test.fixture_second)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job != second.locate!Employee.job);
    assert(first.locate!Company.employees != second.locate!Company.employees);
    assert(first.locate!(fixture_second.Employee).job != second.locate!(fixture_second.Employee).job);
    assert(first.locate!(fixture_second.Company).employees != second.locate!(fixture_second.Company).employees);
}

unittest {
    auto first = new SingletonInstantiator;
    auto second = new SingletonInstantiator;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(aermicioi.aedi.test.fixture)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job == parameters.locate!Job);
    assert(second.locate!Employee.job == second.locate!Job);
    assert(second.locate!Employee.job != parameters.locate!Job);
}

unittest {
    auto instantiator = new ApplicationInstantiator;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);

    instantiator.componentScan!(Company)("company.custom");
    instantiator.componentScan!(Identifiable!ulong, Employee);
    instantiator.componentScan!(Employee)(parameters, "employee.custom"); 
    instantiator.componentScan!Company(parameters);
    instantiator.componentScan!Employee;
    instantiator.componentScan!Job;
    
    instantiator.instantiate();
    
    assert(instantiator.locate!Company("company.custom").employees[0] != parameters.locate!Employee);
    assert(instantiator.locate!Employee(name!(Identifiable!ulong)) != parameters.locate!Employee);
    assert(instantiator.locate!Employee("employee.custom").job == parameters.locate!Job);
    assert(instantiator.locate!Company.employees[0] == parameters.locate!Employee);
    assert(instantiator.locate!Employee.job == instantiator.locate!Job);
}

unittest {
    auto first = new ApplicationInstantiator;
    auto second = new ApplicationInstantiator;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(Identifiable!ulong, Employee)(parameters);
    first.componentScan!(Job);
    second.componentScan!(Identifiable!ulong, Company);
    second.componentScan!(Employee);
    second.componentScan!(Job);
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee(name!(Identifiable!ulong)).job == parameters.locate!Job);
    assert(second.locate!Company(name!(Identifiable!ulong)).employees[0] != parameters.locate!Employee);
}

unittest {
    auto first = new ApplicationInstantiator;
    auto second = new ApplicationInstantiator;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(Company, Employee, Job, Identifiable!ulong, Company)(parameters);
    second.componentScan!(Company, Employee, Job, Identifiable!ulong, Company);
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!(Company).employees[0] == parameters.locate!Employee);
    assert(first.locate!Employee.job == parameters.locate!Job);
    assert(first.locate!Company != first.locate!Company(name!(Identifiable!ulong)));
    
    assert(second.locate!(Company).employees[0] != second.locate!Employee);
    assert(second.locate!Employee.job == second.locate!Job);
    assert(second.locate!Company != second.locate!Company(name!(Identifiable!ulong)));
}

unittest {
    auto first = new ApplicationInstantiator;
    auto second = new ApplicationInstantiator;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);

    first.componentScan!(aermicioi.aedi.test.fixture)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture);
    
    assert(first.locate!(Company).employees[0] == parameters.locate!Employee);
    assert(first.locate!Employee.job == parameters.locate!Job);
    
    assert(second.locate!(Company).employees[0] != second.locate!Employee);
    assert(second.locate!Employee.job == second.locate!Job);
}


unittest {
    import s = aermicioi.aedi.test.fixture_second;

    auto first = new ApplicationInstantiator;
    auto second = new ApplicationInstantiator;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", 49));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new s.Employee("Zack", cast(ubyte) 20));
    parameters.register(new s.Job("Magician", 49));
    
    first.componentScan!(
        aermicioi.aedi.test.fixture,
        aermicioi.aedi.test.fixture_second
    )(parameters);
    
    second.componentScan!(
        aermicioi.aedi.test.fixture,
        aermicioi.aedi.test.fixture_second
    );
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!(Company).employees[0] == parameters.locate!Employee);
    assert(first.locate!Employee.job == parameters.locate!Job);
    assert(first.locate!(s.Company).employees[0] == parameters.locate!(s.Employee));
    assert(first.locate!(s.Employee).job == parameters.locate!(s.Job));
    
    assert(second.locate!(Company).employees[0] != second.locate!Employee);
    assert(second.locate!Employee.job == second.locate!Job);
    assert(second.locate!(s.Company).employees[0] == second.locate!(s.Employee));
    assert(second.locate!(s.Employee).job == second.locate!(s.Job));
}