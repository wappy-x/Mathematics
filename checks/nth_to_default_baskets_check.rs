// Nth-to-default baskets -- the check behind the card.  std only, no crates.
// Five names, hazard 2% each, recovery 40%, five years, riskless rate 5%, quarterly premiums.
// Nothing imported knows the answer: the normal curve is a series written here, its inverse
// is bisection, integrals are Simpson's rule, random numbers come from a hand-written splitmix64.
const LAM: f64 = 0.02; const R: f64 = 0.40; const T: f64 = 5.0; const RATE: f64 = 0.05;
const DT: f64 = 0.25; const NAMES: usize = 5;
use std::f64::consts::PI;

fn dates() -> Vec<f64> { (1..=20).map(|j| DT * j as f64).collect() }

fn n(x: f64) -> f64 { // bell-curve area left of x: erf from its all-positive series
    let z = x.abs() / 2f64.sqrt();
    if z > 6.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut s, mut k) = (z, z, 0.0);
    while term > 1e-17 * s { k += 1.0; term *= 2.0 * z * z / (2.0 * k + 1.0); s += term; }
    let erf = 2.0 / PI.sqrt() * (-z * z).exp() * s;
    if x < 0.0 { 0.5 * (1.0 - erf) } else { 0.5 * (1.0 + erf) }
}

fn ninv(p: f64) -> f64 { // the point with area p to its left, by bisection
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if n(mid) < p { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let s: f64 = (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * s
}

fn count_law(q: f64, nn: usize) -> Vec<f64> { // chance of 0..nn defaults, each name failing with chance q
    let mut law = vec![0.0; nn + 1]; law[0] = 1.0;
    for _ in 0..nn {
        law = (0..=nn).map(|j| law[j] * (1.0 - q) + if j > 0 { law[j - 1] * q } else { 0.0 }).collect();
    }
    law
}

// Q_k(t) = chance that fewer than k names have defaulted by t, for k = 1..nn
fn survival(t: f64, rho: f64, lam: f64, nn: usize, fix: bool) -> Vec<f64> {
    if t == 0.0 { return vec![1.0; nn]; }
    let p = 1.0 - (-lam * t).exp();
    let law = if rho == 0.0 { count_law(p, nn) }
    else if rho == 1.0 { let mut l = vec![0.0; nn + 1]; l[0] = 1.0 - p; l[nn] = p; l } // all default at once
    else {
        let (c, w) = (ninv(p), if fix { (1.0 - rho).sqrt() } else { 1.0 });
        let mut law = vec![0.0; nn + 1];
        for i in 0..=400 { // Simpson over the economy score m
            let m = -8.0 + i as f64 * 0.04;
            let wt = (if i == 0 || i == 400 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * 0.04 / 3.0
                * (-m * m / 2.0).exp() / (2.0 * PI).sqrt();
            for (j, v) in count_law(n((c - rho.sqrt() * m) / w), nn).iter().enumerate() { law[j] += wt * v; }
        }
        law
    };
    let mut acc = 0.0;
    (0..nn).map(|j| { acc += law[j]; acc }).collect()
}

// Road 2: each kth default time is a synthetic name; price it with the CDS legs of its survival curve
fn legs(rho: f64, lam: f64, nn: usize, rec: f64, fix: bool) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let a: Vec<f64> = (0..nn).map(|k| dates().iter().map(|&t| DT * (-RATE * t).exp() * survival(t, rho, lam, nn, fix)[k]).sum()).collect();
    let grid: Vec<Vec<f64>> = (0..=100).map(|i| survival(T * i as f64 / 100.0, rho, lam, nn, fix)).collect();
    let p: Vec<f64> = (0..nn).map(|k| (1.0 - rec) * ((-RATE * T).exp() * (1.0 - grid[100][k])
        + RATE * simpson(&|t: f64| (-RATE * t).exp() * (1.0 - grid[(t * 20.0).round() as usize][k]), 0.0, T, 100))).collect();
    let s = (0..nn).map(|k| 1e4 * p[k] / a[k]).collect();
    (a, p, s)
}
fn legs0(rho: f64) -> (Vec<f64>, Vec<f64>, Vec<f64>) { legs(rho, LAM, NAMES, R, true) }

fn flat_cds(lam: f64) -> (f64, f64, f64) { // Road 1: the closed-form legs for one flat hazard
    let c = RATE + lam; let x = (-c * DT).exp();
    let a = DT * x * (1.0 - x.powi(20)) / (1.0 - x); let p = (1.0 - R) * lam * (1.0 - (-c * T).exp()) / c;
    (a, p, 1e4 * p / a)
}

struct Rng(u64);
impl Rng { fn uniform(&mut self) -> f64 { // splitmix64, then 53 random bits
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
} }

fn simulate(rho: f64, rng: &mut Rng, paths: usize) -> Vec<(f64, f64)> { // Road 3: draw, sort, settle
    let ct = ninv(1.0 - (-LAM * T).exp());
    let mut sums = [[0.0f64; 5]; 2]; // sums of a, v, a*a, a*v, v*v
    for _ in 0..paths {
        let mut g = Vec::with_capacity(6);
        for _ in 0..3 {
            let (u1, u2) = (1.0 - rng.uniform(), rng.uniform()); let rr = (-2.0 * u1.ln()).sqrt();
            g.push(rr * (2.0 * PI * u2).cos()); g.push(rr * (2.0 * PI * u2).sin());
        }
        let mut taus: Vec<f64> = g[1..].iter().map(|e| rho.sqrt() * g[0] + (1.0 - rho).sqrt() * e)
            .filter(|&x| x < ct).map(|x| -n(-x).ln() / LAM).collect(); // dates inside five years only
        taus.sort_by(|a, b| a.partial_cmp(b).unwrap());
        for k in 0..2 {
            let tk = if taus.len() > k { taus[k] } else { 99.0 };
            let a = dates().iter().filter(|&&t| t < tk).map(|&t| DT * (-RATE * t).exp()).sum::<f64>(); // premium leg a, protection v
            let v = if tk <= T { (1.0 - R) * (-RATE * tk).exp() } else { 0.0 };
            for (j, z) in [a, v, a * a, a * v, v * v].iter().enumerate() { sums[k][j] += z; }
        }
    }
    let pf = paths as f64; // the premium is a ratio of two averages: its error uses v - s*a, both legs random
    (0..2).map(|k| { let m: Vec<f64> = sums[k].iter().map(|z| z / pf).collect(); let s = m[1] / m[0];
        (1e4 * s, 1e4 * ((m[4] - 2.0 * s * m[3] + s * s * m[2]) / pf).sqrt() / m[0]) }).collect()
}

fn commas(x: f64) -> String { // whole dollars with thousands separators
    let s = format!("{:.0}", x); let b = s.as_bytes(); let mut out = String::new();
    for (i, ch) in b.iter().enumerate() { if i > 0 && (b.len() - i) % 3 == 0 { out.push(','); } out.push(*ch as char); }
    out
}
fn pct(x: f64) -> String { format!("{:.2}%", x * 100.0) }

fn main() {
    let (a1, p1, s1) = flat_cds(LAM);
    println!("single name: annuity {:.6}  protection {:.6}  spread {:.2} bp", a1, p1, s1);
    assert!((s1 - 121.06).abs() < 0.005);
    println!("independent first-to-default hazard {}: five-year survival {:.6} = {:.6}^5",
        pct(NAMES as f64 * LAM), (-(NAMES as f64) * LAM * T).exp(), (-LAM * T).exp());
    let (af, pf, sf) = flat_cds(NAMES as f64 * LAM);
    println!("independent FTD legs: x {:.6}  annuity {:.6}  protection {:.6}", (-(RATE + NAMES as f64 * LAM) * DT).exp(), af, pf);
    let (l0, l3, l1) = (legs0(0.0), legs0(0.3), legs0(1.0));
    println!("rho 0.3 legs: FTD annuity {:.6} protection {:.6}  2TD annuity {:.6} protection {:.6}", l3.0[0], l3.1[0], l3.0[1], l3.1[1]);
    let p5 = 1.0 - (-LAM * T).exp(); let c5 = ninv(p5);
    println!("rho 0.3 year 5: cutoff {:.4}  weights {:.4} {:.4}  economies with q below 25% {}", c5, 0.3f64.sqrt(), 0.7f64.sqrt(), pct(1.0 - n((c5 - 0.7f64.sqrt() * ninv(0.25)) / 0.3f64.sqrt())));
    for m in [-2i32, 0, 2] {
        let q = n((c5 - 0.3f64.sqrt() * m as f64) / 0.7f64.sqrt()); let law = count_law(q, NAMES);
        println!("  economy {:+}: each name {}  at least one {}  at least two {}", m, pct(q), pct(1.0 - law[0]), pct(1.0 - law[0] - law[1]));
    }
    let mut rng = Rng(20261123);
    let sim0 = simulate(0.0, &mut rng, 200000); let sim3 = simulate(0.3, &mut rng, 200000);
    println!("rho 0.0  FTD  closed form {:.2}  curve road {:.2}  simulation {:.2} +- {:.2} bp", sf, l0.2[0], sim0[0].0, sim0[0].1);
    println!("rho 0.0  2TD  binomial curve {:.2}  simulation {:.2} +- {:.2} bp", l0.2[1], sim0[1].0, sim0[1].1);
    println!("rho 0.3  FTD  copula integral {:.2}  simulation {:.2} +- {:.2} bp", l3.2[0], sim3[0].0, sim3[0].1);
    println!("rho 0.3  2TD  copula integral {:.2}  simulation {:.2} +- {:.2} bp", l3.2[1], sim3[1].0, sim3[1].1);
    println!("rho 1.0  FTD {:.2}  2TD {:.2} bp  (single name {:.2})", l1.2[0], l1.2[1], s1);
    assert!((l0.2[0] - sf).abs() < 0.02 && (l1.2[0] - s1).abs() < 0.02 && (l1.2[1] - s1).abs() < 0.02);
    let refs = [l0.2[0], l0.2[1], l3.2[0], l3.2[1]];
    for (i, (s, e)) in sim0.iter().chain(sim3.iter()).enumerate() { assert!((s - refs[i]).abs() < 4.0 * e); }
    for rho in [0.0, 0.3, 1.0] {
        let s = survival(T, rho, LAM, NAMES, true); assert!(p5 - 1e-12 < 1.0 - s[0] && 1.0 - s[0] < NAMES as f64 * p5); // riskiest name <= any default <= sum
        println!("rho {:.1}  by year 5: no default {}  at least one {}  at least two {}", rho, pct(s[0]), pct(1.0 - s[0]), pct(1.0 - s[1]));
    }
    println!("at least one default by year 5, any dependence: from {} to {}", pct(p5), pct(NAMES as f64 * p5));
    println!("ladder at rho 0.3, k = 1..5: {} bp", l3.2.iter().map(|s| format!("{:.2}", s)).collect::<Vec<_>>().join("  "));
    for (rho, l) in [(0.0, &l0), (0.3, &l3), (1.0, &l1)] {
        let tot: f64 = l.1.iter().sum();
        println!("sum of the five protection legs at rho {:.1}: {:.6}  five single names {:.6}", rho, tot, NAMES as f64 * p1);
        assert!((tot - NAMES as f64 * p1).abs() < 1e-5);
    }
    println!("sweep: rho, FTD bp, 2TD bp");
    let sweep: Vec<Vec<f64>> = (0..=10).map(|i| legs0(i as f64 / 10.0).2).collect();
    for i in 0..=10 { println!("  {:.1}  {:7.2}  {:7.2}", i as f64 / 10.0, sweep[i][0], sweep[i][1]); }
    assert!((0..10).all(|i| sweep[i][0] > sweep[i + 1][0]), "FTD falls at every step");
    let mut peak = 0; for i in 0..=10 { if sweep[i][1] > sweep[peak][1] { peak = i; } }
    println!("2TD peaks on the grid at rho {:.1}: {:.2} bp, then falls back to {:.2}", peak as f64 / 10.0, sweep[peak][1], s1);
    assert!(peak > 0 && peak < 10 && sweep[3][1] > sweep[0][1]);
    println!("dollars on $10m, per quarter: FTD rho 0 {}  rho 0.3 {}  single {}", commas(sf * 250.0), commas(l3.2[0] * 250.0), commas(s1 * 250.0));
    let riskless: f64 = dates().iter().map(|&t| DT * (-RATE * t).exp()).sum();
    println!("break: add the five single spreads {:.2}  treat as independent {:.2}  vs {:.2}", NAMES as f64 * s1, sf, l3.2[0]);
    println!("break: premiums for all five years {:.2}  drop sqrt(1-rho) {:.2}", 1e4 * l3.1[0] / riskless, legs(0.3, LAM, NAMES, R, false).2[0]);
    let j2 = 1.0 - survival(T, 0.3, LAM, 2, true)[1]; let dc = (j2 - p5 * p5) / (p5 * (1.0 - p5)); // both of two names default by year 5
    println!("trap: default correlation by year 5 at rho 0.3 {:.4}; used as rho it gives FTD {:.2}", dc, legs0(dc).2[0]);
    println!("try: recovery 20% {:.2}  ten names {:.2}  hazard 1% {:.2}  rho 0.6 FTD {:.2} 2TD {:.2}",
        legs(0.3, LAM, NAMES, 0.2, true).2[0], legs(0.3, LAM, 10, R, true).2[0], legs(0.3, 0.01, NAMES, R, true).2[0], legs0(0.6).2[0], legs0(0.6).2[1]);
    println!("ALL CHECKS PASS");
}
