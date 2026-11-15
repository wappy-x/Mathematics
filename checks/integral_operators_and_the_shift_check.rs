// Three model operators: the check behind the card.  Rust std only, no crates.
// A blur (weights 1/4, 1/2, 1/4), a fade-in volume mask g(x) = x, a running
// total and a one-sample delay line, each held as a matrix on N samples: the
// finite rehearsal.  Nothing imported knows a norm: power iteration, row sums
// and a sign-pattern search are written out.  Roads: closed forms against
// power iteration; brute force against row sums; exact window integrals
// against midpoint sums; the endless delay line against its cut.
use std::f64::consts::PI;

fn l2(x: &[f64]) -> f64 { x.iter().fold(0.0, |s, v| s + v * v).sqrt() }
fn blur_w(x: &[f64], w: [f64; 3]) -> Vec<f64> { // zero beyond both ends
    let n = x.len();
    (0..n).map(|i| w[0] * (if i > 0 { x[i - 1] } else { 0.0 }) + w[1] * x[i]
        + w[2] * (if i < n - 1 { x[i + 1] } else { 0.0 })).collect()
}
fn blur(x: &[f64]) -> Vec<f64> { blur_w(x, [0.25, 0.5, 0.25]) }
fn power(apply: &dyn Fn(&[f64]) -> Vec<f64>, n: usize, it: usize) -> (f64, Vec<f64>) {
    let mut x = vec![1.0; n]; // largest |Ax|/|x| of a symmetric map, from all ones
    for _ in 0..it {
        let y = apply(&x); let s = l2(&y); x = y.iter().map(|v| v / s).collect();
    }
    (l2(&apply(&x)), x)
}
fn blur_exact(n: usize) -> f64 { let c = (PI / (2 * n + 2) as f64).cos(); c * c }
fn mask_gain(n: usize) -> f64 { (0..n).map(|i| (i as f64 + 0.5) / n as f64).fold(f64::MIN, f64::max) }
fn fmt(xs: &[f64], d: usize) -> String { xs.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(" ") }
fn unit(k: usize) -> Vec<f64> { (0..5).map(|j| if j == k { 1.0 } else { 0.0 }).collect() }
fn window(lo: f64, hi: f64, f: &dyn Fn(f64) -> f64) -> f64 { // midpoint sums of f(t)^2 and 1
    let m = 100000; let h = (hi - lo) / m as f64; let (mut a, mut b) = (0.0, 0.0);
    for i in 0..m { let t = lo + (i as f64 + 0.5) * h; a += f(t) * f(t) * h; b += h; }
    (a / b).sqrt()
}
fn volt(x: &[f64], l: f64) -> Vec<f64> { // (Vx)_i = h(x_1 + ... + x_(i-1) + x_i/2)
    let h = l / x.len() as f64; let mut s = 0.0; let mut y = Vec::new();
    for &v in x { y.push(h * (s + v / 2.0)); s += v; }
    y
}
fn volt_t(y: &[f64], l: f64) -> Vec<f64> {
    let r: Vec<f64> = y.iter().rev().cloned().collect(); volt(&r, l).into_iter().rev().collect()
}
fn cut_delay(x: &[f64]) -> Vec<f64> { let mut y = vec![0.0]; y.extend_from_slice(&x[..x.len() - 1]); y }
fn delay(x: &[f64]) -> Vec<f64> { let mut y = vec![0.0]; y.extend_from_slice(x); y }
fn advance(x: &[f64]) -> Vec<f64> { x[1..].to_vec() }
fn cut_pow(v: &[f64], m: usize) -> Vec<f64> { let mut v = v.to_vec(); for _ in 0..m { v = cut_delay(&v); } v }

fn main() {
    println!("1. blur, N = 5 samples: weights 1/4, 1/2, 1/4, zero beyond the ends");
    let click = [0.0, 0.0, 4.0, 0.0, 0.0]; let out = blur(&click);
    println!("   click {} -> {}", fmt(&click, 1), fmt(&out, 1));
    let (sc, so): (f64, f64) = (click.iter().sum(), out.iter().sum());
    println!("   sum {:.1} -> {:.1}; 2-norm {:.4} -> {:.4}, gain {:.4}", sc, so, l2(&click), l2(&out), l2(&out) / l2(&click));
    assert!(out == vec![0.0, 1.0, 2.0, 1.0, 0.0] && (l2(&out) * l2(&out) - 6.0).abs() < 1e-12);
    let rows: Vec<f64> = (0..5).map(|i| blur(&unit(i)).iter().map(|v| v.abs()).sum()).collect();
    let rmax = rows.iter().cloned().fold(f64::MIN, f64::max);
    println!("   row sums {}; peak gain = largest row sum {:.4}", fmt(&rows, 2), rmax);
    let best = (0..32).map(|k: usize| {
        let s: Vec<f64> = (0..5).map(|j| if (k >> j) & 1 == 1 { 1.0 } else { -1.0 }).collect();
        blur(&s).iter().map(|v| v.abs()).fold(f64::MIN, f64::max)
    }).fold(f64::MIN, f64::max);
    println!("   peak gain, brute force over all 32 sign patterns: {:.4}", best);
    assert!((best - rmax).abs() < 1e-15); // road 2: brute force
    let (g5, v5) = power(&blur, 5, 6000);
    println!("   2-norm gain: power iteration {:.6}; cos^2(pi/12) {:.6}; Schur bound 1", g5, blur_exact(5));
    let vm = v5.iter().cloned().fold(f64::MIN, f64::max);
    println!("   best input, scaled to peak 1: {}", fmt(&v5.iter().map(|v| v / vm).collect::<Vec<_>>(), 4));
    assert!((g5 - blur_exact(5)).abs() < 1e-12 && g5 < 1.0);

    println!("2. as N grows: the gain creeps up to 1 and never reaches it");
    for n in [5usize, 20, 80] {
        let (g, _) = power(&blur, n, 6000);
        println!("   N {:3}: blur power iteration {:.6}, closed form {:.6}, gap {:.6}", n, g, blur_exact(n), 1.0 - g);
        assert!((g - blur_exact(n)).abs() < 1e-10 && g < 1.0); // road 1: closed form
    }
    let ch = [1usize, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 40];
    println!("   chart N    {}", ch.iter().map(|n| format!("{:5}", n)).collect::<Vec<_>>().join(" "));
    println!("   chart blur {}", fmt(&ch.iter().map(|&n| blur_exact(n)).collect::<Vec<_>>(), 3));
    println!("   chart mask {}", fmt(&ch.iter().map(|&n| mask_gain(n)).collect::<Vec<_>>(), 3));

    println!("3. fade-in mask g(x) = x on a 1 s clip, N midpoint samples");
    println!("   N = 5: diagonal {}; gain {:.4}", fmt(&(0..5).map(|i| (i as f64 + 0.5) / 5.0).collect::<Vec<_>>(), 1), mask_gain(5));
    for n in [5usize, 50, 500] {
        let gmin = (0..n).map(|i| (i as f64 + 0.5) / n as f64).fold(f64::MAX, f64::min);
        println!("   N {:3}: gain {:.6}; inverse mask gain {:.0}", n, mask_gain(n), 1.0 / gmin);
    }
    for e in [0.1f64, 0.01, 0.001] {
        let exact = ((1.0 - (1.0 - e).powi(3)) / (3.0 * e)).sqrt(); let q = window(1.0 - e, 1.0, &|t| t);
        let res = window(0.5 - e / 2.0, 0.5 + e / 2.0, &|t| t - 0.5);
        println!("   e {:5.3}: end window gain {:.6} (midpoint {:.6}); bump at 0.5 residual {:.7} (midpoint {:.7})",
            e, exact, q, e / 12f64.sqrt(), res);
        assert!((exact - q).abs() < 1e-9 && exact < 1.0); // road 3: exact integral
        assert!((res - e / 12f64.sqrt()).abs() < 1e-9);
    }

    println!("4. running total (Volterra), N-point midpoint grid on [0, 1]");
    for n in [10usize, 40, 160, 640] {
        let (s2, x) = power(&|x: &[f64]| volt_t(&volt(x, 1.0), 1.0), n, 40);
        let g = l2(&volt(&x, 1.0)); let nf = n as f64;
        println!("   N {:3}: gain {:.9}; gap x N^2 {:.4}; every eigenvalue 1/(2N) = {:.6}", n, g, (2.0 / PI - g) * nf * nf, 1.0 / (2.0 * nf));
        assert!((g - 2.0 / PI).abs() < 0.2 / (nf * nf) && (g * g - s2).abs() < 1e-12);
    }
    println!("   2/pi = {:.6}; Schur bound = 1.0000", 2.0 / PI);

    println!("5. delay line S, one sample per step");
    let x = vec![3.0, 1.0, 4.0, 1.0, 5.0];
    let y = cut_pow(&x, 5); let sx = cut_delay(&x);
    println!("   cut at N = 5: Sx = {}, energy {:.0} -> {:.0}; S^5 x = {}", fmt(&sx, 0), l2(&x) * l2(&x), l2(&sx) * l2(&sx), fmt(&y, 0));
    let mut z = x.clone();
    for _ in 0..12000 { z = delay(&z); }
    let dx = delay(&x);
    println!("   endless: Sx = {}, energy {:.0}; S^12000 x (0.25 s at 48 kHz) energy {:.0}", fmt(&dx, 0), l2(&dx) * l2(&dx), l2(&z) * l2(&z));
    assert!(y == vec![0.0; 5] && l2(&z) == l2(&x) && z[12000..] == x[..]); // road 4: cut against endless
    assert!((l2(&sx) * l2(&sx) - (l2(&x) * l2(&x) - x[4] * x[4])).abs() < 1e-12); // only the last sample is lost
    println!("   advance after delay {}; delay after advance {}", fmt(&advance(&delay(&x)), 0), fmt(&delay(&advance(&x)), 0));
    assert!(advance(&delay(&x)) == x && delay(&advance(&x)) != x);
    let gains: Vec<f64> = (1..7).map(|m| (0..5).map(|k| l2(&cut_pow(&unit(k), m))).fold(f64::MIN, f64::max)).collect();
    println!("   cut S^m, m = 1..6, gain {}; endless S^m gain 1 for every m", fmt(&gains, 0));
    let geo: Vec<f64> = (0..60).map(|n| 0.5f64.powi(n)).collect();
    println!("   advance of (1, 0.5, 0.25, ...) = 0.5 x the list; its 2-norm {:.4}, sqrt(4/3) {:.4}", l2(&geo), (4.0f64 / 3.0).sqrt());

    println!("6. what breaks");
    println!("   largest single blur weight as the peak gain: 0.5000 (true {:.4})", rmax);
    println!("   the cut delay S^5 as the delay's gain: {:.0} (endless list: 1)", gains[4]);
    println!("   Schur bound as the running total's gain: 1.0000 (true {:.4})", 2.0 / PI);
    println!("   the N = 5 mask's gain as the mask's norm: {:.4} (true 1)", mask_gain(5));

    println!("7. try changing");
    let box3 = |x: &[f64]| blur_w(x, [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0]); let (gb, _) = power(&box3, 5, 6000);
    let pb = box3(&[1.0; 5]).iter().map(|v| v.abs()).fold(f64::MIN, f64::max);
    println!("   box blur 1/3 each, N = 5: peak gain {:.4}, 2-norm gain {:.6}", pb, gb);
    assert!((gb - (1.0 + 2.0 * (PI / 6.0).cos()) / 3.0).abs() < 1e-12);
    let gm: Vec<f64> = (0..500).map(|i| 0.5 + 0.5 * (i as f64 + 0.5) / 500.0).collect();
    println!("   mask 0.5 + 0.5x, N = 500: gain {:.6}, inverse mask gain {:.6}",
        gm.iter().cloned().fold(f64::MIN, f64::max), 1.0 / gm.iter().cloned().fold(f64::MAX, f64::min));
    let (_, x2) = power(&|x: &[f64]| volt_t(&volt(x, 2.0), 2.0), 160, 40);
    println!("   running total over 2 s, N = 160: gain {:.6}; 4/pi {:.6}", l2(&volt(&x2, 2.0)), 4.0 / PI);
    println!("   blur at N = 1000: 2-norm gain {:.8}", blur_exact(1000));
    println!("ALL CHECKS PASS");
}
