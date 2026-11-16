// Integral equations -- the check behind the card.  Rust std only, no crates.
// A 1 m strip of tarp roof hangs like a cable between two beams; rain ponds
// in its sag.  Roads to the sag: (1) closed form, (2) the Fredholm series,
// (3) Volterra marching from one end, plus the residual of -u'' = lam (h0 + u).
use std::f64::consts::PI;

const RHO: f64 = 1000.0; // kg/m^3
const GRAV: f64 = 9.81; // m/s^2
const TENS: f64 = 1962.0; // N/m
const H0: f64 = 0.01; // m

// polynomials in x: coefficient lists, lowest power first
fn padd(p: &[f64], q: &[f64]) -> Vec<f64> {
    let n = p.len().max(q.len());
    (0..n).map(|k| p.get(k).copied().unwrap_or(0.0) + q.get(k).copied().unwrap_or(0.0)).collect()
}
fn pscale(p: &[f64], c: f64) -> Vec<f64> { p.iter().map(|a| c * a).collect() }
fn pmulx(p: &[f64]) -> Vec<f64> { let mut v = vec![0.0]; v.extend_from_slice(p); v }
fn pint(p: &[f64]) -> Vec<f64> {
    let mut v = vec![0.0];
    v.extend(p.iter().enumerate().map(|(k, a)| a / (k as f64 + 1.0)));
    v
}
fn peval(p: &[f64], x: f64) -> f64 { p.iter().rev().fold(0.0, |s, a| s * x + a) }

// (G p)(x) = (1 - x) int_0^x y p(y) dy + x int_x^1 (1 - y) p(y) dy
fn green(p: &[f64]) -> Vec<f64> {
    let a = pint(&pmulx(p));
    let b = pint(&padd(p, &pscale(&pmulx(p), -1.0)));
    let left = padd(&a, &pscale(&pmulx(&a), -1.0));
    let right = padd(&[0.0, peval(&b, 1.0)], &pscale(&pmulx(&b), -1.0));
    padd(&left, &right)
}

fn exact(x: f64, lam: f64) -> f64 { // closed form: -u'' = lam (H0 + u), u(0) = u(1) = 0
    let r = lam.sqrt();
    H0 * ((r * (x - 0.5)).cos() / (r / 2.0).cos() - 1.0)
}

fn neumann(lam: f64, n: usize) -> (Vec<f64>, Vec<f64>) { // Fredholm series, n terms
    let mut term = pscale(&green(&[1.0]), lam * H0);
    let (mut u, mut mids) = (term.clone(), vec![peval(&term, 0.5)]);
    for _ in 0..n - 1 {
        term = pscale(&green(&term), lam);
        u = padd(&u, &term);
        mids.push(peval(&term, 0.5));
    }
    (u, mids)
}

// Picard on u = s0 x - lam int_0^x (x - y)(h + u(y)) dy
fn volterra(s0: f64, h: f64, lam: f64, passes: usize) -> (Vec<f64>, Vec<f64>) {
    let (mut u, mut gaps) = (vec![0.0, s0], vec![]);
    for _ in 0..passes {
        let new = padd(&[0.0, s0], &pscale(&pint(&pint(&padd(&[h], &u))), -lam));
        gaps.push((peval(&new, 1.0) - peval(&u, 1.0)).abs());
        u = new;
    }
    (u, gaps)
}

fn shoot(lam: f64, passes: usize) -> (Vec<f64>, f64) { // start slope that lands the far end on 0
    let a = volterra(1.0, 0.0, lam, passes).0;
    let b = volterra(0.0, H0, lam, passes).0;
    let s0 = -peval(&b, 1.0) / peval(&a, 1.0);
    (padd(&pscale(&a, s0), &b), s0)
}

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, panels: usize) -> f64 {
    let w = (hi - lo) / panels as f64;
    let mut s = f(lo) + f(hi);
    for k in 1..panels { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(lo + k as f64 * w); }
    s * w / 3.0
}
fn g_sin(n: f64, x: f64) -> f64 { // Simpson's rule for int_0^1 G(x, y) sin(n pi y) dy
    simpson(&|y: f64| y * (1.0 - x) * (n * PI * y).sin(), 0.0, x, 2000)
        + simpson(&|y: f64| x * (1.0 - y) * (n * PI * y).sin(), x, 1.0, 2000)
}
fn fact(n: usize) -> f64 { (1..=n).fold(1.0, |p, k| p * k as f64) }
fn mm(v: f64) -> f64 { 1000.0 * v }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let lam = RHO * GRAV / TENS;
    let r = lam.sqrt();
    println!("lambda = rho g / T = {:.4} 1/m^2; sqrt(lambda)/2 = {:.6}; cos of it = {:.6}", lam, r / 2.0, (r / 2.0).cos());
    println!("pi^2 = {:.4} 1/m^2; critical tension rho g / pi^2 = {:.2} N/m", PI.powi(2), RHO * GRAV / PI.powi(2));
    let (rain, ex) = (lam * H0 * 0.5 * 0.5 / 2.0, exact(0.5, lam));
    println!("rain alone, no ponding (Green's formula): midpoint sag {:.4} mm", mm(rain));
    println!("road 1, closed form: midpoint sag {:.4} mm, {:.4} times the rain-alone sag", mm(ex), ex / rain);

    let (u_n, mids) = neumann(lam, 30);
    let first: Vec<f64> = mids[..5].iter().map(|&t| mm(t)).collect();
    println!("road 2, Fredholm series, midpoint terms: {} mm", join(&first, 4));
    for n in [1, 2, 4, 8, 16, 30] {
        println!("  sum of {:2} terms: {:.6} mm", n, mm(mids[..n].iter().sum()));
    }
    let rate8 = lam / 8.0;
    let (true_tail, bound_tail): (f64, f64) = (mids[16..].iter().sum(), mids[15] * rate8 / (1.0 - rate8));
    println!("  tail after 16 terms: true {:.4} um, bound with lambda/8 = {:.3}: {:.4} um", mm(true_tail) * 1e3, rate8, mm(bound_tail) * 1e3);
    let ratio = mids[29] / mids[28];
    println!("  term ratio {:.6}; lambda/pi^2 = {:.6}", ratio, lam / PI.powi(2));

    let (u_v, s0) = shoot(lam, 14);
    let slope_cf = H0 * r * (r / 2.0).tan();
    println!("road 3, Volterra shooting: start slope {:.6}; closed form {:.6}; Fredholm {:.6}", s0, slope_cf, u_n[1]);
    println!("  midpoint sag {:.6} mm", mm(peval(&u_v, 0.5)));
    let gaps = volterra(s0, H0, lam, 9).1;
    let m0 = lam * (H0 / 2.0 + s0 / 6.0); // largest first gap on [0, 1]
    let bound = |n: usize| 2.0 * m0 * lam.powf(n as f64) / fact(2 * n + 2);
    for n in [2, 4, 6] {
        println!("  Picard pass {}: gap at far end {:.4} um, factorial bound {:.4} um", n, mm(gaps[n]) * 1e3, mm(bound(n)) * 1e3);
    }

    let mut res = vec![];
    for h in [0.01, 0.005] {
        let x = 0.3;
        let d2 = (peval(&u_n, x + h) - 2.0 * peval(&u_n, x) + peval(&u_n, x - h)) / (h * h);
        res.push(-d2 - lam * (H0 + peval(&u_n, x)));
        println!("residual of -u'' - lambda (h0 + u) at x = 0.3 m, step {} m: {:.4}e-6 1/m", h, res[res.len() - 1] * 1e6);
    }

    println!("what breaks:");
    let far = peval(&volterra(lam * H0 / 2.0, H0, lam, 14).0, 1.0);
    println!("  Volterra started at the rain-alone slope {:.4}: far end at {:.4} mm, not 0", lam * H0 / 2.0, mm(far));
    let lam_hi = 12.0;
    let (_, mids_hi) = neumann(lam_hi, 30);
    println!("  tension {:.1} N/m (lambda 12): Fredholm terms {:.4} mm, then {:.1} mm at term 30", RHO * GRAV / lam_hi, mm(mids_hi[0]), mm(mids_hi[29]));
    let (u_hi, _) = shoot(lam_hi, 20);
    println!("  same tension, Volterra shooting: midpoint {:.4} mm; closed form {:.4} mm", mm(peval(&u_hi, 0.5)), mm(exact(0.5, lam_hi)));
    let shrink: Vec<f64> = [1.0, 49.0].iter().map(|&n| g_sin(n, 0.5) / (n * PI / 2.0).sin()).collect();
    println!("  G shrinks mode 1 by {:.6} (1/pi^2 = {:.6}), mode 49 by {:.4}e-5 (1/(49 pi)^2 = {:.4}e-5)",
        shrink[0], 1.0 / PI.powi(2), shrink[1] * 1e5, 1e5 / (49.0 * PI).powi(2));
    let fake = TENS * 1e-6 / shrink[1];
    println!("  first kind: 1 um of sag noise in mode 49 reads as {:.2} Pa of load; the rain is {:.2} Pa", fake, RHO * GRAV * H0);

    let xs: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    let rain_pts: Vec<f64> = xs.iter().map(|&x| mm(lam * H0 * x * (1.0 - x) / 2.0)).collect();
    let pond_pts: Vec<f64> = xs.iter().map(|&x| mm(exact(x, lam))).collect();
    println!("chart rain alone (mm): {}", join(&rain_pts, 2));
    println!("chart ponded (mm):     {}", join(&pond_pts, 2));
    let worst = xs.iter().map(|&x| (peval(&u_n, x) - exact(x, lam)).abs().max((peval(&u_v, x) - exact(x, lam)).abs())).fold(0.0, f64::max);

    assert!((peval(&u_n, 0.5) - ex).abs() < 1e-9); // Fredholm series meets the closed form
    assert!((peval(&u_v, 0.5) - ex).abs() < 1e-9); // Volterra shooting meets the closed form
    assert!(worst < 1e-9); // ... at every chart point
    assert!((s0 - slope_cf).abs() < 1e-9 && (u_n[1] - slope_cf).abs() < 1e-9);
    assert!((ratio - lam / PI.powi(2)).abs() < 1e-6); // series shrinks at lambda/pi^2 per term
    assert!(true_tail <= bound_tail); // the lambda/8 tail bound holds
    assert!((0..9).all(|n| gaps[n] <= bound(n)));
    assert!(res[0].abs() < 1e-4 && res[0] / res[1] > 3.5 && res[0] / res[1] < 4.5); // residual falls like step^2
    assert!((shrink[0] - 1.0 / PI.powi(2)).abs() < 1e-9 && (shrink[1] * (49.0 * PI).powi(2) - 1.0).abs() < 1e-6);
    assert!(mids_hi[29] > 100.0 * mids_hi[0]); // lambda > pi^2: the series blows up
    assert!((peval(&u_hi, 0.5) - exact(0.5, lam_hi)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
