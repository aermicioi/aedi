/**
This module is a container for a set of templates that are used across library and aren't bound to some specific module.
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
module aermicioi.util.traits.traits;
import std.traits;
import std.typetuple;
import std.algorithm;
import std.array;

public {

    enum bool isHashable(T) = isBasicType!(T) || hasMember!(T, "toHash") || is(T == string) || is(T == enum);
    enum bool isPublic(alias T) = __traits(getProtection, T) == "public";
    enum bool isPublic(alias T, string member) = getProtection!(T, member) == "public";
    enum bool isMethod(alias T, string member) = isSomeFunction!(__traits(getMember, T, member));
    enum bool evaluateMember(alias pred, T, string member) = pred!(__traits(getMember, T, member));
    enum bool isPropertyGetter(alias func) = (variadicFunctionStyle!func == Variadic.no) && (arity!func == 0) && (functionAttributes!func & FunctionAttribute.property);
    enum bool isPropertySetter(alias func) = (variadicFunctionStyle!func == Variadic.no) && (arity!func == 1) && (functionAttributes!func & FunctionAttribute.property);

    enum bool isValue(alias T) = is(typeof(T)) && !is(typeof(T) == void);
    enum bool isValue(T) = false;
    enum bool isType(alias T) = is(T);
    enum bool isProperty(alias T) =
            (isBasicType!(typeof(T)) ||
                isArray!(typeof(T)) ||
                isAssociativeArray!(typeof(T)) ||
                isAggregateType!(typeof(T)) ||
                is(typeof(T) == enum)
            )
            && !isSomeFunction!T
            && !isTemplate!T;
    enum bool isProperty(alias T, string member) = isProperty!(getMember!(T, member));
    enum bool isTypeOrValue(alias T) = isValue!T || isType!T;

    enum bool isConstructor(alias T) = isSomeFunction!T && (identifier!T == "__ctor");
    enum bool isDestructor(alias T) = isSomeFunction!T && (identifier!T == "__dtor");

    enum bool isConstructor(string T) = T == "__ctor";
    enum bool isDestructor(string T) = T == "__dtor";

    enum bool isTrue(bool state) = state == true;
    alias isFalse = templateNot!isTrue;

    template getProperty(alias T, string member) {
        static if (isProperty!(T, member)) {
            alias getProperty = member;
        } else {
            alias getProperty = TypeTuple!();
        }
    }

    template identifier(alias T) {
        alias identifier = Identity!(__traits(identifier, T));
    }

    template isEmpty(T...) {
        enum bool isEmpty = T.length == 0;
    }

    template templateTryGetOverloads(alias symbol) {
        static if (__traits(compiles, getOverloads!symbol)) {

            alias templateTryGetOverloads = getOverloads!symbol;
        } else {

            alias templateTryGetOverloads = symbol;
        }
    }

    template allMembers(alias Type) {
        alias allMembers = TypeTuple!(__traits(allMembers, Type));
    }

    template equals(alias first, alias second) {
        static if (isValue!first && isValue!second && typeCompare!(first, second)) {
            enum bool equals = first == second;
        } else {
            enum bool equals = typeCompare!(first, second);
        }
    }

    template isClassOrStructMagicMethods(string member) {
        enum bool isClassOrStructMagicMethods = equals!(member, "this") || equals!(member, "__ctor") || equals!(member, "__dtor");
    }

    template staticMapWith(alias pred, alias Type, T...) {
        static if (T.length > 1) {
            alias staticMapWith = TypeTuple!(staticMapWith!(pred, Type, T[0 .. $ / 2]), staticMapWith!(pred, Type, T[$ / 2 .. $]));
        } else static if (T.length == 1) {
            alias staticMapWith = TypeTuple!(pred!(Type, T[0]));
        } else {
            alias staticMapWith = TypeTuple!();
        }
    }

    template getMember(alias T, string member) {

        alias getMember = Identity!(__traits(getMember, T, member));
    }

    template getOverloads(alias T, string member) {

        alias getOverloads = AliasSeq!(__traits(getOverloads, T, member));
    }

    template getOverloadsOrMember(alias T, string member) {
        static if (isSomeFunction!(getMember!(T, member))) {
            alias getOverloadsOrMember = getOverloads!(T, member);
        } else {
            alias getOverloadsOrMember = getMember!(T, member);
        }
    }

    template typeCompare(alias first, alias second) {
        static if (isValue!first) {
            static if (isValue!second) {

                enum bool typeCompare = is(typeof(first) : typeof(second));
            } else static if (isType!second) {

                enum bool typeCompare = is(typeof(first) : second);
            } else {

                enum bool typeCompare = false;
            }
        } else static if (isType!first) {
            static if (isValue!second) {

                enum bool typeCompare = is(first : typeof(second));
            } else static if (isType!second) {

                enum bool typeCompare = is(first : second);
            } else {

                enum bool typeCompare = false;
            }
        }
    }

    template typeCompare(first, second) {
        enum bool typeCompare = is(first : second);
    }

    template typeOf(alias T) {
        static if (isValue!T) {
            alias typeOf = typeof(T);
        } else {
            alias typeOf = T;
        }
    }

    template emptyIf(alias pred) {
        template emptyIf(alias T) {
            static if (pred!(T)) {
                alias emptyIf = TypeTuple!();
            } else {
                alias emptyIf = T;
            }
        }
    }

    template notEmptyIf(alias pred) {
        template notEmptyIf(alias T) {
            static if (pred!(T)) {
                alias notEmptyIf = T;
            } else {
                alias notEmptyIf = TypeTuple!();
            }
        }
    }

    template templateStringof(alias T) {
        enum string templateStringof = T.stringof;
    }

    template isTemplate(alias T) {
        enum bool isTemplate = __traits(isTemplate, T);
    }

    template execute(alias pred, Args...) {
        static if (isTemplate!pred) {
            alias execute = pred!Args;
        } else static if (isSomeFunction!pred) {
            auto execute = pred(Args);
        }
    }

    template compiles(alias pred, args...) {
        enum bool compiles = __traits(compiles, pred!args);
    }

    template pragmaMsg(args...) {
        pragma(msg, args);
    }

    template getAttributes(alias symbol) {
        alias getAttributes = TypeTuple!(__traits(getAttributes, symbol));
    }

    template requiredArity(alias symbol) {
        enum bool requiredArity = Filter!(partialPrefixed!(isType, void), ParameterDefaults!symbol);
    }

    template isType(Type, alias symbol) {
        enum bool isType = is(symbol == Type);
    }

    template isType(Type, Second) {
        enum bool isType = is(symbol == Type);
    }

    template isReferenceType(Type) {
        enum bool isReferenceType = is(Type == class) || is(Type == interface);
    }

    template getProtection(alias T, string member) {

        static if (__traits(compiles, __traits(getProtection, __traits(getMember, T, member)))) {
            enum auto getProtection = __traits(getProtection, __traits(getMember, T, member));
        } else {
            enum auto getProtection = "private";
        }
    }

    template getProtection(alias symbol) {
        static if (__traits(compiles, __traits(getProtection, symbol))) {
            enum auto getProtection = __traits(getProtection, symbol);
        } else {
            enum auto getProtection = "private";
        }
    }

    template isProtection(alias T, string member, string protection = "public") {
        enum bool isProtection = getProtection!(T, member) == protection;
    }

    template isProtection(T, string member, string protection = "public") {
        enum bool isProtection = getProtection!(T, member) == protection;
    }

    template isProtection(alias symbol, string protection) {
        enum bool isProtection = getProtection!symbol == protection;
    }

    template getMembersWithProtection(T, string member, string protection = "public") {
        import aermicioi.util.traits.partial : chain, eq;

        alias getMembersWithProtection = Filter!(
            chain!(
                eq!"public",
                getProtection
            ),
            __traits(getOverloads, T, member)
        );
    }

    template StringOf(alias Symbol) {
        enum auto StringOf = Symbol.stringof;
    }

    template hasMembers(alias Symbol) {
        enum bool hasMembers = __traits(compiles, __traits(allMembers, Symbol));
    }

    template hasMembers(Symbol) {
        enum bool hasMembers = __traits(compiles, __traits(allMembers, Symbol));
    }

    template templateSpecs(alias T : Base!Args, alias Base, Args...) {
        alias Template = Base;
        alias Args = Args;
    }

    template templateSpecs(T : Base!Args, alias Base, Args...) {
        alias Template = Base;
        alias Args = Args;
    }

    template concat(args...) {
        static if (args.length > 1) {
            enum auto concat = args[0] ~ concat!(args[1 .. $]);
        } else {
            enum auto concat = args[0];
        }
    }

    template isField(T, string field) {

        auto isField() {
            import aermicioi.util.traits.partial : eq;
            static if (Filter!(eq!field, FieldNameTuple!T).length > 0) {
                return true;
            } else {
                return false;
            }
        }
    }

    template toType(alias T) {
        static if (is(typeof({T x;}))) {
            alias toType = T;
        } else {
            alias toType = typeof(T);
        }
    }

    enum bool isDerived(alias T, alias Z) = is(T : Z);
    enum bool isEq(alias T, alias Z) = is(T == Z);

    enum bool isStaticFunction(alias method) = Identity!(__traits(isStaticFunction, method));
}

private {
    alias Identity(alias A) = A;
}
