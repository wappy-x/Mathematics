// Universal approximation -- the same check as the Python, in Rust.  No crates.
// A one-hidden-layer ReLU network with 10 units is built to equal the straight-
// line join of sin x at 11 points on [0, pi].  Roads: the network against the
// join read off piece by piece; the error measured at 10,001 points against the
// bound h^2/8 and a midpoint formula; four broken hypotheses, two of them with a
// lower bound proved by a divided difference (a sum that wipes out every
// straight line or every parabola); and a training run whose units are dead.
use std::f64::consts::PI;

fn relu(z: f64) -> f64 { if z > 0.0 { z } else { 0.0 } }

struct Net { c: f64, a: Vec<f64>, kinks: Vec<f64>, xs: Vec<f64>, ys: Vec<f64> }

fn build(f: &dyn Fn(f64) -> f64, n: usize) -> Net {   // unit k computes relu(1 * x - x_k)
    let xs: Vec<f64> = (0..=n).map(|k| k as f64 * PI / n as f64).collect();
    let ys: Vec<f64> = xs.iter().map(|&x| f(x)).collect();
    let s: Vec<f64> = (0..n).map(|k| (ys[k + 1] - ys[k]) / (xs[k + 1] - xs[k])).collect();
    let mut a = vec![s[0]];
    for k in 1..n { a.push(s[k] - s[k - 1]) }
    Net { c: ys[0], a, kinks: xs[..n].to_vec(), xs, ys }
}

fn net(m: &Net, x: f64) -> f64 {
    let mut out = m.c;
    for (ak, bk) in m.a.iter().zip(m.kinks.iter()) { out += ak * relu(x - bk) }
    out
}

fn join(xs: &[f64], ys: &[f64], x: f64) -> f64 {     // road two: find the piece, draw its chord
    let mut j = 0;
    while j < xs.len() - 2 && x > xs[j + 1] { j += 1 }
    let t = (x - xs[j]) / (xs[j + 1] - xs[j]);
    ys[j] + t * (ys[j + 1] - ys[j])
}

fn grid() -> Vec<f64> { (0..=10000).map(|i| i as f64 * PI / 10000.0).collect() }

fn max_err(f: &dyn Fn(f64) -> f64, n: usize) -> (f64, f64) {
    let m = build(f, n);
    let (mut best, mut at) = (-1.0, 0.0);
    for x in grid() {
        let e = (f(x) - net(&m, x)).abs();
        if e > best || (e == best && x > at) { best = e; at = x }
    }
    (best, at)
}

fn bound(n: usize) -> f64 { (PI / n as f64).powi(2) / 8.0 }   // M h^2 / 8 with M = 1 for sin

fn ddiff(pts: &[f64], f: &dyn Fn(f64) -> f64) -> f64 {        // lower bound on the miss of
    let mut w = Vec::new();                                    // every polynomial of degree
    for i in 0..pts.len() {                                    // pts.len() - 2
        let mut p = 1.0;
        for j in 0..pts.len() { if j != i { p *= pts[i] - pts[j] } }
        w.push(1.0 / p);
    }
    let num: f64 = w.iter().zip(pts.iter()).map(|(wi, &x)| wi * f(x)).sum();
    num.abs() / w.iter().map(|wi| wi.abs()).sum::<f64>()
}

fn joined(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let sin = |x: f64| x.sin();
    let m = build(&sin, 10);
    let gap = grid().iter().map(|&x| (net(&m, x) - join(&m.xs, &m.ys, x)).abs()).fold(0.0, f64::max);
    let (err, at) = max_err(&sin, 10);
    let mid = (0.45 * PI).sin() * (1.0 - (PI / 20.0).cos());
    let h = PI / 10.0;
    println!("sin x on [0, pi]: 10 hidden ReLU units, kinks at x_k = k*pi/10, k = 0 to 9");
    println!("output weights a_k: {}", joined(&m.a, 4));
    println!("numbers in the network: 10 weights + 10 biases + 10 output weights + 1 output bias = 31");
    println!("network against the chord join, largest gap over 10,001 points below 1e-12: {}", if gap < 1e-12 { "yes" } else { "no" });
    println!("h = pi/10 = {:.6}; h^2 = {:.6}; bound h^2/8 = {:.6}", h, h * h, bound(10));
    println!("measured max error at 10,001 points: {:.6} at x = {:.4}", err, at);
    println!("midpoint formula sin(0.45 pi)(1 - cos(pi/20)): {:.6}", mid);
    println!("measured / bound: {:.4}", err / bound(10));
    println!("units | max error | bound h^2/8 | error ratio to the row above");
    let sizes = [5usize, 10, 20, 40, 80];
    let mut errs: Vec<f64> = Vec::new();
    for (i, &n) in sizes.iter().enumerate() {
        errs.push(max_err(&sin, n).0);
        let ratio = if i > 0 { format!("{:.4}", errs[i - 1] / errs[i]) } else { "-".to_string() };
        println!("{} | {:.6} | {:.6} | {}", n, errs[i], bound(n), ratio);
    }
    let target = bound(10) / 2.0;
    let need = PI / (8.0 * target).sqrt();
    let mut n_half = 10;
    while bound(n_half) > target { n_half += 1 }
    println!("halve the error: target {:.6}; formula pi/sqrt(8 target) = {:.2} units, {:.4} times 10; bound at 14 = {:.6}, at 15 = {:.6}; smallest: {}",
             target, need, need / 10.0, bound(14), bound(15), n_half);
    for eps in [0.01f64, 0.001, 0.0001] {
        let n = (PI / (8.0 * eps).sqrt()).ceil() as usize;
        println!("error {}: units by the bound {}; measured error {:.6}", eps, n, max_err(&sin, n).0);
    }
    let dims: Vec<String> = [1u32, 2, 3].iter().map(|&d| format!("d = {}: {}", d, 10u64.pow(d))).collect();
    println!("grid of 10 pieces per axis: {}; d = 784: 10^784", dims.join("; "));
    let step = |x: f64| if x >= 1.6 { 1.0 } else { 0.0 };
    let jump: Vec<f64> = [10usize, 20, 40, 80].iter().map(|&n| max_err(&step, n).0).collect();
    println!("break 1, a jump of 1 at x = 1.6, max error at 10, 20, 40, 80 units: {}", joined(&jump, 3));
    println!("break 2, outside [0, pi]: network at 2 pi = {:.4}, sin 2 pi = 0; at 4: network {:.4}, sin {:.4}",
             net(&m, 2.0 * PI), net(&m, 4.0), (4.0f64).sin());
    let line_low = ddiff(&[0.0, PI / 2.0, PI], &sin);
    let line_hi = grid().iter().map(|&x| (x.sin() - 0.5).abs()).fold(0.0, f64::max);
    println!("break 3, no kink (identity units): every line misses by >= {:.6}; the constant 0.5 misses by {:.6}", line_low, line_hi);
    let g = 48usize;
    let (mut par_low, mut best) = (0.0, (0, 0, 0, 0));
    for i in 0..=g { for j in i + 1..=g { for k in j + 1..=g { for l in k + 1..=g {
        let p = |q: usize| q as f64 * PI / g as f64;
        let v = ddiff(&[p(i), p(j), p(k), p(l)], &sin);
        if v > par_low { par_low = v; best = (i, j, k, l) }
    }}}}
    let para = |x: f64| 4.0 * x * (PI - x) / (PI * PI);
    let miss = grid().iter().map(|&x| (x.sin() - para(x)).abs()).fold(0.0, f64::max);
    let par_hi = grid().iter().map(|&x| (x.sin() - (para(x) - miss / 2.0)).abs()).fold(0.0, f64::max);
    println!("break 4, square units, any width: every parabola misses by >= {:.6} (points ({}, {}, {}, {}) x pi/48); parabola through 0, pi/2, pi misses by {:.6}; lowered by half: {:.6}",
             par_low, best.0, best.1, best.2, best.3, miss, par_hi);
    let tx: Vec<f64> = (0..=100).map(|j| j as f64 * PI / 100.0).collect();   // 101 training points
    let (mut ta, tw, tb, mut tc, mut dead) = (vec![0.5; 10], vec![1.0; 10], vec![-4.0; 10], 0.0f64, 0.0f64);
    for _ in 0..300 {                                                       // gradient descent, rate 0.1
        let (mut ga, mut gw, mut gb, mut gc) = (vec![0.0; 10], vec![0.0; 10], vec![0.0; 10], 0.0);
        for &x in &tx {
            let z: Vec<f64> = (0..10).map(|k| tw[k] * x + tb[k]).collect();
            let d = 2.0 * (tc + (0..10).map(|k| ta[k] * relu(z[k])).sum::<f64>() - x.sin()) / 101.0;
            gc += d;
            for k in 0..10 {
                let on = if z[k] > 0.0 { 1.0 } else { 0.0 };
                ga[k] += d * relu(z[k]); gw[k] += d * ta[k] * on * x; gb[k] += d * ta[k] * on;
            }
        }
        for gv in ga.iter().chain(gw.iter()).chain(gb.iter()) { dead = dead.max(gv.abs()) }
        tc -= 0.1 * gc;
        for k in 0..10 { ta[k] -= 0.1 * ga[k] }
    }
    let closed = 1.0 / (PI / 200.0).tan() / 101.0;                          // sum of sin(j pi/100) = cot(pi/200)
    let stuck = grid().iter().map(|&x| (x.sin() - tc).abs()).fold(0.0, f64::max);
    println!("training with every kink at x = 4: largest unit gradient over 300 steps {:.1}; output bias {:.6}; mean of sin at the 101 points {:.6}; max error {:.6}",
             dead, tc, closed, stuck);
    let fit40 = |x: f64| net(&m, x) + (0..10).map(|j| relu(x - m.xs[j]) - 2.0 * relu(x - m.xs[j] - h / 2.0) + relu(x - m.xs[j + 1])).sum::<f64>() * 2.0 / h;
    let memo = m.xs.iter().map(|&x| (fit40(x) - x.sin()).abs()).fold(0.0, f64::max);   // 30 more units: a tent on each piece
    let wild = grid().iter().map(|&x| (fit40(x) - x.sin()).abs()).fold(0.0, f64::max);
    println!("generalisation, 10 units + 30 tent units: error at the 11 samples below 1e-12: {}; max error at 10,001 points {:.6}",
             if memo < 1e-12 { "yes" } else { "no" }, wild);
    let fig: Vec<f64> = (0..=40).map(|i| { let x = i as f64 * PI / 40.0; (x.sin() - net(&m, x)).abs() }).collect();
    println!("figure, error at x = i*pi/40, i = 0 to 40: {}", joined(&fig, 4));
    assert!(gap < 1e-12);                                      // network = chord join
    assert!(0.98 * bound(10) < err && err <= bound(10));       // bound holds and is nearly tight
    assert!((err - mid).abs() < 1e-6);                         // scan agrees with the formula
    assert!((1..5).all(|i| errs[i - 1] / errs[i] > 3.9 && errs[i - 1] / errs[i] < 4.1));
    assert!(n_half == 15 && (need / 10.0 - 2f64.sqrt()).abs() < 1e-9);
    assert!(jump.iter().all(|&v| v >= 0.5));                   // continuity: no width helps
    assert!((line_low - 0.5).abs() < 1e-12 && (line_hi - 0.5).abs() < 1e-12);
    assert!(par_low <= par_hi && par_hi < par_low + 1e-4 && par_low > 2.0 * bound(10));
    assert!(dead == 0.0 && (tc - closed).abs() < 1e-12 && (stuck - closed).abs() < 1e-12);
    assert!(memo < 1e-12 && (wild - (1.0 - (PI / 20.0).sin() * (1.0 - (PI / 20.0).cos()))).abs() < 1e-9);   // tent 1 minus the smallest midpoint gap
    println!("ALL CHECKS PASS");
}
