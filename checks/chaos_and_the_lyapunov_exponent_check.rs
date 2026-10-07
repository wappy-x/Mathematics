// The Lyapunov exponent of the logistic map x -> r x (1 - x): the same check in Rust.
// No crates; ln and sin from std are the only borrowed functions.
fn f(r: f64, x: f64) -> f64 { r * x * (1.0 - x) }

fn fmt(v: &[f64]) -> String { v.iter().map(|u| format!("{:.2}", u)).collect::<Vec<_>>().join(", ") }

fn lam(r: f64, mut x: f64) -> (f64, f64, f64) {  // road 1: mean of ln|f'| on one orbit
    let (d0, n) = (1e-9, 200000);                 // road 2: a twin orbit d0 away, no derivative
    for _ in 0..1000 { x = f(r, x) }
    let (mut y, mut s1, mut s2, mut s3) = (x + d0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        s1 += (r * (1.0 - 2.0 * x)).abs().ln();
        s3 += (r * (1.0 - 2.0 * x)).abs();
        x = f(r, x);
        y = f(r, y);
        s2 += ((y - x).abs() / d0).ln();
        y = x + if y > x { d0 } else { -d0 };     // pull the twin back to distance d0
    }
    (s1 / n as f64, s2 / n as f64, s3 / n as f64)
}

fn cross(r: f64, mut x: f64, d: f64) -> i32 {     // steps until two starts d apart differ by 0.5
    let (mut y, mut n) = (x + d, 0);
    while (x - y).abs() < 0.5 && n < 1000 { x = f(r, x); y = f(r, y); n += 1 }
    n
}

fn main() {
    let ((l4, t4, mean4), (l39, t39, _)) = (lam(4.0, 0.2), lam(3.9, 0.2));
    let (mut lo, mut hi) = (0.0_f64, std::f64::consts::PI / 2.0);  // bisection: sin^2(theta) = 0.2
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if mid.sin().powi(2) < 0.2 { lo = mid } else { hi = mid }
    }
    let (mut x, mut prod) = (0.2_f64, 1.0_f64);
    for _ in 0..20 { prod *= (4.0 * (1.0 - 2.0 * x)).abs(); x = f(4.0, x) }
    let (x20, sin20) = (x, (1048576.0 * lo).sin().powi(2));
    let tele = 1048576.0 * ((2097152.0 * lo).sin() / (2.0 * lo).sin()).abs();
    let (hor, gain) = ((0.5_f64 / 1e-10).ln() / l39, 1000.0_f64.ln() / l39);
    let mut c10: Vec<i32> = (0..1000).map(|k| cross(3.9, (k as f64 + 0.5) / 1000.0, 1e-10)).collect();
    c10.sort();
    let m10 = c10.iter().sum::<i32>() as f64 / 1000.0;
    let m13 = (0..1000).map(|k| cross(3.9, (k as f64 + 0.5) / 1000.0, 1e-13)).sum::<i32>() as f64 / 1000.0;
    let med = (c10[499] + c10[500]) as f64 / 2.0;
    let (mut x, mut y, mut gap) = (0.2_f64, 0.2_f64 + 1e-10, Vec::new());
    for n in 0..61 {
        if n % 5 == 0 { gap.push((x - y).abs().ln() / 10.0_f64.ln()) }
        x = f(3.9, x);
        y = f(3.9, y);
    }
    let lr: Vec<f64> = (0..13).map(|k| lam(2.8 + k as f64 / 10.0, 0.2).0).collect();
    let pred: Vec<f64> = (0..13).map(|k| -10.0 + l39 * 5.0 * k as f64 / 10.0_f64.ln()).collect();
    let (ln2, ln08, half016) = (2.0_f64.ln(), 0.8_f64.ln(), 0.16_f64.ln() / 2.0);
    println!("r = 4.0: road 1, average of ln|f'| = {:.4}; road 2, twin orbits = {:.4}; ln 2 = {:.4}", l4, t4, ln2);
    println!("r = 3.9: road 1, average of ln|f'| = {:.4}; road 2, twin orbits = {:.4}; bits per step {:.3}", l39, t39, l39 / ln2);
    println!("r = 4.0, from 0.2: x20 by the map = {:.8}; sin^2(2^20 theta) = {:.8}", x20, sin20);
    println!("product of |f'| over 20 steps = {:.2}; 2^20 |sin 2theta20 / sin 2theta0| = {:.2}", prod, tele);
    println!("horizon at r = 3.9, gap 1e-10 to 0.5: ln(5e9) = {:.2}, / lambda = {:.2} steps", 5e9_f64.ln(), hor);
    println!("1000 starts, first step the gap reaches 0.5: median {:.0}, mean {:.2}, fewest {}, most {}; from 0.2 alone {}",
             med, m10, c10[0], c10[999], cross(3.9, 0.2, 1e-10));
    println!("gap 1e-13 instead: mean {:.2}, {:.2} steps gained; ln(1000) = {:.2}, / lambda = {:.2}", m13, m13 - m10, 1000.0_f64.ln(), gain);
    println!("settled: r = 2.8 gives {:.4}, ln 0.8 = {:.4}; r = 3.2 gives {:.4}, ln(0.16) / 2 = {:.4}; r = 3.5 gives {:.4}",
             lr[0], ln08, lr[4], half016, lr[7]);
    println!("figure, lambda at r = 2.8, 2.9, ..., 4.0: {}", fmt(&lr));
    println!("figure, log10 of the gap from 0.2 at steps 0, 5, ..., 60: {}", fmt(&gap));
    println!("figure, prediction -10 + lambda n / ln 10: {}", fmt(&pred));
    println!("mistake 1, ln of the average |f'| at r = 4: ln {:.4} = {:.4}", mean4, mean4.ln());
    println!("mistake 2, one step from 0.2 at r = 3.9: ln 2.34 = {:.4}, horizon {:.2} steps", 2.34_f64.ln(), 5e9_f64.ln() / 2.34_f64.ln());
    println!("mistake 3, start on the fixed point 0 at r = 4: {:.4} = ln 4", lam(4.0, 0.0).0);
    assert!((l39 - t39).abs() < 0.01 && (l4 - t4).abs() < 0.01);          // two roads to lambda agree
    assert!((l4 - ln2).abs() < 0.005 && (lr[0] - ln08).abs() < 1e-6);
    assert!((prod / tele - 1.0).abs() < 1e-6 && (x20 - sin20).abs() < 1e-6); // the sine-squared telescope
    assert!((med - hor).abs() < 1.0 && (m13 - m10 - gain).abs() < 1.0);
    println!("ALL CHECKS PASS");
}
