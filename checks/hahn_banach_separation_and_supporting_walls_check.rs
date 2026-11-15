// Separation: a wall between a budget set and a cheaper bundle.  std only, no crates.
// Same numbers and labels as the Python check.  A small exact-fraction type, Q, does the
// exact work; the worst-case price, the gauge, the polar and the bipolar are built by hand.
use std::{cmp::Ordering, ops::{Add, Div, Mul, Sub}};

#[derive(Clone, Copy, Debug, PartialEq, Eq)] struct Q(i128, i128);
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn qi(n: i128) -> Q { Q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl Q { fn f(self) -> f64 { self.0 as f64 / self.1 as f64 } fn abs(self) -> Q { Q(self.0.abs(), self.1) } }
fn f4(x: Q) -> String { format!("{:.4}", x.f()) }
fn bill(p: &[Q], x: &[Q]) -> Q { p.iter().zip(x).fold(qi(0), |s, (a, b)| s + *a * *b) }
fn worst_price(x: &[Q], qbar: &[Q], w: &[Q]) -> Vec<Q> { // road 1: high where you buy, low where you sell
    (0..x.len()).map(|t| if x[t] >= qi(0) { qbar[t] + w[t] } else { qbar[t] - w[t] }).collect()
}
fn gauge(x: &[Q], qbar: &[Q], w: &[Q], m: Q, cap: Q) -> Q { // the smallest t > 0 with x / t in the set
    let b = bill(&worst_price(x, qbar, w), x) / m;
    let c = x.iter().map(|v| v.abs()).max().unwrap() / cap;
    qi(0).max(b).max(c)
}
fn corners(walls: &[(Q, Q)]) -> Vec<(Q, Q)> {
    let mut pts: Vec<(Q, Q)> = Vec::new();
    for (i, &(a, b)) in walls.iter().enumerate() {
        for &(c, d) in &walls[i + 1..] {
            let det = a * d - b * c;
            if det == qi(0) { continue; }
            let p = ((d - b) / det, (a - c) / det);
            if walls.iter().all(|&(u, v)| u * p.0 + v * p.1 <= qi(1)) && !pts.contains(&p) { pts.push(p); }
        }
    }
    pts.sort_by(|a, b| a.1.f().atan2(a.0.f()).partial_cmp(&b.1.f().atan2(b.0.f())).unwrap());
    pts
}
fn hull(pts: &[(Q, Q)]) -> Vec<(Q, Q)> {
    let mut s: Vec<(Q, Q)> = pts.to_vec(); s.sort(); s.dedup();
    let mut out = Vec::new();
    for seq in [s.clone(), s.iter().rev().cloned().collect()] {
        let mut part: Vec<(Q, Q)> = Vec::new();
        for p in seq {
            while part.len() > 1 {
                let (a, b) = (part[part.len() - 2], part[part.len() - 1]);
                if (b.0 - a.0) * (p.1 - a.1) - (b.1 - a.1) * (p.0 - a.0) <= qi(0) { part.pop(); } else { break; }
            }
            part.push(p);
        }
        part.pop();
        out.extend(part);
    }
    out.sort_by(|a, b| a.1.f().atan2(a.0.f()).partial_cmp(&b.1.f().atan2(b.0.f())).unwrap());
    out
}
fn splitmix(state: &mut u64) -> f64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) as f64 / 18446744073709551616.0
}
fn px(a: Q, b: Q) -> String { format!("{:.2} {:.2}", 220.0 + 15.0 * a.f(), 220.0 - 15.0 * b.f()) }

fn main() {
    // ---- two hours, night then evening: pounds per MWh; MWh per hour, negative = sold back ----
    let (qbar, w, m, cap, x0) = ([qi(50), qi(150)], [qi(10), qi(30)], qi(500), qi(12), [qi(11), qi(-1)]);
    let qs = worst_price(&x0, &qbar, &w);
    let (fore, hi_b, worst) = (bill(&qbar, &x0), bill(&[qbar[0] + w[0], qbar[1] + w[1]], &x0), bill(&qs, &x0));
    let grid = (0..441).map(|k| bill(&[qbar[0] - w[0] + w[0] * qi(k / 21) / qi(10), // road 2: try 441 price lists
                                      qbar[1] - w[1] + w[1] * qi(k % 21) / qi(10)], &x0)).max().unwrap(); // in the band
    assert!(worst == qi(540) && grid == qi(540) && fore == qi(400) && hi_b == qi(480));
    let s0 = gauge(&x0, &qbar, &w, m, cap);
    let (mut lo, mut hi) = (0.5f64, 4.0f64); // road 3: bisection, membership tested by the price grid
    for _ in 0..60 {
        let t = (lo + hi) / 2.0;
        let xs = [11.0 / t, -1.0 / t];
        let mut mx = f64::NEG_INFINITY;
        for i in 0..21 { for j in 0..21 { mx = mx.max((40 + i) as f64 * xs[0] + (120 + 3 * j) as f64 * xs[1]); } }
        if mx <= 500.0 && xs[0].abs().max(xs[1].abs()) <= 12.0 { hi = t; } else { lo = t; }
    }
    assert!(s0 == q(27, 25) && (hi - 1.08).abs() < 1e-12);
    let sup = [x0[0] / s0, x0[1] / s0];
    assert!(bill(&qs, &sup) == m && sup[0].abs().max(sup[1].abs()) <= cap);
    let r = (m / (qbar[0] + w[0]).max(qbar[1] + w[1])).min(cap);
    let phi = [qs[0] / m, qs[1] / m];
    println!("forecast bill {}, all-high bill {}, worst bill {} (grid of 441: {})", f4(fore), f4(hi_b), f4(worst), f4(grid));
    println!("worst price list ({}, {}); over budget by {}", f4(qs[0]), f4(qs[1]), f4(worst - m));
    println!("gauge s(x0) = {} (bisection {:.4}); supporting point ({}, {})", f4(s0), hi, f4(sup[0]), f4(sup[1]));
    println!("phi = ({}, {}) per MWh; phi(x0) = {}; ball radius {}; norm {} <= 1/r = {}", f4(phi[0]), f4(phi[1]),
             f4(bill(&phi, &x0)), f4(r), f4(phi[0].abs().max(phi[1].abs())), f4(qi(1) / r));
    let (mut state, mut bad) = (2026u64, 0);
    for _ in 0..2000 { // Hahn-Banach's promise: phi never exceeds the gauge
        let (a, b) = (q((40000.0 * splitmix(&mut state)) as i128 - 20000, 1000), q((40000.0 * splitmix(&mut state)) as i128 - 20000, 1000));
        if bill(&phi, &[a, b]) > gauge(&[a, b], &qbar, &w, m, cap) { bad += 1; }
    }
    assert!(bad == 0 && (bill(&phi, &x0).f() - hi).abs() < 1e-12); // and the wall meets the bisection gauge at x0
    println!("phi <= s at 2000 random schedules (SplitMix64 seed 2026): {} failures", bad);

    // ---- convexity: two plans, their halfway mix, and 121 walls that try to split them ----
    let (pa, pb) = ((qi(10), qi(0)), (qi(0), qi(4)));
    let mix = ((pa.0 + pb.0) / qi(2), (pa.1 + pb.1) / qi(2));
    let score = |k: i128, p: (Q, Q)| qi(k / 11 - 5) * p.0 + qi(k % 11 - 5) * p.1; // wall k of 121
    let split = (0..121).filter(|&k| { let (a, b, m) = (score(k, pa), score(k, pb), score(k, mix)); m > a.max(b) || m < a.min(b) }).count();
    println!("convexity: plans ({}, {}) and ({}, {}), halfway mix ({}, {}); of 121 walls, {} put the mix beyond both plans",
             f4(pa.0), f4(pa.1), f4(pb.0), f4(pb.1), f4(mix.0), f4(mix.1), split);
    assert!(mix == (qi(5), qi(2)) && split == 0);

    // ---- the bipolar: walls a.x <= 1 -> corners -> polar -> walls again ----
    let mut walls = Vec::new();
    for a in [qi(40), qi(60)] { for b in [qi(120), qi(180)] { walls.push((a / m, b / m)); } }
    let k = qi(1) / cap; walls.extend([(k, qi(0)), (qi(0) - k, qi(0)), (qi(0), k), (qi(0), qi(0) - k)]);
    let (c, polar) = (corners(&walls), hull(&walls)); // the polar as the hull of the 8 walls
    let polar2 = corners(&c); // road two: every functional that scores the corners of C at most 1
    assert!(c.len() == 6 && polar.len() == 6 && polar2 == polar && corners(&polar2) == c);
    let cs: Vec<String> = c.iter().map(|p| format!("({}, {})", f4(p.0), f4(p.1))).collect();
    println!("budget set corners: {}", cs.join(", "));
    println!("8 walls, {} of them corners of the polar; the polar built from the {} corners has {}, the same; their walls give back the same {} corners",
             polar.len(), c.len(), polar2.len(), c.len());

    // ---- a week: 168 hourly prices (illustrative), band 20 per cent, budget 10000 pounds ----
    let day = |h: usize| -> i128 { if h < 6 { 50 } else if h < 16 { 90 } else if h < 20 { 150 } else { 70 } };
    let qw: Vec<Q> = (0..168).map(|h| qi(day(h % 24) - if h >= 120 { 10 } else { 0 })).collect();
    let ww: Vec<Q> = qw.iter().map(|p| *p / qi(5)).collect();
    let xw: Vec<Q> = (0..168).map(|h| if h % 24 < 5 { qi(3) } else if (16..20).contains(&(h % 24)) { q(-5, 4) } else { qi(1) }).collect();
    let low = xw.iter().filter(|t| **t < qi(0)).count();
    for (n, mb) in [(24usize, None), (168usize, Some(qi(10000)))] {
        let (p, ws, x) = (&qw[..n], &ww[..n], &xw[..n]);
        let hp: Vec<Q> = p.iter().zip(ws).map(|(a, b)| *a + *b).collect();
        let vals = (bill(p, x), bill(&hp, x), bill(&worst_price(x, p, ws), x));
        let mut line = format!("N = {}: forecast {}, all-high {}, worst {}", n, f4(vals.0), f4(vals.1), f4(vals.2));
        if let Some(mb) = mb {
            let sw = gauge(x, p, ws, mb, cap);
            line += &format!("; budget {}, gauge {}, scale to {} per cent", f4(mb), f4(sw), f4(qi(100) / sw));
            assert!(vals == (qi(8110), qi(9732), qi(11792)) && low == 28);
        }
        println!("{}", line);
    }
    println!("hours priced at the low end in the week: {}", low);

    // ---- infinite hours: what the finite rehearsal hides ----
    let mut direct = 0.0f64;
    for t in (1..=1000000u64).rev() { direct += 1.0 / ((t * t) as f64); }
    direct += 1.0 / (1000000.0 + 0.5);
    for n in [24u64, 168, 1000, 10000] {
        let mut part = 0.0f64;
        for t in 1..=n { part += 1.0 / ((t * t) as f64); }
        let (tail, nf) = (std::f64::consts::PI.powi(2) / 6.0 - part, n as f64);
        assert!((tail - (direct - part)).abs() < 1e-9 && (nf * tail - 1.0).abs() < 1.0 / nf);
        println!("dense set, N = {}: best margin {:.6} MWh, N x margin {:.4}", n, tail, nf * tail);
    }
    for n in [24u64, 168, 1000] {
        let best = (1..=n).map(|t| 100.0 * (1.0 - 1.0 / t as f64)).fold(f64::MIN, f64::max);
        assert!((best - 100.0 * (1.0 - 1.0 / n as f64)).abs() < 1e-12);
        println!("sup price 100 never reached, N = {}: best 1 MWh placement {:.4}", n, best);
    }
    let gaps: Vec<String> = [1.0f64, 10.0, 100.0, 1000.0].iter().map(|x| format!("{:.4}", 1.0 / x)).collect();
    println!("curve v >= 1/u against v <= 0, gap at u = 1, 10, 100, 1000: {}", gaps.join(", "));

    // ---- try changing ----
    for (label, wt, mt, x) in [("band 30 per cent", [qi(15), qi(45)], m, x0), ("sell 3 MWh", w, m, [qi(11), qi(-3)]),
                               ("budget 550", w, qi(550), x0), ("buy 13 MWh", w, m, [qi(13), qi(-1)])] {
        println!("try {}: worst bill {}, gauge {}", label, f4(bill(&worst_price(&x, &qbar, &wt), &x)), f4(gauge(&x, &qbar, &wt, mt, cap)));
    }
    let cp: Vec<String> = c.iter().map(|p| px(p.0, p.1)).collect();
    println!("figure, {}, x0 {}, support {}, wall {} {}, all-high {} {}", cp.join(", "), px(x0[0], x0[1]), px(sup[0], sup[1]),
             px(qi(4), q(260, 120)), px(qi(13), q(-280, 120)), px(qi(4), q(260, 180)), px(qi(13), q(-280, 180)));
    println!("ALL CHECKS PASS");
}
