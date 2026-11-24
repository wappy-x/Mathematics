// Convertible risk -- the check behind the card.  std only; nothing used knows a
// convertible.  The bond: five years, face 100, 2% coupon paid yearly, convertible
// at any time into one Acme share.  Acme: 100 today, riskless rate 5%, dividend
// yield 2%.  The tree splits value Tsiveriotis-Fernandes style: the equity part is
// discounted at the riskless rate, the cash part at riskless plus the credit spread.
// Converting forfeits the coupon due.  255 steps.
const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 5.0; const FACE: f64 = 100.0;
const CPN: f64 = 2.0; const M: usize = 255; const QUOTE: f64 = 108.0;
const CB04: f64 = 103.8592;                   // Convertible bonds: 1000 steps, exact last step

struct Out { v: f64, e: f64, b: f64, g: f64, r1: Vec<(f64, f64)>, r2: Vec<(f64, f64)> }

// Price, equity part, cash part, d(price)/d(spread) and the first two rows.
fn cb_full(sig: f64, spr: f64, s0: f64, m: usize, ratio: f64, split: bool, smooth: bool) -> Out {
    let dt = T / m as f64; let u = (sig * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((R - Q) * dt).exp() - d) / (u - d);
    let dr = if split { (-R * dt).exp() } else { (-(R + spr) * dt).exp() };
    let dk = (-(R + spr) * dt).exp(); let per = (m as f64 / T).round() as usize;
    let (h, k) = (sig * dt.sqrt(), FACE + CPN);
    let node = |n: usize, j: usize| s0 * u.powf(j as f64) * d.powf((n - j) as f64);
    let (mut e, mut b, mut g) = (vec![0.0; m + 1], vec![0.0; m + 1], vec![0.0; m + 1]);
    for j in 0..=m {
        let s = node(m, j);
        let x0 = if ratio > 0.0 { (k / (ratio * s)).ln() } else { h }; // maturity: max(share, 102)
        if smooth && x0.abs() < h { // a cell across 102: average it
            e[j] = ratio * s * (h.exp() - x0.exp()) / (2.0 * h); b[j] = k * (x0 + h) / (2.0 * h);
        } else if x0 < 0.0 { e[j] = ratio * s; } else { b[j] = k; }
    }
    let (mut r1, mut r2) = (vec![], vec![]);
    for n in (0..m).rev() {
        let cp = if n % per == 0 && n > 0 { CPN } else { 0.0 };
        for j in 0..=n {
            let s = node(n, j);
            let mut ee = dr * (p * e[j + 1] + (1.0 - p) * e[j]);
            let mut gg = dk * (p * g[j + 1] + (1.0 - p) * g[j]);
            let mut bb = dk * (p * b[j + 1] + (1.0 - p) * b[j]);
            gg -= dt * bb; // product rule on dk * (...)
            if !split { gg -= dt * ee; }
            bb += cp; // converting forfeits the coupon due
            if ratio * s > ee + bb { ee = ratio * s; bb = 0.0; gg = 0.0; }
            e[j] = ee; b[j] = bb; g[j] = gg;
        }
        if n == 1 { r1 = (0..2).map(|j| (node(1, j), e[j] + b[j])).collect(); }
        if n == 2 { r2 = (0..3).map(|j| (node(2, j), e[j] + b[j])).collect(); }
    }
    Out { v: e[0] + b[0], e: e[0], b: b[0], g: g[0], r1, r2 }
}
fn cb(sig: f64, spr: f64, s0: f64) -> f64 { cb_full(sig, spr, s0, M, 1.0, true, true).v }

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, tol: f64) -> (f64, usize) {
    let (mut flo, mut k) = (f(lo), 1);        // k counts every tree priced
    while hi - lo > tol {
        let mid = 0.5 * (lo + hi); let fm = f(mid); k += 1;
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    (0.5 * (lo + hi), k)
}

fn secant(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> (f64, usize) {
    let (mut fa, mut fb, mut k) = (f(a), f(b), 2);
    while (b - a).abs() > 1e-12 {
        let nb = b - fb * (b - a) / (fb - fa);
        a = b; b = nb; fa = fb; fb = f(b); k += 1;
    }
    (b, k)
}

fn commas(x: f64) -> String {
    let s = format!("{:.0}", x.abs());
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    if x < -0.5 { format!("-{}", out) } else { out }
}

fn main() {
    println!("convertible: 5 years, face 100, coupon 2, one share; Acme 100, r 5%, q 2%; tree {} steps", M);
    let floor: f64 = (1..6).map(|t| CPN * (-(R + 0.03) * t as f64).exp()).sum::<f64>() + FACE * (-(R + 0.03) * T).exp();
    let tf = cb_full(0.20, 0.03, 100.0, M, 0.0, true, true).v;
    println!("bond floor at 3% spread: closed form {:.6}  tree with no conversion {:.6}", floor, tf);
    assert!((floor - tf).abs() < 1e-9);
    let o20 = cb_full(0.20, 0.03, 100.0, M, 1.0, true, true);
    println!("model price at vol 20%, spread 3%: {:.4} (equity part {:.4}, cash part {:.4}); quote {:.2}", o20.v, o20.e, o20.b, QUOTE);
    let p1005 = cb_full(0.20, 0.03, 100.0, 1005, 1.0, true, true).v;
    println!("same price on 1005 steps: {:.4}; on the 1000-step tree of Convertible bonds: {:.4}", p1005, CB04);
    assert!((o20.v - p1005).abs() < 0.01 && o20.v > floor.max(100.0));
    assert!((o20.v - CB04).abs() < 0.01);      // another tree, another smoothing, the same model

    let vs: Vec<String> = [10, 20, 30, 40].iter().map(|&v| format!("{}%:{:.2}", v, cb(v as f64 / 100.0, 0.03, 100.0))).collect();
    println!("price against volatility, spread 3%: {}", vs.join(" "));
    let ss: Vec<String> = [0, 2, 4, 6].iter().map(|&s| format!("{}%:{:.2}", s, cb(0.20, s as f64 / 100.0, 100.0))).collect();
    println!("price against spread, vol 20%:      {}", ss.join(" "));
    let fv = |v: f64| cb(v, 0.03, 100.0) - QUOTE;
    let (iv, kb) = bisect(&fv, 0.05, 0.60, 1e-9); let (iv2, ks) = secant(&fv, 0.20, 0.30);
    println!("implied vol at 3% spread: bisection {:.4}% in {} trees, secant {:.4}% in {} trees", 100.0 * iv, kb, 100.0 * iv2, ks);
    let fs = |s: f64| cb(0.20, s, 100.0) - QUOTE;
    let (isp, kb) = bisect(&fs, -0.01, 0.10, 1e-9); let (isp2, ks) = secant(&fs, 0.03, 0.02);
    println!("implied spread at 20% vol: bisection {:.2} bp in {} trees, secant {:.2} bp in {} trees", 1e4 * isp, kb, 1e4 * isp2, ks);
    assert!((iv - iv2).abs() < 1e-7 && (isp - isp2).abs() < 1e-7);
    assert!((cb(iv, 0.03, 100.0) - QUOTE).abs() < 1e-6 && (cb(0.20, isp, 100.0) - QUOTE).abs() < 1e-6);
    let pairs: Vec<(i32, f64)> = (1..7).map(|s| (s, bisect(&|v: f64| cb(v, s as f64 / 100.0, 100.0) - QUOTE, 0.05, 0.60, 1e-6).0)).collect();
    let ps: Vec<String> = pairs.iter().map(|&(s, v)| format!("{}%:{:.2}", s, 100.0 * v)).collect();
    println!("chart, spread and the vol that reprices 108: {}", ps.join(" "));
    assert!(pairs.windows(2).all(|w| w[0].1 < w[1].1));

    let o = cb_full(iv, 0.03, 100.0, M, 1.0, true, true); let v = o.v;
    println!("at the implied vol: price {:.4} = equity part {:.4} + cash part {:.4}", v, o.e, o.b);
    let uu = (iv * (T / M as f64).sqrt()).exp(); let pp = (((R - Q) * T / M as f64).exp() - 1.0 / uu) / (uu - 1.0 / uu);
    println!("tree factors: up u {:.6}  down d {:.6}  up weight p {:.6}", uu, 1.0 / uu, pp);
    let ((s10, v10), (s11, v11)) = (o.r1[0], o.r1[1]);
    let ((s20, v20), (s21, v21), (s22, v22)) = (o.r2[0], o.r2[1], o.r2[2]);
    println!("one step in:  Acme {:.4} {:.4}  bond {:.4} {:.4}", s10, s11, v10, v11);
    println!("two steps in: Acme {:.4} {:.4} {:.4}  bond {:.4} {:.4} {:.4}", s20, s21, s22, v20, v21, v22);
    let delta = (v11 - v10) / (s11 - s10);
    let (hp, hm) = (s22 - s21, s21 - s20);
    let gamma = 2.0 * ((v22 - v21) / hp - (v21 - v20) / hm) / (hp + hm);
    let u2 = (2.0 * iv * (T / M as f64).sqrt()).exp(); // two lattice steps: the kink stays put
    let (a, b, c) = (cb(iv, 0.03, 100.0 * u2), v, cb(iv, 0.03, 100.0 / u2));
    let (kp, km) = (100.0 * u2 - 100.0, 100.0 - 100.0 / u2);
    let tdelta = (km * km * (a - b) + kp * kp * (b - c)) / (kp * km * (kp + km));
    let tgamma = 2.0 * ((a - b) / kp - (b - c) / km) / (kp + km);
    println!("three trees from Acme {:.4}, 100, {:.4}: prices {:.4} {:.4} {:.4}", 100.0 / u2, 100.0 * u2, c, b, a);
    println!("delta: nodes {:.4}  three trees {:.4};  gamma: nodes {:.6}  three trees {:.6}", delta, tdelta, gamma, tgamma);
    assert!((delta - tdelta).abs() < 0.002 && (gamma / tgamma - 1.0).abs() < 0.02);
    let vega = (cb(iv + 0.01, 0.03, 100.0) - cb(iv - 0.01, 0.03, 100.0)) / 2.0;
    let (cs01, cs1) = (5.0 * (cb(iv, 0.03001, 100.0) - cb(iv, 0.02999, 100.0)), (cb(iv, 0.0301, 100.0) - cb(iv, 0.0299, 100.0)) / 2.0);
    let cs10 = (cb(iv, 0.031, 100.0) - cb(iv, 0.029, 100.0)) / 20.0;   // reprice 10 bp either side: the line moves too
    println!("vega per vol point {:.4};  credit per +1 bp: bump 10 bp {:.6}  bump 1 bp {:.6}  bump 0.1 bp {:.6}", vega, cs10, cs1, cs01);
    let full1005 = |s: f64| cb_full(iv, s, 100.0, 1005, 1.0, true, true);
    let (g1005, c1005) = (full1005(0.03).g * 1e-4, (full1005(0.031).v - full1005(0.029).v) / 20.0);
    println!("  slope with the conversion line held {:.6};  on 1005 steps {:.6}, bump 10 bp {:.6}", o.g * 1e-4, g1005, c1005);
    assert!(o.g * 1e-4 < cs10 && cs10 < 0.97 * o.g * 1e-4 && g1005 < c1005 && c1005 < 0.97 * g1005);   // held line: too steep, < 3%
    println!("cash part's spread duration: {:.4} years ({:.4} with the line held)", -cs10 / (o.b * 1e-4), -o.g / o.b);

    let n = 100_000.0;
    let short = (n * delta).round();
    println!("hedge: buy {} bonds (face 10,000,000, cost {}), short {} shares", n, commas(n * v), short);
    for k in [-3, -2, -1, 1, 2, 3] { // moves onto the tree's own price levels
        let s = 100.0 * u2.powf(k as f64);
        let full = n * (cb(iv, 0.03, s) - v) - short * (s - 100.0);
        let taylor = n * (0.5 * tgamma * (s - 100.0).powf(2.0)) + (n * tdelta - short) * (s - 100.0);
        println!("  Acme jumps to {:6.2} (move {:+6.2}): hedged P&L full {:>9}   delta-gamma estimate {:>9}", s, s - 100.0, commas(full), commas(taylor));
        assert!(full > 0.0 && (full - taylor).abs() < 0.25 * taylor);
    }
    let wide = n * (cb(iv, 0.04, 100.0) - v);
    println!("  spread widens 100 bp, Acme still: hedged P&L {}", commas(wide));

    let lv: Vec<i32> = (0..6).map(|i| 60 + 20 * i).collect();
    println!("chart, Acme price:    {}", lv.iter().map(|s| format!("{:6}", s)).collect::<Vec<_>>().join(" "));
    let curve: Vec<Out> = lv.iter().map(|&s| cb_full(iv, 0.03, s as f64, M, 1.0, true, true)).collect();
    println!("chart, bond price:    {}", curve.iter().map(|c| format!("{:6.2}", c.v)).collect::<Vec<_>>().join(" "));
    let dl: Vec<f64> = curve.iter().map(|c| (c.r1[1].1 - c.r1[0].1) / (c.r1[1].0 - c.r1[0].0)).collect();
    println!("chart, node delta:    {}", dl.iter().map(|x| format!("{:6.3}", x)).collect::<Vec<_>>().join(" "));
    assert!(dl.windows(2).all(|w| w[0] < w[1]) && curve.iter().zip(&lv).all(|(c, &s)| c.v >= floor.max(s as f64)));

    println!("what breaks");
    let bump = (cb(iv, 0.03, 101.0) - cb(iv, 0.03, 99.0)) / 2.0;
    println!("  delta from a plain bump of 1 dollar     {:.4}", bump);
    let rough: Vec<f64> = [101.0, 100.0, 99.0].iter().map(|&x| cb_full(iv, 0.03, x, M, 1.0, true, false).v).collect();
    println!("  last step not smoothed: price {:.4}, 1-dollar bump delta {:.4}", rough[1], (rough[0] - rough[2]) / 2.0);
    println!("  implied vol solved at zero spread       {:.4}%", 100.0 * bisect(&|v: f64| cb(v, 0.0, 100.0) - QUOTE, 0.05, 0.6, 1e-9).0);
    println!("  gamma with the two gaps taken as equal  {:.5}", ((v22 - v21) - (v21 - v20)) / ((hp + hm) / 2.0).powf(2.0));
    println!("  hedge one share per bond, Acme to {:.2} {}", 100.0 * u2, commas(n * (a - v) - n * (100.0 * u2 - 100.0)));
    let nos = cb_full(iv, 0.03, 100.0, M, 1.0, false, true);
    println!("  whole bond at the risky rate: price {:.4}, credit per bp {:.6}", nos.v, nos.g * 1e-4);
    println!("ALL CHECKS PASS");
}
