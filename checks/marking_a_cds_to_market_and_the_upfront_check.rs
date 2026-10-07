// Valuing an existing CDS -- the check behind the card.  std only, no crates.
// The root finders, the integrator and the random numbers are written out below.
const R: f64 = 0.40; // recovery
const RATE: f64 = 0.05; // riskless rate
const T: f64 = 5.0; const DT: f64 = 0.25; // years left; premium period
const NOTIONAL: f64 = 10_000_000.0; const NQ: usize = 20; // $10m; twenty quarterly premium dates

fn annuity(lam: f64, n: usize) -> f64 {
    // road 1: add up n survival-weighted, discounted quarters
    (1..=n).map(|i| DT * (-(RATE + lam) * DT * i as f64).exp()).sum()
}
fn annuity_geom(lam: f64, n: usize) -> f64 {
    // road 2: the same sum as a geometric series
    let x = (-(RATE + lam) * DT).exp();
    DT * x * (1.0 - x.powi(n as i32)) / (1.0 - x)
}
fn protection(lam: f64, t_end: f64, rec: f64) -> f64 {
    let k = RATE + lam;
    (1.0 - rec) * lam / k * (1.0 - (-k * t_end).exp())
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}
fn par(lam: f64, rec: f64) -> f64 { protection(lam, T, rec) / annuity(lam, NQ) }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn newton(f: &dyn Fn(f64) -> f64, mut x: f64) -> f64 {
    let h = 1e-7;
    for _ in 0..40 {
        x -= f(x) / ((f(x + h) - f(x - h)) / (2.0 * h));
    }
    x
}
fn hazard_for(s: f64, rec: f64) -> f64 { bisect(&|l| par(l, rec) - s, 1e-12, 5.0) }
fn upfront(lam: f64, c: f64) -> f64 { protection(lam, T, R) - c * annuity(lam, NQ) }
fn curve_legs(hz: &[f64], n: usize) -> (f64, f64) { // piecewise hazard: hz[0] to 1y, hz[1] to 3y, hz[2] to 5y
    let (mut h_cum, mut p, mut a) = (0.0, 0.0, 0.0);
    for i in 1..=n {
        let h = hz[if i <= 4 { 0 } else if i <= 12 { 1 } else { 2 }]; let k = RATE + h;
        p += (1.0 - R) * h / k * (-RATE * DT * (i - 1) as f64 - h_cum).exp() * (1.0 - (-k * DT).exp());
        h_cum += h * DT; a += DT * (-RATE * DT * i as f64 - h_cum).exp();
    }
    (p, a)
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {
        // splitmix64, the same stream as the Python check
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn simulate(rng: &mut Rng, cum: &[f64], lam: f64, c: f64, paths: usize) -> (f64, f64, f64) {
    // road 3: draw default times, pay both legs path by path
    let (mut sv, mut sv2, mut sa) = (0.0, 0.0, 0.0);
    for _ in 0..paths {
        let tau = -rng.next().ln() / lam;
        let a = cum[((tau / DT) as usize).min(NQ)]; // premiums paid on dates before default
        let v = (if tau <= T { (1.0 - R) * (-RATE * tau).exp() } else { 0.0 }) - c * a;
        sv += v;
        sv2 += v * v;
        sa += a;
    }
    let p = paths as f64;
    let m = sv / p;
    (m, ((sv2 / p - m * m) / p).sqrt(), sa / p)
}

fn main() {
    let mut rng = Rng(20260928);
    let mut cum = vec![0.0];
    for i in 1..=NQ {
        let last = cum[i - 1];
        cum.push(last + DT * (-RATE * DT * i as f64).exp());
    }
    // ---- the old trade: protection bought at 120 bp, par is now 200 bp, five years left ----
    let (c, s_now) = (0.012, 0.020);
    let lam = hazard_for(s_now, R);
    let (a, a_g) = (annuity(lam, NQ), annuity_geom(lam, NQ));
    let x = (-(RATE + lam) * DT).exp();
    let p = protection(lam, T, R);
    let p_simp = simpson(&|t| (1.0 - R) * lam * (-(RATE + lam) * t).exp(), 0.0, T, 2000);
    let v = (s_now - c) * a;
    let v_legs = p_simp - c * a_g;
    let (v_mc, v_se, a_mc) = simulate(&mut rng, &cum, lam, c, 2_000_000);
    let v100 = (s_now - 0.01) * a;
    // ---- fixed coupon plus upfront: a name quoted at 250 bp ----
    let q = 0.025;
    let lam_q = hazard_for(q, R);
    let a_q = annuity(lam_q, NQ);
    let (u100, u500) = ((q - 0.01) * a_q, (q - 0.05) * a_q);
    let (u_mc, u_se, _) = simulate(&mut rng, &cum, lam_q, 0.01, 2_000_000);
    let back_b = par(bisect(&|l| upfront(l, 0.01) - u100, 1e-12, 5.0), R);
    let back_n = par(newton(&|l| upfront(l, 0.01) - u100, 0.05), R);
    let back_5 = par(bisect(&|l| upfront(l, 0.05) - u500, 1e-12, 5.0), R);
    let a_free = annuity(0.0, NQ);
    let mut hz: Vec<f64> = vec![]; // the bootstrapped curve: quotes 120, 200, 250 bp at 1, 3, 5 years
    for (n, s) in [(4usize, 0.012), (12, 0.020), (20, 0.025)] {
        let f = |h: f64| { let mut t = hz.clone(); t.extend([h; 3]); let (p, a) = curve_legs(&t, n); p / a - s };
        hz.push(bisect(&f, 1e-12, 5.0));
    }
    let (p_c, a_c) = curve_legs(&hz, NQ);
    let u_c = p_c - 0.01 * a_c;

    let rows: Vec<(&str, f64, usize)> = vec![
        ("house: par spread at hazard 2%, bp", 1e4 * par(0.02, R), 4), ("house: annuity at hazard 2%", annuity(0.02, NQ), 6),
        ("hazard that prices 200 bp", lam, 6), ("  credit-triangle guess 0.02/0.6", 0.02 / 0.6, 6),
        ("x = e^-(r+lam)/4", x, 6), ("x^20", x.powi(20), 6),
        ("annuity, 20-term sum", a, 6), ("annuity, geometric series", a_g, 6), ("annuity, simulated", a_mc, 6),
        ("protection leg, closed form", p, 6), ("protection leg, Simpson", p_simp, 6), ("premium leg at 120 bp", c * a, 6),
        ("1 value per $1, (s - c) A", v, 6), ("2 value per $1, P - c A", v_legs, 6),
        ("3 value per $1, simulated", v_mc, 6), ("  simulation standard error", v_se, 6),
        ("value on $10m", v * NOTIONAL, 2), ("100 bp contract on $10m", v100 * NOTIONAL, 2),
        ("  difference", (v100 - v) * NOTIONAL, 2), ("  20 bp x annuity x $10m", 0.002 * a * NOTIONAL, 2),
        ("hazard that prices 250 bp", lam_q, 6), ("annuity at 250 bp", a_q, 6),
        ("upfront %, coupon 100", 100.0 * u100, 4), ("upfront $ on $10m, coupon 100", u100 * NOTIONAL, 2),
        ("price, coupon 100", 100.0 * (1.0 - u100), 4), ("upfront %, coupon 100, simulated", 100.0 * u_mc, 4),
        ("  simulation standard error %", 100.0 * u_se, 4), ("upfront %, coupon 500", 100.0 * u500, 4),
        ("back to bp: bisection, coupon 100", 1e4 * back_b, 6), ("back to bp: Newton, coupon 100", 1e4 * back_n, 6),
        ("back to bp: bisection, coupon 500", 1e4 * back_5, 6), ("riskless annuity (hazard 0)", a_free, 6),
        ("lowest upfront %, coupon 100", -100.0 * 0.01 * a_free, 4), ("lowest upfront %, coupon 500", -100.0 * 0.05 * a_free, 4),
        ("highest upfront %, 1 - R", 100.0 * (1.0 - R), 4), ("curve annuity to 5y", a_c, 6),
        ("curve upfront %, 250 bp, coupon 100", 100.0 * u_c, 4), ("curve upfront $ on $10m", u_c * NOTIONAL, 2),
        ("wrong: inception annuity, $", 0.008 * annuity(0.02, NQ) * NOTIONAL, 2),
        ("wrong: riskless annuity, $", 0.008 * a_free * NOTIONAL, 2), ("wrong: 80 bp x 5 years, $", 0.008 * 5.0 * NOTIONAL, 2),
        ("wrong: coupon's hazard in upfront %", 100.0 * 0.015 * annuity(hazard_for(0.01, R), NQ), 4),
        ("try: R = 25%, upfront %, coupon 100", 100.0 * 0.015 * annuity(hazard_for(q, 0.25), NQ), 4),
        ("try: par falls to 80 bp, $", -0.004 * annuity(hazard_for(0.008, R), NQ) * NOTIONAL, 2),
    ];
    for (name, val, d) in &rows {
        println!("{:<38} {:>16.*}", name, *d, val);
    }
    println!("{:<38} {}", "curve hazards 0-1y, 1-3y, 3-5y", hz.iter().map(|h| format!("{:.6}", h)).collect::<Vec<_>>().join(" "));
    let line = |label: &str, xs: Vec<String>| println!("{}{}", label, xs.join(" "));
    let spreads: Vec<f64> = (1..=8).map(|k| 50.0 * k as f64).collect();
    line("chart, par today bp ", spreads.iter().map(|s| format!("{:7.0}", s)).collect());
    line("chart, value $k     ", spreads.iter().map(|s| format!("{:7.2}", (s / 1e4 - c) * annuity(hazard_for(s / 1e4, R), NQ) * 10000.0)).collect());
    line("chart, frozen $k    ", spreads.iter().map(|s| format!("{:7.2}", (s / 1e4 - c) * annuity(0.02, NQ) * 10000.0)).collect());
    let years = [5usize, 4, 3, 2, 1, 0];
    line("chart, years left   ", years.iter().map(|y| format!("{:7}", y)).collect());
    line("chart, mark $k      ", years.iter().map(|&y| format!("{:7.2}", (protection(lam, y as f64, R) - c * annuity(lam, 4 * y)) * 10000.0)).collect());
    let quotes: Vec<f64> = (1..=12).map(|k| 50.0 * k as f64).collect();
    line("chart, quote bp     ", quotes.iter().map(|s| format!("{:6.0}", s)).collect());
    line("chart, up% c=100    ", quotes.iter().map(|s| format!("{:6.2}", 100.0 * (s / 1e4 - 0.01) * annuity(hazard_for(s / 1e4, R), NQ))).collect());
    line("chart, up% c=500    ", quotes.iter().map(|s| format!("{:6.2}", 100.0 * (s / 1e4 - 0.05) * annuity(hazard_for(s / 1e4, R), NQ))).collect());

    assert!((par(0.02, R) - 0.01210561519).abs() < 1e-10, "house par spread, 121.06 bp");
    assert!((v - v_legs).abs() < 1e-10, "formula vs legs priced by Simpson and the geometric series");
    assert!((v_mc - v).abs() < 4.0 * v_se, "simulation lands within 4 standard errors");
    assert!((u_mc - u100).abs() < 4.0 * u_se, "simulated upfront within 4 standard errors");
    assert!((a_mc - a).abs() < 0.01, "simulated premium stream vs the annuity sum");
    assert!((back_b - q).abs() < 1e-12 && (back_n - q).abs() < 1e-12, "two root finders return the 250 bp quote");
    assert!((back_5 - q).abs() < 1e-12, "coupon 500 round trip returns 250 bp");
    assert!((a_c - 4.027235).abs() < 1e-6 && (p_c / a_c - q).abs() < 1e-12, "curve matches the bootstrap card");
    assert!((u_c - 0.0604).abs() < 5e-5 && u_c > u100, "curve upfront 6.04%, above the flat 5.95%");
    println!("ALL CHECKS PASS");
}
