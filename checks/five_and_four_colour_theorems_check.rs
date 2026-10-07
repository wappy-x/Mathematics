// Five and four colour theorems -- the same check as the Python, in Rust.  No crates.  The map is 12
// council wards: the centre A, the ring B C D E F round it, the outer ring G H I J K L, each ward's
// neighbours listed both ways round.  Four colours are reached three ways -- the six-colour peel run
// as a program, by hand in alphabetical order, and an exhaustive search that also settles three --
// then the Kempe swap is run on the five-colour proof's hard case.
use std::collections::{BTreeMap, BTreeSet};
type G = BTreeMap<char, Vec<char>>;
type Col = BTreeMap<char, i64>;
const WARDS: [(char, &str); 12] = [('A', "BCDEF"), ('B', "ACFGL"), ('C', "ABDGHI"), ('D', "ACEIJ"),
    ('E', "ADFJK"), ('F', "ABEKL"), ('G', "BCHL"), ('H', "CGI"), ('I', "CDHJ"), ('J', "DEIK"),
    ('K', "EFJL"), ('L', "BFGK")];
const RING: &str = "BCDEF"; const OUT: &str = "GHIJKL";
// the colours 1 to k no neighbour of v wears
fn free(g: &G, col: &Col, v: char, k: i64) -> Vec<i64> { (1..=k).filter(|c| !g[&v].iter().any(|u| col.get(u) == Some(c))).collect() }
// no border with one colour on both sides
fn proper(g: &G, col: &Col) -> bool { g.iter().all(|(u, ns)| ns.iter().all(|v| col.get(u).is_none() || col.get(v).is_none() || col[u] != col[v])) }
fn greedy(g: &G, order: &str, col: &Col) -> Col {           // each ward in turn takes its lowest free colour
    let mut col = col.clone();
    for v in order.chars() { let c = free(g, &col, v, 9)[0]; col.insert(v, c); }
    col
}
fn peel(g: &G) -> Vec<String> {                             // lift out the least busy ward, over and over
    let (mut left, mut out) = (g.clone(), Vec::new());
    while !left.is_empty() {
        let v = *left.iter().min_by_key(|(u, ns)| (ns.len(), **u)).unwrap().0;   // ties go to the earlier letter
        out.push(format!("{}{}", v, left[&v].len()));
        left = left.iter().filter(|(a, _)| **a != v).map(|(a, ns)| (*a, ns.iter().copied().filter(|b| *b != v).collect())).collect();
    }
    out
}
fn count(g: &G, k: i64, col: &Col) -> i64 {                 // how many proper colourings with k colours
    match g.keys().find(|v| !col.contains_key(v)) {         // the first ward still uncoloured
        None => 1,
        Some(&v) => free(g, col, v, k).iter().map(|&c| { let mut n = col.clone(); n.insert(v, c); count(g, k, &n) }).sum() } }
fn chain(g: &G, col: &Col, v: char, a: i64, b: i64) -> String {   // the wards reached from v through colours a and b
    let (mut seen, mut stack) = (BTreeSet::from([v]), vec![v]);
    while let Some(u) = stack.pop() {
        for w in g[&u].clone() { if !seen.contains(&w) && [Some(&a), Some(&b)].contains(&col.get(&w)) { seen.insert(w); stack.push(w); } }
    }
    seen.iter().collect()
}
// trade colours a and b all along one chain
fn swap(col: &Col, comp: &str, a: i64, b: i64) -> Col { col.iter().map(|(v, &c)| (*v, if !comp.contains(*v) { c } else if c == a { b } else if c == b { a } else { c })).collect() }
fn show(col: &Col) -> String { col.iter().map(|(v, c)| format!("{}{}", v, c)).collect::<Vec<String>>().join(" ") }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn main() {
    let map: G = WARDS.iter().map(|(v, ns)| (*v, ns.chars().collect())).collect();
    let (none, deg): (Col, Col) = (BTreeMap::new(), map.iter().map(|(v, ns)| (*v, ns.len() as i64)).collect());
    let (nv, ne) = (map.len() as i64, deg.values().sum::<i64>() / 2);   // lines counted once
    let peeled = peel(&map);   // the lifting order, each ward with the borders it still had
    let order: String = peeled.iter().rev().map(|p| p.chars().next().unwrap()).collect();   // put back in reverse
    let (back, hand) = (greedy(&map, &order, &none), greedy(&map, "ABCDEFGHIJKL", &none));
    let (rev, counts) = (greedy(&map, "LKJIHGFEDCBA", &none), (1..=4).map(|k| count(&map, k, &none)).collect::<Vec<i64>>());
    let fewest = (1..=4).find(|&k| counts[k as usize - 1] > 0).unwrap();   // the chromatic number, road 3
    let seed: Col = RING.chars().enumerate().map(|(i, v)| (v, i as i64 + 1)).collect();   // the ring in five colours
    let hard = greedy(&map, OUT, &seed);   // the outer ring filled in round it, still no colour for A
    let (kch, bad) = (chain(&map, &hard, 'B', 1, 3), chain(&map, &hard, 'B', 1, 2));   // the good pair, then the bad
    let (fixed, badfix) = (swap(&hard, &kch, 1, 3), swap(&hard, &bad, 1, 2));
    let mut five = fixed.clone(); five.insert('A', free(&map, &fixed, 'A', 5)[0]);   // A takes the freed colour
    let swapped: Col = kch.chars().map(|v| (v, fixed[&v])).collect();   let (used, inks) = (|c: &Col| *c.values().max().unwrap(), |c: &Col| c.values().collect::<BTreeSet<&i64>>().len());
    println!("the ward map: V = {} wards, E = {} borders, at most 3V - 6 = {}; borders per ward {}, adding to {} = 2E, at most 6V - 12 = {}, fewest {}, average {:.2}",
             nv, ne, 3 * nv - 6, show(&deg), 2 * ne, 6 * nv - 12, deg.values().min().unwrap(), 2.0 * ne as f64 / nv as f64);
    println!("road 1, lift out the least busy ward over and over: {}; most borders at a lift {}, the promise is 5\n  put them back in reverse, lowest free colour each time: {}, colours used {}, proper: {}",
             peeled.join(" "), peeled.iter().map(|p| p[1..].parse::<i64>().unwrap()).max().unwrap(), show(&back), used(&back), yn(proper(&map, &back)));
    println!("road 2, by hand A to L, lowest free colour: {}, colours used {}, proper: {}", show(&hand), used(&hand), yn(proper(&map, &hand)));
    println!("road 3, exhaustive: proper colourings with 1, 2, 3, 4 colours: {:?}; fewest colours that work {}", counts, fewest);
    println!("the hard case, A lifted out and its ring given five colours: {}; colours free for A: {}\n  the {} ring wards all bordering each other would need {} lines, past the {} a flat drawing on {} dots allows",
             show(&hard), free(&map, &hard, 'A', 5).len(), RING.len(), RING.len() * (RING.len() - 1) / 2, 3 * RING.len() - 6, RING.len());
    println!("  the 1-and-3 chain from B: {}; does it reach D, wearing 3: {}\n  swap 1 and 3 along it: {}, whole map still proper: {}, colours free for A: {:?}",
             kch, yn(kch.contains('D')), show(&swapped), yn(proper(&map, &fixed)), free(&map, &fixed, 'A', 5));
    println!("five colours over the whole map: {}, proper: {}, colours used {}", show(&five), yn(proper(&map, &five)), inks(&five));
    println!("mistake 1, three colours on this map: {} of {} shadings proper\nmistake 2, the swap run on the neighbours B and C: the 1-and-2 chain {} takes C along, colours free for A still {}",
             counts[2], 3i64.pow(nv as u32), bad, free(&map, &badfix, 'A', 5).len());
    println!("mistake 3, colouring L back to A instead: {}, colours used {}", show(&rev), used(&rev));
    assert!(*deg.values().min().unwrap() <= 5 && ne <= 3 * nv - 6 && map.iter().all(|(v, ns)| ns.iter().all(|u| map[u].contains(v))));
    assert!(proper(&map, &hand) && proper(&map, &back) && used(&hand) == 4 && counts[2] == 0 && counts[3] > 0);
    assert!(!kch.contains('D') && proper(&map, &fixed) && free(&map, &fixed, 'A', 5) == vec![1] && proper(&map, &five) && inks(&five) == 5);
    assert!(bad.contains('C') && free(&map, &badfix, 'A', 5).is_empty() && used(&rev) == 5 && fewest == used(&hand));
    println!("ALL CHECKS PASS");
}
