// Credit indices -- the check behind the card.  std only, no crates.
// The root finder, the integrator, the normal CDF and the random numbers are written out below.
use std::f64::consts::PI;
const R: f64 = 0.40; // recovery
const RATE: f64 = 0.05; // riskless rate
const T: f64 = 5.0; const DT: f64 = 0.25; const NQ: usize = 20; // years; quarter; 20 fee dates
const NOTIONAL: f64 = 10_000_000.0; const NAMES: usize = 125; const COUPON: f64 = 0.01;
const TRADED: f64 = 0.0117; // the index's own quoted spread on the screen

fn annuity(lam: f64) -> f64 {
    // road 1: add up twenty survival-weighted quarters
    (1..=NQ).map(|i| DT * (-(RATE + lam) * DT * i as f64).exp()).sum()
}
fn annuity_geom(lam: f64) -> f64 {
    // road 2: the same sum as a geometric series
    let x = (-(RATE + lam) * DT).exp();
    DT * x * (1.0 - x.powi(NQ as i32)) / (1.0 - x)
}
fn protection(lam: f64, rec: f64) -> f64 {
    let k = RATE + lam;
    (1.0 - rec) * lam / k * (1.0 - (-k * T).exp())
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn hazard_for(s: f64, rec: f64) -> f64 { bisect(&|l| protection(l, rec) / annuity(l) - s, 1e-12, 5.0) }
fn upfront_flat(q: f64) -> f64 { (q - COUPON) * annuity(hazard_for(q, R)) } // the one-name quoting convention
fn index_legs(quotes: &[f64], rec: f64) -> (f64, f64, Vec<f64>) {
    // road 1: closed-form legs, summed name by name
    let lams: Vec<f64> = quotes.iter().map(|&s| hazard_for(s, rec)).collect();
    let p: f64 = lams.iter().map(|&l| protection(l, rec)).sum();
    let a: f64 = lams.iter().map(|&l| annuity(l)).sum();
    (p / NAMES as f64, a / NAMES as f64, lams)
}
fn intrinsic(quotes: &[f64], rec: f64) -> f64 { let (p, a, _) = index_legs(quotes, rec); p / a }

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {
        // splitmix64, the same stream as the Python check
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u = self.next(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.next()).cos() }
}
fn ncdf(x: f64) -> f64 {
    // normal CDF from a Chebyshev fit to erfc, error < 1.2e-7
    let z = x.abs() / 2f64.sqrt();
    let t = 1.0 / (1.0 + 0.5 * z);
    let e = t * (-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418 + t * (-0.18628806
        + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277))))))))).exp();
    if x >= 0.0 { 1.0 - 0.5 * e } else { 0.5 * e }
}
fn simulate(rng: &mut Rng, cum: &[f64], lams: &[f64], s: f64, rho: f64, paths: usize) -> (f64, f64, f64) {
    // road 3: default times for all 125 names, path by path
    let (mut sv, mut sv2, mut sp, mut sa) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let (z, mut p, mut a) = (rng.gauss(), 0.0, 0.0);
        for &lam in lams {
            let u = if rho == 0.0 { rng.next() } else { ncdf(-(rho.sqrt() * z + (1.0 - rho).sqrt() * rng.gauss())) };
            let tau = -u.ln() / lam;
            a += cum[((tau / DT) as usize).min(NQ)];
            if tau <= T { p += (1.0 - R) * (-RATE * tau).exp(); }
        }
        let v = (p - s * a) / NAMES as f64; // index value per $1 at spread s on this path
        sv += v; sv2 += v * v; sp += p; sa += a;
    }
    let m = sv / paths as f64;
    (m, ((sv2 / paths as f64 - m * m) / paths as f64).sqrt(), sp / sa)
}

fn main() {
    let mut quotes = vec![0.0080; 100]; // 100 names at 80 bp, 25 at 300 bp
    quotes.extend([0.0300; 25]);
    let mut cum = vec![0.0];
    for i in 1..=NQ { let last = cum[i - 1]; cum.push(last + DT * (-RATE * DT * i as f64).exp()); }
    // ---- the 125 legs, two ways ----
    let (p, a, lams) = index_legs(&quotes, R);
    let (l_t, l_w) = (lams[0], lams[NAMES - 1]);
    let p_simp = lams.iter().map(|&l| simpson(&|t| (1.0 - R) * l * (-(RATE + l) * t).exp(), 0.0, T, 2000)).sum::<f64>() / NAMES as f64;
    let a_geom = lams.iter().map(|&l| annuity_geom(l)).sum::<f64>() / NAMES as f64;
    let s_i = p_simp / a_geom; // road 2: total protection over total annuity
    let s_w = quotes.iter().zip(&lams).map(|(s, &l)| s * annuity(l)).sum::<f64>() / lams.iter().map(|&l| annuity(l)).sum::<f64>();
    let s_avg = quotes.iter().sum::<f64>() / NAMES as f64;
    let w_wide = 25.0 * annuity(l_w) / (NAMES as f64 * a);
    let u_sum = lams.iter().map(|&l| protection(l, R) - COUPON * annuity(l)).sum::<f64>() / NAMES as f64;
    let u_trd = upfront_flat(TRADED);
    let mut rng = Rng(20260928);
    let (m0, se0, q0) = simulate(&mut rng, &cum, &lams, s_i, 0.0, 100000);
    let (m2, se2, q2) = simulate(&mut rng, &cum, &lams, s_i, 0.20, 100000);
    // ---- one wide name defaults at 40% recovery ----
    let n = NAMES as f64;
    let jtd = (1.0 - R) / n - (protection(l_w, R) - COUPON * annuity(l_w)) / n;
    let s_after = intrinsic(&quotes[..NAMES - 1], R); // 124 names left; weights unchanged, 1/125 each

    let rows: Vec<(&str, f64, usize)> = vec![
        ("house: par spread at hazard 2%, bp", 1e4 * protection(0.02, R) / annuity(0.02), 4),
        ("hazard, 80 bp name", l_t, 6), ("hazard, 300 bp name", l_w, 6),
        ("annuity, 80 bp name", annuity(l_t), 6), ("annuity, 300 bp name", annuity(l_w), 6),
        ("protection leg, 80 bp name", protection(l_t, R), 6), ("protection leg, 300 bp name", protection(l_w, R), 6),
        ("index protection leg per $1", p, 6), ("  same, Simpson", p_simp, 6),
        ("index annuity per $1", a, 6), ("  same, geometric series", a_geom, 6),
        ("1 intrinsic spread, P / A, bp", 1e4 * s_i, 4), ("2 annuity-weighted quotes, bp", 1e4 * s_w, 4),
        ("plain average of quotes, bp", 1e4 * s_avg, 4),
        ("share of the 300 bp names, headcount", 25.0 / n, 4), ("share of the 300 bp names, weighted", w_wide, 4),
        ("3 simulated value at s_I, independent", m0, 7), ("  standard error, independent", se0, 7),
        ("  simulated spread, independent, bp", 1e4 * q0, 4),
        ("3 simulated value at s_I, rho = 20%", m2, 7), ("  standard error, rho = 20%", se2, 7),
        ("  simulated spread, rho = 20%, bp", 1e4 * q2, 4),
        ("intrinsic upfront %, sum of 125 legs", 100.0 * u_sum, 4), ("  (s_I - c) x index annuity, %", 100.0 * (s_i - COUPON) * a, 4),
        ("intrinsic upfront $ on $10m", u_sum * NOTIONAL, 2),
        ("flat conversion of s_I, upfront %", 100.0 * upfront_flat(s_i), 4),
        ("traded quote, bp", 1e4 * TRADED, 4), ("traded upfront %, flat conversion", 100.0 * u_trd, 4),
        ("traded upfront $ on $10m", u_trd * NOTIONAL, 2), ("skew, traded - intrinsic, bp", 1e4 * (TRADED - s_i), 4),
        ("skew in upfront $ on $10m", (u_trd - u_sum) * NOTIONAL, 2),
        ("slice per name $", NOTIONAL / n, 2),
        ("default: payout % of notional", 100.0 * (1.0 - R) / n, 4), ("default: payout $", (1.0 - R) / n * NOTIONAL, 2),
        ("default: notional left $", NOTIONAL * (n - 1.0) / n, 2),
        ("coupon per quarter before $", COUPON * DT * NOTIONAL, 2), ("coupon per quarter after $", COUPON * DT * NOTIONAL * (n - 1.0) / n, 2),
        ("default: legs of that name given up $", (protection(l_w, R) - COUPON * annuity(l_w)) / n * NOTIONAL, 2),
        ("default: net gain to buyer $", jtd * NOTIONAL, 2), ("intrinsic after default, bp", 1e4 * s_after, 4),
        ("wrong: skew against plain average, bp", 1e4 * (TRADED - s_avg), 4),
        ("wrong: payout with no recovery, %", 100.0 / n, 4),
        ("wrong: upfront from plain average, %", 100.0 * upfront_flat(s_avg), 4),
        ("try: R = 25%, intrinsic, bp", 1e4 * intrinsic(&quotes, 0.25), 4),
        ("try: a tight name defaults, bp", 1e4 * intrinsic(&quotes[1..], R), 4),
        ("try: all 125 at 124 bp, bp", 1e4 * intrinsic(&[0.0124; NAMES], R), 4),
    ];
    for (name, v, d) in &rows { println!("{:<40} {:>14.*}", name, *d, v); }
    let wide: Vec<f64> = (1..=8).map(|k| 100.0 * k as f64).collect();
    let chart_i: Vec<f64> = wide.iter().map(|w| { let mut q = vec![0.008; 100]; q.extend([w / 1e4; 25]); 1e4 * intrinsic(&q, R) }).collect();
    let line = |label: &str, xs: Vec<String>| println!("{}{}", label, xs.join(" "));
    line("chart, wide names bp ", wide.iter().map(|w| format!("{:7.0}", w)).collect());
    line("chart, intrinsic bp  ", chart_i.iter().map(|v| format!("{:7.2}", v)).collect());
    line("chart, average bp    ", wide.iter().map(|w| format!("{:7.2}", (8000.0 + 25.0 * w) / 125.0)).collect());

    assert!((protection(0.02, R) / annuity(0.02) - 0.01210561519).abs() < 1e-10, "house par spread, 121.06 bp");
    assert!((s_i - s_w).abs() < 1e-12, "Simpson legs vs annuity-weighted quotes");
    assert!((1e4 * s_i * 10.0).round() / 10.0 == 121.0 && s_i < s_avg, "the syllabus's 121.0 bp, below the 124 bp average");
    assert!((u_sum - (s_i - COUPON) * a).abs() < 1e-12, "sum of 125 upfronts vs one index upfront");
    assert!(m0.abs() < 4.0 * se0 && m2.abs() < 4.0 * se2, "both simulations price the index at zero at s_I");
    assert!(chart_i.iter().zip(&wide).all(|(c, w)| *c < (8000.0 + 25.0 * w) / 125.0), "intrinsic below average");
    assert!(s_after < s_i && s_i < intrinsic(&quotes[1..], R), "a wide default lowers s_I, a tight one raises it");
    assert!((1..50).all(|k| annuity(hazard_for(k as f64 * 20e-4, R)) > annuity(hazard_for((k + 1) as f64 * 20e-4, R))), "A(s) falls");
    println!("ALL CHECKS PASS");
}
