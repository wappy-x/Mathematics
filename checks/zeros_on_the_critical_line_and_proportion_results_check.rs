// Zeros on the line -- the same check as the Python, in Rust.  No crates.  Hardy's function Z(t) two
// ways (Euler-Maclaurin zeta and Riemann-Siegel); sign changes of Z against an argument-principle count;
// Gram's law and its first failure; Hardy's integrals; the zero count N(T) at the verified height.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(k: f64, a: C) -> C { c(k * a.re, k * a.im) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn ph(a: C) -> f64 { a.im.atan2(a.re) }
fn ln(a: C) -> C { c(md(a).ln(), ph(a)) }
fn ex(a: C) -> C { let m = a.re.exp(); c(m * a.im.cos(), m * a.im.sin()) }
fn pw(x: f64, s: C) -> C { ex(sc(x.ln(), s)) } // x^s for real x > 0
const BERN: [f64; 5] = [1.0 / 6.0, -1.0 / 30.0, 1.0 / 42.0, -1.0 / 30.0, 5.0 / 66.0]; // B2, B4, ..., B10
fn zeta(s: C) -> C { // head sum + tail integral + end corrections (Euler-Maclaurin)
    let nn = 20usize.max((s.im.abs() / 2.0) as usize + 10); let n = nn as f64;
    let mut z = (1..nn).fold(c(0.0, 0.0), |z, k| add(z, pw(k as f64, sc(-1.0, s))));
    z = add(add(z, div(pw(n, sub(c(1.0, 0.0), s)), sub(s, c(1.0, 0.0)))), sc(0.5, pw(n, sc(-1.0, s))));
    let (mut r, mut f) = (mul(s, pw(n, sub(c(-1.0, 0.0), s))), 2.0);
    for (k, b) in BERN.iter().enumerate() {
        z = add(z, sc(b / f, r)); let k = k as f64;
        r = sc(1.0 / (n * n), mul(r, mul(add(s, c(2.0 * k + 1.0, 0.0)), add(s, c(2.0 * k + 2.0, 0.0))))); f *= (2.0 * k + 3.0) * (2.0 * k + 4.0);
    }
    z
}
fn theta(t: f64) -> f64 { // arg of Gamma(1/4 + it/2) - (t/2) log pi, Stirling after 10 shifts
    let w = c(10.25, 0.5 * t); let w3 = mul(w, mul(w, w)); let w5 = mul(w3, mul(w, w));
    let lg = add(sub(sub(mul(sub(w, c(0.5, 0.0)), ln(w)), w), div(c(1.0 / 360.0, 0.0), w3)), add(div(c(1.0 / 12.0, 0.0), w), div(c(1.0 / 1260.0, 0.0), w5)));
    lg.im - (0..10).map(|k| (t / 2.0).atan2(0.25 + k as f64)).sum::<f64>() - t / 2.0 * PI.ln()
}
fn theta_st(t: f64) -> f64 { t / 2.0 * (t / (2.0 * PI)).ln() - t / 2.0 - PI / 8.0 + 1.0 / (48.0 * t) + 7.0 / (5760.0 * t.powi(3)) }
fn z_em(t: f64) -> C { mul(ex(c(0.0, theta(t))), zeta(c(0.5, t))) } // should be real
fn z_rs(t: f64) -> f64 { // Riemann-Siegel: a short cosine sum plus its first correction
    let a = (t / (2.0 * PI)).sqrt(); let m = a as usize; let p = a - m as f64; let th = theta_st(t);
    let main = 2.0 * (1..=m).map(|n| (th - t * (n as f64).ln()).cos() / (n as f64).sqrt()).sum::<f64>();
    let sign = if m % 2 == 1 { 1.0 } else { -1.0 };
    main + sign * a.powf(-0.5) * (2.0 * PI * (p * p - p - 1.0 / 16.0)).cos() / (2.0 * PI * p).cos()
}
fn changes(v: &[f64]) -> usize { v.windows(2).filter(|w| w[0] * w[1] < 0.0).count() }
fn grid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, h: f64) -> Vec<f64> { (0..=((b - a) / h).round() as usize).map(|k| f(a + k as f64 * h)).collect() }
fn gram(n: i32) -> f64 { // the height g_n where theta(g_n) = n pi, by bisection
    let (mut lo, mut hi) = (10.0, 1e4);
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if theta(mid) < n as f64 * PI { lo = mid } else { hi = mid } }
    lo
}
fn boxc(t: f64) -> f64 { // argument principle: turns of zeta round -0.5..1.5 x 1..T
    let cs = [c(-0.5, 1.0), c(1.5, 1.0), c(1.5, t), c(-0.5, t), c(-0.5, 1.0)];
    let mut pts = Vec::new();
    for w in cs.windows(2) { let n = (md(sub(w[1], w[0])) / 0.02).round() as usize; for k in 0..n { pts.push(add(w[0], sc(k as f64 / n as f64, sub(w[1], w[0])))) } }
    pts.push(cs[0]);
    let v: Vec<C> = pts.iter().map(|&s| zeta(s)).collect();
    v.windows(2).map(|w| ph(div(w[1], w[0]))).sum::<f64>() / (2.0 * PI)
}
fn n0(t: f64) -> f64 { theta(t) / PI + 1.0 } // smooth zero count, log-gamma road
fn n1(t: f64) -> f64 { t / (2.0 * PI) * (t / (2.0 * PI * std::f64::consts::E)).ln() + 7.0 / 8.0 }
fn height(n: f64) -> f64 { // invert the smooth count: the height of zero number n
    let (mut lo, mut hi) = (10.0, 1e14);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if n0(mid) < n { lo = mid } else { hi = mid } }
    lo
}
fn commas(x: f64) -> String { // 12362403019661.1 -> "12,362,403,019,661"
    let s = format!("{:.0}", x); let b = s.as_bytes(); let mut o = String::new();
    for (i, ch) in b.iter().enumerate() { if i > 0 && (b.len() - i) % 3 == 0 { o.push(',') } o.push(*ch as char) }
    o
}
fn main() {
    let zr = grid(&z_rs, 10.0, 100.0, 0.05); let ze = grid(&|t| z_em(t).re, 10.0, 100.0, 0.05);
    let coarse: Vec<usize> = [1.0, 2.0, 3.0].iter().map(|&h| changes(&grid(&z_rs, 10.0, 100.0, h))).collect();
    let (inside, above) = (boxc(100.0), boxc(101.5));
    let gap = (0..785).map(|k| { let t = 10.0 + k as f64 * 0.37; (z_em(t).re - z_rs(t)).abs() }).fold(0.0, f64::max);
    let imag = (0..812).map(|k| z_em(k as f64 * 0.37).im.abs()).fold(0.0, f64::max);
    println!("theta(100): log-gamma road {:.6}, Stirling road {:.6}; theta/pi + 1 = {:.4}", theta(100.0), theta_st(100.0), n0(100.0));
    println!("Z(0) = zeta(1/2) = {:.6}; Z real on 0..300: largest imaginary part below 1e-6: {}", z_em(0.0).re, if imag < 1e-6 { "True" } else { "False" });
    let (mut lo, mut hi) = (14.0, 15.0); // first zero: bisection on the sign of Z
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if z_em(mid).re * z_em(lo).re > 0.0 { lo = mid } else { hi = mid } }
    println!("first zero, by bisection on the sign of Z between 14 and 15: {:.6}", lo);
    println!("sign changes of Z on 10..100, step 0.05: Riemann-Siegel {}, Euler-Maclaurin {}", changes(&zr), changes(&ze));
    println!("sign changes on 10..100 at steps 1, 2, 3: {}, {}, {}", coarse[0], coarse[1], coarse[2]);
    println!("argument principle, box -0.5..1.5 x 1..100: {:.0} zeros in the strip; to height 101.5: {:.0}", inside, above);
    println!("Riemann-Siegel against Euler-Maclaurin on 10..300: largest gap {:.4}", gap);
    println!("chart t = 0, 1, ..., 50, Z(t): {}", (0..51).map(|t| format!("{:.2}", z_em(t as f64).re)).collect::<Vec<_>>().join(", "));
    let bad = (0..200).find(|&n| (if n % 2 == 0 { 1.0 } else { -1.0 }) * z_em(gram(n)).re < 0.0).unwrap();
    let g: Vec<f64> = [0, 1, bad - 1, bad, bad + 1].iter().map(|&n| gram(n)).collect();
    let sc2: Vec<usize> = [(g[2], g[3]), (g[3], g[4])].iter().map(|&(a, b)| changes(&(0..401).map(|k| z_em(a + (b - a) * k as f64 / 400.0).re).collect::<Vec<_>>())).collect();
    println!("Gram points g_0 = {:.4}, g_1 = {:.4}; Z(g_0) = {:.4}, Z(g_1) = {:.4}", g[0], g[1], z_em(g[0]).re, z_em(g[1]).re);
    println!("first failure of Gram's law: n = {}, g = {:.4}, Z(g) = {:.4}; sign changes g_{}..g_{}: {}, g_{}..g_{}: {}",
        bad, g[3], z_em(g[3]).re, bad - 1, bad, sc2[0], bad, bad + 1, sc2[1]);
    let mut hardy = Vec::new();
    for tt in [100usize, 200, 300] { // midpoint rule, step 0.05
        let pts: Vec<f64> = (0..20 * tt).map(|k| (k as f64 + 0.5) * 0.05).collect();
        let zs: Vec<C> = pts.iter().map(|&t| z_em(t)).collect();
        let i = 0.05 * zs.iter().map(|z| z.re).sum::<f64>(); let j = 0.05 * zs.iter().map(|&z| md(z)).sum::<f64>();
        let k = 0.05 * pts.iter().map(|&t| zeta(c(0.5, t)).re).sum::<f64>();
        hardy.push((tt as f64, i, j, k));
        println!("T = {}: integral of Z {:.2}; of |Z| {:.2}; of Re zeta(1/2 + it) {:.2}", tt, i, j, k);
    }
    let t = 3e12;
    println!("N(T) at T = 3e12: theta road {}; simple formula {}; without the -T/2pi term {}", commas(n0(t)), commas(n1(t)), commas(t / (2.0 * PI) * (t / (2.0 * PI)).ln()));
    let h13 = height(1e13);
    println!("Riemann-Siegel terms at T = 3e12: {}", commas((t / (2.0 * PI)).sqrt().floor()));
    println!("height where the smooth count reaches 10^13: {}", commas(h13));
    let (hh, nh) = (3000175332800.0, 12363153437138.0); // verified height; its proved exact count
    println!("verified height {}: smooth count {}; proved exact count {}", commas(hh), commas(n0(hh)), commas(nh));
    println!("zeros per unit height N(T)/T: T = 100: {:.2}, T = 10^6: {:.2}, T = 3e12: {:.2}", n0(100.0) / 100.0, n0(1e6) / 1e6, n0(t) / t);
    for (name, x) in [("Levinson 1974", 0.3474), ("Conrey 1989", 0.4088), ("checked to 3e12", 1.0)] {
        println!("bars, {:16} {:40} {:.4}", name, "#".repeat((40.0 * x as f64).round() as usize), x);
    }
    assert!(changes(&zr) == 29 && changes(&ze) == 29 && inside.round() == 29.0 && n0(100.0).round() == 29.0);
    assert!((theta(100.0) - theta_st(100.0)).abs() < 1e-9 && gap < 0.02 && imag < 1e-6); // two roads to theta, to Z
    assert!(bad == 126 && sc2 == vec![0, 2] && (g[0] - 17.8456).abs() < 1e-4 && (lo - 14.134725142).abs() < 1e-8); // published Gram data
    assert!(hardy.iter().all(|&(tt, i, j, k)| (k - tt).abs() < 0.05 * tt && i.abs() < 0.1 * j)); // Hardy's comparison
    assert!((n0(t) - n1(t)).abs() < 0.05 && (n0(100.0) - n1(100.0)).abs() < 1e-3 && coarse[1] < 29); // log-gamma against simple formula
    assert!((n0(hh) - nh).abs() < 2.0 && 2.44e12 < h13 && h13 < 2.45e12); // published: exact count; Gourdon's height 2.44... x 10^12
    println!("ALL CHECKS PASS");
}
