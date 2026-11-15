// Hamilton-Jacobi equations -- the same check as the Python, in Rust.  Standard library only, no crates.
// A 40 t truck crosses a 100 km route over rolling hills; u(x, t) = least fuel (L) to be at km x at time t (h).
// Roads: the closed form, characteristics (Hamilton's equations) by RK4, a dynamic-programming grid,
// the Hopf-Lax minimum by search, and the residual u_t + H(u_x, x) by centred differences.
use std::f64::consts::PI;
const K: f64 = 2.5e-5; const R: f64 = 0.14; const W: f64 = 0.027; const D: f64 = 100.0; const T: f64 = 1.25;
const AMP: f64 = 30.0; const LAM: f64 = 50.0;          // hills: 30 m up and down every 50 km, plus 0.4 m/km
fn h(x: f64) -> f64 { 200.0 + 0.4 * x + AMP * (2.0 * PI * x / LAM).sin() }        // elevation, m
fn dh(x: f64) -> f64 { 0.4 + AMP * 2.0 * PI / LAM * (2.0 * PI * x / LAM).cos() } // grade, m per km
fn d2h(x: f64) -> f64 { -AMP * (2.0 * PI / LAM).powi(2) * (2.0 * PI * x / LAM).sin() }
fn b(x: f64) -> f64 { R + W * dh(x) }                  // fuel per km that does not depend on speed, L/km
fn bb(x: f64) -> f64 { R * x + W * (h(x) - h(0.0)) }   // its total from km 0 to km x, L
fn c() -> f64 { 2.0 / (3.0 * (3.0 * K).sqrt()) }
fn l0(v: f64) -> f64 { K * v.abs().powi(3) }          // drag fuel per hour at speed v, L/h
fn h0(q: f64) -> f64 { c() * q.abs().powf(1.5) }      // its slope transform
fn dh0(q: f64) -> f64 { (if q >= 0.0 { 1.0 } else { -1.0 }) * (q.abs() / (3.0 * K)).sqrt() } // speed chosen at price q
fn ham(x: f64, p: f64) -> f64 { h0(p - b(x)) }        // the Hamiltonian with hills
fn exact(x: f64, t: f64) -> f64 { K * x.powi(3) / (t * t) + bb(x) } // road 1: straight line, hills added
fn tern(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // minimiser of a one-dip function
    for _ in 0..200 {
        let a = lo + (hi - lo) / 3.0; let cc = hi - (hi - lo) / 3.0;
        if f(a) < f(cc) { hi = cc; } else { lo = a; }
    }
    lo
}
fn rate(s: [f64; 3]) -> [f64; 3] {                    // x' = H_p, p' = -H_x, u' = p H_p - H
    let v = dh0(s[1] - b(s[0])); [v, v * W * d2h(s[0]), s[1] * v - ham(s[0], s[1])]
}
fn chars(p0: f64, n: usize) -> ([f64; 3], f64, f64) { // road 2: RK4 along the characteristic
    let (mut s, dt) = ([0.0, p0, 0.0], T / n as f64); let (mut vmin, mut vmax) = (f64::MAX, f64::MIN);
    let add = |s: [f64; 3], k: [f64; 3], m: f64| [s[0] + m * k[0], s[1] + m * k[1], s[2] + m * k[2]];
    for _ in 0..n {
        let k1 = rate(s); let k2 = rate(add(s, k1, dt / 2.0)); let k3 = rate(add(s, k2, dt / 2.0)); let k4 = rate(add(s, k3, dt));
        for i in 0..3 { s[i] += dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        let v = dh0(s[1] - b(s[0])); vmin = vmin.min(v); vmax = vmax.max(v);
    }
    (s, vmin, vmax)
}
fn dp(n: usize) -> f64 {                              // road 3: best path through a 1 km x (T/n) h grid
    let (dt, big, m) = (T / n as f64, 1e18, 100usize); let mut u = vec![big; m + 1]; u[0] = 0.0;
    for _ in 0..n {
        u = (0..=m).map(|x| (0..=m).filter(|&y| u[y] < big)
            .map(|y| u[y] + K * (x as f64 - y as f64).abs().powi(3) / (dt * dt) + bb(x as f64) - bb(y as f64))
            .fold(f64::MAX, f64::min)).collect();
    }
    u[m]
}
fn two(x: f64, t: f64) -> f64 { (K * x.powi(3) / (t * t)).min(K * (D - x).powi(3) / (t * t)) } // depots at 0 and 100
fn row(label: &str, v: Vec<String>) { println!("{}{}", label, v.join(" ")); }
fn main() {
    let (mut lo, mut hi) = (b(0.0), b(0.0) + 2.0);    // shoot: the starting price that lands on km 100
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if chars(mid, 500).0[0] < D { lo = mid; } else { hi = mid; } }
    let (s, vmin, vmax) = chars(lo, 500); let (xc, pc, uc) = (s[0], s[1], s[2]);
    let (u_dp, u_dp7, ex) = (dp(25), dp(7), exact(D, T));
    let v_leg = tern(&|v| -(0.48 * v - l0(v)), 0.0, 300.0);
    let y_star = tern(&|y| K * y.powi(3) / 0.25 + 0.75 * l0((D - y) / 0.75), 0.0, D);
    let hl = K * y_star.powi(3) / 0.25 + 0.75 * l0((D - y_star) / 0.75);
    let res: Vec<f64> = [0.002, 0.001].iter().map(|&e| {
        let ut = (exact(D, T + e) - exact(D, T - e)) / (2.0 * e); let ux = (exact(D + e, T) - exact(D - e, T)) / (2.0 * e);
        (ut + ham(D, ux)).abs() }).collect();
    let bs: Vec<f64> = (0..1001).map(|x| b(x as f64 / 10.0)).collect();
    println!("route: {:.0} km in {:.2} h, so {:.0} km/h; drag {:.2} L/km, rolling {:.2} L/km", D, T, D / T, K * (D / T).powi(2), R);
    println!("inputs: k = {:.6} L h^2/km^3, climb {:.3} L/m, hills h = 200 + 0.4 x + {:.0} sin(2 pi x / {:.0}) m", K, W, AMP, LAM);
    println!("by hand: 3 k v^2 = {:.2} L/km, k v^3 = {:.2} L/h, 0.48 x 80 = {:.2}; grade wave {:.4} m/km, b(0) = {:.5} L/km", 3.0 * K * (D / T).powi(2), K * (D / T).powi(3), 0.48 * D / T, AMP * 2.0 * PI / LAM, b(0.0));
    println!("climb: net {:.0} m, costing {:.2} L; grade from {:.2} to {:.2} m/km", h(D) - h(0.0), W * (h(D) - h(0.0)), dh(LAM / 2.0), dh(0.0));
    println!("speed-free fuel per km b(x): {:.4} to {:.4} L/km", bs.iter().cloned().fold(f64::MAX, f64::min), bs.iter().cloned().fold(f64::MIN, f64::max));
    println!("closed form: drag {:.2} + rolling {:.2} + climb {:.2} = {:.2} L", K * D.powi(3) / (T * T), R * D, W * (h(D) - h(0.0)), ex);
    println!("fixed fuel B(100) = {:.2} L; average {:.2} L/km; 1.0 h deadline costs {:.2} L more; at 1.5 h drag {:.2} L", bb(D), ex / D, exact(D, 1.0) - ex, K * D.powi(3) / 2.25);
    println!("slopes at km 100: u_x = p = {:.5} L/km, u_t = {:.2} L/h", b(D) + 3.0 * K * (D / T).powi(2), -2.0 * K * D.powi(3) / T.powi(3));
    println!("price p on the 80 km/h path at km 0, 25, 50: {:.5} {:.5} {:.5} L/km", b(0.0) + 0.48, b(25.0) + 0.48, b(50.0) + 0.48);
    println!("Legendre: H0(0.48) = max of 0.48 v - L0(v) = {:.2} L/h at v = {:.2} km/h", 0.48 * v_leg - l0(v_leg), v_leg);
    println!("characteristics: start price {:.5} L/km, ends at km {:.4}, fuel {:.4} L, end price {:.5}", lo, xc, uc, pc);
    println!("characteristics: speed stays between {:.4} and {:.4} km/h; H along it {:.4} L/h", vmin, vmax, ham(xc, pc));
    println!("grid, 25 steps of {:.2} h: {:.4} L; 7 steps of {:.4} h: {:.4} L", T / 25.0, u_dp, T / 7.0, u_dp7);
    println!("Hopf-Lax replan at 0.5 h: best place {:.2} km, drag fuel {:.2} + {:.2} = {:.2} L", y_star, K * y_star.powi(3) / 0.25, 0.75 * l0((D - y_star) / 0.75), hl);
    println!("residual |u_t + H(u_x, x)| at step 0.002, 0.001 h or km: {:.3} {:.3} x 1e-6", 1e6 * res[0], 1e6 * res[1]);
    let up = (0..100000).filter(|&i| dh((i as f64 + 0.5) / 1000.0) > 0.0).count() as f64 / 1000.0; // km of climbing
    let t_up = up / 70.0; let v_dn = (D - up) / (T - t_up); let slow = K * (70.0f64.powi(2) * up + v_dn * v_dn * (D - up));
    println!("mistake 1, fuel per km taken as per hour: drag {:.2} L", T * K * (D / T).powi(2));
    println!("mistake 2, 70 km/h on the {:.2} km of climbs, {:.2} km/h elsewhere: drag {:.2} L, total {:.2} L", up, v_dn, slow, slow + bb(D));
    println!("mistake 3, two depots, km 70: west characteristics {:.3} L, Hopf-Lax minimum {:.3} L", K * 70.0f64.powi(3) / (T * T), two(70.0, T));
    println!("mistake 4, hill grade frozen at km 0: {:.2} L", K * D.powi(3) / (T * T) + b(0.0) * D);
    println!("kink at km 50: value {:.3} L, slope {:.3} then {:.3} L/km", two(50.0, T), 3.0 * K * 2500.0 / (T * T), -3.0 * K * 2500.0 / (T * T));
    let bmin60 = R + W * (0.4 - 60.0 * 2.0 * PI / LAM);
    let y75 = tern(&|y| K * y.powi(3) / 0.5625 + 0.5 * l0((D - y) / 0.5), 0.0, D);
    println!("try: deadline 1.5 h {:.2} L; replan at 0.75 h, best place {:.2} km; 60 m hills, lowest b {:.4} L/km", exact(D, 1.5), y75, bmin60);
    let a_coast = (0.4 + (R + K * (D / T).powi(2)) / W) / (2.0 * PI / LAM); // hill height at which 80 km/h first coasts
    println!("try: on 60 m hills 80 km/h still burns {:.4} L/km on the steepest descent; L < 0 only below {:.2} km/h; coasting from {:.1} m hills", K * (D / T).powi(2) + bmin60, (-bmin60 / K).sqrt(), a_coast);
    row("chart, deadline h  ", (0..9).map(|i| format!("{:6.3}", 1.0 + i as f64 / 8.0)).collect());
    row("chart, fuel L      ", (0..9).map(|i| format!("{:6.2}", exact(D, 1.0 + i as f64 / 8.0))).collect());
    row("chart, km          ", (0..11).map(|i| format!("{:6}", 10 * i)).collect());
    row("chart, two depots  ", (0..11).map(|i| format!("{:6.3}", two(10.0 * i as f64, T))).collect());
    row("chart, west only   ", (0..11).map(|i| format!("{:6.3}", K * (10.0 * i as f64).powi(3) / (T * T))).collect());
    assert!((uc - ex).abs() < 1e-6 && (xc - D).abs() < 1e-6);       // characteristics land on the closed form
    assert!((u_dp - ex).abs() < 1e-6 && u_dp7 - ex > 1e-6);         // grid minimum agrees; misaligned grid is above
    assert!((hl - K * D.powi(3) / (T * T)).abs() < 1e-6 && (y_star - 40.0).abs() < 1e-4); // Hopf-Lax replan
    assert!(res[1] < res[0] / 3.0 && res[1] < 1e-4);                // residual shrinks like step^2
    assert!((0.48 * v_leg - l0(v_leg) - h0(0.48)).abs() < 1e-9 && vmax - vmin < 1e-6);
    assert!(slow > K * D.powi(3) / (T * T) && two(70.0, T) < K * 70.0f64.powi(3) / (T * T));
    println!("ALL CHECKS PASS");
}
