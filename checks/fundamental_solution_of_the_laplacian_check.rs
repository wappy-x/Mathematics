// The fundamental solution of -Laplacian: one 1 nC charge in a large hall, and a 1 nC/m wire.
// std only. Simpson's rule and every check are written out here.
use std::f64::consts::PI;

const EPS0: f64 = 8.8541878188e-12; // F/m (CODATA 2022)
const Q: f64 = 1e-9; // C
const LAM: f64 = 1e-9; // C/m
const B: f64 = 0.5; // bump width, m

fn area(d: i32) -> f64 { // surface of the unit sphere in d dimensions
    [2.0, 2.0 * PI, 4.0 * PI, 2.0 * PI * PI][d as usize - 1]
}
fn phi_f(r: f64, d: i32) -> f64 { // the fundamental solution, -Lap Phi = delta, as a function of r = |x|
    match d {
        1 => -r / 2.0,
        2 => -r.ln() / (2.0 * PI),
        _ => r.powi(2 - d) / ((d - 2) as f64 * area(d)),
    }
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn lap<F: Fn(&[f64]) -> f64>(f: F, p: &[f64], h: f64) -> f64 { // centred-difference Laplacian at point p
    let mut s = 0.0;
    for i in 0..p.len() {
        let (mut up, mut dn) = (p.to_vec(), p.to_vec());
        up[i] += h; dn[i] -= h;
        s += (f(&up) - 2.0 * f(p) + f(&dn)) / (h * h);
    }
    s
}
fn sci(x: f64, p: usize) -> String { // Python's e-format: mantissa, sign, two-digit exponent
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn norm(p: &[f64]) -> f64 { p.iter().map(|c| c * c).sum::<f64>().sqrt() }
fn heat(r: f64, d: i32, t: f64) -> f64 { // scaled kappa = 1: integral of the heat kernel over time 0..T, t = e^u
    let g = |u: f64| u.exp() * (-r * r / (4.0 * u.exp())).exp() / (4.0 * PI * u.exp()).powf(d as f64 / 2.0);
    simpson(g, -30.0, t.ln(), 6000)
}
fn bump(r: f64) -> f64 { (-r * r / (2.0 * B * B)).exp() }
fn ident(d: i32, eps: f64, c: f64) -> f64 { // integral over r > eps of c Phi (-Lap bump), radially
    simpson(|r| area(d) * r.powi(d - 1) * c * phi_f(r, d) * (d as f64 / (B * B) - r * r / B.powi(4)) * bump(r), eps, 5.0, 8000)
}
fn cube_flux(c: [f64; 3], n: usize) -> f64 { // flux of the field x/(4 pi |x|^3) out of the cube [-1, 1]^3, charge at c
    let mut tot = 0.0;
    for ax in 0..3 {
        for s in [-1.0, 1.0] {
            let face = |u: f64, v: f64| {
                let mut p = vec![u, v];
                p.insert(ax, s);
                let x: Vec<f64> = (0..3).map(|i| p[i] - c[i]).collect();
                s * x[ax] / (4.0 * PI * norm(&x).powi(3))
            };
            tot += simpson(|u| simpson(|v| face(u, v), -1.0, 1.0, n), -1.0, 1.0, n);
        }
    }
    tot
}

fn main() {
    let (qe, le) = (Q / EPS0, LAM / EPS0);
    println!("hand: Q/eps0 = {:.4} V m; Phi_3(1 m) = 1/(4 pi) = {:.7} per m; potential at 1 m {:.5} V", qe, phi_f(1.0, 3), qe * phi_f(1.0, 3));
    println!("hand: potential at 10 cm {:.4} V, at 2 m {:.5} V; field at 1 m {:.5} V/m", qe * phi_f(0.1, 3), qe * phi_f(2.0, 3), qe / (4.0 * PI));
    println!("hand: wire lambda/eps0 = {:.4} V; /(2 pi) = {:.4} V; ln 100 = {:.5}; 1 cm to 1 m: {:.4} V; field at 10 cm {:.3} V/m",
        le, le / (2.0 * PI), 100f64.ln(), le * (phi_f(0.01, 2) - phi_f(1.0, 2)), le / (2.0 * PI * 0.1));

    for d in 1..=4 { // road 1: the radial formula, flux -Phi'(r) A_d r^(d-1) through spheres
        let fl: Vec<f64> = [0.5, 1.0, 2.0].iter()
            .map(|&r| -(phi_f(r + 1e-5, d) - phi_f(r - 1e-5, d)) / 2e-5 * area(d) * r.powi(d - 1)).collect();
        let s: Vec<String> = fl.iter().map(|x| format!("{:.6}", x)).collect();
        println!("d = {}: Phi(1 m) = {:.7}; flux through spheres r = 0.5, 1, 2 m: {}", d, phi_f(1.0, d) + 0.0, s.join(", "));
        for x in &fl { assert!((x - 1.0).abs() < 1e-8); }
    }

    let f3 = |p: &[f64]| phi_f(norm(p), 3); // road 2: the formula back in Laplace's equation, centred differences
    let f2 = |p: &[f64]| phi_f(norm(p), 2);
    let cases: [(&str, &dyn Fn(&[f64]) -> f64, Vec<f64>); 2] =
        [("d = 3 at (0.6, 0.3, 0.2) m", &f3, vec![0.6, 0.3, 0.2]), ("d = 2 at (0.6, 0.3) m", &f2, vec![0.6, 0.3])];
    for (name, f, p) in cases.iter() {
        let (a, b) = (lap(f, p, 0.02), lap(f, p, 0.01));
        println!("{}: centred Laplacian {} (h 2 cm), {} (h 1 cm), ratio {:.2}", name, sci(a, 3), sci(b, 3), a / b);
        assert!((a / b - 4.0).abs() < 0.05 && b.abs() < 1e-4);
    }
    let w1 = lap(|p: &[f64]| 1.0 / (norm(p) * norm(p)), &[1.0, 0.0, 0.0], 0.01);
    let w2 = lap(|p: &[f64]| 1.0 / norm(p), &[1.0, 0.0], 0.01);
    let exact = |p: i32, d: i32| p * (p + d - 2); // Step 1 on r^p: Lap r^p = p (p + d - 2) r^(p - 2), here at r = 1 m
    println!("mistake, field shape 1/r^2 as a 3-d potential: Laplacian at 1 m {:.4} per m^4 (h 1 cm), exactly {}, not 0", w1, exact(-2, 3));
    println!("mistake, 1/r as the wire's potential: Laplacian in the plane at 1 m {:.4} per m^3 (h 1 cm), exactly {}, not 0", w2, exact(-1, 2));
    assert!((w1 - exact(-2, 3) as f64).abs() < 5e-3 && (w2 - exact(-1, 2) as f64).abs() < 5e-3);

    for r in [0.5, 1.0, 2.0] { // road 3: the heat kernel added up over all time
        let v = heat(r, 3, 40f64.exp());
        println!("d = 3, r = {:.1} m: time integral of heat kernel {:.7}, 1/(4 pi r) {:.7}", r, v, phi_f(r, 3));
        assert!((v - phi_f(r, 3)).abs() < 1e-7);
    }
    println!("d = 3, tail beyond t = e^40 at most {}", sci(2.0 * (4.0 * PI).powf(-1.5) * (-20f64).exp(), 1));
    let v4 = heat(1.0, 4, 40f64.exp());
    println!("d = 4, r = 1 m: time integral {:.7}, 1/(4 pi^2 r^2) {:.7}", v4, phi_f(1.0, 4));
    assert!((v4 - phi_f(1.0, 4)).abs() < 1e-7);
    for t in [1e4, 1e8] {
        let dv = heat(0.01, 2, t) - heat(1.0, 2, t);
        println!("d = 2, T = {}: at 1 m alone {:.4} (grows like ln T/(4 pi)); 1 cm minus 1 m {:.6}; ln(100)/(2 pi) {:.6}; tail at most {}",
            sci(t, 0), heat(1.0, 2, t), dv, phi_f(0.01, 2), sci(1.0 / (16.0 * PI * t), 1));
        assert!((dv - phi_f(0.01, 2)).abs() < 2.0 / (16.0 * PI * t));
    }

    for d in [2, 3] { // road 4: the point-source identity with a bump of width b = 50 cm
        for eps in [0.1, 0.01, 0.001] {
            let v = ident(d, eps, 1.0);
            let part = area(d) * eps.powi(d - 1) * phi_f(eps, d) * (-eps / (B * B)) * bump(eps);
            println!("d = {}, eps = {} m: integral outside eps {:.6}; flux part {:.6}; Phi part {:.6}; sum {:.6}",
                d, eps, v, bump(eps), part, bump(eps) + part);
            assert!((v - bump(eps) - part).abs() < 1e-8);
        }
    }
    let w: Vec<f64> = [2, 3, 4].iter().map(|&d| ident(d, 1e-9, 1.0)).collect();
    println!("whole integral, bump width 0.5 m, d = 2, 3, 4: {:.6}, {:.6}, {:.6}; bump at the source 1, at the 5 m cut-off {}", w[0], w[1], w[2], sci(bump(5.0), 1));
    for x in &w { assert!((x - 1.0).abs() < 1e-6); }
    println!("mistake, 2-d constant 1/(2 pi r) in 3-d: identity gives {:.6}; potential at 1 m {:.4} V", ident(3, 1e-9, 2.0), qe / (2.0 * PI));

    let (fin, fout) = (cube_flux([0.5, 0.3, -0.2], 120), cube_flux([2.5, 0.0, 0.0], 120)); // road 5: Gauss on a cube
    println!("cube 2 m wide, charge at (0.5, 0.3, -0.2) m: flux {:.6} -> {:.4} V m; charge at (2.5, 0, 0) m: flux {:.6}", fin, qe * fin, fout);
    assert!((fin - 1.0).abs() < 1e-5 && fout.abs() < 1e-6);

    let k = 1.0 / (4.0 * PI * EPS0); // the hall: an earthed floor 5 m below the charge acts as a mirror charge
    let di = (1.0f64 + 100.0).sqrt();
    println!("hall: earthed floor 5 m below, mirror charge 10 m below; at 1 m sideways it shifts the potential by {:.4} V ({:.2}% of its 1 m value) and the field by {:.5} V/m ({:.2}%)",
        -k * Q / di, 100.0 / di, k * Q / (di * di), 100.0 / (di * di));
    let c1: Vec<String> = (1..9).map(|i| format!("{:.2}", qe * phi_f(i as f64 / 4.0, 3))).collect();
    let c2: Vec<String> = (1..9).map(|i| format!("{:.2}", le * phi_f(i as f64 / 4.0, 2) + 0.0)).collect();
    println!("chart, point charge V at r = 0.25..2 m: {}", c1.join(", "));
    println!("chart, wire V above 1 m at r = 0.25..2 m: {}", c2.join(", "));
    let far: Vec<String> = [1e3, 1e6].iter().map(|&r| format!("{:.2} V", le * (phi_f(0.01, 2) - phi_f(r, 2)))).collect();
    println!("mistake, wire potential taken as zero far away: 1 cm to R = 1 km, 1000 km: {}", far.join(", "));
    println!("ALL CHECKS PASS");
}
