// Peano's theorem -- the same check as the Python, in Rust.  No crates.
// Euler polygons for y' = sqrt|y| and y' = 1 + y^2, both from y(0) = 0, are
// compared with exact solutions (0, t^2/4, tan t), with the integral equation
// they converge to, and with the blow-up time found as an area by Simpson's rule.
fn euler(f: fn(f64) -> f64, y0: f64, t_end: f64, h: f64) -> Vec<f64> {
    let mut ys = vec![y0];                  // corner values of the polygon at t = 0, h, 2h, ...
    for _ in 0..(t_end / h).round() as usize {
        let y = *ys.last().unwrap();
        ys.push(y + h * f(y));              // new value = old value + step x rate
    }
    ys
}
fn simpson(g: fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // area under g, n even
    let w = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..=n { s += g(a + i as f64 * w) * if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } }
    w / 3.0 * s
}
fn residual(f: fn(f64) -> f64, ys: &[f64], h: f64) -> f64 {   // largest |y(t) - integral of f(y)|
    let (mut area, mut worst) = (0.0f64, 0.0f64);
    for k in 1..ys.len() {
        area += h * (f(ys[k - 1]) + 4.0 * f((ys[k - 1] + ys[k]) / 2.0) + f(ys[k])) / 6.0;   // Simpson, exact here
        worst = worst.max((ys[k] - area).abs());
    }
    worst
}
fn sq(y: f64) -> f64 { y.abs().sqrt() }   fn tn(y: f64) -> f64 { 1.0 + y * y }
fn inv(u: f64) -> f64 { 1.0 / tn(u) }   fn quarter(t: f64) -> f64 { t * t / 4.0 }
fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}
fn late(t: f64) -> f64 { if t < 1.0 { 0.0 } else { (t - 1.0) * (t - 1.0) / 4.0 } }   // rests, then rises
fn main() {
    let hs = [0.1, 0.01, 0.001];
    let stuck: Vec<f64> = hs.iter().map(|&h| *euler(sq, 0.0, 2.0, h).last().unwrap()).collect();
    let miss = (0..201).map(|i| i as f64 / 100.0)    // do t^2/4 and late solve it? slopes by central difference
        .flat_map(|t| [quarter as fn(f64) -> f64, late].map(|g| ((g(t + 1e-6) - g(t - 1e-6)) / 2e-6 - sq(g(t))).abs()))
        .fold(0.0f64, f64::max);
    let ts: Vec<f64> = (0..9).map(|i| i as f64 / 4.0).collect();
    let nudged = *euler(sq, 1e-6, 2.0, 0.001).last().unwrap();
    let b = 1.0f64; let m = tn(b); let tw = (1.0f64).min(b / m);    // box: times 0 to 1, values -1 to 1
    let runs: Vec<Vec<f64>> = hs.iter().map(|&h| euler(tn, 0.0, tw, h)).collect();
    let mut gaps = vec![]; let mut res = vec![]; let mut slope = 0.0f64;
    for (r, &h) in runs.iter().zip(hs.iter()) {
        gaps.push(r.iter().enumerate().map(|(k, y)| (y - (k as f64 * h).tan()).abs()).fold(0.0, f64::max));
        for k in 0..r.len() - 1 { slope = slope.max((r[k + 1] - r[k]).abs() / h) }
        res.push(residual(tn, r, h));
    }
    let (mut t, mut y, h, marks) = (0.0f64, 0.0f64, 1e-6, [10.0f64, 100.0, 1000.0]);
    let mut hit: Vec<f64> = vec![];
    while hit.len() < 3 {                   // Euler until |y| leaves the boxes of size 10, 100, 1000
        y = y + h * tn(y); t = t + h;
        if y > marks[hit.len()] { hit.push(t) }
    }
    let life = 2.0 * simpson(inv, 0.0, 1.0, 1000);   // time to infinity = area under 1/(1 + u^2)
    let past = *euler(tn, 0.0, 2.0, 0.1).last().unwrap();
    let ends: Vec<f64> = runs.iter().map(|r| *r.last().unwrap()).collect();
    let atans: Vec<f64> = marks.iter().map(|x| x.atan()).collect();
    println!("y' = sqrt|y|, y(0) = 0: Euler y(2) with h = 0.1, 0.01, 0.001: {}", fmt(&stuck, 4));
    println!("t^2/4 and waits 1: largest |slope - sqrt(y)| on [0, 2] = {:.6}; 2^2/4 = {:.4}", miss, 2.0 * 2.0 / 4.0);
    println!("chart t:        {}", fmt(&ts, 2));
    println!("chart Euler:    {}", fmt(&vec![0.0; ts.len()], 4));
    println!("chart t^2/4:    {}", fmt(&ts.iter().map(|s| s * s / 4.0).collect::<Vec<_>>(), 4));
    println!("chart waits 1:  {}", fmt(&ts.iter().map(|&s| late(s)).collect::<Vec<_>>(), 4));
    println!("start nudged to 0.000001, h = 0.001: Euler y(2) = {:.6}; exact (1 + 0.001)^2 = {:.6}", nudged, 1.001f64.powi(2));
    println!("y' = 1 + y^2 in the box b = {:.0}: M = {:.0}, window T = min(1, b/M) = {:.2}", b, m, tw);
    println!("Euler y(0.5) with h = 0.1, 0.01, 0.001: {}; tan 0.5 = {:.6}", fmt(&ends, 6), 0.5f64.tan());
    println!("largest gap to tan t on [0, 0.5]: {}", fmt(&gaps, 6));
    println!("steepest polygon segment: {:.4}, under the bound M = {:.0}", slope, m);
    println!("integral-equation residual: {}", fmt(&res, 6));
    println!("Euler (h = 0.000001) leaves |y| <= 10, 100, 1000 at t = {}", fmt(&hit, 4));
    println!("arctan of 10, 100, 1000:                         {}", fmt(&atans, 4));
    println!("blow-up time: 2 x area under 1/(1 + u^2) on [0, 1] = {:.6}; pi/2 = {:.6} = {:.4} to 4 places", life, std::f64::consts::PI / 2.0, std::f64::consts::PI / 2.0);
    println!("mistakes: tan 2 = {:.4}; Euler h = 0.1 run to t = 2: {:.1}", 2.0f64.tan(), past);
    assert!(stuck.iter().all(|&v| v == 0.0) && miss < 1e-6 && (nudged - 1.001f64.powi(2)).abs() < 0.01);
    assert!(gaps[2] < gaps[1] / 5.0 && gaps[1] / 5.0 < gaps[0] / 25.0 && slope <= m);   // converge to tan
    assert!(res[2] < res[1] / 5.0 && res[1] / 5.0 < res[0] / 25.0);                     // obey the equation
    assert!(hit.iter().zip(atans.iter()).all(|(a, b)| (a - b).abs() < 5e-5) && (life - std::f64::consts::PI / 2.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
