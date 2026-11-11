// Convergence rates -- the check behind the card.  No crates.
// Part 1: an error that halves each step against one that squares, from 0.1.
// Part 2: the Rosenbrock valley f = (1 - x1)^2 + b (x2 - x1^2)^2, b = 100, written
// with x = x1, y = x2 below, minimised at (1, 1).  Same roads as the Python: condition-number rate against
// measured rate, Newton's predicted constant against measured, measured orders.

fn sci(v: f64) -> String { // 3 significant figures, same text in Python and Rust
    let mut e = v.log10().floor() as i32;
    let mut m = v / 10f64.powf(e as f64);
    if m >= 9.995 { m /= 10.0; e += 1; }
    format!("{:.2}e{}", m, e)
}
fn order(es: &[f64], i: usize) -> f64 { (es[i + 1] / es[i]).ln() / (es[i] / es[i - 1]).ln() }
fn model(step: impl Fn(f64) -> f64, e0: f64, tol: f64) -> Vec<f64> {
    let mut es = vec![e0];
    while *es.last().unwrap() >= tol { let e = step(*es.last().unwrap()); es.push(e); }
    es
}
fn grad(x: f64, y: f64, b: f64) -> (f64, f64) { (-2.0 * (1.0 - x) - 4.0 * b * x * (y - x * x), 2.0 * b * (y - x * x)) }
fn hess(x: f64, y: f64, b: f64) -> (f64, f64, f64) { (2.0 - 4.0 * b * (y - x * x) + 8.0 * b * x * x, -4.0 * b * x, 2.0 * b) }
fn dist(x: f64, y: f64) -> f64 { ((x - 1.0) * (x - 1.0) + (y - 1.0) * (y - 1.0)).sqrt() }
fn eig(b: f64) -> (f64, f64) {
    let (p, q, r) = hess(1.0, 1.0, b);
    let (m, h) = ((p + r) / 2.0, (p - r) / 2.0);
    let rad = (h * h + q * q).sqrt();
    (m + rad, m - rad)
}
fn spd(c: f64) -> f64 { 10f64.ln() / -c.ln() } // steps per decimal digit
fn gd(mut x: f64, mut y: f64, tol: f64, b: f64, best: bool) -> Vec<f64> {
    let (lb, mb) = eig(b);
    let a = if best { 2.0 / (lb + mb) } else { 1.0 / lb };
    let mut es = vec![dist(x, y)];
    while *es.last().unwrap() >= tol {
        let g = grad(x, y, b);
        x -= a * g.0; y -= a * g.1;
        es.push(dist(x, y));
    }
    es
}
fn newton(mut x: f64, mut y: f64, tol: f64) -> Vec<f64> {
    let mut es = vec![dist(x, y)];
    while *es.last().unwrap() >= tol {
        let g = grad(x, y, 100.0);
        let (a, c, d) = hess(x, y, 100.0);
        let det = a * d - c * c;
        let (nx, ny) = (x - (d * g.0 - c * g.1) / det, y - (a * g.1 - c * g.0) / det);
        x = nx; y = ny;
        es.push(dist(x, y));
    }
    es
}
fn join(v: &[String]) -> String { v.join(" ") }

fn main() {
    // ---- 1. halving against squaring ----
    let half = model(|e| e / 2.0, 0.1, 1e-12);
    let sq = model(|e| e * e, 0.1, 1e-12);
    println!("chart, halving digits {}", join(&(0..7).map(|k| format!("{:.2}", -(0.1 / 2f64.powi(k)).log10())).collect::<Vec<_>>()));
    println!("chart, squaring digits {}", join(&(0..7).map(|k| format!("{:.0}", -(0.1f64).log10() * 2f64.powi(k))).collect::<Vec<_>>()));
    println!("after 1 step: halving {}, squaring {}; after 4: halving {}, squaring {}", sci(half[1]), sci(sq[1]), sci(half[4]), sci(sq[4]));
    println!("digits gained per step by halving {:.3}", -(0.5f64).log10());
    println!("steps to error < 1e-12: halving {}, squaring {}", half.len() - 1, sq.len() - 1);
    assert!(half.len() - 1 == (0.1f64 / 1e-12).log2().ceil() as usize);
    assert!(sq.len() - 1 == 12f64.log2().ceil() as usize);
    println!("order estimates: halving {:.3}, squaring {:.3}", order(&half, 5), order(&sq, 2));
    assert!((order(&half, 5) - 1.0).abs() < 1e-9);
    assert!((order(&sq, 2) - 2.0).abs() < 1e-9);

    // ---- 2. the condition number at the bottom of the valley ----
    let (l, mu) = eig(100.0);
    let kap = l / mu;
    let (p, q, r) = hess(1.0, 1.0, 100.0);
    let mut v = (1.0, 0.0);
    for _ in 0..60 { // power iteration: an independent road to L
        let w = (p * v.0 + q * v.1, q * v.0 + r * v.1);
        let n = (w.0 * w.0 + w.1 * w.1).sqrt();
        v = (w.0 / n, w.1 / n);
    }
    let lpow = v.0 * (p * v.0 + q * v.1) + v.1 * (q * v.0 + r * v.1);
    println!("Hessian at (1, 1): {:.0} {:.0} {:.0}; L {:.4} (power iteration {:.4}), mu {:.6}", p, q, r, l, lpow, mu);
    assert!((lpow - l).abs() < 1e-6);
    assert!(((p - mu) * (r - mu) - q * q).abs() < 1e-6);
    println!("by hand: mean {:.0}, half-gap {:.0}, radius {:.4}; step 1/L {:.6}; ln 10 {:.3}", (p + r) / 2.0, (p - r) / 2.0, l - (p + r) / 2.0, 1.0 / l, 10f64.ln());
    let (rate, best) = (1.0 - 1.0 / kap, (kap - 1.0) / (kap + 1.0));
    println!("kappa {:.2}; predicted rate 1 - 1/kappa {:.6}, {:.0} steps per digit", kap, rate, spd(rate));
    println!("best fixed step 2/(L + mu): rate {:.6}, {:.0} steps per digit", best, spd(best));
    let es = gd(-1.2, 1.0, 1e-6, 100.0, false);
    let n = es.len();
    println!("GD from (-1.2, 1): {} steps to error < 1e-6; last ratio {:.6}", n - 1, es[n - 1] / es[n - 2]);
    println!("GD error at k = 0, 1000, 10000, 20000, 30000: {}", join(&[0, 1000, 10000, 20000, 30000].iter().map(|&k| sci(es[k])).collect::<Vec<_>>()));
    let k3 = es.iter().position(|&e| e < 1e-3).unwrap();
    let k6 = n - 1;
    println!("steps from 1e-3 to 1e-6: measured {}, predicted {:.0}", k6 - k3, 3.0 * spd(rate));
    assert!((es[n - 1] / es[n - 2] - rate).abs() < 1e-6);
    assert!(((k6 - k3) as f64 / (3.0 * spd(rate)) - 1.0).abs() < 0.01);
    let ne = newton(-1.2, 1.0, 1e-6);
    println!("Newton from (-1.2, 1): {} steps; errors {}", ne.len() - 1, join(&ne.iter().map(|&e| sci(e)).collect::<Vec<_>>()));

    // ---- 3. measuring the order on the valley's slice y = 1: h'(x) = 400x^3 - 398x - 2 ----
    let dh = |x: f64| 400.0 * x * x * x - 398.0 * x - 2.0;
    let d2h = |x: f64| 1200.0 * x * x - 398.0;
    let d3h = |x: f64| 2400.0 * x;
    let (mut x, mut nt) = (1.2, vec![0.2]);
    while *nt.last().unwrap() > 1e-9 { x = x - dh(x) / d2h(x); nt.push((x - 1.0f64).abs()); }
    let (mut x0, mut x1, mut se) = (1.2, 1.1, vec![0.2, 0.1]);
    while *se.last().unwrap() > 1e-9 {
        let x2 = x1 - dh(x1) * (x1 - x0) / (dh(x1) - dh(x0));
        x0 = x1; x1 = x2; se.push((x1 - 1.0f64).abs());
    }
    let m = d3h(1.0) / (2.0 * d2h(1.0));
    println!("slice Newton errors {} | secant {}", join(&nt.iter().map(|&e| sci(e)).collect::<Vec<_>>()), join(&se.iter().map(|&e| sci(e)).collect::<Vec<_>>()));
    println!("Newton e(k+1)/e(k)^2: {} | predicted {:.4}", join(&(0..nt.len() - 1).map(|i| format!("{:.4}", nt[i + 1] / (nt[i] * nt[i]))).collect::<Vec<_>>()), m);
    println!("order estimates: Newton {} | secant {}", join(&(1..nt.len() - 1).map(|i| format!("{:.3}", order(&nt, i))).collect::<Vec<_>>()),
             join(&(1..se.len() - 1).map(|i| format!("{:.3}", order(&se, i))).collect::<Vec<_>>()));
    let (a, b) = (nt.len(), se.len());
    assert!((nt[a - 1] / (nt[a - 2] * nt[a - 2]) - m).abs() < 0.01);
    assert!((order(&nt, a - 2) - 2.0).abs() < 0.05);
    assert!((order(&se, b - 2) - (1.0 + 5f64.sqrt()) / 2.0).abs() < 0.05);
    println!("golden ratio phi {:.3}; slice second derivative {:.0}, third {:.0}", (1.0 + 5f64.sqrt()) / 2.0, d2h(1.0), d3h(1.0));

    // ---- what breaks ----
    let x4 = model(|e| e - 4.0 * e * e * e / (12.0 * e * e), 1.0, 1e-6); // Newton on x^4: flat bottom
    let (mut rx, mut ry, mut rk) = (-1.2f64, 1.0f64, 0); // GD, step 1/L, on a round bowl (L/2)|x - (1, 1)|^2, where kappa = 1
    while dist(rx, ry) >= 1e-6 { rx -= l * (rx - 1.0) / l; ry -= l * (ry - 1.0) / l; rk += 1; }
    println!("round-valley guess {} step, real {}; kappa from L alone: {:.0} steps per digit", rk, n - 1, spd(1.0 - 1.0 / l));
    println!("Newton on x^4: ratio {:.6}, {} steps to 1e-6; early order estimate {:.1}", x4[1] / x4[0], x4.len() - 1, order(&ne, 1));
    assert!((x4[1] / x4[0] - 2.0 / 3.0).abs() < 1e-12);
    assert!(x4.len() - 1 == (6.0 * 10f64.ln() / 1.5f64.ln()).ceil() as usize);

    // ---- try changing ----
    let b1 = eig(1.0);
    let g1 = gd(-1.2, 1.0, 1e-6, 1.0, false);
    println!("b = 1: kappa {:.2}, GD {} steps; tol 1e-9: GD {}, Newton {}", b1.0 / b1.1, g1.len() - 1,
             gd(-1.2, 1.0, 1e-9, 100.0, false).len() - 1, newton(-1.2, 1.0, 1e-9).len() - 1);
    println!("step 2/(L + mu): GD {} steps", gd(-1.2, 1.0, 1e-6, 100.0, true).len() - 1);
    let bars: Vec<String> = [2.0, 10.0, 100.0, 1000.0].iter().map(|&c: &f64| format!("kappa {}: {:.1}", c, spd(1.0 - 1.0 / c))).collect();
    println!("bars, steps per digit: {} kappa {:.0}: {:.1}", join(&bars), kap, spd(rate));
    println!("ALL CHECKS PASS");
}
