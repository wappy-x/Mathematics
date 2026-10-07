// Barone-Adesi-Whaley American put -- the same check as the Python, in Rust.  No crates.
// Rust has no erf, so the bell-curve area is built by adding thin slices under the curve
// (Simpson's rule).  The critical price is found twice (Newton, then bisection), and the
// honest reference is a Cox-Ross-Rubinstein tree that checks early exercise at every node.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height at x
fn n_cdf(x: f64) -> f64 {                                                // area left of x
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let n = 4000; let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}

fn d1(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt())
}
fn euro_put(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let a = d1(s, k, r, q, v, t);
    k * (-r * t).exp() * n_cdf(-(a - v * t.sqrt())) - s * (-q * t).exp() * n_cdf(-a)
}
fn beta(r: f64, q: f64, v: f64, h: f64, sign: f64) -> f64 {   // roots of b^2 + (n-1) b - m/h = 0
    let (m, n) = (2.0 * r / (v * v), 2.0 * (r - q) / (v * v));
    (-(n - 1.0) + sign * ((n - 1.0).powi(2) + 4.0 * m / h).sqrt()) / 2.0
}
fn gap(x: f64, k: f64, r: f64, q: f64, v: f64, t: f64, b: f64) -> f64 {   // value matching at x
    let lump = -(x / b) * (1.0 - (-q * t).exp() * n_cdf(-d1(x, k, r, q, v, t)));
    euro_put(x, k, r, q, v, t) + lump - (k - x)
}
fn newton(k: f64, r: f64, q: f64, v: f64, t: f64, b: f64, trace: &mut Vec<(usize, f64)>) -> f64 {
    let binf = beta(r, q, v, 1.0, -1.0);
    let sinf = k * binf / (binf - 1.0);                                      // the perpetual boundary
    let mut x = sinf + (k - sinf) * (((r - q) * t - 2.0 * v * t.sqrt()) * k / (k - sinf)).exp();
    trace.push((0, x));
    for it in 1..50 {
        let (a, eq) = (d1(x, k, r, q, v, t), (-q * t).exp());
        let slope = -eq * n_cdf(-a) * (1.0 - 1.0 / b) - (1.0 + eq * phi(a) / (v * t.sqrt())) / b + 1.0;
        let new = x - gap(x, k, r, q, v, t, b) / slope;
        trace.push((it, new));
        if (new - x).abs() < 1e-12 * k { return new; }
        x = new;
    }
    x
}
fn crit(k: f64, r: f64, q: f64, v: f64, t: f64, b: f64) -> f64 { newton(k, r, q, v, t, b, &mut Vec::new()) }
fn bisect(k: f64, r: f64, q: f64, v: f64, t: f64, b: f64) -> f64 {   // second road to the same price
    let (mut lo, mut hi) = (1.0, k);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if gap(mid, k, r, q, v, t, b) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn baw_with(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64, b: f64, x: f64) -> f64 {
    if s <= x { return k - s; }                                              // exercise now
    let a = -(x / b) * (1.0 - (-q * t).exp() * n_cdf(-d1(x, k, r, q, v, t)));
    euro_put(s, k, r, q, v, t) + a * (s / x).powf(b)
}
fn baw_put(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let b = beta(r, q, v, 1.0 - (-r * t).exp(), -1.0);
    baw_with(s, k, r, q, v, t, b, crit(k, r, q, v, t, b))
}
fn tree_put(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64, steps: usize) -> f64 {
    let dt = t / steps as f64;
    let u = (v * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d); let disc = (-r * dt).exp();
    let node = |i: usize, j: usize| s * u.powi(j as i32) * d.powi((i - j) as i32);
    let mut w: Vec<f64> = (0..=steps).map(|j| (k - node(steps, j)).max(0.0)).collect();
    for i in (0..steps).rev() {
        w = (0..=i).map(|j| (disc * (p * w[j + 1] + (1.0 - p) * w[j])).max(k - node(i, j))).collect();
    }
    w[0]
}

fn main() {
    let (s, k, r, q, v, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let h = 1.0 - (-r * t).exp();
    let (m, n) = (2.0 * r / (v * v), 2.0 * (r - q) / (v * v));
    let (b1, b2) = (beta(r, q, v, h, -1.0), beta(r, q, v, h, 1.0));
    let mut trace = Vec::new();
    let x = newton(k, r, q, v, t, b1, &mut trace);
    let xb = bisect(k, r, q, v, t, b1);
    let na = n_cdf(-d1(x, k, r, q, v, t));
    let a = -(x / b1) * (1.0 - (-q * t).exp() * na);
    let eu = euro_put(s, k, r, q, v, t);
    let lump = a * (s / x).powf(b1);
    let baw = eu + lump;
    let (t2000, t4000) = (tree_put(s, k, r, q, v, t, 2000), tree_put(s, k, r, q, v, t, 4000));
    let e = 1e-5;
    let slope = (baw_put(x + 2.0 * e, k, r, q, v, t) - baw_put(x + e, k, r, q, v, t)) / e;
    let binf = beta(r, q, v, 1.0, -1.0);
    let sinf = k * binf / (binf - 1.0);
    let perp = (k - sinf) * (s / sinf).powf(binf);
    let long = baw_put(s, k, r, q, v, 200.0);
    let mut rows: Vec<(String, f64)> = vec![
        ("m = 2r/sigma^2".into(), m), ("n = 2(r-q)/sigma^2".into(), n), ("h = 1 - e^-rT".into(), h),
        ("beta1, negative root".into(), b1), ("beta2, positive root".into(), b2), ("perpetual boundary".into(), sinf)];
    for (i, xi) in &trace { rows.push((format!("Newton step {}", i), *xi)); }
    let bp = beta(r, q, v, 1.0, -1.0);
    let xp = crit(k, r, q, v, t, bp);
    let ak = -(k / b1) * (1.0 - (-q * t).exp() * n_cdf(-d1(k, k, r, q, v, t)));
    let wrong_root = eu - (x / b2) * (1.0 - (-q * t).exp() * na) * (s / x).powf(b2);
    let more: Vec<(&str, f64)> = vec![
        ("S* by bisection", xb), ("d1 at S*", d1(x, k, r, q, v, t)), ("A, lump at S*", a),
        ("(S/S*)^beta1", (s / x).powf(b1)), ("European put", eu), ("lump at S = 100", lump),
        ("BAW American put", baw), ("tree, 2000 steps", t2000), ("tree, 4000 steps", t4000),
        ("BAW - tree", baw - t2000), ("premium, tree", t2000 - eu),
        ("slope just above S*", slope), ("perpetual put, exact", perp), ("BAW at T = 200 years", long)];
    for (nm, val) in more { rows.push((nm.to_string(), val)); }
    for (nm, val) in &rows { println!("{:<26}{:>14.6}", nm, val); }
    println!("{:<26}{:>14}", "tree node visits", (1..=2000u64).sum::<u64>());
    let wrongs: Vec<(&str, f64)> = vec![
        ("wrong: positive root", wrong_root),
        ("wrong: h = 1, own S*", baw_with(s, k, r, q, v, t, bp, xp)), ("  its S*", xp),
        ("wrong: S* = K, no Newton", eu + ak * (s / k).powf(b1)),
        ("wrong: no floor, S = 70", euro_put(70.0, k, r, q, v, t) + a * (70.0 / x).powf(b1)),
        ("  tree at S = 70", tree_put(70.0, k, r, q, v, t, 2000))];
    for (nm, val) in &wrongs { println!("{:<26}{:>14.6}", nm, val); }

    println!("\nerror table: K=100 r=5% q=2% sigma=20%, tree 2000 steps");
    println!("{:>5}{:>6}{:>9}{:>10}{:>10}{:>10}{:>10}", "T", "S", "S*", "European", "BAW", "tree", "BAW-tree");
    let mats = [0.25_f64, 0.5, 1.0, 2.0, 3.0];
    let spots = [90.0_f64, 100.0, 110.0];
    let mut errs = vec![vec![0.0_f64; mats.len()]; spots.len()];
    let mut worst = 0.0_f64;
    for (ti, &tm) in mats.iter().enumerate() {
        let xm = crit(k, r, q, v, tm, beta(r, q, v, 1.0 - (-r * tm).exp(), -1.0));
        for (si, &sp) in spots.iter().enumerate() {
            let (eu_m, b_m, t_m) = (euro_put(sp, k, r, q, v, tm), baw_put(sp, k, r, q, v, tm), tree_put(sp, k, r, q, v, tm, 2000));
            errs[si][ti] = b_m - t_m;
            worst = worst.max((b_m - t_m).abs());
            println!("{:>5.2}{:>6.0}{:>9.2}{:>10.4}{:>10.4}{:>10.4}{:>+10.4}", tm, sp, xm, eu_m, b_m, t_m, b_m - t_m);
            assert!(b_m >= eu_m && b_m >= k - sp, "American must beat European and exercise");
        }
    }
    for (si, &sp) in spots.iter().enumerate() {
        let cells: Vec<String> = errs[si].iter().map(|e| format!("{:.2}", 100.0 * e)).collect();
        println!("chart, error in cents, S = {:.0}: {}", sp, cells.join(", "));
    }

    assert!((x - xb).abs() < 1e-8, "Newton and bisection must find the same critical price");
    assert!((eu - 6.330080627550).abs() < 1e-9, "European put against the house number");
    assert!((t2000 - 6.660226).abs() < 5e-7 && (t4000 - t2000).abs() < 1e-3, "tree: house number, and settled");
    assert!((baw - 6.672215293).abs() < 1e-8, "BAW price against an independent implementation");
    assert!((baw - t2000).abs() < 0.02, "BAW within two cents of the tree at the house option");
    assert!((slope + 1.0).abs() < 1e-4, "smooth pasting: slope -1 just above S*");
    assert!((long - perp).abs() < 1e-3, "long life must reach the exact perpetual put");
    assert!(0.02 < worst && worst < 0.20, "errors are cents, not zero and not dollars");
    println!("ALL CHECKS PASS");
}
