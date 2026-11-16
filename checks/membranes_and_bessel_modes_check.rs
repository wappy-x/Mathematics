// Drumheads: the modes of a round membrane are Bessel patterns.  std only, no crates.
// A drum 30 cm across (R = 0.15 m), clamped at the rim, waves at c = 100 m/s
// (tension 2000 N/m over 0.2 kg/m^2, illustrative).  Bessel functions and their zeros are
// built here three ways: power series, Bessel's integral, Runge-Kutta 4 from the centre.
use std::f64::consts::PI;

const R: f64 = 0.15; const C: f64 = 100.0;

fn sci(x: f64) -> String { // same e-notation digits in Python and Rust
    if x == 0.0 { return "0.0e+00".to_string(); }
    let mut e = x.abs().log10().floor() as i32;
    let mut m = (x / 10f64.powi(e) * 10.0).round() / 10.0;
    if m.abs() >= 10.0 { m /= 10.0; e += 1; }
    format!("{:.1}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}

fn factorial(n: u32) -> f64 { (1..=n).fold(1.0, |a, k| a * k as f64) }

fn j_series(m: u32, x: f64) -> f64 { // sum (-1)^p (x/2)^(2p+m) / (p! (p+m)!), 40 terms
    let mut t = (x / 2.0).powi(m as i32) / factorial(m);
    let mut s = 0.0;
    for p in 0..40 { s += t; t *= -(x / 2.0).powi(2) / (((p + 1) * (p + 1 + m)) as f64); }
    s
}

fn j_integral(m: u32, x: f64) -> f64 { // (1/pi) int_0^pi cos(m tau - x sin tau), trapezoid, 64 points
    let (n, mf) = (64, m as f64);
    let mut s = 0.5 * (1.0 + (mf * PI).cos());
    for i in 1..n {
        let tau = i as f64 * PI / n as f64;
        s += (mf * tau - x * tau.sin()).cos();
    }
    s / n as f64
}

fn zeros(f: fn(u32, f64) -> f64, m: u32, count: usize) -> Vec<f64> { // scan, then bisect
    let (step, mut a, mut out) = (0.05, 0.05, Vec::new());
    while out.len() < count {
        if f(m, a) * f(m, a + step) < 0.0 {
            let (mut lo, mut hi) = (a, a + step);
            for _ in 0..60 {
                let mid = (lo + hi) / 2.0;
                if f(m, lo) * f(m, mid) > 0.0 { lo = mid } else { hi = mid }
            }
            out.push((lo + hi) / 2.0);
        }
        a += step;
    }
    out
}

fn zeros_rk4(m: u32, count: usize, h: f64) -> Vec<f64> { // y = x^m v: v'' + (2m+1) v'/x + v = 0
    let mf = m as f64;
    let acc = |x: f64, v: f64, w: f64| if x == 0.0 { -v / (2.0 * mf + 2.0) } else { -v - (2.0 * mf + 1.0) * w / x };
    let step = |x: f64, v: f64, w: f64, d: f64| {
        let k1 = (w, acc(x, v, w));
        let k2 = (w + d / 2.0 * k1.1, acc(x + d / 2.0, v + d / 2.0 * k1.0, w + d / 2.0 * k1.1));
        let k3 = (w + d / 2.0 * k2.1, acc(x + d / 2.0, v + d / 2.0 * k2.0, w + d / 2.0 * k2.1));
        let k4 = (w + d * k3.1, acc(x + d, v + d * k3.0, w + d * k3.1));
        (v + d / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0), w + d / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1))
    };
    let (mut x, mut v, mut w, mut out) = (0.0, 1.0, 0.0, Vec::new());
    while out.len() < count {
        let (v2, w2) = step(x, v, w, h);
        if v * v2 < 0.0 { // bisect the length of one RK4 step from x
            let (mut lo, mut hi) = (0.0, h);
            for _ in 0..60 {
                let mid = (lo + hi) / 2.0;
                if step(x, v, w, mid).0 * v > 0.0 { lo = mid } else { hi = mid }
            }
            out.push(x + (lo + hi) / 2.0);
        }
        x += h; v = v2; w = w2;
    }
    out
}

fn simpson(g: &dyn Fn(f64) -> f64) -> f64 {
    let (n, mut s) = (2000, 0.0);
    for i in 0..=n {
        let wgt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += wgt * g(i as f64 / n as f64);
    }
    s / (3.0 * n as f64)
}

fn rel(m: u32, j: f64, r: f64) -> f64 { // height at r over the shape's highest point
    let peak = (0..=1000).map(|i| j_series(m, j * i as f64 / 1000.0).abs()).fold(0.0, f64::max);
    (j_series(m, j * r / R) / peak * 1e6).round() / 1e6 + 0.0
}

fn main() {
    let z: Vec<Vec<f64>> = (0..6).map(|m| zeros(j_series, m, 3)).collect();
    let hz = |j: f64| C * j / (2.0 * PI * R);
    println!("drum: R = {} m (30 cm across), c = {:.0} m/s; f = c j/(2 pi R) = {:.3} Hz per unit of j", R, C, C / (2.0 * PI * R));
    println!("series, 40 terms: first omitted term of J0 at x = 16, the largest x used, is {}", sci(8f64.powi(80) / factorial(40).powi(2)));
    let mut worst_int: f64 = 0.0;
    for m in 0..6 { for (a, b) in z[m].iter().zip(zeros(j_integral, m as u32, 3)) { worst_int = worst_int.max((a - b).abs()); } }
    println!("zeros by Bessel's integral (64 points) against the series: worst gap below 1e-10: {}", if worst_int < 1e-10 { "yes" } else { "no" });
    let mut errs = Vec::new();
    for h in [0.1, 0.05] {
        let mut e: f64 = 0.0;
        for m in 0..4 { for (a, b) in z[m].iter().zip(zeros_rk4(m as u32, 3, h)) { e = e.max((a - b).abs()); } }
        errs.push(e);
        println!("zeros by RK4 from the centre, h = {}: worst gap {}", h, sci(e));
    }
    println!("RK4 gap ratio when h halves: {:.1}", errs[0] / errs[1]);
    assert!(worst_int < 1e-10 && errs[1] < 1e-6 && 10.0 < errs[0] / errs[1] && errs[0] / errs[1] < 22.0);
    let mut modes: Vec<(f64, usize, usize)> = Vec::new();
    for m in 0..6 { for n in 1..=3 { modes.push((z[m][n - 1], m, n)); } }
    modes.sort_by(|a, b| a.partial_cmp(b).unwrap());
    modes.truncate(10);
    println!("mode (m,n)   j_mn      k (1/m)   f (Hz)   f/f1   diameters circles  shapes");
    for &(j, m, n) in &modes {
        println!("  ({},{})   {:8.4}  {:8.2}  {:7.1}  {:5.3}       {}         {}       {}",
                 m, n, j, j / R, hz(j), j / modes[0].0, m, n - 1, if m == 0 { 1 } else { 2 });
    }
    let order: Vec<(usize, usize)> = modes[..4].iter().map(|&(_, m, n)| (m, n)).collect();
    assert!(order == vec![(0, 1), (1, 1), (2, 1), (0, 2)]);
    assert!((z[0][0] - 2.404826).abs() < 1e-6 && (z[1][0] - 3.831706).abs() < 1e-6 && (z[2][0] - 5.135622).abs() < 1e-6);
    let f1 = hz(z[0][0]);
    println!("fundamental: omega = c k = {:.1} rad/s, f = {:.1} Hz, period {:.3} ms", C * z[0][0] / R, f1, 1000.0 / f1);
    let cyc: Vec<String> = modes[1..4].iter().map(|&(j, _, _)| format!("{:.3}", j / modes[0].0)).collect();
    println!("cycles done by the next modes in one period of the fundamental: {}", cyc.join(", "));
    println!("nodal circle of (0,2) at r = R j01/j02 = {:.2} cm; of (1,2) at {:.2} cm",
             R * z[0][0] / z[0][1] * 100.0, R * z[1][0] / z[1][1] * 100.0);
    let tim: Vec<String> = [1, 2, 3, 4].iter().map(|&m| format!("{:.3}", z[m][0] / z[1][0])).collect();
    println!("timpani family (m,1), m = 1..4, over (1,1): {}; a 2:3:4:5 ladder is 1.000, 1.500, 2.000, 2.500", tim.join(", "));
    // road 4: the full shape J_m(k r) cos(m theta) in the plain Cartesian Laplacian, by centred differences
    for m in [1u32, 2] {
        let k = z[m as usize][0] / R;
        let phi = |x: f64, y: f64| j_series(m, k * (x * x + y * y).sqrt()) * (m as f64 * y.atan2(x)).cos();
        let mut gaps = Vec::new();
        for h in [2e-3, 1e-3] {
            let (x0, y0) = (0.05, 0.03);
            let lap = (phi(x0 + h, y0) + phi(x0 - h, y0) + phi(x0, y0 + h) + phi(x0, y0 - h) - 4.0 * phi(x0, y0)) / h.powi(2);
            gaps.push((-lap / phi(x0, y0) - k * k).abs());
        }
        println!("({},1) in Cartesian -Laplacian / shape at (0.05, 0.03) m: k^2 = {:.2} 1/m^2; gap {} at h = 2 mm, {} at 1 mm, ratio {:.1}",
                 m, k * k, sci(gaps[0]), sci(gaps[1]), gaps[0] / gaps[1]);
        assert!(gaps[1] < 1e-2 * k * k && 3.0 < gaps[0] / gaps[1] && gaps[0] / gaps[1] < 5.0);
    }
    let cross = simpson(&|s: f64| j_series(0, z[0][0] * s) * j_series(0, z[0][1] * s) * s);
    let norm = simpson(&|s: f64| j_series(0, z[0][0] * s).powi(2) * s);
    let half = j_series(1, z[0][0]).powi(2) / 2.0;
    println!("orthogonality: int_0^1 J0(j01 s) J0(j02 s) s ds below 1e-12: {}; int J0(j01 s)^2 s ds = {:.6}, J1(j01)^2 / 2 = {:.6}", if cross.abs() < 1e-12 { "yes" } else { "no" }, norm, half);
    assert!(cross.abs() < 1e-12 && (norm - half).abs() < 1e-9);
    for r in [0.0, 0.10] {
        let hs: Vec<String> = (0..3).map(|m| format!("{:.3}", rel(m, z[m as usize][0], r))).collect();
        println!("strike at r = {:.0} cm: heights of (0,1), (1,1), (2,1) over their peaks: {}", r * 100.0, hs.join(", "));
    }
    let rs: Vec<String> = (0..11).map(|i| format!("{:5.1}", i as f64 * 1.5)).collect();
    println!("figure, r (cm):  {}", rs.join(" "));
    for m in 0..3u32 {
        let v: Vec<String> = (0..11).map(|i| format!("{:5.2}", rel(m, z[m as usize][0], i as f64 * 0.015))).collect();
        println!("figure, ({},1) / peak: {}", m, v.join(" "));
    }
    let pk: Vec<String> = [1u32, 2].iter().map(|&m| format!("{:.2}", 100.0 * R * zeros(|m, x| j_series(m - 1, x) - m as f64 / x * j_series(m, x), m, 1)[0] / z[m as usize][0])).collect();
    println!("highest points of (1,1) and (2,1), where J_m' = J_(m-1) - m J_m / x = 0: r = {} cm", pk.join(", "));
    println!("figure, 400 px per m: discs of radius 60 px at x 80, 220, 360, 500, y 90; (0,2) nodal circle radius {:.1} px; (2,1) nodal diameters end {:.2} px across and up from centre",
             60.0 * z[0][0] / z[0][1], 60.0 / 2f64.sqrt());
    println!("mistakes:");
    println!("  whole-number ladder: second note {:.1} Hz, not {:.1} Hz", 2.0 * f1, hz(z[1][0]));
    println!("  round modes only: second note {:.1} Hz; misses {:.1} and {:.1} Hz", hz(z[0][1]), hz(z[1][0]), hz(z[2][0]));
    println!("  30 cm taken as the radius: fundamental {:.1} Hz, not {:.1} Hz", C * z[0][0] / (2.0 * PI * 0.30), f1);
    println!("  m = 1.5 round the circle: cos(1.5 theta) is {:.0} at theta = 0 and {:.0} after a full turn, a jump of {:.0}",
             0f64.cos(), (1.5 * 2.0 * PI).cos(), 0f64.cos() - (3.0 * PI).cos());
    println!("ALL CHECKS PASS");
}
