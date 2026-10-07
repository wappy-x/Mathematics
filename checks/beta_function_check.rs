// The beta function -- the same check as the Python, in Rust.  No crates.
// Road 1 is the defining integral itself, after x = sin^2 of an angle.  Road 2 is the Gamma
// ratio, with Gamma computed from its own integral.  Nothing imported knows either.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for k in 1..n {
        s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(lo + k as f64 * h);
    }
    s * h / 3.0
}

fn beta_direct(a: f64, b: f64) -> f64 {        // road 1: B = 2 * integral of sin^(2a-1) cos^(2b-1) of the angle
    2.0 * simpson(&|th: f64| th.sin().powf(2.0 * a - 1.0) * th.cos().powf(2.0 * b - 1.0), 0.0, PI / 2.0, 2000)
}

fn gamma(x: f64) -> f64 {                      // Gamma(x) = 2 * integral of w^(2x-1) e^(-w^2), w from 0 to 10
    2.0 * simpson(&|w: f64| w.powf(2.0 * x - 1.0) * (-w * w).exp(), 0.0, 10.0, 4000)
}

fn beta_gamma(a: f64, b: f64) -> f64 {         // road 2: Gamma(a) Gamma(b) / Gamma(a + b)
    gamma(a) * gamma(b) / gamma(a + b)
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let cases = [("B(2, 3) ramp", 2.0, 3.0, "1!2!/4!", 1.0 / 12.0),
                 ("B(3/2, 3/2) arch", 1.5, 1.5, "half disc pi(1/2)^2/2", PI * 0.25 / 2.0),
                 ("B(1/2, 1/2)", 0.5, 0.5, "pi", PI),
                 ("B(3, 3/2)", 3.0, 1.5, "16/105", 16.0 / 105.0)];
    println!("road 1: the integral, x = sin^2 of an angle, Simpson 2000 panels; road 2: Gamma ratio, Gamma by its own integral");
    let (mut r1, mut r2) = (Vec::new(), Vec::new());
    for &(label, a, b, name, exact) in cases.iter() {
        r1.push(beta_direct(a, b));
        r2.push(beta_gamma(a, b));
        println!("{:16} road 1 {:.9}  road 2 {:.9}  {} = {:.9}", label, r1[r1.len() - 1], r2[r2.len() - 1], name, exact);
    }
    println!("swap the two: B(3, 2) = {:.9}, B(3/2, 3) = {:.9}", beta_gamma(3.0, 2.0), beta_direct(1.5, 3.0));
    let g = gamma(0.5);
    println!("Gamma(1/2) = {:.9}, squared {:.9}; Gamma(5) = {:.9}", g, g.powi(2), gamma(5.0));
    let xs: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    println!("chart x = 0, 0.1, ..., 1");
    println!("  ramp x(1-x)^2:  {}", join(&xs.iter().map(|x| x * (1.0 - x).powi(2)).collect::<Vec<_>>(), 2));
    println!("  arch sqrt(x(1-x)): {}", join(&xs.iter().map(|x| (x * (1.0 - x)).sqrt()).collect::<Vec<_>>(), 2));
    println!("ramp peak at x = 1/3: {:.6}; arch peak at x = 1/2: {:.6}", (1.0 / 3.0) * (2.0f64 / 3.0).powi(2), 0.5);
    let wrong1 = beta_gamma(3.0, 4.0);
    let wrong2 = 2.0 * 6.0 / 120.0;
    let wrong3 = gamma(2.0) * gamma(3.0) / gamma(4.0);
    println!("mistake 1, minus 1 dropped, x^2(1-x)^3: B(3, 4) = {:.6}, not {:.6}", wrong1, 1.0 / 12.0);
    println!("mistake 2, factorials with no shift: 2!3!/5! = {:.6}", wrong2);
    println!("mistake 3, stretch factor u dropped: Gamma(2)Gamma(3)/Gamma(4) = {:.6}", wrong3);
    let eps = [0.1, 0.01, 0.001];
    let tails: Vec<f64> = eps.iter().map(|e| simpson(&|x: f64| 1.0 / (1.0 - x), 0.0, 1.0 - e, 20000)).collect();
    println!("b = 0: area under 1/(1-x) from 0 to 1-e, e = 0.1, 0.01, 0.001: {}", join(&tails, 4));
    assert!(r1.iter().zip(&r2).all(|(p, q)| (p - q).abs() < 1e-9));                  // two roads agree
    assert!(r1.iter().zip(cases.iter()).all(|(p, c)| (p - c.4).abs() < 1e-9));       // road 1 hits each closed form
    assert!((g - PI.sqrt()).abs() < 1e-9 && (gamma(5.0) - 24.0).abs() < 1e-9);       // Gamma from its integral
    assert!(tails.iter().zip(eps.iter()).all(|(v, e)| (v - (1.0 / e).ln()).abs() < 1e-4));
    println!("ALL CHECKS PASS");
}
