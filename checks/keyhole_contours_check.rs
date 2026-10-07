// The keyhole contour -- the same check as the Python, in Rust.  No crates.
// Road one: the real integral of x^(a-1)/(1+x), summed after x = e^u.
// Road two: a trapezoid sum round the keyhole, against 2 pi i times the residue at -1.
// The branch of z^(a-1) is built by hand, argument in [0, 2 pi]: no library power of z.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn e(t: f64) -> C { c(t.cos(), t.sin()) } // e^(it)
fn power(rho: f64, th: f64, a: f64) -> C { sc(e((a - 1.0) * th), rho.powf(a - 1.0)) } // z^(a-1) at z = rho e^(i th)
fn trap(g: &dyn Fn(f64) -> C, lo: f64, hi: f64, n: usize) -> C { // trapezoid sum, n steps
    let h = (hi - lo) / n as f64;
    let mut s = sc(add(g(lo), g(hi)), 0.5);
    for j in 1..n { s = add(s, g(lo + j as f64 * h)) }
    sc(s, h)
}
fn real_road(a: f64) -> f64 { trap(&|u: f64| c((a * u).exp() / (1.0 + u.exp()), 0.0), -80.0, 80.0, 4000).re }
fn bank(a: f64, th: f64, r: f64, big: f64, n: usize) -> C { // z = x e^(i th), x = e^u from r to R
    trap(&|u: f64| sc(power(u.exp(), th, a), u.exp() / (1.0 + u.exp())), r.ln(), big.ln(), n)
}
fn circle(a: f64, rho: f64, t0: f64, t1: f64, n: usize) -> C { // z = rho e^(it), dz = i z dt
    trap(&|t: f64| div(mul(mul(power(rho, t, a), c(0.0, rho)), e(t)), add(c(1.0, 0.0), sc(e(t), rho))), t0, t1, n)
}
fn keyhole(a: f64, r: f64, big: f64, n: usize, low: f64) -> [C; 4] { // top bank out, round, bottom bank in, back round 0
    [bank(a, 0.0, r, big, n), sc(bank(a, low, r, big, n), -1.0), circle(a, big, 0.0, 2.0 * PI, n), circle(a, r, 2.0 * PI, 0.0, n)]
}
fn total(p: [C; 4]) -> C { add(add(p[0], p[1]), add(p[2], p[3])) }
fn res(a: f64) -> C { power(1.0, PI, a) } // (z + 1) F(z) = z^(a-1), at z = -1 = e^(i pi)
fn solve(a: f64) -> C { div(mul(c(0.0, 2.0 * PI), res(a)), sub(c(1.0, 0.0), e(2.0 * PI * a))) }
fn main() {
    let tpi = c(0.0, 2.0 * PI);
    for a in [0.25, 0.5, 0.75] {
        println!("a = {:.2}: pi/sin(pi a) = {:.6}; real line, x = e^u: {:.6}; residue route: {}", a, PI / (PI * a).sin(), real_road(a), show(solve(a)));
        assert!((real_road(a) - PI / (PI * a).sin()).abs() < 1e-8 && abs(sub(solve(a), c(real_road(a), 0.0))) < 1e-8);
    }
    println!("a = 0.50: residue at -1 {}; bottom-bank factor e^(2 pi i a) {}", show(res(0.5)), show(e(PI)));
    let p = keyhole(0.5, 0.5, 4.0, 4000, 2.0 * PI);
    println!("keyhole a = 0.50, r = 0.5, R = 4: top bank {}; bottom bank {}", show(p[0]), show(p[1]));
    println!("  big circle {}; small circle {}", show(p[2]), show(p[3]));
    println!("  four pieces {}; 2 pi i x residue {}", show(total(p)), show(mul(tpi, res(0.5))));
    let q = keyhole(0.25, 0.5, 4.0, 4000, 2.0 * PI);
    println!("keyhole a = 0.25: four pieces {}; 2 pi i x residue {}", show(total(q)), show(mul(tpi, res(0.25))));
    let errs: Vec<String> = [250, 1000, 4000].iter().map(|&n| format!("{:.9}", abs(sub(total(keyhole(0.5, 0.5, 4.0, n, 2.0 * PI)), mul(tpi, res(0.5)))))).collect();
    println!("keyhole error at n = 250, 1000, 4000 steps: {}", errs.join(", "));
    assert!(abs(sub(total(p), mul(tpi, res(0.5)))) < 1e-5 && abs(sub(total(q), mul(tpi, res(0.25)))) < 1e-5);
    let big: Vec<(f64, f64)> = [4.0f64, 64.0, 1024.0].iter().map(|&r| (abs(circle(0.5, r, 0.0, 2.0 * PI, 4000)), 2.0 * PI * r.sqrt() / (r - 1.0))).collect();
    let small: Vec<(f64, f64)> = [0.5f64, 1.0 / 64.0, 1.0 / 1024.0].iter().map(|&r| (abs(circle(0.5, r, 2.0 * PI, 0.0, 4000)), 2.0 * PI * r.sqrt() / (1.0 - r))).collect();
    let fmt = |v: &Vec<(f64, f64)>| v.iter().map(|(s, b)| format!("{:.6} ({:.6})", s, b)).collect::<Vec<_>>().join("; ");
    println!("big circle size (bound) at R = 4, 64, 1024: {}", fmt(&big));
    println!("small circle size (bound) at r = 1/2, 1/64, 1/1024: {}", fmt(&small));
    assert!(big.iter().chain(small.iter()).all(|(s, b)| s <= b) && big[2].0 < big[1].0 && big[1].0 < big[0].0 && small[2].0 < small[1].0 && small[1].0 < small[0].0);
    println!("mistake, bottom bank given the top value: four pieces {}, not 6.283185 + 0.000000i", show(total(keyhole(0.5, 0.5, 4.0, 4000, 0.0))));
    println!("mistake, arg(-1) taken as -pi: a = 0.50 gives {}", show(div(mul(tpi, power(1.0, -PI, 0.5)), sub(c(1.0, 0.0), e(PI)))));
    println!("mistake, bottom bank not reversed: a = 0.25 gives {}", show(div(mul(tpi, res(0.25)), add(c(1.0, 0.0), e(PI / 2.0)))));
    println!("a = 1, no decay: big circle {} at R = 4, {} at R = 64", show(circle(1.0, 4.0, 0.0, 2.0 * PI, 4000)), show(circle(1.0, 64.0, 0.0, 2.0 * PI, 4000)));
    let (d, ox, oy, s) = (0.08f64, 180.0, 120.0, 25.0); // figure: 0 at (180, 120), 25 units per 1, r = 0.5, R = 4
    let pt = |rho: f64, t: f64| format!("({:.2}, {:.2})", ox + s * rho * t.cos(), oy - s * rho * t.sin());
    println!("figure, top bank {} to {}, bottom {} to {}, pole {}", pt(0.5, d), pt(4.0, d), pt(4.0, -d), pt(0.5, -d), pt(1.0, PI));
    println!("ALL CHECKS PASS");
}
