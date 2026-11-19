// Tropical geometry and computation -- the same check as the Python file, in Rust.
// Standard library only, no crates.  Min-plus: a (+) b = min(a, b), a (.) b = a + b.
use std::collections::{BTreeMap, BTreeSet};
type Lp = BTreeMap<i64, i64>; // a Laurent polynomial in t: exponent -> integer
type Poly = BTreeMap<Vec<i64>, u64>; // a polynomial over F_p: exponents -> coefficient
const P: u64 = 32003;
const LINE: [(f64, f64, f64); 3] = [(0.0, 0.0, 0.0), (-2.0, 1.0, 0.0), (-1.0, 0.0, 1.0)];
fn winners(x: f64, y: f64, terms: &[(f64, f64, f64)], max: bool) -> Vec<usize> {
    let v: Vec<f64> = terms.iter().map(|(c, i, j)| c + i * x + j * y).collect();
    let best = v.iter().cloned().fold(v[0], |a, b| if max { a.max(b) } else { a.min(b) });
    (0..v.len()).filter(|&k| v[k] == best).collect() }
fn ladd(fs: &[&Lp]) -> Lp {
    let mut out = Lp::new();
    for f in fs { for (e, c) in f.iter() { *out.entry(*e).or_insert(0) += c; } }
    out.into_iter().filter(|(_, c)| *c != 0).collect() }
fn lmul(f: &Lp, g: &Lp) -> Lp {
    let terms: Vec<Lp> = f.iter().flat_map(|(a, c)| g.iter().map(move |(b, d)| Lp::from([(a + b, c * d)]))).collect();
    ladd(&terms.iter().collect::<Vec<_>>()) }
fn lp(t: &[(i64, i64)]) -> Lp { t.iter().cloned().collect() }
fn show(f: &Lp) -> String { // lowest power first
    let s: String = f.iter().map(|(e, c)| format!(" {} {}t^{}", if *c < 0 { "-" } else { "+" }, if c.abs() > 1 { c.abs().to_string() } else { String::new() }, e)).collect();
    if &s[1..2] == "+" { s[3..].to_string() } else { format!("-{}", &s[3..]) } }
fn classical(x: &Lp) -> Lp { lmul(&lp(&[(1, -1)]), &ladd(&[&lp(&[(0, 1)]), &lmul(&lp(&[(-2, 1)]), x)])) }
fn pairs(v: &[(i64, i64)]) -> String { format!("[{}]", v.iter().map(|(a, b)| format!("({}, {})", a, b)).collect::<Vec<_>>().join(", ")) }
fn ints(v: &[i64]) -> String { format!("[{}]", v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ")) }
fn turns(s: &[(f64, f64)], max: bool) -> Vec<(i64, i64)> { // midpoints where the winner changes
    (0..s.len()).filter(|&k| winners(s[k].0, s[k].1, &LINE, max) != winners(s[(k + 1) % s.len()].0, s[(k + 1) % s.len()].1, &LINE, max))
        .map(|k| (((s[k].0 + s[(k + 1) % s.len()].0) as i64).div_euclid(2), ((s[k].1 + s[(k + 1) % s.len()].1) as i64).div_euclid(2))).collect() }
fn rays_of(walk: &[(i64, i64)]) -> Vec<(i64, i64)> {
    let mut r: Vec<(i64, i64)> = walk.iter().map(|(x, y)| { let g = (x - 2).abs().max((y - 1).abs()); ((x - 2).div_euclid(g), (y - 1).div_euclid(g)) }).collect();
    r.sort(); r }
fn lattice(d: i64) -> Vec<(i64, i64)> { (0..=d).flat_map(|i| (0..=d - i).map(move |j| (i, j))).collect() }
fn regions(terms: &[(f64, f64, f64)]) -> (usize, usize) { // brute force on a 161 x 161 grid, X and Y in -10..10
    let (mut seen, mut edge) = (BTreeSet::new(), BTreeSet::new());
    for u in -80..81i64 { for w in -80..81i64 {
        let k = winners((2 * u + 1) as f64 / 8.0, (2 * w + 1) as f64 / 8.0, terms, false)[0];
        seen.insert(k); if u.abs() == 80 || w.abs() == 80 { edge.insert(k); } } }
    (seen.len(), seen.difference(&edge).count()) }
fn splitmix(s: u64) -> (u64, u64) { // SplitMix64: returns the new state and a number
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31)) }
fn key(m: &[i64], lex: bool) -> Vec<i64> { if lex { m.to_vec() } else { let mut k = vec![m.iter().sum::<i64>()]; k.extend(m.iter().rev().map(|e| -e)); k } }
fn lead(f: &Poly, lex: bool) -> Vec<i64> { f.keys().max_by_key(|m| key(m, lex)).unwrap().clone() }
fn divides(n: &[i64], m: &[i64]) -> bool { m.iter().zip(n).all(|(a, b)| a >= b) }
fn powmod(mut b: u64, mut e: u64) -> u64 { let mut r = 1; while e > 0 { if e & 1 == 1 { r = r * b % P; } b = b * b % P; e >>= 1; } r }
fn monic(f: &Poly, lex: bool) -> Poly {
    let c = powmod(f[&lead(f, lex)], P - 2);
    f.iter().map(|(m, a)| (m.clone(), a * c % P)).collect() }
fn sub(f: &mut Poly, g: &Poly, c: u64, m: &[i64], n: &[i64]) { // f - c * (m / n) * g, in place
    for (mm, cc) in g {
        let k: Vec<i64> = (0..mm.len()).map(|i| mm[i] + m[i] - n[i]).collect();
        let v = (f.get(&k).cloned().unwrap_or(0) + P * P - c * cc % P) % P;
        if v != 0 { f.insert(k, v); } else { f.remove(&k); }
    } }
fn nf(f: &Poly, g: &[Poly], lex: bool) -> Poly { // the full remainder on division by G
    let (mut f, mut r) = (f.clone(), Poly::new());
    while !f.is_empty() {
        let m = lead(&f, lex);
        match g.iter().find(|h| divides(&lead(h, lex), &m)) {
            Some(h) => { let c = f[&m]; sub(&mut f, h, c, &m, &lead(h, lex)); }
            None => { let c = f.remove(&m).unwrap(); r.insert(m, c); }
        }
    }
    r }
fn groebner(fs: &[Poly], lex: bool) -> (Vec<Poly>, usize) { // Buchberger, then the reduced basis
    let mut g: Vec<Poly> = fs.iter().map(|f| monic(f, lex)).collect();
    let mut pairs: Vec<(usize, usize)> = (0..g.len()).flat_map(|j| (0..j).map(move |i| (i, j))).collect();
    let mut done = 0;
    while !pairs.is_empty() {
        let (i, j) = pairs.remove(0);
        let (a, b) = (lead(&g[i], lex), lead(&g[j], lex));
        if a.iter().zip(&b).all(|(x, y)| *x == 0 || *y == 0) { continue; } // coprime leads: skip
        let l: Vec<i64> = a.iter().zip(&b).map(|(x, y)| *x.max(y)).collect();
        let mut s = Poly::new();
        sub(&mut s, &g[i], P - 1, &l, &a); sub(&mut s, &g[j], 1, &l, &b);
        let r = nf(&s, &g, lex); done += 1;
        if !r.is_empty() { g.push(monic(&r, lex)); let n = g.len() - 1; pairs.extend((0..n).map(|k| (k, n))); }
    }
    let lts: Vec<Vec<i64>> = g.iter().map(|f| lead(f, lex)).collect();
    let keep: Vec<Poly> = (0..g.len()).filter(|&k| !(0..g.len()).any(|h| h != k && divides(&lts[h], &lts[k]) && (lts[h] != lts[k] || h < k))).map(|k| g[k].clone()).collect();
    let red = (0..keep.len()).map(|k| { let o: Vec<Poly> = (0..keep.len()).filter(|&h| h != k).map(|h| keep[h].clone()).collect(); monic(&nf(&keep[k], &o, lex), lex) }).collect();
    (red, done) }
fn monomials(n: usize, top: i64) -> Vec<Vec<i64>> { // every exponent tuple with entries 0..top
    if n == 0 { return vec![vec![]]; }
    monomials(n - 1, top).into_iter().flat_map(|m| (0..=top).map(move |e| { let mut v = m.clone(); v.push(e); v })).collect() }
fn main() {
    println!("== min-plus arithmetic ==");
    for a in -4..5i64 { for b in -4..5i64 { assert!((-4..5i64).all(|c| a + b.min(c) == (a + b).min(a + c)));
        assert!(2 * a.min(b) == (2 * a).min(a + b).min(2 * b)); } }
    println!("3 (+) 5 = {}   3 (.) 5 = {}   (x (+) y)^2 = x^2 (+) y^2 on all 81 pairs", 3.min(5), 3 + 5);
    println!("== the tropical line min(0, X - 2, Y - 1) ==");
    for (x, y) in [(1i64, 3i64), (3, 3), (3, 0), (2, 1)] {
        let names: Vec<&str> = winners(x as f64, y as f64, &LINE, false).iter().map(|&k| ["nothing", "A", "B"][k]).collect();
        println!("prices ({}, {}): costs {} -> best {}", x, y, ints(&[0, x - 2, y - 1]), names.join(" = "));
    }
    assert!(winners(2.0, 1.0, &LINE, false) == vec![0, 1, 2]);
    let q: Vec<f64> = (0..22).map(|k| (2 * k + 1) as f64 / 4.0).collect(); // half steps, offset a quarter: no ties
    let mut s: Vec<(f64, f64)> = q.iter().map(|v| (7.0, v - 4.0)).collect();
    s.extend(q.iter().map(|v| (7.0 - v, 7.0))); s.extend(q.iter().map(|v| (-4.0, 7.0 - v))); s.extend(q.iter().map(|v| (v - 4.0, -4.0)));
    let walk = turns(&s, false); let rays = rays_of(&walk);
    println!("walk round the box from (-4, -4) to (7, 7): the winner changes at {}", pairs(&walk));
    assert!(rays == vec![(-1, -1), (0, 1), (1, 0)]);
    println!("rays from (2, 1): {}  sum: ({}, {})", pairs(&rays), rays.iter().map(|r| r.0).sum::<i64>(), rays.iter().map(|r| r.1).sum::<i64>());
    let newton = [(0i64, 0i64), (1, 0), (0, 1)];
    // each edge, turned a quarter turn to the left, gives the inward normal
    let normals: Vec<(i64, i64)> = (0..3).map(|k| (newton[k].1 - newton[(k + 1) % 3].1, newton[(k + 1) % 3].0 - newton[k].0)).collect();
    let mut sn = normals.clone(); sn.sort(); assert!(sn == rays);
    println!("Newton triangle {} edges' inward normals: {}", pairs(&newton), pairs(&normals));
    println!("== classical points over Laurent series: x = t^a, then y ==");
    let mut found = BTreeSet::new();
    for a in [-1i64, 0, 1, 2, 3, 4] {
        let x = lp(&[(a, 1)]); let y = classical(&x);
        assert!(ladd(&[&lp(&[(0, 1)]), &lmul(&lp(&[(-2, 1)]), &x), &lmul(&lp(&[(-1, 1)]), &y)]).is_empty());
        let (vx, vy) = (*x.keys().next().unwrap(), *y.keys().next().unwrap()); found.insert((vx, vy));
        assert!(winners(vx as f64, vy as f64, &LINE, false).len() >= 2);
        println!("x = t^{}: y = {} -> (val x, val y) = ({}, {})", a, show(&y), vx, vy);
    }
    assert!(!found.iter().any(|(x, y)| *x == 2 && *y > 1));
    for b in [3i64, 4] {
        let x = lp(&[(2, -1), (b, 1)]); let y = classical(&x);
        let (vx, vy) = (*x.keys().next().unwrap(), *y.keys().next().unwrap());
        assert!((vx, vy) == (2, b - 1) && winners(vx as f64, vy as f64, &LINE, false) == vec![0, 1]);
        println!("x = -t^2 + t^{}: y = {} -> ({}, {}), on the upward ray: needs the cancellation", b, show(&y), vx, vy);
    }
    let off = ladd(&[&lp(&[(0, 1)]), &lmul(&lp(&[(-2, 1)]), &lp(&[(3, 1)])), &lmul(&lp(&[(-1, 1)]), &lp(&[(3, 1)]))]);
    assert!(winners(3.0, 3.0, &LINE, false) == vec![0] && *off.keys().next().unwrap() == 0);
    println!("off the line: (3, 3) has the single winner [0]; x = y = t^3 gives {} != 0", show(&off));
    println!("== a smooth tropical cubic: bounded regions = genus ==");
    for d in 1..5i64 {
        let (total, bounded) = regions(&lattice(d).iter().map(|&(i, j)| ((i * i + i * j + j * j) as f64, i as f64, j as f64)).collect::<Vec<_>>());
        let inner = lattice(d).iter().filter(|&&(i, j)| i > 0 && j > 0 && i + j < d).count();
        assert!(total == lattice(d).len() && bounded == inner && inner as i64 == (d - 1) * (d - 2) / 2);
        println!("degree {}: {} regions, {} bounded; interior lattice points {}; (d-1)(d-2)/2 = {}", d, total, bounded, inner, (d - 1) * (d - 2) / 2);
    }
    println!("== Grobner bases over F_32003: dense quadrics in n variables ==");
    let mut seed = 2026u64;
    for n in 1..5usize {
        let mut fs = vec![];
        for _ in 0..n {
            let mut f = Poly::new();
            for m in monomials(n, 2).into_iter().filter(|m| m.iter().sum::<i64>() <= 2) { let (s2, z) = splitmix(seed); seed = s2; f.insert(m, z % P); }
            fs.push(f);
        }
        for lex in [false, true] {
            let (g, done) = groebner(&fs, lex);
            let lts: Vec<Vec<i64>> = g.iter().map(|f| lead(f, lex)).collect();
            let std = monomials(n, 1 << n).iter().filter(|m| !lts.iter().any(|t| divides(t, m))).count();
            assert!(std == 1 << n); // Bezout: 2^n solutions, counted with multiplicity
            if lex { assert!(lts.iter().map(|t| t[n - 1]).max().unwrap() == 1 << n && g.len() == n && g.iter().map(|f| f.len()).sum::<usize>() == n * ((1 << n) + 1)); } // shape lemma
            else { assert!(g.iter().zip(&lts).all(|(f, t)| f.keys().all(|m| m == t || t.iter().sum::<i64>() > m.iter().sum::<i64>() || (t.iter().sum::<i64>() == m.iter().sum::<i64>() && t.iter().zip(m).filter(|(a, b)| a != b).last().map_or(false, |(a, b)| a < b))))); } // grevlex, written another way
            let top = lts.iter().map(|t| t.iter().sum::<i64>()).max().unwrap();
            println!("n = {} {:>7}: {:>2} polynomials, top degree {:>2}, {:>3} terms, {:>3} S-polynomials reduced; standard monomials {} = 2^{}",
                n, if lex { "lex" } else { "grevlex" }, g.len(), top, g.iter().map(|f| f.len()).sum::<usize>(), done, std, n);
        }
    }
    let shapes: Vec<String> = (1..6u32).map(|n| format!("({}, {}, {})", n, 1u64 << n, 1u64 << (1u64 << n))).collect();
    println!("growth shapes: n, Bezout 2^n, doubly exponential 2^(2^n): [{}]  2^10 = {}  2^20 = {}", shapes.join(", "), 1 << 10, 1 << 20);
    println!("== what breaks ==");
    println!("max instead of min: the winner changes at {} -> rays (-1, 0), (0, -1), (1, 1)", pairs(&turns(&s, true)));
    assert!(rays_of(&turns(&s, true)) == vec![(-1, 0), (0, -1), (1, 1)]);
    println!("call {{trop f = 0}} the curve: trop f(3, 3) = {}  trop f(5, 4) = {} -> a whole quarter-plane, not a line", 0.min(3 - 2).min(3 - 1), 0.min(5 - 2).min(4 - 1));
    let flat = regions(&lattice(3).iter().map(|&(i, j)| (0.0, i as f64, j as f64)).collect::<Vec<_>>()); assert!(flat == (3, 0));
    println!("cubic with every coefficient 0: only {} of 10 terms ever win, {} bounded -> the genus 1 is invisible", flat.0, flat.1);
    let reached: BTreeSet<(i64, i64)> = found.iter().filter(|p| **p != (2, 1)).map(|&(x, y)| (if x > 2 { 1 } else { -1 }, if y == 1 { 0 } else { -1 })).collect();
    println!("monomial x = t^a only: rays reached {} -> the upward ray is missed", pairs(&reached.into_iter().collect::<Vec<_>>()));
    println!("figure, vertex (2, 1); box corners (-4, -4) (7, 7); ray ends (7, 1) (2, 7) (-3, -4); Newton triangle (0, 0) (1, 0) (0, 1)");
    println!("ALL CHECKS PASS");
}
