// American exercise on a tree -- the same check as the Python, in Rust.  No crates.
// Rust has no erf, so the bell-curve area N(x) is built the honest way: thin
// slices added up under the curve (Simpson's rule).
use std::f64::consts::PI;
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                     // bell-curve area left of x
    if x < -12.0 { return 0.0; } else if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn bs(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64, put: bool) -> f64 {
    let vt = sigma * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sigma * sigma) * t) / vt;
    let d2 = d1 - vt;
    if put { k * (-r * t).exp() * n_cdf(-d2) - s * (-q * t).exp() * n_cdf(-d1) }
    else { s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2) }
}
fn moves(r: f64, q: f64, sigma: f64, dt: f64, kind: &str) -> (f64, f64, f64) {
    if kind == "crr" {                        // Cox-Ross-Rubinstein: mirror moves
        let u = (sigma * dt.sqrt()).exp();
        return (u, 1.0 / u, (((r - q) * dt).exp() - 1.0 / u) / (u - 1.0 / u));
    }
    let nu = (r - q - 0.5 * sigma * sigma) * dt;   // Jarrow-Rudd: even odds
    ((nu + sigma * dt.sqrt()).exp(), (nu - sigma * dt.sqrt()).exp(), 0.5)
}
// Backward induction.  rule "hold" never exercises early (the European price),
// "max" takes the larger of holding and exercising (the American price), "bar"
// follows a fixed line: exercise at or below bar, hold above it.
fn tree(s0: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64, steps: usize,
        rule: &str, put: bool, kind: &str, bar: f64) -> (f64, Vec<f64>) {
    let dt = t / steps as f64;
    let (u, d, p) = moves(r, q, sigma, dt, kind);
    let disc = (-r * dt).exp();
    let pay = |s: f64| if put { (k - s).max(0.0) } else { (s - k).max(0.0) };
    let mut spot: Vec<f64> = (0..=steps)
        .map(|j| s0 * u.powf(j as f64) * d.powf((steps - j) as f64)).collect();
    let mut v: Vec<f64> = spot.iter().map(|&s| pay(s)).collect();
    let mut edge = vec![0.0f64; steps + 1];
    for i in (0..steps).rev() {
        spot.truncate(i + 1);                            // this step's prices
        for s in spot.iter_mut() { *s /= d; }
        v = (0..=i).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
        if rule != "hold" {
            for j in 0..=i {
                let x = pay(spot[j]);
                let take = if rule == "max" { x > v[j] } else { spot[j] <= bar };
                if take { v[j] = x;  edge[i] = edge[i].max(spot[j]); }
            }
        }
    }
    (v[0], edge)
}
// Road three: no tree at all.  A row of log-spaced prices marched back through
// time by the rule the Black-Scholes equation gives, taking the larger of
// holding and exercising at every price after every step.
fn grid(s0: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {
    let (nx, half) = (301usize, 1.5f64);
    let dx = 2.0 * half / (nx - 1) as f64;
    let nt = (t * sigma * sigma / (0.4 * dx * dx)) as usize + 1;  // small steps stay stable
    let dt = t / nt as f64;
    let (a, b) = (0.5 * sigma * sigma * dt / (dx * dx), (r - q - 0.5 * sigma * sigma) * dt / (2.0 * dx));
    let sp: Vec<f64> = (0..nx).map(|i| s0 * (-half + i as f64 * dx).exp()).collect();
    let mut v: Vec<f64> = sp.iter().map(|&s| (k - s).max(0.0)).collect();
    for _ in 0..nt {
        let mut w = v.clone();
        for i in 1..nx - 1 {
            w[i] = (v[i] + a * (v[i+1] - 2.0 * v[i] + v[i-1]) + b * (v[i+1] - v[i-1])) / (1.0 + r * dt);
        }
        w[0] = k - sp[0];  w[nx - 1] = 0.0;
        v = (0..nx).map(|i| w[i].max((k - sp[i]).max(0.0))).collect();
    }
    v[(nx - 1) / 2]
}
fn main() {
    let (s, k, r, q, sigma, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (u, d, p) = moves(r, q, sigma, t / 4.0, "crr");
    let low = s * d * d * d;                       // three down moves in a row
    let kids = ((k - low * u).max(0.0), (k - low * d).max(0.0));
    let hold = (-r * t / 4.0).exp() * (p * kids.0 + (1.0 - p) * kids.1);
    let (am4, eu4) = (tree(s, k, r, q, sigma, t, 4, "max", true, "crr", 0.0).0, tree(s, k, r, q, sigma, t, 4, "hold", true, "crr", 0.0).0);
    let (eu_tree, eu_bs) = (tree(s, k, r, q, sigma, t, 2000, "hold", true, "crr", 0.0).0,
                            bs(s, k, r, q, sigma, t, true));
    let (am, edge) = tree(s, k, r, q, sigma, t, 2000, "max", true, "crr", 0.0);
    let (am_jr, am_grid) = (tree(s, k, r, q, sigma, t, 2000, "max", true, "jr", 0.0).0, grid(s, k, r, q, sigma, t));
    let rows: Vec<(&str, f64)> = vec![
        ("up move u, one quarter", u), ("down move d, one quarter", d), ("chance of an up move p", p),
        ("three downs: the price at 9 months", low), ("hold: discounted average of the two", hold),
        ("exercise now: K - S", k - low), ("the larger of the two: exercise", hold.max(k - low)),
        ("4-step tree, American put", am4), ("4-step tree, European put", eu4),
        ("2000-step tree, European put", eu_tree), ("Black-Scholes European put", eu_bs),
        ("2000-step tree, American put", am), ("Jarrow-Rudd tree, American put", am_jr),
        ("grid, no tree, American put", am_grid), ("early-exercise premium", am - eu_tree),
        ("the most it could be, K(1 - e^-rT)", k * (1.0 - (-r * t).exp()))];
    for (name, val) in &rows { println!("{:<38}{:>13.6}", name, val); }
    println!("{:<38}{:>13.6}{:>13.6}", "  the two payoffs at expiry, up then down", kids.0, kids.1);
    println!();
    let counts = [10usize, 25, 50, 100, 250, 500, 1000, 2000];
    println!("steps       {}", counts.iter().map(|n| format!("{:>9}", n)).collect::<Vec<_>>().join(""));
    println!("American put{}", counts.iter().map(|&n| format!("{:>9.4}", tree(s, k, r, q, sigma, t, n, "max", true, "crr", 0.0).0)).collect::<Vec<_>>().join(""));
    println!();
    let bars = [95.0_f64, 90.0, 85.0, 82.0, 75.0];
    let fixed: Vec<f64> = bars.iter()
        .map(|&b| tree(s, k, r, q, sigma, t, 2000, "bar", true, "crr", b).0).collect();
    println!("a fixed exercise line at {}", bars.iter().map(|b| format!("{:>9.0}", b)).collect::<Vec<_>>().join(""));
    println!("is worth                {}", fixed.iter().map(|v| format!("{:>9.4}", v)).collect::<Vec<_>>().join(""));
    println!();
    println!("exercise boundary: the highest price still worth exercising, 2000 steps");
    let months = [2usize, 4, 6, 8, 10, 12];
    println!("months gone {}", months.iter().map(|m| format!("{:>9}", m)).collect::<Vec<_>>().join(""));
    println!("price       {}", months.iter().map(|&m| format!("{:>9.2}", if m < 12 { edge[m * 2000 / 12] } else { k })).collect::<Vec<_>>().join(""));
    println!();
    let (c_am0, c_bs0) = (tree(s, k, r, 0.0, sigma, t, 2000, "max", false, "crr", 0.0).0,
                          bs(s, k, r, 0.0, sigma, t, false));
    let (c_am, c_eu) = (tree(s, k, r, q, sigma, t, 2000, "max", false, "crr", 0.0).0,
                        tree(s, k, r, q, sigma, t, 2000, "hold", false, "crr", 0.0).0);
    for (name, val) in [("American call, no dividend, tree", c_am0),
                        ("Black-Scholes call, no dividend", c_bs0),
                        ("American call, 2% dividend, tree", c_am),
                        ("European call, the same tree", c_eu)] {
        println!("{:<38}{:>13.6}", name, val);
    }
    println!("{:<38}{:>13.9}", "American minus European call, 2% dividend", c_am - c_eu);
    println!();
    println!("premium against the rate, at the money, per $100 of strike");
    let mut prem_r: Vec<f64> = Vec::new();
    for rate in [0.00_f64, 0.02, 0.05, 0.10] {
        let a1 = tree(s, k, rate, q, sigma, t, 1000, "max", true, "crr", 0.0).0;
        let e1 = tree(s, k, rate, q, sigma, t, 1000, "hold", true, "crr", 0.0).0;
        prem_r.push(a1 - e1);
        println!("  r = {:.2}    premium {:8.4}", rate, a1 - e1);
    }
    println!("premium against volatility: at the money at $100, then deep in at $75");
    let (mut prem_atm, mut prem_itm): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for sg in [0.10_f64, 0.20, 0.30, 0.40] {
        let a1 = tree(s, k, r, q, sg, t, 1000, "max", true, "crr", 0.0).0;
        let e1 = tree(s, k, r, q, sg, t, 1000, "hold", true, "crr", 0.0).0;
        let a2 = tree(75.0, k, r, q, sg, t, 1000, "max", true, "crr", 0.0).0;
        let e2 = tree(75.0, k, r, q, sg, t, 1000, "hold", true, "crr", 0.0).0;
        prem_atm.push(a1 - e1);
        prem_itm.push(a2 - e2);
        println!("  sigma = {:.2} premium {:8.4} at $100,{:8.4} at $75", sg, a1 - e1, a2 - e2);
    }
    println!();
    let spots: Vec<f64> = (0..9).map(|i| 60.0 + 5.0 * i as f64).collect();
    let am_curve: Vec<f64> = spots.iter().map(|&x| tree(x, k, r, q, sigma, t, 1000, "max", true, "crr", 0.0).0).collect();
    let eu_curve: Vec<f64> = spots.iter().map(|&x| tree(x, k, r, q, sigma, t, 1000, "hold", true, "crr", 0.0).0).collect();
    println!("chart, Acme price     {}", spots.iter().map(|x| format!("{:>8.0}", x)).collect::<Vec<_>>().join(""));
    println!("chart, American put   {}", am_curve.iter().map(|x| format!("{:>8.2}", x)).collect::<Vec<_>>().join(""));
    println!("chart, European put   {}", eu_curve.iter().map(|x| format!("{:>8.2}", x)).collect::<Vec<_>>().join(""));
    println!("chart, exercise now   {}", spots.iter().map(|x| format!("{:>8.2}", (k - x).max(0.0))).collect::<Vec<_>>().join(""));
    assert!((eu_bs - 6.330080627550).abs() < 1e-9, "the closed form vs the house put price");
    assert!((eu_tree - eu_bs).abs() < 0.005, "the tree without the max vs the closed form");
    assert!((am - am_jr).abs() < 0.01, "two lattices, one American price");
    assert!((am - am_grid).abs() < 0.02, "lattice against grid");
    assert!((c_am0 - c_bs0).abs() < 0.005, "no dividend: the American call equals the European");
    assert!(am - eu_tree > 0.3, "the right to exercise early is worth real money");
    assert!(fixed.iter().all(|&x| x < am - 0.01), "every fixed line is beaten by the moving one");
    assert!((0..9).all(|i| am_curve[i] >= (k - spots[i]).max(0.0) - 1e-9), "never below intrinsic");
    assert!([2usize, 4, 6, 8].iter().all(|&m| edge[m * 2000 / 12] < edge[(m + 2) * 2000 / 12]), "the boundary climbs");
    assert!(prem_r[0] < 1e-9 && 1e-9 < prem_r[3], "no premium at a zero rate, a large one at 10%");
    assert!(prem_itm[0] > prem_itm[3], "deep in the money, volatility cuts the premium");
    assert!(prem_atm[0] < prem_atm[3], "at the money, volatility lifts it");
    println!("ALL CHECKS PASS");
}
