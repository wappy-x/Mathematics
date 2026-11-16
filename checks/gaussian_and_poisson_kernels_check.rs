// Gaussian and Poisson kernels -- the check behind the card.  std only.
// The rail: steel, diffusivity about 0.13 cm^2/s, a weld band 2.5 cm wide left
// 500 K above the rest of the rail at t = 0.  Same roads and same output as the Python.
use std::f64::consts::PI;

const KAP: f64 = 0.13; const A: f64 = 1.25; const U0: f64 = 500.0; // cm^2/s; band half-width, cm; band height u0, K

fn c_hw() -> f64 { (2.0 * 2f64.ln()).sqrt() } // half-width at half-maximum, in standard deviations
fn g(s: f64, x: f64) -> f64 { (-x * x / (2.0 * s * s)).exp() / (s * (2.0 * PI).sqrt()) }
fn p(y: f64, x: f64) -> f64 { y / (PI * (x * x + y * y)) }

fn gauss<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 { // 3-point Gauss-Legendre
    let (h, r) = ((b - a) / m as f64, 0.6f64.sqrt() / 2.0);
    let mut sum = 0.0;
    for j in 0..m {
        let c = a + (j as f64 + 0.5) * h;
        sum += 5.0 / 18.0 * (f(c - r * h) + f(c + r * h)) + 4.0 / 9.0 * f(c);
    }
    h * sum
}

fn erf(z: f64) -> f64 { // positive-term series: (2/sqrt pi) e^(-z^2) sum 2^n z^(2n+1)/(2n+1)!!
    let w = z.abs();
    if w > 6.0 { return if z > 0.0 { 1.0 } else { -1.0 }; } // 1 - erf 6 is below 3e-17
    let (mut term, mut s, mut n) = (w, w, 0.0);
    while term > 1e-17 * s {
        n += 1.0;
        term *= 2.0 * w * w / (2.0 * n + 1.0);
        s += term;
    }
    (if z >= 0.0 { 1.0 } else { -1.0 }) * 2.0 / PI.sqrt() * (-w * w).exp() * s
}

fn heat(x: f64, s: f64) -> f64 {
    U0 / 2.0 * (erf((x + A) / (s * 2f64.sqrt())) - erf((x - A) / (s * 2f64.sqrt())))
}
fn lap(x: f64, y: f64) -> f64 { U0 / PI * (((x + A) / y).atan() - ((x - A) / y).atan()) }
fn conv(k: fn(f64, f64) -> f64, w: f64, x: f64) -> f64 { gauss(|q| U0 * k(w, x - q), -A, A, 200) }
fn mills(s: f64, c: f64) -> f64 { (2.0 / PI).sqrt() * s / c * (-c * c / (2.0 * s * s)).exp() } // Mills bound: bell weight beyond |x| = c
fn cut_g(s: f64, d: f64) -> f64 { d + 40.0 * s * (s / d).min(1.0) } // where tail_g stops integrating
fn tail_g(s: f64, d: f64, m: usize) -> f64 { 2.0 * gauss(|x| g(s, x), d, cut_g(s, d), m) }
fn tail_p(y: f64, d: f64) -> f64 { 2.0 * gauss(|u| y * d / (PI * (d * d + y * y * u * u)), 0.0, 1.0, 200) }
fn pr(r: f64, th: f64) -> f64 { (1.0 - r * r) / (1.0 - 2.0 * r * th.cos() + r * r) / (2.0 * PI) }
fn log10(v: f64) -> f64 { v.ln() / 10f64.ln() }

fn sci(v: f64) -> String { // Python's .4e: two-digit exponent with its sign
    let t = format!("{:.4e}", v);
    let (m, e) = t.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn main() {
    let c = c_hw();
    // ---- both kernels have area 1; the Poisson area arrives slowly ----
    let ga = gauss(|x| g(1.0, x), -12.0, 12.0, 400);
    println!("bell area, s = 1, over |x| < 12: {:.12}; Mills bound on the weight beyond 12: {}",
             ga, sci((2.0 / PI).sqrt() / 12.0 * (-72.0f64).exp()));
    for l in [10.0f64, 100.0, 1000.0] {
        let num = gauss(|x| p(1.0, x), -l, l, 40 * l as usize);
        println!("Poisson area, y = 1, over |x| < {}: {:.6}; (2/pi) atan L {:.6}; missing {:.6}, about 2/(pi L) = {:.6}",
                 l, num, 2.0 / PI * l.atan(), 1.0 - num, 2.0 / (PI * l));
        assert!((num - 2.0 / PI * l.atan()).abs() < 1e-9 && 1.0 - num < 2.0 / (PI * l));
    }
    assert!((ga - 1.0).abs() < 1e-12);

    // ---- the rail: the bell of width s = sqrt(2 kappa t) is the heat kernel ----
    println!("rail: kappa {} cm^2/s, band half-width {} cm, height {:.0} K; half-max half-width = {:.4} standard deviations", KAP, A, U0, c);
    for t in [10.0f64, 100.0] {
        let s = (2.0 * KAP * t).sqrt();
        let y = c * s;
        assert!((g(s, y) - g(s, 0.0) / 2.0).abs() < 1e-12 && (p(y, y) - p(y, 0.0) / 2.0).abs() < 1e-12); // half-maximum at y
        println!("t = {} s: s = {:.4} cm, half-width {:.4} cm; centre by erf {:.4} K, by convolution {:.4} K; Poisson at y = {:.4}: {:.4} K, by convolution {:.4} K",
                 t, s, y, heat(0.0, s), conv(g, s, 0.0), y, lap(0.0, y), conv(p, y, 0.0));
        assert!((heat(0.0, s) - conv(g, s, 0.0)).abs() < 1e-9 && (lap(0.0, y) - conv(p, y, 0.0)).abs() < 1e-9);
    }
    let (s, y) = (2.6f64.sqrt(), c * 2.6f64.sqrt());
    println!("by hand, t = 10 s: a/(s sqrt 2) {:.4}, erf {:.4}; a/y {:.4}, atan {:.4} rad, x 2u0/pi {:.4} K",
             A / (s * 2f64.sqrt()), erf(A / (s * 2f64.sqrt())), A / y, (A / y).atan(), 2.0 * U0 / PI);
    let (s, y, h) = (26f64.sqrt(), c * 26f64.sqrt(), 1e-3);
    let ut = (heat(5.0, (2.0 * KAP * (100.0 + h)).sqrt()) - heat(5.0, (2.0 * KAP * (100.0 - h)).sqrt())) / (2.0 * h);
    let uxx = (heat(5.0 + h, s) - 2.0 * heat(5.0, s) + heat(5.0 - h, s)) / (h * h);
    let vxx = (lap(5.0 + h, y) - 2.0 * lap(5.0, y) + lap(5.0 - h, y)) / (h * h);
    let vyy = (lap(5.0, y + h) - 2.0 * lap(5.0, y) + lap(5.0, y - h)) / (h * h);
    println!("at x = 5 cm, t = 100 s: u_t {:.6}, kappa u_xx {:.6} K/s; Poisson v_xx {:.6}, -v_yy {:.6} K/cm^2",
             ut, KAP * uxx, vxx, -vyy);
    assert!((ut - KAP * uxx).abs() < 1e-5 && (vxx + vyy).abs() < 1e-5);

    // ---- approximate identity: weight beyond the band edge, and the centre's error ----
    for (t, tl) in [(0.01f64, "0.01"), (0.1, "0.1"), (1.0, "1")] {
        let s = (2.0 * KAP * t).sqrt();
        let y = c * s;
        let z = A / s;
        let (g1, g2, pp) = (tail_g(s, A, 400), tail_g(s, A, 800), tail_p(y, A));
        let lo = 2.0 * (-z * z / 2.0).exp() / (2.0 * PI).sqrt() * (1.0 / z - 1.0 / z.powi(3));
        let up = 2.0 * (-z * z / 2.0).exp() / (2.0 * PI).sqrt() / z;
        println!("t = {:>5} s, s {:.4}, y {:.4} cm: bell beyond {} cm {} (Mills {} to {}); Poisson {:.6}, (2/pi) atan(y/a) {:.6}, 2y/(pi a) {:.6}",
                 tl, s, y, A, sci(g2), sci(lo), sci(up), pp, 2.0 / PI * (y / A).atan(), 2.0 * y / (PI * A));
        println!("      centre error: bell {} K, Poisson {:.4} K; at the edge x = a: bell {:.4} K, Poisson {:.4} K",
                 sci(U0 * g2), U0 * pp, heat(A, s), lap(A, y));
        println!("      bell integral cut at {:.4} cm; Mills bound on the weight beyond the cut {}", cut_g(s, A), sci(mills(s, cut_g(s, A))));
        assert!((g1 - g2).abs() < 1e-6 * g2 && lo < g2 && g2 < up && g2 - lo < 3.0 * up / z.powi(4)); // next Mills term
        assert!((pp - 2.0 / PI * (y / A).atan()).abs() < 1e-12 && (heat(0.0, s) - U0 * (1.0 - g2)).abs() < 1e-8);
    }

    // ---- the far rail at t = 100 s: bell against Poisson of the same half-width ----
    let (s, y) = (26f64.sqrt(), c * 26f64.sqrt());
    for x in [0.0f64, 10.0, 20.0, 30.0, 50.0] {
        let far = if x > 0.0 { format!(", far-field 2a u0 y/(pi x^2) {:.4} K", 2.0 * A * U0 * y / (PI * x * x)) } else { String::new() };
        println!("x = {:>2} cm: bell {} K, Poisson {:.4} K{}", x, sci(conv(g, s, x)), lap(x, y), far);
    }
    assert!((lap(50.0, y) - 2.0 * A * U0 * y / (PI * 2500.0)).abs() < 0.02 * lap(50.0, y) && conv(g, s, 30.0) < 1e-5);

    // ---- widths add: bells by variance (3-4-5), Poisson kernels by height ----
    let gg = gauss(|q| g(3.0, q) * g(4.0, -q), -60.0, 60.0, 400);
    let pp = gauss(|th: f64| p(3.0, 5.0 * th.tan()) * p(4.0, -5.0 * th.tan()) * 5.0 / th.cos().powi(2), -PI / 2.0, PI / 2.0, 400);
    println!("G_3 * G_4 at 0 over |q| < 60 (beyond: below G_3(0) x Mills(4, 60) = {}): {:.9}; G_5(0) {:.9}.  P_3 * P_4 at 0: {:.9}; P_7(0) {:.9}",
             sci(g(3.0, 0.0) * mills(4.0, 60.0)), gg, g(5.0, 0.0), pp, p(7.0, 0.0));
    assert!((gg - g(5.0, 0.0)).abs() < 1e-12 && (pp - p(7.0, 0.0)).abs() < 1e-12);
    let inv = 2.0 * gauss(|xi: f64| (-2.0 * PI * xi).exp() * (4.0 * PI * xi).cos(), 0.0, 10.0, 1000); // y = 1, x = 2
    println!("inverse transform of e^(-2 pi |xi|) at x = 2 over |xi| < 10 (beyond: below e^(-20 pi)/pi = {}): {:.9}; P_1(2) = {:.9}",
             sci((-20.0 * PI).exp() / PI), inv, p(1.0, 2.0));
    assert!((inv - p(1.0, 2.0)).abs() < 1e-12);
    let (s, y) = (2.6f64.sqrt(), c * 2.6f64.sqrt());
    println!("t = 10 s, detail 0.5 cycles/cm kept: bell {}, Poisson {}",
             sci((-2.0 * PI * PI * s * s * 0.25).exp()), sci((-2.0 * PI * y * 0.5).exp()));

    // ---- the disc: near the rim, (1/2pi) P_r is the half-plane kernel at height 1 - r ----
    let ths = [0.0f64, 0.01, 0.03];
    let dv: Vec<String> = ths.iter().map(|&th| format!("{:.4}", pr(0.99, th))).collect();
    let hv: Vec<String> = ths.iter().map(|&th| format!("{:.4}", p(0.01, th))).collect();
    println!("r = 0.99 at angle 0, 0.01, 0.03 rad: disc {} ; half-plane {}", dv.join(" "), hv.join(" "));
    for (r, rl) in [(0.9f64, "0.9"), (0.99, "0.99"), (0.999, "0.999")] {
        let far = 2.0 * gauss(|th| pr(r, th), 0.5, PI, 400);
        let hp = 2.0 / PI * ((1.0 - r) / 0.5).atan();
        println!("r = {}: disc weight beyond 0.5 rad {:.6}; half-plane (2/pi) atan((1-r)/0.5) {:.6}", rl, far, hp);
        assert!(far < 3.0 * (1.0 - r) && (far / hp - 1.0).abs() < 0.25);
    }

    // ---- what breaks ----
    let s = 2.6f64.sqrt();
    println!("break, width sqrt(kappa t) at t = 10 s: centre {:.4} K, not {:.4} K", heat(0.0, 1.3f64.sqrt()), heat(0.0, s));
    println!("break, drop the 1/s: area {:.4}, centre {:.4} K", s, s * heat(0.0, s));
    for l in [10.0f64, 100.0, 1000.0] {
        let pa = gauss(|x: f64| x.abs() * p(1.0, x), -l, l, 40 * l as usize);
        let pv = gauss(|x| x * x * p(1.0, x), -l, l, 40 * l as usize);
        println!("break, Poisson of |x| over |x| < {}: {:.4}, ln(1+L^2)/pi {:.4}; second moment {:.2}",
                 l, pa, (1.0 + l * l).ln() / PI, pv);
        assert!((pa - (1.0 + l * l).ln() / PI).abs() < 1e-8 && (pv - 2.0 / PI * (l - l.atan())).abs() < 1e-6);
    }
    println!("bell of s = 1 on |x|: {:.4}, sqrt(2/pi) {:.4}", gauss(|x: f64| x.abs() * g(1.0, x), 0.0, 12.0, 400) * 2.0, (2.0 / PI).sqrt());

    // ---- chart points ----
    let (s, y) = (2.6f64.sqrt(), c * 2.6f64.sqrt());
    let xs: Vec<String> = (0..11).map(|x| format!("{}", x)).collect();
    let hb: Vec<String> = (0..11).map(|x| format!("{:.1}", heat(x as f64, s))).collect();
    let hp: Vec<String> = (0..11).map(|x| format!("{:.1}", lap(x as f64, y))).collect();
    println!("chart x: {}", xs.join(" "));
    println!("chart bell t = 10 s: {}", hb.join(" "));
    println!("chart Poisson y = {:.4}: {}", y, hp.join(" "));
    let sg = 1.0 / c;
    let tb: Vec<String> = (1..11).map(|d| format!("{:.1}", log10(tail_g(sg, d as f64, 400)))).collect();
    let tp: Vec<String> = (1..11).map(|d| format!("{:.2}", log10(tail_p(1.0, d as f64)))).collect();
    println!("chart log10 tail bell: {}", tb.join(" "));
    println!("chart log10 tail Poisson: {}", tp.join(" "));
    let worst = (1..11).map(|d| mills(sg, cut_g(sg, d as f64)) / tail_g(sg, d as f64, 400)).fold(0.0, f64::max);
    println!("chart bell tails cut at d + 40 s min(1, s/d): Mills share beyond the cut at most {}", sci(worst));
    println!("ALL CHECKS PASS");
}
