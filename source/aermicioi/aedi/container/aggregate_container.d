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
module aermicioi.aedi.container.aggregate_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.exception.not_found_exception;
import std.range.interfaces;
import std.typecons;

class AggregateContainer : Container, Storage!(Container, string), AggregateLocator!(Object, string) {
    
    private {
        ObjectStorage!(Container, string) containers;
    }
    
    public {
        
        this() {
            this.containers = new ObjectStorage!(Container, string);
        }
        
        AggregateContainer set(Container container, string identity) {
        	this.containers.set(container, identity);
        
        	return this;
        }
        
        AggregateContainer remove(string identity) {
        	this.containers.remove(identity);
        
        	return this;
        }
        
        Object get(string identity) {
            if (this.containers.has(identity)) {
                Object container = cast(Object) this.containers.get(identity); 
                
                if (container !is null) {
                    return container;
                }
            }
            
        	foreach (container; this.containers) {
        	    if (container.has(identity)) {
        	        return container.get(identity);
        	    }
        	}
        	
        	throw new NotFoundException("Object by id " ~ identity ~ " not found.");
        }
        
        bool has(in string identity) inout {
            if (this.containers.has(identity)) {
                return true;
            }
            
            foreach (container; this.containers.contents) {
                if (container.has(identity)) {
                    return true;
                }
            }
            
            return false;
        }
        
        AggregateContainer instantiate() {
            
            foreach (container; this.containers) {
                container.instantiate;
            }
            
            return this;
        }
        
        /**
        Get a specific locator.
        
        Params:
            key = the locator identity.
        **/
        Locator!(Object, string) getLocator(string key) {
            
            return this.containers.get(key);
        }
        
        /**
        Get all locators in aggregate locator
        
        Returns:
        	InputRange!(Tuple!(Locator!(Type, KeyType), LocatorKeyType)) a range of locator => identity
        **/
        InputRange!(Tuple!(Locator!(Object, string), string)) getLocators() {
            import std.algorithm;
            
            return this.containers.contents.byKeyValue.map!(
                a => tuple(cast(Locator!()) a.value, a.key)
            ).inputRangeObject;
        }
        
        /**
        Check if aggregate locator contains a specific locator.
        
        Params:
        	key = the identity of locator in aggregate locator
        **/
        bool hasLocator(string key) inout {
            
            return this.containers.has(key);
        }
    }
}