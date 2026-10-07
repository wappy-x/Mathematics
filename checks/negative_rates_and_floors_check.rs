// Negative rates and floors -- the same check as negative_rates_and_floors_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so N(x) is built by adding thin
// slices under the bell curve (Simpson).  Bisection and random numbers written out too.
// Compile: rustc --edition 2021 -O negative_rates_and_floors_check.rs -o /tmp/nrf_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}
fn n_cdf(x: f64) -> f64 { if x < -12.0 { 0.0 } else if x > 12.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, x, 4000) } }
fn expect<P: Fn(f64) -> f64, L: Fn(f64) -> f64>(payoff: P, level: L, kink: f64) -> f64 {
    let g = |z: f64| payoff(level(z)) * phi(z);
    let k = kink.max(-10.0).min(10.0);
    simpson(&g, -10.0, k, 4000) + simpson(&g, k, 10.0, 4000)
}
fn bach(f: f64, k: f64, s: f64, t: f64, cp: f64) -> f64 {        // normal model, per unit of rate
    let w = s * t.sqrt();
    if w == 0.0 { return (cp * (f - k)).max(0.0); }
    let d = cp * (f - k) / w;
    cp * (f - k) * n_cdf(d) + w * phi(d)
}
fn black(f: f64, k: f64, s: f64, t: f64, cp: f64) -> f64 {       // Black-76; NaN when f/k is not positive
    let w = s * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * w * w) / w;
    cp * (f * n_cdf(cp * d1) - k * n_cdf(cp * (d1 - w)))
}
fn shifted(f: f64, k: f64, a: f64, s: f64, t: f64, cp: f64) -> f64 {
    if k + a <= 0.0 { return (cp * (f - k)).max(0.0); }          // strike at or below the wall
    black(f + a, k + a, s, t, cp)
}
fn matched(a: f64, f: f64, sn: f64, t: f64) -> Option<f64> {
    let target = sn * t.sqrt() / (2.0 * PI).sqrt();
    if target >= f + a { return None; }                             // the shift is too small
    let (mut lo, mut hi) = (1e-9, 50.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if shifted(f, f, a, mid, t, 1.0) < target { lo = mid } else { hi = mid }
    }
    Some(0.5 * (lo + hi))
}
fn pct(v: f64, w: usize, p: usize) -> String { format!("{:>w$.p$}%", v * 100.0, w = w - 1, p = p) }
fn row(name: &str, v: f64) { println!("{:<44}{:>14.2}", name, v); }

fn main() {
    let (m, tau, fq, k, sn) = (10_000_000.0_f64, 1.0_f64, -0.005_f64, 0.0_f64, 0.005_f64);
    let d: Vec<f64> = (0..4).map(|t| (1.0 + fq).powf(-(t as f64))).collect();
    let f: Vec<f64> = (0..3).map(|i| (d[i] / d[i + 1] - 1.0) / tau).collect();
    let t = [0.0_f64, 1.0, 2.0];
    println!("period  fixes  paid    D(paid)      forward");
    for i in 0..3 { println!("{:>6} {:>6.0} {:>5} {:>10.6} {}", i + 1, t[i], i + 1, d[i + 1], pct(f[i], 12, 6)); }
    for (kb, why) in [(k, "divides by a zero strike"), (0.0001, "log of a negative number")] {
        let v = black(f[1], kb, 0.30, 1.0, -1.0);
        if v.is_finite() { println!("black, F = -0.50%, K = {}: {:.6}", pct(kb, 1, 2), v); }
        else { println!("black, F = -0.50%, K = {}: no price ({})", pct(kb, 1, 2), why); }
    }
    row("black, F = +0.01%, K = 1e-8, floorlet $", 0.0 + (m * d[2] * black(1e-4, 1e-8, 0.30, 1.0, -1.0)).max(0.0));

    let (mut flo, mut flo_int, mut cap0, mut intr, mut leg) = (vec![], vec![], vec![], vec![], vec![]);
    for i in 0..3 {
        let (w, pay, fi) = (sn * t[i].sqrt(), m * tau * d[i + 1], f[i]);
        flo.push(pay * bach(fi, k, sn, t[i], -1.0));
        if w > 0.0 {
            let lvl = |z: f64| fi + w * z;
            flo_int.push(pay * expect(|l| (k - l).max(0.0), lvl, (k - fi) / w));
            cap0.push(pay * expect(|l| (l - k).max(0.0), lvl, (k - fi) / w));
        } else { flo_int.push(pay * (k - fi).max(0.0)); cap0.push(pay * (fi - k).max(0.0)); }
        intr.push(pay * (k - fi).max(0.0)); leg.push(pay * fi);
    }
    println!("period    floorlet     by integral    intrinsic   0-strike caplet   P(below 0)");
    for i in 0..3 {
        let pb = if t[i] > 0.0 { n_cdf((k - f[i]) / (sn * t[i].sqrt())) } else { 1.0 };
        println!("{:>6} {:>11.2} {:>14.2} {:>12.2} {:>12.2} {}", i + 1, flo[i], flo_int[i], intr[i], cap0[i], pct(pb, 12, 2));
    }
    let dd = |i: usize| (k - f[i]) / (sn * t[i].sqrt());               // by hand: periods 2 and 3
    println!("{:<26}{:>12}{:>12}", "by hand", "period 2", "period 3");
    let hand: [(&str, Box<dyn Fn(usize) -> f64>); 6] = [("wiggle w = sN sqrt(T), bp", Box::new(|i| 1e4 * sn * t[i].sqrt())), ("d = (K - F) / w", Box::new(dd)),
        ("N(d)", Box::new(|i| n_cdf(dd(i)))), ("phi(d)", Box::new(|i| phi(dd(i)))),
        ("floorlet bp, undiscounted", Box::new(|i| 1e4 * bach(f[i], k, sn, t[i], -1.0))),
        ("floorlet bp, times D", Box::new(|i| 1e4 * d[i + 1] * bach(f[i], k, sn, t[i], -1.0)))];
    for (name, g) in hand.iter() { println!("{:<26}{:>12.6}{:>12.6}", name, g(1), g(2)); }
    let mut x: u64 = 0x2545F4914F6CDD1D;
    let mut unif = || { x ^= x << 13; x ^= x >> 7; x ^= x << 17; ((x >> 11) as f64 + 0.5) / 9007199254740992.0 };
    let (n, mut tot, mut tot2) = (200_000usize, 0.0_f64, 0.0_f64);
    for _ in 0..n {                                                  // pay max(fixing, 0) on every path
        let (u1, u2) = (unif(), unif()); let z1 = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let (u3, u4) = (unif(), unif()); let z2 = (-2.0 * u3.ln()).sqrt() * (2.0 * PI * u4).cos();
        let v: f64 = [(0usize, 0.0_f64), (1, z1), (2, z2)].iter()
            .map(|&(i, z)| m * tau * d[i + 1] * (f[i] + sn * t[i].sqrt() * z).max(0.0)).sum();
        tot += v; tot2 += v * v;
    }
    let (mc, se) = (tot / n as f64, ((tot2 / n as f64 - (tot / n as f64).powi(2)) / n as f64).sqrt());
    let s = |v: &Vec<f64>| -> f64 { v.iter().sum() };
    row("one basis point, one year, on the loan", m * tau * 1e-4);
    row("unfloored leg, sum D tau F M", s(&leg)); row("unfloored leg, M (D(0) - D(3))", m * (d[0] - d[3]));
    row("floor, normal formula", s(&flo)); row("floor, integral", s(&flo_int)); row("floor, intrinsic only", s(&intr));
    row("floor, time value", s(&flo) - s(&intr)); row("floored leg = leg + floor", s(&leg) + s(&flo));
    row("floored leg = zero-strike cap", s(&cap0)); row("floored leg, Monte Carlo", mc); row("  Monte Carlo std error", se);

    println!("smallest shift that can match, 1y and 2y: {} {}", pct(-f[1] + sn * (1.0 / (2.0 * PI)).sqrt(), 1, 4), pct(-f[2] + sn * (2.0 / (2.0 * PI)).sqrt(), 1, 4));
    println!("shift  vol 1y match  vol 2y match     floor $   floored leg $   by integral");
    let (mut s1_2, mut fl10) = (0.0, 0.0);
    for a in [0.0075_f64, 0.01, 0.02, 0.03, 0.10] {
        let s1 = matched(a, f[1], sn, 1.0).unwrap();
        let s2 = match matched(a, f[2], sn, 2.0) {
            Some(v) => v,
            None => { println!("{} {}          none    no price: the 2y quote cannot be matched", pct(a, 5, 2), pct(s1, 12, 2)); continue; }
        };
        let fl = [flo[0], m * tau * d[2] * shifted(f[1], k, a, s1, 1.0, -1.0), m * tau * d[3] * shifted(f[2], k, a, s2, 2.0, -1.0)];
        let g2 = f[2] + a;
        let chk = m * tau * d[3] * expect(|l| (k + a - l).max(0.0), |z| g2 * (-0.5 * s2 * s2 * 2.0 + s2 * 2.0_f64.sqrt() * z).exp(),
                                          (((k + a) / g2).ln() + s2 * s2) / (s2 * 2.0_f64.sqrt()));
        let sf: f64 = fl.iter().sum();
        println!("{} {} {} {:>11.2} {:>15.2} {:>13.2}", pct(a, 5, 2), pct(s1, 12, 2), pct(s2, 13, 2), sf, s(&leg) + sf, chk + fl[0] + fl[1] + s(&leg));
        assert!((chk - fl[2]).abs() < 1e-4, "shifted formula vs integral, year-3 floorlet");
        if a == 0.02 { s1_2 = s1; }
        if a == 0.10 { fl10 = sf; }
    }

    let ks = [-0.015_f64, -0.0125, -0.01, -0.0075, -0.005, -0.0025, 0.0, 0.0025, 0.005];
    let s1a = matched(0.01, f[1], sn, 1.0).unwrap();
    let line = |lab: &str, g: &dyn Fn(f64) -> f64| println!("{:<22}{}", lab, ks.iter().map(|&kk| format!(" {:>7.2}", g(kk))).collect::<String>());
    println!("{:<22}{}", "chart, strike bp", ks.iter().map(|&kk| format!(" {:>7.0}", kk * 1e4)).collect::<String>());
    line("chart, normal", &|kk| 1e4 * d[2] * bach(f[1], kk, sn, 1.0, -1.0));
    line("chart, shift 2%", &|kk| 1e4 * d[2] * shifted(f[1], kk, 0.02, s1_2, 1.0, -1.0));
    line("chart, shift 1%", &|kk| 1e4 * d[2] * shifted(f[1], kk, 0.01, s1a, 1.0, -1.0));

    row("wrong: skip period 1, it has fixed", s(&flo) - flo[0]);
    row("wrong: discount at 1, not D > 1", (0..3).map(|i| flo[i] / d[i + 1]).sum());
    row("wrong: 2% shift's vol used at 1% shift", flo[0] + [1usize, 2].iter().map(|&i| m * tau * d[i + 1] * shifted(f[i], k, 0.01, matched(0.02, f[i], sn, t[i]).unwrap(), t[i], -1.0)).sum::<f64>());
    row("try: normal vol 1.00%", (0..3).map(|i| m * tau * d[i + 1] * bach(f[i], k, 0.01, t[i], -1.0)).sum());
    row("try: floor at -0.25%, floored leg", s(&leg) + (0..3).map(|i| m * tau * d[i + 1] * bach(f[i], -0.0025, sn, t[i], -1.0)).sum::<f64>());

    assert!((s(&leg) - m * (d[0] - d[3])).abs() < 1e-6, "leg period by period vs the telescoped curve");
    assert!((s(&flo) - s(&flo_int)).abs() < 1e-4, "normal formula vs brute-force integral");
    assert!((s(&leg) + s(&flo) - s(&cap0)).abs() < 1e-4, "leg + floor must equal the zero-strike cap, priced separately");
    assert!((mc - (s(&leg) + s(&flo))).abs() < 4.0 * se, "Monte Carlo within four standard errors");
    assert!(s(&flo) > s(&intr) && (fl10 - s(&flo)).abs() < 0.01 * s(&flo), "floor above intrinsic; wide shift near normal");
    println!("ALL CHECKS PASS");
}
