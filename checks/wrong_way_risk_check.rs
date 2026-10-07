// Wrong-way risk -- the check behind the card.  Rust std only, no crates.
// A put on Northwind's own shares, bought from Northwind.  Default is tied to the
// share through a Gaussian copula; CVA is recomputed at each correlation.
// Normal CDF by series, quantile by bisection, integrals by Simpson's rule,
// random numbers by splitmix64 and Box-Muller: all written out below.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R_: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const LAM: f64 = 0.02; const REC: f64 = 0.40;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { k += 2.0; term *= x * x / k; total += term; }
    0.5 + phi(x) * total
}
fn inv_n(p: f64) -> f64 {
    let (mut lo, mut hi) = (-9.0, 9.0);
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if n(mid) < p { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
struct M { l: f64, a: f64, v: f64, d1: f64, d2: f64, disc: f64 }
impl M {
    fn s_t(&self, y: f64) -> f64 { S * ((R_ - Q - 0.5 * SIG * SIG) * T + self.v * y).exp() }
    fn p_rho(&self, y: f64, rho: f64) -> f64 {
        if rho >= 1.0 { return if y <= self.a { 1.0 } else { 0.0 }; }
        n((self.a - rho * y) / (1.0 - rho * rho).sqrt())
    }
    // road 1: integrate payoff x bell-curve height x conditional default chance
    fn cva_int(&self, rho: f64, put: bool) -> f64 {
        let (lo, mut hi) = if put { (-9.0, -self.d2) } else { (-self.d2, 9.0) };
        if rho >= 1.0 { hi = hi.min(self.a); }
        if hi <= lo { return 0.0; }
        let pay = |y: f64| if put { K - self.s_t(y) } else { self.s_t(y) - K };
        self.l * self.disc * simpson(|y| pay(y) * phi(y) * self.p_rho(y, rho), lo, hi, 4000)
    }
    // road 2: closed form with the two-score bell-curve area N2 (Plackett's identity)
    fn cva_closed(&self, rho: f64, put: bool) -> f64 {
        let (a, v, dq) = (self.a, self.v, (-Q * T).exp());
        if put { self.l * (K * self.disc * n2(-self.d2, a, rho) - S * dq * n2(-self.d1, a - rho * v, rho)) }
        else { self.l * (S * dq * n2(self.d1, a - rho * v, -rho) - K * self.disc * n2(self.d2, a, -rho)) }
    }
}
fn n2(h: f64, k: f64, rho: f64) -> f64 {
    let dens = |t: f64| {
        if 1.0 - t * t < 1e-14 { return 0.0; }
        (-(h * h - 2.0 * t * h * k + k * k) / (2.0 * (1.0 - t * t))).exp() / (2.0 * PI * (1.0 - t * t).sqrt())
    };
    n(h) * n(k) + if rho != 0.0 { simpson(dens, 0.0, rho, 2000) } else { 0.0 }
}
// road 3: simulate share and credit scores together
struct Rng(u64);
impl Rng {
    fn rand(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn mc(m: &M, rho: f64, paths: usize) -> (f64, f64, f64, f64) {
    let mut g = Rng(2026);
    let (mut sp, mut sc, mut sp2, mut sc2) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let (u1, u2, u3) = (g.rand(), g.rand(), g.rand());
        let y = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let e = (-2.0 * u3.ln()).sqrt() * (2.0 * PI * g.rand()).cos();
        if rho * y + (1.0 - rho * rho).sqrt() * e <= m.a {
            let st = m.s_t(y);
            let (xp, xc) = (m.l * m.disc * (K - st).max(0.0), m.l * m.disc * (st - K).max(0.0));
            sp += xp; sp2 += xp * xp; sc += xc; sc2 += xc * xc;
        }
    }
    let nf = paths as f64;
    let (mp, mcl) = (sp / nf, sc / nf);
    (mp, ((sp2 / nf - mp * mp) / nf).sqrt(), mcl, ((sc2 / nf - mcl * mcl) / nf).sqrt())
}
fn main() {
    let (l, p) = (1.0 - REC, 1.0 - (-LAM * T).exp());
    let v = SIG * T.sqrt();
    let d1 = ((S / K).ln() + (R_ - Q + 0.5 * SIG * SIG) * T) / v;
    let m = M { l, a: inv_n(p), v, d1, d2: d1 - v, disc: (-R_ * T).exp() };
    let (a, disc, dq) = (m.a, m.disc, (-Q * T).exp());
    let put = K * disc * n(-m.d2) - S * dq * n(-d1);
    let call = S * dq * n(d1) - K * disc * n(m.d2);
    let (indep_put, indep_call) = (l * p * put, l * p * call);
    println!("{:<34}{:>12.6}", "clean put, Black-Scholes", put);
    println!("{:<34}{:>12.6}", "clean call, Black-Scholes", call);
    println!("{:<34}{:>12.6}", "one-year default chance p", p);
    println!("{:<34}{:>12.6}", "default cutoff a", a);
    println!("{:<22}{:>12.6}{:>12.6}", "d1, d2", d1, m.d2);
    println!("{:<34}{:>12.6}", "independent put CVA  L p P", indep_put);
    println!("{:<34}{:>12.6}", "independent call CVA L p C", indep_call);
    println!();
    println!("rho    put:integral    closed   x indep   call:integral   closed   x indep");
    let rhos = [-0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 0.9, 1.0];
    let mut res = Vec::new();
    for &rho in rhos.iter() {
        let row = (m.cva_int(rho, true), m.cva_closed(rho, true), m.cva_int(rho, false), m.cva_closed(rho, false));
        println!("{:>5.2} {:>13.6} {:>9.6} {:>8.2} {:>14.6} {:>9.6} {:>8.2}",
                 rho, row.0, row.1, row.0 / indep_put, row.2, row.3, row.2 / indep_call);
        res.push(row);
    }
    let at = |x: f64| res[rhos.iter().position(|&r| r == x).unwrap()];
    let (put5, call5) = (at(0.5).0, at(0.5).2);
    let (mp, sep, mcl, sec) = mc(&m, 0.5, 1000000);
    println!();
    println!("{:<34}{:>12.4}  +/- {:.4}", "MC rho 0.5 put, 1000000 paths", mp, sep);
    println!("{:<34}{:>12.4}  +/- {:.4}", "MC rho 0.5 call, 1000000 paths", mcl, sec);
    let parity = |x: f64| l * (K * disc * n(a) - S * dq * n(a - x * v));
    println!("{:<22}{:>12.6}{:>12.6}", "K e^-rT, S e^-qT", K * disc, S * dq);
    println!("{:<34}{:>12.6}{:>12.6}", "N2(-d2, a; .5), N2(-d1, a-.5v; .5)", n2(-m.d2, a, 0.5), n2(-d1, a - 0.5 * v, 0.5));
    println!("{:<34}{:>12.6}", "rho 0.5 put CVA - call CVA", put5 - call5);
    println!("{:<34}{:>12.6}", "  L(K D N(a) - S e^-qT N(a-rho v))", parity(0.5));
    for x in [0.0, 0.5, 1.0] {
        println!("{:<30}{:>4.1}{:>12.6}", "put exposure given default, rho", x, at(x).0 / (l * p));
    }
    println!("{:<34}{:>12.6}", "rho 0.5 risky put  P - CVA", put - put5);
    println!("{:<34}{:>12.6}", "independent risky put", put - indep_put);
    println!("{:<34}{:>12.6}", "ceiling: put pays K at default", l * K * disc * p);
    println!("{:<34}{:>12.6}", "house check: L p x Acme call", indep_call);
    println!();
    println!("wrong answers");
    println!("{:<34}{:>12.6}", "wrong: independent formula at 0.5", indep_put);
    println!("{:<34}{:>12.6}", "wrong: 50% as a variance share", m.cva_int(0.5f64.sqrt(), true));
    println!("{:<34}{:>12.6}", "wrong: sign of rho flipped", at(-0.5).0);
    println!("{:<34}{:>12.6}", "wrong: the ceiling read as a price", l * K * disc * p);
    println!();
    println!("chart: default chance % at rho 0.5 by year-end price; {:.2} at rho 0", 100.0 * p);
    for st in [60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 140.0] {
        let y = ((st / S).ln() - (R_ - Q - 0.5 * SIG * SIG) * T) / v;
        println!("  price {:>5.0}   default chance {:>6.2}   put pays {:>5.2}", st, 100.0 * m.p_rho(y, 0.5), (K - st).max(0.0));
    }
    for (i, &x) in rhos.iter().enumerate() {
        assert!((res[i].0 - res[i].1).abs() < 1e-7, "put: integral road vs closed-form road");
        assert!((res[i].2 - res[i].3).abs() < 1e-7, "call: integral road vs closed-form road");
        assert!((res[i].0 - res[i].2 - parity(x)).abs() < 1e-7, "CVA parity");
        if i > 0 { assert!(res[i - 1].0 < res[i].0 && res[i - 1].2 > res[i].2, "put up, call down"); }
    }
    assert!((at(0.0).0 - l * p * put).abs() < 1e-8, "independence: integral must collapse to L p P");
    assert!((mp - put5).abs() < 4.0 * sep && (mcl - call5).abs() < 4.0 * sec, "simulation within 4 standard errors");
    assert!(at(1.0).0 < l * K * disc * p, "no model beats the ceiling");
    assert!((put - 6.330080627550).abs() < 1e-9 && (indep_call - 0.1096).abs() < 5e-5 && (call - indep_call - 9.117).abs() < 5e-4,
            "house put, CVA 0.1096, risky call 9.117");
    println!("ALL CHECKS PASS");
}
