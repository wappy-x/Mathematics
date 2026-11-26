// Polya counting -- the same check as the Python, in Rust.  No crates.  A move is a list: the
// corner in position i goes to position move[i].  Road one: cycles, cycle index, colours in its
// slots.  Road two: paint every pattern, list the orbits by brute force, sort them by colour.
use std::collections::{BTreeMap, BTreeSet};
type Poly = BTreeMap<Vec<usize>, usize>;
fn group(n: i64, flips: bool) -> Vec<Vec<usize>> {     // the turns of an n-sided shape, then flips
    let signs: Vec<i64> = if flips { vec![1, -1] } else { vec![1] };
    signs.iter().flat_map(|&s| (0..n).map(move |k| (0..n).map(|i| ((s * i + k) % n + n) as usize % n as usize).collect())).collect()
}
fn cycles(m: &[usize]) -> Vec<usize> {                  // cycle lengths of one move: r2 gives [2, 2]
    let (mut seen, mut out) = (vec![false; m.len()], vec![]);
    for i in 0..m.len() { let (mut j, mut n) = (i, 0);
        while !seen[j] { seen[j] = true; j = m[j]; n += 1; }
        if n > 0 { out.push(n); } }
    out
}
fn term(m: &[usize]) -> String {                        // the move's term, written like x1^2x2
    let c = cycles(m);
    let lens: BTreeSet<usize> = c.iter().cloned().collect();
    lens.iter().map(|&n| { let k = c.iter().filter(|&&x| x == n).count();
        if k > 1 { format!("x{}^{}", n, k) } else { format!("x{}", n) } }).collect()
}
fn mul(p: &Poly, q: &Poly) -> Poly {                     // multiply two polynomials in the colours
    let mut out = Poly::new();
    for (a, u) in p { for (b, v) in q { *out.entry(a.iter().zip(b).map(|(x, y)| x + y).collect()).or_insert(0) += u * v; } }
    out
}
fn fill(m: &[usize], k: usize, e: &[usize], power: bool) -> usize {   // slot xn -> y1^n + ... + yk^n,
    let mut p: Poly = [(vec![0; k], 1)].into_iter().collect();          // then the coefficient of type e
    for n in cycles(m) { p = mul(&p, &(0..k).map(|c| ((0..k).map(|d| if c != d { 0 } else if power { n } else { 1 }).collect(), 1)).collect()); }
    *p.get(e).unwrap_or(&0)
}
fn paints(n: usize, k: usize) -> Vec<Vec<usize>> { if n == 0 { return vec![vec![]]; }   // every way to paint
    paints(n - 1, k).into_iter().flat_map(|p| (0..k).map(move |c| { let mut q = p.clone(); q.push(c); q })).collect() }
fn act(m: &[usize], p: &[usize]) -> Vec<usize> { (0..m.len()).map(|j| p[m.iter().position(|&x| x == j).unwrap()]).collect() }
fn orbits(g: &[Vec<usize>], k: usize) -> BTreeSet<Vec<usize>> {
    paints(g[0].len(), k).iter().map(|p| g.iter().map(|m| act(m, p)).min().unwrap()).collect() }
fn by_type(g: &[Vec<usize>], k: usize, e: &[usize]) -> usize {
    orbits(g, k).iter().filter(|o| (0..k).map(|c| o.iter().filter(|&&x| x == c).count()).collect::<Vec<_>>() == e).count()
}
fn row(t: &str, v: &[String]) { println!("{:<22}{}", t, v.iter().map(|x| format!("{:>8}", x)).collect::<String>()); }
fn pw(k: usize, m: &[usize]) -> usize { k.pow(cycles(m).len() as u32) }
fn plus(v: &[usize], zeros: bool) -> String { v.iter().filter(|&&x| zeros || x > 0).map(|x| x.to_string()).collect::<Vec<_>>().join(" + ") }
fn index(g: &[Vec<usize>]) -> Vec<(String, usize)> {     // each term, and how many moves have it
    let ts: Vec<String> = g.iter().map(|m| term(m)).collect();
    ts.iter().enumerate().filter(|(i, s)| !ts[..*i].contains(s)).map(|(_, s)| (s.clone(), ts.iter().filter(|x| *x == s).count())).collect() }
fn zline(g: &[Vec<usize>]) -> String {
    format!("Z = ({}) / {}", index(g).iter().map(|(s, c)| if *c > 1 { format!("{} {}", c, s) } else { s.clone() }).collect::<Vec<_>>().join(" + "), g.len()) }
fn avg(v: &[usize], g: &[Vec<usize>], listed: usize) -> usize {   // Burnside's average, divided exactly
    let s: usize = v.iter().sum(); assert!(s % g.len() == 0 && s / g.len() == listed, "{:?} {}", v, listed); s / g.len() }
fn main() {
    let t = group(4, true); let terms = index(&t);
    row("move", &(0..8).map(|i| format!("r{}{}", i % 4, if i < 4 { "" } else { "f" })).collect::<Vec<_>>());
    row("its cycle term", &t.iter().map(|m| term(m)).collect::<Vec<_>>());
    for k in [2, 3] { row(&format!("k^cycles, k = {}", k), &t.iter().map(|m| pw(k, m).to_string()).collect::<Vec<_>>()); }
    println!("{}", zline(&t));
    let parts = |f: &dyn Fn(&[usize]) -> usize| -> Vec<usize> { terms.iter().map(|(s, c)| c * f(t.iter().find(|m| term(m) == *s).unwrap())).collect() };
    for k in [2, 3, 4] { let (pk, list) = (parts(&|m| pw(k, m)), orbits(&t, k).len());
        println!("k = {}: ({}) / 8 = {}; listing the orbits gives {}", k, plus(&pk, true), avg(&pk, &t, list), list); }
    let types: Vec<Vec<usize>> = [4, 3, 2, 1, 0].iter().map(|&b| vec![b, 4 - b]).collect();
    let inv: Vec<usize> = types.iter().map(|e| t.iter().map(|m| fill(m, 2, e, true)).sum()).collect();
    let (listed, two) = (types.iter().map(|e| by_type(&t, 2, e)).collect::<Vec<_>>(), parts(&|m| fill(m, 2, &[2, 2], true)));
    println!("two black corners: ({}) / 8 = {}", plus(&two, true), avg(&two, &t, by_type(&t, 2, &[2, 2])));
    row("4,3,2,1,0 black: Z", &inv.iter().zip(&listed).map(|(v, l)| avg(&[*v], &t, *l).to_string()).collect::<Vec<_>>());
    row("4,3,2,1,0 black: list", &listed.iter().map(|v| v.to_string()).collect::<Vec<_>>());
    let (h, nk, rb) = (group(6, true), group(6, false), [2, 2, 1, 1]);
    let fills = |g: &[Vec<usize>], k: usize, e: &[usize]| -> Vec<usize> { g.iter().map(|m| fill(m, k, e, true)).collect() };
    let (br, nl, bz, hc) = (fills(&h, 4, &rb), fills(&nk, 4, &rb), fills(&h, 2, &[4, 2]), h.iter().map(|m| pw(2, m)).collect::<Vec<_>>());
    println!("hexagon: {}", zline(&h));
    println!("R R B B G Y bracelets: ({}) / {} = {}, listing {}; necklaces {}, listing {}", plus(&br, false), h.len(),
             avg(&br, &h, by_type(&h, 4, &rb)), by_type(&h, 4, &rb), avg(&nl, &nk, by_type(&nk, 4, &rb)), by_type(&nk, 4, &rb));
    println!("benzene, 4 H, 2 Cl: ({}) / {} = {}, listing {}; every H/Cl mix {}, listing {}", plus(&bz, false), h.len(),
             avg(&bz, &h, by_type(&h, 2, &[4, 2])), by_type(&h, 2, &[4, 2]), avg(&hc, &h, orbits(&h, 2).len()), orbits(&h, 2).len());
    let half: usize = t.iter().map(|m| if *m != t[2] { pw(2, m) } else { 2 }).sum();   // r2 misread as one 4-cycle
    println!("mistakes: no division {}, b + w in every slot {}, half turn as x4 {}, halving the necklaces {}", t.iter().map(|m| pw(2, m)).sum::<usize>(),
             t.iter().map(|m| fill(m, 2, &[2, 2], false)).sum::<usize>() as f64 / 8.0, half as f64 / 8.0, nl.iter().sum::<usize>() / nk.len() / 2);
    for k in [2, 3] { assert!(t.iter().all(|m| pw(k, m) == paints(4, k).iter().filter(|p| act(m, p) == **p).count())); }
    assert!(inv.iter().sum::<usize>() == parts(&|m| pw(2, m)).iter().sum::<usize>());   // b = w = 1 adds the colour counts back up
    println!("ALL CHECKS PASS");
}
