// The matrix exponential -- the same check as the Python, in Rust.  No crates.
// Two rooms share a wall, heating off: T' = A T, T(0) = (30, 10) C above outside.
// Roads: the power series summed term by term, the eigenvector formula, Euler steps.
// Second case: a heater warming a room, J = [[-1, 1], [0, -1]], one eigenvector.
type M = [[f64; 2]; 2];
const I2: M = [[1.0, 0.0], [0.0, 1.0]];

fn mul(x: &M, y: &M) -> M {
    let mut z = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { z[i][j] = x[i][0] * y[0][j] + x[i][1] * y[1][j] } }
    z
}

fn expm(m: &M, t: f64, terms: usize) -> M {     // I + Mt + (Mt)^2/2! + ... term by term
    let (mut s, mut term) = (I2, I2);
    for k in 1..terms {
        term = mul(&term, m);
        for i in 0..2 { for j in 0..2 { term[i][j] *= t / k as f64; s[i][j] += term[i][j] } }
    }
    s
}

fn eig_form(t: f64) -> M {                      // 0.5 [[e^-t + e^-3t, e^-t - e^-3t], ...]
    let p = ((-t).exp() + (-3.0 * t).exp()) / 2.0;
    let m = ((-t).exp() - (-3.0 * t).exp()) / 2.0;
    [[p, m], [m, p]]
}

fn app(m: &M, v: [f64; 2]) -> [f64; 2] { [m[0][0] * v[0] + m[0][1] * v[1], m[1][0] * v[0] + m[1][1] * v[1]] }

fn euler(m: &M, mut v: [f64; 2], t_end: f64, h: f64) -> [f64; 2] {   // new state = old + h x rate
    for _ in 0..(t_end / h).round() as usize {
        let d = app(m, v);
        v = [v[0] + h * d[0], v[1] + h * d[1]];
    }
    v
}

fn gap(x: &M, y: &M) -> f64 { let mut g: f64 = 0.0; for i in 0..2 { for j in 0..2 { g = g.max((x[i][j] - y[i][j]).abs()) } } g }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn fm(x: &M) -> String { format!("[[{:.6}, {:.6}], [{:.6}, {:.6}]]", x[0][0], x[0][1], x[1][0], x[1][1]) }

fn main() {
    let a: M = [[-2.0, 1.0], [1.0, -2.0]];
    let jm: M = [[-1.0, 1.0], [0.0, -1.0]];
    let (t0, r0) = ([30.0, 10.0], [0.0, 10.0]);
    let (p, q): (M, M) = ([[0.0, 1.0], [0.0, 0.0]], [[0.0, 0.0], [1.0, 0.0]]);   // the wall's two one-way flows
    let e = |t: f64| (-t).exp();
    let e1 = expm(&a, 1.0, 60);
    let times: Vec<f64> = (0..7).map(|k| 0.5 * k as f64).collect();
    let semi = mul(&expm(&a, 0.5, 60), &e1);
    let err: Vec<f64> = [0.01, 0.005, 0.0025].iter().map(|&h| (euler(&a, t0, 1.0, h)[0] - app(&eig_form(1.0), t0)[0]).abs()).collect();
    let ej = expm(&jm, 1.0, 60);
    let heat: Vec<f64> = (0..9).map(|k| app(&expm(&jm, 0.5 * k as f64, 60), r0)[0]).collect();
    let split = app(&mul(&expm(&p, 1.0, 60), &expm(&q, 1.0, 60)), t0)[0] * e(2.0);
    let row = |f: &dyn Fn(f64) -> f64| times.iter().map(|&t| format!("{:5.2}", f(t))).collect::<Vec<_>>().join(" ");
    println!("series e^(A*1):      {}", fm(&e1));
    println!("eigenvectors e^(A*1): {}; agree to 1e-12: {}", fm(&eig_form(1.0)), yn(gap(&e1, &eig_form(1.0)) < 1e-12));
    let r1 = app(&e1, t0);
    println!("rooms at t = 1 h: T1 = {:.4} C, T2 = {:.4} C; 20e^-1 + 10e^-3 = {:.4}", r1[0], r1[1], 20.0 * e(1.0) + 10.0 * e(3.0));
    println!("t (h)   {}", times.iter().map(|t| format!("{:5.1}", t)).collect::<Vec<_>>().join(" "));
    println!("T1 (C)  {}", row(&|t| app(&expm(&a, t, 60), t0)[0]));
    println!("T2 (C)  {}", row(&|t| app(&expm(&a, t, 60), t0)[1]));
    println!("e^(A*0.5) e^(A*1) = {}", fm(&semi));
    println!("e^(A*1.5), eigen  = {}; agree: {}", fm(&eig_form(1.5)), yn(gap(&semi, &eig_form(1.5)) < 1e-12));
    println!("Euler T1(1) error, h = 0.01, 0.005, 0.0025: {:.5} {:.5} {:.5} ratios {:.2} {:.2}", err[0], err[1], err[2], err[0] / err[1], err[1] / err[2]);
    println!("series e^(J*1) = {}; equals e^-1 [[1, 1], [0, 1]]: {}", fm(&ej), yn(gap(&ej, &[[e(1.0), e(1.0)], [0.0, e(1.0)]]) < 1e-12));
    println!("heater case t (h)   {}", (0..9).map(|k| format!("{:4.1}", 0.5 * k as f64)).collect::<Vec<_>>().join(" "));
    println!("room R = 10te^-t (C) {}", heat.iter().map(|r| format!("{:4.2}", r)).collect::<Vec<_>>().join(" "));
    println!("room peak: t = 1 h, R = {:.4} C = 10/e = {:.4}", heat[2], 10.0 / std::f64::consts::E);
    println!("mistake, e^ entry by entry: T1(1) = {:.2} C, not {:.2}", 30.0 * e(2.0) + 10.0 * e(-1.0), r1[0]);
    println!("mistake, e^-2 e^P e^Q for e^(A*1): T1(1) = {:.2} C", split);
    println!("mistake, J's start times e^-t: R(1) = {:.2} C, not {:.2}", 0.0 * e(1.0), heat[2]);
    println!("mistake, three terms at t = 3 h: T1 = {:.2} C, not {:.4}", app(&expm(&a, 3.0, 3), t0)[0], app(&eig_form(3.0), t0)[0]);
    assert!(gap(&e1, &eig_form(1.0)) < 1e-12);                          // series = eigenvectors
    assert!(gap(&semi, &eig_form(1.5)) < 1e-12);                        // e^(As) e^(At) = e^(A(s+t))
    assert!((0..9).all(|k| (heat[k] - 5.0 * k as f64 * e(0.5 * k as f64)).abs() < 1e-12));   // J by hand
    assert!(1.9 < err[0] / err[1] && err[0] / err[1] < 2.1 && 1.9 < err[1] / err[2] && err[1] / err[2] < 2.1);
    println!("ALL CHECKS PASS");
}
