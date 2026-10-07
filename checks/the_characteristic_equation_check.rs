// The characteristic equation -- the same check as the Python, in Rust.  No
// crates.  The shock absorber y'' + b y' + 5y = 0, y(0) = 1 cm, y'(0) = 0, is
// answered by two roads: the closed form built from the quadratic's roots, and
// Euler's small steps along the slope, which never call exp.  The roots are
// found twice: by the quadratic formula, and by bisection, which never calls sqrt.
const C: f64 = 5.0;

fn roots(b: f64) -> (f64, f64) {                // quadratic formula for r^2 + b r + C = 0
    let d = (b * b - 4.0 * C).sqrt();
    ((-b + d) / 2.0, (-b - d) / 2.0)
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {                            // f changes sign between lo and hi
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn euler(b: f64, t_end: f64, h: f64) -> f64 {   // position += h velocity; velocity += h acceleration
    let (mut y, mut v) = (1.0, 0.0);
    for _ in 0..(t_end / h).round() as usize { (y, v) = (y + h * v, v + h * (-b * v - C * y)) }
    y
}

fn leftover(f: &dyn Fn(f64) -> f64, t: f64, a: f64, b: f64, c: f64) -> f64 {
    let k = 1e-3;                                // a y'' + b y' + c y by finite differences
    a * (f(t + k) - 2.0 * f(t) + f(t - k)) / (k * k) + b * (f(t + k) - f(t - k)) / (2.0 * k) + c * f(t)
}

fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (r1, r2) = roots(6.0);
    let c1 = (0.0 - r2 * 1.0) / (r1 - r2);      // from C1 + C2 = 1 and r1 C1 + r2 C2 = 0
    let over = |t: f64| c1 * (r1 * t).exp() + (1.0 - c1) * (r2 * t).exp();
    let r = -C.sqrt();                           // b = 2 sqrt 5: the root repeats
    let crit = |t: f64| (1.0 + (0.0 - r * 1.0) * t) * (r * t).exp();
    let one = |t: f64| (r * t).exp();            // the repeated root used once, no t e^(rt)
    let p = |x: f64| x * x + 6.0 * x + C;
    let rb = [bisect(&p, -3.0, 0.0), bisect(&p, -6.0, -3.0)];
    let (bc, hs) = (2.0 * C.sqrt(), [0.01, 0.005, 0.0025]);
    let ts: Vec<f64> = (0..7).map(|i| 0.5 * i as f64).collect();
    let steps: Vec<f64> = hs.iter().map(|&h| euler(6.0, 1.0, h)).collect();
    let e_over: Vec<f64> = steps.iter().map(|y| (y - over(1.0)).abs()).collect();
    let e_crit = (euler(bc, 1.0, 0.0025) - crit(1.0)).abs();
    let res = [leftover(&over, 1.0, 1.0, 6.0, C), leftover(&crit, 1.0, 1.0, bc, C)];
    let ce: Vec<f64> = [1.0f64, 2.0].iter().map(|&t| leftover(&|s: f64| s.exp(), t, t * t, t, -1.0) / t.exp()).collect();
    let lin = leftover(&|s: f64| s, 2.0, 4.0, 2.0, -1.0);
    println!("y'' + b y' + 5y = 0, y(0) = 1 cm, y'(0) = 0 cm/s");
    println!("b = 6: discriminant {:.0}; roots by formula {}; by bisection {}", 36.0 - 4.0 * C, fmt(&[r1, r2], 6), fmt(&rb, 6));
    println!("b = 6: C1 = {:.4}, C2 = {:.4}; y(1) = {:.6} cm", c1, 1.0 - c1, over(1.0));
    println!("b = 6, Euler y(1) at h = 0.01 0.005 0.0025: {}", fmt(&steps, 6));
    println!("errors: {}; ratios on halving h: {:.3} {:.3}", fmt(&e_over, 6), e_over[0] / e_over[1], e_over[1] / e_over[2]);
    println!("b = 2 sqrt 5 = {:.6}: discriminant {:.6}; repeated root {:.6}; C1 = 1, C2 = {:.6}", bc, bc * bc - 4.0 * C, r, -r);
    println!("critical: y(1) = {:.6} cm; Euler h = 0.0025: {:.6}; error {:.6}", crit(1.0), euler(bc, 1.0, 0.0025), e_crit);
    println!("law's leftover at t = 1 by finite differences, in millionths: b = 6 {:.2}; critical {:.2}", res[0].abs() * 1e6, res[1].abs() * 1e6);
    println!("figure, t (s):           {}", fmt(&ts, 2));
    println!("figure, b = 6 y (cm):    {}", fmt(&ts.iter().map(|&t| over(t)).collect::<Vec<_>>(), 2));
    println!("figure, critical y (cm): {}", fmt(&ts.iter().map(|&t| crit(t)).collect::<Vec<_>>(), 2));
    println!("within 0.05 cm of level: b = 6 after {:.2} s; critical after {:.2} s",
             bisect(&|t| over(t) - 0.05, 0.0, 10.0), bisect(&|t| crit(t) - 0.05, 0.0, 10.0));
    println!("mistake, one exponential at the repeated root: y'(0) = {:.3}, not 0; y(1) = {:.4}, not {:.4}", r, one(1.0), crit(1.0));
    println!("mistake, roots' signs flipped to +1 and +5: y(1) = {:.2} cm", c1 * (-r1).exp() + (1.0 - c1) * (-r2).exp());
    println!("hypothesis dropped, t^2 y'' + t y' - y = 0: e^t leaves {} times e^t at t = 1, 2; y = t leaves {:.2}", fmt(&ce, 2), lin.abs());
    println!("house b = 2: discriminant {:.0}, roots -1 +/- 2i, complex", 4.0 - 4.0 * C);
    assert!((rb[0] - r1).abs().max((rb[1] - r2).abs()) < 1e-12);              // formula against bisection
    assert!(e_over[2] < 1e-3 && e_over[0] / e_over[1] > 1.9 && e_over[0] / e_over[1] < 2.1); // steps meet roots
    assert!(e_crit < 1e-3 && (euler(bc, 1.0, 0.0025) - one(1.0)).abs() > 0.2); // t e^(rt) is the missing piece
    assert!(res[0].abs().max(res[1].abs()) < 1e-4);                           // the answers obey the law
    println!("ALL CHECKS PASS");
}
