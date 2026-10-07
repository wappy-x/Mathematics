// Improper integrals -- the same check as the Python, in Rust.  std only:
// ln and sqrt are primitives; every integral is our own Simpson sum.
// The tap pours 1/t^2 litres a minute from minute 1 on; its rival pours 1/t.

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;                      // Simpson's rule, n strips (n even)
    let inner: f64 = (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}

fn blocks(f: &dyn Fn(f64) -> f64, k: i32) -> Vec<f64> { // areas over [1,2], [2,4], ...
    (0..k).map(|j| simpson(f, 2f64.powi(j), 2f64.powi(j + 1), 64)).collect()
}

fn halving(f: &dyn Fn(f64) -> f64, k: i32) -> f64 {    // areas over [1/2,1], [1/4,1/2], ...
    (0..k).map(|j| simpson(f, 2f64.powi(-(j + 1)), 2f64.powi(-j), 64)).sum()
}

fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let sq = |t: f64| 1.0 / (t * t);
    let inv = |t: f64| 1.0 / t;
    let ln2 = 2f64.ln();
    let r1: Vec<f64> = [10.0, 100.0, 1000.0].iter().map(|b| 1.0 - 1.0 / b).collect();
    println!("road 1, antiderivative 1 - 1/B: B = 10, 100, 1000 -> {}", fmt(&r1, 6));
    let (b2, b1) = (blocks(&sq, 10), blocks(&inv, 10));
    println!("road 2, Simpson on doubling blocks of 1/t^2: {}, ...", fmt(&b2[..4], 6));
    let (s2, s1): (f64, f64) = (b2.iter().sum(), b1.iter().sum());
    println!("  10 blocks, 1 to 1024: sum {:.6}; 1 - 1/1024 = {:.6}", s2, 1.0 - 1.0 / 1024.0);
    assert!((1..=10).all(|k| (b2[..k].iter().sum::<f64>() - (1.0 - 2f64.powi(-(k as i32)))).abs() < 1e-7));
    println!("1/t, same blocks: {}, ...; ln 2 = {:.6}", fmt(&b1[..4], 6), ln2);
    println!("  10 blocks, 1 to 1024: sum {:.6}; ln 1024 = {:.6}", s1, 1024f64.ln());
    assert!(b1.iter().all(|x| (x - ln2).abs() < 1e-7));
    let run2: Vec<f64> = (0..=10).map(|k| 0.0 + b2[..k].iter().sum::<f64>()).collect();
    let run1: Vec<f64> = (0..=10).map(|k| 0.0 + b1[..k].iter().sum::<f64>()).collect();
    println!("chart, 1/t^2 totals at B = 1, 2, 4, ..., 1024: [{}]", fmt(&run2, 2));
    println!("chart, 1/t totals at the same B: [{}]", fmt(&run1, 2));
    println!("within 0.001 of 1: tail 1/B at B = 999 is {:.6}, at B = 1000 {:.6}", 1.0 / 999.0, 1.0 / 1000.0);
    let ps = [1.5f64, 2.0, 3.0];
    let pt: Vec<f64> = ps.iter().map(|&p| blocks(&|t: f64| t.powf(-p), 60).iter().sum()).collect();
    let exact: Vec<f64> = ps.iter().map(|p| 1.0 / (p - 1.0)).collect();
    println!("p-test at infinity, p = 1.5, 2, 3: 60 blocks {}; 1/(p - 1) = {}", fmt(&pt, 6), fmt(&exact, 6));
    assert!(pt.iter().zip(&exact).all(|(x, e)| (x - e).abs() < 1e-6));
    let spk = [halving(&|t: f64| 1.0 / t.sqrt(), 20), halving(&|t: f64| 1.0 / t.sqrt(), 40)];
    let cut: Vec<f64> = [0.01f64, 1e-4, 1e-6].iter().map(|s| 2.0 - 2.0 * s.sqrt()).collect();
    println!("spike 1/sqrt(t) on [s, 1]: 2 - 2 sqrt(s) at s = 0.01, 0.0001, 0.000001 -> {}", fmt(&cut, 6));
    println!("  Simpson on halving blocks: 20 blocks {:.6}, 40 blocks {:.6}; formula {:.6}, {:.6}",
             spk[0], spk[1], 2.0 - 2.0 * 2f64.powi(-10), 2.0 - 2.0 * 2f64.powi(-20));
    let cmp: f64 = blocks(&|t: f64| 1.0 / (t * t + t), 40).iter().sum();
    println!("comparison, 1/(t^2 + t) below 1/t^2: 40 blocks {:.6}, under the cap 1; partial fractions give ln 2 = {:.6}",
             cmp, ln2);
    assert!((spk[1] - (2.0 - 2.0 * 2f64.powi(-20))).abs() < 1e-7 && (cmp - ln2).abs() < 1e-7);
    let big: Vec<f64> = [100f64, 10000.0].iter().map(|b| 2.0 * b.sqrt() - 2.0).collect();
    println!("comparison, 1/sqrt(t) above 1/t from 1: totals {} at B = 100, 10000", fmt(&big, 6));
    println!("break 1, stop at B = 100 and call it done: {:.6}, missing tail {:.6}", 1.0 - 1.0 / 100.0, 1.0 / 100.0);
    let neg: Vec<f64> = [1e3f64, 1e6].iter().map(|b| -b.ln()).collect();
    println!("break 2, -1/t is below 1/t^2 yet its totals are {} at B = 1000, 1000000", fmt(&neg, 6));
    println!("break 3, 1/t on [-1, 1]: gaps 0.01 and 0.01 sum {:.6}; gaps 0.01 and 0.02 sum {:.6}",
             0.01f64.ln() - 0.01f64.ln(), 0.01f64.ln() - 0.02f64.ln());
    println!("break 4, -1/t across 0 for 1/t^2 on [-1, 1] gives {:.0}; from 1/1024 to 1 alone {:.2}",
             -1.0 / 1.0 - (-1.0 / -1.0), halving(&sq, 10));
    println!("ALL CHECKS PASS");
}
