// Compactness in Lp -- the check behind the card.  Rust std only.
// A one-second audio clip is a function on the loop [0, 1): time in seconds, the end joined
// to the start, amplitudes illustrative.  Click f_n = n on [0, 1/n), else 0, so its L1 size
// is 1.  Tone g_n(x) = sin(2 pi n x).  Blur: average over the last eps = 0.05 s.
// Delay: (tau_h f)(x) = f(x - h), wrapping round the loop.  The code holds finitely many
// clips and grids, so it checks instances and trends; the theorems rest on the card's proofs.
// Roads: closed forms against midpoint grids lined up with every jump and corner,
// bin averages against a counting rule, and exact ramp-and-plateau shift values.
use std::f64::consts::PI;

// midpoint rule for the integral of f over [a, b]
fn grid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, g: usize) -> f64 {
    let w = (b - a) / g as f64;
    let mut s = 0.0;
    for i in 0..g { s += f(a + (i as f64 + 0.5) * w); }
    w * s
}

fn md1(x: f64) -> f64 { x.rem_euclid(1.0) }
fn click(n: usize, c: f64) -> impl Fn(f64) -> f64 { move |x| if md1(x) < 1.0 / n as f64 { c } else { 0.0 } }
fn tone(n: usize) -> impl Fn(f64) -> f64 { move |x| (2.0 * PI * n as f64 * x).sin() }

// (B f_n)(x) = (1/eps) * integral of f_n over [x - eps, x]
fn blur_click(n: usize, eps: f64) -> impl Fn(f64) -> f64 {
    move |x| { let x = md1(x); n as f64 * (x.min(1.0 / n as f64) - (x - eps).max(0.0)).max(0.0) / eps }
}

fn l1_shift(u: &dyn Fn(f64) -> f64, h: f64, a: f64, b: f64, g: usize) -> f64 { grid(&|x| (u(x - h) - u(x)).abs(), a, b, g) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn bars(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" | ") }

// || P_N f_n - P_N f_2n ||_1 = sum over bins of |mass difference|
fn binned_gap(n: usize, nb: usize) -> f64 {
    let (nf, mut tot) = (n as f64, 0.0);
    for j in 0..nb {
        let (lo, hi) = (j as f64 / nb as f64, (j + 1) as f64 / nb as f64);
        tot += (nf * (hi.min(1.0 / nf) - lo).max(0.0) - 2.0 * nf * (hi.min(1.0 / (2.0 * nf)) - lo).max(0.0)).abs();
    }
    tot
}

fn main() {
    // 1. Clicks fail the shift test: ||tau_h f_n - f_n||_1 = 2 min(nh, 1).
    let ns = [10usize, 100, 1000, 10000];
    let sizes: Vec<f64> = ns.iter().map(|&n| grid(&click(n, n as f64), 0.0, 1.0, 20000)).collect();
    assert!(sizes.iter().all(|v| (v - 1.0).abs() < 1e-9));
    println!("clicks f_n: L1 sizes at n = 10, 100, 1000, 10000 (grid): {}", join(&sizes, 4));
    println!("clicks f_n: L1 distance to the shift by h (formula; a grid agrees)");
    println!("  h     | n=10   | n=100  | n=1000 | n=10000");
    for h in [0.1, 0.01, 0.001] {
        let row: Vec<f64> = ns.iter().map(|&n| 2.0 * (n as f64 * h).min(1.0)).collect();
        for (&n, &v) in ns.iter().zip(&row) { assert!((v - l1_shift(&click(n, n as f64), h, 0.0, 1.0, 20000)).abs() < 1e-9); }
        println!("  {:.3} | {}", h, bars(&row));
    }
    for m in [100usize, 1000] {
        let w = (1..=m).map(|n| 2.0 * (n as f64 * 0.001).min(1.0)).fold(f64::MIN, f64::max);
        println!("  finite family n <= {}: worst shift distance at h = 0.001 is {:.4}", m, w);
    }
    let pairs = [(10usize, 20usize), (10, 40), (100, 200), (100, 10000)];
    let mut parts = vec![];
    for &(n, m) in &pairs {
        let (a, b) = (click(n, n as f64), click(m, m as f64));
        let v = grid(&|x| (a(x) - b(x)).abs(), 0.0, 1.0, 20000);
        assert!((v - 2.0 * (1.0 - n as f64 / m as f64)).abs() < 1e-9);
        parts.push(format!("({}, {}) {:.4}", n, m, v));
    }
    println!("  ||f_n - f_m||_1 for (n, m) = {}", parts.join(", "));

    // 2. The finite rehearsal: average each click over N equal bins (an N-sample clip).
    println!("N-sample clips: ||P_N f_n - P_N f_2n||_1");
    println!("  n      | N=10   | N=100  | N=1000 | no bins");
    for n in [1usize, 3, 10, 100, 1000] {
        let row: Vec<f64> = [10usize, 100, 1000].iter().map(|&nb| binned_gap(n, nb)).collect();
        for (&nb, &v) in [10usize, 100, 1000].iter().zip(&row) { // 0 from n = N on; 1 when bin edges meet both ends
            let want = if n >= nb { 0.0 } else if nb % (2 * n) == 0 { 1.0 } else { -1.0 };
            assert!(if want < 0.0 { 0.0 < v && v < 1.0 } else { (v - want).abs() < 1e-9 });
        }
        let nob = grid(&|x| (click(n, n as f64)(x) - click(2 * n, 2.0 * n as f64)(x)).abs(), 0.0, 1.0, 60000); // no bins
        assert!((nob - 2.0 * (1.0 - n as f64 / (2 * n) as f64)).abs() < 1e-9);
        println!("  n={:<5}| {} | {:.4}", n, bars(&row), nob);
    }

    // 3. Clicks are not uniformly integrable, so no subsequence converges weakly in L1.
    let tail = |n: usize, k: usize| { let c = click(n, n as f64); grid(&|x| if c(x) > k as f64 { c(x) } else { 0.0 }, 0.0, 1.0, 20000) }; // area above K
    let tails: Vec<f64> = [10usize, 100, 1000].iter().map(|&k| [k / 2, k, 2 * k, 10 * k].iter().map(|&n| tail(n, k)).fold(f64::MIN, f64::max)).collect();
    for (&k, &t) in [10usize, 100, 1000].iter().zip(&tails) { // rule: click n keeps area 1 above K exactly when n > K
        assert!((t - (1..=10 * k).map(|n| if n > k { 1.0 } else { 0.0 }).fold(f64::MIN, f64::max)).abs() < 1e-9 && tail(k, k).abs() < 1e-9);
    }
    println!("  worst tail sup_n of the integral of f_n where f_n > K, at K = 10, 100, 1000: {}", join(&tails, 4));
    let first: Vec<f64> = ns.iter().map(|&n| (n as f64 * 0.001).min(1.0)).collect();
    for (&n, &v) in ns.iter().zip(&first) { assert!((v - grid(&click(n, n as f64), 0.0, 0.001, 1000)).abs() < 1e-9); }
    println!("  reading on the first millisecond, n = 10, 100, 1000, 10000: {}", join(&first, 4));

    // 4. Tones g_n: bounded by 1, so uniformly integrable; weakly to 0; still not compact.
    for n in [1usize, 10, 100] {
        let (g, g2, h) = (tone(n), tone(2 * n), 1.0 / (2.0 * n as f64));
        let sz = grid(&|x| g(x).powi(2), 0.0, 1.0, 4000).sqrt();
        let sh = grid(&|x| (g(x - h) - g(x)).powi(2), 0.0, 1.0, 4000).sqrt();
        let pr = grid(&|x| (g(x) - g2(x)).powi(2), 0.0, 1.0, 4000).sqrt();
        let sh1 = grid(&|x| (g(x - h) - g(x)).abs(), 0.0, 1.0, 200000);
        assert!((sz - 1.0 / 2f64.sqrt()).abs() < 1e-9 && (sh - 2f64.sqrt()).abs() < 1e-9 && (pr - 1.0).abs() < 1e-9 && (sh1 - 4.0 / PI).abs() < 1e-6);
        println!("  tone n={:<3}: ||g_n||_2 {:.4}; shift by 1/(2n): L2 {:.4}, L1 {:.4}; ||g_n - g_2n||_2 {:.4}", n, sz, sh, sh1, pr);
    }
    let anti = |x: f64| -(4.0 * PI * x).cos() / (4.0 * PI) + (2.0 * PI * x).cos() / (2.0 * PI);
    let cuts = [0.0, 1.0 / 6.0, 0.5, 5.0 / 6.0, 1.0];
    let gap1: f64 = cuts.windows(2).map(|w| (anti(w[1]) - anti(w[0])).abs()).sum();
    for n in [1usize, 10] {
        let (g, g2) = (tone(n), tone(2 * n));
        assert!((gap1 - grid(&|x| (g(x) - g2(x)).abs(), 0.0, 1.0, 200000)).abs() < 1e-6);
    }
    println!("  ||g_n - g_2n||_1 = {:.4} at every n (antiderivative and grid)", gap1);
    let mut reads = vec![];
    for n in [1usize, 2, 3, 11, 101, 1001] {
        let r = (1.0 - (PI * n as f64 / 2.0).cos()) / (2.0 * PI * n as f64);
        assert!((r - grid(&tone(n), 0.0, 0.25, 200000)).abs() < 1e-8);
        reads.push(r);
    }
    println!("  tone reading on the first quarter second, n = 1, 2, 3, 11, 101, 1001: {}", join(&reads, 6));

    // 5. Blurred clicks pass: worst shift distance 2h/eps, and they converge to the box.
    let bx = |x: f64| if md1(x) < 0.05 { 20.0 } else { 0.0 };
    for n in [20usize, 100, 1000] {
        let u = blur_click(n, 0.05);
        let v = grid(&|x| (u(x) - bx(x)).abs(), 0.0, 0.1, 100000);
        assert!((v - 1.0 / (n as f64 * 0.05)).abs() < 1e-9);
        println!("  blurred click n={:<4}: L1 distance to the box 20 on [0, 0.05) = {:.4}", n, v);
    }
    let hs = [0.04, 0.02, 0.01, 0.005, 0.002, 0.001];
    let chart: Vec<f64> = hs.iter().map(|&h| l1_shift(&blur_click(10000, 0.05), h, -0.05, 0.1, 150000)).collect();
    for (&h, &v) in hs.iter().zip(&chart) { assert!((v - 40.0 * h).abs() < 1e-6); }
    let clk: Vec<f64> = hs.iter().map(|&h| (2..=10000).map(|n| 2.0 * (n as f64 * h).min(1.0)).fold(f64::MIN, f64::max)).collect(); // worst over clicks 2..10^4
    let ton: Vec<f64> = hs.iter().map(|&h| (1..=10000).map(|n| 2f64.sqrt() * (PI * (n as f64 * h).min(0.5)).sin()).fold(f64::MIN, f64::max)).collect();
    for ((&h, &c), &t) in hs.iter().zip(&clk).zip(&ton) { // a grid at the worst member agrees
        let (n, m) = ((1.0 / h).round() as usize, (1.0 / (2.0 * h)).ceil() as usize); // tone m flips under the delay 1/(2m) <= h
        assert!((c - l1_shift(&click(n, n as f64), h, 0.0, 1.0, 20000)).abs() < 1e-9);
        assert!((t - grid(&|x| (tone(m)(x - 1.0 / (2.0 * m as f64)) - tone(m)(x)).powi(2), 0.0, 1.0, 4000).sqrt()).abs() < 1e-9);
    }
    println!("chart h:            {}", hs.iter().map(|h| h.to_string()).collect::<Vec<_>>().join(", "));
    println!("  blurred, worst:   {}", join(&chart, 4));
    println!("  clicks, worst:    {}", join(&clk, 4));
    println!("  tones (L2), worst: {}", join(&ton, 4));
    let at01: Vec<f64> = [5usize, 20, 10000].iter().map(|&n| l1_shift(&blur_click(n, 0.05), 0.01, -0.05, 0.35, 400000)).collect();
    for (&n, &v) in [5usize, 20, 10000].iter().zip(&at01) { // exact: ramps of width r and height H, plateau P
        let (r, hh, p) = (0.05f64.min(1.0 / n as f64), n as f64 * 0.05f64.min(1.0 / n as f64) / 0.05, (1.0 / n as f64 - 0.05).abs());
        assert!((v - (2.0 * hh * 0.01 - hh * (0.01 - p).max(0.0).powi(2) / (2.0 * r))).abs() < 1e-9);
    }
    println!("  blurred at h = 0.01, n = 5, 20, 10000: {}", join(&at01, 4));

    // 6. What breaks on the whole line: a box sliding away passes the shift test, yet never settles.
    let slide = |n: f64| move |x: f64| if n <= x && x < n + 1.0 { 1.0f64 } else { 0.0 };
    let (b3, b1, b5) = (slide(3.0), slide(1.0), slide(5.0));
    let s1 = grid(&|x| (b3(x - 0.01) - b3(x)).abs(), 0.0, 10.0, 10000);
    let s2 = grid(&|x| (b1(x) - b5(x)).abs(), 0.0, 10.0, 10000);
    assert!((s1 - 0.02).abs() < 1e-9 && (s2 - 2.0).abs() < 1e-9);
    println!("sliding box on the line: shift by 0.01 gives {:.4}; ||b_1 - b_5||_1 = {:.4}", s1, s2);

    // 7. Try changing.
    let v = l1_shift(&blur_click(10000, 0.01), 0.001, -0.05, 0.1, 150000);
    assert!((v - 0.2).abs() < 1e-6);
    println!("try: blur over 0.01 s: worst shift distance at h = 0.001 is {:.4}", v);
    let sq: Vec<f64> = (1..=100000usize).map(|n| 2.0 * (n as f64 * 0.01).min(1.0) / (n as f64).sqrt()).collect();
    let mut best = 1;
    for (i, &s) in sq.iter().enumerate() { if s > sq[best - 1] { best = i + 1; } }
    let top = sq[best - 1];
    let v = l1_shift(&click(best, (best as f64).sqrt()), 0.01, 0.0, 1.0, 20000);
    assert!((v - top).abs() < 1e-9 && (top - 2.0 * 0.01f64.sqrt()).abs() < 1e-9);
    println!("try: height sqrt(n) clicks: worst shift distance at h = 0.01 is {:.4}, at n = {}", top, best);
    println!("ALL CHECKS PASS");
}
