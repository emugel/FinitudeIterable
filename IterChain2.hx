package finitudeiterable;

import FinitudeIterable;
using Lambda;

/**
 * Sequential iteration. Subiterators are chained sequentially.
 * Once first subiterator is finished, the second subiterator is iterated,
 * and so on until all subiterators have been iterated.
 *
 * @example
 * ```haxe
 * for (i in new IterChain([
 *      new IterRange(0, 3),
 *      new IterRange(-10, -13),
 *      new IterRange(3, 6)
 * ]) 
 *      trace(i);
 * 
 * // Will show 0, 1, 2, -10, -11, -12, 3, 4, 5.
 *
 * // This will yield the same output:
 *
 * import IterRange.range as range;
 *
 * [ range(0,   3  ),
 *   range(-10, -13),
 *   range(3,   6  ),
 * ].iter(trace);
 *
 * @endexample
 *
 * You can also use the andThen() notation, with `using IterChain`:
 *
 * @example
 * ```haxe
 * using IterChain;
 * using IterLoop;
 * import IterRange.range as range;
 *
 * range(3,0).andThen([0].loop());
 *
 * // /!\ If you iterate through the above line, it will create an infinite 
 * //     iterator generating 3, 2, 1, 0, 0, 0, 0, ...
 * //     The following example will show how this dangerous-looking perspective 
 * //     can be used.
 * @endexample
 * 
 * This style can be used along with IterDual. For example let's say we have 
 * an IterLine which takes 2 points and iterate through the points joining
 * them. Using the previous example, we could then associate a radiation measure 
 * expressed as an Int depending on the distance from the first one:
 *
 * ```haxe
 * using IterChain;
 * using IterLoop;
 * using IterDual;
 * import IterRange.range as range;
 * import IterLine;
 *
 * for (i in dual(
 *      new IterLine({x: -19, y: 24}, {x:100, y: 100}),
 *      range(50, 0).andThen( [0].loop())
 * )) {
 *      trace( i._1 );  // Point: point from the line ({x: ?, y: ?})
 *      trace( i._2 );  // Int:   radiation level, decreasing from 50 to 0
 * }
 * ```
 */
class IterChain2<T> {
    var all         : Iterable<Iterable<T>>;
    var master      : Iterator<Iterable<T>>;
    var inner       : Iterator<T>;
    var isInfinite  : Bool;

    public function new(a:Array<Iterable<T>>) {
        all = a;
        master = all.iterator();
        inner = getNextInnerHavingNext_orNull();
        isInfinite = all.exists(function(itb) 
            return Std.is(itb, "FinitudeIterable") 
                && untyped itb.isInfiniteIter()
        );
    }

    public inline static function andThenIter<T>(a:Iterable<T>, b:Iterable<T>) 
        return new IterChain([a, b]);

    public inline static function iterChain<T>(a:Array<Iterable<T>>) 
        return new IterChain(a);
    
    public macro static function chain<T>(ae:Array<haxe.macro.Expr>) {
        var a = [];
        for (e in ae) { a.push(e); }
        var args = macro $a{a};
        return macro new IterChain2($args);

        // var a : Array<Iterator<T>> = [];
        // for (e in ae)
        //     a.push(macro 
        //             // Nadako sol. 0
        //             // >> Reification
        //             ($e : Iterator<T>)
                
        //             // Nadako sol. 1 & 2: ECheckType
        //             // ${ {
        //             //     expr: ECheckType(
        //             //         e,
        //             //         TPath({ 
        //             //             pack: [],
        //             //             name: "Iterator",
        //             //             params: [
        //             //                 // Nadako sol. 1
        //             //                 // TPType(TPath({ 
        //             //                 //     pack: [],
        //             //                 //     name: "T" 
        //             //                 // }))

        //             //                 // Nadako sol. 2
        //             //                 // >> Reification
        //             //                 TPType(macro : T)
        //             //             ] 
        //             //         })
        //             //     ),
        //             //     pos: e.pos
        //             // } }
        //         ); 

        // var args = macro $a{a};
        // return macro new IterChain2($args);
    }

    public inline function isInfiniteIter():Bool return isInfinite;
    public inline function iterator():IterableIterator<T> return new IterChain(all);
    public inline function next() return inner.next();
    public function hasNext() 
        return inner.hasNext() 
            || ((inner = getNextInnerHavingNext_orNull()) != null)
        ;

    public function getNextInnerHavingNext_orNull() {
        while (inner == null || !inner.hasNext()) {
            if (master.hasNext()) inner = master.next().iterator();
            else return null;
        }
        return inner;
    }
}

