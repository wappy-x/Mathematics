// Helmholtz and eigenfunctions -- the same check as the Python, in Rust.  No crates.
// A steel plate 0.6 m by 0.4 m, 3 mm thick, simply supported on all four edges.
// Its mode shapes are the eigenfunctions of -Laplacian on the rectangle with zero
// edge values.  Road 1: separated sines.  Road 2: a grid, solved by power iteration.
// Road 3: the Rayleigh quotient of a dome.  Then the dome is expanded in the modes.
use std::f64::consts::PI;
const A: f64 = 0.6; const B: f64 = 0.4; const H: f64 = 0.003;    // plate sides and thickness, m
const E: f64 = 207e9; const NU: f64 = 0.30; const RHO: f64 = 7850.0; // steel: Pa, Poisson, kg/m^3

fn lam(m: f64, n: f64) -> f64 {             // road 1: eigenvalue of -Laplacian, 1/m^2
    PI * PI * (m * m / (A * A) + n * n / (B * B))
}

fn neg_lap(v: &[f64], nx: usize, ny: usize, h: f64) -> Vec<f64> {
    let mut out = vec![0.0; nx * ny];
    for j in 0..ny {
        for i in 0..nx {
            let p = j * nx + i;
            let mut s = 4.0 * v[p];
            if i > 0 { s -= v[p - 1]; } if i < nx - 1 { s -= v[p + 1]; }
            if j > 0 { s -= v[p - nx]; } if j < ny - 1 { s -= v[p + nx]; }
            out[p] = s / (h * h);
        }
    }
    out
}

fn grid_eigs(h: f64, k: usize, iters: usize) -> Vec<f64> {   // road 2: 5-point -Laplacian
    let (nx, ny) = ((A / h).round() as usize - 1, (B / h).round() as usize - 1);
    let n = nx * ny;
    let c = 8.0 / (h * h);                  // above every grid eigenvalue (Gershgorin)
    let (mut found, mut vals): (Vec<Vec<f64>>, Vec<f64>) = (vec![], vec![]);
    for _ in 0..k {
        let mut v: Vec<f64> = (0..n).map(|p| 1.0 + ((7 * p) % 13) as f64 / 13.0).collect();
        for _ in 0..iters {                 // power iteration on c*I - (-Laplacian)
            let w = neg_lap(&v, nx, ny, h);
            v = (0..n).map(|p| c * v[p] - w[p]).collect();
            for u in &found {               // remove the modes already found
                let d: f64 = (0..n).map(|p| v[p] * u[p]).sum();
                v = (0..n).map(|p| v[p] - d * u[p]).collect();
            }
            let norm = v.iter().map(|x| x * x).sum::<f64>().sqrt();
            v = v.iter().map(|x| x / norm).collect();
        }
        let w = neg_lap(&v, nx, ny, h);
        vals.push((0..n).map(|p| v[p] * w[p]).sum());
        found.push(v);
    }
    vals
}

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, panels: usize) -> f64 {
    let step = (hi - lo) / panels as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..panels {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * step);
    }
    s * step / 3.0
}

fn coef(m: f64, n: f64) -> f64 {            // unit dome's coefficient on mode (m,n), by quadrature
    let ix = simpson(&|x| x * (A - x) * (m * PI * x / A).sin(), 0.0, A, 400);
    let iy = simpson(&|y| y * (B - y) * (n * PI * y / B).sin(), 0.0, B, 400);
    4.0 / (A * B) * 16.0 / (A * A * B * B) * ix * iy
}

fn rq(f: &dyn Fn(f64) -> f64, df: &dyn Fn(f64) -> f64, g: &dyn Fn(f64) -> f64, dg: &dyn Fn(f64) -> f64) -> f64 {
    let (gx, gy) = (simpson(&|x| f(x) * f(x), 0.0, A, 200), simpson(&|y| g(y) * g(y), 0.0, B, 200));
    let (dx, dy) = (simpson(&|x| df(x) * df(x), 0.0, A, 200), simpson(&|y| dg(y) * dg(y), 0.0, B, 200));
    (dx * gy + gx * dy) / (gx * gy)         // Rayleigh quotient of the shape f(x) g(y), slopes df, dg, by Simpson
}

fn bih(h: f64) -> f64 {                     // plate law, road 2: 13-point stencil for Delta^2 on phi_11 at the centre
    let p = |i: i32, j: i32| (PI * (0.5 + i as f64 * h / A)).sin() * (PI * (0.5 + j as f64 * h / B)).sin();
    (20.0 * p(0, 0) - 8.0 * (p(1, 0) + p(-1, 0) + p(0, 1) + p(0, -1)) + 2.0 * (p(1, 1) + p(1, -1) + p(-1, 1)
        + p(-1, -1)) + p(2, 0) + p(-2, 0) + p(0, 2) + p(0, -2)) / (h * h * h * h) / p(0, 0)
}

fn sci(x: f64, plus: bool) -> String {      // Python's {:.1e} and {:+.1e}: two-digit exponent
    let s = format!("{:.1e}", x);
    let (mant, ex) = s.split_once('e').unwrap();
    let e: i32 = ex.parse().unwrap();
    let sign = if plus && x >= 0.0 { "+" } else { "" };
    format!("{}{}e{}{:02}", sign, mant, if e < 0 { "-" } else { "+" }, e.abs())
}

fn join(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let d = E * H * H * H / (12.0 * (1.0 - NU * NU));   // bending stiffness, N m
    let s = (d / (RHO * H)).sqrt();                    // m^2/s: plate omega = lambda * S
    let hz = |lv: f64| lv * s / (2.0 * PI);
    let mut modes: Vec<(f64, i32, i32)> = vec![];
    for m in 1..9 { for n in 1..9 { modes.push((lam(m as f64, n as f64), m, n)); } }
    modes.sort_by(|p, q| p.partial_cmp(q).unwrap());
    let l1 = modes[0].0;
    println!("plate {} m x {} m x {:.0} mm steel: D = {:.2} N m, rho H = {:.2} kg/m^2, sqrt(D/(rho H)) = {:.4} m^2/s",
             A, B, H * 1000.0, d, RHO * H, s);
    println!("mode  lambda (1/m^2)  omega (rad/s)  f (Hz)  plate ratio  membrane ratio");
    for &(lv, m, n) in &modes[..4] {
        println!("({},{})  {:13.3}  {:12.2}  {:7.2}  {:10.3}  {:13.3}", m, n, lv, lv * s, hz(lv), lv / l1, (lv / l1).sqrt());
    }
    let dz = simpson(&|z| E * z * z / (1.0 - NU * NU), -H / 2.0, H / 2.0, 2);   // D again: each layer's stiffness times z^2
    let (b1, b2) = (bih(0.05), bih(0.025));
    let brich = (4.0 * b2 - b1) / 3.0;      // Richardson, as for the grid road
    let fs = s * brich.sqrt() / (2.0 * PI); // the first note, from the plate equation itself
    println!("plate law, second road: D by layers through the thickness {:.2} N m; 13-point stencil for Delta^2 phi_11 / phi_11:", dz);
    println!("  h = 0.05 m {:.1}, h = 0.025 m {:.1}, order {:.2}, Richardson {:.1}, lambda_11^2 = {:.1} 1/m^4; first note {:.2} Hz",
             b1, b2, ((l1 * l1 - b1) / (l1 * l1 - b2)).log2(), brich, l1 * l1, fs);
    let first3: Vec<(i32, i32)> = modes[..3].iter().map(|t| (t.1, t.2)).collect();
    let (hs, hf) = (0.05, 0.025);
    let (gc, gf) = (grid_eigs(hs, 3, 6000), grid_eigs(hf, 3, 6000));
    println!("grid road, first three eigenvalues of -Laplacian (1/m^2):");
    println!("  h = {} m: {}", hs, join(&gc, 3));
    println!("  h = {} m: {}", hf, join(&gf, 3));
    let rich: Vec<f64> = (0..3).map(|i| (4.0 * gf[i] - gc[i]) / 3.0).collect();
    let order: Vec<f64> = (0..3).map(|i| ((modes[i].0 - gc[i]) / (modes[i].0 - gf[i])).log2()).collect();
    println!("  Richardson (4 x fine - coarse)/3: {}", join(&rich, 3));
    println!("  observed order: {}", join(&order, 2));
    let r = rq(&|x| x * (A - x), &|x| A - 2.0 * x, &|y| y * (B - y), &|y| B - 2.0 * y);   // road 3: the dome
    println!("Rayleigh quotient of the dome x(a-x)y(b-y): R = {:.3} 1/m^2; 10/a^2 + 10/b^2 = {:.3}; lambda_1 = {:.3}; R/lambda_1 = {:.4}",
             r, 10.0 / (A * A) + 10.0 / (B * B), l1, r / l1);
    println!("  f from R: {:.2} Hz against {:.2} Hz", hz(r), hz(l1));
    let (c11, pi6) = (coef(1.0, 1.0), PI * PI * PI * PI * PI * PI);
    println!("unit dome 16 x(a-x) y(b-y)/(a^2 b^2): c11 by quadrature {:.6}, 1024/pi^6 = {:.6}", c11, 1024.0 / pi6);
    println!("  c21 = {:.6}, c31 = {:.6}, c13 = {:.6}, c33 = {:.6}",
             coef(2.0, 1.0).abs(), coef(3.0, 1.0), coef(1.0, 3.0), coef(3.0, 3.0));
    let mut exact: Vec<(i32, i32, f64)> = vec![];
    for m in (1..60).step_by(2) { for n in (1..60).step_by(2) { exact.push((m, n, 1024.0 / (pi6 * (m * m * m) as f64 * (n * n * n) as f64))); } }
    let parseval: f64 = exact.iter().map(|t| t.2 * t.2).sum();
    println!("  sum of c^2 over odd m, n < 60: {:.6}; mean-square rule (4/ab) int f^2 = 1024/900 = {:.6}", parseval, 1024.0 / 900.0);
    println!("  share in mode (1,1): {:.2} %", 100.0 * c11 * c11 / (1024.0 / 900.0));
    for mm in [1, 3, 5, 11, 21] {
        let sm: f64 = exact.iter().filter(|t| t.0 <= mm && t.1 <= mm).map(|t| t.2 * (if (t.0 + t.1) % 4 == 2 { 1.0 } else { -1.0 })).sum();
        println!("  centre value from modes m, n <= {:2}: {:.6}, error {}", mm, sm, sci(sm - 1.0, true));
    }
    let rexp = exact.iter().map(|&(m, n, c)| lam(m as f64, n as f64) * c * c).sum::<f64>() / parseval;
    println!("  R rebuilt from the expansion, sum lambda c^2 / sum c^2: {:.3} 1/m^2, short by {} (modes past 59 left out)",
             rexp, sci(r - rexp, false));
    let names = ["(1,1)", "(2,1)", "(1,2)"];
    let strike: Vec<String> = first3.iter().zip(names).map(|(&(m, n), nm)| format!("{} {:.3}", nm,
        (m as f64 * PI * 0.15 / A).sin() * (n as f64 * PI * 0.10 / B).sin())).collect();
    let centre: Vec<String> = first3.iter().zip(names).map(|(&(m, n), nm)| format!("{} {:.3}", nm,
        ((m as f64 * PI / 2.0).sin() * (n as f64 * PI / 2.0).sin()).abs())).collect();
    println!("strike at (0.15, 0.10) m, mode weights: {}", strike.join(", "));
    println!("strike at the centre, mode weights:     {}", centre.join(", "));
    let lim = 2.0 * PI * 20000.0 / s;               // lambda of a 20 kHz plate note
    let count = (1..400).flat_map(|m| (1..400).map(move |n| lam(m as f64, n as f64))).filter(|&l| l <= lim).count();
    let weyl = A * B * lim / (4.0 * PI);
    let weyl2 = weyl - 2.0 * (A + B) * lim.sqrt() / (4.0 * PI);
    println!("plate notes below 20 kHz: lambda <= {:.0} 1/m^2; count {}; Weyl ab L/(4 pi) = {:.1}; with edge term {:.1}", lim, count, weyl, weyl2);
    println!("mistakes:");
    println!("  membrane sqrt rule for the plate's 2nd note: {:.2} Hz, not {:.2} Hz", hz(l1) * (modes[1].0 / l1).sqrt(), hz(modes[1].0));
    println!("  trial w = 1 ignores the zero edge: R = {:.3}, below lambda_1 = {:.3}", rq(&|_| 1.0, &|_| 0.0, &|_| 1.0, &|_| 0.0), l1);
    println!("  c11 without dividing by int phi^2 = ab/4 = {:.2} m^2: {:.6}", A * B / 4.0, c11 * A * B / 4.0);
    println!("  omega read as hertz: {:.2} 'Hz' for a {:.2} Hz note", l1 * s, hz(l1));
    println!("figure, px per m 200: plates at x 20, 170, 320, y 30, size {:.0} x {:.0}; nodal line of (2,1) at x {:.0}; of (1,2) at y {:.0}",
             A * 200.0, B * 200.0, 170.0 + A / 2.0 * 200.0, 30.0 + B / 2.0 * 200.0);
    assert!(first3 == vec![(1, 1), (2, 1), (1, 2)]);
    assert!((0..3).all(|i| (rich[i] / modes[i].0 - 1.0).abs() < 5e-4));      // grid meets sines
    assert!(order.iter().all(|&p| 1.9 < p && p < 2.1));                     // second order, as claimed
    assert!(l1 < r && r < 1.02 * l1 && (r - (10.0 / (A * A) + 10.0 / (B * B))).abs() < 1e-6);
    assert!((c11 - 1024.0 / pi6).abs() < 1e-9 && coef(2.0, 1.0).abs() < 1e-12);
    assert!((parseval - 1024.0 / 900.0).abs() < 1e-8 && 0.0 < r - rexp && r - rexp < 2e-4);
    assert!((count as f64 - weyl2).abs() < 15.0);                           // Weyl's count
    assert!((dz / d - 1.0).abs() < 1e-12 && (fs / hz(l1) - 1.0).abs() < 1e-4);  // plate law: D and the note by two roads
    println!("ALL CHECKS PASS");
}
