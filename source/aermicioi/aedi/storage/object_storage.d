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
	Alexandru Ermicioi
**/
module aermicioi.aedi.storage.object_storage;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.exception.not_found_exception;

import std.conv;

/**
 Implementation of Storage, Locator and AliasAware interfaces.
 
 Stores Type elements by KeyType identity in.
**/
class ObjectStorage(Type = Object, KeyType = string) : Storage!(Type, KeyType), Locator!(Type, KeyType), AliasAware!(KeyType) {
    
    private {
        
        Type[KeyType] values;
        
        KeyType[KeyType] aliasings;
    }
    
    public {
        
        /**
        Fetch an element by identity.
        
        Params:
        	identity = the identity of element to be returned
        
        Throws:
        	NotFoundException when no element is present in storage.
        
        Returns:
        	Type the element with identity.
        **/
        Type get(KeyType identity) {
            
            identity = this.resolve(identity);
            
            if (!this.has(identity)) {
                throw new NotFoundException("Element " ~ identity.to!string ~ " not found.");
            }
            
            return this.values[identity];
        }
        
        /**
        Check if an element is present in storage.
        
        Params:
        	identity = the identity of element.
        
        Returns:
        	bool if element with identity exists in storage.
        **/
        bool has(KeyType identity) inout {
            return (this.resolve(identity) in this.values) !is null;
        }
        
		/**
		Save an element in storage by identity.
		
		Params:
			identity = the identity of element in storage.
			element = the element which is saved in storage.
		
		Returns:
			ObjectStorage
		**/
        ObjectStorage set(KeyType identity, Type element) {
            
            this.values[identity] = element;
            
            return this;
        }
        
		/**
		Remove an element with identity from storage.
		
		Params:
			identity = identity of element which should be removed from storage.
		
		Returns:
			ObjectStorage
		**/
        ObjectStorage remove(KeyType identity) {
            
            this.values.remove(identity);
            
            return this;
        }
        
        /**
        Get the contents of storage as associative array.
        
        Returns:
        	Type[KeyType] the contents of storage.
        **/
        Type[KeyType] contents() {
            return this.values;
        }
        
        /**
        Iterate over elements in storage
        
        Params:
        	dg = the delegate which will do something on each element.
        
        Returns:
        	int
        **/
        int opApply(scope int delegate(Type value) dg) {
        	
        	foreach (value; this.contents()) {
        		
        		auto result = dg(value);
        		
        		if (result != 0) {
        			return result;
        		}
        	}
        	
        	return 0;
        }
        
        /**
        ditto
        **/
        int opApply(scope int delegate(KeyType key, Type value) dg) {
        	
        	foreach (key, value; this.contents()) {
        		
        		auto result = dg(key, value);
        		
        		if (result != 0) {
        			return result;
        		}
        	}
        	
        	return 0;
        }
        
        /**
        Alias an identity with alias_/
        
        Params:
        	identity = identity which will be aliased
        	alias_ = the new alias of identity.
        
        Returns:
        	ObejcStorage
        **/
        ObjectStorage link(KeyType identity, KeyType alias_) {
            
            this.aliasings[alias_] = identity;
            
            return this;
        }
        
        /**
        Removes alias.
        
        Params:
        	alias_ = alias to remove.

        Returns:
            this
        	
        **/
        ObjectStorage unlink(KeyType alias_) {
            this.aliasings.remove(alias_);
            
            return this;
        }
        
        /**
        Resolve the alias to an element identity.
        
        Params:
        	alias_ = the alias to an identity.
        Returns:
        	KeyType the last found identity in alias chain.
        **/
        const(KeyType) resolve(KeyType alias_) const {
            
            if ((alias_ in this.aliasings) !is null) {
                return this.resolve(this.aliasings[alias_]);
            } else {
                return alias_;
            }
        }
    }
}