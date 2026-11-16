// Dispersion on a canal: ripples behind a barge, group velocity from plane waves, KdV balance.
const G: f64 = 9.81; // gravity, m/s^2
const H: f64 = 1.5; // canal depth, m
const U: f64 = 1.8; // barge speed, m/s
const SIG: f64 = 0.072; // surface tension, N/m
const RHO: f64 = 1000.0; // water density, kg/m^3
const PI: f64 = std::f64::consts::PI;

fn omega(k: f64, sig: f64) -> f64 { ((G * k + sig * k.powi(3) / RHO) * (k * H).tanh()).sqrt() }
fn cg_formula(k: f64) -> f64 { 0.5 * omega(k, 0.0) / k * (1.0 + 2.0 * k * H / (2.0 * k * H).sinh()) }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
// Python-style e-notation: 2.50e-03
fn e2(x: f64, p: usize) -> String {
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}
fn res_water(k: f64, w: f64, d: f64) -> (f64, f64) {
    let phi = |x: f64, z: f64, t: f64| (k * (z + H)).cosh() * (k * x - w * t).cos();
    let (x, t) = (0.3, 0.2);
    let lap = (phi(x + d, -0.5, t) + phi(x - d, -0.5, t) + phi(x, -0.5 + d, t) + phi(x, -0.5 - d, t)
        - 4.0 * phi(x, -0.5, t)) / (d * d);
    let surf = (phi(x, 0.0, t + d) - 2.0 * phi(x, 0.0, t) + phi(x, 0.0, t - d)) / (d * d)
        + G * (phi(x, d, t) - phi(x, -d, t)) / (2.0 * d);
    (lap.abs() / (k * k * phi(x, -0.5, t).abs()), surf.abs() / (w * w * phi(x, 0.0, t).abs()))
}
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    // 1. the wake wave: crests keep pace with the barge
    let k = bisect(&|q| omega(q, 0.0) / q - U, 0.5, 20.0);
    let w = omega(k, 0.0);
    println!("wake wave: k = {:.4} rad/m, wavelength = {:.4} m, omega = {:.4} rad/s, period = {:.4} s", k, 2.0 * PI / k, w, 2.0 * PI / w);
    println!("deep-water guess g/U^2 = {:.4} rad/m, kh = {:.3}, tanh(kh) = {:.5}, 1 + 2kh/sinh(2kh) = {:.5}",
        G / (U * U), k * H, (k * H).tanh(), 1.0 + 2.0 * k * H / (2.0 * k * H).sinh());
    // 2. read the relation off the plane wave
    for d in [1e-2, 5e-3] {
        let r = res_water(k, w, d);
        let ds = if d == 1e-2 { "1e-02" } else { "5e-03" };
        println!("plane wave in the canal, step {}: Laplace {}, surface {} (relative)", ds, e2(r.0, 2), e2(r.1, 2));
        assert!(r.0.max(r.1) < 1e-3);
    }
    let k20 = 2.0 * PI / 20.0;
    let r_wrong = res_water(k20, (G * k20).sqrt(), 5e-3).1;
    println!("20 m wave with the deep-water omega: surface residual {:.4}", r_wrong);
    assert!((r_wrong - (1.0 - (k20 * H).tanh())).abs() < 1e-3); // the miss is 1 - tanh(kh) of the term's size
    // 3. group velocity, four roads
    let dk = 1e-4;
    let cg_fd = (omega(k + dk, 0.0) - omega(k - dk, 0.0)) / (2.0 * dk);
    let cg = cg_formula(k);
    println!("phase velocity omega/k = {:.4} m/s; group velocity formula = {:.4} m/s, centred difference = {:.4} m/s", w / k, cg, cg_fd);
    assert!((cg - cg_fd).abs() < 1e-6);
    assert!((w / k - U).abs() < 1e-9);
    for frac in [0.5, 0.10, 0.05, 0.01] {
        let (k1, k2) = (k * (1.0 - frac / 2.0), k * (1.0 + frac / 2.0));
        println!("two waves {:4.0}% apart in k: beat speed d omega/d k = {:.4} m/s", frac * 100.0, (omega(k2, 0.0) - omega(k1, 0.0)) / (k2 - k1));
    }
    let dkk = 0.05 * k;
    let env = |x: f64, t: f64| {
        let (mut re, mut im) = (0.0, 0.0);
        for (amp, q) in [(0.5, k - dkk), (1.0, k), (0.5, k + dkk)] {
            let ph = (q - k) * x - (omega(q, 0.0) - w) * t;
            re += amp * ph.cos();
            im += amp * ph.sin();
        }
        re.hypot(im)
    };
    let tt = 20.0;
    let (mut xp, mut best) = (0.0, -1.0);
    for i in -5000..30000 {
        let x = i as f64 * 0.001;
        let e = env(x, tt);
        if e > best { best = e; xp = x; }
    }
    println!("three-wave group: peak at {:.3} m after {:.0} s, speed {:.4} m/s, height {:.4} (2 at the start)", xp, tt, xp / tt, env(xp, tt));
    assert!((xp / tt - cg).abs() < 2e-3);
    println!("in {:.0} s the crests move {:.1} m, the group {:.2} m; {:.2} crests pass through it", tt, U * tt, cg * tt, (U - cg) * tt / (2.0 * PI / k));
    let xs: Vec<f64> = (0..21).map(|i| -10.0 + 2.0 * i as f64).collect();
    println!("envelope t=0 s: {}", join(&xs.iter().map(|&x| env(x, 0.0)).collect::<Vec<_>>(), 2));
    println!("envelope t=20 s: {}", join(&xs.iter().map(|&x| env(x, tt)).collect::<Vec<_>>(), 2));
    println!("energy made 10 s ago sits {:.2} m behind the barge; Kelvin wedge half-angle {:.2} deg", (U - cg) * 10.0, (1.0f64 / 3.0).asin().to_degrees());
    // 4. the dispersion relation across wavelengths
    let lams = [0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0, 30.0, 50.0];
    println!("wavelength m: {}", lams.iter().map(|l| format!("{}", l)).collect::<Vec<_>>().join(", "));
    println!("phase m/s: {}", join(&lams.iter().map(|l| omega(2.0 * PI / l, 0.0) / (2.0 * PI / l)).collect::<Vec<_>>(), 3));
    println!("group m/s: {}", join(&lams.iter().map(|l| cg_formula(2.0 * PI / l)).collect::<Vec<_>>(), 3));
    let c0 = (G * H).sqrt();
    println!("long-wave limit sqrt(g h) = {:.4} m/s", c0);
    // 5. long waves: the linear KdV relation
    let beta = c0 * H * H / 6.0;
    let wk = c0 * k20 - beta * k20.powi(3);
    println!("20 m wave: exact {:.4} m/s, KdV {:.4} m/s, deep-water formula {:.4} m/s", omega(k20, 0.0) / k20, wk / k20, (G / k20).sqrt());
    assert!((wk / k20 - omega(k20, 0.0) / k20).abs() < 0.02);
    let lin = |x: f64, t: f64| (k20 * x - wk * t).cos();
    let d = 1e-2;
    let rl = (lin(1.0, d) - lin(1.0, -d)) / (2.0 * d) + c0 * (lin(1.0 + d, 0.0) - lin(1.0 - d, 0.0)) / (2.0 * d)
        + beta * (lin(1.0 + 2.0 * d, 0.0) - 2.0 * lin(1.0 + d, 0.0) + 2.0 * lin(1.0 - d, 0.0) - lin(1.0 - 2.0 * d, 0.0)) / (2.0 * d.powi(3));
    println!("plane wave in linear KdV: residual {}", e2(rl.abs(), 2));
    assert!(rl.abs() < 1e-4);
    // 6. KdV solitary wave a sech^2((x - Vt)/l)
    let a = 0.3;
    let (v, ell) = (c0 * (1.0 + a / (2.0 * H)), (4.0 * H.powi(3) / (3.0 * a)).sqrt());
    println!("solitary wave a = {} m: speed {:.4} m/s (linear {:.4}), width scale {:.4} m", a, v, c0, ell);
    let eta = |x: f64, t: f64, s: f64| a / ((x - s * t) / ell).cosh().powi(2);
    let kdv_terms = |x: f64, d: f64, s: f64| {
        let et = (eta(x, d, s) - eta(x, -d, s)) / (2.0 * d);
        let ex = (eta(x + d, 0.0, s) - eta(x - d, 0.0, s)) / (2.0 * d);
        let exxx = (eta(x + 2.0 * d, 0.0, s) - 2.0 * eta(x + d, 0.0, s) + 2.0 * eta(x - d, 0.0, s) - eta(x - 2.0 * d, 0.0, s)) / (2.0 * d.powi(3));
        let (nl, disp) = (1.5 * c0 / H * eta(x, 0.0, s) * ex, beta * exxx);
        (et + c0 * ex + nl + disp, nl, disp)
    };
    let (mut res, mut nl) = ([0.0; 2], 0.0);
    for (j, d) in [0.1, 0.05].iter().enumerate() {
        let rs: Vec<(f64, f64, f64)> = (0..81).map(|i| kdv_terms(-10.0 + 0.25 * i as f64, *d, v)).collect();
        res[j] = rs.iter().map(|r| r.0.abs()).fold(0.0, f64::max);
        nl = rs.iter().map(|r| r.1.abs()).fold(0.0, f64::max);
        println!("KdV residual, step {} m: max {} m/s (steepening term up to {:.4}, spreading term up to {:.4})", d, e2(res[j], 2),
            nl, rs.iter().map(|r| r.2.abs()).fold(0.0, f64::max));
    }
    assert!(res[1] < 0.1 * nl);
    assert!(res[1] < 0.3 * res[0]);
    let r_lin = (0..81).map(|i| kdv_terms(-10.0 + 0.25 * i as f64, 0.05, c0).0.abs()).fold(0.0, f64::max);
    println!("same hump at the linear speed {:.4} m/s: residual {:.4} m/s", c0, r_lin);
    assert!(r_lin > 3.0 * res[1]);
    // 7. drop the spreading term: the hump breaks
    let tb = 2.0 * H * ell / (3.0 * c0 * a * 4.0 / (3.0 * 3f64.sqrt()));
    let xs: Vec<f64> = (0..30001).map(|i| -15.0 + 0.001 * i as f64).collect();
    let sp: Vec<f64> = xs.iter().map(|&x| c0 * (1.0 + 1.5 * eta(x, 0.0, v) / H)).collect();
    let mut tb_brute = f64::INFINITY;
    for i in 0..30000 {
        if sp[i] > sp[i + 1] { tb_brute = tb_brute.min((xs[i + 1] - xs[i]) / (sp[i] - sp[i + 1])); }
    }
    println!("no spreading term: breaks at {:.4} s (formula), {:.4} s (crossing characteristics), after {:.2} m", tb, tb_brute, c0 * tb);
    assert!((tb - tb_brute).abs() < 1e-3);
    // 8. surface tension: the slowest ripple
    let (lmin_closed, cmin_closed) = (2.0 * PI * (SIG / (RHO * G)).sqrt(), (4.0 * G * SIG / RHO).powf(0.25));
    let gr = (5f64.sqrt() - 1.0) / 2.0;
    let cp = |l: f64| omega(2.0 * PI / l, SIG) / (2.0 * PI / l);
    let (mut lo, mut hi) = (0.005, 0.05);
    for _ in 0..100 {
        let (m1, m2) = (hi - gr * (hi - lo), lo + gr * (hi - lo));
        if cp(m1) < cp(m2) { hi = m2 } else { lo = m1 }
    }
    println!("slowest ripple: {:.3} cm at {:.4} m/s (search), {:.3} cm at {:.4} m/s (closed form)", 100.0 * lo, cp(lo), 100.0 * lmin_closed, cmin_closed);
    assert!((lo - lmin_closed).abs() < 1e-5);
    assert!((cp(lo) - cmin_closed).abs() < 1e-6);
    let kc = 2.0 * PI / 0.005;
    let cgc = (omega(kc + 1e-2, SIG) - omega(kc - 1e-2, SIG)) / 2e-2;
    println!("0.5 cm ripple: phase {:.4} m/s, group {:.4} m/s", omega(kc, SIG) / kc, cgc);
    println!("ALL CHECKS PASS");
}
