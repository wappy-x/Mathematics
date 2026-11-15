// Entropy conditions -- the same check as the Python, in Rust.  No crates.
// A one-lane road, Greenshields flux q(rho) = V rho (1 - rho/RM).  A light at
// x = 0 turns green at t = 0: a jammed queue behind it, an empty road ahead.
// Roads: the Lax test, the entropy inequality, the Cole-Hopf formula for the
// viscous road, a finite-difference grid for the viscous road, and its residual.
use std::f64::consts::PI;
const V: f64 = 25.0; // top speed, m/s
const RM: f64 = 0.15; // jam density, cars/m
const T: f64 = 60.0; // time, s
fn q(r: f64) -> f64 { V * r * (1.0 - r / RM) } // flux, cars per second
fn dq(r: f64) -> f64 { V * (1.0 - 2.0 * r / RM) } // wave speed q'(rho), m/s
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn pf(d: f64) -> &'static str { if d <= 0.0 { "passes" } else { "fails" } }
fn sci(v: f64) -> String { // e-notation with the same digits as the Python
    let e = v.abs().log10().floor() as i32;
    let m = v / 10f64.powi(e);
    format!("{:.3}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn fan(x: f64, t: f64) -> f64 { (RM / 2.0 * (1.0 - x / (V * t))).max(0.0).min(RM) }
fn log_phi(z: f64) -> f64 { // log of the normal CDF, written out
    if z < -3.0 { // continued fraction for the far left tail
        let x = -z;
        let mut f = x;
        for k in (1..=(30 + (300.0 / x) as i64)).rev() { f = x + k as f64 / f; }
        return -x * x / 2.0 - 0.5 * (2.0 * PI).ln() - f.ln();
    }
    if z > 3.0 { return (-log_phi(-z).exp()).ln_1p(); }
    let (mut term, mut s, mut n) = (z, z, 0.0); // power series in the middle
    while term.abs() > 1e-17 * s.abs() {
        n += 1.0;
        term *= z * z / (2.0 * n + 1.0);
        s += term;
    }
    (0.5 + s * (-z * z / 2.0).exp() / (2.0 * PI).sqrt()).ln()
}
fn visc(x: f64, t: f64, eps: f64) -> f64 { // exact viscous density, by Cole-Hopf
    let sg = (2.0 * eps * t).sqrt();
    let d = -V * x / eps + log_phi((x - V * t) / sg) - log_phi(-(x + V * t) / sg);
    if d > 700.0 { 0.0 } else { RM / (1.0 + d.exp()) }
}
fn grid(eps: f64, dx: f64) -> f64 { // second road: explicit grid, t = 50 s to 60 s
    let (t0, t1, half) = (50.0, T, 2000.0);
    let n = (2.0 * half / dx) as usize;
    let xs: Vec<f64> = (0..=n).map(|i| -half + i as f64 * dx).collect();
    let mut r: Vec<f64> = xs.iter().map(|&x| visc(x, t0, eps)).collect();
    let steps = ((t1 - t0) * 4.0 * eps / (dx * dx)).round() as usize;
    let dt = (t1 - t0) / steps as f64;
    let (a, b) = (dt / (2.0 * dx), eps * dt / (dx * dx));
    for _ in 0..steps {
        let f: Vec<f64> = r.iter().map(|&v| q(v)).collect();
        let mut nr = r.clone();
        for i in 1..n {
            nr[i] = r[i] - a * (f[i + 1] - f[i - 1]) + b * (r[i + 1] - 2.0 * r[i] + r[i - 1]);
        }
        r = nr;
    }
    (0..=n).map(|i| (r[i] - visc(xs[i], t1, eps)).abs()).fold(0.0, f64::max) * 1000.0
}
fn jump(rl: f64, rr: f64) -> (f64, bool, f64) { // speed, Lax test, entropy production
    let s = (q(rr) - q(rl)) / (rr - rl);
    let psi = |r: f64| V * (r * r / 2.0 - 2.0 * r.powi(3) / (3.0 * RM)); // eta = rho^2/2
    (s, dq(rl) > s && s > dq(rr), (psi(rr) - psi(rl)) - s * (rr * rr - rl * rl) / 2.0)
}
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn qx(n: i128, d: i128) -> (i128, i128) { // flux 25 r (1 - r/(15/100)) at r = n/d, exact
    let (num, den) = (25 * n * (15 * d - 100 * n), d * 15 * d);
    let g = gcd(num, den);
    (num / g, den / g)
}
fn main() {
    let (kk, hh_) = (1000.0, 3600.0); // cars/m to cars/km; cars/s to cars/h
    println!("GREEN LIGHT: queue at 150 cars/km behind x = 0, empty road ahead");
    let (sa, laxa, da) = jump(RM, 0.0);
    println!("rival A, the jump stays put: q left {:.0}, q right {:.0} cars/h, speed {:.1} m/s",
             q(RM) * hh_, q(0.0) * hh_, sa + 0.0);
    println!("  wave speeds: left {:.0} m/s, right {:.0} m/s; Lax test passes: {}", dq(RM), dq(0.0), yn(laxa));
    println!("  entropy production {:.5} (must be <= 0): {}", da, pf(da));
    let h = 0.01;
    let past_fan: f64 = (0..(V * T / h) as usize).map(|i| fan((i as f64 + 0.5) * h, T)).sum::<f64>() * h;
    println!("rival B, the fan: density at the light {:.1} cars/km, flow {:.0} cars/h", fan(0.0, T) * kk, q(RM / 2.0) * hh_);
    println!("  at t = 60 s: fan edges at x = {:.0} m and {:.0} m, density at x = 750 m {:.1} cars/km",
             -V * T, V * T, fan(750.0, T) * kk);
    println!("  cars past the light in 60 s: flow x time {:.2}, area under the fan {:.2}, rival A {:.2}",
             q(RM / 2.0) * T, past_fan, 0.0);
    println!("  start wave: the car at x = -300 m has {:.0} cars ahead and starts at {:.1} s; jam spacing {:.2} m",
             300.0 * RM, 300.0 / V, 1.0 / RM);
    println!("  top speed {:.0} m/s = {:.0} km/h; L1 gap rival A to fan {:.2} cars", V, V * 3.6, 2.0 * past_fan);

    println!("RED LIGHT: arrivals at 30 cars/km run into a queue at 150 cars/km");
    let ((a1, b1), (a2, b2)) = (qx(15, 100), qx(3, 100)); // exact shock speed
    let (num, den) = ((a1 * b2 - a2 * b1) * 100, b1 * b2 * 12);
    let g = gcd(num, den);
    let (sn, sd) = (num / g * den.signum(), den.abs() / g);
    let (sr, laxr, dr) = jump(0.03, RM);
    let s_exact = if sd == 1 { format!("{}", sn) } else { format!("{}/{}", sn, sd) };
    println!("  arrivals flow {:.0} cars/h; shock speed {:.4} m/s = {:.1} km/h, exact {}",
             q(0.03) * hh_, sr, sr * 3.6, s_exact);
    println!("  wave speeds: behind {:.0} m/s, ahead {:.0} m/s; Lax test passes: {}", dq(0.03), dq(RM), yn(laxr));
    println!("  entropy production {:.5} (must be <= 0): {}", dr, pf(dr));
    let car = |r: f64| V * (1.0 - r / RM);
    println!("  mistake, car speeds in the test: {:.0} > {:.0} > {:.0} holds: {}",
             car(0.03), sr, car(RM), yn(car(0.03) > sr && sr > car(RM)));
    for eps in [20.0, 2.0, 0.2] {
        let w = 4.0 * eps / (dq(0.03) - dq(RM));
        println!("  viscous shock, eps = {:>4.1} m^2/s: thickness 4 eps/40 = {:.3} m", eps, w);
    }

    println!("VANISHING VISCOSITY at t = 60 s (Cole-Hopf, exact for each eps)");
    println!("  eps m^2/s | cars/km at 750 m | cars/km at 1500 m | L1 gap to fan, cars | cars past light");
    let (mut gaps, mut past) = (vec![], vec![]);
    for eps in [200.0, 20.0, 2.0, 0.2] {
        let dx = 0.5; // symmetric about the light: integrate x > 0 only
        let xs: Vec<f64> = (0..4000).map(|i| (i as f64 + 0.5) * dx).collect();
        gaps.push(2.0 * xs.iter().map(|&x| (visc(x, T, eps) - fan(x, T)).abs()).sum::<f64>() * dx);
        past.push(xs.iter().map(|&x| visc(x, T, eps)).sum::<f64>() * dx);
        println!("  {:>9.1} | {:>16.3} | {:>17.3} | {:>19.4} | {:>15.4}", eps, visc(750.0, T, eps) * kk,
                 visc(1500.0, T, eps) * kk, gaps[gaps.len() - 1], past[past.len() - 1]);
    }
    println!("  gap shrinks by {:.2}, {:.2}, {:.2} per tenfold cut in eps",
             gaps[0] / gaps[1], gaps[1] / gaps[2], gaps[2] / gaps[3]);
    println!("  mistake, stop at eps = 200: {:.2} cars cross, {:.2} cars misplaced", past[0], gaps[0]);
    let (e2, e1) = (grid(50.0, 2.0), grid(50.0, 1.0));
    println!("  grid road, eps = 50, 50 s to 60 s: max error {} cars/km at dx = 2 m, {} at dx = 1 m, order {:.2}",
             sci(e2), sci(e1), (e2 / e1).log2());
    let mut res = vec![];
    for hh in [1.0, 0.5] { // residual rho_t + q_x - eps rho_xx at (750 m, 60 s)
        let f = |x: f64, t: f64| visc(x, t, 20.0);
        let rt = (f(750.0, T + hh) - f(750.0, T - hh)) / (2.0 * hh);
        let qd = (q(f(750.0 + hh, T)) - q(f(750.0 - hh, T))) / (2.0 * hh);
        let rxx = (f(750.0 + hh, T) - 2.0 * f(750.0, T) + f(750.0 - hh, T)) / (hh * hh);
        res.push(rt + qd - 20.0 * rxx);
    }
    println!("  residual of the Cole-Hopf answer, eps = 20: {} at step 1, {} at step 0.5", sci(res[0]), sci(res[1]));
    let k = 2.0 * PI / 1.0; // a ripple 1 m long; eps = -1 m^2/s, t = 1 s
    let grow = 1.0 * k * k * 1.0 / 10f64.ln(); // log10 of e^(|eps| k^2 t)
    println!("mistake, eps = -1 m^2/s: a 1 m ripple grows by 10^{:.2} in one second", grow);
    let pts: Vec<f64> = (0..17).map(|i| -2000.0 + 250.0 * i as f64).collect();
    let row = |g: &dyn Fn(f64) -> f64| pts.iter().map(|&x| format!("{:.1}", g(x) * kk)).collect::<Vec<_>>().join(", ");
    println!("chart x m:   {}", pts.iter().map(|x| format!("{}", x)).collect::<Vec<_>>().join(", "));
    println!("chart A:     {}", row(&|x| if x < 0.0 { RM } else { 0.0 }));
    println!("chart fan:   {}", row(&|x| fan(x, T)));
    println!("chart eps200:{}", row(&|x| visc(x, T, 200.0)));
    println!("figure, x from {} to {} m, t from 0 to {:.0} s, fan edges ({:.0}, {:.0}) and ({:.0}, {:.0}), rival A jump x = 0",
             -2000, 2000, T, -V * T, T, V * T, T);

    assert!(sa == 0.0 && !laxa && da > 0.0 && laxr && dr < 0.0); // Lax and entropy agree
    assert!(sn == -5 && sd == 1 && (sr + 5.0).abs() < 1e-12);
    assert!((past_fan - q(RM / 2.0) * T).abs() < 1e-6 && (q(RM / 2.0) * T - 56.25).abs() < 1e-12);
    assert!(gaps[0] > gaps[1] && gaps[1] > gaps[2] && gaps[2] > gaps[3] && gaps[3] < 0.05); // viscous -> fan
    assert!((past[3] - 56.25).abs() < 0.05 && (visc(0.0, T, 2.0) - fan(0.0, T)).abs() < 1e-12);
    assert!(e1 < 0.1 && 3.5 < e2 / e1 && e2 / e1 < 4.5 && res[1].abs() < res[0].abs() && res[0].abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
