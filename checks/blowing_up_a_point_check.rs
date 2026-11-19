// Blowing up a point -- the same check as the Python, in Rust.  No crates.
// A curve F(x, y) = 0 over Q is a map {(i, j): c} for its terms c x^i y^j.
// Blowing up the origin in the chart y = t x turns x^i y^j into x^(i+j) t^j;
// dividing out x^m, m the lowest degree present, leaves the strict transform.
use std::collections::{BTreeMap, BTreeSet};
type P = BTreeMap<(u32, u32), i128>;

fn poly(terms: &[((u32, u32), i128)]) -> P { terms.iter().cloned().collect() }
fn ipow(a: i128, n: u32) -> i128 { (0..n).fold(1i128, |s, _| s.checked_mul(a).expect("overflow")) }

fn show(f: &P, a: &str, v: &str) -> String {      // lex order, second letter first
    let mut keys: Vec<_> = f.keys().cloned().collect();
    keys.sort_by_key(|&(i, j)| (std::cmp::Reverse(j), std::cmp::Reverse(i)));
    let mut out = String::new();
    for (i, j) in keys {
        let c = f[&(i, j)];
        let pa = if i > 1 { format!("{}^{}", a, i) } else if i == 1 { a.to_string() } else { String::new() };
        let pv = if j > 1 { format!("{}^{}", v, j) } else if j == 1 { v.to_string() } else { String::new() };
        let mono = pa + &pv;
        let mag = if c.abs() != 1 || mono.is_empty() { c.abs().to_string() } else { String::new() };
        out += if c < 0 { " - " } else { " + " };
        out += &(mag + &mono);
    }
    if &out[1..2] == "+" { out[3..].to_string() } else { format!("-{}", &out[3..]) }
}

fn add(f: &mut P, k: (u32, u32), c: i128) {
    let e = f.entry(k).or_insert(0);
    *e += c;
    if *e == 0 { f.remove(&k); }
}
fn mult(f: &P) -> u32 { f.keys().map(|&(i, j)| i + j).min().unwrap() }
fn ev(f: &P, a: i128, b: i128) -> i128 { f.iter().map(|(&(i, j), &c)| c * ipow(a, i) * ipow(b, j)).sum() }
fn swap(f: &P) -> P { f.iter().map(|(&(i, j), &c)| ((j, i), c)).collect() }
fn blow(f: &P, m: u32) -> P { f.iter().map(|(&(i, j), &c)| ((i + j - m, j), c)).collect() }
fn deriv(f: &P, k: u32) -> P {                     // k = 0: d/dx, k = 1: d/d(second letter)
    let mut d = P::new();
    for (&(i, j), &c) in f {
        let e = if k == 0 { i } else { j };
        if e > 0 { add(&mut d, (i - (1 - k), j - k), c * e as i128) }
    }
    d
}

fn shift(f: &P, r: i128) -> P {                    // F(x, t + r), by Pascal's triangle
    let mut g = P::new();
    for (&(i, j), &c) in f {
        let mut row: Vec<i128> = vec![1];
        for _ in 0..j {
            let mut next = vec![1];
            for n in 0..row.len() - 1 { next.push(row[n] + row[n + 1]) }
            next.push(1);
            row = next;
        }
        for k in 0..=j { add(&mut g, (i, k), c * row[k as usize] * ipow(r, j - k)) }
    }
    g
}

fn directions(f: &P, m: u32) -> Vec<i128> {        // integer roots t of F_m(1, t)
    let cone: P = f.iter().filter(|(&(i, j), _)| i + j == m).map(|(&(_, j), &c)| ((0, j), c)).collect();
    assert!(cone.get(&(0, m)) == Some(&1));        // monic: no vertical direction, rational roots are integers
    let h = cone.values().map(|c| c.abs()).max().unwrap() + 1;
    (-h..=h).filter(|&r| ev(&cone, 0, r) == 0).collect()
}

fn order(f: &P, r: i128) -> u32 {                 // how many times t = r is a root of F(0, t)
    let (mut c, mut k) = (f.clone(), 0);
    while ev(&c, 0, r) == 0 { c = deriv(&c, 1); k += 1; }
    k
}

fn resolve(f: &P, pad: &str) -> (u32, u32, u32) {  // blow up until smooth: (blow-ups, sum m(m-1)/2, branches)
    let m = mult(f);
    if m == 1 { return (0, 0, 1) }
    let (g, roots) = (blow(f, m), directions(f, m));
    println!("{}m = {}, strict transform {}, meets E at t = {:?}", pad, m, show(&g, "x", "t"), roots);
    let on_e: P = g.iter().filter(|(&(i, _), _)| i == 0).map(|(&k, &c)| (k, c)).collect();   // strict transform at x = 0: F_m(1, t)
    assert!(roots.iter().map(|&r| order(&on_e, r)).sum::<u32>() == m);   // all m slopes found, with repeats: none irrational
    let mut t = (1, m * (m - 1) / 2, 0);
    for r in roots {
        let s = resolve(&shift(&g, r), &format!("{}  ", pad));
        t = (t.0 + s.0, t.1 + s.1, t.2 + s.2);
    }
    t
}

fn sing(f: &P, p: i128) -> Vec<(i128, i128)> {     // points over F_p where F and both slopes vanish
    let (dx, dy) = (deriv(f, 0), deriv(f, 1));
    let mut out = vec![];
    for a in 0..p { for b in 0..p {
        if [f, &dx, &dy].iter().all(|q| ev(q, a, b).rem_euclid(p) == 0) { out.push((a, b)) }
    } }
    out
}
fn count(f: &P, p: i128) -> usize { (0..p).flat_map(|a| (0..p).map(move |b| (a, b))).filter(|&(a, b)| ev(f, a, b).rem_euclid(p) == 0).count() }
fn pmul(a: &BTreeMap<u32, i128>, b: &BTreeMap<u32, i128>) -> BTreeMap<u32, i128> {
    let mut c = BTreeMap::new();
    for (&i, &u) in a { for (&j, &w) in b { *c.entry(i + j).or_insert(0) += u * w } }
    c.into_iter().filter(|&(_, v)| v != 0).collect()
}
fn ppow(a: &BTreeMap<u32, i128>, n: u32) -> BTreeMap<u32, i128> {
    (0..n).fold([(0u32, 1i128)].into_iter().collect(), |s, _| pmul(&s, a))
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let f = poly(&[((0, 2), 1), ((3, 0), -1), ((2, 0), -1)]);   // the nodal cubic y^2 = x^2(x + 1)
    let m = mult(&f);
    let g = blow(&f, m);
    println!("curve {} = 0 over Q; multiplicity at (0, 0): m = {}", show(&f, "x", "y"), m);
    println!("chart y = t x: F(x, t x) = x^{} * ({})", m, show(&g, "x", "t"));
    let roots = directions(&f, m);
    println!("strict transform meets E (x = 0) at t = {:?}, the two tangent slopes", roots);
    for &r in &roots {
        println!("  at (0, {}): gradient ({}, {}), not zero: smooth", r, ev(&deriv(&g, 0), 0, r), ev(&deriv(&g, 1), 0, r));
    }
    let g2 = blow(&swap(&f), m);                                  // chart x = s y: letters (s, y)
    let on_e: Vec<i128> = (-2..3).filter(|&s| ev(&g2, 0, s) == 0).collect();
    println!("chart x = s y: strict transform {}; on E (y = 0) s = {:?}, so s = 1/t; vertical s = 0 gives {}",
             show(&swap(&g2), "s", "y"), on_e, ev(&g2, 0, 0));
    let (xp, yp): (BTreeMap<u32, i128>, BTreeMap<u32, i128>) =   // road 2: lines y = t x through the node
        ([(2, 1), (0, -1)].into_iter().collect(), [(3, 1), (1, -1)].into_iter().collect());
    let mut sub: BTreeMap<u32, i128> = BTreeMap::new();
    for (&(i, j), &c) in &f {
        for (k, w) in pmul(&ppow(&xp, i), &ppow(&yp, j)) { *sub.entry(k).or_insert(0) += c * w }
    }
    sub.retain(|_, w| *w != 0);
    let upoly = |q: &BTreeMap<u32, i128>| -> P { q.iter().map(|(&i, &c)| ((i, 0), c)).collect() };
    let over: Vec<i128> = (-3..4).filter(|&t| ev(&upoly(&xp), t, 0) == 0 && ev(&upoly(&yp), t, 0) == 0).collect();
    println!("road 2: x = t^2 - 1, y = t^3 - t; F(x(t), y(t)) has {} nonzero coefficients; parameters at the node t = {:?}",
             sub.len(), over);
    let (p, gp) = (7i128, blow(&f, 2));                           // road 3: count over F_7
    let image: BTreeSet<(i128, i128)> = (0..p).flat_map(|a| (0..p).map(move |b| (a, b)))
        .filter(|&(a, b)| ev(&gp, a, b).rem_euclid(p) == 0).map(|(a, b)| (a, a * b % p)).collect();
    println!("over F_{}: curve {} points, singular {:?}; strict transform {} points, singular {:?}; image of (x, t) -> (x, t x): {} points",
             p, count(&f, p), sing(&f, p), count(&gp, p), sing(&gp, p), image.len());
    println!("resolving, chart by chart:");
    let chains: Vec<(&str, P)> = vec![("node", f.clone()), ("cusp", poly(&[((0, 2), 1), ((3, 0), -1)])),
        ("tacnode", poly(&[((0, 2), 1), ((4, 0), -1), ((5, 0), -1)])), ("y^2 = x^5", poly(&[((0, 2), 1), ((5, 0), -1)])),
        ("triple point", poly(&[((0, 3), 1), ((2, 1), -1), ((4, 0), 1)]))];
    let mut results = vec![];
    for (name, c) in &chains {
        println!("{}: {}", name, show(c, "x", "y"));
        let r = resolve(c, "  ");
        println!("  -> blow-ups {}, sum of m(m - 1)/2 = {}, branches {}", r.0, r.1, r.2);
        results.push(r);
    }
    println!("genus of the nodal cubic: (3 - 1)(3 - 2)/2 - sum = 1 - {} = {}", results[0].1, 1 - results[0].1 as i32);
    let t = poly(&[((2, 2), 1), ((3, 0), -1), ((2, 0), -1)]);
    let once = poly(&[((1, 2), 1), ((2, 0), -1), ((1, 0), -1)]);
    let smooth_pt = swap(&shift(&swap(&f), -1));                  // F moved so (-1, 0) sits at the origin
    let k = poly(&[((0, 2), 1), ((3, 0), -1), ((2, 0), -2)]);
    println!("mistake 1, keep the total transform {}: {} singular points over F_7", show(&t, "x", "t"), sing(&t, 7).len());
    println!("mistake 2, divide by x once, {}: {} singular points over F_7", show(&once, "x", "t"), sing(&once, 7).len());
    println!("mistake 3, blow up the smooth point (-1, 0): m = {}; node still singular: {}", mult(&smooth_pt), yn(sing(&f, 7).contains(&(0, 0))));
    println!("mistake 4, {} over Q: rational points over the node {:?}; slopes are +-{:.11}", show(&k, "x", "y"), directions(&k, 2), 2f64.sqrt());
    let q = 11;
    println!("over F_{}: curve {} points, strict transform {} points", q, count(&f, q), count(&blow(&f, 2), q));
    let (a, b) = (3i128, 2i128);                                  // figure: the parameter t = a/b = 3/2 ends both drawings
    let (xe, ye) = (format!("{}/{}", a * a - b * b, b * b), format!("{}/{}", ipow(a, 3) - a * b * b, ipow(b, 3)));
    println!("figure, node (0, 0); loop end (-1, 0); arm ends ({xe}, -{ye}), ({xe}, {ye}); over the node (0, -1), (0, 1); parabola ends ({xe}, -{a}/{b}), ({xe}, {a}/{b})");
    assert!(g == poly(&[((0, 2), 1), ((1, 0), -1), ((0, 0), -1)]) && roots == vec![-1, 1]);
    assert!(sub.is_empty() && over == vec![-1, 1]);
    assert!(count(&f, 7) == image.len() && image.len() == count(&gp, 7) - 1 && sing(&gp, 7).is_empty() && sing(&f, 7) == vec![(0, 0)]);
    assert!(results == vec![(1, 1, 2), (1, 1, 1), (2, 2, 2), (2, 2, 1), (1, 3, 3)]);
    assert!(sing(&t, 7).len() == 7 && sing(&once, 7).len() == 2 && directions(&k, 2).is_empty());
    println!("ALL CHECKS PASS");
}
