// Completeness of sines and cosines -- the check behind the card.  std only.
// The siren is a square wave: +1 V on (0, pi), -1 V on (-pi, 0), phase x in radians.
// Energy means the integral of the square over one cycle, in V^2 rad.
// Every infinite object is a truncation: harmonics up to N, shown at several N.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for i in 1..m {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn b_sq(k: usize) -> f64 { 4.0 / (PI * k as f64) }

fn partial(x: f64, n: usize, b: &dyn Fn(usize) -> f64) -> f64 {
    let mut s = 0.0;
    for k in (1..=n).step_by(2) { s += b(k) * (k as f64 * x).sin(); }
    s
}

fn missing_ledger(n: usize, b: &dyn Fn(usize) -> f64, energy: f64) -> f64 {
    let mut s = 0.0;
    for k in (1..=n).step_by(2) { s += b(k).powi(2); }
    energy - PI * s
}

fn check(label: &str, got: f64, want: f64, tol: f64) {
    assert!((got - want).abs() < tol, "{} {} {}", label, got, want);
}

fn yes(ok: bool) -> &'static str { if ok { "yes" } else { "no" } }

fn main() {
    // 1. Rehearsal: 8 samples of one cycle and 8 sampled harmonics.
    let m = 8usize;
    let xs: Vec<f64> = (0..m).map(|j| -PI + (j as f64 + 0.5) * 2.0 * PI / m as f64).collect();
    let fs: Vec<f64> = xs.iter().map(|&x| if x > 0.0 { 1.0 } else { -1.0 }).collect();
    let r = (2.0 / m as f64).sqrt();
    let mut u: Vec<Vec<f64>> = vec![xs.iter().map(|_| 1.0 / (m as f64).sqrt()).collect()];
    for n in 1..=3 {
        let nf = n as f64;
        u.push(xs.iter().map(|&x| (nf * x).cos() * r).collect());
        u.push(xs.iter().map(|&x| (nf * x).sin() * r).collect());
    }
    u.push(xs.iter().map(|&x| (4.0 * x).sin() / (m as f64).sqrt()).collect());
    let dot = |a: &Vec<f64>, b: &Vec<f64>| -> f64 {
        let mut s = 0.0;
        for (p, q) in a.iter().zip(b.iter()) { s += p * q; }
        s
    };
    let mut gram: f64 = 0.0;
    for i in 0..m { for j in 0..m {
        let id = if i == j { 1.0 } else { 0.0 };
        gram = gram.max((dot(&u[i], &u[j]) - id).abs());
    } }
    let coef: Vec<f64> = u.iter().map(|v| dot(v, &fs)).collect();
    let mut err: f64 = 0.0;
    for j in 0..m {
        let mut s = 0.0;
        for (c, v) in coef.iter().zip(u.iter()) { s += c * v[j]; }
        err = err.max((s - fs[j]).abs());
    }
    let csum: f64 = coef.iter().map(|c| c * c).sum();
    println!("rehearsal, M = 8 samples, 8 sampled harmonics");
    println!("  largest Gram error below 1e-12: {}", yes(gram < 1e-12));
    println!("  largest rebuild error below 1e-12: {}", yes(err < 1e-12));
    println!("  sample energy {:.6} = sum of squared amounts {:.6}", dot(&fs, &fs), csum);
    println!("  drop sin 3x: rebuild misses energy {:.6}", coef[6].powi(2));
    assert!(gram < 1e-12, "{}", gram);
    assert!(err < 1e-12, "{}", err);
    check("rehearsal energy", csum, dot(&fs, &fs), 1e-12);

    // 2. The siren's sine amounts: closed form against Simpson.
    println!("sine amounts b_k = 4/(pi k): closed form, Simpson, energy pi b_k^2");
    for k in [1usize, 3, 5] {
        let kf = k as f64;
        let simp = 2.0 / PI * simpson(&|x: f64| (kf * x).sin(), 0.0, PI, 200);
        println!("  k = {}: {:.6} {:.6} {:.6}", k, b_sq(k), simp, PI * b_sq(k).powi(2));
        check("b_k", simp, b_sq(k), 1e-6);
    }

    // 3. Missing energy ||f - S_N f||^2: ledger against a direct integral.
    let e = 2.0 * PI;
    println!("siren energy ||f||^2 = {:.6} V^2 rad", e);
    let top = (1..100usize).step_by(2).filter(|&k| 500.0 * k as f64 <= 44100.0 / 2.0).max().unwrap();
    println!("44.1 kHz copy keeps odd harmonics up to {}: {} Hz <= {} Hz", top, 500 * top, 44100 / 2);
    println!("N, missing energy by ledger, by direct integral, share missing");
    for n in [1usize, 3, 5, top] {
        let led = missing_ledger(n, &b_sq, e);
        let direct = 2.0 * simpson(&|x: f64| (1.0 - partial(x, n, &b_sq)).powi(2), 0.0, PI, 6000);
        println!("  {}: {:.6} {:.6} {:.4}%", n, led, direct, 100.0 * led / e);
        check("missing", direct, led, 1e-6);
    }
    println!("large N, ledger only: N, missing, N x missing (tends to 8/pi)");
    for n in [99usize, 999, 9999] {
        let led = missing_ledger(n, &b_sq, e);
        println!("  {}: {:.6} {:.6}", n, led, n as f64 * led);
    }
    println!("  8/pi = {:.6}", 8.0 / PI);
    check("rate", 9999.0 * missing_ledger(9999, &b_sq, e), 8.0 / PI, 1e-3);

    // 4. Chart and bars.
    let ns = [1usize, 3, 9, 27, 81, 243, 729, 2187];
    let pts: Vec<(usize, f64)> = ns.iter().map(|&n| (n, missing_ledger(n, &b_sq, e))).collect();
    let a: Vec<String> = pts.iter().map(|p| format!("{:.2}", (p.0 as f64).log10())).collect();
    let b: Vec<String> = pts.iter().map(|p| format!("{:.2}", p.1.log10())).collect();
    println!("chart, log10 N: {}", a.join(" "));
    println!("chart, log10 missing: {}", b.join(" "));
    let slope = (pts[7].1.log10() - pts[6].1.log10()) / (2187f64.log10() - 729f64.log10());
    println!("chart, last slope: {:.3}", slope);
    check("slope", slope, -1.0, 0.01);
    let bars: Vec<String> = [1usize, 3, 5, 7, 9].iter()
        .map(|&k| format!("k={}:{:.2}%", k, 100.0 * PI * b_sq(k).powi(2) / e)).collect();
    println!("bars, share of energy per harmonic: {}", bars.join(" "));

    // 5. The proof in numbers: ramp g (siren averaged over a window of half-width d).
    let (d, n) = (0.02f64, 99usize);
    let b_g = |k: usize| b_sq(k) * (k as f64 * d).sin() / (k as f64 * d);
    let g = |x: f64| 1.0f64.min(x / d).min((PI - x) / d);
    let pieces = |f: &dyn Fn(f64) -> f64| simpson(f, 0.0, d, 200)
        + simpson(f, d, PI - d, 6000) + simpson(f, PI - d, PI, 200);
    let fg = 2.0 * pieces(&|x: f64| (1.0 - g(x)).powi(2));
    println!("proof, delta = {}, N = {}", d, n);
    println!("  ||f - g||^2: closed 4 delta/3 = {:.6}, Simpson {:.6}", 4.0 * d / 3.0, fg);
    check("f-g", fg, 4.0 * d / 3.0, 1e-9);
    for k in [1usize, 3] {
        let kf = k as f64;
        let simp = 2.0 / PI * pieces(&|x: f64| g(x) * (kf * x).sin());
        println!("  b_{}(g): closed {:.6}, Simpson {:.6}", k, b_g(k), simp);
        check("b_g", simp, b_g(k), 1e-8);
    }
    let eg = e - 8.0 * d / 3.0;
    let gled = missing_ledger(n, &b_g, eg);
    let gdir = 2.0 * pieces(&|x: f64| (g(x) - partial(x, n, &b_g)).powi(2));
    let gb = 4.0 / (d * ((n + 1) as f64).powi(2));
    println!("  ||g - S_N g||^2: ledger {:.6}, direct {:.6}, bound 4/(delta (N+1)^2) {:.6}", gled, gdir, gb);
    check("g ledger", gdir, gled, 1e-6);
    assert!(gled <= gb);
    let fs_n = missing_ledger(n, &b_sq, e).sqrt();
    let bound = (4.0 * d / 3.0).sqrt() + gled.sqrt();
    println!("  ||f - S_N f|| = {:.6} <= {:.6} + {:.6} = {:.6}", fs_n, (4.0 * d / 3.0).sqrt(), gled.sqrt(), bound);
    assert!(fs_n <= bound);

    // 6. What breaks.
    let n = 999usize;
    let drop3 = missing_ledger(n, &b_sq, e) + PI * b_sq(3).powi(2);
    println!("breaks, N = {}: harmonic 3 dropped, missing {:.6} (never below {:.6})", n, drop3, PI * b_sq(3).powi(2));
    let offset = missing_ledger(n, &b_sq, e) + 0.25 * 2.0 * PI;
    println!("breaks, N = {}: sines only, siren + 0.5 V, missing {:.6} (never below {:.6})", n, offset, 0.5 * PI);
    let si = simpson(&|u: f64| if u != 0.0 { u.sin() / u } else { 1.0 }, 0.0, PI, 2000);
    for n in [43usize, 999] {
        let peak = partial(PI / (n + 1) as f64, n, &b_sq);
        println!("breaks, sup norm: N = {}, peak of S_N at pi/(N+1) = {:.6}", n, peak);
    }
    println!("breaks, sup norm: limit (2/pi) Si(pi) = {:.6}", 2.0 / PI * si);
    check("gibbs", partial(PI / 1000.0, 999, &b_sq), 2.0 / PI * si, 1e-5);
    println!("ALL CHECKS PASS");
}
