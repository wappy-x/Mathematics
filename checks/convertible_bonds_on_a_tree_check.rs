// Convertible bonds on a tree -- the check behind the card.  std only, no crates.
// Nothing imported knows the answer: the bell-curve area is a series written out
// here, and both trees are loops.  Money is per bond, face 100, converting into 1 share.
use std::f64::consts::PI;
fn n_cdf(x: f64) -> f64 {                   // bell-curve area left of x, built here:
    if x.abs() > 3.0 {                      // far out, a continued fraction for the tail
        let mut f = x.abs();
        for k in (1..=80).rev() { f = x.abs() + k as f64 / f; }
        let tail = (-x * x / 2.0).exp() / (2.0 * PI).sqrt() / f; return if x < 0.0 { tail } else { 1.0 - tail };
    }
    let (mut term, mut total, mut k) = (x, x, 0.0);   // near the middle, the Taylor series
    while term.abs() > 1e-17 { k += 1.0; term *= -x * x / 2.0 / k; total += term / (2.0 * k + 1.0); }
    0.5 + total / (2.0 * PI).sqrt()
}
#[derive(Clone, Copy)]
struct M { r: f64, q: f64, sig: f64, s: f64 }   // rate, dividend yield, volatility, spread
const S0: f64 = 100.0; const F: f64 = 100.0; const C: f64 = 2.0; const T: usize = 5;
type Call = Option<(f64, f64, f64)>; type Put = Option<(f64, f64)>;   // (price, first year, trigger), (price, year)
fn floor_at(m: M, t: f64) -> f64 {          // straight bond: coupons and face at r + s
    let mut sum = 0.0;
    for k in 1..=T { if k as f64 > t + 1e-12 { sum += C * (-(m.r + m.s) * (k as f64 - t)).exp(); } }
    sum + F * (-(m.r + m.s) * (T as f64 - t)).exp()
}
fn last_step(m: M, s: f64, tau: f64, rc: f64, re: f64) -> (f64, f64) {
    let k = F + C;                          // maturity payoff max(102, share), split
    let d1 = ((s / k).ln() + (m.r - m.q + 0.5 * m.sig * m.sig) * tau) / (m.sig * tau.sqrt()); let d2 = d1 - m.sig * tau.sqrt();
    (k * (-rc * tau).exp() * n_cdf(-d2), s * ((m.r - m.q - re) * tau).exp() * n_cdf(d1))
}
// a choice leaves one kind: worth no more than its share, no cash; worth a call or put price, all cash
fn mislabelled(s: f64, v: f64, b: f64, cash: [Option<f64>; 2]) -> bool {
    if s >= v { b != 0.0 } else { cash.iter().any(|&k| k == Some(v)) && b != v }
}
// A call or put also pays any coupon due.  mode 0 discounts the cash part at r + s and the share
// part at r; 1 puts both at r + s, 2 both at r.
fn tree(m: M, s0: f64, steps: usize, american: bool, call: Call, put: Put, mode: u8, smooth: bool) -> (f64, f64, usize) {
    let dt = T as f64 / steps as f64;
    let u = (m.sig * dt.sqrt()).exp(); let d = 1.0 / u; let p = (((m.r - m.q) * dt).exp() - d) / (u - d);
    let dc = if mode != 2 { (-(m.r + m.s) * dt).exp() } else { (-m.r * dt).exp() }; let de = if mode != 1 { (-m.r * dt).exp() } else { dc };
    let per = steps / T;                    // steps per year: coupon dates are nodes
    let mut spot: Vec<f64> = (0..=steps).map(|j| s0 * u.powf(j as f64) * d.powf((steps - j) as f64)).collect();
    let mut v_: Vec<f64> = spot.iter().map(|&x| (F + C).max(x)).collect();
    let (mut b_, mut bad): (Vec<f64>, usize) = (spot.iter().map(|&x| if F + C > x { F + C } else { 0.0 }).collect(), 0);
    for i in (0..steps).rev() {
        let t = i as f64 * dt; spot = spot[..i + 1].iter().map(|x| x / d).collect();
        let cpn = if i % per == 0 && i > 0 { C } else { 0.0 }; let fl = floor_at(m, t) + cpn;
        let (mut nv, mut nb) = (Vec::with_capacity(i + 1), Vec::with_capacity(i + 1));
        for j in 0..=i {
            let (mut b, e);
            if i == steps - 1 && smooth {   // last step: the exact one-step split
                let (bb, ee) = last_step(m, spot[j], dt, -dc.ln() / dt, -de.ln() / dt); b = bb + cpn; e = ee;
            } else {                        // plain step: average the two branches
                b = dc * (p * b_[j + 1] + (1.0 - p) * b_[j]) + cpn;
                e = de * (p * (v_[j + 1] - b_[j + 1]) + (1.0 - p) * (v_[j] - b_[j]));
            }
            let mut v = b + e;
            if let Some((kp, tp)) = put { if (t - tp).abs() < 1e-9 && v < kp + cpn { v = kp + cpn; b = v; } }   // put for cash
            if let Some((kc, tc, trig)) = call { if t >= tc - 1e-9 && v > kc + cpn && spot[j] >= trig { v = kc + cpn; b = v; } }
            if american && spot[j] > v { v = spot[j]; b = 0.0; }   // holder converts
            nv.push(v); nb.push(b);
            let cash = [put.map(|(kp, _)| kp + cpn), call.map(|(kc, _, _)| kc + cpn)];
            if v < fl.max(spot[j]) - 1e-9 || mislabelled(spot[j], v, b, cash) { bad += 1; }
        }
        v_ = nv; b_ = nb;
    }
    (v_[0], b_[0], bad)
}
// three branches, one ladder of prices with a rung on the call level; a tie there converts
fn tri(m: M, s0: f64, rungs: usize, call: Call, put: Put, level: f64) -> (f64, f64, usize) {
    let dx = (level / s0).ln() / rungs as f64; let w = 1.25 * m.sig / dx;   // a rung: 1.25 step sds
    let steps = 5 * (T as f64 * w * w / 5.0).ceil() as usize;            // coupon dates are nodes
    let dt = T as f64 / steps as f64; let nu = m.r - m.q - m.sig * m.sig / 2.0;
    let a = (m.sig * m.sig * dt + nu * dt * nu * dt) / (dx * dx);
    let (pu, pm, pd) = ((a + nu * dt / dx) / 2.0, 1.0 - a, (a - nu * dt / dx) / 2.0);
    let (k, per, mut bad) = ((6.0 * m.sig * (T as f64).sqrt() / dx) as usize, steps / T, 0usize);
    let mut lv: Vec<f64> = (0..=2 * k).map(|i| s0 * ((i as f64 - k as f64) * dx).exp()).collect(); lv[k + rungs] = level;
    let walk = |w: &Vec<f64>, f: f64, top: f64| -> Vec<f64> {
        let mut o = vec![f * w[0]];
        for i in 1..2 * k { o.push(f * (pu * w[i + 1] + pm * w[i] + pd * w[i - 1])); }
        o.push(top); o
    };
    let (mut b_, mut e_): (Vec<f64>, Vec<f64>) = lv.iter().map(|&x| last_step(m, x, dt, m.r + m.s, m.r)).unzip();
    for i in (0..steps).rev() {
        let (t, cpn) = (i as f64 * dt, if i % per == 0 && i > 0 { C } else { 0.0 });
        if i < steps - 1 { b_ = walk(&b_, (-(m.r + m.s) * dt).exp(), 0.0); e_ = walk(&e_, (-m.r * dt).exp(), lv[2 * k]); }
        for j in 0..=2 * k {
            let x = lv[j]; let mut b = b_[j] + cpn; let mut v = b + e_[j];
            if let Some((kp, tp)) = put { if (t - tp).abs() < 1e-9 && v < kp + cpn { v = kp + cpn; b = v; } }
            if let Some((kc, tc, trig)) = call { if t >= tc - 1e-9 && v > kc + cpn && x >= trig { v = kc + cpn; b = v; } }
            if x >= v { v = x; b = 0.0; }
            b_[j] = b; e_[j] = v - b;
            if mislabelled(x, v, b, [put.map(|(kp, _)| kp + cpn), call.map(|(kc, _, _)| kc + cpn)]) { bad += 1; }
        }
    }
    (b_[k] + e_[k], b_[k], bad)
}
fn euro_closed(m: M, s0: f64) -> (f64, f64) {   // conversion only at maturity, no call
    let (mut cash, share) = last_step(m, s0, T as f64, m.r + m.s, m.r);
    for k in 1..T { cash += C * (-(m.r + m.s) * k as f64).exp(); } (cash + share, cash)
}
fn row(name: &str, val: f64) { println!("{:<38}{:>11.4}", name, val); }
fn main() {
    let m = M { r: 0.05, q: 0.02, sig: 0.20, s: 0.03 };
    let (n, hard, soft, put3) = (1000, Some((130.0, 2.0, 0.0)), Some((100.0, 2.0, 130.0)), Some((100.0, 3.0)));
    let tr = |m: M, s0: f64, k: usize, call: Call, put: Put| tree(m, s0, k, true, call, put, 0, true);
    let (floor0, parity) = (floor_at(m, 0.0), S0 * 1.0);
    let (plain, plain_cash, bad) = tr(m, S0, n, None, None);
    let (called, _, bad_c) = tr(m, S0, n, hard, None);
    let (soft_v, putted, bad_b) = (tr(m, S0, n, soft, None).0, tr(m, S0, n, None, put3).0, tr(m, S0, n, hard, put3).2);
    let ((euro_tree, euro_tree_cash, _), (euro_cf, euro_cf_cash)) = (tree(m, S0, n, false, None, None, 0, true), euro_closed(m, S0));
    let (risky, safe) = (tree(m, S0, n, true, None, None, 1, true).0, tree(m, S0, n, true, None, None, 2, true).0);
    let tri40: Vec<(f64, f64, usize)> = [(None, None), (hard, None), (soft, None), (None, put3), (hard, put3)]
        .iter().map(|&(k, h)| tri(m, S0, 40, k, h, 130.0)).collect();
    let (t_plain, t_call, t_soft, t_put, t_both) = (tri40[0].0, tri40[1].0, tri40[2].0, tri40[3].0, tri40[4].0);
    let cost60 = tri(m, S0, 60, None, None, 130.0).0 - tri(m, S0, 60, hard, None, 130.0).0;
    println!("market: S 100, r 5%, q 2%, sigma 20%; bond: face 100, coupon 2, 5 years, 1 share");
    for (name, val) in [("bond floor at r + s = 8%", floor0), ("parity: 1 share x 100", parity),
        ("tree price, 1000 steps", plain), ("  cash part", plain_cash), ("  share part", plain - plain_cash),
        ("premium over parity, %", 100.0 * (plain / parity - 1.0)), ("three-branch tree, 40 rungs to 130", t_plain),
        ("with issuer call 130 from year 2", t_call), ("  cost of that call", t_plain - t_call),
        ("  the same cost, 60 rungs to 130", cost60), ("with holder put 100 at year 3", t_put),
        ("  value of that put", t_put - t_plain), ("with the call and the put", t_both),
        ("soft call: 100 once share >= 130", soft_v), ("  three-branch tree", t_soft),
        ("two-branch tree, call 130", called), ("two-branch tree, put 100", putted),
        ("convert at maturity only, tree", euro_tree), ("  the same, closed form", euro_cf),
        ("  tree cash part", euro_tree_cash), ("  closed-form cash part", euro_cf_cash),
        ("right to convert early is worth", plain - euro_tree), ("everything at 8%", risky),
        ("everything at 5%", safe), ("5-step tree, plain last step", tree(m, S0, 5, true, None, None, 0, false).0)] { row(name, val); }
    println!("nodes below max(floor, parity) or mislabelled: {}, {} with the call, {} with call and put", bad, bad_c, bad_b);
    let mut saw: Vec<(f64, usize)> = (1000..=1200).step_by(5).map(|k| (tr(m, S0, k, hard, None).0, k)).collect();
    saw.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let (lo, hi) = (saw[0], saw[saw.len() - 1]);
    println!("two-branch tree, call 130, 1000 to 1200 steps: {:.4} at {} to {:.4} at {}", lo.0, lo.1, hi.0, hi.1);
    let (u, d) = (m.sig.exp(), (-m.sig).exp()); let p = ((m.r - m.q).exp() - d) / (u - d);
    let (cash_h, eq_h) = ((-(m.r + m.s)).exp() * (1.0 - p) * (F + C), (-m.r).exp() * p * 100.0 * u);
    println!("by hand: the year-4 node at S = 100, one step a year");
    for (name, val) in [("up factor u", u), ("down factor d", d), ("up weight p", p), ("share after an up", 100.0 * u),
        ("share after a down", 100.0 * d), ("cash: e^-0.08 x (1-p) x 102", cash_h),
        ("share: e^-0.05 x p x 122.14", eq_h), ("hold: cash + share + coupon 2", cash_h + eq_h + C),
        ("the same node, all at 8%", (-(m.r + m.s)).exp() * (p * 100.0 * u + (1.0 - p) * (F + C)) + C)] { row(name, val); }
    let counts = [100usize, 250, 500, 1000, 2000]; let conv: Vec<f64> = counts.iter().map(|&k| tr(m, S0, k, None, None).0).collect();
    println!("steps     {}", counts.iter().map(|k| format!("{:>9}", k)).collect::<String>());
    println!("price     {}", conv.iter().map(|v| format!("{:>9.4}", v)).collect::<String>());
    let spots: Vec<f64> = (0..7).map(|i| 40.0 + 20.0 * i as f64).collect();
    let curve: Vec<f64> = spots.iter().map(|&x| tr(m, x, n, None, None).0).collect();
    let line = |v: &Vec<f64>, dp: usize| v.iter().map(|x| format!("{:>8.*}", dp, x)).collect::<String>();
    println!("chart, Acme today     {}", line(&spots, 0));
    println!("chart, convertible    {}", line(&curve, 2));
    println!("chart, bond floor     {:>8.2} at every share price; parity = share price", floor0);
    let (m6, m0, try_vol) = (M { s: 0.06, ..m }, M { q: 0.0, ..m }, tr(M { sig: 0.30, ..m }, S0, n, None, None).0);
    let (try_spr, try_fl) = (tr(m6, S0, n, None, None).0, floor_at(m6, 0.0));
    let try_q0 = tr(m0, S0, n, None, None).0; let try_q0e = try_q0 - tree(m0, S0, n, false, None, None, 0, true).0;
    let (try_c115, _, bad_115) = tri(m, S0, 21, Some((115.0, 2.0, 0.0)), None, 115.0);
    let bad_t = bad_115 + tri40.iter().map(|x| x.2).sum::<usize>();
    println!("try: sigma 30% {:.4}; spread 6% {:.4} (floor {:.4})", try_vol, try_spr, try_fl);
    println!("try: no dividend {:.4} (early conversion {:.4}); call at 115 {:.4} (cost {:.4})", try_q0, try_q0e, try_c115, t_plain - try_c115);
    assert!((n_cdf(0.3) - 0.617911422188953).abs() < 1e-12, "the series against a tabled bell-curve area");
    assert!((euro_tree - euro_cf).abs() < 0.005, "tree without early conversion vs the closed form");
    assert!((euro_tree_cash - euro_cf_cash).abs() < 0.02, "the two cash parts agree too");
    assert!((plain - t_plain).abs() < 0.01, "two-branch and three-branch trees: one American price");
    assert!((soft_v - t_soft).abs() < 0.01, "and one soft-call price: the trigger only forces conversion");
    assert!((putted - t_put).abs() < 0.05, "and one put price, to the two-branch tree's wobble");
    assert!((cost60 - (t_plain - t_call)).abs() < 0.02, "the call's cost has settled on the three-branch tree");
    assert!(bad + bad_c + bad_b + bad_t == 0, "never below floor or parity, never mislabelled, at any node");
    assert!(risky < plain && plain < safe, "between the all-at-8% and all-at-5% trees");
    assert!(t_call < t_plain && t_plain < t_both && t_both < t_put && soft_v < plain, "a call takes value away, a put adds it");
    assert!((conv[4] - conv[3]).abs() < 0.01, "the tree has settled");
    assert!((0..7).all(|i| curve[i] >= floor0.max(spots[i])), "chart above both bounds");
    assert!(try_q0e < 1e-9 && 1e-9 < plain - euro_tree, "no dividend: early conversion is worth nothing");
    println!("ALL CHECKS PASS");
}
