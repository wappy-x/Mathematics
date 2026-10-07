// The Lebesgue differentiation theorem -- the same check as the Python, in Rust, no crates.
// Exact fractions are written by hand: a numerator and denominator in i128.
// Demand f(t) in kW, t in minutes: 2 + t^2/200 before minute 20, 5 from 20 to 45,
// 3 from 45 to 60; the log also holds a glitch, f(30) = 100, at one instant.
// Road 1: exact window averages from the running total F, in fractions.
// Road 2: the same averages summed as a meter would: 2000 midpoint samples.
// Road 3: the closed forms worked by hand on the card.
// Maximal inequality: g = f - phi, phi the continuous ramp version of f. The set
// where the largest average of |g| beats alpha, found on a grid, against the
// bound 3 ||g||_1 / alpha, with the Vitali greedy choice run on the witnesses.
// Failures: the jump instants, the glitch, the maximal function of a block, and 1/|x|.
// The code checks windows down to h = 0.001 on grids; that averages converge at
// almost every point of every integrable f is the proof's work.
#[derive(Clone, Copy, Debug)]
struct Q(i128, i128); // numerator, denominator > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs().max(1) } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl PartialEq for Q { fn eq(&self, o: &Q) -> bool { self.0 * o.1 == o.0 * self.1 } }
impl Q { fn f(self) -> f64 { self.0 as f64 / self.1 as f64 } fn lt(self, n: i128) -> bool { self.0 < n * self.1 } }
fn z(n: i128) -> Q { q(n, 1) }

fn f(t: f64) -> f64 {
    if t == 30.0 { return 100.0; } // the glitch: one instant
    if t < 20.0 { 2.0 + t * t / 200.0 } else if t < 45.0 { 5.0 } else { 3.0 }
}
fn big_f(t: Q) -> Q { // integral of f from 0 to t
    if t.lt(20) { z(2) * t + t * t * t / z(600) }
    else if t.lt(45) { q(160, 3) + z(5) * (t - z(20)) } else { q(535, 3) + z(3) * (t - z(45)) }
}
fn avg(t: i128, h: Q) -> Q { (big_f(z(t) + h) - big_f(z(t) - h)) / (z(2) * h) } // road 1
fn meter(fun: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // road 2: midpoint sum
    let w = (b - a) / n as f64;
    (0..n).fold(0.0, |s, k| s + fun(a + (k as f64 + 0.5) * w)) * w
}
fn closed(t: i128, h: Q) -> Q { // road 3
    match t { 10 => q(5, 2) + h * h / z(600), 20 => q(9, 2) - h / z(20) + h * h / z(1200), 30 => z(5), 45 => z(4), _ => z(3) }
}
fn gg(x: f64, d: f64) -> f64 { // integral of |g| up to x
    let (u, v) = ((x - 20.0).max(0.0).min(d), (x - 45.0).max(0.0).min(d));
    (u - u * u / (2.0 * d)) + (2.0 * v - v * v / d)
}
fn phi(t: f64, d: f64) -> f64 { // continuous: jumps ramped, no glitch
    if t == 30.0 { return 5.0; }
    if 20.0 <= t && t < 20.0 + d { return 4.0 + (t - 20.0) / d; }
    if 45.0 <= t && t < 45.0 + d { return 5.0 - 2.0 * (t - 45.0) / d; }
    f(t)
}
fn maxavg(g: &dyn Fn(f64) -> f64, x: f64, hg: &[f64], extra: &[f64]) -> (f64, f64) { // sup over the grid, with witness
    let mut best = (f64::NEG_INFINITY, 0.0);
    for &h in hg.iter().chain(extra.iter()).filter(|&&h| h > 0.0) {
        let v = (g(x + h) - g(x - h)) / (2.0 * h);
        if v > best.0 || (v == best.0 && h > best.1) { best = (v, h); }
    }
    best
}

fn main() {
    let hs = [z(4), z(2), z(1), q(1, 4), q(1, 1000)];
    println!("windows h (minutes): 4 2 1 0.25 0.001");
    for t in [10i128, 20, 30, 45, 52] {
        let row: Vec<Q> = hs.iter().map(|&h| avg(t, h)).collect();
        assert!((0..5).all(|i| row[i] == closed(t, hs[i])));
        let tf = t as f64;
        assert!((0..5).all(|i| { let h = hs[i].f(); (row[i].f() - meter(&f, tf - h, tf + h, 2000) / (2.0 * h)).abs() < 1e-8 }));
        let lim = (f(tf - 1e-9) + f(tf + 1e-9)) / 2.0; // the two one-sided values
        assert!((row[4].f() - lim).abs() < 1e-3);
        let s: Vec<String> = row.iter().map(|v| format!("{:.6}", v.f())).collect();
        println!("average at t = {}: {} | recorded f(t) {}", t, s.join(" "), f(tf));
    }
    for h in [1.0f64, 0.001] { // Lebesgue-point test, roads 2 and 3
        let sp = 0.5 + h / 20.0 - h * h / 1200.0;
        for (t, c, want) in [(10.0, 2.5, h / 20.0), (20.0, 5.0, sp), (20.0, 4.5, sp), (30.0, 100.0, 95.0), (30.0, 5.0, 0.0), (45.0, 3.0, 1.0)] {
            let d = meter(&|s: f64| (f(s) - c).abs(), t - h, t + h, 2000) / (2.0 * h);
            assert!((d - want).abs() < 1e-9);
            println!("spread h = {}: t = {}, value {}: average of |f - value| = {:.6}", h, t, c, d);
        }
    }
    let k = q(1, 1000);
    let (rq, lq) = ((big_f(z(20) + k) - big_f(z(20))) / k, (big_f(z(20)) - big_f(z(20) - k)) / k);
    assert!(lq == z(4) - k / z(10) + k * k / z(600));
    assert!(rq == z(5));
    println!("window [19, 21] at t = 20: left minute {:.6}, right minute {:.6}", (big_f(z(20)) - big_f(z(19))).f(), (big_f(z(21)) - big_f(z(20))).f());
    println!("slopes of F at 20, h = 0.001: right {:.6}, left {:.6}; at 10: {:.6}", rq.f(), lq.f(), ((big_f(z(10) + k) - big_f(z(10))) / k).f());

    let mut hg = vec![0.001f64]; // window grid 0.001 up to about 64
    for _ in 0..559 { let last = hg[hg.len() - 1]; hg.push(last * 1.02); }
    let (alpha, dl) = (0.2f64, 1.0f64);
    let n1 = meter(&|s: f64| (f(s) - phi(s, dl)).abs(), 0.0, 60.0, 60000);
    assert!((n1 - 1.5 * dl).abs() < 1e-6);
    let mut wit: Vec<(f64, f64, f64)> = Vec::new();
    for i in 0..1201 {
        let x = i as f64 * 0.05;
        let extra: Vec<f64> = [20.0, 20.0 + dl, 45.0, 45.0 + dl].iter().filter(|&&p| x != p).map(|&p| (x - p).abs()).collect();
        let (m, h) = maxavg(&|y: f64| gg(y, dl), x, &hg, &extra);
        if m > alpha { wit.push((x - h, x + h, x)); }
    }
    let mut sorted = wit.clone();
    sorted.sort_by(|p, r| (p.0 - p.1).partial_cmp(&(r.0 - r.1)).unwrap()); // Vitali: longest first
    let mut chosen: Vec<(f64, f64)> = Vec::new();
    for &(a, b, _) in &sorted { if chosen.iter().all(|&(c, e)| b <= c || a >= e) { chosen.push((a, b)); } }
    let tot: f64 = chosen.iter().fold(0.0, |s, &(a, b)| s + (b - a));
    let in3 = |x: f64, j: (f64, f64)| (x - (j.0 + j.1) / 2.0).abs() <= 1.5 * (j.1 - j.0);
    assert!(wit.iter().all(|&(a, b, _)| chosen.iter().any(|&j| in3(a, j) && in3(b, j))));
    assert!(tot <= n1 / alpha);
    assert!(wit.len() as f64 * 0.05 <= 3.0 * tot);
    println!("ramps delta = {}: ||g||_1 closed form {:.6}, meter {:.6}", dl, 1.5 * dl, n1);
    println!("maximal, alpha = {}: grid points with M g > alpha: {}, about {:.2} minutes", alpha, wit.len(), wit.len() as f64 * 0.05);
    println!("Vitali: {} witness windows, {} chosen disjoint, total length {:.4}; 3 x total {:.4}; bound 3 ||g||_1 / alpha = {:.4}",
        wit.len(), chosen.len(), tot, 3.0 * tot, 3.0 * n1 / alpha);
    let mut cs = chosen.clone();
    cs.sort_by(|p, r| p.partial_cmp(r).unwrap());
    let cstr: Vec<String> = cs.iter().map(|&(a, b)| format!("({:.3}, {:.3})", a, b)).collect();
    println!("  chosen: {}", cstr.join(" "));
    for dd in [1.0f64, 4.0, 16.0, 1024.0] {
        println!("bad set bound, delta = 1/{}: 4 ||g||_1 / alpha = {:.6}", dd, 4.0 * 1.5 / dd / alpha);
    }
    println!("bad set itself: t = 20, 30, 45 (spreads 0.5, 95, 1); total length 0");

    let gb = |x: f64| x.max(0.0).min(1.0); // a block: 1 on [0, 1]
    for x in [2.0f64, 5.0, 10.0] {
        let (m, _) = maxavg(&gb, x, &hg, &[x.abs(), (x - 1.0).abs()]);
        assert!((m - 1.0 / (2.0 * x)).abs() < 1e-12);
        println!("block, M at x = {}: grid sup {:.6}; 1/(2x) {:.6}", x, m, 1.0 / (2.0 * x));
    }
    let cnt = (0..2101).map(|k| -10.0 + k as f64 * 0.01).filter(|&x| maxavg(&gb, x, &hg, &[x.abs(), (x - 1.0).abs()]).0 > 0.1).count();
    let lev = cnt as f64 * 0.01;
    assert!((lev - 9.0).abs() < 0.03);
    println!("block, set where M > 0.1: grid {:.2}; closed form 1/0.1 - 1 = 9; bound 3/0.1 = 30", lev);
    let num = meter(&|x: f64| maxavg(&gb, x, &hg, &[x.abs(), (x - 1.0).abs()]).0, 1.0, 10.0, 900);
    assert!((num - 10f64.ln() / 2.0).abs() < 1e-4);
    println!("block, integral of M from 1 to 10: meter {:.6}; ln(10)/2 {:.6}", num, 10f64.ln() / 2.0);
    println!("block, integral of M from 1 to R, ln(R)/2: R = 10^3 {:.6}, R = 10^6 {:.6}", 1e3f64.ln() / 2.0, 1e6f64.ln() / 2.0);
    let mut row: Vec<String> = Vec::new();
    for k in [1i32, 3, 6] { // drop local integrability: 1/|x| capped at 10^k
        let m = 10f64.powi(k);
        let cap = |s: f64| (1.0 / s.abs()).min(m);
        let ends: Vec<f64> = std::iter::once(0.0).chain((0..=k).rev().map(|j| 1.0 / 10f64.powi(j))).collect(); // the cap's edge, then decades
        let a1 = ends.windows(2).fold(0.0, |s, w| s + (meter(&cap, w[0], w[1], 2000) + meter(&cap, -w[1], -w[0], 2000))) / 2.0;
        assert!((a1 - (1.0 + m.ln())).abs() < 1e-4);
        row.push(format!("k = {} meter {:.6}, 1 + ln 10^k {:.6}", k, a1, 1.0 + m.ln()));
    }
    println!("1/|x| capped at 10^k, average at 0 over h = 1: {}", row.join("; "));
    let hc = [z(8), z(4), z(2), z(1), q(1, 2), q(1, 4)];
    for t in [20i128, 10] {
        let s: Vec<String> = hc.iter().map(|&h| format!("{:.2}", avg(t, h).f())).collect();
        println!("chart, average at {} for h = 8 4 2 1 0.5 0.25: {}", t, s.join(" "));
    }
    let pts: Vec<String> = [0.0f64, 4.0, 8.0, 12.0, 16.0].iter().map(|&t| format!("({},{:.1})", 40.0 + 5.0 * t, 200.0 - 30.0 * f(t))).collect();
    println!("figure, curve px {} (140,{:.1}); y at 5 kW {:.1}, at 3 kW {:.1}; window x 120..160 top {:.1}; midpoints y {:.1} and {:.1}",
        pts.join(" "), 200.0 - 30.0 * f(20.0 - 1e-9), 200.0 - 30.0 * f(31.0), 200.0 - 30.0 * f(50.0), 200.0 - 30.0 * avg(20, z(4)).f(),
        200.0 - 15.0 * (f(20.0 - 1e-9) + f(20.0)), 200.0 - 15.0 * (f(45.0 - 1e-9) + f(45.0)));
    println!("ALL CHECKS PASS");
}
