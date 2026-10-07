// Caratheodory's extension theorem -- the same check as the Python, in Rust.
// No crates.  Durations are exact rationals, written out by hand on i128.  A
// shift is a half-open stretch of hours [a, b), and the premeasure gives each
// its duration.  Same roads, same rows, same labels as the Python.
use std::cmp::Ordering;
use std::collections::BTreeSet;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, Debug)]
struct R(i128, i128);                                // numerator, denominator > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i128, d: i128) -> R {
    let (g, s) = (gcd(n, d).max(1), if d < 0 { -1 } else { 1 });
    R(s * n / g, s * d / g)
}
fn ri(n: i128) -> R { R(n, 1) }
fn p2(k: i32) -> R { if k >= 0 { R(1 << k, 1) } else { R(1, 1 << -k) } }   // 2 to the power k
impl Add for R { type Output = R; fn add(self, o: R) -> R { r(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for R { type Output = R; fn sub(self, o: R) -> R { r(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for R { type Output = R; fn mul(self, o: R) -> R { r(self.0 * o.0, self.1 * o.1) } }
impl Div for R { type Output = R; fn div(self, o: R) -> R { r(self.0 * o.1, self.1 * o.0) } }
impl PartialEq for R { fn eq(&self, o: &R) -> bool { self.0 * o.1 == o.0 * self.1 } }
impl Eq for R {}
impl PartialOrd for R { fn partial_cmp(&self, o: &R) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for R { fn cmp(&self, o: &R) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl std::fmt::Display for R {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) }
    }
}
type Iv = (R, R);

fn dur(p: &[Iv]) -> R { p.iter().fold(ri(0), |s, &(a, b)| s + (b - a)) }   // the premeasure
fn merge(p: &[Iv]) -> Vec<Iv> {                      // the same set as few shifts as possible
    let mut v = p.to_vec();
    v.sort();
    let mut out: Vec<Iv> = Vec::new();
    for (a, b) in v {
        if let Some(last) = out.last_mut() {
            if a <= last.1 { last.1 = last.1.max(b); continue; }
        }
        out.push((a, b));
    }
    out
}
fn inter(p: &[Iv], q: &[Iv]) -> Vec<Iv> {            // intersection of two finite unions
    let mut out = Vec::new();
    for &(a, b) in p { for &(c, d) in q { if a.max(c) < b.min(d) { out.push((a.max(c), b.min(d))) } } }
    out
}
fn comp(q: &[Iv]) -> Vec<Iv> {                       // complement inside the day [0, 24)
    let (mut out, mut x) = (Vec::new(), ri(0));
    for (a, b) in merge(q) { if x < a { out.push((x, a)) } x = x.max(b) }
    if x < ri(24) { out.push((x, ri(24))) }
    out
}
fn split(a: i128, b: i128, n: i32) -> Vec<Iv> {      // [a, b) cut into halves of what is left
    let cuts: Vec<R> = (0..=n).map(|k| ri(b) - ri(b - a) * p2(-k)).collect();
    (0..n as usize).map(|k| (cuts[k], cuts[k + 1])).collect()
}
fn fmt2(x: R) -> String {                            // exact rational to two decimals, halves up
    let y = x * ri(100) + r(1, 2);
    let q = y.0.div_euclid(y.1);
    format!("{}.{:02}", q / 100, q % 100)
}
fn num(x: R) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{}", x.0 as f64 / x.1 as f64) } }
fn burst(k: i32) -> Iv { let s = ri(24) - p2(1 - k); (s, s + p2(-(k + 1))) }
fn in_pager(t: f64) -> bool {                        // float road: find t's slot, then its half
    let mut k = 1;
    while t >= 24.0 - 0.5f64.powi(k) && k < 60 { k += 1 }
    t < 24.0 - 2.0 * 0.5f64.powi(k) + 0.5f64.powi(k + 1)
}
fn splitmix(s: u64) -> (u64, u64) {                  // SplitMix64, written out
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn iv(a: i128, b: i128) -> Iv { (ri(a), ri(b)) }
fn join(v: &[R]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    let (early, late, night) = (iv(6, 14), iv(14, 22), iv(22, 30));
    println!("shift durations: early {}, late {}, night {} hours", dur(&[early]), dur(&[late]), dur(&[night]));
    let (one_way, other_way) = (dur(&[early, late]), dur(&merge(&[early, late])));
    println!("early and night together: {}; [6, 22) as two shifts {}, as one {}", dur(&[early, night]), one_way, other_way);
    let cut8 = split(6, 14, 30);
    let sums: Vec<R> = (1..=6).map(|n| dur(&cut8[..n])).collect();
    println!("early shift cut into halves of what is left, sums after 1..6 pieces: {}", join(&sums));
    println!("left over after 30 pieces: {} hours", ri(8) - dur(&cut8));
    for n in [1, 10, 100, 1000] {
        println!("cover n={}: instant 14 inside [14, 14 + 1/n) -> {}; closed [6, 14] inside [6, 14 + 1/n) -> {}",
                 n, dur(&[(ri(14), ri(14) + r(1, n))]), dur(&[(ri(6), ri(14) + r(1, n))]));
    }
    let mins = |f: &dyn Fn(i32) -> R| (1..=5).map(|k| num(ri(60) * f(k))).collect::<Vec<_>>().join(", ");
    println!("first five bursts, minutes long: {}; starting at minute {}",
             mins(&|k| dur(&[burst(k)])), mins(&|k| burst(k).0 - ri(23)));
    let inner: Vec<R> = (0..=40).map(|n| dur(&(1..=n).map(burst).collect::<Vec<_>>())).collect();
    let outer: Vec<R> = (0..=40).map(|n| inner[n as usize] + dur(&[(ri(24) - p2(-n), ri(24))])).collect();
    for n in 1..=6 {
        println!("chart, n={}: inner {} min, outer {} min", n, fmt2(ri(60) * inner[n]), fmt2(ri(60) * outer[n]));
    }
    let geometric = r(1, 4) / (ri(1) - r(1, 2));     // first burst 1/4 hour, each next half as long
    println!("pager set: geometric sum {} hour = {} min; after 40 bursts the gap is {}",
             geometric, ri(60) * geometric, outer[40] - inner[40]);
    let seed = 20260929u64;
    let (mut state, mut hits, big_n) = (seed, 0u64, 200000u64);
    for _ in 0..big_n {
        let (s, z) = splitmix(state);
        state = s;
        if in_pager(23.0 + (z >> 11) as f64 / 2f64.powi(53)) { hits += 1 }
    }
    let minutes = (60 * hits) as f64 / big_n as f64;
    let tol = 4.0 * 60.0 * (0.25 / big_n as f64).sqrt();                     // four standard errors
    println!("random sample, {} times in [23, 24), seed {}: {} hits, {:.3} min, allowed {:.3}", big_n, seed, hits, minutes, tol);
    let atoms = [iv(0, 6), iv(6, 14), iv(14, 22), iv(22, 24)];
    let algebra: Vec<Vec<Iv>> = (0..16).map(|m| (0..4).filter(|i| m >> i & 1 == 1).map(|i| atoms[i]).collect()).collect();
    let outer_fin = |p: &[Iv]| atoms.iter().filter(|at| !inter(p, &[**at]).is_empty()).fold(ri(0), |s, at| s + dur(&[*at]));
    let mut tests = algebra.clone();
    for t in [vec![iv(0, 3)], vec![iv(3, 6)], vec![iv(5, 15)], vec![iv(13, 23)], vec![iv(1, 2), iv(20, 21)]] { tests.push(t) }
    let mut good = 0;
    for a in &algebra { for t in &tests {
        if outer_fin(&inter(t, a)) + outer_fin(&inter(t, &comp(a))) == outer_fin(t) { good += 1 }
    } }
    let (e, t) = (vec![iv(0, 3)], vec![iv(0, 6)]);
    let split_sum = outer_fin(&inter(&t, &e)) + outer_fin(&inter(&t, &comp(&e)));
    println!("small algebra from the rota's day boundaries: {} sets; criterion holds {} of {}", algebra.len(), good, 16 * tests.len());
    println!("[0, 3) is not in it: outer {}; splitting [0, 6) gives {}, not {}", outer_fin(&e), split_sum, outer_fin(&t));
    let flag = |p: &[Iv]| if merge(p).iter().any(|&(_, b)| b == ri(24)) { 1 } else { 0 };
    let cut24 = split(0, 24, 20);
    let flag_sum: i32 = cut24.iter().map(|&p| flag(&[p])).sum();
    println!("end flag: first {} halving pieces of the day score {}, the day scores {}, [0, 12) and [12, 24) score {} + {}; pieces fill 24 - {} hours",
             cut24.len(), flag_sum, flag(&[iv(0, 24)]), flag(&[iv(0, 12)]), flag(&[iv(12, 24)]), ri(24) - dur(&cut24));
    let count = |lo: i128, hi: i128, qmax: i128| -> usize {   // distinct rationals p/q in [lo, hi]
        let mut s: BTreeSet<R> = BTreeSet::new();
        for q in 1..=qmax { for p in lo * q..=hi * q { s.insert(r(p, q)); } }
        s.len()
    };
    let counts: Vec<usize> = [1, 2, 4, 8, 16].iter().map(|&q| count(6, 14, q) - 1).collect();   // drop 14 itself
    println!("rational times in [6, 14) with denominator up to 1, 2, 4, 8, 16: {:?}; doubled {:?}",
             counts, counts.iter().map(|c| 2 * c).collect::<Vec<_>>());
    let at14 = count(14, 14, 16);
    println!("instant 14: counting rational times {}, doubled {}", at14, 2 * at14);
    let nu = |p: &[Iv]| ri(2) * dur(&inter(p, &[iv(0, 6), iv(12, 18)]));
    for (name, p) in [("[0, 12)", iv(0, 12)), ("[6, 18)", iv(6, 18)), ("[0, 24)", iv(0, 24)), ("[6, 12)", iv(6, 12))] {
        println!("two measures on {}: duration {}, other {}", name, dur(&[p]), nu(&[p]));
    }
    let x = |h: i128| ri(30) + r(25, 2) * (ri(h) - ri(6));
    let z = |h: R| ri(30) + ri(300) * (h - ri(23));
    let rota: Vec<String> = [early, late, night, iv(23, 24)].iter().map(|&(a, b)| format!("{}-{}", num(x(a.0)), num(x(b.0)))).collect();
    let zoom: Vec<String> = (1..=5).map(burst).map(|(a, b)| format!("{}-{}", num(z(a)), num(z(b)))).collect();
    println!("figure, rota: {}", rota.join(", "));
    println!("figure, zoom: {}", zoom.join(", "));
    assert!((1..=6).all(|n| sums[n - 1] == ri(8) - ri(8) * p2(-(n as i32))) && one_way == other_way && one_way == ri(16));
    assert!((1..=40).all(|n| inner[n] + p2(-(n as i32 + 1)) == geometric));          // loop sum vs series
    assert!((minutes - 30.0).abs() < tol);                                              // sample vs series
    assert!(good == 16 * tests.len() && split_sum == ri(12) && split_sum != outer_fin(&t));
    assert!(flag_sum == 0 && flag(&[iv(0, 24)]) == 1 && ri(24) - dur(&cut24) == ri(24) * p2(-(cut24.len() as i32)));
    assert!(nu(&[iv(0, 12)]) == ri(12) && nu(&[iv(6, 18)]) == ri(12) && nu(&[iv(6, 12)]) != ri(6));
    println!("ALL CHECKS PASS");
}
