// Bumping a simulated price -- the same check in Rust, std only, no crates.
// The bell-curve area is a series, the random numbers come from SplitMix64, both written
// out here; the exact variances come from Simpson's rule, never from the simulation.
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const CASH: f64 = 100.0; const NP: usize = 10000; const KINDS: [&str; 3] = ["fresh", "dig", "shared"];
fn w() -> f64 { SIG * T.sqrt() } fn disc() -> f64 { (-R * T).exp() } fn drift() -> f64 { (R - Q - 0.5 * SIG * SIG) * T }
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn area(x: f64) -> f64 {                          // bell-curve area left of x
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total) = (x, x);            // x + x^3/3 + x^5/(3*5) + ...
    for k in 1..120 { term *= x * x / (2 * k + 1) as f64; total += term; }
    0.5 + phi(x) * total
}
fn d2(s: f64) -> f64 { ((s / K).ln() + drift()) / w() }
fn call(s: f64) -> f64 { s * (-Q * T).exp() * area(d2(s) + w()) - K * disc() * area(d2(s)) }
fn digi(s: f64) -> f64 { CASH * disc() * area(d2(s)) }   // pays CASH if the share ends above K
fn zcut(s: f64) -> f64 { ((K / s).ln() - drift()) / w() } // draws above this finish in the money
fn grow(z: f64) -> f64 { (drift() + w() * z).exp() }
fn sq(x: f64) -> f64 { x.powf(2.0) }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // integral of f(z) phi(z)
    let m = 400; let hh = (b - a) / m as f64;
    let mut t = f(a) * phi(a) + f(b) * phi(b);
    for i in 1..m { let z = a + i as f64 * hh; t += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(z) * phi(z); }
    t * hh / 3.0
}
fn ey2(s: f64) -> f64 { simpson(&|z| sq(disc() * (s * grow(z) - K)), zcut(s), 9.0) }
struct Exact { b: f64, dc: f64, dd: f64, spc: f64, spd: f64 }
fn exact() -> Exact {
    let (b, w, disc) = (d2(S), w(), disc());
    Exact { b, dc: (-Q * T).exp() * area(b + w), dd: CASH * disc * phi(b) / (S * w),
            spc: -(-Q * T).exp() * phi(b + w) / (S * w) / S * ((b + w) / w + 1.0),
            spd: CASH * disc * phi(b) / (w * S.powf(3.0)) * (b * (b / w + 1.0) / w - 1.0 / w.powf(2.0) + 2.0 * (b / w + 1.0)) }
}
fn bias(e: &Exact, kind: &str, h: f64) -> f64 {
    if kind == "dig" { (digi(S + h) - digi(S - h)) / (2.0 * h) - e.dd } else { (call(S + h) - call(S - h)) / (2.0 * h) - e.dc }
}
fn var1(kind: &str, h: f64) -> f64 {              // exact variance of ONE path's estimate
    if kind == "fresh" { return (ey2(S + h) - sq(call(S + h)) + ey2(S - h) - sq(call(S - h))) / (4.0 * h * h); }
    let (up, dn) = (zcut(S + h), zcut(S - h));
    if kind == "dig" {
        let m2 = sq(CASH * disc() / (2.0 * h)) * (area(dn) - area(up));
        return m2 - sq(digi(S + h) - digi(S - h)) / (4.0 * h * h);
    }
    let m2 = simpson(&|z| sq(disc() * ((S + h) * grow(z) - K) / (2.0 * h)), up, dn)
        + simpson(&|z| sq(disc() * grow(z)), dn, 9.0);
    m2 - sq((call(S + h) - call(S - h)) / (2.0 * h))
}
fn rmse(e: &Exact, kind: &str, h: f64, n: f64) -> f64 { (sq(bias(e, kind, h)) + var1(kind, h) / n).sqrt() }
fn best(e: &Exact, kind: &str, n: f64) -> f64 {   // golden-section search on log h
    let (mut a, mut b, g) = (0.01f64.ln(), 60.0f64.ln(), (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..60 {
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if rmse(e, kind, c.exp(), n) < rmse(e, kind, d.exp(), n) { b = d; } else { a = c; }
    }
    (0.5 * (a + b)).exp()
}
fn theory(e: &Exact, kind: &str, n: f64) -> f64 { // best bump from the leading terms alone
    if kind == "fresh" { return ((ey2(S) - sq(call(S))) / 2.0 / (2.0 * sq(e.spc / 6.0) * n)).powf(1.0 / 6.0); }
    (CASH * CASH * disc() * disc() * phi(e.b) / (2.0 * S * w()) / (4.0 * sq(e.spd / 6.0) * n)).powf(0.2)
}
fn normals(seed: u64, n: usize) -> Vec<f64> {     // SplitMix64, then Box-Muller
    let (mut st, mut out) = (seed, Vec::with_capacity(n));
    let mut unif = || { st = st.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (st ^ (st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    for _ in 0..n / 2 {
        let rad = (-2.0 * unif().ln()).sqrt(); let ang = 2.0 * PI * unif();
        out.push(rad * ang.cos()); out.push(rad * ang.sin());
    }
    out
}
fn cpay(s: f64, z: f64) -> f64 { disc() * (s * grow(z) - K).max(0.0) }
fn dpay(s: f64, z: f64) -> f64 { if s * grow(z) > K { CASH * disc() } else { 0.0 } }
fn stats(xs: &[f64]) -> (f64, f64) {              // mean and standard error, in order
    let (n, mut m, mut v) = (xs.len() as f64, 0.0, 0.0);
    for x in xs { m += x; }
    m /= n; for x in xs { v += (x - m) * (x - m); }
    (m, (v / (n - 1.0) / n).sqrt())
}
fn estimate(kind: &str, h: f64, za: &[f64], zb: &[f64]) -> (f64, f64) {   // fresh: up on za, down on zb
    if kind == "fresh" {
        let (u, su) = stats(&za.iter().map(|&z| cpay(S + h, z)).collect::<Vec<f64>>());
        let (d, sd) = stats(&zb.iter().map(|&z| cpay(S - h, z)).collect::<Vec<f64>>());
        return ((u - d) / (2.0 * h), (su * su + sd * sd).sqrt() / (2.0 * h));
    }
    let pay = if kind == "dig" { dpay } else { cpay };
    stats(&za.iter().map(|&z| (pay(S + h, z) - pay(S - h, z)) / (2.0 * h)).collect::<Vec<f64>>())
}
fn main() {
    let e = exact();
    let truth = |k: &str| if k == "dig" { e.dd } else { e.dc };
    println!("--- 1. exact answers from the closed forms ---");
    println!("call:    price {:.6}  delta {:.6}  V''' {:.6}", call(S), e.dc, e.spc);
    println!("digital: price {:.6}  delta {:.6}  V''' {:.6}  from a bump {:.6}", digi(S), e.dd, e.spd, 6.0 * bias(&e, "dig", 0.1) / 0.01);
    let (za0, zb0) = (normals(20261111, NP), normals(777, NP));
    println!("--- 2. one run, {} paths per leg: delta (standard error) ---", NP);
    println!("{:>6}  {:>19}  {:>19}  {:>19}", "h", "fresh call", "shared call", "shared digital");
    let mut one: Vec<Vec<(f64, f64)>> = Vec::new();
    for h in [10.0, 1.0, 0.1, 0.01] {
        let row: Vec<(f64, f64)> = ["fresh", "shared", "dig"].iter().map(|k| estimate(k, h, &za0, &zb0)).collect();
        let cells: String = row.iter().map(|(m, s)| format!("  {:>9.4} ({:>7.4})", m, s)).collect();
        println!("{:>6.2}{}", h, cells); one.push(row);
    }
    for h in [1.0, 0.01] {
        let cells: String = ["fresh", "shared", "dig"].iter().map(|k| format!("  {:.4}", (var1(k, h) / NP as f64).sqrt())).collect();
        println!("exact se at h = {:.2}:{}", h, cells);
    }
    println!("digital paths whose two legs differ at h = 0.01: {}", za0.iter().filter(|&&z| dpay(S + 0.01, z) != dpay(S - 0.01, z)).count());
    println!("--- 3. exact root-mean-square error at the best bump, n paths per leg ---");
    println!("{:>8}  {:>8} {:>7} {:>8}  {:>10} {:>7} {:>8}  {:>14}", "n", "fresh h*", "theory", "rmse", "digital h*", "theory", "rmse", "shared, h=0.01");
    let mut rates: Vec<Vec<(f64, f64)>> = vec![Vec::new(), Vec::new(), Vec::new()];
    for n in [1000.0, 10000.0, 100000.0, 1000000.0] {
        for (i, k) in KINDS.iter().enumerate() {
            let hk = if *k == "shared" { 0.01 } else { best(&e, k, n) };
            rates[i].push((hk, rmse(&e, k, hk, n)));
        }
        let ((hf, ef), (hd, ed), (_, es)) = (rates[0][rates[0].len() - 1], rates[1][rates[1].len() - 1], rates[2][rates[2].len() - 1]);
        println!("{:>8}  {:>8.3} {:>7.3} {:>8.5}  {:>10.3} {:>7.3} {:>8.5}  {:>14.5}",
                 n as u64, hf, theory(&e, "fresh", n), ef, hd, theory(&e, "dig", n), ed, es);
    }
    let order: Vec<f64> = (0..3).map(|i| rates[i][2].1.log10() - rates[i][3].1.log10()).collect();
    println!("observed order, last decade: fresh {:.3} (theory 0.333)  digital {:.3} (theory 0.400)  shared {:.3} (theory 0.500)",
             order[0], order[1], order[2]);
    let (runs, hs, mut sqe) = (100u64, [rates[0][1].0, rates[1][1].0, rates[2][1].0], [0.0f64; 3]);
    for j in 0..runs {
        let (za, zb) = (normals(5000 + 2 * j, NP), normals(5001 + 2 * j, NP));
        for (i, k) in KINDS.iter().enumerate() { sqe[i] += sq(estimate(k, hs[i], &za, &zb).0 - truth(k)); }
    }
    println!("--- 4. {} independent runs of {} paths at those bumps: measured against exact ---", runs, NP);
    for (i, k) in KINDS.iter().enumerate() {
        println!("{:<7} h = {:>7.3}  bias {:+.5}  noise {:.5}  exact rmse {:.5}  measured {:.5}  measured/exact {:.3}", k, hs[i], bias(&e, k, hs[i]),
                 (var1(k, hs[i]) / NP as f64).sqrt(), rmse(&e, k, hs[i], NP as f64), (sqe[i] / runs as f64).sqrt(), (sqe[i] / runs as f64).sqrt() / rmse(&e, k, hs[i], NP as f64));
    }
    let nb = |k: &str, i: usize| (var1(k, hs[i]) / NP as f64).sqrt() / bias(&e, k, hs[i]).abs();
    println!("noise / |bias| at those bumps: fresh {:.2} (leading order {:.2}), digital {:.2} (leading order 2.00)", nb("fresh", 0), 2f64.sqrt(), nb("dig", 1));
    println!("--- 5. what breaks, {} paths per leg unless stated ---", NP);
    let hc = 2.0f64.powf(-52.0).powf(1.0 / 3.0) * S;   // the cube-root rule for a pricer with no noise
    println!("fresh call, cube-root bump {:.6}: exact se {:.1}", hc, (var1("fresh", hc) / NP as f64).sqrt());
    println!("fresh call, one-cent bump: one run gives {:.4}, se {:.4}", one[3][0].0, one[3][0].1);
    println!("shared digital, one-cent bump: exact rmse {:.4}, at its best bump {:.5}", rmse(&e, "dig", 0.01, NP as f64), rates[1][1].1);
    println!("fresh call, h = {:.3} kept at 1000000 paths: exact rmse {:.5}, at its best bump {:.5}",
             hs[0], rmse(&e, "fresh", hs[0], 1e6), rates[0][3].1);
    println!("--- 6. chart points, every value is log10 ---");
    for k in KINDS {
        let cells: String = [10.0, 1.0, 0.1, 0.01, 0.001].iter().map(|&h| format!(" {:.2}", (var1(k, h) / NP as f64).sqrt().log10())).collect();
        println!("chart, se at n = 10000, h = 10 to 0.001, {:<6}{}", k, cells);
    }
    for (i, k) in KINDS.iter().enumerate() {
        let cells: String = rates[i].iter().map(|&(_, r)| format!(" {:.2}", r.log10())).collect();
        println!("chart, best rmse, n = 1e3 to 1e6, {:<6}{}", k, cells);
    }
    let parts: [(&str, Box<dyn Fn(f64) -> f64>); 3] = [("bias", Box::new(|h| bias(&e, "fresh", h).abs())),
        ("noise", Box::new(|h| (var1("fresh", h) / NP as f64).sqrt())), ("rmse", Box::new(|h| rmse(&e, "fresh", h, NP as f64)))];
    for (lab, f) in parts.iter() {
        let cells: String = [32.0, 16.0, 8.0, 4.0, 2.0, 1.0].iter().map(|&h| format!(" {:.2}", f(h).log10())).collect();
        println!("chart, fresh call, h = 32 to 1, {:<5}{}", lab, cells);
    }
    assert!((6.0 * bias(&e, "dig", 0.1) / 0.01 - e.spd).abs() < 0.01 * e.spd.abs(), "digital V''' formula against a bump");
    assert!((one[3][0].1 / (var1("fresh", 0.01) / NP as f64).sqrt() - 1.0).abs() < 0.05, "fresh se: run against Simpson");
    assert!((one[1][2].1 / (var1("dig", 1.0) / NP as f64).sqrt() - 1.0).abs() < 0.10, "digital se: run against exact");
    assert!((one[3][1].0 - e.dc).abs() < 3.0 * one[3][1].1, "shared call delta within three standard errors");
    assert!(one[3][0].1 > 1000.0 * one[3][1].1, "fresh draws are 1000 times noisier at one cent");
    for i in 0..2 { assert!((rates[i][3].0 / theory(&e, KINDS[i], 1e6) - 1.0).abs() < 0.02, "best bump vs theory"); }
    for (i, p) in [1.0 / 3.0, 0.4, 0.5].iter().enumerate() { assert!((order[i] - p).abs() < 0.02, "order vs theorem"); }
    for i in 0..3 { assert!(((sqe[i] / runs as f64).sqrt() / rmse(&e, KINDS[i], hs[i], NP as f64) - 1.0).abs() < 0.2, "100 runs against the exact rmse"); }
    println!("ALL CHECKS PASS");
}
