// Pullbacks and pushouts -- the same check as the Python, in Rust.  No crates.
// A pullback of sets is a join of two tables on a shared key; a pushout glues
// two customer lists along a match table.  Each answer is reached by two or
// more roads: the definition row by row, a count by keys or by classes, and
// the universal property counted by brute force over every pair of maps.
use std::collections::BTreeSet;

const KEYS: [&str; 4] = ["Ana", "Ben", "Cai", "Dev"];

fn all_maps(n: usize, m: usize) -> Vec<Vec<usize>> {   // every map from n things to m things
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..n {
        out = out.iter().flat_map(|f| (0..m).map(move |v| { let mut g = f.clone(); g.push(v); g })).collect();
    }
    out
}

fn nested_loop_join<A: Copy, B: Copy>(left: &[(A, &str)], right: &[(B, &str)]) -> Vec<(A, B)> {
    let mut out = Vec::new();                          // road 1: the definition, every pair tested
    for &(a, ka) in left { for &(b, kb) in right { if ka == kb { out.push((a, b)) } } }
    out
}

fn glue(a_list: &[&str], b_list: &[&str], m: &[(&str, &str)]) -> Vec<Vec<String>> {
    let na = a_list.len();                             // pushout: union-find on the disjoint union
    let names: Vec<&str> = a_list.iter().chain(b_list.iter()).copied().collect();
    let mut parent: Vec<usize> = (0..names.len()).collect();
    fn find(p: &Vec<usize>, mut v: usize) -> usize { while p[v] != v { v = p[v] } v }
    for &(x, y) in m {
        let i = a_list.iter().position(|&s| s == x).unwrap();
        let j = na + b_list.iter().position(|&s| s == y).unwrap();
        let (ri, rj) = (find(&parent, i), find(&parent, j));
        parent[ri] = rj;
    }
    let mut out: Vec<Vec<String>> = Vec::new();
    let roots: BTreeSet<usize> = (0..names.len()).map(|v| find(&parent, v)).collect();
    for r in roots {
        let mut c: Vec<String> = (0..names.len()).filter(|&v| find(&parent, v) == r).map(|v| names[v].to_string()).collect();
        c.sort();
        out.push(c);
    }
    out.sort();
    out
}

fn maps_agreeing(a_list: &[&str], b_list: &[&str], m: &[(&str, &str)]) -> (usize, usize) {
    let mut good = 0;                                  // road 2: maps into {0, 1} that agree on S
    for u in all_maps(a_list.len(), 2) {
        for v in all_maps(b_list.len(), 2) {
            if m.iter().all(|&(x, y)| u[a_list.iter().position(|&s| s == x).unwrap()]
                == v[b_list.iter().position(|&s| s == y).unwrap()]) { good += 1 }
        }
    }
    (good, (1 << a_list.len()) * (1 << b_list.len()))
}

fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }

fn main() {
    let orders = [(1001, "Ana"), (1002, "Ben"), (1003, "Ana"), (1004, "Dev"), (1005, "Ben"), (1006, "Ana")];
    let addresses = [("Leeds", "Ana"), ("York", "Ana"), ("Hull", "Ben"), ("Bath", "Cai")];
    let shop1 = ["Ana", "Ben", "Cai", "Dev"];
    let shop2 = ["ana.k", "ben.r", "eve", "fay", "gus"];
    let matches = vec![("Ana", "ana.k"), ("Ben", "ben.r")];
    let mut faulty = matches.clone();                   // a shared household phone
    faulty.push(("Ana", "ben.r"));
    faulty.push(("Ben", "ana.k"));
    let join = nested_loop_join(&orders, &addresses);
    println!("orders {}, addresses {}, all pairs {}", orders.len(), addresses.len(), orders.len() * addresses.len());
    println!("road 1, every pair tested: {} matching rows", join.len());
    for (a, b) in &join { println!("  order {} -> {}", a, b) }
    let mut total = 0;
    for c in KEYS {                                    // road 2: group by key, multiply the counts
        let n = orders.iter().filter(|o| o.1 == c).count();
        let m = addresses.iter().filter(|o| o.1 == c).count();
        println!("road 2, key {}: {} orders x {} addresses = {}", c, n, m, n * m);
        total += n * m;
    }
    println!("road 2 total: {}", total);
    let mut pairs = 0;                                 // universal property: maps from a 2-row table T
    let mut matching: Vec<(Vec<usize>, Vec<usize>)> = Vec::new();
    for p in all_maps(2, orders.len()) {
        for q in all_maps(2, addresses.len()) {
            pairs += 1;
            if (0..2).all(|t| orders[p[t]].1 == addresses[q[t]].1) { matching.push((p.clone(), q)) }
        }
    }
    let mut jpos: Vec<(usize, usize)> = Vec::new();
    for (ia, o) in orders.iter().enumerate() {
        for (ib, d) in addresses.iter().enumerate() { if o.1 == d.1 { jpos.push((ia, ib)) } }
    }
    let through: BTreeSet<usize> = matching.iter().map(|(p, q)| all_maps(2, jpos.len()).iter()
        .filter(|h| (0..2).all(|t| jpos[h[t]] == (p[t], q[t]))).count()).collect();
    println!("pairs of maps from a 2-row table: {}; matching: {} = {} x {}", pairs, matching.len(), join.len(), join.len());
    println!("maps into the join giving each matching pair: exactly one every time: {}", yn(through == BTreeSet::from([1])));
    let pt_o: Vec<(i32, &str)> = orders.iter().map(|o| (o.0, "pt")).collect();
    let pt_a: Vec<(&str, &str)> = addresses.iter().map(|a| (a.0, "pt")).collect();
    let one_point = nested_loop_join(&pt_o, &pt_a);
    let cards = [("Ana", "Ana"), ("Ben", "Ben")];      // loyalty-card holders, a subset of the keys
    let card_rows = nested_loop_join(&orders, &cards).len();
    println!("key set of one point: {} rows, the plain product", one_point.len());
    println!("key map a subset inclusion (card holders Ana, Ben): {} rows, the orders by card holders", card_rows);
    let z4z6: Vec<(i32, i32)> = (0..4).flat_map(|x| (0..6).map(move |y| (x, y))).filter(|&(x, y)| x % 2 == y % 2).collect();
    let closed = z4z6.iter().all(|&(x1, y1)| z4z6.iter().all(|&(x2, y2)| z4z6.contains(&((x1 + x2) % 4, (y1 + y2) % 6))));
    let inverses = z4z6.iter().all(|&(x, y)| z4z6.contains(&((-x).rem_euclid(4), (-y).rem_euclid(6))));
    println!("groups: clock-4 and clock-6 over parity: {} of 24 pairs; closed under adding {}, undos inside {}",
             z4z6.len(), yn(closed), yn(inverses));
    let zipped = orders.len().min(addresses.len());
    let real = orders.iter().zip(addresses.iter()).filter(|(o, d)| o.1 == d.1).count();
    let shared: Vec<&str> = KEYS.iter().copied()
        .filter(|&c| orders.iter().any(|o| o.1 == c) && addresses.iter().any(|d| d.1 == c)).collect();
    println!("mistake, rows paired by position: {} rows, {} a real match", zipped, real);
    println!("mistake, one row per shared key: {} rows", shared.len());
    println!("mistake, no key condition: {} rows", orders.len() * addresses.len());
    for (name, m) in [("true matches", &matches), ("faulty matcher", &faulty)] {
        let cls = glue(&shop1, &shop2, m);
        let (good, tot) = maps_agreeing(&shop1, &shop2, m);
        println!("{}: {} + {} - {} = {}; classes found {}", name, shop1.len(), shop2.len(), m.len(),
                 shop1.len() + shop2.len() - m.len(), cls.len());
        let shown: Vec<String> = cls.iter().map(|c| format!("{{{}}}", c.join(", "))).collect();
        println!("  merged list: {}", shown.join(", "));
        println!("  maps into two labels agreeing on the matches: {} of {} = 2 to the {}", good, tot, cls.len());
    }
    let direct = |x: &str, y: &str| x == y || faulty.contains(&(x, y)) || faulty.contains(&(y, x));
    let broken = direct("Ana", "ana.k") && direct("ana.k", "Ben") && !direct("Ana", "Ben");
    println!("faulty, direct matches only: Ana with ana.k {}, ana.k with Ben {}, Ana with Ben {}: {}",
             yn(direct("Ana", "ana.k")), yn(direct("ana.k", "Ben")), yn(direct("Ana", "Ben")),
             if broken { "not transitive" } else { "no break in this chain" });
    assert!(join.len() == total && total == 8);                               // road 1 against road 2
    assert!(matching.len() == join.len() * join.len() && through == BTreeSet::from([1]));
    assert!(one_point.len() == 24 && card_rows == 5);
    let by_parity: usize = (0..2).map(|c| (0..4).filter(|x| x % 2 == c).count() * (0..6).filter(|y| y % 2 == c).count()).sum();
    assert!(z4z6.len() == by_parity && closed && inverses);
    let (c1, c2) = (glue(&shop1, &shop2, &matches), glue(&shop1, &shop2, &faulty));
    assert!(maps_agreeing(&shop1, &shop2, &matches).0 == 1 << c1.len() && c1.len() == 4 + 5 - 2);
    assert!(maps_agreeing(&shop1, &shop2, &faulty).0 == 1 << c2.len() && c2.len() == 6 && c2.len() != shop1.len() + shop2.len() - faulty.len());
    assert!(real == 1 && shared.len() == 2 && broken);
    println!("ALL CHECKS PASS");
}
