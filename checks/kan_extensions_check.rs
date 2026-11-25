// Kan extensions -- the same check as the Python, in Rust.  No crates.
// A meter is read on days 1, 3 and 5.  F sends each reading day to the log so
// far.  An order is a category with one arrow from a to b when a <= b, so a
// functor on it is a set for each day and a map for each a <= b.  The left and
// right Kan extensions along days {1, 3, 5} -> days 1..6 are built from the
// general colimit and limit, checked against the last-or-next-reading shortcut,
// and checked by their defining property: natural maps counted on both sides.
use std::collections::BTreeMap;

type Sets = BTreeMap<i64, Vec<String>>;
type Map = Box<dyn Fn(i64, i64, &str) -> String>;
const A: [i64; 3] = [1, 3, 5];
const B: [i64; 6] = [1, 2, 3, 4, 5, 6];

fn keep(_j: i64, _k: i64, x: &str) -> String { x.to_string() } // F(j <= k): the log only grows

fn find(root: &[usize], mut e: usize) -> usize { while root[e] != e { e = root[e] } e }

fn colim(jj: &[i64], s: &Sets, fmap: &dyn Fn(i64, i64, &str) -> String) -> Vec<String> {
    // disjoint union of s[j], glued along every j <= k
    let elems: Vec<(i64, String)> = jj.iter().flat_map(|&j| s[&j].iter().map(move |x| (j, x.clone()))).collect();
    let mut root: Vec<usize> = (0..elems.len()).collect();
    for &j in jj { for &k in jj { if j < k { for x in &s[&j] {
        let a = elems.iter().position(|e| e.0 == j && &e.1 == x).unwrap();
        let b = elems.iter().position(|e| e.0 == k && e.1 == fmap(j, k, x)).unwrap();
        let ra = find(&root, a);
        root[ra] = find(&root, b);
    }}}}
    let mut cls: BTreeMap<usize, Vec<String>> = BTreeMap::new();
    for (i, e) in elems.iter().enumerate() { cls.entry(find(&root, i)).or_default().push(format!("{}/{}", e.0, e.1)) }
    let mut out: Vec<String> = cls.into_values().map(|mut c| { c.sort(); c.join("+") }).collect();
    out.sort();
    out
}

fn lim(jj: &[i64], s: &Sets, fmap: &dyn Fn(i64, i64, &str) -> String) -> Vec<String> {
    // tuples, one entry per j, that agree along every j <= k
    let mut tups: Vec<Vec<(i64, String)>> = vec![vec![]];
    for &j in jj {
        tups = tups.iter().flat_map(|t| s[&j].iter().map(move |x| { let mut u = t.clone(); u.push((j, x.clone())); u })).collect();
    }
    tups.iter().filter(|t| t.iter().all(|(j, x)| t.iter().all(|(k, y)| j >= k || fmap(*j, *k, x) == *y)))
        .map(|t| t.iter().map(|(j, x)| format!("{}/{}", j, x)).collect::<Vec<_>>().join(","))
        .map(|s| if s.is_empty() { "*".to_string() } else { s }).collect()
}

fn lan(j0: &[i64], s: &Sets, strict: bool) -> (Sets, Map) { // left extension along j0 -> B
    let mut sets = Sets::new();
    for b in B {
        let jj: Vec<i64> = j0.iter().copied().filter(|&a| a < b || (a == b && !strict)).collect();
        sets.insert(b, colim(&jj, s, &keep));
    }
    let c2 = sets.clone();
    (sets, Box::new(move |_b, c, x| { // a class at b lies in one class at c
        let first = x.split('+').next().unwrap();
        c2[&c].iter().find(|y| y.split('+').any(|p| p == first)).unwrap().clone()
    }))
}

fn ran(j0: &[i64], s: &Sets) -> (Sets, Map) { // right extension along j0 -> B
    let mut sets = Sets::new();
    for b in B {
        let jj: Vec<i64> = j0.iter().copied().filter(|&a| a >= b).collect();
        sets.insert(b, lim(&jj, s, &keep));
    }
    (sets, Box::new(|_b, c, x| { // forget the entries for days before c
        let k: Vec<&str> = x.split(',')
            .filter(|p| *p != "*" && p.split('/').next().unwrap().parse::<i64>().unwrap() >= c).collect();
        if k.is_empty() { "*".to_string() } else { k.join(",") }
    }))
}

fn funcs(x: &[String], y: &[String]) -> Vec<Vec<String>> { // every function x -> y, as image lists
    let mut out: Vec<Vec<String>> = vec![vec![]];
    for _ in x { // one more argument: every earlier function, extended by every value
        out = out.iter().flat_map(|f| y.iter().map(move |v| { let mut g = f.clone(); g.push(v.clone()); g })).collect();
    }
    out
}

fn nat(objs: &[i64], xs: &Sets, xm: &dyn Fn(i64, i64, &str) -> String,
       ys: &Sets, ym: &dyn Fn(i64, i64, &str) -> String) -> u64 { // count natural maps on a chain
    let mut ways: BTreeMap<Vec<String>, u64> = funcs(&xs[&objs[0]], &ys[&objs[0]]).into_iter().map(|f| (f, 1)).collect();
    for w in objs.windows(2) {
        let (c, d) = (w[0], w[1]);
        let mut new = BTreeMap::new();
        for g in funcs(&xs[&d], &ys[&d]) {
            let n: u64 = ways.iter().filter(|(f, _)| xs[&c].iter().enumerate().all(|(i, x)| {
                let at = xs[&d].iter().position(|z| *z == xm(c, d, x)).unwrap();
                ym(c, d, &f[i]) == g[at]
            })).map(|(_, w)| w).sum();
            if n > 0 { new.insert(g, n); }
        }
        ways = new;
    }
    ways.values().sum()
}

fn test_functor(size: fn(i64) -> i64, step: fn(i64, i64) -> i64) -> (Sets, Map) { // G from one-day steps
    let sets = B.iter().map(|&b| (b, (0..size(b)).map(|v| v.to_string()).collect())).collect();
    (sets, Box::new(move |b, c, x| { let mut v: i64 = x.parse().unwrap(); for d in b..c { v = step(d, v) } v.to_string() }))
}

fn ent(n: usize) -> String { if n == 1 { format!("{} entry", n) } else { format!("{} entries", n) } }
fn label(c: &str) -> String { c.replace(',', "+").split('+').next().unwrap().split('/').nth(1).unwrap().to_string() }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let read = |d: i64| match d { 1 => 1204, 3 => 1236, _ => 1271 }; // meter readings, kWh
    let f: Sets = A.iter().map(|&a| (a, A.iter().filter(|&&d| d <= a).map(|&d| format!("d{}:{}", d, read(d))).collect())).collect();
    let tests: Vec<(&str, (Sets, Map))> = vec![
        ("two states, held", test_functor(|_| 2, |_, v| v)),
        ("counter to 2", test_functor(|_| 3, |_, v| (v + 1).min(2))),
        ("2 states on odd days, 1 on even", test_functor(|b| 1 + b % 2, |_, _| 0))];
    let (l, lm) = lan(&A, &f, false);
    let (r, rm) = ran(&A, &f);
    println!("== the readings: F sends a reading day to the log so far ==");
    for a in A { println!("F({}) = [{}]", a, f[&a].iter().map(|s| format!("'{}'", s)).collect::<Vec<_>>().join(", ")) }
    println!("== the extensions to every day, by the colimit and limit formulas ==");
    for b in B {
        let last = *A.iter().filter(|&&a| a <= b).max().unwrap();
        let nxt: Vec<i64> = A.iter().copied().filter(|&a| a >= b).collect();
        let (mut lab_l, mut lab_r): (Vec<String>, Vec<String>) =
            (l[&b].iter().map(|c| label(c)).collect(), r[&b].iter().filter(|c| *c != "*").map(|c| label(c)).collect());
        (lab_l.sort(), lab_r.sort());
        let rs = if !nxt.is_empty() { format!("{}, newest {}", ent(r[&b].len()), lab_r.last().unwrap()) }
                 else { format!("{} point, no reading", r[&b].len()) };
        println!("day {}: left {}, newest {} | right {}", b, ent(l[&b].len()), lab_l.last().unwrap(), rs);
        assert!(lab_l == f[&last] && lab_l.len() == l[&b].len()); // shortcut: last reading
        assert!(if !nxt.is_empty() { lab_r == f[&nxt[0]] && lab_r.len() == r[&b].len() } else { r[&b] == vec!["*".to_string()] });
    }
    println!("day 0, before any reading: left {} (the empty set)", ent(colim(&[], &f, &keep).len()));
    println!("== the defining property: natural maps counted on both sides ==");
    let gk = |s: &Sets| -> Sets { A.iter().map(|&a| (a, s[&a].clone())).collect() };
    for (name, (s, m)) in &tests {
        let (l1, l2) = (nat(&B, &l, &*lm, s, &**m), nat(&A, &f, &keep, &gk(s), &**m));
        let (r1, r2) = (nat(&A, &gk(s), &**m, &f, &keep), nat(&B, s, &**m, &r, &*rm));
        println!("G = {}: Nat(Lan F, G) = {}, Nat(F, G K) = {}; Nat(G K, F) = {}, Nat(G, Ran F) = {}", name, l1, l2, r1, r2);
        assert!(l1 == l2 && r1 == r2); // the two adjunctions
    }
    println!("== limits and colimits: extend along the functor to one point ==");
    let x: Sets = A.iter().map(|&a| (a, vec!["0".to_string(), "1".to_string()])).collect();
    let (cf, lf) = (colim(&A, &f, &keep), lim(&A, &f, &keep));
    let (to2, from2) = (nat(&A, &f, &keep, &x, &keep), nat(&A, &x, &keep, &f, &keep));
    println!("colimit of F: {}; Nat(F, constant 2-set) = {} = 2^{}", ent(cf.len()), to2, cf.len());
    println!("limit of F: {}; Nat(constant 2-set, F) = {} = {}^2", ent(lf.len()), from2, lf.len());
    assert!(to2 == 1u64 << cf.len() && from2 == (lf.len() * lf.len()) as u64);
    println!("== adjoints: 3x <= y exactly when x <= floor(y/3) ==");
    let lan_id = |y: i64| (-100..101).filter(|x| 3 * x <= y).max().unwrap(); // Lan along 3x
    let ran_id = |x: i64| (-100..101i64).filter(|y| x <= y.div_euclid(3)).min().unwrap(); // Ran along floor
    println!("left extension of the identity along 3x, at y = 20: {} packs", lan_id(20));
    println!("right extension of the identity along floor(y/3), at x = 6: {} boxes", ran_id(6));
    let (ok_l, ok_r) = ((-30..31i64).all(|y| lan_id(y) == y.div_euclid(3)), (-30..31i64).all(|x| ran_id(x) == 3 * x));
    println!("equals floor(y/3) on all {} y: {}; equals 3x on all {} x: {}", 61, yn(ok_l), 61, yn(ok_r));
    assert!(ok_l && ok_r && lan_id(20) == 6 && ran_id(6) == 18);
    println!("== what breaks ==");
    let glued: usize = A.iter().map(|a| f[a].len()).sum();
    println!("glue forgotten at day 6: {}, not {}", ent(glued), l[&6].len());
    println!("agreement forgotten at day 2: {} tuples, not {}", f[&3].len() * f[&5].len(), r[&2].len());
    let (ls, lsm) = lan(&A, &f, true);
    let (tname, (s, m)) = &tests[2];
    let (n1, n2) = (nat(&B, &ls, &*lsm, s, &**m), nat(&A, &f, &keep, &gk(s), &**m));
    println!("strict a < b: day 3 gets {}, not {}; with G = {}, Nat(strict, G) = {} against Nat(F, G K) = {}",
             ent(ls[&3].len()), l[&3].len(), tname, n1, n2);
    println!("left and right swapped at day 6: {} against {} point", ent(l[&6].len()), r[&6].len());
    assert!(glued == 6 && l[&6].len() == 3 && r[&2].len() == 2 && ls[&3].len() == 1);
    assert!(n1 != n2);
    println!("ALL CHECKS PASS");
}
