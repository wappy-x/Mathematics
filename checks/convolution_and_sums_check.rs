// Convolution and sums -- the same check as the Python, in Rust.  No crates.
// The dart: x and y independent, each uniform on [0, 1] metres; S = x + y.
// Roads to P(S < 0.5) = 1/8: the triangle density integrated exactly, the
// corner area of the square, grids of cells convolved exactly, and simulated
// darts.  Then the numerical convolution of the two densities, two discrete
// rulers, a continuous plus a discrete reading, the algebra, and what breaks.
use std::collections::BTreeMap;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Fr { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Fr { n: s * n / g, d: s * d / g }
}
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { fr(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.n * o.n, self.d * o.d) } }
impl Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Fr { fn partial_cmp(&self, o: &Fr) -> Option<std::cmp::Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) } }
impl std::fmt::Display for Fr {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
impl Fr { fn f(self) -> f64 { self.n as f64 / self.d as f64 } }
fn maxf(a: Fr, b: Fr) -> Fr { if a < b { b } else { a } }
fn minf(a: Fr, b: Fr) -> Fr { if a < b { a } else { b } } // exact fractions by hand, on i128

type Law = BTreeMap<i64, Fr>;
fn z(n: i128) -> Fr { fr(n, 1) }

fn h_exact(s: Fr) -> Fr {
    // the triangle: s on [0, 1], 2 - s on [1, 2]
    let dist = if s < z(1) { z(1) - s } else { s - z(1) };
    maxf(z(0), z(1) - dist)
}

fn trapezoid(f: fn(Fr) -> Fr, a: Fr, b: Fr, pieces: i128) -> Fr {
    // exact when f is a straight line on each piece
    let w = (b - a) / z(pieces);
    (0..pieces).fold(z(0), |acc, i| acc + (f(a + z(i) * w) + f(a + z(i + 1) * w)) * w / z(2))
}

fn shoelace(pts: &[(Fr, Fr)]) -> Fr {
    // area of a polygon from its corners
    let n = pts.len();
    let s = (0..n).fold(z(0), |acc, i| acc + pts[i].0 * pts[(i + 1) % n].1 - pts[(i + 1) % n].0 * pts[i].1);
    (if s < z(0) { z(0) - s } else { s }) / z(2)
}

fn slide(p: &Law, q: &Law) -> Law {
    // (p * q)(k) = sum over a of p(a) q(k - a)
    let lo = p.keys().next().unwrap() + q.keys().next().unwrap();
    let hi = p.keys().last().unwrap() + q.keys().last().unwrap();
    (lo..=hi).map(|k| (k, p.iter().fold(z(0), |acc, (a, pa)| acc + *pa * *q.get(&(k - a)).unwrap_or(&z(0))))).collect()
}

fn push(p: &Law, q: &Law) -> Law {
    // law of a + b under the product law: add over pairs
    let mut out = Law::new();
    for (a, pa) in p {
        for (b, qb) in q {
            let e = out.entry(a + b).or_insert(z(0));
            *e = *e + *pa * *qb;
        }
    }
    out
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        // SplitMix64: uniform draws in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 / (1u64 << 53) as f64
    }
}

fn fmt(v: &[Fr]) -> String { v.iter().map(|x| format!("{:.2}", x.f())).collect::<Vec<_>>().join(", ") }

fn main() {
    // road 1 and road 2: the triangle density against the corner of the square
    let half = fr(1, 2);
    let r1 = trapezoid(h_exact, z(0), half, 5);
    let r2 = shoelace(&[(z(0), z(0)), (half, z(0)), (z(0), half)]);
    println!("P(S < 0.5): integral of the triangle density = {}; corner area of the square = {}", r1, r2);
    assert_eq!(r1, r2);
    let (lo, hi) = (trapezoid(h_exact, z(0), z(1), 4), trapezoid(h_exact, fr(3, 2), z(2), 5));
    let tot = trapezoid(h_exact, z(0), z(2), 8);
    println!("P(S <= 1) = {}; P(S > 1.5) = {}; P(0.5 <= S <= 1.5) = {}; total {}; peak h(1) = {}", lo, hi, z(1) - r1 - hi, tot, h_exact(z(1)));
    assert_eq!(tot, z(1));

    // road 3: cut the board into n x n cells, read each dart at its cell's midpoint,
    // and convolve the two discrete cell laws exactly
    for n in [10i64, 100, 1000] {
        let cells: Law = (0..n).map(|a| (a, z(1))).collect(); // counts; each cell has chance 1/n
        let c = slide(&cells, &cells);
        let hits = c.iter().filter(|(k, _)| 2 * (*k + 1) < n).fold(z(0), |acc, (_, v)| acc + *v); // (a + b + 1)/n < 1/2
        let nn = (n * n) as i128;
        let gap = fr(1, 8) - hits / z(nn);
        println!("grid of {} x {} cells: P(S < 0.5) = {}/{} = {:.5}; gap to 1/8 = {:.5}", n, n, hits, nn, hits.f() / nn as f64, gap.f());
        assert_eq!(gap, fr(1, 4 * n as i128));
        if n == 10 {
            let dens: Vec<Fr> = (0..2 * n - 1).map(|k| c[&k] / z(n as i128)).collect(); // chance c/n^2 over width 1/n
            println!("tenths grid, density at s = 0.1, 0.2, ..., 1.9: {}", fmt(&dens));
            assert!((0..2 * n - 1).all(|k| dens[k as usize] == h_exact(fr((k + 1) as i128, n as i128))));
        }
    }

    // the convolution integral itself, by a midpoint sum, f = g = 1 on [0, 1)
    let m = 1000;
    let h_num = |s: f64| (0..m).filter(|i| { let t = s - (*i as f64 + 0.5) / m as f64; 0.0 <= t && t < 1.0 }).count() as f64 / m as f64;
    let hn: Vec<f64> = (0..11).map(|j| h_num(j as f64 / 5.0)).collect();
    println!("midpoint convolution, m = {}, at s = 0, 0.2, ..., 2: {}", m, hn.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", "));
    assert!(hn.iter().enumerate().all(|(j, v)| (v - h_exact(fr(j as i128, 5)).f()).abs() <= 1.0 / m as f64));
    let tri: Vec<Fr> = (0..11).map(|j| h_exact(fr(j, 5))).collect();
    println!("chart, independent: {}", fmt(&tri));
    let flat: Vec<Fr> = (0..11).map(|j| if z(0) <= fr(j, 10) && fr(j, 10) <= z(1) { half } else { z(0) }).collect();
    println!("chart, y = x: {}", fmt(&flat));

    // two discrete laws: x read in tenths, y read in fifths (units: tenths of a metre)
    let p: Law = (0..10).map(|a| (a, fr(1, 10))).collect();
    let q: Law = (0..10).step_by(2).map(|b| (b, fr(1, 5))).collect();
    let pq = slide(&p, &q);
    println!("tenths + fifths, chance x 50 at 0, 1, ..., 17 tenths: {}", pq.values().map(|v| (*v * z(50)).to_string()).collect::<Vec<_>>().join(", "));
    assert_eq!(pq, push(&p, &q));
    assert_eq!(pq, slide(&q, &p));
    assert_eq!(slide(&slide(&p, &q), &p), slide(&p, &slide(&q, &p)));
    println!("slide formula = sum over pairs: yes; p * q = q * p: yes; (p * q) * p = p * (q * p): yes");

    // a continuous law plus a discrete one: x uniform, y in fifths
    let mixed = q.iter().fold(z(0), |acc, (b, qb)| acc + *qb * minf(maxf(half - fr(*b as i128, 10), z(0)), z(1)));
    println!("x uniform + y in fifths: P(S < 0.5) = 0.2 x (0.5 + 0.3 + 0.1) = {} = {:.2}", mixed, mixed.f());

    // road 4: simulated darts; and what breaks when x and y are tied together
    let (n_darts, mut g) = (200000usize, SplitMix(20260929));
    let (mut ind, mut same, mut anti, mut mix, mut mx) = (0usize, 0usize, 0usize, 0usize, 0usize);
    for _ in 0..n_darts {
        let (x, y) = (g.next(), g.next());
        ind += (x + y < 0.5) as usize;
        same += (x + x < 0.5) as usize;
        anti += (x + (1.0 - x) < 0.5) as usize;
        mix += (10.0 * x < (5 - 2 * (5.0 * y) as i64) as f64) as usize;
        mx += (x.max(y) < 0.5) as usize;
    }
    let nf = n_darts as f64;
    let se = (0.125 * 0.875 / nf).sqrt();
    println!("{} simulated darts, seed 20260929: P(S < 0.5) = {:.4} (1/8 = 0.1250, standard error {:.4})", n_darts, ind as f64 / nf, se);
    assert!((ind as f64 / nf - 0.125).abs() < 4.0 * se);
    println!("simulated, x uniform + y in fifths: {:.4} (exact 0.18)", mix as f64 / nf);
    assert!((mix as f64 / nf - mixed.f()).abs() < 4.0 * (0.18 * 0.82 / nf).sqrt());
    println!("breaks, y = 1 - x: {:.4} (the sum is always 1)", anti as f64 / nf);
    println!("breaks, y = x: {:.4} (exact 0.25)", same as f64 / nf);
    assert!((same as f64 / nf - 0.25).abs() < 4.0 * (0.25 * 0.75 / nf).sqrt());
    println!("breaks, product of CDFs F(0.5) x F(0.5) = {} is P(max < 0.5), simulated {:.4}", half * half, mx as f64 / nf);

    // the picture: metre (x, y) -> SVG (60 + 200x, 220 - 200y)
    let pt = |x: Fr, y: Fr| format!("{},{}", (z(60) + z(200) * x).f() as i64, (z(220) - z(200) * y).f() as i64);
    println!("figure, square {} to {}; corner x + y < 0.5: {} {} {}; x + y = 1: {} {}; x + y = 1.5: {} {}",
        pt(z(0), z(1)), pt(z(1), z(0)), pt(z(0), z(0)), pt(half, z(0)), pt(z(0), half),
        pt(z(0), z(1)), pt(z(1), z(0)), pt(half, z(1)), pt(z(1), half));
    println!("ALL CHECKS PASS");
}
