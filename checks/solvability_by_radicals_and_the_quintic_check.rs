// Solvable by radicals -- the same check as the Python, in Rust.  No crates.
// It computes the Galois group of x^5 - x - 1 instead of quoting it: factor
// patterns mod 5 and mod 2 (Dedekind), the group those shuffles generate, and
// a count of patterns over every prime below 10,000 (Chebotarev: evidence).
use std::collections::{BTreeSet, HashMap};
type Poly = Vec<i64>;
type Perm = Vec<usize>;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn cm(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cs(a: C, b: C) -> C { C { re: a.re - b.re, im: a.im - b.im } }
fn cd(a: C, b: C) -> C { let n = b.re * b.re + b.im * b.im; cm(a, C { re: b.re / n, im: -b.im / n }) }

fn trim(mut a: Poly) -> Poly { while a.last() == Some(&0) { a.pop(); } a }
fn powmod(mut b: i64, mut e: i64, p: i64) -> i64 { let mut r = 1; while e > 0 { if e & 1 == 1 { r = r * b % p } b = b * b % p; e >>= 1 } r }
fn divmod_p(a: &Poly, b: &Poly, p: i64) -> (Poly, Poly) {    // long division mod p
    let (mut a, inv) = (trim(a.clone()), powmod(b[b.len() - 1], p - 2, p));
    let mut q = vec![0; if a.len() >= b.len() { a.len() - b.len() + 1 } else { 1 }];
    while a.len() >= b.len() {
        let (c, s) = (a[a.len() - 1] * inv % p, a.len() - b.len());
        q[s] = c;
        for (i, bi) in b.iter().enumerate() { a[s + i] = (a[s + i] - c * bi).rem_euclid(p) }
        a = trim(a);
    }
    (trim(q), a)
}
fn mul_p(a: &Poly, b: &Poly, p: i64) -> Poly {
    let mut out = vec![0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] = (out[i + j] + x * y) % p } }
    trim(out)
}
fn gcd_p(a: &Poly, b: &Poly, p: i64) -> Poly {
    let (mut a, mut b) = (a.clone(), b.clone()); while !b.is_empty() { let r = divmod_p(&a, &b, p).1; a = b; b = r } a
}
fn pattern(f: &Poly, p: i64) -> Perm {                       // degrees of the factors of f mod p
    let (mut g, mut h, mut degs, mut k) = (trim(f.iter().map(|c| c.rem_euclid(p)).collect()), vec![0, 1], vec![], 0);
    while g.len() > 1 {
        k += 1;
        if g.len() - 1 < 2 * k { degs.push(g.len() - 1); break }
        let (mut e, mut base) = (p, divmod_p(&h, &g, p).1);
        h = vec![1];
        while e > 0 {                                          // h <- h^p mod g
            if e & 1 == 1 { h = divmod_p(&mul_p(&h, &base, p), &g, p).1 }
            base = divmod_p(&mul_p(&base, &base, p), &g, p).1;
            e >>= 1;
        }
        let mut hx = h.clone();
        hx.resize(h.len().max(2), 0);
        hx[1] = (hx[1] - 1).rem_euclid(p);
        let d = gcd_p(&g, &trim(hx), p);
        for _ in 0..(d.len() - 1) / k { degs.push(k) }
        g = divmod_p(&g, &d, p).0;
    }
    degs.sort_by(|a, b| b.cmp(a));
    degs
}
fn compose(s: &Perm, t: &Perm) -> Perm { t.iter().map(|&i| s[i]).collect() }
fn inverse(s: &Perm) -> Perm { let mut o = vec![0; s.len()]; for (i, &x) in s.iter().enumerate() { o[x] = i } o }
fn closure(gens: &[Perm]) -> BTreeSet<Perm> {                // every shuffle the generators make
    let e: Perm = (0..gens[0].len()).collect();
    let (mut group, mut frontier) = (BTreeSet::from([e.clone()]), vec![e]);
    while !frontier.is_empty() {
        let new: BTreeSet<Perm> = frontier.iter().flat_map(|x| gens.iter().map(move |g| compose(g, x))).collect();
        frontier = new.into_iter().filter(|y| !group.contains(y)).collect();
        for y in &frontier { group.insert(y.clone()); }
    }
    group
}
fn peel_sizes(group: &BTreeSet<Perm>) -> Vec<usize> {       // commutator subgroup, again and again
    let (mut g, mut sizes) = (group.clone(), vec![group.len()]);
    while sizes[sizes.len() - 1] > 1 {
        let mut comms = BTreeSet::new();
        for a in &g { for b in &g { comms.insert(compose(&compose(a, b), &compose(&inverse(a), &inverse(b)))); } }
        g = closure(&comms.into_iter().collect::<Vec<_>>());
        sizes.push(g.len());
        if sizes[sizes.len() - 1] == sizes[sizes.len() - 2] { break }
    }
    sizes
}
fn cycle_type(s: &Perm) -> Perm {
    let (mut seen, mut out) = (vec![false; s.len()], vec![]);
    for i in 0..s.len() {
        let (mut n, mut j) = (0, i);
        while !seen[j] { seen[j] = true; j = s[j]; n += 1 } if n > 0 { out.push(n) }
    }
    out.sort_by(|a, b| b.cmp(a));
    out
}
fn ev(f: &[i64], x: C) -> C { f.iter().rev().fold(C { re: 0.0, im: 0.0 }, |acc, &c| { let m = cm(acc, x); C { re: m.re + c as f64, im: m.im } }) }
fn roots(f: &[i64]) -> Vec<C> {                              // Durand-Kerner: every complex root at once
    let (n, mut z, mut w) = (f.len() - 1, vec![], C { re: 1.0, im: 0.0 });
    for _ in 0..n { z.push(w); w = cm(w, C { re: 0.4, im: 0.9 }) }
    for _ in 0..200 { for i in 0..n {
        let den = (0..n).filter(|&j| j != i).fold(C { re: 1.0, im: 0.0 }, |acc, j| cm(acc, cs(z[i], z[j])));
        z[i] = cs(z[i], cd(ev(f, z[i]), den));
    } }
    z
}
fn tup(t: &[usize]) -> String {                              // Python's tuple printing
    if t.len() == 1 { format!("({},)", t[0]) } else { format!("({})", t.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
}
fn tups(ts: &[Perm]) -> String { format!("[{}]", ts.iter().map(|t| tup(t)).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn evi(f: &Poly, x: i64, p: i64) -> i64 { f.iter().rev().fold(0, |acc, &c| (acc * x + c).rem_euclid(p)) }

fn main() {
    let (f, g5): (Poly, Poly) = (vec![-1, -1, 0, 0, 0, 1], vec![-2, 0, 0, 0, 0, 1]);
    let ps: Vec<i64> = (2..10000).filter(|&p| (2..).take_while(|d| d * d <= p).all(|d| p % d != 0)).collect();
    let vals: Vec<i64> = (0..5).map(|a| evi(&f, a, 5)).collect();
    println!("1. factor patterns of x^5 - x - 1\nmod 5: {}; values at 0..4 mod 5: {:?}", tup(&pattern(&f, 5)), vals);
    let f5: Poly = f.iter().map(|c| c.rem_euclid(5)).collect();
    let quad5 = (0..5).flat_map(|b| (0..5).map(move |c| (b, c))).filter(|&(b, c)| divmod_p(&f5, &vec![c, b, 1], 5).1.is_empty()).count();
    println!("monic quadratics mod 5 dividing it, by trying all 25: {}", quad5);
    let (prod2, f2): (Poly, Poly) = (mul_p(&vec![1, 1, 1], &vec![1, 0, 1, 1], 2), f.iter().map(|c| c.rem_euclid(2)).collect());
    println!("mod 2: {}; (x^2+x+1)(x^3+x^2+1) mod 2 = {:?}, f mod 2 = {:?}", tup(&pattern(&f, 2)), prod2, f2);
    let disc = 3125 * f[0].pow(4) + 256 * f[1].pow(5);      // x^5 + a x + b: 5^5 b^4 + 4^4 a^5
    let z = roots(&f);
    let mut dn = C { re: 1.0, im: 0.0 };
    for i in 0..5 { for j in i + 1..5 { let d = cs(z[i], z[j]); dn = cm(dn, cm(d, d)) } }
    let facs: Vec<i64> = ps.iter().copied().filter(|p| disc % p == 0).collect();
    println!("discriminant: formula {}; from the five roots {:.3}; prime factors {:?}", disc, dn.re, facs);
    let real = z.iter().filter(|r| r.im.abs() < 1e-9).map(|r| r.re).fold(f64::MIN, f64::max);
    println!("square? {}; real root {:.10}", yn(((disc as f64).sqrt() as i64).pow(2) == disc), real);
    let (c5, t23): (Perm, Perm) = (vec![1, 2, 3, 4, 0], vec![1, 0, 3, 4, 2]);
    let swaps: Vec<Perm> = (0..5).flat_map(|i| (i + 1..5).map(move |j| (0..5).map(|k| if k == i { j } else if k == j { i } else { k }).collect())).collect();
    let sizes: Vec<usize> = swaps.iter().map(|t| closure(&[c5.clone(), t.clone()]).len()).collect();
    println!("2. the group the shuffles generate\na (3, 2) shuffle cubed has cycle type {}", tup(&cycle_type(&compose(&t23, &compose(&t23, &t23)))));
    println!("5-cycle with each of the 10 swaps generates: {:?}", sizes);
    let groups: Vec<(&str, Vec<Perm>)> = vec![("S3, cubic", vec![vec![1, 2, 0], vec![1, 0, 2]]),
        ("D4, x^4 - 2", vec![vec![1, 2, 3, 0], vec![0, 3, 2, 1]]), ("F20, x^5 - 2", vec![c5.clone(), vec![0, 2, 4, 1, 3]]),
        ("S5, x^5 - x - 1", vec![c5.clone(), swaps[0].clone()])];
    let peels: Vec<Vec<usize>> = groups.iter().map(|(_, gens)| peel_sizes(&closure(gens))).collect();
    for (k, (name, _)) in groups.iter().enumerate() { println!("peel sizes {}: {:?}", name, peels[k]) }
    println!("sizes of D4, its turns, its half turn, the identity: {:?}", [groups[1].1.clone(), vec![vec![1, 2, 3, 0]], vec![vec![2, 3, 0, 1]], vec![vec![0, 1, 2, 3]]].iter().map(|g| closure(g).len()).collect::<Vec<_>>());
    let good: Vec<i64> = ps.iter().copied().filter(|p| disc % p != 0).collect();
    let n = good.len();
    let (mut counts, mut shape): (HashMap<Perm, usize>, HashMap<Perm, usize>) = (HashMap::new(), HashMap::new());
    for &p in &good { *counts.entry(pattern(&f, p)).or_insert(0) += 1 }
    for s in closure(&groups[3].1) { *shape.entry(cycle_type(&s)).or_insert(0) += 1 }
    println!("3. patterns at every prime below 10,000 (evidence, not proof)\nprimes used {} ({} skipped)", good.len(), facs.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(" and "));
    let mut order: Vec<Perm> = shape.keys().cloned().collect();
    order.sort_by(|a, b| shape[b].cmp(&shape[a]).then(a.cmp(b)));
    for t in &order {
        let c = *counts.get(t).unwrap_or(&0);
        println!("pattern {:<16} {:4}  share {:.3}  S5 predicts {:3}/120 = {:.3}  {}", tup(t), c, c as f64 / n as f64, shape[t], shape[t] as f64 / 120.0, "#".repeat((c + 6) / 12));
    }
    let r19: Vec<i64> = (0..19).filter(|&a| evi(&f, a, 19) == 0 && (5 * a.pow(4) - 1).rem_euclid(19) == 0).collect();
    let lin = vec![19 - r19[0], 1]; let (q19, rem19) = divmod_p(&f.iter().map(|c| c.rem_euclid(19)).collect(), &mul_p(&lin, &lin, 19), 19);
    println!("4. what breaks\nmod 19: (x - {})^2 divides f, remainder {:?}; cofactor pattern {}: two roots merge", r19[0], rem19, tup(&pattern(&q19, 19)));
    let f20 = closure(&groups[2].1); let odd20 = f20.iter().filter(|s| (5 - cycle_type(s).len()) % 2 == 1).count();
    println!("F20 also has odd shuffles: {} of {}, yet peels {:?}", odd20, f20.len(), peels[2]);
    let seen2: Vec<Perm> = ps.iter().filter(|&&p| p != 2 && p != 5).map(|&p| pattern(&g5, p)).collect::<BTreeSet<_>>().into_iter().collect();
    let types20: Vec<Perm> = f20.iter().map(cycle_type).collect::<BTreeSet<_>>().into_iter().collect();
    println!("x^5 - 2 patterns seen: {}; F20 cycle types: {}", tups(&seen2), tups(&types20));
    let real4 = roots(&[-2, 0, 0, 0, 1]).iter().filter(|r| r.im.abs() < 1e-9).count();
    println!("Q(2^(1/4)): degree 4, roots of x^4 - 2 inside it {}, so {} automorphisms", real4, real4);
    let dd: f64 = 1.0 / 4.0 - 1.0 / 27.0; let cbrt = |x: f64| x.abs().powf(1.0 / 3.0) * if x >= 0.0 { 1.0 } else { -1.0 };
    let (u, v) = (cbrt(0.5 + dd.sqrt()), cbrt(0.5 - dd.sqrt()));
    let dk3 = roots(&[-1, -1, 0, 1]).iter().filter(|r| r.im.abs() < 1e-9).map(|r| r.re).fold(f64::MIN, f64::max);
    println!("5. the cubic x^3 - x - 1 by Cardano\nq^2/4 + p^3/27 = 23/108 = {:.10}; u = {:.10}, v = {:.10}, u*v = {:.10}", dd, u, v, u * v);
    println!("Cardano root {:.10}; Durand-Kerner root {:.10}; discriminant {}", u + v, dk3, -4 * (-1i64).pow(3) - 27 * (-1i64).pow(2));
    assert!(pattern(&f, 5) == vec![5] && quad5 == 0 && vals.iter().all(|&x| x != 0));
    assert!(pattern(&f, 2) == vec![3, 2] && prod2 == f2);
    assert!(disc == 2869 && (dn.re.round() as i64) == 2869 && facs == vec![19, 151]);
    assert!(sizes == vec![120; 10] && peels[3] == vec![120, 60, 60]);
    assert!(peels[..3].iter().all(|s| s[s.len() - 1] == 1) && rem19.is_empty() && real4 == 2);
    assert!(counts.len() == shape.len() && order.iter().all(|t| { let (o, e) = (counts[t] as f64 / n as f64, shape[t] as f64 / 120.0);
        (o - e).abs() < 3.0 * (e * (1.0 - e) / n as f64).sqrt() }));
    assert!(seen2.iter().all(|t| types20.contains(t)) && (u + v - dk3).abs() < 1e-12 && (u * v - 1.0 / 3.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
