// Phragmen-Lindelof -- the same check as the Python, in Rust.  No crates.
// Strip |Im z| < pi/2, f(z) = exp(exp z).  Road one: closed forms.  Road two: complex
// arithmetic written out here and grid searches.  Then the damper of the proof, the
// half-plane, and the three-lines bound for exp(z^2) on the strip 0 <= Re z <= 1.
use std::f64::consts::{E, PI};
const H: f64 = PI / 2.0;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(z: C) -> C { sc(c(z.im.cos(), z.im.sin()), z.re.exp()) }
fn f(z: C) -> C { cexp(cexp(z)) }                          // exp(exp z), built by hand
fn top(h: &dyn Fn(C) -> C, pts: &[C]) -> (f64, C) {       // (largest |h|, where)
    let mut b = (md(h(pts[0])), pts[0]);
    for &z in pts { let m = md(h(z)); if m > b.0 { b = (m, z); } }
    b
}
fn row(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let edges: Vec<C> = (-300..=300).flat_map(|k| [c(k as f64 / 100.0, H), c(k as f64 / 100.0, -H)]).collect();
    let e_max = top(&f, &edges).0;
    let f1 = md(f(c(1.0, 0.0)));
    println!("strip |Im z| < pi/2, f = exp(exp z): largest |f| on both edges, x from -3 to 3: {:.6}", e_max);
    let t = cexp(c(1.0, H));
    println!("exp z on the top edge at x = 1: {:.6} + {:.6}i", t.re, t.im);
    println!("f(1): by hand {:.6}; closed form e^e {:.6}", f1, E.exp());
    let xs: Vec<f64> = (-4..3).map(|k| k as f64 / 2.0).collect();
    println!("chart, x: {}", row(&xs, 1));
    println!("chart, |f(x)| on the centre line: {}", row(&xs.iter().map(|&x| md(f(c(x, 0.0)))).collect::<Vec<_>>(), 2));
    println!("growth: ln ln |f(x)| at x = 1, 2, 3: {}", row(&[1.0, 2.0, 3.0].map(|x| md(f(c(x, 0.0))).ln().ln()), 6));
    let (a, cc, b, eps) = (1.0f64, 0.5f64, 0.75f64, 0.01f64);
    let dl = (b * H).cos();
    println!("damper, A = 1, c = 0.5, b = 0.75, eps = 0.01: delta = cos(b pi/2) = {:.6}", dl);
    let r_closed = (a / (eps * dl)).ln() / (b - cc);
    let mut x = 0.0f64;
    while a * (cc * x).exp() - 2.0 * eps * dl * (b * x).cosh() > 0.0 { x += 0.001; }
    println!("end walls under control from |x| = R: closed form {:.2}; scan {:.2}", r_closed, x);
    println!("bound at z = 1 once the damper comes off, eps = 0.01, 0.001, 0.0001: {}",
             row(&[0.01, 0.001, 0.0001].map(|e: f64| (2.0 * e * b.cosh()).exp()), 6));
    let hd = |z: C| { let (p, q) = (cexp(sc(z, b)), cexp(sc(z, -b))); cexp(sc(c(p.re + q.re, p.im + q.im), -eps)) }; // the damper h
    let hp = md(cexp(c(E, 0.0)));
    println!("half-plane: |e^z| at z = e is {:.6}, the same as |f(1)|", hp);
    let g3 = |z: C| cexp(mul(z, z));                        // three lines: exp(z^2)
    let mm = |t: f64| top(&g3, &(-3000..=3000).map(|k| c(t, k as f64 / 1000.0)).collect::<Vec<_>>()).0;
    let (m0, m1) = (mm(0.0), mm(1.0));
    let ths: Vec<f64> = (0..5).map(|k| k as f64 / 4.0).collect();
    let grid: Vec<f64> = ths.iter().map(|&t| mm(t)).collect();
    let bound: Vec<f64> = ths.iter().map(|&t| m0.powf(1.0 - t) * m1.powf(t)).collect();
    println!("three lines, exp(z^2) on 0 <= Re z <= 1: M0 = {:.6}, M1 = {:.6}", m0, m1);
    println!("chart, theta: {}", row(&ths, 2));
    println!("chart, M(theta) by grid search: {} | closed form e^(theta^2): {}", row(&grid, 3),
             row(&ths.iter().map(|t| (t * t).exp()).collect::<Vec<_>>(), 3));
    println!("chart, bound M0^(1-theta) M1^theta: {}", row(&bound, 3));
    let g = |z: C| mul(mul(g3(z), cexp(sc(c(z.re - 1.0, z.im), m0.ln()))), cexp(sc(z, -m1.ln())));  // f M0^(z-1) M1^(-z)
    let rect: Vec<C> = (0..=100).flat_map(|k| (-300..=300).map(move |y| c(k as f64 / 100.0, y as f64 / 100.0))).collect();
    let (gm, gz) = top(&g, &rect);
    let on_edge = gz.re == 0.0 || gz.re == 1.0;
    println!("g = exp(z^2 - z): largest |g| on the grid {:.6}, on an edge: {}; |g(1/2)| = {:.6}",
             gm, if on_edge { "yes" } else { "no" }, md(g(c(0.5, 0.0))));
    println!("break 1, no growth limit: edges {:.6}, f(1) = {:.6}", e_max, f1);
    let f2 = |z: C| f(sc(z, 0.5));
    let wide: Vec<C> = (-300..=300).flat_map(|k| [c(k as f64 / 100.0, 2.0 * H), c(k as f64 / 100.0, -2.0 * H)]).collect();
    println!("break 2, strip twice as wide, exp(exp(z/2)) on |Im z| < pi: edges {:.6}, at z = 2 {:.6}",
             top(&f2, &wide).0, md(f2(c(2.0, 0.0))));
    let box2: Vec<C> = (-200..=200).flat_map(|k| (-50..=50).map(move |y| c(k as f64 / 100.0, y as f64 * H / 50.0))).collect();
    let (rm, rz) = top(&f, &box2);
    println!("break 3, rectangle |x| <= 2: largest |f| {:.6} at x = {:.0}, y = {:.0}, an end wall", rm, rz.re, rz.im.abs());
    println!("break 4, arithmetic mean of M0, M1: {:.6}, against the geometric {:.6}; true M(1/2) {:.6}", (m0 + m1) / 2.0, bound[2], grid[2]);
    assert!((e_max - 1.0).abs() < 1e-12 && (f1 - E.exp()).abs() < 1e-9);            // edges; e^e
    assert!(grid.iter().zip(&bound).zip(&ths).all(|((p, q), t)| (p - (t * t).exp()).abs() < 1e-9 && (q - t.exp()).abs() < 1e-9 && *p <= q + 1e-12));
    assert!((x - r_closed).abs() < 0.01 && (dl - (PI / 8.0).sin()).abs() < 1e-12);     // R two ways; delta = sin(pi/8)
    assert!((-300..=300).all(|k| (-10..=10).all(|y| md(hd(c(k as f64 / 10.0, y as f64 * H / 10.0)))
        <= (-eps * dl * (b * (k as f64 / 10.0).abs()).exp()).exp() + 1e-15)));              // Step 1's damper bound
    assert!(gm <= 1.0 + 1e-12 && on_edge && (rm - E.powi(2).exp()).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
