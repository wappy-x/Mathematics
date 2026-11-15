// Elliptic, parabolic, hyperbolic -- the same check as the Python, in Rust.  No crates.
// Road one finds each principal matrix's eigenvalues by Jacobi rotations.  Road two counts
// their signs from the characteristic polynomial by Descartes' rule, with no eigenvalues.
// Road three scans the principal symbol over unit directions.  The three behaviours are
// checked by a series against a relaxed grid and a formula against a stepped grid.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;

fn jacobi(a0: &M) -> Vec<f64> {            // road one: rotate the off-diagonal entries away
    let mut a = a0.clone(); let n = a.len();
    for _ in 0..30 {
        for p in 0..n {
            for q in p + 1..n {
                let t = 0.5 * (2.0 * a[p][q]).atan2(a[q][q] - a[p][p]); let (c, s) = (t.cos(), t.sin());
                for k in 0..n { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
                for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
            }
        }
    }
    let mut ev: Vec<f64> = (0..n).map(|i| a[i][i]).collect();
    ev.sort_by(|x, y| y.partial_cmp(x).unwrap());
    let big = ev.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    ev.iter().map(|&v| if v.abs() < 1e-12 * big { 0.0 } else { v }).collect()
}

fn charpoly(m: &M) -> Vec<f64> {           // det(lambda I - A), highest power first
    if m.len() == 2 { return vec![1.0, -(m[0][0] + m[1][1]), m[0][0] * m[1][1] - m[0][1] * m[1][0]]; }
    let (a, b, c, d, e, f, g, h, i) = (m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2]);
    let det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    vec![1.0, -(a + e + i), a * e - b * d + a * i - c * g + e * i - f * h, -det]
}

fn descartes(cp0: &[f64]) -> (usize, usize, usize) {   // road two: root signs read off the coefficients
    let mut cp = cp0.to_vec(); let mut zero = 0;
    while *cp.last().unwrap() == 0.0 { cp.pop(); zero += 1; }
    let m = cp.len() - 1;
    let flips = |c: &[f64]| c.windows(2).filter(|w| w[0] * w[1] < 0.0).count();
    let neg: Vec<f64> = cp.iter().enumerate().map(|(k, &x)| if (m - k) % 2 == 1 { -x } else { x }).collect();
    (flips(&cp), flips(&neg), zero)
}

fn symbol(a: &M, xi: &[f64]) -> f64 {
    let mut s = 0.0;
    for i in 0..a.len() { for j in 0..a.len() { s += a[i][j] * xi[i] * xi[j]; } }
    s
}

fn scan(a: &M) -> (f64, f64, &'static str) {   // road three: the symbol over unit directions
    let mut ds: Vec<Vec<f64>> = Vec::new();
    if a.len() == 2 { for j in 0..360 { let t = PI * j as f64 / 360.0; ds.push(vec![t.cos(), t.sin()]); } } else {
        for i in 0..181 { for j in 0..360 {
            let (u, v) = (PI * i as f64 / 180.0, PI * j as f64 / 180.0);
            ds.push(vec![u.sin() * v.cos(), u.sin() * v.sin(), u.cos()]);
        } }
    }
    let ps: Vec<f64> = ds.iter().map(|d| symbol(a, d)).collect();
    let lo = ps.iter().cloned().fold(f64::INFINITY, f64::min); let hi = ps.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let tol = 1e-9 * lo.abs().max(hi.abs());
    (lo, hi, if lo < -tol && hi > tol { "both signs" } else if lo.abs().min(hi.abs()) <= tol { "touches 0" } else { "never 0" })
}

fn family(pos: usize, neg: usize, zero: usize, n: usize) -> &'static str {
    if zero == 0 && pos.max(neg) == n { "elliptic" } else if zero == 1 && pos.max(neg) == n - 1 { "parabolic" }
    else if zero == 0 && pos.min(neg) == 1 { "hyperbolic" } else { "none of the three" }
}

fn simpson(f: &dyn Fn(f64) -> f64, b: f64, m: usize) -> f64 {
    let mut s = 0.0;
    for k in 0..=m { let w = if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }; s += w * f(b * k as f64 / m as f64); }
    (b / m as f64 / 3.0) * s
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let kap = 1.2e-5; let c = (2000.0f64 / 0.2).sqrt();   // steel diffusivity m^2/s; drum speed m/s
    let d = |v: Vec<Vec<f64>>| v;
    let cases: Vec<(&str, M)> = vec![
        ("held steady  u_xx + u_yy = 0 in (x, y)", d(vec![vec![1.0, 0.0], vec![0.0, 1.0]])),
        ("cooling      kappa(u_xx + u_yy) - u_t = 0 in (x, y, t)", d(vec![vec![kap, 0.0, 0.0], vec![0.0, kap, 0.0], vec![0.0, 0.0, 0.0]])),
        ("drum ringing c^2(u_xx + u_yy) - u_tt = 0 in (x, y, t)", d(vec![vec![c * c, 0.0, 0.0], vec![0.0, c * c, 0.0], vec![0.0, 0.0, -1.0]])),
        ("trap         u_xx + u_yy + u_zz + 4(u_xy + u_yz + u_xz)", d(vec![vec![1.0, 2.0, 2.0], vec![2.0, 1.0, 2.0], vec![2.0, 2.0, 1.0]])),
        ("halved right u_xx + 2u_xy + u_yy, off-diagonal 1", d(vec![vec![1.0, 1.0], vec![1.0, 1.0]])),
        ("not halved   u_xx + 2u_xy + u_yy, off-diagonal 2", d(vec![vec![1.0, 2.0], vec![2.0, 1.0]]))];
    let mut fams: Vec<&str> = Vec::new();
    for (name, a) in &cases {
        let ev = jacobi(a); let n = a.len();
        let s1 = (ev.iter().filter(|&&v| v > 0.0).count(), ev.iter().filter(|&&v| v < 0.0).count(), ev.iter().filter(|&&v| v == 0.0).count());
        let s2 = descartes(&charpoly(a)); let (lo, hi, s3) = scan(a);
        let fam = family(s1.0, s1.1, s1.2, n); fams.push(fam);
        println!("{}: eigenvalues {}; signs +{} -{} 0x{} -> {}; Descartes +{} -{} 0x{}; scan {:.6} to {:.6}, {}",
                 name, join(&ev), s1.0, s1.1, s1.2, fam, s2.0, s2.1, s2.2, lo, hi, s3);
        assert!(s1 == s2);
        assert!((s3 == "both signs") == (s1.0 > 0 && s1.1 > 0) && (s3 == "touches 0") == (s1.2 > 0));
    }
    // characteristic surfaces: the cone r = c t for the drum, the slices t = const for cooling
    let phi = |x: f64, y: f64, t: f64| (x * x + y * y).sqrt() - c * t;
    for &(x, y, t) in &[(0.3, 0.1, 0.002), (-0.2, 0.25, 0.004)] {
        let e = 1e-6;
        let g = [(phi(x + e, y, t) - phi(x - e, y, t)) / (2.0 * e), (phi(x, y + e, t) - phi(x, y - e, t)) / (2.0 * e),
                 (phi(x, y, t + e) - phi(x, y, t - e)) / (2.0 * e)];
        let pc = symbol(&cases[2].1, &g);
        println!("cone at ({}, {}, {}): drum symbol on the cone's normal, size {:.6} against c^2 = {:.0}", x, y, t, pc.abs(), c * c);
        assert!(pc.abs() < 1e-4 * c * c);
    }
    println!("slice t = const: cooling symbol {:.1}, drum symbol {:.1}", symbol(&cases[1].1, &[0.0, 0.0, 1.0]), symbol(&cases[2].1, &[0.0, 0.0, 1.0]));
    let (mut lo, mut hi) = (0.0f64, 1e6f64);   // front speed s with symbol(n, -s) = 0, by bisection
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if symbol(&cases[2].1, &[1.0, 0.0, -mid]) > 0.0 { lo = mid } else { hi = mid } }
    println!("travel: drum front speed by bisection {:.6} m/s, formula sqrt(T/sigma) {:.6} m/s; centre tap reaches long edges after {:.2} ms, short edges {:.2} ms; lowest note {:.2} Hz",
             lo, c, 0.25 / c * 1000.0, 0.5 / c * 1000.0, c / 2.0 * (1.0 / 1.0f64.powi(2) + 1.0 / 0.5f64.powi(2)).sqrt());
    assert!((lo - c).abs() < 1e-6);

    // settle: steady plate 1 m by 0.5 m, long edge y = 0 at 100 C, other edges 0 C, centre value
    let term = |n: usize| 400.0 / (n as f64 * PI) * (n as f64 * PI / 2.0).sin() / (2.0 * (n as f64 * PI * 0.25).cosh());
    let ser: f64 = (1..16).step_by(2).map(term).sum();
    let (nx, ny, w) = (40usize, 20usize, 1.78);
    let mut u: M = (0..=ny).map(|j| (0..=nx).map(|i| if j == 0 && i > 0 && i < nx { 100.0 } else { 0.0 }).collect()).collect();
    let mut sweep = 0;
    for s in 1..=3000 {
        sweep = s; let mut big = 0.0f64;
        for j in 1..ny { for i in 1..nx {
            let dd = w * ((u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4.0 - u[j][i]); u[j][i] += dd; big = big.max(dd.abs());
        } }
        if big < 1e-10 { break; }
    }
    println!("settle: centre {:.4} C by series to n = 15 (first omitted term {:.6} C), {:.4} C by relaxation at h = 0.025 m in {} sweeps",
             ser, term(17).abs(), u[ny / 2][nx / 2], sweep);
    assert!((ser - u[ny / 2][nx / 2]).abs() < 0.1);

    // spread: a weld spot across a 1 m strip, explicit steps, its variance against 2 kappa t
    let (h, r) = (0.01f64, 0.25f64); let dt = r * h * h / kap; let mut v = vec![0.0f64; 101]; v[50] = 1.0;
    for _ in 0..288 { let mut nv = vec![0.0; 101]; for j in 1..100 { nv[j] = v[j] + r * (v[j - 1] - 2.0 * v[j] + v[j + 1]); } v = nv; }
    let var = (0..101).map(|j| (j as f64 * h - 0.5).powi(2) * v[j]).sum::<f64>() / v.iter().sum::<f64>();
    println!("spread: after {:.1} s the spot's standard width is {:.4} cm on the grid, {:.4} cm from sqrt(2 kappa t); slowest mode of the plate fades with time constant {:.1} s; at 0.5 m after 1 s the kernel is 10^{:.1} of its peak",
             288.0 * dt, 100.0 * var.sqrt(), 100.0 * (2.0 * kap * 600.0).sqrt(), 1.0 / (kap * PI * PI * 5.0), -0.25 / (4.0 * kap) / 10f64.ln());
    assert!((var.sqrt() - (2.0 * kap * 600.0).sqrt()).abs() < 1e-4);

    // uniform ellipticity: a tapered plate, thickness 10 mm at x = 0 down to the tip, steel k = 50 W/(m K)
    for &tip in &[0.002f64, 0.001] {
        let hx = |x: f64| 0.010 * (1.0 - (1.0 - tip / 0.010) * x);
        let th = (0..101).map(|i| scan(&vec![vec![50.0 * hx(i as f64 / 100.0), 0.0], vec![0.0, 50.0 * hx(i as f64 / 100.0)]]).0).fold(f64::INFINITY, f64::min);
        let f = |x: f64| 1.0 / (50.0 * hx(x));
        let q = 100.0 / simpson(&f, 1.0, 2000); let mid = 100.0 - q * simpson(&f, 0.5, 2000);
        let a = 1.0 - tip / 0.010;
        let qf = 100.0 * 0.5 * a / (1.0 / (1.0 - a)).ln(); let midf = 100.0 - qf * (1.0 / (1.0 - a / 2.0)).ln() / (0.5 * a);
        println!("taper to {:.0} mm: theta {:.4} W/K; heat flow {:.4} W/m (closed form {:.4}); middle {:.4} C (closed form {:.4})", tip * 1000.0, th, q, qf, mid, midf);
        assert!((th - 50.0 * tip).abs() < 1e-12 && (q - qf).abs() < 1e-6 && (mid - midf).abs() < 1e-6);
    }
    for &eps in &[1e-3f64, 1e-6] {             // knife edge, cut eps short of the tip: theta = 50 * 0.01 * eps
        let q = 100.0 * 0.5 / (1.0 / eps).ln();
        println!("knife edge cut {:.6} m short: theta {:.7} W/K; heat flow {:.4} W/m; middle {:.4} C", eps, 50.0 * 0.010 * eps, q, 100.0 - q * 2f64.ln() / 0.5);
    }

    // what breaks: a ringing steel plate bends, a fourth-order equation; E 200 GPa, nu 0.3, 5 mm, 7850 kg/m^3
    let dpl = 200e9 * 0.005f64.powi(3) / (12.0 * (1.0 - 0.3f64.powi(2))); let m = 7850.0 * 0.005;
    println!("steel plate: D {:.1} N m, mass {:.2} kg/m^2; bending wave speed {:.2} m/s at 1 m wavelength, {:.2} m/s at 0.1 m: no single speed",
             dpl, m, (dpl / m).sqrt() * 2.0 * PI / 1.0, (dpl / m).sqrt() * 2.0 * PI / 0.1);
    // try changing: the trap's off-diagonal entries
    for &off in &[0.4f64, -0.5] {
        println!("try: trap off-diagonal {:.1}: eigenvalues {}", off, join(&jacobi(&vec![vec![1.0, off, off], vec![off, 1.0, off], vec![off, off, 1.0]])));
    }
    let c2 = (8000.0f64 / 0.2).sqrt();
    println!("try: drum tension 8000 N/m: speed {:.1} m/s, long edges after {:.3} ms, lowest note {:.2} Hz", c2, 0.25 / c2 * 1000.0, c2 / 2.0 * 5f64.sqrt());
    assert!(fams[0] == "elliptic" && fams[1] == "parabolic" && fams[2] == "hyperbolic");
    assert!(fams[3] == "hyperbolic" && fams[4] == "parabolic" && fams[5] == "hyperbolic");
    println!("ALL CHECKS PASS");
}
