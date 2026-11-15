// Hahn-Banach check: extend a bond price rule to every portfolio, keeping its norm.
// std only.  Three states (down, flat, up), payoffs and prices in pounds,
// all prices illustrative.  Nothing used knows the answer: the searches are written out.
const G: [f64; 3] = [100.0, 100.0, 100.0]; // government bond
const B: [f64; 3] = [40.0, 100.0, 100.0]; // corporate bond
const Z: [f64; 3] = [60.0, 100.0, 140.0]; // share
const PG: f64 = 95.0;
const PB: f64 = 89.0;
const BOUND: f64 = 0.95; // the bound s(x) = 0.95|x|

fn size(x: &[f64]) -> f64 { x.iter().fold(0.0, |m, v| m.max(v.abs())) }
fn value(w: &[f64], x: &[f64]) -> f64 { (0..3).map(|i| w[i] * x[i]).sum() }
fn signs() -> Vec<[f64; 3]> {
    let mut v = Vec::new();
    for a in [-1.0, 1.0] { for b in [-1.0, 1.0] { for c in [-1.0, 1.0] { v.push([a, b, c]); } } }
    v
}
fn dnorm(w: &[f64]) -> f64 { signs().iter().fold(0.0, |m, s| m.max(value(w, s).abs())) }
fn phi(a: f64, b: f64) -> f64 { a * PG + b * PB }
fn port(a: f64, b: f64, k: f64) -> [f64; 3] {
    [a * G[0] + b * B[0] + k * Z[0], a * G[1] + b * B[1] + k * Z[1], a * G[2] + b * B[2] + k * Z[2]]
}
fn tmin(f: &dyn Fn(f64) -> f64) -> f64 { // minimum of a convex f on [-4, 4], by thirds
    let (mut lo, mut hi) = (-4.0, 4.0);
    for _ in 0..200 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if f(m1) <= f(m2) { hi = m2 } else { lo = m1 }
    }
    f((lo + hi) / 2.0)
}
fn min2(f: &dyn Fn(f64, f64) -> f64) -> f64 { tmin(&|a| tmin(&|b| f(a, b))) }
fn det(m: &[[f64; 3]; 3]) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn solve(c: f64) -> [f64; 3] { // state prices that price G, B and Z at c
    let (a, r) = ([G, B, Z], [PG, PB, c]);
    let mut w = [0.0; 3];
    for k in 0..3 {
        let mut m = a;
        for i in 0..3 { m[i][k] = r[i]; }
        w[k] = det(&m) / det(&a);
    }
    w
}
fn grid() -> Vec<[f64; 3]> {
    let mut v = Vec::new();
    for a in -3..4 { for b in -3..4 { for c in -3..4 { v.push([a as f64, b as f64, c as f64]); } } }
    v
}
fn qsize(x: &[f64]) -> f64 { x.iter().map(|v| v.abs().sqrt()).sum::<f64>().powi(2) }

fn main() {
    println!("three states (down, flat, up); G = (100,100,100) at 95, B = (40,100,100) at 89");
    let mut on_m: f64 = 0.0;
    for t in -200000..=200000 {
        let b = t as f64 / 1e5;
        on_m = on_m.max(phi(1.0, b).abs() / size(&port(1.0, b, 0.0)));
    }
    println!("norm of the bond rule on M, scan of 400001 portfolios: {:.6}", on_m);
    assert!((on_m - PG / size(&G)).abs() < 1e-9, "the rule's norm on M is the government bond's ratio");

    // road 1: the one-step band, lo = sup[phi(m) - s(m - z)], hi = inf[s(m + z) - phi(m)]
    let hi1 = min2(&|a, b| BOUND * size(&port(a, b, 1.0)) - phi(a, b));
    let lo1 = -min2(&|a, b| BOUND * size(&port(a, b, -1.0)) - phi(a, b));
    // road 2: state prices; the bonds fix w_d and w_f + w_u, the share's price runs with w_u = t
    let wd = (PG - PB) / (G[0] - B[0]);
    let rest = PG / 100.0 - wd;
    let (lo2, hi2) = (value(&[wd, rest, 0.0], &Z), value(&[wd, 0.0, rest], &Z));
    // road 3: solve for the rule at each share price c and keep the c whose norm stays 0.95
    let ok: Vec<f64> = (280..585).map(|c| c as f64 / 4.0).filter(|&c| dnorm(&solve(c)) <= BOUND + 1e-9).collect();
    let (lo3, hi3) = (ok.iter().cloned().fold(f64::MAX, f64::min), ok.iter().cloned().fold(f64::MIN, f64::max));
    println!("forced: w_d = {:.4}, w_f + w_u = {:.4}", wd, rest);
    for (name, lo, hi) in [("road 1, one-step formula", lo1, hi1),
                           ("road 2, state prices >= 0", lo2, hi2), ("road 3, scan of c", lo3, hi3)] {
        println!("{:<27} share price band: {:.2} to {:.2}", name, lo, hi);
    }
    assert!((lo1 - lo2).abs() < 1e-6 && (hi1 - hi2).abs() < 1e-6, "one-step formula against state prices");
    assert!((lo3 - lo2).abs() < 1e-9 && (hi3 - hi2).abs() < 1e-9, "norm scan against state prices");
    for (name, a, b, k) in [("lo witness: m = (8/15)G + (2/3)B, m - z", 8.0 / 15.0, 2.0 / 3.0, -1.0),
                            ("hi witness: m = (2/15)G - (4/3)B, m + z", 2.0 / 15.0, -4.0 / 3.0, 1.0)] {
        let (y, s) = (port(a, b, k), BOUND * size(&port(a, b, k)));
        println!("{} = ({:.2}, {:.2}, {:.2}), phi(m) = {:.2}, s = {:.2}", name, y[0], y[1], y[2], phi(a, b), s);
        let end = if k < 0.0 { lo2 } else { hi2 };
        assert!((k * (s - phi(a, b)) - end).abs() < 1e-9, "a hand witness hits the band's end");
    }

    let mid = solve((lo2 + hi2) / 2.0);
    let gr = grid();
    let excess = gr.iter().fold(f64::MIN, |m, x| m.max(value(&mid, x) - BOUND * size(x)));
    println!("midpoint c = {:.2}: w = ({:.4}, {:.4}, {:.4}), norm {:.4}, sum of |w| {:.4}",
             (lo2 + hi2) / 2.0, mid[0], mid[1], mid[2], dnorm(&mid), mid.iter().map(|v| v.abs()).sum::<f64>());
    println!("  largest Phi(x) - 0.95|x| over {} payoffs: {:.4}", gr.len(), excess.abs());
    assert!(excess < 1e-9 && (value(&mid, &G) - PG).abs() < 1e-9 && (value(&mid, &B) - PB).abs() < 1e-9);
    let norming = [0.0, 0.0, 1.0];
    println!("norming rule for z: w = (0, 0, 1), value {:.2}, |z| = {:.2}, norm {:.2}",
             value(&norming, &Z), size(&Z), dnorm(&norming));

    let cs: Vec<f64> = (0..9).map(|i| (148 + 17 * i) as f64 / 2.0).collect();
    println!("chart, share price c:  {}", cs.iter().map(|c| format!("{:.1}", c)).collect::<Vec<_>>().join(" "));
    println!("chart, norm of rule:   {}", cs.iter().map(|&c| format!("{:.2}", dnorm(&solve(c)))).collect::<Vec<_>>().join(" "));
    for c in [131.0, 0.0] {
        let w = solve(c);
        let bad = gr.iter().fold(f64::MIN, |m, x| m.max(value(&w, x) - BOUND * size(x)));
        println!("breaks, share at {:6.2}: w = ({:.4}, {:.4}, {:.4}), norm {:.4}, worst excess {:.4}",
                 c, w[0], w[1], w[2], dnorm(&w), bad);
        assert!(dnorm(&w) > BOUND + 0.1 && (dnorm(&w) - w.iter().map(|v| v.abs()).sum::<f64>()).abs() < 1e-9);
    }

    println!("square-root rule: size(e1) + size(e2) = 2.00, size(e1 + e2) = {:.2}", qsize(&[1.0, 1.0]));
    for n in [3usize, 10, 100] {
        let line = PG / qsize(&vec![100.0; n]);
        let w = vec![PG / 100.0 / n as f64; n]; // spread the price evenly: the best case
        let mut tests: Vec<Vec<f64>> = (0..n).map(|j| (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect()).collect();
        tests.push(vec![1.0; n]);
        let best = tests.iter().fold(0.0f64, |m, x| m.max((0..n).map(|i| w[i] * x[i]).sum::<f64>().abs() / qsize(x)));
        println!("  N = {:3}: bound on the bond line {:.6}, best extension {:.6}, ratio {:.2}", n, line, best, best / line);
        assert!((best / line - n as f64).abs() < 1e-9, "the forced bound grows N-fold");
    }

    let (mut total, mut high, mut p, mut n) = (0.0f64, 0u64, 1u64, 0u64); // 120 on [4^k, 2*4^k)
    let mut rows: Vec<String> = Vec::new();
    for k in 1..7u32 {
        for stop in [2 * 4u64.pow(k) - 1, 4u64.pow(k + 1) - 1] {
            while n < stop {
                n += 1;
                if p * 4 <= n { p *= 4; }
                let price = if n < 2 * p { 120.0 } else { 40.0 };
                total += price;
                if price > 100.0 { high += 1; }
            }
            assert!(high == (4u64.pow(k + 1) - 1) / 3, "count of peak hours against the closed form");
            rows.push(format!("{}: {:.2}", stop, total / stop as f64));
        }
    }
    let blocks: Vec<String> = (1..4u32).map(|j| format!("{}-{}", 4u64.pow(j), 2 * 4u64.pow(j) - 1)).collect();
    println!("peak blocks at GBP 120/MWh, else 40: hours 1, {}", blocks.join(", "));
    println!("running average, GBP/MWh, at hour {}", rows[..6].join(", "));
    println!("                                  {}", rows[6..].join(", "));
    println!("band for the long-run average: {:.2} to {:.2}", 40.0 + 80.0 / 3.0, 40.0 + 160.0 / 3.0);
    for (pb, z) in [(92.0, Z), (PB, [60.0, 100.0, 100.0])] {
        let d = (PG - pb) / (G[0] - B[0]);
        let r = PG / 100.0 - d;
        println!("try: B at {:.2}, share ({}, {}, {}): band {:.2} to {:.2}", pb, z[0], z[1], z[2],
                 value(&[d, r, 0.0], &z), value(&[d, 0.0, r], &z));
    }
    println!("ALL CHECKS PASS");
}
