// Multilevel Monte Carlo -- the same check as the Python, in Rust.  No crates.  Nothing imported
// knows an answer: uniforms from the recurrence of the Monte Carlo pricing card, normals by Box-Muller,
// every integral by Simpson's rule, exact Euler prices from a density convolved with itself on a grid.
use std::f64::consts::PI;
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const MU: f64 = R - Q; const MOD: u64 = 1 << 32;
const SEED: u64 = 20260914; const PILOT: usize = 20000; const L: usize = 6; const EPS: f64 = 0.01;
const EXACT: f64 = 9.227005508154;                         // the call card's price
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // every integral on this card
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn row(name: &str, v: f64) { println!("{:<44}{:>12.6}", name, v); } fn rowi(name: &str, v: u64) { println!("{:<44}{:>12}", name, v); }
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }      // bell-curve height
fn ncdf(x: f64) -> f64 { 0.5 + simpson(&phi, 0.0, x, 4000) }           // bell-curve area to the left
fn disc() -> f64 { (-R * T).exp() }
fn bs_call() -> f64 {                                      // road 1: Black-Scholes
    let vt = SIG * T.sqrt();
    let d1 = ((S0 / K).ln() + (MU + 0.5 * SIG * SIG) * T) / vt;
    S0 * (-Q * T).exp() * ncdf(d1) - K * (-R * T).exp() * ncdf(d1 - vt)
}
fn normals(st: &mut u64, count: usize) -> Vec<f64> {      // the recurrence, then Box-Muller, in pairs
    let mut out = Vec::new();
    while out.len() < count {
        *st = (1664525 * *st + 1013904223) % MOD;
        let rad = (-2.0 * ((*st as f64 + 0.5) / MOD as f64).ln()).sqrt();
        *st = (1664525 * *st + 1013904223) % MOD;
        let ang = 2.0 * PI * (*st as f64 + 0.5) / MOD as f64;
        out.push(rad * ang.cos()); out.push(rad * ang.sin());
    }
    out
}
fn cost(l: usize) -> u64 { if l == 0 { 1 } else { 3 << (l - 1) } }   // fine steps plus coarse steps
fn euler_end(dws: &[f64], h: f64) -> f64 {                // Euler's terminal reading along given increments
    let mut y = S0;
    for dw in dws { y *= 1.0 + MU * h + SIG * dw; }
    y
}
fn level(l: usize, n: usize, st: &mut u64) -> ([f64; 6], usize) {   // n samples of P_l - P_(l-1), shared increments
    let nf = 1usize << l;
    let (hf, mut s, mut done) = (T / nf as f64, [0.0f64; 6], 0usize);
    while done < n {
        let zs = normals(st, nf);
        let mut j = 0;
        while j < zs.len() {                              // level 0 uses both draws of a pair
            let fine: Vec<f64> = zs[j..j + nf].iter().map(|z| z * hf.sqrt()).collect();
            let pf = disc() * (euler_end(&fine, hf) - K).max(0.0);
            let mut pc = 0.0;
            if l > 0 {                                    // the coarse path sums the fine increments in pairs
                let coarse: Vec<f64> = (0..nf).step_by(2).map(|i| fine[i] + fine[i + 1]).collect();
                pc = disc() * (euler_end(&coarse, 2.0 * hf) - K).max(0.0);
            }
            let y = pf - pc;
            for (u, w) in s.iter_mut().zip([y, y * y, pf, pf * pf, pc, pc * pc]) { *u += w; }
            done += 1; j += nf;
        }
    }
    (s, done)
}
fn exact_euler(l: usize, n: usize) -> f64 {                // road 3: E[P_l] with no random numbers
    let (lo, hi) = (-1.6f64, 1.6f64);
    let (h, dx, mid) = (T / (1u64 << l) as f64, (hi - lo) / n as f64, n / 2);
    let one = |x: f64| {                                  // density of log of one Euler factor ...
        let z = (x.exp() - 1.0 - MU * h) / (SIG * h.sqrt());
        phi(z) * x.exp() / (SIG * h.sqrt())
    };
    let mut f: Vec<f64> = (0..=n).map(|i| one(lo + i as f64 * dx)).collect();
    for _ in 0..l {                                       // ... convolved with itself: 2, 4, ... steps
        f = (0..=n).map(|k| {
            let (a, b) = (k.saturating_sub(mid), n.min(k + mid));
            dx * (a..=b).map(|i| f[i] * f[k + mid - i]).sum::<f64>()
        }).collect();
    }
    let g = |i: usize| f[i] * (S0 * (lo + i as f64 * dx).exp() - K).max(0.0);
    let pay = dx / 3.0 * (mid..=n).map(|i| {
        (if i == mid || i == n { 1.0 } else if (i - mid) % 2 == 1 { 4.0 } else { 2.0 }) * g(i)
    }).sum::<f64>();
    disc() * pay
}
fn plan(vs: &[f64], eps: f64) -> (Vec<u64>, u64) {       // path counts meeting the budget eps^2/2 at least cost
    let lam = 2.0 / (eps * eps) * vs.iter().enumerate().map(|(l, v)| (v * cost(l) as f64).sqrt()).sum::<f64>();
    let ns: Vec<u64> = vs.iter().enumerate().map(|(l, v)| (lam * (v / cost(l) as f64).sqrt()).ceil() as u64).collect();
    let c = ns.iter().enumerate().map(|(l, m)| m * cost(l)).sum();
    (ns, c)
}
fn main() {
    let bs = bs_call();
    let (a, b) = (S0 * (1.0 + MU * T) - K, S0 * SIG * T.sqrt());   // one Euler step: a + b Z, a normal ending
    let p0 = disc() * (a * ncdf(a / b) + b * phi(a / b));
    let v0 = disc() * disc() * ((a * a + b * b) * ncdf(a / b) + a * b * phi(a / b)) - p0 * p0;
    let ex: Vec<f64> = (0..=L).map(|l| exact_euler(l, 640)).collect();
    println!("Acme call: S={:.0} K={:.0} r={:.2} q={:.2} sigma={:.2} T={:.0}; Euler steps h = 1 .. 1/{}", S0, K, R, Q, SIG, T, 1 << L);
    row("Black-Scholes price", bs); row("one Euler step, closed form: price", p0);
    row("one Euler step, closed form: payoff variance", v0);
    let (mut st, mut k, h6, mut prev) = (SEED, 0, T / (1 << L) as f64, 0.0);   // one path, read on all seven grids:
    let fine = loop {                                     // the seed's first one in the money on both
        let zs = normals(&mut st, 1 << L);                // the coarsest and the finest grid
        let fine: Vec<f64> = zs.iter().map(|z| z * h6.sqrt()).collect(); k += 1;
        if euler_end(&[fine.iter().sum::<f64>()], T).min(euler_end(&fine, h6)) > K { break fine; }
    };
    println!("path {} of the seed, read on every grid\ngrid      steps    ending      payoff   correction", k);
    for l in 0..=L {
        let blk = (1usize << L) >> l;
        let inc: Vec<f64> = (0..1usize << L).step_by(blk).map(|i| fine[i..i + blk].iter().sum::<f64>()).collect();
        let y = euler_end(&inc, T / (1u64 << l) as f64);
        let p = disc() * (y - K).max(0.0);
        println!("{:<10}{:>6}{:>10.4}{:>12.6}{:>13.6}", format!("level {}", l), 1 << l, y, p, p - prev);
        prev = p;
    }
    let (mut pil, mut vs) = (Vec::new(), Vec::new());
    println!("pilot, 20000 paths a level");
    println!("level  h         exact E[P_l]  exact dE   pilot mean   std err    V_l       V ratio  cost  sqrt(V C)");
    for l in 0..=L {
        let (s, n) = level(l, PILOT, &mut st);
        let nf = n as f64;
        let (m, v) = (s[0] / nf, s[1] / nf - (s[0] / nf) * (s[0] / nf));
        pil.push((m, v, s[3] / nf - (s[2] / nf) * (s[2] / nf), s[5] / nf - (s[4] / nf) * (s[4] / nf))); vs.push(v);
        let d = ex[l] - if l > 0 { ex[l - 1] } else { 0.0 };
        let rt = if l > 1 { format!("{:>8.3}", vs[l - 1] / v) } else { format!("{:>8}", "") };
        println!("{:<6} {:<9.6}{:>12.6}{:>11.6}{:>12.6}{:>10.6}{:>10.4}{}{:>6}{:>11.4}", l, T / (1u64 << l) as f64, ex[l], d, m,
                 (v / nf).sqrt(), v, rt, cost(l), (v * cost(l) as f64).sqrt());
    }
    let (ns, tot) = (plan(&vs, EPS).0, vs.iter().enumerate().map(|(l, v)| (v * cost(l) as f64).sqrt()).sum::<f64>());
    println!("eps = {}: budget eps^2/2 = {:.6}, sum sqrt(V C) = {:.4}, 2/eps^2 x sum = {:.1}", EPS, EPS * EPS / 2.0, tot, 2.0 / EPS / EPS * tot);
    println!("level  paths N_l   mean        variance    N_l x cost");
    let (mut means, mut var, mut work) = (Vec::new(), 0.0, 0u64);
    for l in 0..=L {
        let (s, n) = level(l, ns[l] as usize, &mut st);
        let nf = n as f64;
        let (m, v) = (s[0] / nf, s[1] / nf - (s[0] / nf) * (s[0] / nf));
        means.push(m); var += v / nf; work += n as u64 * cost(l);
        println!("{:<6} {:>9}  {:>10.6}  {:>10.4}  {:>11}", l, n, m, v, n as u64 * cost(l));
    }
    let (est, bias, se) = (means.iter().sum::<f64>(), ex[L] - bs, var.sqrt());
    let plain = (2.0 * pil[L].2 / (EPS * EPS)).ceil() as u64 * (1u64 << L);
    row("multilevel estimate", est); row("  its standard error", se); row("  exact Euler bias at h = 1/64", bias);
    row("  root-mean-square error", (var + bias * bias).sqrt()); row("  gap to Black-Scholes", est - bs);
    rowi("step-evaluations, multilevel", work); row("payoff variance at h = 1/64, pilot", pil[L].2);
    rowi("step-evaluations, plain MC at h = 1/64", plain); row("  ratio, plain over multilevel", plain as f64 / work as f64);
    println!("cost for a target error: L = 6 - log2(0.01/eps) as if the bias forced it, then L kept at 6, then L = 2");
    println!("eps      L   bias        multilevel   x eps^2    plain        x eps^2");
    let mut rows = Vec::new();
    for (e, lv) in [(0.08f64, 3usize), (0.04, 4), (0.02, 5), (0.01, 6), (0.005, 6), (0.01, 2)] {
        let c = plan(&vs[..=lv], e).1;
        let p = (2.0 * pil[lv].2 / (e * e)).ceil() as u64 * (1u64 << lv);
        rows.push((e, lv, c, p));
        println!("{:<8} {:<3}{:>9.6}{:>13}{:>10.1}{:>13}{:>10.1}", e, lv, ex[lv] - bs, c, c as f64 * e * e, p, p as f64 * e * e);
    }
    let vi: Vec<f64> = (0..=L).map(|l| if l == 0 { vs[0] } else { pil[l].2 + pil[l].3 }).collect();
    let indep = plan(&vi, EPS).1;
    let same = (2.0 * vs.iter().sum::<f64>() / (EPS * EPS)).ceil() as u64 * (0..=L).map(cost).sum::<u64>();
    println!("what breaks");
    row("  drop level 0, keep only the corrections", means[1..].iter().sum::<f64>());
    row("  stop at level 0: one step, exact price", ex[0]); row("    its bias", ex[0] - bs);
    rowi("  fresh draws for the coarse path: cost", indep); rowi("  the same N on every level: cost", same);
    assert!((bs - EXACT).abs() < 1e-9);                   // road 1 against the house number
    assert!((ex[0] - p0).abs() < 1e-6);                   // road 3 against the one-step closed form
    for l in 0..=L { assert!((exact_euler(l, 1280) - ex[l]).abs() < 1e-7); }   // road 3 on a grid twice as fine
    assert!((pil[0].0 - p0).abs() < 4.0 * (v0 / PILOT as f64).sqrt() && (pil[0].1 / v0 - 1.0).abs() < 0.05);
    for l in 1..=L { assert!((pil[l].0 - (ex[l] - ex[l - 1])).abs() < 4.0 * (vs[l] / PILOT as f64).sqrt()); }
    for l in 2..=L { assert!(1.5 < vs[l - 1] / vs[l] && vs[l - 1] / vs[l] < 2.5); }   // variance roughly halves
    assert!((est - ex[L]).abs() < 4.0 * se);              // road 2 against road 3
    assert!(se < 1.05 * EPS / 2f64.sqrt() && (var + bias * bias).sqrt() < EPS);
    for &(e, lv, _, _) in &rows { assert!((ex[lv] - bs).abs() < e / 2f64.sqrt()); }
    for w in rows[..4].windows(2) { assert!(w[1].3 as f64 / w[0].3 as f64 > 7.0 && (w[1].2 as f64 / w[0].2 as f64) < 6.0); }
    assert!(plain as f64 / work as f64 > 5.0 && same > plain && indep > plain);
    println!("ALL CHECKS PASS");
}
