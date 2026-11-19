// De Rham cohomology of the punctured plane -- the same check as the Python, in Rust.
// No crates.  Three roads to one answer, H^0 = 1, H^1 = 1, H^2 = 0:
//   road 1: algebraic de Rham of C[z, 1/z], ranks by exact integer elimination
//   road 2: loop integrals of the angle form, by Simpson's rule written out
//   road 3: two local angle potentials on slit planes, and the jump between them
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Frac { n: i128, d: i128 }           // a fraction in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i128, d: i128) -> Frac {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Frac { n: s * n / g, d: s * d / g }
}
fn mul(a: Frac, b: Frac) -> Frac { frac(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn add(a: Frac, b: Frac) -> Frac { frac(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn fstr(a: Frac) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

fn rank(m0: &Vec<Vec<i128>>, p: i128) -> usize {   // fraction-free elimination; p = 0 means over Q
    let red = |v: i128| if p != 0 { v.rem_euclid(p) } else { v };
    let mut m: Vec<Vec<i128>> = m0.iter().map(|row| row.iter().map(|&v| red(v)).collect()).collect();
    let mut r = 0;
    for c in 0..m[0].len() {
        let Some(piv) = (r..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, piv);
        for i in 0..m.len() {
            if i != r && m[i][c] != 0 {
                let (a, b) = (m[r][c], m[i][c]);
                let row: Vec<i128> = m[i].iter().zip(m[r].iter()).map(|(&x, &y)| red(a.checked_mul(x).unwrap() - b.checked_mul(y).unwrap())).collect();
                m[i] = row;
            }
        }
        r += 1;
    }
    r
}

fn de_rham(lo: i128, hi: i128, p: i128) -> (usize, usize, usize, Vec<i128>) {
    let src: Vec<i128> = (lo..=hi).collect();
    let tgt: Vec<i128> = ((if lo != 0 { lo - 1 } else { 0 })..hi).collect();
    let d: Vec<Vec<i128>> = tgt.iter().map(|&m| src.iter().map(|&n| if m == n - 1 { n } else { 0 }).collect()).collect();
    let rk = rank(&d, p);
    let missed: Vec<i128> = tgt.iter().copied().filter(|&m| {
        let aug: Vec<Vec<i128>> = d.iter().zip(tgt.iter())
            .map(|(row, &t)| { let mut r = row.clone(); r.push(if t == m { 1 } else { 0 }); r }).collect();
        rank(&aug, p) > rk
    }).collect();
    (rk, src.len() - rk, tgt.len() - rk, missed)
}

fn show(poly: &Vec<(i128, Frac)>) -> String {      // leading term first
    let mut v = poly.clone();
    v.sort_by(|a, b| b.0.cmp(&a.0));
    let mut out = String::new();
    for (e, c) in v {
        let neg = c.n < 0;
        let s = if neg { "-" } else if out.is_empty() { "" } else { "+" };
        out += &(if out.is_empty() { s.to_string() } else { format!(" {} ", s) });
        let a = Frac { n: c.n.abs(), d: c.d };
        if !(a == frac(1, 1) && e != 0) { out += &fstr(a) }
        if e == 1 { out += "z" } else if e != 0 { out += &format!("z^{}", e) }
    }
    out
}

fn simpson(f: &dyn Fn(f64) -> f64) -> f64 {
    let n = 2000;
    let h = 1.0 / n as f64;
    let w = |k: i32| if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=n).fold(0.0, |s, k| s + f(k as f64 * h) * w(k))
}

type Form<'a> = &'a dyn Fn(f64, f64) -> (f64, f64);
fn along(form: Form, path: &dyn Fn(f64) -> (f64, f64), vel: &dyn Fn(f64) -> (f64, f64)) -> f64 {
    simpson(&|t| { let ((x, y), (u, v)) = (path(t), vel(t)); let (p, q) = form(x, y); p * u + q * v })
}
fn circle(form: Form, cx: f64, cy: f64, r: f64, turns: f64) -> f64 {
    let w = TAU * turns;
    along(form, &|t| (cx + r * (w * t).cos(), cy + r * (w * t).sin()),
          &|t| (-r * w * (w * t).sin(), r * w * (w * t).cos()))
}
fn square(form: Form, cx: f64, cy: f64, s: f64) -> f64 {
    let c = [(cx + s, cy - s), (cx + s, cy + s), (cx - s, cy + s), (cx - s, cy - s)];
    (0..4).fold(0.0, |total, i| { let ((ax, ay), (bx, by)) = (c[i], c[(i + 1) % 4]);
        total + along(form, &|t| (ax + t * (bx - ax), ay + t * (by - ay)), &|_| (bx - ax, by - ay)) })
}
fn omega(x: f64, y: f64) -> (f64, f64) { let r2 = x * x + y * y; (-y / r2, x / r2) }
fn alpha(x: f64, y: f64) -> (f64, f64) { let r2 = x * x + y * y; ((2.0 * x - 3.0 * y) / r2, (3.0 * x + 2.0 * y) / r2) }
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn theta1(x: f64, y: f64) -> f64 { y.atan2(x) }
fn theta2(x: f64, y: f64) -> f64 { (-y).atan2(-x) + PI }
fn cmul(a: (f64, f64), b: (f64, f64)) -> (f64, f64) { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn cpow(z: (f64, f64), e: i32) -> (f64, f64) {
    let o = (0..e.abs()).fold((1.0, 0.0), |o, _| cmul(o, z));
    if e < 0 { let m = o.0 * o.0 + o.1 * o.1; (o.0 / m, -o.1 / m) } else { o }
}
fn hits(v: &Vec<i128>) -> String { v.iter().map(|m| format!("z^{} dz", m)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (rk, h0, h1, missed) = de_rham(-6, 6, 0);
    println!("road 1, algebra on C[z, 1/z], degrees -6 to 6, exact ranks");
    println!("rank of d over Q: {} of 13; dim H^0 = {}; dim H^1 = {}; not hit: {}", rk, h0, h1, hits(&missed));
    let alg: Vec<(i128, Frac)> = vec![(2, frac(3, 1)), (0, frac(-2, 1)), (-1, frac(5, 1)), (-3, frac(4, 1))];
    let res = alg[2].1;
    let big_f: Vec<(i128, Frac)> = alg.iter().filter(|t| t.0 != -1).map(|&(m, c)| (m + 1, mul(c, frac(1, m + 1)))).collect();
    let mut df: Vec<(i128, Frac)> = big_f.iter().filter(|t| t.0 != 0).map(|&(e, c)| (e - 1, mul(frac(e, 1), c))).collect();
    df.push((-1, add(frac(0, 1), res)));
    let mut sa = alg.clone(); sa.sort_by(|a, b| a.0.cmp(&b.0)); df.sort_by(|a, b| a.0.cmp(&b.0));
    let same = df == sa;
    println!("alpha = ({}) dz = d({}) + {} dz/z: {}", show(&alg), show(&big_f), fstr(res), if same { "yes" } else { "no" });
    let fz = |z: (f64, f64)| alg.iter().fold((0.0, 0.0), |s, &(e, c)| {
        let t = cpow(z, e as i32); let k = c.n as f64 / c.d as f64; (s.0 + k * t.0, s.1 + k * t.1) });
    let integrand = |t: f64| { let z = ((TAU * t).cos(), (TAU * t).sin()); cmul(cmul(fz(z), (0.0, TAU)), z) };
    let zi = (simpson(&|t| integrand(t).0), simpson(&|t| integrand(t).1));
    let resf = res.n as f64 / res.d as f64;
    println!("contour integral of alpha round |z| = 1: {} + {}i; 2 pi x {} = {}", f6(zi.0), f6(zi.1), fstr(res), f6(TAU * resf));
    println!("road 2, loop integrals of omega = (-y dx + x dy)/(x^2 + y^2)");
    let h = 1e-5;
    let qx = (omega(1.0 + h, 2.0).1 - omega(1.0 - h, 2.0).1) / (2.0 * h);
    let py = (omega(1.0, 2.0 + h).0 - omega(1.0, 2.0 - h).0) / (2.0 * h);
    println!("cross rates at (1, 2): dQ/dx = {}, dP/dy = {}", f6(qx), f6(py));
    let loops = [("unit circle, once round", circle(&omega, 0.0, 0.0, 1.0, 1.0)),
                 ("square of half-side 1 round the origin", square(&omega, 0.0, 0.0, 1.0)),
                 ("square of half-side 1 centred at (3, 0)", square(&omega, 3.0, 0.0, 1.0)),
                 ("circle of radius 2, twice round", circle(&omega, 0.0, 0.0, 2.0, 2.0))];
    for (name, v) in loops.iter() { println!("{}: {}", name, f6(*v)) }
    let la = circle(&alpha, 0.0, 0.0, 1.0, 1.0);
    let diff = |x: f64, y: f64| { let (a, w) = (alpha(x, y), omega(x, y)); (a.0 - 3.0 * w.0, a.1 - 3.0 * w.1) };
    let rest = circle(&diff, 0.5, -0.2, 2.0, 1.0);
    let ca = (alpha(1.0 + h, 2.0).1 - alpha(1.0 - h, 2.0).1) / (2.0 * h) - (alpha(1.0, 2.0 + h).0 - alpha(1.0, 2.0 - h).0) / (2.0 * h);
    println!("alpha_real = ((2x - 3y) dx + (3x + 2y) dy)/(x^2 + y^2): curl at (1, 2) {}, loop {}, class c = {}", f6(ca), f6(la), f6(la / TAU));
    println!("alpha_real - 3 omega round a circle of radius 2 at (0.5, -0.2): {}", f6(rest));
    let g = |x: f64, y: f64| { let w = omega(x, y); let k = (x * x + y * y - 1.0) / 2.0; (k * w.0, k * w.1) };
    let curl = (g(1.0 + h, 2.0).1 - g(1.0 - h, 2.0).1) / (2.0 * h) - (g(1.0, 2.0 + h).0 - g(1.0, 2.0 - h).0) / (2.0 * h);
    println!("H^2: dx dy = d(((x^2 + y^2 - 1)/2) omega); curl at (1, 2) = {}", f6(curl));
    println!("road 3, two local angles, slit along the negative and the positive x-axis");
    let ths: [fn(f64, f64) -> f64; 2] = [theta1, theta2];
    let gap = ths.iter().map(|th| ((th(1.0 + h, 2.0) - th(1.0 - h, 2.0)) / (2.0 * h) - omega(1.0, 2.0).0).abs()).fold(0.0, f64::max);
    let jump = theta2(0.0, -1.0) - theta1(0.0, -1.0);
    println!("d(theta) = omega at (1, 2): {}; theta2 - theta1 at (0, 1): {}, at (0, -1): {}",
             if gap < 1e-8 { "yes" } else { "no" }, f6(theta2(0.0, 1.0) - theta1(0.0, 1.0)), f6(jump));
    let mu_i = 4.0 * PI * 1e-7 * 10.0 * 1e6;                          // mu0 I in microtesla metres
    let wire = |x: f64, y: f64| { let w = omega(x, y); (mu_i / TAU * w.0, mu_i / TAU * w.1) };
    let (c1, c2) = (circle(&wire, 0.0, 0.0, 0.05, 1.0), square(&wire, 0.03, 0.02, 0.1));
    println!("wire, 10 A: B-form = {} omega microtesla m; |B| at 0.05 m = {} microtesla", f6(mu_i / TAU), f6(mu_i / TAU / 0.05));
    println!("clamp loops: circle r 0.05 m {}, square half-side 0.1 m at (0.03, 0.02) {}; current {} A", f6(c1), f6(c2), f6(c2 / mu_i * 10.0));
    let (rk5, h05, h15, missed5) = de_rham(-6, 6, 5);
    let (rkz, h0z, h1z, _) = de_rham(0, 6, 0);
    println!("mistake 1, zero curl so exact: predicted 0.000000, unit circle {}", f6(loops[0].1));
    println!("mistake 2, atan2 as one potential: end - start {}; across the negative x-axis it jumps {}",
             f6(theta1(TAU.cos(), TAU.sin()) - theta1(0f64.cos(), 0f64.sin())), f6(theta1(-1.0, -1e-9) - theta1(-1.0, 1e-9)));
    println!("mistake 3, over F_5: rank {}, dim H^0 = {}, dim H^1 = {}, not hit: {}", rk5, h05, h15, hits(&missed5));
    println!("mistake 4, the whole line C[z], degrees 0 to 6: rank {}, dim H^0 = {}, dim H^1 = {}", rkz, h0z, h1z);
    let (circ, tor, chi): (i64, i64, i64) = (3 - 3, 9 - 27 + 18, 64 - 4 * 16 + 6 * 4);
    println!("Betti counts from Euler counts: punctured plane, circle 3 - 3 = {}, so 1 {} 0; square-lattice torus 9 - 27 + 18 = {}, so 1 {} 1; quartic 64 - 64 + 24 = {}, so 1 0 {} 0 1",
             circ, 1 - circ, tor, 2 - tor, chi, chi - 2);
    assert!(h0 == 1 && h1 == 1 && missed == vec![-1] && same);          // road 1: one class, dz/z
    assert!((zi.1 - TAU * 5.0).abs() < 1e-9 && zi.0.abs() < 1e-9);       // residue against contour
    assert!(loops[..2].iter().all(|l| (l.1 - TAU).abs() < 1e-9) && loops[2].1.abs() < 1e-9);
    assert!((loops[3].1 - 2.0 * TAU).abs() < 1e-9 && (la - 3.0 * TAU).abs() < 1e-9 && rest.abs() < 1e-9 && ca.abs() < 1e-6);
    assert!((jump - loops[0].1).abs() < 1e-9 && gap < 1e-8);              // road 3 against road 2
    assert!((curl - 1.0).abs() < 1e-6 && (c1 - c2).abs() < 1e-9 && (c2 / mu_i * 10.0 - 10.0).abs() < 1e-9);
    assert!(h05 == 3 && missed5 == vec![-6, -1, 4] && h1z == 0);
    println!("ALL CHECKS PASS");
}
