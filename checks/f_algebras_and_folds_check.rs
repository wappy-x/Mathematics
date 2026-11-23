// F-algebras and folds -- the same check as the Python, in Rust.  No crates.
// The expression type is a functor F: one layer, a literal or an operator over
// two holes.  fold is the only recursive function the algebras use; every job
// on the tree is an algebra, one step of rules handed to fold.  No Iterator::fold.
#[derive(Clone, PartialEq, Debug)]
enum Layer<X> { Lit(i64), Add(X, X), Mul(X, X) }
use Layer::*;

#[derive(Clone, PartialEq, Debug)]
struct Tree(Box<Layer<Tree>>);

fn fmap<X, Y>(l: &Layer<X>, f: &mut dyn FnMut(&X) -> Y) -> Layer<Y> {   // F on arrows
    match l { Lit(n) => Lit(*n), Add(a, b) => { let x = f(a); Add(x, f(b)) }, Mul(a, b) => { let x = f(a); Mul(x, f(b)) } }
}

fn into(l: Layer<Tree>) -> Tree { Tree(Box::new(l)) }      // in: one layer of trees becomes a tree
fn out(t: &Tree) -> &Layer<Tree> { &t.0 }                  // out: read a tree's top layer back

fn fold<A>(alg: &mut dyn FnMut(Layer<A>) -> A, t: &Tree) -> A {   // children first, then one step
    let l = fmap(out(t), &mut |c: &Tree| fold(&mut *alg, c));
    alg(l)
}

fn lit(n: i64) -> Tree { into(Lit(n)) }
fn node(op: &str, a: Tree, b: Tree) -> Tree { into(if op == "add" { Add(a, b) } else { Mul(a, b) }) }

fn evaluate(l: Layer<i64>) -> i64 { match l { Lit(n) => n, Add(a, b) => a + b, Mul(a, b) => a * b } }
fn clock(m: i64) -> impl Fn(Layer<i64>) -> i64 { move |l| match l { Lit(n) => n % m, o => evaluate(o) % m } }
fn size(l: Layer<i64>) -> i64 { match l { Lit(_) => 1, Add(a, b) | Mul(a, b) => 1 + a + b } }
fn height(l: Layer<i64>) -> i64 { match l { Lit(_) => 0, Add(a, b) | Mul(a, b) => 1 + a.max(b) } }
fn show(l: Layer<String>) -> String {
    match l { Lit(n) => n.to_string(), Add(a, b) => format!("({} + {})", a, b), Mul(a, b) => format!("({} * {})", a, b) }
}
fn drop_digit(l: Layer<i64>) -> i64 { match l { Lit(n) => n / 10, o => evaluate(o) } }

fn postorder(t: &Tree) -> Vec<String> {                    // road two: the walk from Rooted trees
    match out(t) {
        Lit(n) => vec![n.to_string()],
        Add(a, b) => [postorder(a), postorder(b), vec!["add".to_string()]].concat(),
        Mul(a, b) => [postorder(a), postorder(b), vec!["mul".to_string()]].concat(),
    }
}

fn stack_run(tokens: &[String]) -> i64 {                   // evaluate the post-order list with a stack
    let mut stack: Vec<i64> = Vec::new();
    for tok in tokens {
        if tok == "add" || tok == "mul" {
            let (b, a) = (stack.pop().unwrap(), stack.pop().unwrap());
            stack.push(if tok == "add" { a + b } else { a * b });
        } else { stack.push(tok.parse().unwrap()) }
    }
    stack[0]
}

fn fold_list(nil: i64, cons: &dyn Fn(i64, i64) -> i64, xs: &[i64]) -> i64 {   // the list functor's fold
    if xs.is_empty() { nil } else { cons(xs[0], fold_list(nil, cons, &xs[1..])) }
}
fn line_totals(t: &Tree) -> Vec<i64> {                     // road three: each line read off the tree
    let lit_of = |s: &Tree| if let Lit(n) = out(s) { *n } else { 0 };
    let line = |s: &Tree| match out(s) { Add(q, p) | Mul(q, p) => lit_of(q) * lit_of(p), Lit(n) => *n };
    match out(t) { Add(a, b) | Mul(a, b) => vec![line(a), line(b)], Lit(n) => vec![*n] }
}
fn receipt(p: i64) -> Tree { node("add", node("mul", lit(3), lit(p)), node("mul", lit(2), lit(240))) }

fn ev(t: &Tree) -> i64 { fold(&mut evaluate, t) }
fn fc(m: i64, t: &Tree) -> i64 { let c = clock(m); fold(&mut |l| c(l), t) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn commuting(m: i64, small: &[Tree]) -> Vec<Vec<i64>> {   // every map small -> m-hour clock, on the square
    let mut good = Vec::new();
    let c = clock(m);
    for code in 0..m.pow(small.len() as u32) {
        let h: Vec<i64> = (0..small.len()).map(|i| code / m.pow(i as u32) % m).collect();
        let ok = small.iter().enumerate().all(|(i, s)| {
            h[i] == c(fmap(out(s), &mut |ch: &Tree| h[small.iter().position(|x| x == ch).unwrap()]))
        });
        if ok { good.push(h) }
    }
    good
}

fn main() {
    let t = receipt(125);
    let mut log: Vec<String> = Vec::new();
    let total = fold(&mut |l: Layer<i64>| {
        let args = match &l { Lit(n) => ("lit", n.to_string()), Add(a, b) => ("add", format!("{} {}", a, b)), Mul(a, b) => ("mul", format!("{} {}", a, b)) };
        let v = evaluate(l);
        log.push(format!("  {} {} -> {}", args.0, args.1, v));
        v
    }, &t);
    let rpn = postorder(&t);
    let lines = line_totals(&t);
    let via_list = fold_list(0, &|x, acc| x + acc, &lines);                   // then a list fold
    println!("expression: 3 x 125 + 2 x 240, prices in pence");
    println!("tree, printed by a fold: {}", fold(&mut show, &t));
    println!("fold, evaluate: {} pence = £{}.{:02}", total, total / 100, total % 100);
    println!("fold, count nodes: {}; fold, height: {}", fold(&mut size, &t), fold(&mut height, &t));
    println!("fold, the 10-hour clock: {}", fc(10, &t));
    println!("the evaluate fold, in the order its steps run:");
    for line in &log { println!("{}", line) }
    println!("road two, a stack run on the post-order list {}: {}", rpn.join(" "), stack_run(&rpn));
    println!("road three, a list fold over the line totals read off the tree, {:?}: {}", lines, via_list);

    let mut layers: Vec<Layer<i64>> = vec![Lit(2), Lit(3)];   // functor laws over {0, 1, 2, 3, 4}
    for op in ["add", "mul"] { for a in 0..5 { for b in 0..5 { layers.push(if op == "add" { Add(a, b) } else { Mul(a, b) }) } } }
    let (f, g) = (|x: &i64| (x + 1) % 5, |x: &i64| 2 * x % 5);
    let ident = layers.iter().all(|l| fmap(l, &mut |x: &i64| *x) == *l);
    let comp = layers.iter().all(|l| fmap(l, &mut |x: &i64| g(&f(x))) == fmap(&fmap(l, &mut |x: &i64| f(x)), &mut |x: &i64| g(x)));
    println!("functor laws on all {} layers over 0 to 4: identity {}, composition {}", layers.len(), yn(ident), yn(comp));

    let mut levels: Vec<Vec<Tree>> = vec![Vec::new()];        // F applied k times to the empty set
    for _ in 0..3 {
        let prev = levels.last().unwrap().clone();
        let mut next = vec![lit(2), lit(3)];
        for op in ["add", "mul"] { for a in &prev { for b in &prev { next.push(node(op, a.clone(), b.clone())) } } }
        levels.push(next);
    }
    let mut rec: Vec<usize> = vec![0];
    for _ in 0..4 { let a = *rec.last().unwrap(); rec.push(2 + 2 * a * a) }
    let counts: Vec<usize> = levels.iter().map(|x| x.len()).collect();
    println!("trees built in k layers, k = 0 to 3, by listing: {:?}", counts);
    println!("the same by the count a(k+1) = 2 + 2 a(k)^2, k = 0 to 4: {:?}", rec);
    let trees = &levels[3];
    let lambek = trees.iter().all(|s| into(out(s).clone()) == *s
        && fold(&mut |l: Layer<Layer<Tree>>| fmap(&l, &mut |x: &Layer<Tree>| into(x.clone())), s) == *out(s));
    let same_eval = trees.iter().all(|s| ev(s) == stack_run(&postorder(s)));
    let fusion = trees.iter().all(|s| fc(10, s) == ev(s) % 10);
    let same_size = trees.iter().all(|s| fold(&mut size, s) == postorder(s).len() as i64);
    println!("on all {} trees: in undoes out, and out is a fold: {}", trees.len(), yn(lambek));
    println!("on all {} trees: evaluate fold = stack run {}; clock fold = last digit of evaluate {}; size = list length {}",
             trees.len(), yn(same_eval), yn(fusion), yn(same_size));

    let small = &levels[2];
    let good = commuting(3, small);
    let the_fold: Vec<i64> = small.iter().map(|s| fc(3, s)).collect();
    println!("maps from the {} trees of height at most 1 to the 3-hour clock: {}; squares commuting: {}; it is the fold: {}",
             small.len(), 3i64.pow(small.len() as u32), good.len(), yn(good == vec![the_fold.clone()]));

    let toks: Vec<String> = fold(&mut |l: Layer<Vec<String>>| match l { Lit(n) => vec![n.to_string()],   // brackets lost
        Add(a, b) => [a, vec!["add".to_string()], b].concat(), Mul(a, b) => [a, vec!["mul".to_string()], b].concat() }, &t);
    let mut flat: i64 = toks[0].parse().unwrap();             // a calculator with no precedence
    for k in (1..toks.len()).step_by(2) { let x: i64 = toks[k + 1].parse().unwrap(); flat = if toks[k] == "add" { flat + x } else { flat * x } }
    let dropped = fold(&mut drop_digit, &t);
    let cells: Vec<(&str, Vec<(&str, &str)>)> = vec![("A1", vec![("ref", "B1"), ("lit", "1")]), ("B1", vec![("lit", "2"), ("ref", "A1")])];
    let (mut path, mut cell) = (vec!["A1"], "A1");
    let nxt = loop {
        let ops = &cells.iter().find(|c| c.0 == cell).unwrap().1;
        let n = ops.iter().find(|e| e.0 == "ref").unwrap().1;
        if path.contains(&n) { break n }
        path.push(n);
        cell = n;
    };
    let shown = [path.clone(), vec![nxt]].concat();
    println!("mistake 1, a calculator read left to right over {}: {}", toks.join(" "), flat);
    println!("mistake 2, fusing 'drop the last digit', no algebra map: fold gives {}, but {} drops to {}", dropped, total, total / 10);
    println!("mistake 3, A1 = B1 + 1 and B1 = 2 x A1: unfolding {} meets A1 again after {} steps: a cycle, no finite tree, no fold", shown.join(" -> "), path.len());
    let (mut subsets, mut sizes): (Vec<Vec<i64>>, Vec<usize>) = (vec![vec![]], vec![1]);   // each member out, or in
    for x in 0..5 { let more: Vec<Vec<i64>> = subsets.iter().map(|s| [s.clone(), vec![x]].concat()).collect(); subsets.extend(more); sizes.push(subsets.len()) }
    println!("no initial algebra for the power-set functor: subsets listed for sets of 0 to 5 members: {:?}, never n", sizes);
    println!("try: price 140 gives {}; the 7-hour clock gives {}; the 2-hour clock: {} maps, {} commuting",
             ev(&receipt(140)), fc(7, &t), 2i64.pow(small.len() as u32), commuting(2, small).len());
    assert!(total == stack_run(&rpn) && total == via_list);                 // three roads to the total
    assert!(ident && comp && lambek);                                       // functor laws, Lambek
    assert!(same_eval && fusion && same_size);                              // fold against walk, on 202 trees
    assert!(counts == rec[..4].to_vec());                                   // listing against the count
    assert!(good.len() == 1 && good[0] == the_fold);                        // uniqueness, by brute force
    assert!(dropped != total / 10 && flat != total);                        // the mistakes really differ
    assert!(sizes == (0..6).map(|n| 1usize << n).collect::<Vec<usize>>());   // the listing against 2^n
    println!("ALL CHECKS PASS");
}
