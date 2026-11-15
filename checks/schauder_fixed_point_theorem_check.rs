// Schauder -- the same check as the Python, in Rust.  No crates.
// Part 1 is the finite rehearsal: a three-good market, where Brouwer applies.
// Parts 2-4 cut infinite-dimensional maps to N numbers, at several N.  Floats
// are added in explicit loops, so Python and Rust add in the same order.

const ALPHA: [[f64; 3]; 2] = [[0.2, 0.5, 0.3], [0.6, 0.1, 0.3]]; // spending shares: Ann, Ben
const OWN: [[f64; 3]; 2] = [[8.0, 1.0, 2.0], [2.0, 9.0, 4.0]];   // units owned: grain, cloth, fuel
const CAP: f64 = 100.0;                     // demand cap, so z stays finite at p_i = 0
const Q: f64 = 0.01;
const K: f64 = 0.01;
const TAU: f64 = 100.0;

fn excess(p: &[f64]) -> [f64; 3] {          // z_i(p): units wanted minus units owned
    let mut z = [0.0; 3];
    for (a, w) in ALPHA.iter().zip(OWN.iter()) {
        let wealth = p[0] * w[0] + p[1] * w[1] + p[2] * w[2];
        for i in 0..3 {
            z[i] += if p[i] > 0.0 { (a[i] * wealth / p[i]).min(CAP) } else { CAP };
            z[i] -= w[i];
        }
    }
    z
}

fn price_map(p: &[f64], s: f64) -> Vec<f64> { // raise short goods by s per unit, rescale to 100
    let up: Vec<f64> = excess(p).iter().map(|&zi| zi.max(0.0)).collect();
    let total = 100.0 + s * (up[0] + up[1] + up[2]);
    (0..3).map(|i| 100.0 * (p[i] + s * up[i]) / total).collect()
}

fn dist(u: &[f64], v: &[f64]) -> f64 {      // l2 distance, squares added left to right
    let mut t = 0.0;
    for (a, b) in u.iter().zip(v.iter()) { t += (a - b) * (a - b); }
    t.sqrt()
}

fn time_to(u: f64) -> f64 {                 // closed form: seconds to reach depth u^2
    (2.0 / K) * (-u - (Q / K) * (1.0 - K * u / Q).ln())
}

fn depth(t: f64) -> f64 {                   // road one: invert the closed form by halving
    let (mut lo, mut hi) = (0.0, Q / K);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if time_to(mid) < t { lo = mid } else { hi = mid }
    }
    lo * lo
}

fn kak(x: &[f64]) -> Vec<f64> {             // Kakutani's map cut to len(x) entries
    let r = dist(x, &vec![0.0; x.len()]);
    let mut out = vec![(1.0 - r * r).max(0.0).sqrt()];
    out.extend_from_slice(&x[..x.len() - 1]);
    out
}

fn main() {
    // 1a. Road one: clearing prices by hand.  Fuel: 7.2 p3 = 300.
    //     Cloth: 8.6 p2 = 4.2 p1 + 1.4 p3 with p1 = 100 - p2 - p3.
    let p3 = 300.0 / 7.2;
    let p2 = (4.2 * (100.0 - p3) + 1.4 * p3) / 12.8;
    let star = [100.0 - p2 - p3, p2, p3];
    let zmax = excess(&star).iter().fold(0.0_f64, |m, zi| m.max(zi.abs()));
    println!("clearing prices (GBP): grain {:.6}, cloth {:.6}, fuel {:.6}", star[0], star[1], star[2]);
    println!("wealth there: Ann {:.6}, Ben {:.6}; largest excess demand {:.6}",
             star[0] * 8.0 + star[1] + star[2] * 2.0, star[0] * 2.0 + star[1] * 9.0 + star[2] * 4.0, zmax);
    assert!(zmax < 1e-9);
    for s in [1.0, 20.0] {
        let mv = dist(&price_map(&star, s), &star);
        println!("s = {:4.1}: the price map moves the clearing prices by {:.6}", s, mv);
        assert!(mv < 1e-9);
    }

    // 1b. Road two: search the price triangle on a 0.25 GBP grid for the point the map moves least.
    let (mut best, mut at) = (1e9, vec![0.0; 3]);
    for a in 0..401 {
        for b in 0..(401 - a) {
            let p = vec![a as f64 * 0.25, b as f64 * 0.25, 100.0 - a as f64 * 0.25 - b as f64 * 0.25];
            let d = dist(&price_map(&p, 20.0), &p);
            if d < best { best = d; at = p; }
        }
    }
    println!("grid search, s = 20: least move {:.6} at ({:.2}, {:.2}, {:.2})", best, at[0], at[1], at[2]);
    assert!(dist(&at, &star) < 0.25);

    // 1c. Repeating the map: settles at s = 1, never settles at s = 20.
    let mut smallest = 1e9;
    for s in [1.0, 20.0] {
        let mut p = vec![100.0 / 3.0; 3];
        smallest = 1e9;
        for n in 1..=2000 {
            let new = price_map(&p, s);
            if n > 1000 { smallest = f64::min(smallest, dist(&new, &p)); }
            p = new;
        }
        println!("s = {:4.1}: after 2000 rounds, distance to clearing {:.6}; smallest move in rounds 1001-2000 {:.6}",
                 s, dist(&p, &star), smallest);
    }
    assert!(smallest > 1.0);
    for d in [0.1, 0.01] {
        let nudged = [star[0] + d, star[1] - d, star[2]];
        let ratio = dist(&price_map(&nudged, 20.0), &star) / dist(&nudged, &star);
        println!("s = 20, nudge {:.2}: the map stretches the gap to the fixed point by {:.6}", d, ratio);
        assert!(ratio > 1.0);
    }

    // 1d. A buyer who wants 10 units of fuel below 50 GBP and none at or above it; 5 for sale.
    let moves: Vec<f64> = (0..10001)            // fuel prices 0 to 100 GBP
        .map(|k| 2.0 * ((if k as f64 * 0.01 < 50.0 { 10.0 } else { 0.0 }) - 5.0)).collect();
    let least = moves.iter().fold(f64::INFINITY, |m, v| m.min(v.abs()));
    println!("jumping demand, fuel prices 0-100 GBP moved by 2 GBP per unit short: least move {:.6} GBP", least);
    assert!(least == 2.0 * f64::min(10.0 - 5.0, 5.0 - 0.0));
    assert!(moves.iter().enumerate().all(|(k, m)| (0.0..=100.0).contains(&(k as f64 * 0.01 + m))));

    // 2. The tank: h' = q - k sqrt(h), h(0) = 0.  q = 0.01 m/s, k = 0.01 m^0.5/s, window 100 s.
    println!("tank closed form: depth at 25 s {:.6} m, 50 s {:.6} m, 100 s {:.6} m; level it tends to {:.6} m",
             depth(25.0), depth(50.0), depth(100.0), (Q / K) * (Q / K));
    println!("self-map test: inflow alone over the window, q * tau = {:.6} m, cap 1 m", Q * TAU);
    for d in [1e-2, 1e-4, 1e-6] {           // T(d) - T(0) = -k sqrt(d) t, largest at t = tau
        let g = K * f64::sqrt(d) * TAU;
        println!("start gap {:.6} m: gap after the integral map {:.6} m, ratio {:.1}", d, g, g / d);
    }
    let mut errs = Vec::new();
    for n in [10usize, 100, 1000, 10000] {  // road two: Euler polygons, the Peano construction
        let (mut h, dt) = (0.0_f64, TAU / n as f64);
        for _ in 0..n { h += dt * (Q - K * h.sqrt()); }
        let e = (h - depth(TAU)).abs();
        errs.push(e);
        println!("N = {:5} steps: depth at 100 s {:.6} m, error {:.6} m, log10 N {:.0}, log10 error {:.3}",
                 n, h, e, (n as f64).log10(), e.log10());
    }
    assert!(errs[3] < 1e-4 && 8.0 < errs[0] / errs[1] && errs[0] / errs[1] < 12.0);
    assert!(8.0 < errs[2] / errs[3] && errs[2] / errs[3] < 12.0);

    // 3. The tank run backwards from empty: y' = k sqrt(y), y(0) = 0.  Two fixed points.
    let (n, ds) = (10000usize, TAU / 10000.0);
    let y: Vec<f64> = (0..=n).map(|i| (K * i as f64 * ds / 2.0) * (K * i as f64 * ds / 2.0)).collect();
    let (mut acc, mut worst) = (0.0_f64, 0.0_f64); // apply the integral map by the trapezoid rule
    for i in 0..n {
        acc += ds * K * (y[i].sqrt() + y[i + 1].sqrt()) / 2.0;
        worst = worst.max((acc - y[i + 1]).abs());
    }
    println!("backwards tank: h = 0 and h = (k t / 2)^2 both solve; trapezoid residual {:.6} m; gap at 100 s {:.6} m",
             worst, y[n]);
    assert!(worst < 1e-9 && (y[n] - 0.25).abs() < 1e-12);

    // 4. Kakutani's map on the l2 ball, cut to N entries: (sqrt(1 - |x|^2), x_1, ..., x_{N-1}).
    for n in [10usize, 100, 1000] {
        let (mut lo, mut hi) = (0.0_f64, 1.0_f64); // road one: halve on c = sqrt(1 - N c^2)
        for _ in 0..100 {
            let mid = (lo + hi) / 2.0;
            if mid < (1.0 - n as f64 * mid * mid).max(0.0).sqrt() { lo = mid } else { hi = mid }
        }
        let x = vec![lo; n];
        let res = dist(&kak(&x), &x);       // the cut map leaves x in place
        let mut x1 = x.clone();
        x1.push(0.0);
        let true_move = dist(&kak(&x1), &x1); // the next entry: the full map moves it
        let far = 1.0 / ((10 * n + 1) as f64).sqrt(); // fixed point of the 10N cut: closed form
        let gap = (n as f64 * (lo - far) * (lo - far) + 9.0 * n as f64 * far * far).sqrt();
        let inv = 1.0 / ((n + 1) as f64).sqrt();
        println!("N = {:4}: c = {:.6} (1/sqrt(N+1) = {:.6}), size {:.6}, residual {:.6}, full map moves it {:.6}, gap to the N = {} point {:.6}",
                 n, lo, inv, (n as f64).sqrt() * lo, res, true_move, 10 * n, gap);
        assert!((lo - inv).abs() < 1e-12 && res < 1e-9 && gap > 1.0);
        assert!((true_move - inv).abs() < 1e-12);
    }
    println!("ALL CHECKS PASS");
}
