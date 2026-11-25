// Stationary phase: the check behind the card. Standard library only.
// Bessel functions are written out twice: as the power series and as the
// defining angle integral. Every other integral is Simpson's rule written out.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for k in 1..n {
        acc += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    (f(a) + f(b) + acc) * h / 3.0
}

fn j_series(n: i32, r: f64) -> f64 {
    let mut fact = 1.0;
    for k in 1..=n { fact *= k as f64; }
    let (mut s, mut term) = (0.0, (r / 2.0).powi(n) / fact);
    for k in 1..=80 {
        s += term;
        term *= -(r / 2.0).powi(2) / (k as f64 * (k + n) as f64);
    }
    s
}

fn j_angle(n: i32, r: f64) -> f64 {
    let m = 2 * (r as usize) + 80;
    let mut s = 0.0;
    for k in 0..m {
        let t = 2.0 * PI * k as f64 / m as f64;
        s += (n as f64 * t - r * t.sin()).cos();
    }
    s / m as f64
}

fn lead(n: i32, r: f64) -> f64 {
    (2.0 / (PI * r)).sqrt() * (r - n as f64 * PI / 2.0 - PI / 4.0).cos()
}

fn f6(x: f64) -> String { format!("{:.6}", x) }

fn sci3(x: f64) -> String { // Python's {:.3e}: two-digit exponent with a sign
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn osc(phi: &dyn Fn(f64) -> f64, a: f64, b: f64, lam: f64, n: usize) -> f64 {
    let c = simpson(&|x| (lam * phi(x)).cos(), a, b, n);
    let s = simpson(&|x| (lam * phi(x)).sin(), a, b, n);
    c.hypot(s)
}

fn main() {
    // ---- the example: J0(10) ----
    let r = 10.0;
    let (js, ja) = (j_series(0, r), j_angle(0, r));
    let jsimp = simpson(&|t: f64| (r * t.sin()).cos(), 0.0, PI, 20000) / PI;
    let (amp, u) = ((2.0 / (PI * r)).sqrt(), r - PI / 4.0);
    println!("J0(10): series {}, angle integral {}, Simpson on [0, pi] {}", f6(js), f6(ja), f6(jsimp));
    println!("leading term: sqrt(2/(pi r)) {}, r - pi/4 {}, cos {}, product {}", f6(amp), f6(u), f6(u.cos()), f6(lead(0, r)));
    println!("to four places: leading {:.4}, true {:.4}", lead(0, r), ja);
    println!("dropped pi/4: {}; wrong sign of the curvature, cos(r + pi/4): {}", f6(amp * r.cos()), f6(amp * (r + PI / 4.0).cos()));
    assert!((js - ja).abs() < 1e-12 && (jsimp - ja).abs() < 1e-10);
    // ---- the gap shrinks like r^(-3/2) ----
    for &r in &[10.0f64, 100.0, 1000.0] {
        let j = j_angle(0, r);
        let gap = j - lead(0, r);
        let nxt = (2.0 / (PI * r)).sqrt() * (r - PI / 4.0).sin() / (8.0 * r);
        println!("r={}: J0 {:.9}, leading {:.9}, gap {}, next term sin(u)/(8r) {}, r^1.5 |gap| {:.4}",
                 r, j, lead(0, r), sci3(gap), sci3(nxt), r.powf(1.5) * gap.abs());
        assert!(gap.abs() <= 1.01 * (2.0 / PI).sqrt() / 8.0 * r.powf(-1.5) + 0.1 * r.powf(-2.5));
        assert!((gap - nxt).abs() < 0.2 * r.powf(-2.5));
    }
    println!("ceiling on r^1.5 |gap| for large r: sqrt(2/pi)/8 = {:.4}", (2.0 / PI).sqrt() / 8.0);
    assert!((j_angle(0, 1000.0) - simpson(&|t: f64| (1000.0 * t.sin()).cos(), 0.0, PI, 200000) / PI).abs() < 1e-10);
    println!("J1(10): series {}, angle integral {}, leading {}", f6(j_series(1, 10.0)), f6(j_angle(1, 10.0)), f6(lead(1, 10.0)));
    println!("J1(1000): angle integral {}, leading {}", f6(j_angle(1, 1000.0)), f6(lead(1, 1000.0)));
    assert!((j_series(1, 10.0) - j_angle(1, 10.0)).abs() < 1e-12);

    // ---- van der Corput ----
    for &lam in &[10.0f64, 100.0, 1000.0] {
        let i1 = osc(&|x| x + x * x, 0.0, 1.0, lam, 40000);
        assert!((i1 - osc(&|x| x + x * x, 0.0, 1.0, lam, 20000)).abs() < 1e-9 && i1 <= 3.0 / lam);
        let i2 = osc(&|x| x * x / 2.0, -1.0, 1.0, lam, 40000);
        assert!(i2 <= 8.0 / lam.sqrt() && (i2 - (2.0 * PI / lam).sqrt()).abs() < 2.5 / lam);
        println!("lambda={}: first-derivative |I| {:.6} <= 3/lambda {:.6} (ratio {:.3}); second-derivative |I| {:.6} <= 8/sqrt(lambda) {:.6}, Fresnel sqrt(2 pi/lambda) {:.6}",
                 lam, i1, 3.0 / lam, i1 * lam / 3.0, i2, 8.0 / lam.sqrt(), (2.0 * PI / lam).sqrt());
    }
    for &r in &[10.0f64, 100.0] {
        let bound = (8.0 * 2f64.sqrt() / r.sqrt() + 4.0 * 3f64.sqrt() / r) / PI;
        let j = j_angle(0, r).abs();
        println!("uniform bound on |J0({})|: {:.4} against {:.4}, ratio {:.2}", r, bound, j, bound / j);
        assert!(j <= bound);
        let mu2 = (0..1001).map(|k| (PI / 6.0 + k as f64 * PI / 1500.0).sin()).fold(f64::INFINITY, f64::min); // road 2
        let mu1 = (0..1001).map(|k| (k as f64 * PI / 6000.0).cos()).fold(f64::INFINITY, f64::min);
        assert!(((8.0 / (r * mu2).sqrt() + 2.0 * 3.0 / (r * mu1)) / PI - bound).abs() < 1e-9); // the lemma's 8 and 3
    }

    // ---- what breaks: a flat stationary point, phase x^3 ----
    let g43 = simpson(&|v: f64| (-v.powi(3)).exp(), 0.0, 6.0, 6000);
    let limit = 2.0 * (PI / 6.0).cos() * g43;
    println!("cubic phase limit 2 cos(pi/6) Gamma(4/3) = {:.4} (Gamma(4/3) {:.6})", limit, g43);
    let mut last = 0.0;
    for &lam in &[10.0f64, 100.0, 1000.0, 10000.0] {
        let ic = 2.0 * simpson(&|x: f64| (lam * x.powi(3)).cos(), 0.0, 1.0, 400000);
        println!("lambda={}: integral of cos(lambda x^3) on [-1, 1] {:.6}, times lambda^(1/3) {:.4}, times lambda^(1/2) {:.4}",
                 lam, ic, ic * lam.powf(1.0 / 3.0), ic * lam.powf(0.5));
        last = ic * lam.powf(1.0 / 3.0);
    }
    assert!((last - limit).abs() < 0.01 && (g43 - 0.8929795116).abs() < 1e-8);
    // ---- what breaks: the ends of the interval (imaginary part of the J0 integral) ----
    let mut rgap = 0.0;
    for &r in &[10.0f64, 100.0, 1000.0] {
        let im = simpson(&|t: f64| (r * t.sin()).sin(), 0.0, PI, 200000) / PI;
        let sp = (2.0 / (PI * r)).sqrt() * (r - PI / 4.0).sin();
        println!("r={}: imaginary part {:.6}, stationary point alone {:.6}, gap {:.6}, r x gap {:.4}", r, im, sp, im - sp, r * (im - sp));
        rgap = r * (im - sp);
    }
    println!("end-point prediction for r x gap: 2/pi = {:.4}", 2.0 / PI);
    assert!((rgap - 2.0 / PI).abs() < 0.01);

    // ---- zeros of J0 and the drum's round notes ----
    let note = 100.0 / (2.0 * PI * 0.15);
    println!("drum: hertz per unit of j = {:.6}", note);
    for &k in &[1i32, 2, 3, 10] {
        let beta = (k as f64 - 0.25) * PI;
        let (mut lo, mut hi) = (beta - 0.3, beta + 0.3);
        for _ in 0..60 {
            let mid = (lo + hi) / 2.0;
            if j_angle(0, lo) * j_angle(0, mid) > 0.0 { lo = mid; } else { hi = mid; }
        }
        let (jz, mc) = ((lo + hi) / 2.0, beta + 1.0 / (8.0 * beta));
        println!("zero {}: true {:.6}, (k - 1/4) pi {:.6}, with 1/(8 beta) {:.6}; note {:.1} Hz, predicted {:.1} Hz, {:.1} Hz",
                 k, jz, beta, mc, note * jz, note * beta, note * mc);
        assert!((mc - jz).abs() < 0.005 / (k * k) as f64);
        if k == 1 { assert!((jz - 2.404825557695773).abs() < 1e-9); }
        if k == 1 { assert!((note * jz - 255.2).abs() < 0.05); } // the fundamental on Drumheads: 255.2 Hz
    }

    // ---- the sphere and the circle ----
    for &rho in &[10.25f64, 100.25] {
        let q = 2.0 * PI * simpson(&|t: f64| (2.0 * PI * rho * t.cos()).cos() * t.sin(), 0.0, PI, 40000);
        let cf = 2.0 * (2.0 * PI * rho).sin() / rho;
        println!("sphere rho={}: quadrature {:.6}, two poles 2 sin(2 pi rho)/rho {:.6}, rho x value {:.4}", rho, q, cf, rho * q);
        assert!((q - cf).abs() < 1e-9);
    }
    let rho = 10.3;
    let circ = 2.0 * PI * j_angle(0, 2.0 * PI * rho);
    let cl = 2.0 / rho.sqrt() * (2.0 * PI * rho - PI / 4.0).cos();
    println!("circle rho=10.3: 2 pi J0(2 pi rho) {:.6}, two points (2/sqrt(rho)) cos(2 pi rho - pi/4) {:.6}, envelope 2/sqrt(rho) {:.6}", circ, cl, 2.0 / rho.sqrt());
    assert!((circ - cl).abs() < 0.01);

    // ---- chart points ----
    let rs: Vec<String> = (1..=20).map(|r| r.to_string()).collect();
    let jv: Vec<String> = (1..=20).map(|r| format!("{:.3}", j_angle(0, r as f64))).collect();
    let lv: Vec<String> = (1..=20).map(|r| format!("{:.3}", lead(0, r as f64))).collect();
    println!("chart r: {}", rs.join(", "));
    println!("chart J0: {}", jv.join(", "));
    println!("chart leading: {}", lv.join(", "));
    println!("ALL CHECKS PASS");
}
