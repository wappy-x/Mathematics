// Saddle points and minimax -- the same check as the Python, in Rust.  No crates.
// Two pumps must deliver at least 100 L/s.  The PLANNER picks flows x = (x1, x2) in L/s to MINIMISE the
// power f0(x) = 0.02 x1^2 + 0.03 x2^2 kW.  The PRICE SETTER picks a price lam >= 0 (kW per L/s) to MAXIMISE
// the Lagrangian L(x, lam) = f0(x) + lam (100 - x1 - x2): the power, plus lam for every L/s short.
// Road 1: the saddle, where the two best replies meet.  Road 2: min-max and max-min by brute force on grids.
// Road 3: the price setter climbs q(lam) by Danskin's slope, the shortfall, until demand is met.
const A: [f64; 2] = [0.02, 0.03]; // kW per (L/s)^2
const D: f64 = 100.0; // L/s demanded
const KWH: f64 = 0.20; // pounds per kWh

fn f0(x: [f64; 2]) -> f64 { A[0] * x[0] * x[0] + A[1] * x[1] * x[1] }
fn lag(x: [f64; 2], lam: f64) -> f64 { f0(x) + lam * (D - x[0] - x[1]) }
fn reply(lam: f64) -> [f64; 2] { [lam / (2.0 * A[0]), lam / (2.0 * A[1])] } // marginal cost = the price
fn q(lam: f64) -> f64 { lag(reply(lam), lam) } // the planner's best bill at price lam
fn short(lam: f64) -> f64 { let x = reply(lam); D - x[0] - x[1] } // L/s short at the planner's reply
fn f4(v: &[f64]) -> String { v.iter().map(|u| format!("{:.4}", u + 0.0)).collect::<Vec<_>>().join(", ") }
fn maxf(it: impl Iterator<Item = f64>) -> f64 { it.fold(f64::NEG_INFINITY, f64::max) }
fn minf(it: impl Iterator<Item = f64>) -> f64 { it.fold(f64::INFINITY, f64::min) }
fn adjust(alpha: f64) -> (f64, usize, Vec<f64>) { // from lam = 0: the final price, the step count and the prices visited
    let (mut lam, mut k, mut trace) = (0.0f64, 0, Vec::new());
    while short(lam).abs() >= 1e-9 && k < 1000 {
        trace.push(lam);
        lam = (lam + alpha * short(lam)).max(0.0);
        k += 1;
    }
    (lam, k, trace)
}
fn spiral(eta: f64) -> Vec<f64> { // F = x y: simultaneous descent in x, ascent in y, step eta, from (1, 1)
    let (mut x, mut y, mut dist) = (1.0f64, 1.0f64, Vec::new());
    for k in 0..101 {
        if k % 25 == 0 { dist.push((x * x + y * y).sqrt()) }
        let (nx, ny) = (x - eta * y, y + eta * x);
        x = nx;
        y = ny;
    }
    dist
}
fn saddle(a: [f64; 2], d: f64) -> (f64, [f64; 2], f64, f64) { // road 1 for other pumps or demand: price, plan, power, dual
    let pr = 1.0 / (2.0 * a[0]) + 1.0 / (2.0 * a[1]);
    let lt = d / pr;
    let xt = [lt / (2.0 * a[0]), lt / (2.0 * a[1])];
    (lt, xt, a[0] * xt[0].powi(2) + a[1] * xt[1].powi(2), d * lt - pr / 2.0 * lt.powi(2))
}

fn main() {
    // ---- road 1: the planner's reply, then the price that leaves no shortfall ----
    let per = 1.0 / (2.0 * A[0]) + 1.0 / (2.0 * A[1]); // L/s delivered per kW per L/s of price
    let lam_s = D / per;
    let xs = reply(lam_s);
    println!("problem: minimise {} x1^2 + {} x2^2 kW subject to x1 + x2 >= {} L/s; tariff {:.2} pounds per kWh", A[0], A[1], D, KWH);
    println!("planner's reply: x1 = {:.4} lam, x2 = {:.4} lam, total {:.4} lam L/s", 1.0 / (2.0 * A[0]), 1.0 / (2.0 * A[1]), per);
    println!("q(lam) = {:.4} lam - {:.4} lam^2; slope {:.4} - {:.4} lam = shortfall", D, per / 2.0, D, per);
    println!("saddle: lam* = {:.4} / {:.4} = {:.4} kW per L/s, x* = ({}) L/s", D, per, lam_s, f4(&xs));
    println!("power {:.4} + {:.4} = {:.4} kW, {:.4} pounds per hour", A[0] * xs[0] * xs[0], A[1] * xs[1] * xs[1], f0(xs), KWH * f0(xs));
    println!("q(lam*) = {:.4} - {:.4} = {:.4} kW; gap {:.4} kW", D * lam_s, per / 2.0 * lam_s * lam_s, q(lam_s), f0(xs) - q(lam_s) + 0.0);

    // ---- road 2: brute force, both orders, on grids ----
    let xg: Vec<[f64; 2]> = (0..201).flat_map(|i| (0..201).map(move |j| [i as f64 / 2.0, j as f64 / 2.0])).collect();
    let lg: Vec<f64> = (0..51).map(|k| k as f64 / 10.0).collect();
    let (mut mm_val, mut mm_x) = (f64::INFINITY, [0.0, 0.0]);
    for &x in &xg { let v = maxf(lg.iter().map(|&l| lag(x, l))); if v < mm_val { mm_val = v; mm_x = x } }
    let (mut xm_val, mut lam_g) = (f64::NEG_INFINITY, 0.0);
    for &l in &lg { let v = minf(xg.iter().map(|&x| lag(x, l))); if v > xm_val { xm_val = v; lam_g = l } }
    println!("road 2, planner first (min over x of max over lam): {:.4} kW at x = ({})", mm_val, f4(&mm_x));
    println!("road 2, price setter first (max over lam of min over x): {:.4} kW at lam = {:.4}", xm_val, lam_g);
    let up = maxf(lg.iter().map(|&l| lag(xs, l))) - lag(xs, lam_s);
    let down = minf(xg.iter().map(|&x| lag(x, lam_s))) - lag(xs, lam_s);
    println!("saddle test on the grids: best price gain {:.4} kW, best plan gain {:.4} kW", up + 0.0, down + 0.0);
    assert!((mm_val - 120.0).abs() < 1e-9 && (xm_val - 120.0).abs() < 1e-9 && (lam_g - lam_s).abs() < 1e-12);
    assert!(mm_x == [60.0, 40.0] && up < 1e-9 && down > -1e-9 && (f0(xs) - q(lam_s)).abs() < 1e-9);

    // ---- road 3: price adjustment by Danskin's slope ----
    let h = 1e-4;
    let cd = (q(1.0 + h) - q(1.0 - h)) / (2.0 * h);
    println!("Danskin at lam = 1: shortfall {:.4} L/s, central difference of q {:.4}", short(1.0), cd);
    assert!((cd - short(1.0)).abs() < 1e-6);
    let alpha = 0.01;
    let (lam, k, trace) = adjust(alpha);
    println!("price adjustment, step {} from lam = 0, lam_k for k = 0..5: {}", alpha, f4(&trace[..6]));
    let sh: Vec<f64> = trace[..6].iter().map(|&l| short(l)).collect();
    println!("shortfall at those prices, L/s: {}", f4(&sh));
    let ratio = (trace[5] - lam_s) / (trace[4] - lam_s);
    println!("error ratio {:.4}, steps below 2 / {:.4} = {:.4} converge; shortfall below 1e-9 L/s after {} steps, lam = {:.4}", ratio, per, 2.0 / per, k, lam);
    assert!((lam - lam_s).abs() < 1e-9 && (ratio - (1.0 - alpha * per)).abs() < 1e-9);
    let chart: Vec<String> = (0..13).map(|i| format!("{:.4}", (q(0.4 * i as f64) * 1e9).round() / 1e9 + 0.0)).collect();
    println!("chart, q(lam) kW at lam = 0, 0.4, ..., 4.8: {}", chart.join(" "));
    println!("figure, power of T L/s split the cheap way {:.4} T^2 kW; T 70..130 L/s, lam 1.6..3.2; saddle ({:.4}, {:.4}); best reply (70, {:.4}) to (130, {:.4}); L = 120 on T = 100 and from (70, {:.4}) to (130, {:.4})",
             1.0 / (2.0 * per), xs[0] + xs[1], lam_s, 70.0 / per, 130.0 / per, lam_s - 30.0 / (2.0 * per), lam_s + 30.0 / (2.0 * per));

    // ---- what breaks ----
    let m: [[f64; 2]; 2] = [[58.0, 95.0], [93.0, 70.0]]; // penalty kick: kicker's scoring percent; rows shoot L, R; columns dive L, R
    let ps: Vec<f64> = (0..601).map(|i| i as f64 / 600.0).collect();
    let pure = (m[0][0].min(m[0][1]).max(m[1][0].min(m[1][1])), m[0][0].max(m[1][0]).min(m[0][1].max(m[1][1])));
    let mixed = (maxf(ps.iter().map(|&p| (0..2).map(|c| p * m[0][c] + (1.0 - p) * m[1][c]).fold(f64::INFINITY, f64::min))),
                 minf(ps.iter().map(|&p| (0..2).map(|r| p * m[r][0] + (1.0 - p) * m[r][1]).fold(f64::NEG_INFINITY, f64::max))));
    let (a, b, c, d) = (m[0][0], m[0][1], m[1][0], m[1][1]);
    let v = (b * c - a * d) / (b + c - a - d);
    println!("penalty [[{}, {}], [{}, {}]], plain choices only: kicker can guarantee {:.4}%, keeper can hold the kicker to {:.4}%", m[0][0], m[0][1], m[1][0], m[1][1], pure.0, pure.1);
    println!("penalty, mixing allowed: {:.4}% and {:.4}%; formula {:.4}%", mixed.0, mixed.1, v);
    assert!(pure == (70.0, 93.0) && (mixed.0 - v).abs() < 1e-9 && (mixed.1 - v).abs() < 1e-9);
    let g: Vec<f64> = (0..101).map(|i| i as f64 / 100.0).collect();
    let ff = |x: f64, y: f64| (x - y) * (x - y); // convex in y too: the y player is not concave
    let mmf = minf(g.iter().map(|&x| maxf(g.iter().map(|&y| ff(x, y)))));
    let xmf = maxf(g.iter().map(|&y| minf(g.iter().map(|&x| ff(x, y)))));
    println!("F = (x - y)^2 on [0, 1]: min over x of max over y {:.4}; max over y of min over x {:.4}", mmf, xmf);
    assert!(mmf == 0.25 && xmf == 0.0);
    let xc = reply(2.0);
    let worst = maxf((0..201).map(|l| lag(xc, l as f64 / 100.0)));
    println!("price capped at 2: planner's reply ({}) L/s, {:.4} delivered, {:.4} short; its worst bill {:.4} = q(2) {:.4} kW",
             f4(&xc), xc[0] + xc[1], short(2.0), worst, q(2.0));
    assert!((worst - q(2.0)).abs() < 1e-9 && short(2.0) > 16.0);
    let ls = [1.0, 10.0, 100.0, 1000.0]; // minimise x on [-1, 1] subject to x^2 <= 0
    let qq: Vec<f64> = ls.iter().map(|&l| minf((0..200001).map(|i| { let x = i as f64 / 100000.0 - 1.0; x + l * x * x }))).collect();
    let qs: Vec<String> = qq.iter().map(|v| format!("{:.6}", v)).collect();
    println!("min x subject to x^2 <= 0: p* = 0; q(lam) at lam = 1, 10, 100, 1000: {}", qs.join(", "));
    assert!(qq.iter().zip(ls.iter()).all(|(v, l)| (v + 1.0 / (4.0 * l)).abs() < 1e-8));
    let eta = 0.1;
    let dist = spiral(eta);
    println!("F = x y, simultaneous steps of {} from (1, 1): distance from the saddle at k = 0, 25, 50, 75, 100: {}", eta, f4(&dist));
    assert!((dist[4] / dist[0] - (1.0 + eta * eta).powi(50)).abs() < 1e-9);

    // ---- try changing ----
    for (at, dt) in [([0.02, 0.02], D), (A, 120.0)] {
        let (lt, xt, pt, qt) = saddle(at, dt);
        println!("try, A = {:?}, D = {}: lam* = {:.4}, x* = ({}) L/s, power {:.4} kW, {:.4} pounds per hour, dual value {:.4} kW",
                 at, dt, lt, f4(&xt), pt, KWH * pt, qt);
    }
    let (_, ka, ta) = adjust(0.04);
    println!("try, alpha = 0.04: lam_k for k = 0..3: {}; error ratio {:.4}; shortfall below 1e-9 L/s after {} steps",
             f4(&ta[..4]), (ta[5] - lam_s) / (ta[4] - lam_s), ka);
    let (la, ka, ta) = adjust(0.05);
    println!("try, alpha = 0.05: lam_k for k = 0..3: {}; still short after {} steps, lam = {:.4}", f4(&ta[..4]), ka, la);
    println!("try, eta = 0.01: distance from the saddle at k = 0, 25, 50, 75, 100: {}", f4(&spiral(0.01)));
    println!("ALL CHECKS PASS");
}
