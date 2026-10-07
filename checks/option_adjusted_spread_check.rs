// Option-adjusted spread -- option_adjusted_spread_check.py in Rust.  Std only; tree, root finder, random numbers written out.
// Compile: rustc --edition 2021 -O option_adjusted_spread_check.rs -o /tmp/oas_check
const N: usize = 30; const C: f64 = 0.06;                      // years, coupon
const BASE: f64 = 0.08; const SLOPE: f64 = 14.0; const KNEE: f64 = 0.05;   // prepayment rule
const SIG: f64 = 0.22; const PRICE: f64 = 103.06;              // rate volatility, market price per $100

fn zero(t: f64) -> f64 { 0.035 + 0.0005 * t }                 // zero rate for t years, continuous
fn sched(i: usize) -> f64 { C / ((1.0 + C).powi((N - i) as i32) - 1.0) }
fn prepay_with(r: f64, slope: f64) -> f64 { BASE + slope * (KNEE - r).max(0.0) }
fn prepay(r: f64) -> f64 { prepay_with(r, SLOPE) }
fn bisect<F: Fn(f64) -> f64>(f: F, target: f64) -> f64 {       // f falls as its input rises
    let (mut lo, mut hi) = (-0.05_f64, 0.30_f64);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if f(mid) > target { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
struct Curve { d: Vec<f64>, fwd: Vec<f64> }
fn calibrate(cv: &Curve, sig: f64, fitted: bool) -> Vec<Vec<f64>> {
    // Tree of one-year rates r(i,j) = a_i e^{sig(2j-i)}; each a_i found so the tree reprices D(i+1).
    let mut rates: Vec<Vec<f64>> = Vec::new();
    let mut q = vec![1.0_f64];
    for i in 0..N {
        let a = if fitted {
            bisect(|a| (0..=i).map(|j| q[j] * (-a * (sig * (2.0 * j as f64 - i as f64)).exp()).exp()).sum(), cv.d[i + 1])
        } else { zero(1.0) };
        let row: Vec<f64> = (0..=i).map(|j| a * (sig * (2.0 * j as f64 - i as f64)).exp()).collect();
        let mut nq = vec![0.0; i + 2];
        for j in 0..=i {
            nq[j] += 0.5 * q[j] * (-row[j]).exp();
            nq[j + 1] += 0.5 * q[j] * (-row[j]).exp();
        }
        rates.push(row);
        q = nq;
    }
    rates
}
fn tree_price(rates: &[Vec<f64>], s: f64, spread_moves_prepay: bool, slope: f64) -> f64 {
    // Road 1: walk back through the tree.  Value per $1 of balance still outstanding at each node.
    let mut v = vec![0.0_f64; N + 1];
    for i in (0..N).rev() {
        let g = sched(i);
        v = (0..=i).map(|j| {
            let r = rates[i][j];
            let p = prepay_with(if spread_moves_prepay { r + s } else { r }, slope);
            (-(r + s)).exp() * (C + g + p * (1.0 - g) + (1.0 - g) * (1.0 - p) * 0.5 * (v[j] + v[j + 1]))
        }).collect();
    }
    100.0 * v[0]
}
fn static_flows(cv: &Curve, slope: f64) -> Vec<f64> {
    // The z-spread's cash flows: one path, rates sitting on the forwards.
    let mut bal = 100.0_f64;
    let mut flows = Vec::new();
    for i in 0..N {
        let (g, p) = (sched(i), prepay_with(cv.fwd[i], slope));
        flows.push(bal * (C + g + p * (1.0 - g)));
        bal *= (1.0 - g) * (1.0 - p);
    }
    flows
}
fn static_price(cv: &Curve, flows: &[f64], z: f64) -> f64 {
    flows.iter().enumerate().map(|(t, f)| f * cv.d[t + 1] * (-z * (t + 1) as f64).exp()).sum()
}
fn mc_weights(rates: &[Vec<f64>], paths: usize, seed: u64) -> Vec<f64> {
    // Road 2: simulate paths through the same rates, forward in time, tracking the balance.
    let mut x = seed;
    let mut w = vec![0.0_f64; N];
    for _ in 0..paths / 2 {
        let mut coins = [0usize; N];
        for c in coins.iter_mut() {
            x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            *c = (x >> 63) as usize;                             // top bit: 1 = rates step up
        }
        for flip in 0..2usize {                                  // each path and its mirror image
            let (mut j, mut bal, mut disc) = (0usize, 100.0_f64, 1.0_f64);
            for i in 0..N {
                let (r, g) = (rates[i][j], sched(i));
                let p = prepay(r);
                disc *= (-r).exp();
                w[i] += bal * (C + g + p * (1.0 - g)) * disc;
                bal *= (1.0 - g) * (1.0 - p);
                j += coins[i] ^ flip;
            }
        }
    }
    w.iter().map(|wi| wi / paths as f64).collect()
}
fn mc_price(w: &[f64], s: f64) -> f64 { w.iter().enumerate().map(|(t, wi)| wi * (-s * (t + 1) as f64).exp()).sum() }

fn main() {
    let d: Vec<f64> = (0..=N).map(|t| (-zero(t as f64) * t as f64).exp()).collect();
    let fwd: Vec<f64> = (0..N).map(|i| (d[i] / d[i + 1]).ln()).collect();
    let cv = Curve { d, fwd };
    let (flat, tree) = (calibrate(&cv, 0.0, true), calibrate(&cv, SIG, true));
    let flows = static_flows(&cv, SLOPE);
    let z_static = bisect(|z| static_price(&cv, &flows, z), PRICE);
    let z_tree0 = bisect(|s| tree_price(&flat, s, false, SLOPE), PRICE);
    let oas = bisect(|s| tree_price(&tree, s, false, SLOPE), PRICE);
    let (w, w_few) = (mc_weights(&tree, 20000, 20260928), mc_weights(&tree, 20, 20260928));
    let oas_mc = bisect(|s| mc_price(&w, s), PRICE);
    let oas_few = bisect(|s| mc_price(&w_few, s), PRICE);
    let opt_dollars = static_price(&cv, &flows, oas) - PRICE;
    let flows0 = static_flows(&cv, 0.0);
    let z_noopt = bisect(|z| static_price(&cv, &flows0, z), PRICE);
    let oas_noopt = bisect(|s| tree_price(&tree, s, false, 0.0), PRICE);
    let oas_wrong_prepay = bisect(|s| tree_price(&tree, s, true, SLOPE), PRICE);
    let unfitted = calibrate(&cv, SIG, false);
    let oas_unfitted = bisect(|s| tree_price(&unfitted, s, false, SLOPE), PRICE);

    let (r0, g0, p0) = (tree[0][0], sched(0), prepay(tree[0][0]));
    let flow1 = 100.0 * (C + g0 + p0 * (1.0 - g0));
    let mut pw = vec![1.0_f64];                                  // chance of each year-16 node: coin flips
    for _ in 0..15 {
        pw = (0..=pw.len()).map(|j| 0.5 * (if j < pw.len() { pw[j] } else { 0.0 } + if j > 0 { pw[j - 1] } else { 0.0 })).collect();
    }
    let avg16: f64 = (0..16).map(|j| pw[j] * prepay(tree[15][j])).sum();
    let rows: Vec<(&str, String)> = vec![
        ("zero rate 1y / 10y / 30y (%)", format!("{:.2} {:.2} {:.2}", 100.0 * zero(1.0), 100.0 * zero(10.0), 100.0 * zero(30.0))),
        ("year 1: short rate r0 (%)", format!("{:.4}", 100.0 * r0)),
        ("year 1: prepayment rate (%)", format!("{:.4}", 100.0 * p0)),
        ("year 1: scheduled principal ($)", format!("{:.4}", 100.0 * g0)),
        ("year 1: prepaid ($)", format!("{:.4}", 100.0 * p0 * (1.0 - g0))),
        ("year 1: cash flow ($)", format!("{:.4}", flow1)),
        ("year 1: D(1), e^-z, flow x both ($)", format!("{:.6} {:.6} {:.4}", cv.d[1], (-z_static).exp(), flow1 * cv.d[1] * (-z_static).exp())),
        ("year 2 up / down rate (%)", format!("{:.4} {:.4}", 100.0 * tree[1][1], 100.0 * tree[1][0])),
        ("year 2 up / down prepay (%)", format!("{:.4} {:.4}", 100.0 * prepay(tree[1][1]), 100.0 * prepay(tree[1][0]))),
        ("year 16 forward rate (%)", format!("{:.4}", 100.0 * cv.fwd[15])),
        ("year 16 prepay at the forward (%)", format!("{:.4}", 100.0 * prepay(cv.fwd[15]))),
        ("year 16 prepay, tree average (%)", format!("{:.4}", 100.0 * avg16)),
        ("static price at spread 0 ($)", format!("{:.4}", static_price(&cv, &flows, 0.0))),
        ("tree price at spread 0 ($)", format!("{:.4}", tree_price(&tree, 0.0, false, SLOPE))),
        ("z-spread, static flows (bp)", format!("{:.4}", 1e4 * z_static)),
        ("z-spread, tree at vol 0 (bp)", format!("{:.4}", 1e4 * z_tree0)),
        ("OAS, tree (bp)", format!("{:.4}", 1e4 * oas)),
        ("OAS, 20000 simulated paths (bp)", format!("{:.4}", 1e4 * oas_mc)),
        ("option cost z - OAS (bp)", format!("{:.4}", 1e4 * (z_static - oas))),
        ("option cost in price ($)", format!("{:.4}", opt_dollars)),
        ("no option: z-spread (bp)", format!("{:.4}", 1e4 * z_noopt)),
        ("no option: OAS on tree (bp)", format!("{:.4}", 1e4 * oas_noopt)),
        ("wrong: spread moves prepayment (bp)", format!("{:.4}", 1e4 * oas_wrong_prepay)),
        ("wrong: tree not fitted to curve (bp)", format!("{:.4}", 1e4 * oas_unfitted)),
        ("wrong: only 20 paths (bp)", format!("{:.4}", 1e4 * oas_few)),
    ];
    for (name, v) in &rows { println!("{:<37} {}", name, v); }
    println!();
    let spreads: Vec<i32> = (0..11).map(|k| 40 + 10 * k).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, spread (bp)  {}", join(spreads.iter().map(|b| format!("{:6}", b)).collect()));
    println!("chart, static ($)   {}", join(spreads.iter().map(|b| format!("{:6.2}", static_price(&cv, &flows, *b as f64 / 1e4))).collect()));
    println!("chart, tree ($)     {}", join(spreads.iter().map(|b| format!("{:6.2}", tree_price(&tree, *b as f64 / 1e4, false, SLOPE))).collect()));
    let vols: Vec<f64> = (0..7).map(|k| 0.05 * k as f64).collect();
    println!("chart, vol (%)      {}", join(vols.iter().map(|v| format!("{:6.0}", 100.0 * v)).collect()));
    println!("chart, OAS (bp)     {}", join(vols.iter().map(|v| {
        let t = calibrate(&cv, *v, true);
        format!("{:6.2}", 1e4 * bisect(|s| tree_price(&t, s, false, SLOPE), PRICE))
    }).collect()));

    assert!((0..N).map(|i| (cv.fwd[i] - flat[i][0]).abs()).fold(0.0, f64::max) < 1e-12, "vol-0 tree must sit on the forwards");
    assert!((z_tree0 - z_static).abs() < 1e-10, "z-spread two ways: tree at vol 0 vs static sum");
    assert!((oas_noopt - z_noopt).abs() < 1e-10, "no option: OAS on the tree must equal the z-spread");
    assert!((oas_mc - oas).abs() < 2e-4, "simulated OAS within 2 bp of the tree");
    assert!(0.0 < oas && oas < z_static, "the borrower's option must cost the investor spread");
    let (mut bal, level) = (100.0_f64, 100.0 * C / (1.0 - (1.0 + C).powi(-(N as i32))));   // no prepayment: level annuity
    for i in 0..N { assert!((bal * (C + sched(i)) - level).abs() < 1e-9, "scheduled payment must be level"); bal *= 1.0 - sched(i); }
    assert!(bal.abs() < 1e-9, "no prepayment: the balance must be paid off in exactly 30 years");
    println!("ALL CHECKS PASS");
}
