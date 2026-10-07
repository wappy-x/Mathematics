// Hessian check, std only.  Heat loss Q in watts through 100 m^2 of wall:
// insulation t cm thick, window area A m^2, 20 degrees inside to out.  Road 1:
// hand-derived gradient and Hessian.  Road 2: difference quotients of Q alone.
// Road 3: Q along the straight path to the new design, as one variable.

fn q(t: f64, a: f64) -> f64 { 20.0 * ((100.0 - a) / (0.5 + t / 4.0) + 2.8 * a) }

const T0: f64 = 10.0; const A0: f64 = 20.0; const HT: f64 = 1.0; const HA: f64 = 2.0;

struct M { g: [f64; 2], h: [[f64; 2]; 2] }

impl M {
    // tangent plane (order 1) or quadratic (order 2) at s times the step
    fn model(&self, s: f64, order: u32, half: f64, mixed: f64) -> f64 {
        let (a, b) = (s * HT, s * HA);
        let lin = q(T0, A0) + self.g[0] * a + self.g[1] * b;
        let quad = self.h[0][0] * a * a + mixed * 2.0 * self.h[0][1] * a * b + self.h[1][1] * b * b;
        lin + if order == 2 { half * quad } else { 0.0 }
    }
}

fn rect(h: f64, k: f64) -> f64 { (q(T0 + h, A0 + k) - q(T0 + h, A0) - q(T0, A0 + k) + q(T0, A0)) / (h * k) }
fn phi(s: f64) -> f64 { q(T0 + s * HT, A0 + s * HA) } // road 3: the path as one variable
fn f(x: f64, y: f64) -> f64 { if x == 0.0 && y == 0.0 { 0.0 } else { x * y * (x * x - y * y) / (x * x + y * y) } }
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let r = 0.5 + T0 / 4.0; // wall resistance, 3
    let m = M { g: [-20.0 * (100.0 - A0) / (4.0 * r * r), 20.0 * (2.8 - 1.0 / r)], // road 1
        h: [[40.0 * (100.0 - A0) / (16.0 * r.powi(3)), 5.0 / (r * r)], [5.0 / (r * r), 0.0]] };
    let e = 0.01; // road 2: centred differences, step e
    let qtt = (q(T0 + e, A0) - 2.0 * q(T0, A0) + q(T0 - e, A0)) / (e * e);
    let qaa = ((q(T0, A0 + e) - 2.0 * q(T0, A0) + q(T0, A0 - e)) / (e * e) * 1e4).round() / 1e4 + 0.0;
    let qta = (q(T0 + e, A0 + e) - q(T0 + e, A0 - e) - q(T0 - e, A0 + e) + q(T0 - e, A0 - e)) / (4.0 * e * e);
    let phi2 = (phi(e) - 2.0 * phi(0.0) + phi(-e)) / (e * e);
    let hhh = m.h[0][0] * HT * HT + 2.0 * m.h[0][1] * HT * HA + m.h[1][1] * HA * HA;
    let rem = phi(1.0) - m.model(1.0, 2, 0.5, 1.0);
    let (w, k) = (HT / 4.0, 100.0 - A0 + 4.0 * HA * r / HT); // phi'''/6 = -20 k w^3 / u^4, u from 3 to 3.25
    let win = (-20.0 * k * w.powi(3) / r.powi(4), -20.0 * k * w.powi(3) / (r + w).powi(4));
    let e1: Vec<f64> = [1.0, 0.5, 0.25].iter().map(|&s| (phi(s) - m.model(s, 1, 0.5, 1.0)).abs()).collect();
    let e2: Vec<f64> = [1.0, 0.5, 0.25].iter().map(|&s| (phi(s) - m.model(s, 2, 0.5, 1.0)).abs()).collect();
    let d = 1e-7;
    let fx = |y: f64| (f(d, y) - f(-d, y)) / (2.0 * d); // slope in x, on the line x = 0
    let fy = |x: f64| (f(x, d) - f(x, -d)) / (2.0 * d); // slope in y, on the line y = 0
    println!("current design: Q(10, 20) = {:.3} W", q(T0, A0));
    println!("road 1 gradient: Q_t = {:.3} W per cm, Q_A = {:.3} W per m^2", m.g[0], m.g[1]);
    println!("road 1 Hessian: Q_tt = {:.4}, Q_tA = Q_At = {:.4}, Q_AA = {:.4}", m.h[0][0], m.h[0][1], m.h[1][1]);
    println!("road 2 differences: Q_tt = {:.4}, Q_tA = {:.4}, Q_AA = {:.4}", qtt, qta, qaa);
    println!("rectangle quotient, 1 x 2, 0.1 x 0.2, 0.01 x 0.02: {}", join(&[1.0, 0.1, 0.01].map(|k| rect(k, 2.0 * k)), 4));
    println!("step (1 cm, 2 m^2): exact {:.3}, tangent plane {:.3}, quadratic {:.3}", phi(1.0), m.model(1.0, 1, 0.5, 1.0), m.model(1.0, 2, 0.5, 1.0));
    println!("correction {:.3} = {:.3} thickness + {:.3} mixed + {:.3} windows",
        m.model(1.0, 2, 0.5, 1.0) - m.model(1.0, 1, 0.5, 1.0), 0.5 * m.h[0][0], 2.0 * m.h[0][1], 2.0 * m.h[1][1]);
    println!("road 3, along the path: phi''(0) = {:.4}, h^T H h = {:.4}", phi2, hhh);
    println!("remainder {:.4}, Lagrange window [{:.4}, {:.4}]", rem, win.0, win.1);
    println!("error at s = 1, 0.5, 0.25: tangent {}; quadratic {}", join(&e1, 4), join(&e2, 4));
    println!("halving s divides them by {:.2}, {:.2} and {:.2}, {:.2}", e1[0] / e1[1], e1[1] / e1[2], e2[0] / e2[1], e2[1] / e2[2]);
    let xs: Vec<f64> = (-4..5).map(|s| s as f64).collect();
    println!("chart s: {}", join(&xs, 0));
    println!("chart exact: {}", join(&xs.iter().map(|&s| phi(s)).collect::<Vec<_>>(), 0));
    println!("chart tangent: {}", join(&xs.iter().map(|&s| m.model(s, 1, 0.5, 1.0)).collect::<Vec<_>>(), 0));
    println!("chart quadratic: {}", join(&xs.iter().map(|&s| m.model(s, 2, 0.5, 1.0)).collect::<Vec<_>>(), 0));
    println!("mistakes: no one-half {:.3}, no mixed term {:.3}", m.model(1.0, 2, 1.0, 1.0), m.model(1.0, 2, 0.5, 0.0));
    println!("xy(x^2 - y^2)/(x^2 + y^2) at 0: x then y {:.3}, y then x {:.3}", (fx(1e-3) - fx(-1e-3)) / 2e-3, (fy(1e-3) - fy(-1e-3)) / 2e-3);
    assert!([(qtt, m.h[0][0]), (qta, m.h[0][1]), (qaa, m.h[1][1])].iter().all(|(a, b)| (a - b).abs() < 1e-3));
    assert!((phi2 - hhh).abs() < 1e-3); // the path's bend is h^T H h
    assert!(win.0 < rem && rem < win.1); // the true remainder obeys Lagrange
    assert!((0..2).all(|i| (e1[i] / e1[i + 1] - 4.0).abs() < 0.5 && (e2[i] / e2[i + 1] - 8.0).abs() < 0.5));
    println!("ALL CHECKS PASS");
}
