// Convex conjugates and Fenchel duality -- the same check as the Python, in Rust.  No crates.
// A roaster needs D = 100 kg of blend from three estates.  Estate i charges f_i(x) = c_i x + q_i x^2 / 2
// pounds for x kg.  The cafe's contract charges k pounds per kg the delivery is off 100 kg, either way.
// Roads to the bill: equal slopes (the formula); every whole-kilo order (brute force); the Fenchel dual
// maximised by search.  Also checked: conjugates by search against their formulas; -y in dg.
const NAMES: [&str; 3] = ["Brazil", "Colombia", "Robusta"];
const C: [f64; 3] = [8.0, 9.0, 5.0];
const Q: [f64; 3] = [0.1, 0.05, 0.2];
const D: f64 = 100.0;

fn f(i: usize, x: f64) -> f64 { C[i] * x + Q[i] * x * x / 2.0 }          // estate i's cost of x kg
fn f_formula(i: usize, y: f64) -> f64 { (y - C[i]).powi(2) / (2.0 * Q[i]) } // its conjugate, Step 1
fn g(z: f64, k: f64) -> f64 { k * (z - D).abs() }                           // the contract's penalty

fn top(h: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> (f64, f64) {   // max of a concave h, ternary
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if h(a) < h(b) { lo = a } else { hi = b }
    }
    (h((lo + hi) / 2.0), (lo + hi) / 2.0)
}
fn f_star(i: usize, y: f64) -> f64 { top(&|x| y * x - f(i, x), -2000.0, 2000.0).0 }   // sup, by search
fn g_star(w: f64, k: f64, r: f64) -> f64 {           // sup over z in [D - R, D + R]: kink or an end
    [D - r, D, D + r].iter().map(|&z| w * z - g(z, k)).fold(f64::MIN, f64::max)
}
fn dual(y: f64, k: f64, fs: fn(usize, f64) -> f64) -> f64 { -(0..3).map(|i| fs(i, y)).sum::<f64>() - g_star(-y, k, 1000.0) }

fn by_slopes(c: &[f64], q: &[f64], d: f64, k: f64) -> (f64, Vec<f64>, f64) {   // equal slopes, capped at k
    let s1: f64 = c.iter().zip(q).map(|(ci, qi)| ci / qi).sum();
    let s2: f64 = q.iter().map(|qi| 1.0 / qi).sum();
    let y = k.min((d + s1) / s2);
    let x: Vec<f64> = c.iter().zip(q).map(|(ci, qi)| (y - ci) / qi).collect();
    let cost: f64 = (0..c.len()).map(|i| c[i] * x[i] + q[i] * x[i] * x[i] / 2.0).sum::<f64>() + k * (x.iter().sum::<f64>() - d).abs();
    (y, x, cost)
}
fn brute(k: f64, rs: &[usize]) -> (f64, usize, usize, usize) {   // every whole-kilo order, 0 to 100 kg
    let mut best = (f64::MAX, 0, 0, 0);
    for a in 0..101 { for b in 0..101 { for &r in rs {
        let v = f(0, a as f64) + f(1, b as f64) + f(2, r as f64) + g((a + b + r) as f64, k);
        if v < best.0 { best = (v, a, b, r) }
    } } }
    best
}
fn join(v: &[String]) -> String { v.join(", ") }

fn main() {
    let all: Vec<usize> = (0..101).collect();
    let mut out = vec![];
    for k in [12.0, 10.0] {
        let (y, x, cost) = by_slopes(&C, &Q, D, k);
        let bf = brute(k, &all);
        let (d_star, y_star) = top(&|t| dual(t, k, f_star), -k, k);
        let tot: f64 = x.iter().sum();
        let sub_g = if (tot - D).abs() < 1e-9 { (-k, k) } else if tot < D { (-k, -k) } else { (k, k) };
        println!("k = {:.0}: price y = {:.2} pounds/kg; kg {}; total {:.2} kg", k, y,
                 join(&(0..3).map(|i| format!("{} {:.2}", NAMES[i], x[i])).collect::<Vec<_>>()), tot);
        println!("  primal, by slopes: {:.2}; every whole-kilo order: {:.2} at {}, {}, {} kg", cost, bf.0, bf.1, bf.2, bf.3);
        println!("  dual, by search: {:.4} at y = {:.4}", d_star, y_star);
        println!("  certificate: slopes {}; -y = {:.2} lies in dg = [{:.0}, {:.0}]",
                 join(&(0..3).map(|i| format!("{:.2}", C[i] + Q[i] * x[i])).collect::<Vec<_>>()), -y, sub_g.0, sub_g.1);
        out.push((y, x, cost, bf, d_star, sub_g));
    }
    let (y, x, cost, bf, d_star, sub_g) = out[0].clone();
    let low = out[1].clone();
    for i in 0..3 {
        println!("{}: f({:.0}) = {:.2}; f*(11) formula {:.2}, by search {:.4}; sells y x - f = {:.2}",
                 NAMES[i], x[i], f(i, x[i]), f_formula(i, 11.0), f_star(i, 11.0), 11.0 * x[i] - f(i, x[i]));
    }
    println!("dual at 11 by hand: 100 x 11 - {:.2} = {:.2}", (0..3).map(|i| f_formula(i, 11.0)).sum::<f64>(), dual(11.0, 12.0, f_formula));
    let (inv, cq): (f64, f64) = (Q.iter().map(|q| 1.0 / q).sum(), C.iter().zip(Q).map(|(c, q)| c / q).sum());
    println!("clearing: sum 1/q = {:.0}, sum c/q = {:.0}; dual = {:.0} - {:.1} (y - 11)^2; average {:.2} pounds/kg; f1*(12) = {:.2}; k = 10: short by {:.0} kg; orders searched {}",
             inv, cq, cost, inv / 2.0, cost / D, f_formula(0, 12.0), D - low.1.iter().sum::<f64>(), 101 * 101 * 101);
    println!("slope of f* at 11 (central difference) = kg offered: {}",
             join(&(0..3).map(|i| format!("{:.4}", (f_star(i, 11.001) - f_star(i, 10.999)) / 0.002)).collect::<Vec<_>>()));
    let mut fy = vec![];                                                      // 117 pairs
    for a in (0..61).step_by(5) { for b in 6..15 { fy.push((f(0, a as f64) + f_star(0, b as f64) - (a * b) as f64, a, b)) } }
    let eq: Vec<(usize, usize)> = fy.iter().filter(|p| p.0.abs() < 1e-6).map(|p| (p.1, p.2)).collect();
    println!("Fenchel-Young, Brazil: 30 kg at 11: {:.4}; 30 kg at 12: {:.4}; grid of 117: {} below 0, equal at {}",
             f(0, 30.0) + f_formula(0, 11.0) - 330.0, f(0, 30.0) + f_formula(0, 12.0) - 360.0,
             fy.iter().filter(|p| p.0 < -1e-9).count(), join(&eq.iter().map(|(a, b)| format!("{} kg/{}", a, b)).collect::<Vec<_>>()));
    println!("abs conjugate, k = 12: g*(-11) = {:.2}; g*(13) with R = 1000, 2000: {:.0}, {:.0}",
             g_star(-11.0, 12.0, 1000.0), g_star(13.0, 12.0, 1000.0), g_star(13.0, 12.0, 2000.0));
    let bic = top(&|t| 30.0 * t - f_formula(0, t), -100.0, 100.0);
    println!("biconjugate, Brazil at 30 kg: f**(30) = {:.4} at slope {:.4}", bic.0, bic.1);
    println!("chart, dual value at y = 9 to 12 by 0.5: {}",
             join(&(0..7).map(|t| format!("{:.3}", dual(9.0 + t as f64 / 2.0, 12.0, f_formula))).collect::<Vec<_>>()));

    let sacks = |s: f64| {                         // Robusta only in whole sacks of s kg: 0 or s
        let k = 12.0;
        let f3 = move |t: f64| (s * t - f(2, s)).max(0.0);   // its conjugate: max of y x - f over {0, s}
        let pr = [0.0, s].iter().map(|&r| f(2, r) + by_slopes(&C[..2], &Q[..2], D - r, k).2).fold(f64::MAX, f64::min);
        let du = top(&|t| -f_formula(0, t) - f_formula(1, t) - f3(t) - g_star(-t, k, 1000.0), -k, k);
        let env = top(&|t| 30.0 * t - f3(t), -100.0, 100.0).0;
        (pr, du.0, du.1, env)
    };
    let (s60, s50, ns) = (sacks(60.0), sacks(50.0), by_slopes(&C[..2], &Q[..2], D, 12.0));   // ns: no Robusta
    let bf60 = brute(12.0, &[0, 60]);
    println!("sacks of 60 kg: primal {:.2} (whole kilos {:.2} at {}, {}, {} kg); no sack {:.2} at {:.0}, {:.0} kg; dual {:.2} at y = {:.2}; gap {:.2}; f3**(30) = {:.2}",
             s60.0, bf60.0, bf60.1, bf60.2, bf60.3, ns.2, ns.1[0], ns.1[1], s60.1, s60.2, s60.0 - s60.1, s60.3);
    let wrong_half = 1100.0 - (0..3).map(|i| (11.0 - C[i]).powi(2) / Q[i]).sum::<f64>();
    let no_cap = 100.0 * 11.0 - (0..3).map(|i| f_formula(i, 11.0)).sum::<f64>();
    println!("wrong: no 1/2 in f*: Brazil f*(11) = {:.2}, dual at 11 = {:.2}", (11.0f64 - 8.0).powi(2) / 0.1, wrong_half);
    println!("wrong: k = 10 but -g*(-y) taken as 100 y everywhere: 'bound' {:.2} above the true {:.2}", no_cap, low.2);
    println!("wrong: kilos fed to f*: f1*(30) = {:.2}", f_formula(0, 30.0));
    for (label, q, d) in [("try: D = 120", Q, 120.0), ("try: Brazil q = 0.2", [0.2, 0.05, 0.2], D)] {
        let (ty, tx, tc) = by_slopes(&C, &q, d, 12.0);
        println!("{}: y = {:.4}, kg {}, cost {:.2}", label, ty, join(&tx.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>()), tc);
    }
    println!("try: sacks of 50 kg: primal {:.2}, dual {:.2} at y = {:.2}", s50.0, s50.1, s50.2);
    let pts = |cs: &[(f64, f64)]| cs.iter().map(|&(a, b)| format!("{:.1},{:.1}", 50.0 + 6.5 * a, 190.0 - 0.4 * b)).collect::<Vec<_>>().join(" ");
    println!("figure, Brazil cost: {}", pts(&(0..9).map(|j| { let a = 5.0 * j as f64; (a, f(0, a)) }).collect::<Vec<_>>()));
    println!("figure, slope-11 line: {} | touch {}", pts(&[(0.0, -45.0), (40.0, 11.0 * 40.0 - 45.0)]), pts(&[(30.0, f(0, 30.0))]));

    assert!((bf.0 - cost).abs() < 1e-9 && (low.3 .0 - low.2).abs() < 1e-9);       // formula = every whole-kilo order
    assert!((d_star - cost).abs() < 1e-6 && (low.4 - low.2).abs() < 1e-6);         // Fenchel dual meets the primal
    assert!((0..3).all(|i| [6.0, 9.5, 11.0, 13.0].iter().all(|&t| (f_star(i, t) - f_formula(i, t)).abs() < 1e-6)));
    let want: Vec<(usize, usize)> = (0..61).step_by(10).map(|a| (a, 8 + a / 10)).collect();
    assert!(fy.iter().all(|p| p.0 > -1e-9) && eq == want && (f(0, 30.0) + f_formula(0, 12.0) - 360.0 - 0.05 * 100.0).abs() < 1e-9);
    assert!(g_star(13.0, 12.0, 2000.0) > g_star(13.0, 12.0, 1000.0) && g_star(13.0, 12.0, 1000.0) > 1000.0 && (bic.0 - f(0, 30.0)).abs() < 1e-6);
    assert!((bf60.0 - s60.0).abs() < 1e-9 && (ns.2 - s60.0).abs() < 1e-9 && s60.0 - s60.1 > 10.0 && (s50.0 - s50.1).abs() < 1e-6);
    assert!(no_cap > low.2 + 10.0 && sub_g.0 <= -y && -y <= sub_g.1 && low.5 .0 <= -low.0 && -low.0 <= low.5 .1);   // -y in dg
    println!("ALL CHECKS PASS");
}
