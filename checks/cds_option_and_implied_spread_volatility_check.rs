// Options on a CDS: Black on the forward spread, risky annuity as the unit. Rust std only, no crates.
// Normal CDF, integrator, root finder and random numbers are written out; same recipe as the Python check.
use std::f64::consts::PI;

const RATE: f64 = 0.05;
const LOSS: f64 = 0.60;
const KNOTS: [f64; 4] = [0.0, 1.0, 3.0, 5.0];
const QUOTES: [f64; 3] = [0.0120, 0.0200, 0.0250];
const TE: f64 = 1.0;
const K: f64 = 0.0250;
const VOL: f64 = 0.50;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn ncdf(x: f64) -> f64 { if x < -12.0 { 0.0 } else if x > 12.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, x, 2000) } }
fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64, n: usize) -> f64 {
    for _ in 0..n { let mid = 0.5 * (lo + hi); if f(mid) < 0.0 { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn surv(t: f64, lam: &[f64]) -> f64 {
    let mut area = 0.0;
    for (i, h) in lam.iter().enumerate() {
        let right = if i + 1 < lam.len() { KNOTS[i + 1] } else { f64::INFINITY };
        area += h * (t.min(right) - KNOTS[i]).max(0.0);
    }
    (-area).exp()
}
fn annuity(a: f64, b: f64, lam: &[f64]) -> f64 {
    let (j0, j1) = ((4.0 * a).round() as i32 + 1, (4.0 * b).round() as i32);
    (j0..=j1).map(|j| 0.25 * (-RATE * j as f64 / 4.0).exp() * surv(j as f64 / 4.0, lam)).sum()
}
fn prot(a: f64, b: f64, lam: &[f64]) -> f64 {
    let mut edges = vec![a];
    for k in &KNOTS[1..lam.len()] { if a < *k && *k < b { edges.push(*k) } }
    edges.push(b);
    let mut total = 0.0;
    for w in edges.windows(2) {
        let (lo, hi) = (w[0], w[1]);
        let i = (0..lam.len()).filter(|&i| KNOTS[i] <= lo).last().unwrap().min(lam.len() - 1);
        let h = lam[i];
        total += LOSS * (-RATE * lo).exp() * surv(lo, lam) * h / (RATE + h) * (1.0 - (-(RATE + h) * (hi - lo)).exp());
    }
    total
}
fn bootstrap(q: &[f64]) -> Vec<f64> {
    let mut lam: Vec<f64> = vec![];
    for (i, s) in q.iter().enumerate() {
        let h = bisect(|h| { let mut l = lam.clone(); l.push(h); prot(0.0, KNOTS[i + 1], &l) - s * annuity(0.0, KNOTS[i + 1], &l) }, 0.0, 1.0, 100);
        lam.push(h);
    }
    lam
}
fn black(f: f64, k: f64, v: f64, a: f64) -> (f64, f64, f64, f64) {
    let d1 = ((f / k).ln() + 0.5 * v * v * TE) / (v * TE.sqrt());
    let d2 = d1 - v * TE.sqrt();
    (a * (f * ncdf(d1) - k * ncdf(d2)), a * (k * ncdf(-d2) - f * ncdf(-d1)), d1, d2)
}
fn option_on(q: &[f64]) -> f64 {
    let lam = bootstrap(q);
    let a = annuity(TE, 5.0, &lam);
    black(prot(TE, 5.0, &lam) / a, K, VOL, a).0
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}
fn pc(x: f64) -> String { format!("{:.6}", 100.0 * x) }

fn main() {
    let lam = bootstrap(&QUOTES);
    let (a, p) = (annuity(TE, 5.0, &lam), prot(TE, 5.0, &lam));
    let f = p / a;
    let fep = LOSS * (-RATE * TE).exp() * (1.0 - surv(TE, &lam));
    let dens = |t: f64, h: f64| LOSS * (-RATE * t).exp() * surv(t, &lam) * h;
    let p_simp = simpson(|t| dens(t, lam[1]), 1.0, 3.0, 200) + simpson(|t| dens(t, lam[2]), 3.0, 5.0, 200);
    let mut rng = Rng(20260928);
    let n_def = 400000;
    let mut sa = [0.0f64; 3];
    for _ in 0..n_def {
        let (mut e, mut tau) = (-rng.unif().ln(), 99.0);
        for (i, h) in lam.iter().enumerate() {
            let width = if i < 2 { KNOTS[i + 1] - KNOTS[i] } else { 99.0 };
            if e <= h * width { tau = KNOTS[i] + e / h; break; }
            e -= h * width;
        }
        sa[0] += (5..21).filter(|&j| tau > j as f64 / 4.0).map(|j| 0.25 * (-RATE * j as f64 / 4.0).exp()).sum::<f64>();
        sa[1] += if 1.0 < tau && tau <= 5.0 { LOSS * (-RATE * tau).exp() } else { 0.0 };
        sa[2] += if tau <= 1.0 { LOSS * (-RATE * TE).exp() } else { 0.0 };
    }
    let (a_mc, p_mc, fep_mc) = (sa[0] / n_def as f64, sa[1] / n_def as f64, sa[2] / n_def as f64);
    let p1 = 1.0 - surv(TE, &lam);
    let se_fep = LOSS * (-RATE).exp() * (p1 * (1.0 - p1) / n_def as f64).sqrt();

    let (pay, rec, d1, d2) = black(f, K, VOL, a);
    let sd = VOL * TE.sqrt();
    let payoff = |z: f64, c: f64| (c * (f * (-0.5 * sd * sd + sd * z).exp() - K)).max(0.0) * phi(z);
    let pay_int = a * simpson(|z| payoff(z, 1.0), -10.0, 10.0, 4000);
    let rec_int = a * simpson(|z| payoff(z, -1.0), -10.0, 10.0, 4000);
    let mut mc = 0.0;
    for _ in 0..200000 {
        let (u1, u2) = (rng.unif(), rng.unif());
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        mc += 0.5 * [z, -z].iter().map(|y| (f * (-0.5 * sd * sd + sd * y).exp() - K).max(0.0)).sum::<f64>();
    }
    let pay_mc = a * mc / 200000.0;
    let (delta, vega) = (a * ncdf(d1), a * f * phi(d1) * TE.sqrt());
    let delta_b = (black(f + 1e-6, K, VOL, a).0 - black(f - 1e-6, K, VOL, a).0) / 2e-6;
    let vega_b = (black(f, K, VOL + 1e-5, a).0 - black(f, K, VOL - 1e-5, a).0) / 2e-5;
    let up: Vec<f64> = QUOTES.iter().map(|q| q + 1e-4).collect();
    let dn: Vec<f64> = QUOTES.iter().map(|q| q - 1e-4).collect();
    let curve_d = (option_on(&up) - option_on(&dn)) / 2.0;
    let (lo_b, hi_b) = (a * (f - K).max(0.0), a * f);
    let iv_bis = bisect(|v| black(f, K, v, a).0 - pay, 1e-4, 5.0, 100);
    let mut v = 0.30;
    for _ in 0..8 { v -= (black(f, K, v, a).0 - pay) / (a * f * phi(black(f, K, v, a).2) * TE.sqrt()); }
    let iv_bad = bisect(|v| black(f, K, v, a).0 - (pay + fep), 1e-4, 5.0, 100);
    let iv_low = bisect(|v| black(f, K, v, a).0 - 0.0120, 1e-4, 5.0, 100);
    let spot_cds = |s: f64| { let h = bisect(|x| prot(0.0, 4.0, &[x]) - s * annuity(0.0, 4.0, &[x]), 0.0, 1.0, 60); annuity(0.0, 4.0, &[h]) };
    let ars: f64 = (5..21).map(|j| 0.25 * (-RATE * j as f64 / 4.0).exp()).sum();

    let rows: Vec<(&str, String)> = vec![
        ("hazard pieces 0-1, 1-3, 3-5y", format!("{:.6} {:.6} {:.6}", lam[0], lam[1], lam[2])), ("Q(1) survival to expiry, D(1)", format!("{:.6} {:.6}", surv(1.0, &lam), (-RATE * TE).exp())),
        ("forward risky annuity A, closed", format!("{:.6}", a)), ("  by simulated defaults", format!("{:.6}", a_mc)),
        ("forward protection leg %, closed", pc(p)), ("  by Simpson", pc(p_simp)),
        ("  by simulated defaults", pc(p_mc)), ("forward spread F bp", format!("{:.4}", 1e4 * f)),
        ("  by simulated defaults", format!("{:.4}", 1e4 * p_mc / a_mc)),
        ("ln(F/K), half variance", format!("{:.6} {:.6}", (f / K).ln(), 0.5 * sd * sd)), ("Black bracket F N(d1) - K N(d2) bp", format!("{:.4}", 1e4 * pay / a)),
        ("d1, d2", format!("{:.6} {:.6}", d1, d2)),
        ("N(d1), N(d2)", format!("{:.6} {:.6}", ncdf(d1), ncdf(d2))), ("payer % (knock-out), Black", pc(pay)),
        ("  by Simpson integral", pc(pay_int)), ("  by Monte Carlo", pc(pay_mc)),
        ("receiver %, Black", pc(rec)), ("  by Simpson integral", pc(rec_int)),
        ("payer - receiver %, integrals", pc(pay_int - rec_int)), ("A (F - K) %", pc(a * (f - K))),
        ("front-end protection %, closed", pc(fep)), ("  by simulated defaults", pc(fep_mc)),
        ("payer that keeps FEP %", pc(pay + fep)), ("delta, % per bp of F: A N(d1)", format!("{:.6}", delta * 1e-2)),
        ("  by bump", format!("{:.6}", delta_b * 1e-2)), ("  whole curve +-1bp, re-bootstrap", format!("{:.6}", 100.0 * curve_d)),
        ("vega, % per vol point: A F phi(d1)", format!("{:.6}", vega)), ("  by bump", format!("{:.6}", vega_b)),
        ("price range %: A(F-K)+ to A F", format!("{} {}", pc(lo_b), pc(hi_b))), ("implied vol from payer, bisection", format!("{:.6}", iv_bis)),
        ("  by Newton from 0.30", format!("{:.6}", v)), ("wrong: invert payer + FEP", format!("{:.6}", iv_bad)),
        ("premium 1.20% < floor: bisection", format!("{:.6}", iv_low)), ("wrong: D(1) as the unit %", pc(black(f, K, VOL, (-RATE).exp()).0)),
        ("wrong: riskless annuity as unit %", pc(black(f, K, VOL, ars).0)), ("wrong: spot 5y spread as forward %", pc(black(0.0250, K, VOL, a).0)),
        ("wrong: spot 5y annuity as unit %", pc(black(f, K, VOL, annuity(0.0, 5.0, &lam)).0)), ("try: vol 25% payer %", pc(black(f, K, 0.25, a).0)),
        ("try: strike 350bp payer %", pc(black(f, 0.035, VOL, a).0)),
    ];
    for (n, v) in &rows { println!("{:<36} {}", n, v); }
    let xs = [0.0150, 0.0200, 0.0250, 0.0300, 0.0350, 0.0400, 0.0450];
    let line = |lab: &str, v: Vec<String>| println!("{}{}", lab, v.join(" "));
    line("chart, spread at expiry (bp)  ", xs.iter().map(|s| format!("{:6.0}", 1e4 * s)).collect());
    line("chart, payer exercise (%)     ", xs.iter().map(|&s| format!("{:6.2}", 100.0 * spot_cds(s) * (s - K).max(0.0))).collect());
    line("chart, receiver exercise (%)  ", xs.iter().map(|&s| format!("{:6.2}", 100.0 * spot_cds(s) * (K - s).max(0.0))).collect());
    line("chart, vol (%)                ", (1..11).map(|i| format!("{:6}", 10 * i)).collect());
    line("chart, payer premium (%)      ", (1..11).map(|i| format!("{:6.2}", 100.0 * black(f, K, i as f64 / 10.0, a).0)).collect());

    assert!((p_simp - p).abs() < 1e-10 && (1e4 * (p_mc / a_mc - f)).abs() < 3.0, "forward spread: three roads agree");
    assert!((fep_mc - fep).abs() < 4.0 * se_fep, "front-end protection: closed form vs simulated defaults");
    assert!((pay_int - pay).abs() < 1e-7 && (pay_mc - pay).abs() < 0.01 * pay, "payer: formula, integral, simulation");
    assert!(((pay_int - rec_int) - a * (f - K)).abs() < 1e-7 && (rec_int - rec).abs() < 1e-7, "parity by the two integrals");
    assert!((delta_b - delta).abs() < 1e-6 && (vega_b - vega).abs() < 1e-6, "Greeks: bumps vs closed forms");
    assert!((iv_bis - VOL).abs() < 1e-9 && (v - VOL).abs() < 1e-9, "implied volatility recovers 50% by two roads");
    assert!(lo_b < pay && pay < hi_b && iv_low < 1e-3 && 0.0120 < lo_b, "below the floor there is no volatility");
    println!("ALL CHECKS PASS");
}
