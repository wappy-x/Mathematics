// Impulses and the delta function -- the same check as the Python, in Rust.
// No crates.  The car body hits a pothole at t = 1 s: y'' + 2y' + 5y =
// delta(t - 1), at rest before it.  Road one is the transform answer
// y = u(t - 1) 0.5 e^(-(t-1)) sin 2(t - 1).  Road two never uses a delta: it
// pushes with a pulse of area 1, strength 1/eps for eps seconds, stepped by RK4.
const A: f64 = 1.0; const S: f64 = 2.0; const H: f64 = 0.0005;

fn ideal(t: f64) -> f64 {                          // road one: the transform's answer
    if t < A { 0.0 } else { 0.5 * (-(t - A)).exp() * (2.0 * (t - A)).sin() }
}

fn pulse_run(eps: f64, area: f64) -> (Vec<f64>, Vec<f64>) { // road two: RK4, force held per step
    let (mut y, mut v, mut ys, mut vs) = (0.0_f64, 0.0_f64, Vec::new(), Vec::new());
    for n in 0..=(6.0 / H).round() as usize {
        ys.push(y); vs.push(v);
        let tm = (n as f64 + 0.5) * H;
        let f = if A <= tm && tm < A + eps { area / eps } else { 0.0 };
        let rate = |y: f64, v: f64| (v, f - 2.0 * v - 5.0 * y);
        let k1 = rate(y, v);
        let k2 = rate(y + H / 2.0 * k1.0, v + H / 2.0 * k1.1);
        let k3 = rate(y + H / 2.0 * k2.0, v + H / 2.0 * k2.1);
        let k4 = rate(y + H * k3.0, v + H * k3.1);
        y += H / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += H / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    (ys, vs)
}

fn main() {
    for eps in [0.5_f64, 0.1, 0.01] {                // the pulse's transform, two ways
        let d = eps / 1000.0;
        let mid: f64 = (0..1000).map(|k| (-S * (A + (k as f64 + 0.5) * d)).exp() / eps * d).sum();
        let exact = (-S * A).exp() * (1.0 - (-S * eps).exp()) / (S * eps);
        println!("pulse eps = {}: transform at s = 2 midpoint {:.6}, formula {:.6}", eps, mid, exact);
        assert!((mid - exact).abs() < 1e-8);
    }
    println!("limit e^(-as) at a = 1, s = 2: {:.6}", (-S * A).exp());
    let lap: f64 = (0..20000).map(|k| { let t = A + (k as f64 + 0.5) * 0.001; (-S * t).exp() * ideal(t) * 0.001 }).sum();
    println!("transform of y at s = 2: midpoint sum {:.8}, e^(-2)/13 = {:.8}", lap, (-2.0_f64).exp() / 13.0);
    assert!((lap - (-2.0_f64).exp() / 13.0).abs() < 1e-7);
    let mut errs: Vec<f64> = Vec::new();
    for eps in [0.2_f64, 0.1, 0.05] {
        let (ys, vs) = pulse_run(eps, 1.0);
        errs.push((0..ys.len()).map(|n| (ys[n] - ideal(n as f64 * H)).abs()).fold(0.0, f64::max));
        let v_after = vs[((A + eps) / H).round() as usize];
        println!("RK4 pulse eps = {}: worst height error {:.6} cm, velocity at pulse end {:.6} cm/s", eps, errs[errs.len() - 1], v_after);
        assert!(errs[errs.len() - 1] < eps && (v_after - 1.0).abs() < 1.5 * eps);
    }
    println!("error ratios as eps halves: {:.2}, {:.2} (order 1 in eps)", errs[0] / errs[1], errs[1] / errs[2]);
    assert!((0..2).all(|i| 1.7 < errs[i] / errs[i + 1] && errs[i] / errs[i + 1] < 2.3));
    let tp = A + 2.0_f64.atan() / 2.0;
    let grid_peak = (0..200000).map(|k| ideal(A + k as f64 * 1e-5)).fold(f64::MIN, f64::max);
    println!("ideal: velocity 0 before, {:.6} after; peak {:.6} cm at t = {:.6} (grid max {:.6})",
             0.5 * (2.0 * 0.0_f64.cos() - 0.0_f64.sin()), ideal(tp), tp, grid_peak);
    let wide = pulse_run(0.5, 1.0).0;
    let row = |g: &dyn Fn(usize) -> f64| (0..17).map(|k| format!("{:5.2}", g(k))).collect::<Vec<_>>().join(" ");
    println!("figure, t    {}", row(&|k| 0.25 * k as f64));
    println!("figure, ideal{} mm", row(&|k| 10.0 * ideal(0.25 * k as f64)));
    println!("figure, 0.5 s{} mm", row(&|k| 10.0 * wide[(0.25 * k as f64 / H).round() as usize]));
    let flat = pulse_run(0.01, 0.01).0.into_iter().fold(f64::MIN, f64::max);
    println!("mistake 1, strength 1 for 0.01 s: area 0.01, peak {:.6} cm instead of {:.6}", flat, ideal(tp));
    println!("mistake 2, delay dropped: y(1.5) = {:.6} cm instead of {:.6}", 0.5 * (-1.5_f64).exp() * 3.0_f64.sin(), ideal(1.5));
    println!("mistake 3, switch u(t - 1) dropped: y(0.5) = {:.6} cm instead of {:.6}", 0.5 * 0.5_f64.exp() * (-1.0_f64).sin(), ideal(0.5));
    println!("ALL CHECKS PASS");
}
