// Schanuel's conjecture, status card: what it says for z = 1 and z = i*pi, the algebra step
// from "e and pi algebraically independent" to "e + pi transcendental", and small searches.
// Rust std only, no crates.  Schanuel is open, so every search here is evidence, not proof.
// Roads: constants by written-out series against the library; relation searches calibrated
// on numbers that do satisfy a relation; g(e + pi) against the expanded P(e, pi) = g(X + Y).
use std::collections::BTreeMap;

fn exp_series(x: f64) -> f64 { // e^x = sum x^k / k!, only +, * and /
    let (mut s, mut t) = (0.0f64, 1.0f64);
    for k in 1..80 { s += t; t = t * x / k as f64; }
    s
}
fn atan_inv(n: f64) -> f64 { // arctan(1/n) = sum (-1)^k / ((2k+1) n^(2k+1))
    let (mut s, mut p, mut k) = (0.0f64, 1.0 / n, 0i32);
    while p > 1e-30 { s += (if k % 2 == 0 { 1.0 } else { -1.0 }) * p / (2 * k + 1) as f64; p = p / (n * n); k += 1; }
    s
}
fn cexp_series(a: f64, b: f64) -> (f64, f64) { // e^(a + bi) by the series, complex product written out
    let (mut sr, mut si, mut tr, mut ti) = (0.0f64, 0.0f64, 1.0f64, 0.0f64);
    for k in 1..80 {
        sr += tr; si += ti;
        let (nr, ni) = ((tr * a - ti * b) / k as f64, (tr * b + ti * a) / k as f64);
        tr = nr; ti = ni;
    }
    (sr, si)
}
// smallest |a z1 + b z2| with whole a, b of size at most 50, not both 0; z = (real, imaginary)
fn lin_min(z1: (f64, f64), z2: (f64, f64)) -> (f64, i64, i64) {
    let mut best: Option<(f64, i64, i64)> = None;
    for a in -50i64..=50 { for b in -50i64..=50 {
        if a == 0 && b == 0 { continue; }
        let (wr, wi) = (a as f64 * z1.0 + b as f64 * z2.0, a as f64 * z1.1 + b as f64 * z2.1);
        let v = (wr * wr + wi * wi).sqrt();
        if best.map_or(true, |q| v < q.0) { best = Some((v, a, b)); }
    } }
    best.unwrap()
}
fn horner(c: &[i64; 4], x: f64) -> f64 { ((c[0] as f64 * x + c[1] as f64) * x + c[2] as f64) * x + c[3] as f64 }
fn best_g(x: f64) -> (f64, [i64; 4]) { // whole-number g of degree <= 3, coefficients of size <= 10
    let mut best: Option<(f64, [i64; 4])> = None;
    for a3 in -10..=10 { for a2 in -10..=10 { for a1 in -10..=10 { for a0 in -10..=10 {
        let c = [a3, a2, a1, a0];
        if c == [0, 0, 0, 0] { continue; }
        let v = horner(&c, x).abs();
        if best.map_or(true, |q| v < q.0) { best = Some((v, c)); }
    } } } }
    best.unwrap()
}
fn text(c: &[i64], names: &[&str]) -> String {
    c.iter().zip(names).filter(|(t, _)| **t != 0).map(|(t, m)| format!("{:+}{}", t, m)).collect::<Vec<_>>().join(" ")
}
fn binom(n: i64, k: i64) -> i64 { (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1)) }
fn best_p(x: f64, y: f64) -> (f64, [i64; 6]) { // P(x, y) of total degree <= 2, coefficients of size <= 4
    let m = [1.0, x, y, x * x, x * y, y * y];
    let mut best: Option<(f64, [i64; 6])> = None;
    let mut c = [-4i64; 6];
    loop {
        if c != [0; 6] {
            let v = (c[0] as f64 * m[0] + c[1] as f64 * m[1] + c[2] as f64 * m[2] + c[3] as f64 * m[3]
                + c[4] as f64 * m[4] + c[5] as f64 * m[5]).abs();
            if best.map_or(true, |q| v < q.0) { best = Some((v, c)); }
        }
        let mut i = 5; // next tuple, last place fastest
        loop { if c[i] < 4 { c[i] += 1; break; } c[i] = -4; if i == 0 { return best.unwrap(); } i -= 1; }
    }
}
fn main() {
    // ---- the constants, two roads each ----
    let (e, pi) = (exp_series(1.0), 16.0 * atan_inv(5.0) - 4.0 * atan_inv(239.0));
    assert!((e - std::f64::consts::E).abs() < 1e-15 && (pi - std::f64::consts::PI).abs() < 1e-15);
    println!("e  = {:.12}   (series; library {:.12})", e, std::f64::consts::E);
    println!("pi = {:.12}   (Machin; library {:.12})", pi, std::f64::consts::PI);
    let (er, ei) = cexp_series(0.0, pi);
    assert!((er + 1.0).abs() < 1e-12 && ei.abs() < 1e-12); // e^(i pi) = -1
    println!("e^(i pi) by the series: real part {:.12}, |imaginary part| below 1e-12", er);
    let epi = exp_series(pi);
    assert!((epi - pi.exp()).abs() < 1e-12 * epi);
    println!("e^pi = {:.9}   e^sqrt2 = {:.9}   e^e = {:.9}", epi, exp_series(2f64.sqrt()), exp_series(e));
    let (s, p) = (e + pi, e * pi);
    println!("e + pi = {:.9}   e * pi = {:.9}", s, p);
    assert!((e * e - s * e + p).abs() < 1e-12 && (pi * pi - s * pi + p).abs() < 1e-12);
    println!("e and pi are the roots of t^2 - (e + pi) t + e pi: both residuals below 1e-12");

    // ---- linear independence over Q ----
    println!("\nsmallest |a z1 + b z2| with whole a, b of size at most 50, not both 0");
    let cases = [("1, sqrt2", (1.0, 0.0), (2f64.sqrt(), 0.0)), ("1, e", (1.0, 0.0), (e, 0.0)),
                 ("1, i pi", (1.0, 0.0), (0.0, pi)), ("pi, i pi", (pi, 0.0), (0.0, pi)), ("1, 2", (1.0, 0.0), (2.0, 0.0))];
    for (name, z1, z2) in cases {
        let (v, a, b) = lin_min(z1, z2);
        println!("  {:9}  {:.9}  at a = {}, b = {}", name, v, a, b);
        if name == "1, 2" { assert!(v == 0.0 && a == -2 * b); } else { assert!(v > 1e-3); }
    }

    // ---- one-variable search ----
    let gn = ["x^3", "x^2", "x", ""];
    println!("\nsmallest |g(x)|, g whole-number, degree <= 3, coefficients of size <= 10");
    let cal = best_g(1.0 + 2f64.sqrt());
    assert!(cal.0 < 1e-12); // calibration: a root is found
    println!("  x = 1 + sqrt2 (algebraic):  below 1e-12, g = {}", text(&cal.1, &gn));
    let (gs, gp) = (best_g(s), best_g(p));
    assert!(gs.0 > 1e-4 && gp.0 > 1e-4);
    println!("  x = e + pi:  {:.9}  g = {}", gs.0, text(&gs.1, &gn));
    println!("  x = e pi:    {:.9}  g = {}", gp.0, text(&gp.1, &gn));

    // ---- the algebra step: P(X, Y) = g(X + Y) is a nonzero polynomial ----
    let c = gs.1;
    let mut pm: BTreeMap<(i64, i64), i64> = BTreeMap::new(); // (i, j) -> coefficient of X^i Y^j
    for (k, &a) in c.iter().enumerate() {
        let n = 3 - k as i64;
        for i in 0..=n { *pm.entry((i, n - i)).or_insert(0) += a * binom(n, i); }
    }
    pm.retain(|_, v| *v != 0);
    let lead = c.iter().position(|&a| a != 0).unwrap();
    let deg = 3 - lead as i64;
    assert!(pm[&(deg, 0)] == c[lead]); // coefficient of X^d equals g's leading coefficient
    let val_p: f64 = pm.iter().map(|(&(i, j), &v)| v as f64 * e.powi(i as i32) * pi.powi(j as i32)).sum();
    let gval = horner(&c, s);
    assert!((val_p - gval).abs() < 1e-9); // two roads to the same number
    println!("\ng(X + Y) for that g: {} nonzero terms, X^{} coefficient {}", pm.len(), deg, pm[&(deg, 0)]);
    println!("  g(e + pi) = {:.9}   P(e, pi) from the expansion = {:.9}", gval, val_p);

    // ---- two-variable search ----
    let pn = ["", "x", "y", "x^2", "xy", "y^2"];
    println!("\nsmallest |P(x, y)|, total degree <= 2, coefficients of size <= 4");
    for (name, x, y) in [("e, e^2", e, e * e), ("e, 1/e", e, 1.0 / e), ("e, pi", e, pi)] {
        let (v, cc) = best_p(x, y);
        if name == "e, pi" { assert!(v > 1e-4); println!("  {:7} {:.9}  P = {}", name, v, text(&cc, &pn)); }
        else { assert!(v < 1e-12); println!("  {:7} below 1e-12  P = {}", name, text(&cc, &pn)); }
    }

    // ---- what breaks, and the generator count ----
    println!("\nwhat breaks");
    assert!((exp_series(2.0) - e * e).abs() < 1e-12);
    println!("z = 1, 2 (dependent): e^2 - e*e below 1e-12, so x^2 - y vanishes at e, e^2: only 1 of 2 forced");
    println!("z = 1, i pi: generators 1, i pi, e, -1; algebraic: 1 and -1; so at most 4 - 2 = 2, never 2n = 4");
    println!("e and 1/e: each transcendental, yet xy - 1 = 0: 'each transcendental' is not 'independent'");

    println!("\ntry changing");
    println!("e^pi - pi = {:.9}", epi - pi);
    println!("z = 1, sqrt3:  smallest |a + b sqrt3| = {:.9}", lin_min((1.0, 0.0), (3f64.sqrt(), 0.0)).0);
    println!("x = e - pi = {:.9}:  smallest |g| = {:.9}", e - pi, best_g(e - pi).0);
    println!("ALL CHECKS PASS");
}
