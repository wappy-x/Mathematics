// Poles on the path -- the same check as the Python, in Rust.  No crates.
// Road one: dent the path round the pole at 0.  The dent keeps -i pi times the
// residue, so PV of e^(ix)/x is i pi and the area under sin x/x is pi.
// Road two: add the humps of sin x/x between multiples of pi, then average the
// partial sums until they settle.  Second example: 1/(x(1+x^2)), PV 0.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn r6(x: f64) -> String { let s = format!("{:.6}", x); if s == "-0.000000" { "0.000000".to_string() } else { s } }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", r6(w.re), if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn simpson(g: &dyn Fn(f64) -> C, a: f64, b: f64, n: usize) -> C { // Simpson's rule on n (even) panels
    let h = (b - a) / n as f64;
    let mut s = add(g(a), g(b));
    for j in 1..n { s = add(s, scale(g(a + j as f64 * h), if j % 2 == 1 { 4.0 } else { 2.0 })) }
    scale(s, h / 3.0)
}
fn arc(f: &dyn Fn(C) -> C, r: f64, start: f64, end: f64) -> C { // z = r e^(it), dz = i z dt
    simpson(&|t: f64| { let z = c(r * t.cos(), r * t.sin()); mul(f(z), c(-z.im, z.re)) }, start, end, 2000)
}
fn wave(z: C) -> C { div(scale(c(z.re.cos(), z.re.sin()), (-z.im).exp()), z) } // e^(iz)/z
fn rat(z: C) -> C { div(c(1.0, 0.0), mul(z, add(c(1.0, 0.0), mul(z, z)))) } // 1/(z(1+z^2))
fn sinc(x: f64) -> C { c(if x == 0.0 { 1.0 } else { x.sin() / x }, 0.0) }
fn big_f(x: f64) -> f64 { x.abs().ln() - 0.5 * (1.0 + x * x).ln() } // antiderivative of 1/(x(1+x^2))
fn res(f: fn(C) -> C, a: C) -> C { // residue by its limit (z - a) f(z), from both sides
    let d = 1e-5;
    scale(sub(scale(f(add(a, c(d, 0.0))), d), scale(f(sub(a, c(d, 0.0))), d)), 0.5)
}
fn main() {
    let (c_wave, c_rat, c_i) = (res(wave, c(0.0, 0.0)), res(rat, c(0.0, 0.0)), res(rat, c(0.0, 1.0)));
    println!("residues by limit: e^(iz)/z at 0 {}; 1/(z(1+z^2)) at 0 {}, at i {}", show(c_wave), show(c_rat), show(c_i));
    for (eps, r) in [(0.5f64, 5.0f64), (0.1, 10.0), (0.01, 20.0)] {
        let (dent, big) = (arc(&wave, eps, PI, 0.0), arc(&wave, r, 0.0, PI));
        let (off, bound) = (abs(add(dent, mul(c(0.0, PI), c_wave))), PI * (eps.exp() - 1.0));
        println!("dent eps = {}: {}, off -pi i by {:.6} (bound {:.6}); big arc R = {}: size {:.6} (Jordan bound {:.6})", eps, show(dent), off, bound, r, abs(big), PI / r);
        assert!(off <= bound && abs(big) <= PI / r);
    }
    let seg = mul(c(0.0, 2.0), simpson(&sinc, 0.1, 10.0, 2000)); // the two real pieces of e^(ix)/x
    let (dent, big) = (arc(&wave, 0.1, PI, 0.0), arc(&wave, 10.0, 0.0, PI));
    let total = add(seg, add(dent, big));
    println!("closed at eps = 0.1, R = 10: segments {} + dent {} + arc {} = {}", show(seg), show(dent), show(big), show(total));
    assert!(abs(total) < 1e-8); // Cauchy: no pole inside, so the loop is 0
    let road1 = PI * c_wave.re; // PV of e^(ix)/x = -(dent limit) = i pi c
    println!("road 1, dent: PV of e^(ix)/x = {}, so area under sin x/x = {:.6}", show(c(0.0, road1)), road1);
    let mut sums: Vec<f64> = Vec::new(); // road 2: the humps, then repeated averaging
    let mut acc = 0.0;
    for k in 0..40 { acc += simpson(&sinc, k as f64 * PI, (k + 1) as f64 * PI, 400).re; sums.push(acc) }
    for _ in 0..20 { sums = sums.windows(2).map(|w| (w[0] + w[1]) / 2.0).collect() }
    let road2 = 2.0 * sums[sums.len() - 1];
    println!("road 2, 40 humps summed and averaged 20 times: {:.6}", road2);
    assert!((road1 - road2).abs() < 1e-9);
    let chart: Vec<String> = (1..=10).map(|k| format!("{:.2}", 2.0 * simpson(&sinc, 0.0, 2.0 * k as f64, 2000).re)).collect();
    println!("chart, area from -X to X, X = 2, 4, ..., 20: {} (pi {:.2})", chart.join(", "), PI);
    for eps in [0.01f64, 0.0001] {
        let (right, left) = (big_f(1.0) - big_f(eps), big_f(-eps) - big_f(-1.0));
        println!("1/(x(1+x^2)), gap eps = {}: right piece {:.6}, left piece {:.6}, sum {}", eps, right, left, r6(right + left));
    }
    let real = big_f(-0.01) - big_f(-10.0) + big_f(10.0) - big_f(0.01); // both real pieces, eps = 0.01, R = 10
    let (dent, big, lp) = (arc(&rat, 0.01, PI, 0.0), arc(&rat, 10.0, 0.0, PI), mul(c(0.0, 2.0 * PI), c_i));
    let closed = add(c(real, 0.0), add(dent, big));
    println!("closed at eps = 0.01, R = 10: real {} + dent {} + arc {} (bound {:.6}) = {}; 2 pi i x Res at i = {}", r6(real), show(dent), show(big), PI / 99.0, show(closed), show(lp));
    assert!(abs(big) <= PI / 99.0 && abs(sub(closed, lp)) < 1e-8); // arc bound pi/(R^2 - 1)
    println!("PV of 1/(x(1+x^2)) = loop - dent limit = {}", show(add(lp, mul(c(0.0, PI), c_rat))));
    println!("mistake, full residue at 0: {:.6}; dent run anticlockwise: {:.6}; left gap 2 eps = 0.001: {:.6} (ln 2 = {:.6})", 2.0 * PI * c_wave.re, -road1, big_f(0.002) - big_f(0.001), 2f64.ln());
    println!("mistake, double pole 1/z^2, dent eps = 0.01: {}, though its residue is 0", show(arc(&|z: C| div(c(1.0, 0.0), mul(z, z)), 0.01, PI, 0.0)));
    let (ox, oy, s) = (180.0, 170.0, 60.0); // figure: 0 at (180, 170), 60 units per 1, R = 2, eps = 0.25
    println!("figure, segments ({:.2}, {:.2})-({:.2}, {:.2}) and ({:.2}, {:.2})-({:.2}, {:.2}); dent top ({:.2}, {:.2}); arc top ({:.2}, {:.2}); i at ({:.2}, {:.2})",
        ox - 2.0 * s, oy, ox - s / 4.0, oy, ox + s / 4.0, oy, ox + 2.0 * s, oy, ox, oy - s / 4.0, ox, oy - 2.0 * s, ox, oy - s);
    println!("ALL CHECKS PASS");
}
