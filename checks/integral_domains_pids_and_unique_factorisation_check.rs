// Domains, principal ideals and unique factorisation -- the same check as the Python,
// in Rust.  No crates.  Fractions are an i128 pair with checked_mul, so overflow
// stops the run.  Three rings: the integers, polynomials in x over Q, and
// polynomials in x and y, where the two-letter searches run over F_3 (mod 3).
use std::collections::BTreeMap;

fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(m(a.n, b.d).checked_add(m(b.n, a.d)).expect("overflow"), m(a.d, b.d)) }
fn mulq(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }
fn divq(a: Q, b: Q) -> Q { q(m(a.n, b.d), m(a.d, b.n)) }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
type P = Vec<Q>;                                     // highest power first
fn pp(cs: &[i128]) -> P { cs.iter().map(|&c| q(c, 1)).collect() }
fn trim(mut p: P) -> P { while p.len() > 1 && p[0].n == 0 { p.remove(0); } p }
fn sub(a: &P, b: &P) -> P {
    let n = a.len().max(b.len());
    let at = |p: &P, i: usize| if i + p.len() >= n { p[i + p.len() - n] } else { q(0, 1) };
    trim((0..n).map(|i| add(at(a, i), Q { n: -at(b, i).n, d: at(b, i).d })).collect())
}
fn mul(a: &P, b: &P) -> P {
    let mut out = vec![q(0, 1); a.len() + b.len() - 1];
    for (i, &u) in a.iter().enumerate() { for (j, &v) in b.iter().enumerate() { out[i + j] = add(out[i + j], mulq(u, v)); } }
    trim(out)
}
fn is0(p: &P) -> bool { p.len() == 1 && p[0].n == 0 }
fn divmod(f: &P, g: &P) -> (P, P) {
    let mut quo = vec![q(0, 1); (f.len() as i64 - g.len() as i64 + 1).max(1) as usize];
    let mut r = f.clone();
    while !is0(&r) && r.len() >= g.len() {
        let (c, d) = (divq(r[0], g[0]), r.len() - g.len());
        let k = quo.len() - 1 - d; quo[k] = c;
        let mut t = vec![c]; t.extend(vec![q(0, 1); d]);
        r = sub(&r, &mul(&t, g));
    }
    (trim(quo), r)
}
fn join(s: &mut String, neg: bool, t: String) {
    if s.is_empty() { s.push_str(&format!("{}{}", if neg { "-" } else { "" }, t)) }
    else { s.push_str(&format!("{}{}", if neg { " - " } else { " + " }, t)) }
}
fn show(p: &P) -> String {
    let (mut s, n) = (String::new(), p.len() - 1);
    for (i, &c) in p.iter().enumerate() {
        if c.n == 0 { continue }
        let (d, a) = (n - i, Q { n: c.n.abs(), d: c.d });
        let cs = if a.n == 1 && a.d == 1 && d > 0 { String::new() } else if a.d > 1 && d > 0 { format!("({})", qs(a)) } else { qs(a) };
        let v = if d == 0 { String::new() } else if d == 1 { "x".to_string() } else { format!("x^{}", d) };
        join(&mut s, c.n < 0, cs + &v);
    }
    if s.is_empty() { "0".into() } else { s }
}
fn ev(p: &P, x: i128) -> Q { p.iter().fold(q(0, 1), |acc, &c| add(mulq(acc, q(x, 1)), c)) }
type B = BTreeMap<(u32, u32), i64>;                  // {(power of x, power of y): coefficient}
fn tidy(out: B, md: i64) -> B {
    out.into_iter().map(|(k, c)| (k, if md > 0 { c.rem_euclid(md) } else { c })).filter(|&(_, c)| c != 0).collect()
}
fn mul2(a: &B, b: &B, md: i64) -> B {
    let mut out = B::new();
    for (&(i, j), &c) in a { for (&(k, l), &e) in b { *out.entry((i + k, j + l)).or_insert(0) += c * e; } }
    tidy(out, md)
}
fn add2(a: &B, b: &B, md: i64) -> B {
    let mut out = a.clone();
    for (&k, &c) in b { *out.entry(k).or_insert(0) += c; }
    tidy(out, md)
}
fn ev2(p: &B, x: i64, y: i64) -> i64 { p.iter().map(|(&(i, j), &c)| c * x.pow(i) * y.pow(j)).sum() }
fn show2(p: &B) -> String {
    let mut s = String::new();
    for (&(i, j), &c) in p.iter().rev() {                 // lex order, x > y
        let mut mono = String::new();
        if i > 0 { mono += "x" } if i > 1 { mono += &format!("^{}", i) }
        if j > 0 { mono += "y" } if j > 1 { mono += &format!("^{}", j) }
        let t = if c.abs() != 1 || mono.is_empty() { format!("{}{}", c.abs(), mono) } else { mono };
        join(&mut s, c < 0, t);
    }
    if s.is_empty() { "0".into() } else { s }
}
fn polys(deg: u32) -> Vec<B> {                        // every polynomial over F_3 of degree <= deg
    let monos: Vec<(u32, u32)> = (0..=deg).flat_map(|i| (0..=deg - i).map(move |j| (i, j))).collect();
    let n = monos.len() as u32;
    (0..3i64.pow(n)).map(|idx| {
        let mut p = B::new();
        for (t, &mo) in monos.iter().enumerate() {
            let c = idx / 3i64.pow(n - 1 - t as u32) % 3;
            if c != 0 { p.insert(mo, c); }
        }
        p
    }).collect()
}
fn divides(h: &B, t: &B, qs_: &[B]) -> bool { qs_.iter().any(|g| mul2(h, g, 3) == *t) }
fn strs(v: &[String]) -> String { format!("[{}]", v.iter().map(|s| format!("'{}'", s)).collect::<Vec<_>>().join(", ")) }
fn b(pairs: &[((u32, u32), i64)]) -> B { pairs.iter().cloned().collect() }
fn main() {
    println!("integers: Euclid on 1071 and 462");
    let (mut a, mut bb) = (1071i64, 462i64);
    while bb != 0 { println!("{} = {} x {} + {}", a, a / bb, bb, a % bb); (a, bb) = (bb, a % bb); }
    let (mut gi, mut si, mut ti, mut r1, mut s1, mut t1) = (1071i64, 1i64, 0i64, 462i64, 0i64, 1i64);
    while r1 != 0 { let k = gi / r1; (gi, si, ti, r1, s1, t1) = (r1, s1, t1, gi - k * r1, si - k * s1, ti - k * t1); }
    println!("gcd {} = {} x 462 - {} x 1071", gi, ti, -si);
    let combos: Vec<i64> = (-30..31).flat_map(|i| (-30..31).map(move |j| i * 1071 + j * 462)).collect();
    let least = *combos.iter().filter(|&&c| c > 0).min().unwrap();
    println!("road 2: smallest positive a x 1071 + b x 462 with |a|, |b| <= 30: {}", least);
    println!("every such combination a multiple of {}: {} ({} checked)", least, yn(combos.iter().all(|c| c % least == 0)), combos.len());
    let (f, g) = (pp(&[1, -6, 11, -6]), pp(&[1, 0, -1]));
    println!("polynomials in x over Q: f = {}, g = {}", show(&f), show(&g));
    let (q1, rem1) = divmod(&f, &g); let (q2, rem2) = divmod(&g, &pp(&[1, -1]));
    println!("f = ({}) g + ({})", show(&q1), show(&rem1));
    println!("g = ({})(x - 1) + {}", show(&q2), show(&rem2));
    let (mut r0, mut s0, mut t0, mut r1, mut s1, mut t1) = (f.clone(), pp(&[1]), pp(&[0]), g.clone(), pp(&[0]), pp(&[1]));
    while !is0(&r1) {
        let (k, rr) = divmod(&r0, &r1);
        let (ns, nt) = (sub(&s0, &mul(&k, &s1)), sub(&t0, &mul(&k, &t1)));
        (r0, s0, t0, r1, s1, t1) = (r1, s1, t1, rr, ns, nt);
    }
    let lead = r0[0];
    let sc = |p: &P| -> P { p.iter().map(|&c| divq(c, lead)).collect() };
    let (h, u, v) = (sc(&r0), sc(&s0), sc(&t0));
    println!("monic gcd: {}", show(&h));
    println!("{} = u f + v g with u = {}, v = {}", show(&h), show(&u), show(&v));
    let rf: Vec<i128> = (-6..7).filter(|&x| ev(&f, x).n == 0).collect();
    let rg: Vec<i128> = (-1..2).filter(|&x| ev(&g, x).n == 0).collect();
    let shared: Vec<i128> = rf.iter().filter(|x| rg.contains(x)).cloned().collect();
    println!("road 2: rational roots of f {:?}, of g {:?}, shared {:?}", rf, rg, shared);
    let (x, y, one) = (b(&[((1, 0), 1)]), b(&[((0, 1), 1)]), b(&[((0, 0), 1)]));
    let l1 = polys(1);
    let common: Vec<String> = l1.iter().filter(|h| !h.is_empty() && divides(h, &x, &l1) && divides(h, &y, &l1)).map(show2).collect();
    println!("polynomials in x and y over F_3: the ideal <x, y>");
    println!("polynomials of degree <= 1 dividing both x and y: {}", strs(&common));
    let cs2: Vec<B> = l1.iter().flat_map(|a| l1.iter().map(|bq| add2(&mul2(a, &x, 0), &mul2(bq, &y, 0), 3)).collect::<Vec<_>>()).collect();
    println!("combinations a x + b y, a and b of degree <= 1: {}, zero at (0, 0): {}", cs2.len(), cs2.iter().filter(|p| ev2(p, 0, 0) == 0).count());
    let ff = b(&[((2, 1), 1), ((0, 3), -1)]);
    let fac = mul2(&mul2(&y, &b(&[((1, 0), 1), ((0, 1), -1)]), 0), &b(&[((1, 0), 1), ((0, 1), 1)]), 0);
    println!("unique factorisation in k[x, y]: {} = y(x - y)(x + y), expanded: {}: {}", show2(&ff), show2(&fac), yn(fac == ff));
    let (f3, l2) = (tidy(ff.clone(), 3), polys(2));
    let linear: Vec<String> = l1.iter().filter(|h| !h.is_empty() && !h.contains_key(&(0, 0))
        && *h.iter().next_back().unwrap().1 == 1 && divides(h, &f3, &l2)).map(show2).collect();
    println!("road 2: monic degree-1 divisors over F_3: {} (x - y is x + 2y mod 3)", strs(&linear));
    let zeros = (0..3).flat_map(|xx| (0..3).map(move |yy| (xx, yy))).filter(|&(xx, yy)| ev2(&ff, xx, yy) % 3 == 0).count();
    println!("road 3: zeros of {} on the 9 points of F_3^2: {} = 3 lines x 3 points - 2 repeats of (0, 0)", show2(&ff), zeros);
    println!("mistake 1, Z mod 12 has zero divisors: 3 x 4 = {}; 4 = 2 x 2 = 4 x 4 = 2 x 8: {}", 3 * 4 % 12,
             yn(2 * 2 % 12 == 4 && 4 * 4 % 12 == 4 && 2 * 8 % 12 == 4));
    let nm = |a: i64, b: i64| a * a + 5 * b * b;
    let mut small: Vec<i64> = (-3..4).flat_map(|a| (-3..4).map(move |b| nm(a, b))).filter(|n| *n == 2 || *n == 3).collect();
    small.sort(); small.dedup();
    println!("mistake 2, Z[sqrt-5]: norms 2 -> {}, 3 -> {}, 1 + sqrt-5 -> {}, 1 - sqrt-5 -> {}; {} x {} = {} = {} x {}",
             nm(2, 0), nm(3, 0), nm(1, 1), nm(1, -1), nm(2, 0), nm(3, 0), nm(2, 0) * nm(3, 0), nm(1, 1), nm(1, -1));
    println!("  elements of norm 2 or 3 (|a|, |b| <= 3): {:?}, so {}", small, if small.is_empty() { "all four are irreducible" } else { "irreducible not proved" });
    println!("mistake 3, least-degree member x taken as generator of <x, y>: y a multiple of x: {}", yn(divides(&x, &y, &l1)));
    let hits = cs2.iter().filter(|p| **p == one).count();
    println!("mistake 4, gcd(x, y) = 1 read as 1 = a x + b y: combinations equal to 1 found: {}", hits);
    assert!(gi == least && least == 21 && combos.iter().all(|c| c % 21 == 0));   // Euclid against brute force
    assert!(ti * 462 + si * 1071 == 21);                                         // Bezout, substituted back
    assert!(show(&h) == "x - 1" && shared == vec![1]);                           // gcd against shared roots
    assert!(is0(&sub(&sub(&h, &mul(&u, &f)), &mul(&v, &g))));                    // u f + v g, multiplied out
    let mut cm = common.clone(); cm.sort(); assert!(cm == ["1", "2"]);           // only units divide x and y
    assert!(hits == 0 && !divides(&x, &y, &l1));                                 // 1 and y out of reach
    let mut ln = linear.clone(); ln.sort();
    assert!(fac == ff && ln == ["x + 2y", "x + y", "y"] && zeros == 7);          // three roads agree
    assert!(small.is_empty());                                                   // no element of norm 2 or 3
    assert!(nm(2, 0) * nm(3, 0) == nm(1, 1) * nm(1, -1));                        // the norm multiplies both ways
    println!("ALL CHECKS PASS");
}
