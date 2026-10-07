// Parseval's identity -- the same check as the Python, in Rust.  No crates;
// std gives pi, sin and cos, nothing more.  The signal is the sawtooth f(x) = x
// on (-pi, pi).  Its coefficients come from numerical integration and from the
// closed form, and the energy ledger is balanced by two independent roads.
use std::f64::consts::PI;
const M: usize = 40000; // midpoints across one cycle
const BIG: usize = 1_000_000;

fn integral(g: impl Fn(f64) -> f64) -> f64 { // midpoint rule over one cycle
    let dx = 2.0 * PI / M as f64;
    (0..M).map(|k| g(-PI + (k as f64 + 0.5) * dx)).sum::<f64>() * dx
}
fn b(n: f64) -> f64 { integral(|x| x * (n * x).sin()) / PI } // sawtooth sine coefficient
fn a(n: f64) -> f64 { integral(|x| x.abs() * (n * x).cos()) / PI } // triangle |x| cosine coefficient
fn partial(n_max: usize, p: i32, start: usize, step: usize) -> f64 { // sum of 1/n^p
    (start..=n_max).step_by(step).map(|n| 1.0 / (n as f64).powi(p)).sum()
}
fn row(v: &[f64], d: usize) -> String {
    v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let energy = integral(|x| x * x) / PI; // (1/pi) times the integral of f^2
    let bs: Vec<f64> = (1..9).map(|n| b(n as f64)).collect();
    let closed: Vec<f64> = (1..9).map(|n| 2.0 * if n % 2 == 1 { 1.0 } else { -1.0 } / n as f64).collect();
    let share: Vec<f64> = bs.iter().map(|t| t * t).collect();
    let run: Vec<f64> = (0..8).map(|k| share[..=k].iter().sum()).collect();
    let resid = integral(|x| (x - (1..4).map(|n| bs[n - 1] * (n as f64 * x).sin()).sum::<f64>()).powi(2)) / PI;
    let big = BIG as f64;
    let direct = partial(BIG, 2, 1, 1) + 1.0 / big - 1.0 / (2.0 * big * big); // tail past BIG, estimated
    let (a0, a1, a3) = (a(0.0), a(1.0), a(3.0));
    let quart = (energy - a0 * a0 / 2.0) * PI * PI / 15.0; // Parseval on |x|: odd n, times 16/15
    let quart_direct = partial(20000, 4, 1, 1);
    let tri_tail: Vec<f64> = [10, 100].iter().map(|&n| 16.0 / (PI * PI) * partial(20001, 4, n + 1 + n % 2, 2)).collect();
    let ns = [10, 100, 1000];
    println!("sawtooth energy (1/pi) int f^2, midpoint rule: {:.6}; 2 pi^2/3 = {:.6}", energy, 2.0 * PI * PI / 3.0);
    println!("b_n, n=1..4, integrated: {} ; closed form 2(-1)^(n+1)/n: {}", row(&bs[..4], 6), row(&closed[..4], 6));
    println!("harmonic share b_n^2, n=1..8: {}", row(&share, 2));
    println!("running total, n=1..8: {}", row(&run, 2));
    println!("running total 4 sum 1/n^2 at N = 10, 100, 1000: {}", row(&ns.map(|n| 4.0 * partial(n, 2, 1, 1)), 4));
    println!("shortfall from 2 pi^2/3 at N = 10, 100, 1000: {}", row(&ns.map(|n| energy - 4.0 * partial(n, 2, 1, 1)), 4));
    println!("ledger after 3 harmonics: {:.6}; missed, integrated: {:.6}; energy minus ledger: {:.6}", run[2], resid, energy - run[2]);
    println!("sum 1/n^2 by Parseval, energy/4: {:.9}", energy / 4.0);
    println!("sum 1/n^2 added directly to 10^6, plus tail: {:.9}; pi^2/6 = {:.9}", direct, PI * PI / 6.0);
    println!("1-ohm reading: mean power {:.4} W; harmonics 1, 2, 3 give {} W; 2 and up {:.4} W",
             energy / 2.0, row(&share[..3].iter().map(|s| s / 2.0).collect::<Vec<_>>(), 4), (energy - share[0]) / 2.0);
    println!("triangle |x|: a_0 = {:.6}, a_1 = {:.6}, a_3 = {:.6}; -4/pi = {:.6}", a0, a1, a3, -4.0 / PI);
    println!("sum 1/n^4 by Parseval on |x|: {:.9}; added directly: {:.9}", quart, quart_direct);
    let nn = [1.0, 9.0, 99.0];
    println!("decay at n = 1, 9, 99: sawtooth n |b_n| {} ; triangle n^2 |a_n| {}",
             row(&nn.map(|n| n * b(n).abs()), 4), row(&nn.map(|n| n * n * a(n).abs()), 4));
    println!("triangle energy missed after N = 10, 100: {}", row(&tri_tail, 7));
    println!("mistake 1, no 1/pi in front: sum 1/n^2 would be {:.4}", energy * PI / 4.0);
    println!("mistake 2, a_0^2 not halved: sum 1/n^4 would be {:.4}", (energy - a0 * a0) * PI * PI / 15.0);
    let sines: f64 = (1..9).map(|n| (integral(|x| x.abs() * (n as f64 * x).sin()) / PI).powi(2)).sum();
    println!("mistake 3, sines only for |x|: ledger {:.4} against energy {:.4}", sines, energy);
    assert!(bs.iter().zip(&closed).all(|(u, v)| (u - v).abs() < 1e-6)); // integration against closed form
    assert!((energy / 4.0 - direct).abs() < 1e-7); // Parseval against direct summing
    assert!((resid - (energy - run[2])).abs() < 1e-6); // Pythagoras for the leftover
    assert!((quart - quart_direct).abs() < 1e-7); // second case, 1/n^4
    println!("ALL CHECKS PASS");
}
