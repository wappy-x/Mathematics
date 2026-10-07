// From one equation to a system -- the same check as the Python, in Rust.  No
// crates.  A 400 kg car corner on a test rig: spring 2000 N/m, damper 800 N s/m,
// so y'' + 2y' + 5y = 0 with y in cm, pushed down 10 cm and let go at rest.
// Road one: the characteristic-equation answer.  Road two: Euler steps on the
// state (y, v), x' = A x.  Second case: a third-order equation, same stepper.
type Mat = Vec<Vec<f64>>;

fn exact(t: f64) -> (f64, f64) { // y = e^-t (10 cos 2t + 5 sin 2t), v = -25 e^-t sin 2t
    ((-t).exp() * (10.0 * (2.0 * t).cos() + 5.0 * (2.0 * t).sin()), -25.0 * (-t).exp() * (2.0 * t).sin())
}

fn times(m: &Mat, x: &[f64]) -> Vec<f64> { // matrix times vector
    m.iter().map(|row| row.iter().zip(x).map(|(a, b)| a * b).sum()).collect()
}

fn euler(m: &Mat, x0: &[f64], t_end: f64, h: f64) -> Vec<f64> { // new state = state + h A state
    let mut x = x0.to_vec();
    for _ in 0..(t_end / h).round() as usize {
        let r = times(m, &x);
        x = x.iter().zip(&r).map(|(a, b)| a + h * b).collect();
    }
    x
}

fn mul(a: (f64, f64), b: (f64, f64)) -> (f64, f64) { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }

fn c(z: (f64, f64)) -> String { // a complex number as a + bi
    format!("{} {} {}i", z.0, if z.1 < 0.0 { "-" } else { "+" }, z.1.abs())
}

fn main() {
    let a: Mat = vec![vec![0.0, 1.0], vec![-5.0, -2.0]]; // rows: y' = v, v' = -5y - 2v
    let x0 = [10.0, 0.0];
    let lam = (-1.0, 2.0); // root of r^2 + 2r + 5 = 0, as (real, imaginary)
    let av = ((a[0][0] + a[0][1] * lam.0, a[0][1] * lam.1), (a[1][0] + a[1][1] * lam.0, a[1][1] * lam.1));
    let lam2 = mul(lam, lam);
    let (e1, e2) = (euler(&a, &x0, 1.0, 1e-4), euler(&a, &x0, 2.0, 1e-4));
    let errs: Vec<f64> = [0.01, 0.005, 0.0025].iter().map(|&h| (euler(&a, &x0, 1.0, h)[0] - exact(1.0).0).abs()).collect();
    let t1 = (std::f64::consts::PI - 2f64.atan()) / 2.0; // y = 0 when tan 2t = -2
    let c3: Mat = vec![vec![0.0, 1.0, 0.0], vec![0.0, 0.0, 1.0], vec![-1.0, -3.0, -3.0]]; // y''' + 3y'' + 3y' + y = 0
    let y3 = (-1f64).exp() * (1.0 + 1.0 + 0.5); // y = e^-t (1 + t + t^2/2) at t = 1
    let e3 = euler(&c3, &[1.0, 0.0, 0.0], 1.0, 1e-4)[0];
    let bad = euler(&vec![vec![0.0, 1.0], vec![5.0, 2.0]], &x0, 1.0, 1e-4)[0]; // signs not flipped
    let swap = euler(&vec![vec![0.0, 1.0], vec![-2.0, -5.0]], &x0, 1.0, 1e-4)[0]; // 2 and 5 swapped
    let pts: Vec<String> = (0..31).map(|k| { let (y, v) = exact(k as f64 / 10.0); format!("{:.1},{:.1}", 80.0 + 24.0 * y, 60.0 - 12.0 * v) }).collect();
    println!("rig: m 400 kg, c 800 N s/m, k 2000 N/m -> y'' + 2y' + 5y = 0 (c/m = 2, k/m = 5)");
    println!("A = {:?}; state x = (y, v) = {:?}; A x = {:?}", a, x0, times(&a, &x0));
    println!("roots of r^2 + 2r + 5: {}, {}; A (1, lam) = ({}, {}), lam (1, lam) = ({}, {})", c(lam), c((lam.0, -lam.1)), c(av.0), c(av.1), c(lam), c(lam2));
    println!("y = e^-t (10 cos 2t + 5 sin 2t) cm, v = y' = -25 e^-t sin 2t cm/s; y = 0 where tan 2t = -2");
    for (t, e) in [(1, &e1), (2, &e2)] {
        let (y, v) = exact(t as f64);
        println!("t = {} s: formula y {:.4} cm, v {:.4} cm/s; Euler h = 0.0001 y {:.4}, v {:.4}", t, y, v, e[0], e[1]);
    }
    println!("Euler error in y at t = 1, h = 0.01, 0.005, 0.0025: {:.5} {:.5} {:.5}", errs[0], errs[1], errs[2]);
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("t (s)  {}", (0..13).map(|k| format!("{:.2}", k as f64 / 4.0)).collect::<Vec<_>>().join(" "));
    println!("y (cm) {}", (0..13).map(|k| format!("{:.2}", exact(k as f64 / 4.0).0)).collect::<Vec<_>>().join(" "));
    let t2 = t1 + std::f64::consts::PI / 2.0;
    println!("y = 0 at t = {:.4} s with v {:.4}, and at t = {:.4} s with v {:.4}", t1, exact(t1).1, t2, exact(t2).1);
    println!("third order y''' + 3y'' + 3y' + y = 0 from (1, 0, 0): y(1) = e^-1 (1 + 1 + 1/2) = {:.4}; Euler {:.4}", y3, e3);
    println!("mistake, bottom row [5, 2]: y(1) = {:.2} cm; mistake, bottom row [-2, -5]: y(1) = {:.2} cm", bad, swap);
    for r in 0..3 { println!("figure, {}", pts[11 * r..(11 * r + 11).min(31)].join(" ")) }
    let close = |p: (f64, f64), q: (f64, f64)| (p.0 - q.0).abs() + (p.1 - q.1).abs() < 1e-12;
    assert!(close(av.0, lam) && close(av.1, lam2)); // roots are A's eigenvalues
    assert!((e1[0] - exact(1.0).0).abs() < 1e-3 && (e2[1] - exact(2.0).1).abs() < 5e-3); // road two meets road one
    assert!((0..2).all(|i| errs[i] / errs[i + 1] > 1.8 && errs[i] / errs[i + 1] < 2.2)); // error halves: order one
    assert!((e3 - y3).abs() < 1e-3); // third order, both roads
    println!("ALL CHECKS PASS");
}
