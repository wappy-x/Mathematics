// Structured rate notes priced by their parts: range accrual, inverse floater, target redemption note.
// Rust std only. Normal CDF, integrator and random numbers are written here.
use std::collections::HashSet;
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 { // normal CDF: series near 0, continued fraction in the tails
    if x.abs() <= 3.0 {
        let (mut term, mut total, mut k) = (x, x, 0.0);
        while term.abs() > 1e-17 {
            k += 1.0;
            term *= -x * x / (2.0 * k);
            total += term / (2.0 * k + 1.0);
        }
        return 0.5 + total / (2.0 * PI).sqrt();
    }
    let y = x.abs();
    let mut f = y;
    for k in (1..=150).rev() { f = y + k as f64 / f; }
    let tail = (-y * y / 2.0).exp() / (2.0 * PI).sqrt() / f;
    if x > 0.0 { 1.0 - tail } else { tail }
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {
    let m = 2000;
    let h = (hi - lo) / m as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    s * h / 3.0
}
const M: f64 = 1000.0; const C: f64 = 0.06; const A: f64 = 0.04; const B: f64 = 0.06;
const F: f64 = 0.05; const SIG: f64 = 0.20; const R: f64 = 0.05; const NF: usize = 12;
fn ts() -> Vec<f64> { (0..NF).map(|j| (j + 1) as f64 / NF as f64).collect() }
fn d(k: f64, t: f64, f: f64, s: f64) -> f64 { ((f / k).ln() - 0.5 * s * s * t) / (s * t.sqrt()) }
fn range_value(f: f64, s: f64) -> f64 { // road 1: long a digital at A, short a digital at B, each month
    M * C * (-R).exp() * ts().iter().map(|&t| n_cdf(d(A, t, f, s)) - n_cdf(d(B, t, f, s))).sum::<f64>() / NF as f64
}
fn floorlet(k: f64, f: f64, s: f64) -> f64 { k * n_cdf(-d(k, 1.0, f, s)) - f * n_cdf(-d(k, 1.0, f, s) - s) }
fn caplet(k: f64, f: f64, s: f64) -> f64 { f * n_cdf(d(k, 1.0, f, s) + s) - k * n_cdf(d(k, 1.0, f, s)) }
fn g(l: f64) -> f64 { (0.10 - 2.0 * l).max(0.0).min(0.08) } // 10% - 2L, floored at 0, capped at 8%
fn inverse_value(f: f64, s: f64) -> f64 { M * (-2.0 * R).exp() * 2.0 * (floorlet(0.05, f, s) - floorlet(0.01, f, s)) }
fn pdf(y: f64, t: f64) -> f64 { // density of log L(t)
    let v = SIG * t.sqrt();
    (-0.5 * ((y - F.ln() + 0.5 * v * v) / v).powi(2)).exp() / (v * (2.0 * PI).sqrt())
}
// target redemption note on a coin: raw coupon 30 when in band, target 50, face 1000, discount .98 a period
const DC: f64 = 0.98; const G: i32 = 50;
fn call_price(i: usize) -> f64 { if i == 1 { 980.0 } else { 985.0 } }
fn node(pre: &[u8], earned: i32, call: bool) -> f64 { // backward road: value just before the coupon at date pre.len()
    let i = pre.len();
    let cpn = (if pre[i - 1] == 1 { 30 } else { 0 }).min(G - earned);
    if earned + cpn == G || i == 3 { return cpn as f64 + 1000.0; }
    let alive = keep(pre, earned + cpn, call);
    cpn as f64 + if call { call_price(i).min(alive) } else { alive }
}
fn keep(pre: &[u8], earned: i32, call: bool) -> f64 { // value of staying alive after this date's coupon
    let (mut h, mut m) = (pre.to_vec(), pre.to_vec());
    h.push(1); m.push(0);
    DC * (node(&h, earned, call) + node(&m, earned, call)) / 2.0
}
fn path_pv(bits: &[u8; 3], policy: &HashSet<Vec<u8>>) -> f64 { // forward road: walk one coin path
    let (mut earned, mut pv) = (0, 0.0);
    for i in 1..=3 {
        let cpn = (if bits[i - 1] == 1 { 30 } else { 0 }).min(G - earned);
        earned += cpn;
        let prin = if earned == G || i == 3 { 1000.0 } else if policy.contains(&bits[..i].to_vec()) { call_price(i) } else { 0.0 };
        pv += DC.powi(i as i32) * (cpn as f64 + prin);
        if prin > 0.0 { return pv; }
    }
    pv
}
fn main() {
    let (d1, d2, t) = ((-R).exp(), (-2.0 * R).exp(), ts());
    let v_rng = range_value(F, SIG);
    let v_inv = inverse_value(F, SIG);
    let v_cap = M * d2 * (0.08 + 2.0 * caplet(0.05, F, SIG) - 2.0 * caplet(0.01, F, SIG)); // road 2: fixed 8% plus caplets
    let v_rng_int = M * C * d1 * t.iter().map(|&tt| simpson(&|y| pdf(y, tt), A.ln(), B.ln())).sum::<f64>() / NF as f64;
    let v_inv_int = M * d2 * (0.08 * simpson(&|y| pdf(y, 1.0), F.ln() - 3.0, 0.01f64.ln())
        + simpson(&|y| (0.10 - 2.0 * y.exp()) * pdf(y, 1.0), 0.01f64.ln(), 0.05f64.ln()));
    // road 4: simulate rate paths with a hand-written generator
    let mut st: u64 = 20260928;
    let mut rnd = || { st = st.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((st >> 11) as f64 + 0.5) / 9007199254740992.0 };
    let paths = 100000;
    let (mut sr, mut sr2, mut sg, mut sg2) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let (mut w, mut hits, mut l) = (0.0, 0, 0.0);
        for j in 0..NF {
            let (u1, u2) = (rnd(), rnd());
            w += (1.0 / NF as f64).sqrt() * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            l = F * (SIG * w - 0.5 * SIG * SIG * t[j]).exp();
            if A <= l && l < B { hits += 1; }
        }
        let (vr, vg) = (M * C * d1 * hits as f64 / NF as f64, M * d2 * g(l));
        sr += vr; sr2 += vr * vr; sg += vg; sg2 += vg * vg;
    }
    let p = paths as f64;
    let (mc_r, mc_g) = (sr / p, sg / p);
    let (se_r, se_g) = (((sr2 / p - mc_r * mc_r) / p).sqrt(), ((sg2 / p - mc_g * mc_g) / p).sqrt());
    let coins: Vec<[u8; 3]> = (0..8u8).map(|x| [x >> 2 & 1, x >> 1 & 1, x & 1]).collect();
    let tree_plain = DC * (node(&[1], 0, false) + node(&[0], 0, false)) / 2.0;
    let tree_call = DC * (node(&[1], 0, true) + node(&[0], 0, true)) / 2.0;
    let none: HashSet<Vec<u8>> = HashSet::new();
    let paths_plain = coins.iter().map(|k| path_pv(k, &none)).sum::<f64>() / 8.0;
    let spots: [Vec<u8>; 5] = [vec![1], vec![0], vec![1, 0], vec![0, 1], vec![0, 0]]; // every place the issuer could call
    let mut paths_call = f64::INFINITY;
    for m in 0..32 {
        let pol: HashSet<Vec<u8>> = (0..5).filter(|i| m >> i & 1 == 1).map(|i| spots[i].clone()).collect();
        paths_call = paths_call.min(coins.iter().map(|k| path_pv(k, &pol)).sum::<f64>() / 8.0);
    }
    let cpn_pv = coins.iter().map(|k| path_pv(k, &none) - DC.powi(if k[0] == 1 && k[1] == 1 { 2 } else { 3 }) * 1000.0).sum::<f64>() / 8.0;
    let s1 = |x: f64| M * C * d1 * t.iter().map(|&tt| n_cdf(d(x, tt, F, SIG))).sum::<f64>() / NF as f64;
    let rows: Vec<(&str, Option<f64>)> = vec![("range accrual: 6% on 1000 while 4% <= L < 6%", None),
        ("month 12: d(4%)", Some(d(A, 1.0, F, SIG))), ("month 12: d(6%)", Some(d(B, 1.0, F, SIG))),
        ("month 12: N(d(4%))", Some(n_cdf(d(A, 1.0, F, SIG)))), ("month 12: N(d(6%))", Some(n_cdf(d(B, 1.0, F, SIG)))),
        ("month 1: chance in band", Some(n_cdf(d(A, t[0], F, SIG)) - n_cdf(d(B, t[0], F, SIG)))),
        ("average chance in band", Some(v_rng / (M * C * d1))), ("month 12: chance in band", Some(n_cdf(d(A, 1.0, F, SIG)) - n_cdf(d(B, 1.0, F, SIG)))),
        ("discount D(1)", Some(d1)),
        ("long 12 digitals at 4%", Some(s1(A))), ("short 12 digitals at 6%", Some(s1(B))),
        ("1 digitals formula", Some(v_rng)), ("2 Simpson over the band", Some(v_rng_int)),
        ("3 simulation, 100000 paths", Some(mc_r)), ("  standard error", Some(se_r)),
        ("delta per 1bp of F", Some((range_value(F + 1e-4, SIG) - range_value(F - 1e-4, SIG)) / 2.0)),
        ("vega per vol point", Some((range_value(F, 0.21) - range_value(F, 0.19)) / 2.0)),
        ("wrong: valued at the forward", Some(M * C * d1)),
        ("wrong: every fixing at month 12", Some(M * C * d1 * (n_cdf(d(A, 1.0, F, SIG)) - n_cdf(d(B, 1.0, F, SIG))))),
        ("inverse floater: 1000 x min(8%, max(0, 10% - 2L))", None), ("discount D(2)", Some(d2)),
        ("1 floorlet spread", Some(v_inv)), ("2 fixed 8% plus caplets", Some(v_cap)), ("3 Simpson over L", Some(v_inv_int)),
        ("4 simulation, 100000 paths", Some(mc_g)), ("  standard error", Some(se_g)),
        ("delta per 1bp of F", Some((inverse_value(F + 1e-4, SIG) - inverse_value(F - 1e-4, SIG)) / 2.0)),
        ("vega per vol point", Some((inverse_value(F, 0.21) - inverse_value(F, 0.19)) / 2.0)),
        ("wrong: valued at the forward", Some(M * d2 * g(F))), ("target note on a coin: 30 in band, target 50", None),
        ("uncalled, backward tree", Some(tree_plain)), ("uncalled, 8 paths", Some(paths_plain)),
        ("  coupons alone", Some(cpn_pv)), ("  principal alone", Some(paths_plain - cpn_pv)),
        ("date 1 after a hit: stay alive", Some(keep(&[1], 30, true))), ("date 1 after a miss: stay alive", Some(keep(&[0], 0, true))),
        ("date 2 at 30 earned: stay alive", Some(keep(&[1, 0], 30, true))), ("date 2 at 0 earned: stay alive", Some(keep(&[0, 0], 0, true))),
        ("callable, backward tree", Some(tree_call)), ("callable, best of 32 policies", Some(paths_call)),
        ("  cost of the call right", Some(tree_plain - tree_call)),
        ("wrong: principal always at date 3", Some(cpn_pv + 1000.0 * DC.powi(3))),
        ("wrong: no target clip", Some(15.0 * (DC + DC.powi(2) + DC.powi(3)) + 1000.0 * DC.powi(3)))];
    for (lab, v) in &rows {
        match v { None => println!("{}", lab), Some(x) => println!("{:<40}{:>14.6}", lab, x) }
    }
    println!("chart, vol %:     {}", (1..=8).map(|k| format!("{:6}", 5 * k)).collect::<Vec<_>>().join(" "));
    println!("chart, range $:   {}", (1..=8).map(|k| format!("{:6.2}", range_value(F, 0.05 * k as f64))).collect::<Vec<_>>().join(" "));
    println!("chart, L %:       {}", (0..=20).map(|k| format!("{:5.1}", k as f64 / 2.0)).collect::<Vec<_>>().join(" "));
    println!("chart, range %:   {}", (0..=20).map(|k| { let l = k as f64 / 200.0;
        format!("{:5.1}", if A <= l && l < B { 100.0 * C } else { 0.0 }) }).collect::<Vec<_>>().join(" "));
    println!("chart, inverse %: {}", (0..=20).map(|k| format!("{:5.1}", 100.0 * g(k as f64 / 200.0))).collect::<Vec<_>>().join(" "));

    assert!((v_rng - v_rng_int).abs() < 1e-8, "digital formula vs integral of the density");
    assert!((mc_r - v_rng).abs() < 4.0 * se_r, "range accrual simulation within 4 standard errors");
    assert!((mc_g - v_inv).abs() < 4.0 * se_g, "inverse floater simulation within 4 standard errors");
    assert!((v_inv - v_cap).abs() < 1e-9, "floor spread vs fixed coupon plus caplets (parity)");
    assert!((v_inv - v_inv_int).abs() < 1e-8, "floor spread vs integral of the payoff");
    assert!((tree_plain - paths_plain).abs() < 1e-9, "backward tree vs 8 enumerated paths");
    assert!((tree_call - paths_call).abs() < 1e-9, "backward tree vs brute-force search over call policies");
    println!("ALL CHECKS PASS");
}
