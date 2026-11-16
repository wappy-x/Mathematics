// Decay of Fourier coefficients and smoothness -- the same check in Rust, std only.
// Three +-1 V waves on the phase circle -pi <= x < pi: square (jumps), triangle
// (kinks), parabola wave (its slope kinks).  Coefficients by a midpoint rule;
// term counts by brute force on a grid and by tail sums, beside the theorem's bound.
use std::f64::consts::PI;

fn sq(x: f64) -> f64 { if x > 0.0 { 1.0 } else if x < 0.0 { -1.0 } else { 0.0 } }
fn tri(x: f64) -> f64 { 1.0 - 2.0 * x.abs() / PI }
fn par(x: f64) -> f64 { 4.0 / (PI * PI) * (PI * x - x * x.abs()) }
fn dtri(x: f64) -> f64 { -2.0 / PI * sq(x) }                       // slope of tri, by hand
fn dpar(x: f64) -> f64 { 4.0 / (PI * PI) * (PI - 2.0 * x.abs()) }  // slope of par, by hand

const M: usize = 20000;                                            // midpoint slices
fn coef(f: fn(f64) -> f64, n: f64) -> f64 {                        // |f^(n)|
    let h = 2.0 * PI / M as f64;
    let (mut a, mut b) = (0.0, 0.0);
    for j in 0..M {
        let x = -PI + (j as f64 + 0.5) * h;
        let v = f(x); a += v * (n * x).cos(); b += v * (n * x).sin();
    }
    (a * a + b * b).sqrt() * h / (2.0 * PI)
}

fn tail(p: i32, n: usize, c: f64) -> f64 {   // c * sum over odd m > n of 1/m^p, plus integral tail
    let top = 1_000_000usize;
    let s: f64 = (n + 1 + n % 2..top).step_by(2).map(|m| 1.0 / (m as f64).powi(p)).sum();
    c * (s + 1.0 / (2.0 * (p - 1) as f64 * (top as f64).powi(p - 1)))
}

fn brute(tri_wave: bool, eps: f64) -> (usize, Vec<f64>) {  // smallest N whose worst grid error <= eps
    let g = 2001;
    let grid: Vec<f64> = (0..g).map(|i| -PI + 2.0 * PI * i as f64 / (g - 1) as f64).collect();
    let mut s = vec![0.0; g];
    let mut hist = vec![0.0; 1];
    for n in 1..=120usize {
        let nf = n as f64;
        if n % 2 == 1 {
            for (i, x) in grid.iter().enumerate() {
                s[i] += if tri_wave { 8.0 / (PI * PI) * (nf * x).cos() / (nf * nf) }
                        else { 32.0 / (PI * PI * PI) * (nf * x).sin() / (nf * nf * nf) };
            }
        }
        let mut worst = 0.0f64;
        for (i, x) in grid.iter().enumerate() {
            let f = if tri_wave { tri(*x) } else { par(*x) };
            worst = worst.max((f - s[i]).abs());
        }
        hist.push(worst);
        if worst <= eps { return (n, hist); }
    }
    (0, hist)
}

fn predict(v: f64, k: f64, eps: f64) -> usize { (v / (PI * k * eps)).powf(1.0 / k).ceil() as usize }
fn overshoot(n: usize) -> f64 {                // peak of S_N on (0, 3pi/(N+1)), 400 points
    let mut best = 0.0f64;
    for i in 1..=400 {
        let x = 3.0 * PI / (n as f64 + 1.0) * i as f64 / 400.0;
        let s: f64 = (1..=n).step_by(2).map(|m| (m as f64 * x).sin() / m as f64).sum();
        best = best.max(4.0 / PI * s);
    }
    best - 1.0
}

fn travel(f: fn(f64) -> f64, k: i32) -> f64 {  // travel of the k-th slope round the loop, sampled from f
    let d = 0.01;                              // 200 midpoints: no sample within d of a kink
    let s = |x: f64| match k { 0 => f(x), 1 => (f(x + d) - f(x - d)) / (2.0 * d), _ => (f(x + d) - 2.0 * f(x) + f(x - d)) / (d * d) };
    let g: Vec<f64> = (0..200).map(|j| s(-PI + 2.0 * PI * (j as f64 + 0.5) / 200.0)).collect();
    (0..200).map(|j| (g[j] - g[(j + 199) % 200]).abs()).sum()   // j = 0 closes the loop at the seam
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let names = ["square", "triangle", "parabola"];
    let funs: [fn(f64) -> f64; 3] = [sq, tri, par];
    let kk = [0i32, 1, 2];
    let vv: Vec<f64> = (0..3).map(|w| travel(funs[w], kk[w])).collect();   // travel of the k-th slope
    let exact = [2.0 / PI, 4.0 / (PI * PI), 16.0 / (PI * PI * PI)];
    let ns = [1.0f64, 3.0, 9.0, 27.0, 81.0];

    println!("1. decay: n^(k+1) |f^(n)| at odd n, integrated; bound V/2pi");
    for w in 0..3 {
        let vals: Vec<f64> = ns.iter().map(|n| n.powi(kk[w] + 1) * coef(funs[w], *n)).collect();
        println!("  {:<9} k={}  {}   bound {:.5}", names[w], kk[w], join(&vals, 5), vv[w] / (2.0 * PI));
        assert!(vals.iter().all(|v| (v - exact[w]).abs() < 1e-3 * exact[w]));
        assert!((vv[w] / (2.0 * PI) - vals[0]).abs() < 1e-4 * vals[0]);   // measured travel: bound is sharp
    }
    println!("  even n=2: {}", join(&funs.iter().map(|f| coef(*f, 2.0)).collect::<Vec<_>>(), 6));

    println!("2. derivative rule: |slope^(n)| against n |f^(n)|");
    let pairs: [(&str, fn(f64) -> f64, fn(f64) -> f64); 2] = [("triangle", tri, dtri), ("parabola", par, dpar)];
    for (name, f, df) in pairs {
        for n in [3.0f64, 9.0] {
            let (lhs, rhs) = (coef(df, n), n * coef(f, n));
            println!("  {:<9} n={}  {:.6}  {:.6}", name, n, lhs, rhs);
            assert!((lhs - rhs).abs() < 1e-4);
        }
    }
    println!("  sawtooth x/pi, smooth inside, n|f^(n)| at n=1,9,99: {}",
             join(&[1.0f64, 9.0, 99.0].map(|n| n * coef(|x| x / PI, n)), 4));

    println!("3. uniform accuracy 0.01 V: terms needed");
    for (w, p, c, tw) in [(1usize, 2i32, 8.0 / (PI * PI), true), (2, 3, 32.0 / (PI * PI * PI), false)] {
        let (n, hist) = brute(tw, 0.01);
        let nt = (1..200).find(|m| tail(p, *m, c) <= 0.01).unwrap();
        let pr = predict(vv[w], kk[w] as f64, 0.01);
        println!("  {:<9} brute force N={} (error {:.5} V, at N-2 {:.5} V)  tail sum N={}  theorem N={}  top {} Hz",
                 names[w], n, hist[n], hist[n - 2], nt, pr, n * 220);
        assert!(n <= nt && nt <= pr);
        if tw { assert!((hist[n] - tail(p, n, c)).abs() < 1e-6); }
    }
    let ntri = brute(true, 0.01).0;
    let (vt, th) = (vv[1], vv[1] / (PI * 0.01));
    println!("  triangle: V1 {:.5}, n=3 coefficient {:.6}, bound {:.6}, theorem N {:.2}, half {:.2}, nonzero tones {}",
             vt, coef(tri, 3.0), vt / (2.0 * PI * 9.0), th, th / 2.0, (ntri + 1) / 2);
    let te: Vec<f64> = [1usize, 9, 41, 81].iter().map(|n| tail(2, *n, 8.0 / (PI * PI))).collect();
    println!("  triangle worst error at N=1,9,41,81: {}", join(&te, 5));
    assert!((te[0] - (1.0 - 8.0 / (PI * PI))).abs() < 1e-6);
    let last = (1..99usize).step_by(2).find(|n| 8.0 / (PI * PI) / (((n + 2) * (n + 2)) as f64) < 0.01).unwrap();
    let ml = tail(2, last, 8.0 / (PI * PI));
    println!("  mistake, stop when the next amplitude < 0.01 V: N={}, worst error {:.5} V, {:.2} x target", last, ml, ml / 0.01);
    for eps in [0.1f64, 0.01, 0.001] {
        println!("  eps {:<5}  theorem N: triangle {}  parabola {}  square rms {}", eps,
                 predict(vv[1], 1.0, eps), predict(vv[2], 2.0, eps), (16.0 / (2.0 * PI * PI * eps * eps)).ceil());
    }

    println!("4. square wave: no uniform accuracy; energy only");
    println!("  overshoot above 1 V at N=41, 401, 4053: {}", join(&[41usize, 401, 4053].map(overshoot), 4));
    let (mut head, mut n) = (0.0, 0usize);
    loop {
        n += 1;
        if n % 2 == 1 { head += 8.0 / (PI * PI) / ((n * n) as f64); }
        if 1.0 - head <= 1e-4 { break; }
    }
    println!("  rms 0.01 V by Parseval: N={}  rms {:.6} V  theorem N={}  top {} Hz",
             n, (1.0 - head).sqrt(), (16.0 / (2.0 * PI * PI * 1e-4)).ceil(), n * 220);
    let (l, mut e2) = (40000, 0.0);
    let h = 2.0 * PI / l as f64;
    for j in 0..l {
        let x = -PI + (j as f64 + 0.5) * h;
        let s: f64 = (1..42).step_by(2).map(|m| (m as f64 * x).sin() / m as f64).sum();
        e2 += (sq(x) - 4.0 / PI * s).powi(2) * h / (2.0 * PI);
    }
    let t41 = tail(2, 41, 8.0 / (PI * PI));
    println!("  N=41 mean-square error: integrated {:.6}  Parseval tail {:.6}", e2, t41);
    assert!((e2 - t41).abs() < 1e-5);
    let (mut si, mut term) = (0.0, PI);                       // Si(pi) as its power series
    for j in 0..30 {
        si += term / (2 * j + 1) as f64;
        term *= -PI * PI / (((2 * j + 2) * (2 * j + 3)) as f64);
    }
    println!("  Gibbs limit (2/pi) Si(pi) - 1 = {:.4}", 2.0 / PI * si - 1.0);
    assert!([401usize, 4053].iter().all(|n| (overshoot(*n) - (2.0 / PI * si - 1.0)).abs() < 1e-3));

    println!("5. converse: sum of |n| |f^(n)| over 0<|n|<=N, N = 10^2, 10^4, 10^6");
    for (w, p, c) in [(1usize, 1i32, 8.0 / (PI * PI)), (2, 2, 32.0 / (PI * PI * PI))] {
        let v: Vec<f64> = [2u32, 4, 6].iter()
            .map(|e| c * (1..10usize.pow(*e)).step_by(2).map(|m| 1.0 / (m as f64).powi(p)).sum::<f64>()).collect();
        println!("  {:<9} {}", names[w], join(&v, 5));
    }
    println!("  parabola limit 4/pi = {:.5}", 4.0 / PI);
    let d0 = 0.0 - 8.0 / (PI * PI) * (1..10000).step_by(2).map(|m| (m as f64 * 0.0).sin() / m as f64).sum::<f64>();
    println!("  triangle slope at x=0: left {:+.5}, right {:+.5}, differentiated series {:.5}", dtri(-1e-9), dtri(1e-9), d0);

    println!("chart, log10 n: {}", join(&ns.map(|n| n.log10()), 3));
    for w in 0..3 {
        println!("chart, {}: {}", names[w], join(&ns.map(|n| (exact[w] / n.powi(kk[w] + 1)).log10()), 3));
    }
    println!("ALL CHECKS PASS");
}
