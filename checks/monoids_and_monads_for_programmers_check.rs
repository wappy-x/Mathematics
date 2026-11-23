// Monoids and monads -- the same check as the Python, in Rust.  No crates.
// Part 1 folds a basket of prices, in pence, with a monoid, and checks the
// answer three ways: left to right, every bracketing, and two tills.
// Part 2 chains lookups that may fail with the Maybe monad, checks the chain
// against plain nested ifs, and checks the monad laws on every case.
use std::collections::{BTreeMap, BTreeSet};
type Table = BTreeMap<String, String>;
type M = Option<String>; // Maybe: None = nothing, Some(x) = just x

fn table(pairs: &[(&str, &str)]) -> Table {
    pairs.iter().map(|(k, v)| (k.to_string(), v.to_string())).collect()
}
fn fold<T: Clone>(op: fn(&T, &T) -> T, e: T, xs: &[T]) -> T {
    let mut acc = e; // start at the identity, combine left to right
    for x in xs { acc = op(&acc, x) }
    acc
}
fn brackets(op: fn(&i64, &i64) -> i64, xs: &[i64]) -> Vec<i64> {
    if xs.len() == 1 { return vec![xs[0]] } // every way to put brackets on xs
    let mut out = Vec::new();
    for k in 1..xs.len() {
        for a in brackets(op, &xs[..k]) { for b in brackets(op, &xs[k..]) { out.push(op(&a, &b)) } }
    }
    out
}
fn add(a: &i64, b: &i64) -> i64 { a + b }
fn sub(a: &i64, b: &i64) -> i64 { a - b }
fn big(a: &i64, b: &i64) -> i64 { if a >= b { *a } else { *b } }
fn join(a: &String, b: &String) -> String { format!("{}{}", a, b) }
fn pair(a: &(i64, i64), b: &(i64, i64)) -> (i64, i64) { (a.0 + b.0, a.1 + b.1) }
fn monoid<T: Clone + PartialEq>(op: fn(&T, &T) -> T, e: T, xs: &[T]) -> bool {
    let ident = xs.iter().all(|a| op(&e, a) == *a && op(a, &e) == *a);
    let assoc = xs.iter().all(|a| xs.iter().all(|b| xs.iter().all(|c|
        op(&op(a, b), c) == op(a, &op(b, c)))));
    ident && assoc
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn unit(x: &str) -> M { Some(x.to_string()) }
fn bind(m: &M, f: &dyn Fn(&str) -> M) -> M { // pass nothing on; feed a value on
    match m { None => None, Some(x) => f(x) }
}
fn look(t: &Table, k: &str) -> M { t.get(k).cloned() }
fn show(m: &M) -> String { match m { None => "nothing".to_string(), Some(x) => format!("just {}", x) } }
fn kleisli(f: &Table, g: &Table) -> Table { // table f, then table g, as one table
    f.iter().filter(|(_, v)| g.contains_key(*v)).map(|(k, v)| (k.clone(), g[v].clone())).collect()
}

fn main() {
    let prices = [("tea", 249i64), ("milk", 120), ("coffee", 375), ("bread", 89)];
    let orders = table(&[("1001", "C17"), ("1002", "C42"), ("1003", "C99")]);
    let customers = table(&[("C17", "LS1"), ("C42", "M60")]);
    let zones = table(&[("LS1", "Z2")]);
    let charges = table(&[("Z1", "299"), ("Z2", "450"), ("Z3", "650")]);
    let steps = vec![orders.clone(), customers.clone(), zones.clone(), charges.clone()];
    let pence: Vec<i64> = prices.iter().map(|p| p.1).collect();
    let total = fold(add, 0, &pence);
    let trees = brackets(add, &pence);
    let (till_a, till_b) = (fold(add, 0, &pence[..3]), fold(add, 0, &pence[3..]));
    let tset: Vec<i64> = trees.iter().copied().collect::<BTreeSet<i64>>().into_iter().collect();
    let items: Vec<String> = prices.iter().map(|(n, p)| format!("{} {}p", n, p)).collect();
    println!("basket: {}", items.join(", "));
    println!("fold with +, from 0, left to right: {}p = £{}.{:02}", total, total / 100, total % 100);
    let run: Vec<String> = (1..5).map(|k| fold(add, 0, &pence[..k]).to_string()).collect();
    println!("running total: {}", run.join(", "));
    println!("all {} bracketings give: {:?}; with one more item, {} bracketings", trees.len(), tset,
             brackets(add, &[pence.clone(), vec![195]].concat()).len());
    println!("two tills: {} + {} = {}", till_a, till_b, till_a + till_b);
    println!("empty basket folds to the identity: {}", fold(add, 0, &[]));
    let mut sample = pence.clone();
    sample.extend([0, 1000]);
    println!("laws hold for +, 0 on {}^3 triples: {}", sample.len(), yn(monoid(add, 0, &sample)));
    println!("laws hold for max, 0: {}; dearest item {}p", yn(monoid(big, 0, &sample)), fold(big, 0, &pence));
    let words: Vec<String> = ["", "LS", "1", "M6"].iter().map(|w| w.to_string()).collect();
    println!("laws hold for joining text, '': {}", yn(monoid(join, String::new(), &words)));
    let undo: Vec<i64> = (0..=1000).filter(|q| big(&375, q) == 0).collect();
    println!("+ has undos (249 + -249 = {}); max undo for 375 among 0..1000: {}", 249 + -249, undo.len());
    let subs = brackets(sub, &pence);
    let sset: Vec<i64> = subs.iter().copied().collect::<BTreeSet<i64>>().into_iter().collect();
    println!("minus, left to right: {}; right to left: {}", subs[subs.len() - 1], subs[0]);
    println!("minus over {} bracketings: {} different answers {:?}", subs.len(), sset.len(), sset);
    let mean_all = total as f64 / 4.0;
    let mean_of_means = (till_a as f64 / 3.0 + till_b as f64 / 1.0) / 2.0;
    println!("mean price {:.2}p; mean of the two tills' means {:.2}p", mean_all, mean_of_means);
    let ones = |xs: &[i64]| -> Vec<(i64, i64)> { xs.iter().map(|&p| (p, 1)).collect() };
    let (s, c) = fold(pair, (0, 0), &ones(&pence));
    let (s1, c1) = fold(pair, (0, 0), &ones(&pence[..3]));
    let (s2, c2) = fold(pair, (0, 0), &ones(&pence[3..]));
    println!("fold (sum, count): ({}, {}) = {:.2}p; two tills ({}, {}) + ({}, {})",
             s, c, s as f64 / c as f64, s1, c1, s2, c2);
    println!("start + at 1 instead of 0: one till {}, two tills {}", fold(add, 1, &pence),
             fold(add, 1, &pence[..3]) + fold(add, 1, &pence[3..]));

    let chain = |order: &str| -> M {
        let mut m = unit(order);
        for t in &steps { m = bind(&m, &|k| look(t, k)) }
        m
    };
    let nested = |o: &str| -> String { // the second road: plain nested ifs
        if !orders.contains_key(o) { return "stops at step 1".to_string() }
        if !customers.contains_key(&orders[o]) { return "stops at step 2".to_string() }
        if !zones.contains_key(&customers[&orders[o]]) { return "stops at step 3".to_string() }
        format!("just {}", charges[&zones[&customers[&orders[o]]]])
    };
    let ids = ["1001", "1002", "1003", "1004"];
    for o in ids { println!("order {}: chain {}; nested ifs {}", o, show(&chain(o)), nested(o)) }
    let fee: i64 = chain("1001").unwrap().parse().unwrap();
    let bill = total + fee;
    println!("order 1001 bill: {} + {} = {}p = £{}.{:02}", total, fee, bill, bill / 100, bill % 100);
    let lenient = |order: &str| -> i64 { // the mistake: a missing key read as 0, no Maybe
        let mut k = order.to_string();
        for t in &steps { k = t.get(&k).cloned().unwrap_or("0".to_string()) }
        k.parse().unwrap()
    };
    let free = lenient("1002");
    println!("order 1002 with a missing lookup read as 0: delivery {}p, bill {}p", free, total + free);
    let mut dset: BTreeSet<String> = BTreeSet::new();
    for t in &steps { for (k, v) in t { dset.insert(k.clone()); dset.insert(v.clone()); } }
    dset.insert("1004".to_string());
    let dom: Vec<String> = dset.into_iter().collect();
    let id: Table = dom.iter().map(|k| (k.clone(), k.clone())).collect(); // unit, as a table
    let mut ts = steps.clone();
    ts.push(id.clone());
    let mut ms: Vec<M> = vec![None];
    ms.extend(dom.iter().map(|a| unit(a)));
    let left = dom.iter().all(|a| ts.iter().all(|f| bind(&unit(a), &|k| look(f, k)) == look(f, a)));
    let right = ms.iter().all(|m| bind(m, &unit) == *m);
    let assoc = ms.iter().all(|m| ts.iter().all(|f| ts.iter().all(|g|
        bind(&bind(m, &|k| look(f, k)), &|k| look(g, k))
            == bind(m, &|x| bind(&look(f, x), &|k| look(g, k))))));
    println!("domain {} keys, {} Maybe values, {} steps", dom.len(), ms.len(), ts.len());
    println!("left identity: {}; right identity: {}; associativity on {} cases: {}",
             yn(left), yn(right), ms.len() * ts.len() * ts.len(), yn(assoc));
    let flat = |mm: Option<M>| -> M { match mm { None => None, Some(m) => m } }; // Maybe Maybe -> Maybe
    let fmap = |f: &Table, m: &M| -> Option<M> { match m { None => None, Some(x) => Some(look(f, x)) } };
    let via_mu = ms.iter().all(|m| ts.iter().all(|f| flat(fmap(f, m)) == bind(m, &|k| look(f, k))));
    println!("bind equals flatten after map on {} cases: {}", ms.len() * ts.len(), yn(via_mu));
    let kid = ts.iter().all(|t| kleisli(&id, t) == *t && kleisli(t, &id) == *t);
    let kas = ts.iter().all(|f| ts.iter().all(|g| ts.iter().all(|h|
        kleisli(&kleisli(f, g), h) == kleisli(f, &kleisli(g, h)))));
    println!("tables under >=>: identity {}; associativity on {} triples {}",
             yn(kid), ts.len().pow(3), yn(kas));
    let whole = fold(kleisli, id.clone(), &steps);
    let shown: Vec<String> = whole.iter().map(|(k, v)| format!("{} -> {}", k, v)).collect();
    println!("fold of the four steps with >=>, from unit: {}", shown.join(", "));
    let same = dom.iter().all(|o| show(&chain(o)) == show(&look(&whole, o)));
    println!("that one table answers every key as the chain does: {}", yn(same));
    assert!(tset == vec![total]); // every bracketing, one answer
    assert!(till_a + till_b == total && total == 833); // two tills; the hand sum
    assert!(trees.len() == 5 && sset.len() == 4 && undo.is_empty() && subs[0] != subs[subs.len() - 1]);
    assert!(s as f64 / c as f64 == mean_all && mean_of_means != mean_all);
    let got: Vec<String> = ids.iter().map(|o| show(&chain(o))).collect();
    assert!(got == vec![nested("1001"), "nothing".into(), "nothing".into(), "nothing".into()]);
    let stops: Vec<String> = ids[1..].iter().map(|o| nested(o)).collect();
    assert!(stops == vec!["stops at step 3", "stops at step 2", "stops at step 1"]);
    assert!(left && right && assoc && via_mu && kid && kas && same);
    assert!(monoid(add, 0, &sample) && monoid(big, 0, &sample) && monoid(join, String::new(), &words));
    assert!(whole == table(&[("1001", "450")]) && bill == 1283);
    assert!(lenient("1001") == fee && free == 0); // the default hides the failure
    println!("ALL CHECKS PASS");
}
