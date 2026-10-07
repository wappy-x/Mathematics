// Pontryagin's principle -- the same check as the Python, in Rust.  No crates.
// A car parks 100 m away, rest to rest, with |u| <= 2 m/s^2.  Road one: the
// maximum principle, H = p1 v + p2 u - 1, switching where p2 = 0.  Road two: a
// grid search offering five throttle settings.  Road three: the costate as a price.
use std::collections::HashMap;
const D: f64 = 100.0; const A: f64 = 2.0;
const DTS: [f64; 3] = [0.1, 0.04, 0.01];

struct Plan { ts: f64, t: f64, p1: f64, p2_0: f64 }
impl Plan {
    fn sigma(&self, t: f64) -> f64 { self.p2_0 - self.p1 * t } // the switching function, p2
    fn speed(&self, t: f64) -> f64 { if t <= self.ts { A * t } else { (A * (self.t - t)).max(0.0) } }
    fn ham(&self, t: f64, u: f64) -> f64 { self.p1 * self.speed(t) + self.sigma(t) * u - 1.0 }
}
fn best_time(d: f64, v0: f64, a: f64) -> (f64, f64) { // to rest at distance d, from v0
    let vp = (a * d + v0 * v0 / 2.0).sqrt();              // peak speed
    ((2.0 * vp - v0) / a, (vp - v0) / a)                  // arrival time, switch time
}
fn grid(dt: f64) -> f64 {                                 // farthest point at each speed k dt
    let (mut best, mut n) = (HashMap::from([(0i64, 0.0f64)]), 0);
    while *best.get(&0).unwrap_or(&-1.0) < D - 1e-9 {
        let mut new: HashMap<i64, f64> = HashMap::new();
        for (&k, &x) in best.iter() {
            for u in -2i64..=2 {
                let y = x + k as f64 * dt * dt + u as f64 * dt * dt / 2.0;
                let slot = new.entry(k + u).or_insert(-1e18);
                if y > *slot { *slot = y }
            }
        }
        best = new;
        n += 1;
    }
    n as f64 * dt
}
fn euler(p: &Plan, n: usize) -> (f64, f64) {              // n steps, u = 2 sign(sigma)
    let (mut x, mut v, mut xs, h) = (0.0, 0.0, 0.0, p.t / n as f64);
    for i in 0..n {
        if i == n / 2 { xs = x }                          // position at the switch
        let u = if p.sigma((i as f64 + 0.5) * h) > 0.0 { A } else { -A };
        (x, v) = (x + h * v, v + h * u);
    }
    (D / 2.0 - xs, x)
}
fn join(v: &[f64], dp: usize) -> String { v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let ts = (D / A).sqrt();
    let p2_0 = 1.0 / A;                                   // H = 0 at t = 0, where v = 0
    let p = Plan { ts, t: 2.0 * ts, p1: p2_0 / ts, p2_0 };
    let e = 1e-4;
    let fd1 = (best_time(D + e, 0.0, A).0 - best_time(D - e, 0.0, A).0) / (2.0 * e);
    let fd2 = -(best_time(D, e, A).0 - best_time(D, -e, A).0) / (2.0 * e);
    let gs: Vec<f64> = DTS.iter().map(|&dt| grid(dt)).collect();
    let eul: Vec<(f64, f64)> = [1000, 2000, 4000].iter().map(|&n| euler(&p, n)).collect();
    println!("switch ts = sqrt(D/a) = {:.4} s; arrival T = {:.4} s; peak speed {:.4} m/s", ts, p.t, A * ts);
    println!("costate p1 = {:.6} s/m; p2(0) = {:.4} s^2/m; p2(T) = {:.4}", p.p1, p2_0, p.sigma(p.t));
    for t in [0.0, 3.0, ts, 10.0] {
        let hs: Vec<String> = [-2.0, -1.0, 0.0, 1.0, 2.0].iter().map(|&u| format!("{:+.3}", (p.ham(t, u) * 1000.0).round() / 1000.0 + 0.0)).collect();
        println!("t = {:7.4}: sigma {:+.4}; H at u = -2..2: {}", t, p.sigma(t), hs.join(" "));
    }
    println!("speed chart, t = 0, 2, ..., 20 s");
    println!("  full throttle then brake: {}", join(&(0..11).map(|i| p.speed(2.0 * i as f64)).collect::<Vec<_>>(), 2));
    println!("  half throttle then brake: {}", join(&(0..11).map(|i| (2.0 * i as f64).min(20.0 - 2.0 * i as f64)).collect::<Vec<_>>(), 2));
    println!("grid search, dt = 0.1, 0.04, 0.01 s: {}", gs.iter().map(|g| format!("{:.3} s", g)).collect::<Vec<_>>().join(", "));
    println!("price of a metre: dT/dD = {:.6}; of a m/s head start: -dT/dv0 = {:.4}", fd1, fd2);
    println!("Euler, 1000, 2000, 4000 steps: short of 50 m at the switch by {}; ends at {}",
        join(&eul.iter().map(|r| r.0).collect::<Vec<_>>(), 5), join(&eul.iter().map(|r| r.1).collect::<Vec<_>>(), 5));
    let v10 = best_time(D, 10.0, A);
    println!("rolling start 10 m/s: T = {:.4} s, switch at {:.4} s", v10.0, v10.1);
    println!("mistake, half throttle: {:.2} s; top speed capped at 10: {:.2} s", best_time(D, 0.0, 1.0).0, 10.0 / A * 2.0 + (D - 10.0 * 10.0 / A) / 10.0);
    println!("mistake, switch late at 8 s: stops at {:.2} m; bound 200 m/s^2: {:.2} s", A * 64.0 / 2.0 + (A * 8.0) * (A * 8.0) / (2.0 * A), best_time(D, 0.0, 200.0).0);
    let y = |v: f64| 200.0 - 8.0 * v;                     // figure: 2.8 px per m, 8 px per m/s
    println!("figure, switch ({:.2}, {:.2}); arc controls y {:.2}; switching curve top {:.2}, control y {:.2}",
        40.0 + 2.8 * D / 2.0, y(A * ts), y(A * ts / 2.0), y((2.0 * A * D).sqrt()), y((2.0 * A * D).sqrt() / 2.0));
    assert!(gs.iter().zip(DTS.iter()).all(|(&g, &dt)| p.t <= g && g < p.t + dt)); // no grid plan beats T
    assert!((fd1 - p.p1).abs() < 1e-6 && (fd2 - p2_0).abs() < 1e-6);  // costate = price of state
    assert!([1.0, 9.0, 13.0].iter().all(|&t| p.ham(t, if p.sigma(t) > 0.0 { A } else { -A }).abs() < 1e-12));
    assert!(eul.windows(2).all(|w| w[0].0 / w[1].0 > 1.9 && w[0].0 / w[1].0 < 2.1)); // Euler, order one
    println!("ALL CHECKS PASS");
}
