// Zero-coupon inflation swap -- the same check as zero_coupon_inflation_swaps_check.py, in Rust.
// Standard library only, no crates.  Three roads to the 5-year par rate: the bond-price
// ratio, bisection on the legs, and state-by-state sums in four random economies.
use std::f64::consts::PI;

const N: f64 = 1_000_000.0; const F: f64 = 1_000_000.0; const C: f64 = 0.01;
const Y: f64 = 0.01;
const TEN: [u32; 7] = [1, 2, 3, 4, 5, 7, 10];
const J_SO_FAR: f64 = 1.06; const K_OLD: f64 = 0.023; const T_OLD: f64 = 7.0;

fn nom(t: u32) -> f64 {
    match t { 1 => 0.0302, 2 => 0.03222, 3 => 0.033735, 4 => 0.03525, 5 => 0.03626, 7 => 0.035755, _ => 0.03525 }
}
fn d(t: u32) -> f64 { (1.0 + nom(t)).powf(-(t as f64)) }             // nominal zero
fn r(t: u32) -> f64 { (1.0 + Y).powf(-(t as f64)) }                  // real zero
fn par(t: u32) -> f64 { (r(t) / d(t)).powf(1.0 / t as f64) - 1.0 }    // road 1
fn a(t: u32) -> f64 { (1.0 + par(t)).powf(t as f64) }                // index forward

fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {
    let mut flo = f(lo);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi); let fm = f(mid);
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn value(k: f64, j0: f64, e: f64) -> f64 { N * (j0 * r(5) - (1.0 + k).powf(e) * d(5)) }

struct Rng { s: u64 }
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.s >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { let u1 = self.u(); let u2 = self.u(); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }
}

fn economy(seed: u64, vol: f64, tilt: f64) -> (f64, f64, f64) {
    let s = 4000;
    let mut g = Rng { s: seed };
    let z: Vec<f64> = (0..s).map(|_| g.normal()).collect();
    let mut j: Vec<f64> = z.iter().map(|x| (vol * 5f64.sqrt() * x).exp()).collect();
    let w: Vec<f64> = z.iter().map(|x| (tilt * x + 0.3 * g.normal()).exp()).collect();
    let sw: f64 = w.iter().sum();
    let psi: Vec<f64> = w.iter().map(|x| d(5) * x / sw).collect();
    let sc = r(5) / psi.iter().zip(&j).map(|(p, q)| p * q).sum::<f64>();
    for q in j.iter_mut() { *q *= sc; }
    let val = |k: f64, j0: f64, e: f64| psi.iter().zip(&j).map(|(p, q)| p * N * (j0 * q - (1.0 + k).powf(e))).sum::<f64>();
    let plain = (j.iter().sum::<f64>() / s as f64).powf(0.2) - 1.0;
    (plain, bisect(|k| val(k, 1.0, 5.0), -0.5, 0.5), val(K_OLD, J_SO_FAR, T_OLD))
}

fn clean(v: f64, p: i32) -> f64 { let m = 10f64.powi(p); (v * m).round() / m + 0.0 }
fn show(name: &str, v: f64) { println!("{:<40} {:>16.6}", name, clean(v, 6)); }

fn main() {
    println!("inputs: notional {:.2}  real yield {:.2}%  index so far {:.2}  old fixed {:.2}% for {}y", N, 100.0 * Y, J_SO_FAR, 100.0 * K_OLD, T_OLD as u32);
    let (k1, k2) = (par(5), bisect(|k| value(k, 1.0, 5.0), -0.5, 0.5));
    let seasoned = value(K_OLD, J_SO_FAR, T_OLD);
    for (name, v) in [("nominal zero D(5)", d(5)), ("real zero R(5)", r(5)), ("index forward A(5)", a(5)),
        ("par rate, road 1 bond ratio %", 100.0 * k1), ("par rate, road 2 bisection %", 100.0 * k2),
        ("seasoned inflation leg, N 1.06 R(5)", N * J_SO_FAR * r(5)), ("old fixed factor 1.023^7", (1.0 + K_OLD).powf(T_OLD)),
        ("seasoned fixed leg, N 1.023^7 D(5)", N * (1.0 + K_OLD).powf(T_OLD) * d(5)), ("seasoned swap value, formula", seasoned)] { show(name, v); }
    let econ = [economy(11, 0.01, 0.0), economy(22, 0.02, -1.0), economy(33, 0.03, 1.0), economy(44, 0.04, 0.5)];
    for (i, (plain, kp, sv)) in econ.iter().enumerate() {
        println!("economy {}: plain average {:.4}%  par {:.6}%  seasoned {:.6}", i + 1, 100.0 * plain, 100.0 * kp, sv);
    }
    let payout = N * (1.15 - a(5));
    show("receiver gets, index ratio 1.15", payout); show("zero linker plus pay-inflation swap", N * 1.15 - payout);

    let (h, b, n5) = (1e-4, k1, nom(5));
    let vb = |bb: f64, j0: f64, k: f64, e: f64| N * d(5) * (j0 * (1.0 + bb).powi(5) - (1.0 + k).powf(e));
    let vn = |nn: f64, j0: f64, k: f64, e: f64| N * (1.0 + nn).powi(-5) * (j0 * a(5) - (1.0 + k).powf(e));
    let mut gaps: Vec<f64> = Vec::new();
    for (tag, j0, k, e) in [("par", 1.0, k1, 5.0), ("seasoned", J_SO_FAR, K_OLD, T_OLD)] {
        let v0 = vb(b, j0, k, e);
        let (be, be_b) = (N * d(5) * j0 * 5.0 * (1.0 + b).powi(4) * h, (vb(b + h, j0, k, e) - vb(b - h, j0, k, e)) / 2.0);
        let (no, no_b) = (-5.0 * v0 / (1.0 + n5) * h, (vn(n5 + h, j0, k, e) - vn(n5 - h, j0, k, e)) / 2.0);
        gaps.extend([(be - be_b).abs(), (no - no_b).abs()]);
        println!("{:<9} breakeven01 {:10.4} bump {:10.4}  nominal01 {:9.4} bump {:9.4}  index01 {:9.4}", tag,
            be, be_b, clean(no, 4), clean(no_b, 4), N * r(5) * 0.001);
    }

    let mut fwd = std::collections::HashMap::new();
    let mut prev = 0u32;
    for &t in TEN.iter() {
        let base = if prev > 0 { a(prev) } else { 1.0 };
        let f = (a(t) / base).powf(1.0 / (t - prev) as f64) - 1.0;
        fwd.insert(t, f);
        println!("curve {:>2}y  nominal {:.4}%  breakeven {:.4}%  A {:.6}  forward {:.4}%", t, 100.0 * nom(t), 100.0 * par(t), a(t), 100.0 * f);
        prev = t;
    }
    println!("chart, breakeven %  {}", TEN.iter().map(|&t| format!("{:.2}", 100.0 * par(t))).collect::<Vec<_>>().join(" "));
    println!("chart, forward %    {}", TEN.iter().map(|t| format!("{:.2}", 100.0 * fwd[t])).collect::<Vec<_>>().join(" "));
    let seg = |yr: u32| fwd[TEN.iter().find(|&&t| t >= yr).unwrap()];
    let mut rebuilt = 1.0;
    for yr in 1..=10 { rebuilt *= 1.0 + seg(yr); }
    show("10y rebuilt from forwards %", 100.0 * (rebuilt.powf(0.1) - 1.0));
    show("6y by flat forward %", 100.0 * ((a(5) * (1.0 + seg(6))).powf(1.0 / 6.0) - 1.0));

    let flow = |t: u32| C * F + if t == 5 { F } else { 0.0 };
    let price: f64 = (1..=5).map(|t| C * F * r(t)).sum::<f64>() + F * r(5);
    let hedge = [10_000.0, 10_000.0, 10_000.0, 10_000.0, 1_010_000.0];   // swap notionals, as the card's table
    let locked: Vec<f64> = (1..=5).map(|t| hedge[t as usize - 1] * a(t)).collect();
    let pv_locked: f64 = (1..=5).map(|t| locked[t as usize - 1] * d(t)).sum();
    let (mut g, mut worst, mut worst_p, mut floored, mut worst_floor) = (Rng { s: 7 }, 0.0f64, 0.0f64, 0, 0.0f64);
    for _ in 0..20000 {
        let mut j = 1.0;
        for t in 1..=5u32 {
            j *= 1.0 + 0.025 + 0.02 * g.normal();
            let (note, i) = (flow(t) * j, t as usize - 1);
            worst = worst.max((note + hedge[i] * (a(t) - j) - locked[i]).abs());
            worst_p = worst_p.max((note + if t == 5 { F * (a(5) - j) } else { 0.0 } - locked[i]).abs());
        }
        if j < 1.0 { floored += 1; worst_floor = worst_floor.max(F * (1.0 - j)); }
    }
    show("linker price, real discounting", price); show("hedged cash, nominal discounting", pv_locked);
    println!("locked cash, years 1-5 {}", locked.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" "));
    println!("paths 20000  worst hedge miss {:.6}  paths under base {}  worst floor residue {:.2}", worst, floored, worst_floor);
    show("floor residue, index ratio 0.95", F * 0.95f64.max(1.0) + F * (a(5) - 0.95) - F * a(5));

    let miss4: f64 = (1..=5).map(|t| C * F * (1.04f64.powi(t as i32) - a(t))).sum();
    for (name, v) in [("wrong: simple fixed leg, payout at 1.15", N * (1.15 - (1.0 + 5.0 * 0.026))),
        ("wrong: new swap valued with simple leg", N * (r(5) - (1.0 + 5.0 * 0.026) * d(5))),
        ("wrong: seasoned marked as new", value(K_OLD, 1.0, 5.0)),
        ("wrong: seasoned discounted at real rate", N * r(5) * (J_SO_FAR * a(5) - (1.0 + K_OLD).powf(T_OLD))),
        ("wrong: principal-only hedge, 4% coupons", miss4),
        ("try: old swap at 2.5%, same dates", value(0.025, 1.0, 5.0)), ("try: payout if inflation is 2.6%", N * (1.026f64.powi(5) - a(5)))] {
        show(name, v);
    }
    let pis: Vec<f64> = (0..11).map(|i| 0.005 * i as f64).collect();
    println!("chart, inflation % a year {}", pis.iter().map(|p| format!("{:.1}", 100.0 * p)).collect::<Vec<_>>().join(" "));
    println!("chart, payout $000        {}", pis.iter().map(|p| format!("{:.2}", N * ((1.0 + p).powi(5) - a(5)) / 1000.0)).collect::<Vec<_>>().join(" "));

    assert!((k1 - 0.026).abs() < 1e-12, "bond ratio must give the 2.6% quote");
    assert!((k2 - k1).abs() < 1e-12, "bisection on the legs lands on the ratio");
    assert!(econ.iter().all(|e| (e.1 - k1).abs() < 1e-10 && (e.2 - seasoned).abs() < 1e-6), "every economy agrees");
    let (lo, hi) = econ.iter().fold((f64::MAX, f64::MIN), |(l, h), e| (l.min(e.0), h.max(e.0)));
    assert!(hi - lo > 0.001, "forecasts differ, prices do not");
    assert!((payout - 13061.943239).abs() < 1e-5, "audited payout at index ratio 1.15");
    assert!((rebuilt - 1.025f64.powi(10)).abs() < 1e-12, "forwards multiply back to the 10-year house breakeven");
    assert!((price - F).abs() < 1e-6 && (pv_locked - F).abs() < 1e-6, "coupon equals real yield: both roads price the linker at face");
    assert!(worst < 1e-6 && worst_p > 100.0, "the strip hedge leaves no inflation on any path; principal-only does");
    assert!(gaps.iter().all(|&x| x < 0.005), "every Greek matches its bump to the cent");
    println!("ALL CHECKS PASS");
}
