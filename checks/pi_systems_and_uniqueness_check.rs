// Pi-systems and Dynkin's theorem -- the same check as the Python, in Rust.
// No crates.  Exact fractions are done by hand in i128 (Q below).  Two rival
// models for tomorrow's noon temperature T, in degrees C:
//   A: T = 8 + 12*U1 + 12*U2;  B: one uniform U read backwards through F.
use std::collections::BTreeSet;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128);                        // numerator, denominator > 0, lowest terms
fn g(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { g(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let k = g(n, d) * d.signum(); Q(n / k, d / k) }
impl Q {
    fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) }
    fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) }
    fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) }
    fn le(self, o: Q) -> bool { self.0 * o.1 <= o.0 * self.1 }
    fn f(self) -> f64 { self.0 as f64 / self.1 as f64 }
}
fn z(n: i128) -> Q { Q(n, 1) }
fn cdf(t: Q) -> Q {                          // P(T <= t), exact
    let s = t.sub(z(8)).mul(q(1, 12));
    if s.le(z(0)) { z(0) } else if s.le(z(1)) { s.mul(s).mul(q(1, 2)) }
    else if s.le(z(2)) { let r = z(2).sub(s); z(1).sub(r.mul(r).mul(q(1, 2))) } else { z(1) }
}
fn dens(t: Q) -> Q {                         // the triangle under F, peak 1/12 at 20
    let v = if t.le(z(20)) { t.sub(z(8)) } else { z(32).sub(t) };
    if v.le(z(0)) { z(0) } else { v.mul(q(1, 144)) }
}
fn simpson(h: &dyn Fn(Q) -> Q, a: i128, b: i128) -> Q {    // exact on degree <= 3
    let (n, w) = (20, q(b - a, 20));
    let mut s = h(z(a)).add(h(z(b)));
    for i in 1..n { s = s.add(z(if i % 2 == 1 { 4 } else { 2 }).mul(h(z(a).add(w.mul(z(i)))))); }
    s.mul(w).mul(q(1, 3))
}
struct Mix(u64);                             // SplitMix64, uniform in [0, 1)
impl Mix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn model_b(u: f64) -> f64 { if u < 0.5 { 8.0 + 12.0 * (2.0 * u).sqrt() } else { 32.0 - 12.0 * (2.0 * (1.0 - u)).sqrt() } }
fn closure(gens: &[u32], full: u32, sigma: bool) -> BTreeSet<u32> {    // smallest lambda- or sigma-system
    let mut s: BTreeSet<u32> = gens.iter().cloned().collect();
    s.insert(full);
    loop {
        let mut new = BTreeSet::new();
        for &a in &s { for &b in &s {
            if a & b == a { new.insert(b & !a); }                 // proper differences
            if sigma { new.insert(a | b); new.insert(full & !a); }
        } }
        if new.is_subset(&s) { return s; }
        s.extend(new);
    }
}
fn fr(x: Q) -> String { format!("{}/{} = {:.6}", x.0, x.1, x.f()) }
fn join<T: std::fmt::Display>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- road 1: the event from half-line values only, by Dynkin moves ----
    let (f15, f20, f30) = (cdf(z(15)), cdf(z(20)), cdf(z(30)));
    let band = f20.sub(f15);                 // (15, 20] = (-inf, 20] minus (-inf, 15]
    let above = z(1).sub(f30);               // (30, inf) = everything minus (-inf, 30]
    let p_dynkin = z(1).sub(z(1).sub(band).sub(above));
    println!("F(15) = {}; F(20) = {}; F(30) = {}", fr(f15), fr(f20), fr(f30));
    let dv: Vec<String> = [15, 20, 30].iter().map(|&x| { let d = dens(z(x)); format!("{}/{}", d.0, d.1) }).collect();
    println!("density f at 15, 20, 30: {}", dv.join(", "));
    println!("band (15, 20]: {}; above 30: {}", fr(band), fr(above));
    println!("P(E) by Dynkin moves on F alone: {}", fr(p_dynkin));
    // ---- road 2: the density integrated, never touching F ----
    let p_dens = simpson(&dens, 15, 20).add(simpson(&dens, 30, 32));
    println!("P(E) by integrating the density: {}", fr(p_dens));
    // ---- roads 3 and 4: simulate both models ----
    let n = 200000usize;
    let ts: Vec<i32> = (8..33).step_by(2).collect();
    let (mut ga, mut gb) = (Mix(2026), Mix(29));
    let mut cnt = [vec![0usize; ts.len()], vec![0usize; ts.len()]];
    let (mut hit, mut heat, mut heat2, mut ceil15) = ([0usize; 2], [0f64; 2], [0f64; 2], 0usize);
    for _ in 0..n {
        let (u1, u2) = (ga.next(), ga.next());
        let ta = 8.0 + 12.0 * u1 + 12.0 * u2;
        let tb = model_b(gb.next());
        if ta.ceil() <= 15.0 { ceil15 += 1; }            // model C: A's reading rounded up
        for (m, t) in [(0, ta), (1, tb)] {
            if (15.0 < t && t <= 20.0) || t > 30.0 { hit[m] += 1; }
            let h = (18.0 - t).max(0.0); heat[m] += h; heat2[m] += h * h;
            for (i, &x) in ts.iter().enumerate() { if t <= x as f64 { cnt[m][i] += 1; } }
        }
    }
    let pe = p_dens.f();
    let se = (pe * (1.0 - pe) / n as f64).sqrt();
    let nm = ["A", "B"];
    for m in 0..2 { println!("P(E), model {} simulated, {} draws: {:.4}", nm[m], n, hit[m] as f64 / n as f64); }
    println!("standard error of one simulated P(E): {:.4}", se);
    println!("chart, t: {}", join(&ts));
    let fx: Vec<String> = ts.iter().map(|&x| format!("{:.2}", cdf(z(x as i128)).f())).collect();
    println!("chart, F exact: {}", fx.join(", "));
    for m in 0..2 {
        let v: Vec<String> = cnt[m].iter().map(|&c| format!("{:.2}", c as f64 / n as f64)).collect();
        println!("chart, model {}: {}", nm[m], v.join(", "));
    }
    // ---- the function version: heating degrees max(18 - T, 0) ----
    let h_exact = simpson(&|t: Q| z(18).sub(t).mul(dens(t)), 8, 18);
    println!("E[max(18 - T, 0)] exact: {}", fr(h_exact));
    let mut hse = [0f64; 2];
    for m in 0..2 {
        let mean = heat[m] / n as f64;
        hse[m] = ((heat2[m] / n as f64 - mean * mean) / n as f64).sqrt();
        println!("E[max(18 - T, 0)], model {} simulated: {:.4} (se {:.4})", nm[m], mean, hse[m]);
    }
    // ---- finite spaces, every set listed ----
    let hl = [0b1u32, 0b11, 0b111, 0b1111, 0b11111, 0];         // six 5-degree bands
    let (d6, s6) = (closure(&hl, 0b111111, false), closure(&hl, 0b111111, true));
    println!("six bands, half-lines at 10..30: lambda closure {} sets, sigma closure {} sets", d6.len(), s6.len());
    let c = [0b0011u32, 0b0110];                 // cold-or-mild, mild-or-warm
    let (mu, nu) = ([q(1, 4); 4], [z(0), q(1, 2), z(0), q(1, 2)]);
    let meas = |w: &[Q; 4], a: u32| (0..4).filter(|i| a >> i & 1 == 1).fold(z(0), |s, i| s.add(w[i]));
    let good: BTreeSet<u32> = (0..16).filter(|&a| meas(&mu, a) == meas(&nu, a)).collect();
    let (dc, sc) = (closure(&c, 15, false), closure(&c, 15, true));
    println!("four bands, not a pi-system: lambda closure {} sets, sigma closure {} sets", dc.len(), sc.len());
    println!("sets where the two four-band models agree: {} of 16; 'mild' gets {:.2} and {:.2}", good.len(), meas(&mu, 2).f(), meas(&nu, 2).f());
    println!("add the overlap 'mild' and the lambda closure has {} sets", closure(&[0b0011, 0b0110, 0b0010], 15, false).len());
    // ---- what breaks ----
    let qn: Vec<usize> = [10i128, 100, 1000].iter()
        .map(|&m| (1..=m).map(|d| (1..=d).filter(|&k| g(k, d) == 1).count()).sum()).collect();
    let dbl: Vec<usize> = qn.iter().map(|x| 2 * x).collect();
    println!("rationals in (0, 1] with denominator <= 10, 100, 1000: {}; doubled: {}; at the point 1/2: 1 against 2", join(&qn), join(&dbl));
    println!("model C (A rounded up), whole degrees only: at 15 both {:.4}; at 15.5 C {:.4} (simulated {:.4}), A {:.4}",
             f15.f(), f15.f(), ceil15 as f64 / n as f64, cdf(q(31, 2)).f());
    let fig: Vec<String> = [8i128, 15, 20, 30, 32].iter().map(|&x| format!("t={} ({:.2}, {:.2})", x,
        z(30).add(q(25, 2).mul(z(x - 8))).f(), z(200).sub(z(1920).mul(dens(z(x)))).f())).collect();
    println!("figure, x = 30 + 12.5(t - 8), y = 200 - 1920 f(t): {}", fig.join("; "));
    assert!(p_dynkin == p_dens && p_dens == q(11, 32));            // F alone against the density
    for m in 0..2 { assert!((hit[m] as f64 / n as f64 - pe).abs() < 4.0 * se); }
    assert!(d6 == s6 && s6.len() == 64);                            // pi-system: lambda closure is everything
    assert!(good == dc && dc.len() == 6 && sc.len() == 16);         // not pi: agreement stops short
    assert!(h_exact == q(125, 108));
    for m in 0..2 { assert!((heat[m] / n as f64 - 125.0 / 108.0).abs() < 4.0 * hse[m]); }
    let se15 = (f15.f() * (1.0 - f15.f()) / n as f64).sqrt();       // model C: agrees at 15, not at 15.5
    assert!((ceil15 as f64 / n as f64 - f15.f()).abs() < 4.0 * se15 && cdf(q(31, 2)).f() - f15.f() > 8.0 * se15);
    println!("ALL CHECKS PASS");
}
