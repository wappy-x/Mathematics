// The Cauchy-Euler equation -- the same check as the Python, in Rust.  No
// crates.  A thick steel pipe: bore 50 mm, outside 100 mm, oil at 20 MPa inside.
// The wall's outward shift y (um) at distance x (mm) from the axis obeys
// x^2 y'' + x y' - y = 0.  Road one: the powers x and 1/x, fitted to the two
// pressures.  Road two: Euler's small steps shot across the wall, no powers.
const E: f64 = 200000.0; const NU: f64 = 0.3; const P: f64 = 20.0;
const XI: f64 = 50.0; const XO: f64 = 100.0;
const K: f64 = E / (1.0 - NU * NU) / 1000.0;           // MPa per um/mm of rate

fn roots(a: f64, b: f64) -> (f64, f64) {                // roots of r(r - 1) + a r + b = 0
    let d = ((a - 1.0).powi(2) - 4.0 * b).sqrt();
    ((1.0 - a + d) / 2.0, (1.0 - a - d) / 2.0)
}
fn radial(y: f64, v: f64, x: f64) -> f64 { K * (v + NU * y / x) }   // across the wall
fn hoop(y: f64, v: f64, x: f64) -> f64 { K * (y / x + NU * v) }     // around the wall
fn resid(a: f64, b: f64, r: f64) -> f64 {               // x^r put into the equation at x = 2, rates by differences, over x^r
    let (x, h) = (2.0f64, 1e-3);
    (x * x * ((x + h).powf(r) - 2.0 * x.powf(r) + (x - h).powf(r)) / (h * h) + a * x * ((x + h).powf(r) - (x - h).powf(r)) / (2.0 * h) + b * x.powf(r)) / x.powf(r)
}

fn euler(a: f64, b: f64, mut x: f64, mut y: f64, mut v: f64, x1: f64, n: usize) -> (f64, f64) {
    let h = (x1 - x) / n as f64;
    for _ in 0..n {
        let (y2, v2) = (y + h * v, v - h * (a * x * v + b * y) / (x * x));
        y = y2; v = v2; x += h;
    }
    (y, v)
}

fn main() {
    // road one: y = A x + B / x, radial stress -P at the bore and 0 outside
    let m = [[K * (1.0 + NU), -K * (1.0 - NU) / (XI * XI)], [K * (1.0 + NU), -K * (1.0 - NU) / (XO * XO)]];
    let det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    let (a_amt, b_amt) = (-P * m[1][1] / det, P * m[1][0] / det);
    let y = |x: f64| a_amt * x + b_amt / x;
    let dy = |x: f64| a_amt - b_amt / (x * x);
    let (ra, rb) = roots(1.0, -1.0);
    println!("indicial roots, a = 1, b = -1: {:.0} and {:.0}", ra, rb);
    println!("steel K = {:.0} MPa; fitted amounts: A = {:.5} um per mm, B = {:.2} um mm", K * 1000.0, a_amt, b_amt);
    println!("shift, powers: bore {:.4} um, outside {:.4} um", y(XI), y(XO));
    let mut errs = Vec::new();
    for n in [100usize, 200, 400] {                     // road two: shoot from the bore
        let f = |s: f64| { let (yy, vv) = euler(1.0, -1.0, XI, s, -P / K - NU * s / XI, XO, n); radial(yy, vv, XO) };
        let s = -f(0.0) * 10.0 / (f(10.0) - f(0.0));
        errs.push(s - y(XI));
        println!("shift at bore, Euler shot, h = {:.3} mm: {:.4} um; error {:+.4}", (XO - XI) / n as f64, s, errs[errs.len() - 1]);
    }
    println!("error ratio when h halves: {:.2}, {:.2}", errs[0] / errs[1], errs[1] / errs[2]);
    let lame = P * (XO * XO + XI * XI) / (XO * XO - XI * XI);
    println!("hoop stress at bore: from the shift {:.2} MPa; Lame's formula {:.2} MPa", hoop(y(XI), dy(XI), XI), lame);
    let rad_out = (radial(y(XO), dy(XO), XO) * 1e9).round() / 1e9 + 0.0;
    println!("radial stress: bore {:.2} MPa, outside {:.2} MPa; hoop outside {:.2} MPa", radial(y(XI), dy(XI), XI), rad_out, hoop(y(XO), dy(XO), XO));
    let xs = [50.0, 60.0, 70.0, 80.0, 90.0, 100.0];
    let row = |g: &dyn Fn(f64) -> f64, w: usize, p: usize| xs.iter().map(|&x| format!("{:w$.p$}", g(x), w = w, p = p)).collect::<Vec<_>>().join(" ");
    println!("figure, x (mm):    {}", row(&|x| x, 5, 0));
    println!("figure, y (um):    {}", row(&|x| y(x), 5, 2));
    println!("figure, A x (um):  {}", row(&|x| a_amt * x, 5, 2));
    println!("figure, B/x (um):  {}", row(&|x| b_amt / x, 5, 2));
    let (r1, r2) = roots(-1.0, 1.0);                    // second case: x^2 y'' - x y' + y = 0
    let yr: Vec<f64> = [100usize, 200, 400].iter().map(|&n| euler(-1.0, 1.0, 1.0, 0.0, 1.0, 2.0, n).0).collect();
    let exact = 2.0 * 2f64.ln();
    println!("repeated case a = -1, b = 1: roots {:.0}, {:.0}; x ln x at 2 = {:.6}", r1, r2, exact);
    println!("  Euler from y(1) = 0, y'(1) = 1, 100/200/400 steps: {:.6} {:.6} {:.6}", yr[0], yr[1], yr[2]);
    let rw = (-1.0 + (1.0f64 + 4.0).sqrt()) / 2.0;      // mistake: r^2 + a r + b = 0, a = 1, b = -1
    println!("mistake, r^2 + r - 1 = 0 gives r = {:.3}: x^r leaves {:.3} x^r", rw, resid(1.0, -1.0, rw));
    println!("mistake, thin-wall rule P x mean radius / thickness: {:.2} MPa, not {:.2}", P * 75.0 / 50.0, lame);
    println!("mistake, one power C x fitted to y(1) = 0: C = 0, so y(2) = {:.6}, not {:.6}", 0.0 * 2.0, exact);
    assert!(errs[2].abs() < 0.1 && 1.8 < errs[0] / errs[1] && errs[0] / errs[1] < 2.2 && 1.8 < errs[1] / errs[2] && errs[1] / errs[2] < 2.2);
    assert!((hoop(y(XI), dy(XI), XI) - lame).abs() < 1e-9 && radial(y(XO), dy(XO), XO).abs() < 1e-9);
    assert!((yr[2] - exact).abs() < 0.005 && (yr[1] - exact).abs() > (yr[2] - exact).abs());
    let fd = [resid(1.0, -1.0, ra), resid(1.0, -1.0, rb), resid(-1.0, 1.0, r1), resid(-1.0, 1.0, r2)];
    assert!(fd.iter().all(|e| e.abs() < 1e-5) && resid(1.0, -1.0, rw) < -0.5);
    println!("ALL CHECKS PASS");
}
