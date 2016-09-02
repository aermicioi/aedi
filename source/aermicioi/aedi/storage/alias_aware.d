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
module aermicioi.aedi.storage.alias_aware;

/**
Interface for objects that are able to alias an identity and resolve an alias to original identity.
**/
interface AliasAware(Type) {
    
    public {
        
        /**
        Alias a key to an alias_.
                
        Params:
        	identity = the originial identity which is to be aliased.
        	alias_ = the alias of identity.
        	
		Returns:
			this
        **/
        AliasAware link(Type identity, Type alias_);
        
        /**
        Removes alias.
        
        Params:
        	alias_ = alias to remove.

        Returns:
            this
        	
        **/
        AliasAware unlink(Type alias_);
        
        /**
        Resolve an alias to original identity, if possible.
        
        Params:
        	alias_ = alias of original identity
        
        Returns:
        	Type the last identity in alias chain.
        
        **/
        const(Type) resolve(Type alias_) const;
    }
}