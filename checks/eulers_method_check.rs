// Euler's method -- the same check as the Python, in Rust, std only.
// The skydiver obeys v' = 9.8 - 0.2 v, v(0) = 0, time in s, speed in m/s.
// Road one: Euler's loop.  Road two: the exact solution 49 (1 - e^(-0.2 t)).
// Road three: the loop's own closed form, 49 (1 - (1 - 0.2 h)^n).

fn f(_t: f64, v: f64) -> f64 { 9.8 - 0.2 * v } // the rate law, m/s per s

fn euler(h: f64, t_end: f64) -> Vec<f64> {      // step along the current slope
    let (mut t, mut v, mut path) = (0.0, 0.0, vec![0.0]);
    for _ in 0..(t_end / h).round() as i32 {
        v += h * f(t, v);
        t += h;
        path.push(v);
    }
    path
}

fn exact(t: f64) -> f64 { 49.0 * (1.0 - (-0.2 * t).exp()) } // by separating variables

fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn last(h: f64, t_end: f64) -> f64 { *euler(h, t_end).last().unwrap() }

fn main() {
    let (hs, tt) = ([2.0, 1.0, 0.5, 0.25], 10.0);
    let errs: Vec<f64> = hs.iter().map(|&h| last(h, tt) - exact(tt)).collect();
    println!("euler, h = 2, t = 0, 2, ..., 10: {}", fmt(&euler(2.0, tt), 2));
    let drag: Vec<f64> = euler(2.0, tt)[..5].iter().map(|v| 0.2 * v).collect();
    println!("euler, h = 2, drag 0.2v at each step: {}", fmt(&drag, 3));
    let fine1: Vec<f64> = euler(1.0, tt).into_iter().step_by(2).collect();
    println!("euler, h = 1, t = 0, 2, ..., 10: {}", fmt(&fine1, 2));
    let ex: Vec<f64> = (0..6).map(|k| exact(2.0 * k as f64)).collect();
    println!("exact, t = 0, 2, ..., 10: {}", fmt(&ex, 2));
    for (&h, &e) in hs.iter().zip(&errs) {
        println!("step {}: euler v(10) = {:.4}, exact {:.4}, error {:.4}, error/h {:.4}",
                 h, last(h, tt), exact(tt), e, e / h);
    }
    let ratios: Vec<f64> = (0..3).map(|i| errs[i] / errs[i + 1]).collect();
    println!("error ratio each time the step halves: {}", fmt(&ratios, 2));
    let closed: Vec<f64> =
        hs.iter().map(|&h| 49.0 * (1.0 - (1.0 - 0.2 * h).powi((tt / h).round() as i32))).collect();
    println!("closed form 49(1 - (1 - 0.2h)^n) at t = 10: {}", fmt(&closed, 4));
    let local: Vec<f64> = hs[..3].iter().map(|&h| last(h, h) - exact(h)).collect();
    println!("one step from rest, error at h = 2, 1, 0.5: {}", fmt(&local, 4));
    let (pred, fine) = (9.8 * (-2.0f64).exp(), last(0.001, tt) - exact(tt));
    println!("predicted error per second of step, 9.8 e^(-2): {:.4}; step 0.001 gives error {:.6}",
             pred, fine);
    let (l, m) = (0.2, 1.96);                   // rule's slope in v; largest |v''|
    let bound = m / (2.0 * l) * ((l * tt).exp() - 1.0);
    println!("guaranteed bound (M / 2L)(e^(LT) - 1) h with L = 0.2, M = 1.96: {:.2} h", bound);
    let (x, y) = (|t: f64| 50.0 + 140.0 * t, |v: f64| 200.0 - 8.0 * v);
    let curve: Vec<String> = (0..9)
        .map(|k| { let t = k as f64 / 4.0; format!("{:.1},{:.1}", x(t), y(exact(t))) }).collect();
    println!("figure, curve (px): {}", curve.join(" "));
    println!("figure, tangent end {:.1},{:.1}; curve end {:.1},{:.1}",
             x(2.0), y(19.6), x(2.0), y(exact(2.0)));
    let mut no_h = 0.0;
    for _ in 0..5 { no_h += f(0.0, no_h) }      // five steps, the h left out
    println!("mistake, h left out (five steps of v + f): 'v(10)' = {:.2}", no_h);
    println!("mistake, slope never updated: 9.8 x 10 = {:.2}", 9.8 * tt);
    println!("mistake, h = 15 past the limit 2 / 0.2 = {:.0}: v(60) = {:.2}, exact {:.2}",
             2.0 / 0.2, last(15.0, 60.0), exact(60.0));
    assert!(hs.iter().zip(&closed).all(|(&h, &c)| (last(h, tt) - c).abs() < 1e-9));
    assert!(ratios.iter().all(|&r| 1.9 < r && r < 2.2));   // first order: error halves
    assert!(((fine / 0.001 - pred) / pred).abs() < 0.01);  // error/h -> 9.8 e^(-2)
    assert!(hs.iter().zip(&errs).all(|(&h, &e)| 0.0 < e && e <= bound * h));
    println!("ALL CHECKS PASS");
}
