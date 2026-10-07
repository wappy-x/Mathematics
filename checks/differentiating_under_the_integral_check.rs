// Differentiating under the integral -- the same check as the Python, in Rust.
// No crates.  Only exp and e come from std; every integral is the card's own
// Simpson sum.  Road one integrates x^n e^(-tx) directly; road two differentiates
// the easy total 1/t n times.  Then the bounded rule, a moving cutoff, a failure.
use std::f64::consts::E;

fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, m: usize) -> f64 {   // parabolas through equal steps
    let w = (b - a) / m as f64;
    let mut s = 0.0;
    for i in 0..=m {
        let c = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += c * g(a + i as f64 * w);
    }
    w / 3.0 * s
}

fn area(n: i32, t: f64) -> f64 { simpson(|x| x.powi(n) * (-t * x).exp(), 0.0, 60.0, 6000) }

fn by_parameter(n: i32, t: f64) -> f64 {        // (1/t) differentiated n times, sign dropped
    let mut p = 1.0;
    for k in 1..=n { p *= k as f64 }
    p / t.powi(n + 1)
}

fn bad(x: f64, t: f64) -> f64 { if x == 0.0 && t == 0.0 { 0.0 } else { x * t.powi(3) / (x * x + t * t).powi(2) } }

fn main() {
    for n in 1..=3 {
        let row: Vec<String> = (0..13).map(|x| format!("{:.2}", (x as f64).powi(n) * (-(x as f64)).exp())).collect();
        println!("chart n={}: {}", n, row.join(" "));
    }
    let lad: Vec<f64> = (0..5).map(|n| area(n, 1.0)).collect();
    let fmt = |v: Vec<f64>| v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ");
    println!("t=1, n=0..4, Simpson on [0, 60]:  {}", fmt(lad.clone()));
    println!("t=1, n=0..4, n!/t^(n+1):          {}", fmt((0..5).map(|n| by_parameter(n, 1.0)).collect()));
    println!("n=3, t=2: Simpson {:.6}; 3!/2^4 {:.6}; forget the t: 6", area(3, 2.0), by_parameter(3, 2.0));
    let f10 = |t: f64| simpson(|x| (-t * x).exp(), 0.0, 10.0, 2000);
    let slope = simpson(|x| -x * (-x).exp(), 0.0, 10.0, 2000);
    println!("bounded rule on [0, 10] at t=1: integral of -x e^(-x) {:.9}; closed -(1 - 11/e^10) {:.9}", slope, -(1.0 - 11.0 * (-10.0f64).exp()));
    let worst = (0..=10000).map(|x| { let x = x as f64 / 1000.0; x * x * (-x / 2.0).exp() }).fold(0.0, f64::max);
    let mut miss = Vec::new();
    for h in [0.1, 0.01, 0.001] {
        let dq = (f10(1.0 + h) - f10(1.0)) / h;
        miss.push((h, (dq - slope).abs()));
        println!("  difference quotient, h={}: {:.9}, off by {:.9}; guaranteed within {:.6}", h, dq, (dq - slope).abs(), 10.0 * worst * h);
    }
    println!("tolerance game: worst x^2 e^(-x/2) on [0, 10] {:.3}; step for 0.001: {:.7}", worst, 0.001 / (10.0 * worst));
    let cut = simpson(|x| x.powi(3) * (-x).exp(), 0.0, 10.0, 2000);
    let closed = 6.0 * (1.0 - (-10.0f64).exp() * (1.0 + 10.0 + 50.0 + 1000.0 / 6.0));
    let tail60 = 96.0 * (-30.0f64).exp() * (1.0 + 30.0 + 450.0 + 4500.0);
    println!("n=3 cut at b=10: Simpson {:.6}; endpoint-built {:.6}; tail {:.6}; worst tail at b=60, t>=1/2: {:.9}", cut, closed, 6.0 - closed, tail60);
    let j = |t: f64| simpson(|x| x * (-t * x).exp(), 0.0, 1.0 / t, 2000);
    let inner = simpson(|x| -x * x * (-x).exp(), 0.0, 1.0, 2000);
    let edge = 1.0 * (-1.0f64).exp() * -1.0;     // f(1, b(1)) times b'(1), b(t) = 1/t
    let dqj = (j(1.0001) - j(0.9999)) / 0.0002;
    println!("moving cutoff b=1/t at t=1: J {:.6}; inside {:.6}; endpoint {:.6}; sum {:.6}", j(1.0), inner, edge, inner + edge);
    println!("  J'(1) by difference quotient {:.6}; closed -2 + 4/e {:.6}", dqj, -2.0 + 4.0 / E);
    println!("mistakes: drop the endpoint {:.6}; flip its sign {:.6}", inner, inner - edge);
    let fb = simpson(|x| bad(x, 0.01), 0.0, 1.0, 20000);
    println!("broken hypothesis: slope of total at t=0 {:.6}; integral of slopes 0; quotient at x=t=0.01 {:.1}", fb / 0.01, bad(0.01, 0.01) / 0.01);
    assert!((0..5).all(|n| (lad[n as usize] - by_parameter(n, 1.0)).abs() < 1e-6) && (area(3, 2.0) - by_parameter(3, 2.0)).abs() < 1e-7);
    assert!(miss.iter().all(|&(h, m)| m <= 10.0 * worst * h) && miss[2].1 < 1e-3 && (slope + 1.0 - 11.0 * (-10.0f64).exp()).abs() < 1e-9);
    assert!((cut - closed).abs() < 1e-8 && (fb / 0.01 - 0.5).abs() < 1e-4);
    assert!((dqj - (inner + edge)).abs() < 1e-6 && (dqj - (-2.0 + 4.0 / E)).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
