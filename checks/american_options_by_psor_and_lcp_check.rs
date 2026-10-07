// American options on a grid -- the same check as the Python, in Rust.  No crates.
// Rust has no erf, so the bell-curve area is built by adding thin slices under the
// curve (Simpson).  Projected SOR on a grid and a 2000-step tree are the two roads.
use std::f64::consts::PI;
const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;   // Acme: strike, rate, dividend
const SIG: f64 = 0.20; const T: f64 = 1.0;                        // volatility, and one year
const XL: f64 = -1.5; const XR: f64 = 1.5;                        // the grid spans ln(S/K)
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x
fn ncdf(x: f64) -> f64 {                                            // area to the left of x
    let (n, h) = (4000, x / 4000.0);
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn euro_put(r: f64) -> f64 {                     // Black-Scholes European put, Acme at 100
    let (vt, d1) = (SIG * T.sqrt(), (r - Q + 0.5 * SIG * SIG) * T / (SIG * T.sqrt()));
    K * (-r * T).exp() * ncdf(vt - d1) - K * (-Q * T).exp() * ncdf(-d1)
}
fn read_line(s: &[f64], g: &[f64], v: &[f64]) -> (f64, f64, f64) {
    // Last node on its floor, first node above it, then a sub-grid reading from the
    // free side, where the gap between value and payoff opens like a square.
    let k = (1..s.len() - 1).filter(|&i| g[i] > 0.0 && v[i] <= g[i] + 1e-12).last().unwrap();
    let (y1, y2) = ((v[k + 1] - g[k + 1]).sqrt(), (v[k + 2] - g[k + 2]).sqrt());
    (s[k], s[k + 1], s[k + 1] - y1 * (s[k + 2] - s[k + 1]) / (y2 - y1))
}
fn layers(m: usize, nt: usize, om: f64, mode: &str, r: f64)
          -> (Vec<f64>, Vec<f64>, Vec<f64>, usize, Vec<(f64, f64, f64)>, f64, f64) {
    // One implicit layer at a time, from expiry back to today.  mode "amer" projects
    // onto the floor inside every sweep, "euro" never does, "lift" solves the free
    // equations and lifts onto the floor once, at the layer's end.
    let (h, dt) = ((XR - XL) / m as f64, T / nt as f64);
    let nu = dt * SIG * SIG / (2.0 * h * h);                    // the spreading ratio
    let eta = dt * (r - Q - 0.5 * SIG * SIG) / (2.0 * h);       // the sliding ratio
    let (lo, up, d) = (nu - eta, nu + eta, 1.0 + 2.0 * nu + r * dt);
    let s: Vec<f64> = (0..=m).map(|i| K * (XL + i as f64 * h).exp()).collect();
    let g: Vec<f64> = s.iter().map(|&x| (K - x).max(0.0)).collect();
    let (mut v, mut sweeps, mut line) = (g.clone(), 0usize, vec![(0.0, 0.0, 0.0); 13]);
    for k in 0..nt {
        let (tau, b) = ((k + 1) as f64 * dt, v.clone());
        v[m] = 0.0;
        v[0] = if mode != "euro" { K - s[0] } else { K * (-r * tau).exp() - s[0] * (-Q * tau).exp() };
        loop {
            let mut chg = 0.0f64;
            for i in 1..m {
                let mut y = (1.0 - om) * v[i] + om * (b[i] + lo * v[i - 1] + up * v[i + 1]) / d;
                if mode == "amer" { y = y.max(g[i]) }             // project after relaxing
                chg = chg.max((y - v[i]).abs());
                v[i] = y;
            }
            sweeps += 1;
            if chg <= 1e-11 { break }
        }
        if mode == "lift" { for i in 0..=m { v[i] = v[i].max(g[i]) } }
        if mode == "amer" && r == R && (k + 1) * 12 % nt == 0 { line[(k + 1) * 12 / nt] = read_line(&s, &g, &v) }
    }
    (s, g, v, sweeps, line, (lo + up) / d, ((1.0 - om).abs() + om * up / d) / (1.0 - om * lo / d))
}
fn tree(n: usize, american: bool, r: f64) -> f64 {
    // Cox-Ross-Rubinstein: up or down each step, roll the payoff back, and for the
    // American put take the better of exercising and holding at every node.
    let (dt, u) = (T / n as f64, (SIG * (T / n as f64).sqrt()).exp());
    let (dn, disc) = (1.0 / u, (-r * dt).exp());
    let p = (((r - Q) * dt).exp() - dn) / (u - dn);
    let (mut pu, mut pd) = (vec![1.0f64; n + 1], vec![1.0f64; n + 1]);
    for i in 1..=n { pu[i] = pu[i - 1] * u; pd[i] = pd[i - 1] * dn; }
    let mut v: Vec<f64> = (0..=n).map(|j| (K - K * pu[n - j] * pd[j]).max(0.0)).collect();
    for i in (0..n).rev() {
        v = (0..=i).map(|j| disc * (p * v[j] + (1.0 - p) * v[j + 1])).collect();
        if american { v = (0..=i).map(|j| v[j].max(K - K * pu[i - j] * pd[j])).collect() }
    }
    v[0]
}
fn toy_exact(al: i64, ga: i64, b: [i64; 2], f: [i64; 2]) -> ([f64; 2], [f64; 2]) {
    // Two coupled values, settled exactly: try all four patterns of "on the floor /
    // above it", keep whichever meets all three conditions at once.
    let d = 1 + al + ga;
    for (num, den) in [([d * b[0] + ga * b[1], al * b[0] + d * b[1]], d * d - al * ga),
                       ([f[0] * d, b[1] + al * f[0]], d), ([b[0] + ga * f[1], f[1] * d], d),
                       ([f[0], f[1]], 1)] {
        let gap = [num[0] - f[0] * den, num[1] - f[1] * den];
        let w = [d * num[0] - ga * num[1] - b[0] * den, d * num[1] - al * num[0] - b[1] * den];
        if gap.iter().chain(w.iter()).all(|&z| z >= 0) && gap[0] * w[0] == 0 && gap[1] * w[1] == 0 {
            let q = den as f64;
            return ([num[0] as f64 / q, num[1] as f64 / q], [w[0] as f64 / q, w[1] as f64 / q]);
        }
    }
    panic!("no pattern met all three conditions")
}
fn toy_sweep(x: [f64; 2], b: [i64; 2], f: [i64; 2], al: f64, ga: f64, om: f64) -> [f64; 2] {
    let (d, mut new) = (1.0 + al + ga, x);       // one projected sweep, lower neighbour first
    for i in 0..2 {
        let (lower, upper) = (if i > 0 { new[i - 1] } else { 0.0 }, if i < 1 { x[i + 1] } else { 0.0 });
        new[i] = (f[i] as f64).max((1.0 - om) * x[i] + om * (b[i] as f64 + al * lower + ga * upper) / d);
    }
    new
}
fn pair(name: &str, a: f64, b: f64) { println!("  {:<40}{:>11.6}{:>11.6}", name, a, b) }
fn row(name: &str, v: f64) { println!("  {:<42}{:>13.6}", name, v) }
fn main() {
    let (bb, ff) = ([0i64, 3], [1i64, 0]);       // the right-hand side, and the two floors
    let free = [(3 * bb[0] + bb[1]) as f64 / 8.0, (bb[0] + 3 * bb[1]) as f64 / 8.0];
    let lift2 = [free[0].max(ff[0] as f64), free[1].max(ff[1] as f64)];
    let lift_w = [3.0 * lift2[0] - lift2[1] - bb[0] as f64, 3.0 * lift2[1] - lift2[0] - bb[1] as f64];
    let (lcp, lcp_w) = toy_exact(1, 1, bb, ff);
    let mut tx = [ff[0] as f64, ff[1] as f64];
    for _ in 0..40 { tx = toy_sweep(tx, bb, ff, 1.0, 1.0, 1.1) }
    let bad = (1.0 - 1.5) * 2.0 + 1.5 * 1.0f64.max(0.0);   // projecting before relaxing
    let good = toy_sweep([2.0, 0.0], [0, 0], [1, 0], 0.0, 0.0, 1.5)[0];  // the rule, from the sweep
    let (mut cyc, mut cycles) = (0.0f64, Vec::new());      // omega = 2, one value, floor 0
    for _ in 0..4 { cyc = toy_sweep([cyc, 0.0], [1, 0], [0, 0], 0.0, 0.0, 2.0)[0]; cycles.push(cyc) }
    let (m, nt, om) = (240usize, 120usize, 1.1f64);
    let (s, g, va, swa, line, qm, qs) = layers(m, nt, om, "amer", R);
    let (ve, vl) = (layers(m, nt, om, "euro", R).2, layers(m, nt, om, "lift", R).2);
    let (va0, ve0) = (layers(m, nt, om, "amer", 0.0).2, layers(m, nt, om, "euro", 0.0).2);
    let (i0, nu) = (m / 2, R - Q - 0.5 * SIG * SIG);   // index m/2 is ln(S/K) = 0, Acme at 100
    let pw = (-nu - (nu * nu + 2.0 * SIG * SIG * R).sqrt()) / (SIG * SIG);
    let perp = K * pw / (pw - 1.0);                    // the never-expiring put's line
    let mut lad: Vec<(usize, usize, usize, f64, f64, f64)> = Vec::new();
    for (mm, nn) in [(60usize, 30usize), (120, 60), (240, 120), (480, 240)] {
        let (sx, gx, vx, swx, _, _, _) = layers(mm, nn, om, "amer", R);
        lad.push((mm, nn, swx, vx[mm / 2], layers(mm, nn, om, "euro", R).2[mm / 2], read_line(&sx, &gx, &vx).2));
    }
    println!("the smallest one: two coupled values, floors 1 and 0");
    for (name, p) in [("free solve, no floor", free), ("free solve, then lifted to the floor", lift2),
                      ("  the lifted pair's two slacks", lift_w), ("exact search over patterns", lcp),
                      ("  its two slacks", lcp_w), ("projected SOR from the floor, 40 sweeps", tx)] {
        pair(name, p[0], p[1]); }
    println!("  {:<40}{:>11.6}  (correct {:.6})", "projecting before relaxing, one value", bad, good);
    println!("  {:<40}{}", "omega = 2 from 0, four sweeps",
             cycles.iter().map(|c| format!("{:>7.3}", c)).collect::<Vec<_>>().join(""));
    println!("\nAcme American put, grid {} x {}, omega {:.3}, {} sweeps in all", m, nt, om, swa);
    for (name, v) in [("contraction of the all-at-once map", qm),
                      ("contraction bound on one projected sweep", qs), ("American put at S = 100", va[i0]),
                      ("European, same grid, no floor", ve[i0]), ("European put, Black-Scholes", euro_put(R)),
                      ("early-exercise premium, same grid", va[i0] - ve[i0]),
                      ("floor lifted once at each layer's end", vl[i0]),
                      ("with r = 0: American on this grid", va0[i0]),
                      ("with r = 0: European on this grid", ve0[i0]),
                      ("line today, last node on its floor", line[12].0),
                      ("line today, first node above it", line[12].1),
                      ("line today, square-root reading", line[12].2), ("perpetual line, exact", perp)] {
        row(name, v); }
    println!("\nrefining the grid, with the tree as the second road");
    println!("  {:<12}{:>8}{:>11}{:>11}{:>10}{:>12}", "grid", "sweeps", "American", "European", "premium", "line today");
    for (mm, nn, sw, av, ev, ln) in &lad {
        println!("  {:<12}{:>8}{:>11.6}{:>11.6}{:>10.6}{:>12.4}", format!("{} x {}", mm, nn), sw, av, ev, av - ev, ln); }
    for n in [2000usize, 4000] {
        let (a, e) = (tree(n, true, R), tree(n, false, R));
        println!("  {:<12}{:>8}{:>11.6}{:>11.6}{:>10.6}", format!("tree {}", n), "", a, e, a - e); }
    println!("\nthe exercise line through the year, grid {} x {}", m, nt);
    let (mut h1, mut h2) = (format!("  {:<12}", "months left"), format!("  {:<12}", "exercise line"));
    for mo in [12usize, 9, 6, 3, 1, 0] {
        h1.push_str(&format!("{:>8}", mo));
        h2.push_str(&format!("{:>8.2}", if mo > 0 { line[mo].2 } else { K })); }
    println!("{}\n{}", h1, h2);
    println!("\ntoday's put against its payoff, grid {} x {}", m, nt);
    for (name, series) in [("Acme price", &s), ("put value", &va), ("payoff", &g)] {
        let cols: String = (i0 - 28..i0 + 5).step_by(4).map(|i| format!("{:>8.2}", series[i])).collect();
        println!("  {:<12}{}", name, cols); }
    assert!((lad[3].3 - tree(2000, true, R)).abs() < 0.01 && (lad[3].4 - euro_put(R)).abs() < 0.01);
    assert!(va[i0] - ve[i0] > 0.30);                  // the floor is worth real money
    assert!((va0[i0] - ve0[i0]).abs() < 1e-12);       // no interest, so the floor never binds
    assert!((tx[0] - lcp[0]).abs().max((tx[1] - lcp[1]).abs()) < 1e-12);  // sweeps vs the search
    assert!(lift_w[0].min(lift_w[1]) < 0.0 && lcp_w[0].min(lcp_w[1]) >= 0.0);
    assert!(perp < line[12].0 && line[12].1 < K && lad.iter().all(|l| (l.5 - lad[3].5).abs() < 0.5));
    let ic = s.iter().position(|&x| x == line[12].0).unwrap();   // the reported contact node
    assert!(va[ic] == g[ic] && va[ic + 1] - g[ic + 1] > 1e-6 && (2..13).all(|mo| line[mo].2 < line[mo - 1].2));
    assert!(bad < ff[0] as f64 && ff[0] as f64 <= good && cycles[0] - cycles[1] > 1.0);
    println!("ALL CHECKS PASS");
}
