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
module aermicioi.util.traits.partial;

import aermicioi.util.traits.traits;
import std.meta;
import std.traits;

/**
Instantiate a template that will check equality of first with second

Params:
    first = first element
    second = second element
    
Returns:
    bool true if equal, false otherwise 
**/
template eq(alias first) {
    enum bool eq(alias second) = (first == second);
}

/**
Instantiate a template that will check if first is greater than second

Params:
    first = first element
    second = second element
    
Returns:
    bool true if greater, false otherwise 
**/
template gt(alias first) {
    enum bool eq(alias second) = (first > second);
}

/**
Instantiate a template that will check if first is less than second

Params:
    first = first element
    second = second element
    
Returns:
    bool true if lesser, false otherwise 
**/
template lt(alias first) {
    enum bool eq(alias second) = (first < second);
}

/**
Instantiate a template that will check if first is greater or equal than second

Params:
    first = first element
    second = second element
    
Returns:
    bool true if greater or equal, false otherwise 
**/
template gte(alias first) {
    enum bool eq(alias second) = (first >= second);
}

/**
Instantiate a template that will check if first is less or equal than second

Params:
    first = first element
    second = second element
    
Returns:
    bool true if lesser or equal, false otherwise 
**/
template lte(alias first) {
    enum bool eq(alias second) = (first <= second);
}


static if (__traits(hasMember, std.meta, "ApplyLeft")) {
    alias partialPrefixed = ApplyLeft;
} else {
    /**
    Prefix a template with a set of arguments.

    Prefix a template with a set of arguments.
    A prefixed template will have first arguments to be
    Args, and rest of passed arguments afterwards (Sargs).

    Params:
        pred = prefixable template
        Args = arguments that are prefixed
        Sargs = arguments that are suffixed
    **/
    template partialPrefixed(alias pred, Args...) {
        template partialPrefixed(Sargs...) {
            alias partialPrefixed = pred!(Args, Sargs);
        }
    }
}

static if (__traits(hasMember, std.meta, "ApplyLeft")) {

    alias partialSuffixed = ApplyRight;
} else {

    /**
    Suffix a template with a set of arguments.

    Suffix a template with a set of arguments.
    A suffixed template will have first arguments to be
    Args, and rest of passed arguments afterwards (Sargs).

    Params:
        pred = prefixable template
        Args = arguments that are suffixed
        Sargs = arguments that are prefixed
    **/
    template partialSuffixed(alias pred, Args...) {
        template partialSuffixed(Sargs...) {
            alias partialSuffixed = pred!(Sargs, Args);
        }
    }
}

/**
Instantiate a template with Args, and apply them
to pred.

Params:
    Args = contained arguments
    pred = a template that Args will be passed to.
**/
template applyArgs(Args...) {
    template applyArgs(alias pred) {
        alias applyArgs = pred!Args;
    }
}

/**
Apply to Preds a set of Args.

Apply to Preds a set of Args.
Given a set of Preds, apply for each Args,
and return a Tuple of results.

Params:
    Preds = predicates that will receive Args.
    Args = arguments that are suffixed
**/
template partial(Preds...) {
    
    template partial(Args...) {
        alias partial = staticMap!(
            applyArgs!Args,
            Preds
        );
    }
}

/**
Chain a set of templates, and apply Args as input.

Chain a set of templates, and apply Args as input.
Description

Params:
	Preds = a set of predicates to be chained.
	Args = arguments passed to chained predicates.

Returns:
	Result of executing chained Preds with Args.
**/
template chain(predicates...) {
    template chain(args...) {
        
        template impl(predicates...) {
            static if (predicates.length > 0) {
                alias predicate = predicates[0];
                alias impl = predicate!(impl!(predicates[1 .. $]));
            } else {
                alias impl = args;
            }
        }
        
        alias chain = impl!predicates;
    }
}

/**
Reverse the order of arguments.

Params:
    args = tuple of template arguments.
**/
template reverse(args...) {
    static if (args.length > 0) {
        alias reverse = AliasSeq!(args[$ - 1], reverse!(args[0 .. $ - 2]));
    } else {
        alias reverse = args[0];
    }
}


/**
Execute trueBranch or falseBranch depending on pred!Args bool result.

Params:
    pred = template depending on which a trueBranch or falseBranch will be executed.
    trueBranch = template to be executed when pred!Args is true.
    falseBranch = template to be executed when pred!Args is false.
    
Return:
    Result of trueBranch or falseBranch depending on pred!Args
**/
template if_(alias pred, alias trueBranch, alias falseBranch) {
    template if_ (Args...) {
        static if (pred!Args) {
            static if (isTemplate!trueBranch) {
                alias if_ = trueBranch!Args;
            } else {
                alias if_ = trueBranch;
            }
        } else {
            static if (isTemplate!trueBranch) {
                alias if_ = falseBranch!Args;
            } else {
                alias if_ = falseBranch;
            }
        }
    }
}

/**
Execute pred, if it does not have any compiler errors.

Params:
    pred = template that will be executed if it does not contain errors.
    response = a response if pred will fail.
    
Return:
    Result of pred if it does not contain errors or response otherwise
**/
alias failable(alias pred, alias response) =
    if_!(
        partialPrefixed!(
            compiles,
            pred
        ),
        pred,
        response
    );
    
template get(size_t index) {
    template get(args...) {
        alias get = args[index];
    }
}
    
template tee(alias predicate, args...) {
    alias tee = args;
    
    alias executed = predicate!args;
}

alias onFail(alias pred) = 
    if_!(
        isTrue,
        isTrue,
        chain!(
            get!0,
            partialPrefixed!(
                tee,
                pred
            )
        )
    );
    
alias onFailPrint(string error) = 
    onFail!(
        partialSuffixed!(
            pragmaMsg,
            error
        )
    );

template staticAssert(alias predicate, string error) {
    template staticAssert(args...) {
        static assert(predicate!args, error);
        
        enum bool staticAssert = predicate!args;
    }
}

auto curry(Dg, Args...)(Dg func, auto ref Args args)
    if (isSomeFunction!Dg) {
    import std.typecons;
    class Curry {
        private {
            Tuple!Args args;
            Dg func;
        }
        
        public {
            this(ref Args args, Dg func) {
                this.args = tuple!(args);
                this.func = func;
            }
            
            ReturnType!Dg opCall(Parameters!Dg[Args.length .. $] args) {
                static if (is(ReturnType!Dg == void)) {
                    func(this.args.expand, args);
                } else {
                    return func(this.args.expand, args);
                }
            }
        }
    }
    
    Curry curry = new Curry(args, func);
    
    return &curry.opCall;
}