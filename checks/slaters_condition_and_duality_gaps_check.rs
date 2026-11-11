// Slater's condition and duality gaps -- the same check as the Python, in Rust.  std only, no crates.
// Minimise pump power (kW) so three mains deliver at least D litres a second (L/s).
use std::cmp::Ordering;

#[derive(Clone, Copy, Debug)]
struct Rat { n: i64, d: i64 }            // an exact fraction n/d with d > 0
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i64, d: i64) -> Rat { let g = gcd(n, d).max(1) * d.signum(); Rat { n: n / g, d: d / g } }
impl Rat {
    fn add(self, o: Rat) -> Rat { r(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn sub(self, o: Rat) -> Rat { r(self.n * o.d - o.n * self.d, self.d * o.d) }
    fn mul(self, o: Rat) -> Rat { r(self.n * o.n, self.d * o.d) }
    fn div(self, o: Rat) -> Rat { r(self.n * o.d, self.d * o.n) }
    fn cmp(self, o: Rat) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
}
fn rmin(a: Rat, b: Rat) -> Rat { if a.cmp(b) == Ordering::Greater { b } else { a } }

const MAINS: [(&str, i64, i64); 3] = [("A", 60, 45), ("B", 50, 55), ("C", 45, 60)];

fn valves() -> Vec<(String, i64, i64)> {  // every open/shut pattern: (name, flow, power)
    let mut out = vec![];
    for m in 0..8 {
        let on: Vec<usize> = (0..3).filter(|i| m >> (2 - i) & 1 == 1).collect();
        let name: String = on.iter().map(|&i| MAINS[i].0).collect();
        out.push((if name.is_empty() { "none".to_string() } else { name },
                  on.iter().map(|&i| MAINS[i].1).sum(), on.iter().map(|&i| MAINS[i].2).sum()));
    }
    out
}
fn q(lam: Rat, d: i64) -> Rat {          // dual function: price lam (kW per L/s) on the shortfall
    MAINS.iter().fold(lam.mul(r(d, 1)), |s, &(_, a, c)| s.add(rmin(r(0, 1), r(c, 1).sub(lam.mul(r(a, 1))))))
}
fn qf(lam: f64, d: i64) -> f64 { lam * d as f64 + MAINS.iter().map(|&(_, a, c)| (c as f64 - lam * a as f64).min(0.0)).sum::<f64>() }

fn solve_valves(d: i64) -> (Vec<(String, i64, i64)>, (String, i64, i64), Rat, Rat, Rat, Vec<Rat>, Rat) {
    let pats = valves();
    let best = pats.iter().filter(|p| p.1 >= d).min_by_key(|p| p.2).unwrap().clone();       // road 1
    let mut lam = r(0, 1);                                                                  // road 2
    for &(_, a, c) in MAINS.iter() { if q(r(c, a), d).cmp(q(lam, d)) == Ordering::Greater { lam = r(c, a); } }
    let mut order = [0usize, 1, 2];                                                         // road 3: LP
    order.sort_by(|&i, &j| r(MAINS[i].2, MAINS[i].1).cmp(r(MAINS[j].2, MAINS[j].1)));
    let (mut left, mut lp, mut x) = (r(d, 1), r(0, 1), vec![r(0, 1); 3]);
    for &i in order.iter() {
        x[i] = rmin(r(1, 1), left.div(r(MAINS[i].1, 1)));
        lp = lp.add(x[i].mul(r(MAINS[i].2, 1))); left = left.sub(x[i].mul(r(MAINS[i].1, 1)));
    }
    let pts: Vec<(i64, i64)> = pats.iter().map(|p| (d - p.1, p.2)).collect();               // road 4: hull
    let mut hull = r(1_000_000, 1);
    for &(u1, c1) in pts.iter() {
        if u1 <= 0 { hull = rmin(hull, r(c1, 1)); }
        for &(u2, c2) in pts.iter() {
            if u1 < 0 && 0 < u2 { hull = rmin(hull, r(c1, 1).add(r((c2 - c1) * u1, u1 - u2))); }
        }
    }
    (pats.clone(), best, lam, q(lam, d), lp, x, hull)
}

const D: i64 = 100;
fn flows(lam: f64) -> Vec<f64> {          // each pump's best flow at price lam: 3c f^2 / a^3 = lam
    MAINS.iter().map(|&(_, a, c)| { let (a, c) = (a as f64, c as f64); a.min(a * (lam * a / (3.0 * c)).sqrt()) }).collect()
}
fn power(f: &[f64]) -> f64 { MAINS.iter().zip(f).map(|(&(_, a, c), fi)| c as f64 * (fi / a as f64).powi(3)).sum() }
fn qc(lam: f64) -> f64 { let f = flows(lam); lam * D as f64 + power(&f) - lam * f.iter().sum::<f64>() }
fn ascent(step: f64, tol: f64) -> Vec<(usize, f64, f64, f64, f64, f64)> {
    let (mut lam, mut rows) = (0.5, vec![]);
    for k in 0..200 {
        let f = flows(lam); let s: f64 = f.iter().sum();
        let plan: Vec<f64> = f.iter().map(|fi| fi * D as f64 / s).collect();   // feasible: upper bound
        assert!(plan.iter().zip(MAINS.iter()).all(|(p, m)| *p <= m.1 as f64));
        let (lo, up) = (qc(lam), power(&plan));
        rows.push((k, lam, s, lo, up, up - lo));
        if up - lo <= tol { break; }
        lam = (lam + step * (D as f64 - s)).max(0.0);
    }
    rows
}
fn tern<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if g(m1) <= g(m2) { hi = m2; } else { lo = m1; }
    }
    (lo + hi) / 2.0
}
fn sq(lam: f64) -> f64 {                  // dual of: minimise 0.75 w kW subject to (w - 40)^2 <= 0
    let g = |w: f64| 0.75 * w + lam * (w - 40.0).powi(2);
    g(tern(g, 0.0, 80.0))
}

fn main() {
    let (pats, best, lam, d, lp, x, hull) = solve_valves(D);
    for (n, f, c) in pats.iter() {
        println!("valves {:<4} flow {:3} L/s  shortfall {:4}  power {:3} kW  {}", n, f, D - f, c, if *f >= D { "meets demand" } else { "-" });
    }
    println!("road 1, every pattern: best {}, {} L/s, p* = {} kW", best.0, best.1, best.2);
    println!("road 2, corners of q: price {:.4} kW per L/s, d* = {:.4} kW", lam.f(), d.f());
    let mut srt = MAINS;                 // q's corners, cheapest kW per L/s first; q's slope is D - flow open
    srt.sort_by(|m, n| r(m.2, m.1).cmp(r(n.2, n.1)));
    let cs: Vec<String> = srt.iter().map(|m| format!("{} {:.4}", m.0, r(m.2, m.1).f())).collect();
    let sl: Vec<String> = (0..4).map(|i| (D - srt[..i].iter().map(|m| m.1).sum::<i64>()).to_string()).collect();
    println!("  corners c/a: {}; slope of q before, between, after: {}", cs.join(" "), sl.join(" "));
    let net: Vec<String> = MAINS.iter().map(|&(n, a, c)| format!("{} {:.1}", n, r(c, 1).sub(lam.mul(r(a, 1))).f())).collect();
    println!("  by hand at that price: credit {:.1}, c - price a: {}", lam.mul(r(D, 1)).f(), net.join(" "));
    println!("road 3, part-open LP: {:.4} kW with A {:.2} B {:.2} C {:.2}", lp.f(), x[0].f(), x[1].f(), x[2].f());
    println!("road 4, lower hull at shortfall 0: {:.4} kW", hull.f());
    let gap = r(best.2, 1).sub(d);
    println!("duality gap {:.4} kW = {:.1}% of p*", gap.f(), 100.0 * gap.f() / best.2 as f64);
    let allopen = pats.iter().find(|p| p.0 == "ABC").unwrap().1;
    let conv = (0..8).all(|m: i64| (0..8).all(|n: i64| (0..3).all(|i| ((m >> i & 1) + (n >> i & 1)) % 2 == 0))); // midpoints
    println!("Slater, valves: all open shortfall {}; midpoint of every two patterns a pattern: {}", D - allopen, if conv { "yes" } else { "no" });
    let xs = r(9, 10);
    let sh = MAINS.iter().fold(r(D, 1), |s, m| s.sub(xs.mul(r(m.1, 1))));
    println!("Slater, part-open: x = 0.9 each, shortfall {:.1}, inside 0 < x < 1", sh.f());
    let ch: Vec<String> = (0..9).map(|i| format!("{:.2}", q(r(i, 4), D).f())).collect();
    println!("chart, q at price 0 to 2 by 0.25: {}", ch.join(" "));
    let fg: Vec<String> = pats.iter().map(|p| format!("{} {} {}", p.0, D - p.1, p.2)).collect();
    println!("figure, (shortfall, kW): {} hull at 0: {:.0}", fg.join(" "), hull.f());

    let fs = [50.0, 40.0, 35.0];
    let inside = fs.iter().zip(MAINS.iter()).all(|(f, m)| 0.0 < *f && *f < m.1 as f64);
    println!("Slater, variable-speed: flows 50 40 35 give shortfall {}, strictly inside 0 < w < a: {}", D as f64 - fs.iter().sum::<f64>(), if inside { "yes" } else { "no" });
    let rows = ascent(0.01, 0.01);
    for &(k, l, s, lo, up, g) in rows.iter() {
        let ratio = if k > 0 { format!("{:.3}", g / rows[k - 1].5) } else { "-".to_string() };
        println!("k={} price {:.6} flow {:7.4} lower {:.6} upper {:.6} gap {:.6} ratio {}", k, l, s, lo, up, g, ratio);
    }
    let per: Vec<f64> = MAINS.iter().map(|&(_, a, c)| a as f64 * (a as f64 / (3.0 * c as f64)).sqrt()).collect();
    let den: f64 = per.iter().sum();                                            // road 2: KKT closed form
    println!("KKT: flow per root-price, a sqrt(a / 3c): {:.4} {:.4} {:.4} sum {:.4}", per[0], per[1], per[2], den);
    let lam_star = (D as f64 / den).powi(2);
    let f_star = flows(lam_star);
    println!("KKT: price {:.6}, flows {:.4} {:.4} {:.4} power {:.6} kW", lam_star, f_star[0], f_star[1], f_star[2], power(&f_star));
    println!("predicted gap ratio (1 - 0.01 D / (2 price))^2 = {:.3}; steps below 4 price / D = {:.4} settle; factor at step 0.06: {:.2}",
             (1.0 - 0.01 * D as f64 / (2.0 * lam_star)).powi(2), 4.0 * lam_star / D as f64, 1.0 - 0.06 * D as f64 / (2.0 * lam_star));
    let dd = D as f64;
    let inner = |fa: f64| tern(|fb: f64| power(&[fa, fb, dd - fa - fb]), (dd - fa - 45.0).max(0.0), (dd - fa).min(50.0));
    let fa = tern(|fa: f64| power(&[fa, inner(fa), dd - fa - inner(fa)]), 10.0, 60.0);
    let brute = power(&[fa, inner(fa), dd - fa - inner(fa)]);
    println!("road 3, search over flows: {:.6} kW", brute);

    println!("no strict point, (w-40)^2 <= 0: p* = 30 kW; p* - q at price 1: {:.6}; at 14.0625: {:.6}; at 1e6: {:.9}",
             30.0 - sq(1.0), 30.0 - sq(14.0625), 30.0 - sq(1e6));
    let (mut lam_v, mut top) = (0.0_f64, -1000.0_f64);
    for k in 0..200 {
        top = top.max(qf(lam_v, D));
        if best.2 as f64 - top <= 0.01 { break; }
        let flow: i64 = MAINS.iter().filter(|m| (m.2 as f64) < lam_v * m.1 as f64).map(|m| m.1).sum();
        lam_v = (lam_v + 0.05 / (k + 1) as f64 * (D - flow) as f64).max(0.0);
    }
    println!("valve dual ascent, 200 steps: best bound {:.4}, gap {:.4}: test never met", top, best.2 as f64 - top);
    for dt in [110, 90] {
        let (_, b2, _, d2, _, _, _) = solve_valves(dt);
        println!("try: demand {}: p* {} kW, d* {:.4} kW, gap {:.1}%", dt, b2.2, d2.f(), 100.0 * (b2.2 as f64 - d2.f()) / b2.2 as f64);
    }
    println!("try: tolerance 1e-6: {} rows; step 0.03: {} rows; step 0.06: {} rows, cap 200",
             ascent(0.01, 1e-6).len(), ascent(0.03, 0.01).len(), ascent(0.06, 0.01).len());

    assert!(best.2 == 100 && d.cmp(r(89, 1)) == Ordering::Equal && lam.cmp(r(11, 10)) == Ordering::Equal);
    assert!(lp.cmp(d) == Ordering::Equal && hull.cmp(d) == Ordering::Equal);
    assert!((0..301).all(|i| q(r(i, 100), D).cmp(d) != Ordering::Greater));
    assert!((rows.last().unwrap().3 - power(&f_star)).abs() < 0.01 && (brute - power(&f_star)).abs() < 1e-6);
    assert!((rows.last().unwrap().1 - lam_star).abs() < 0.02 && rows.last().unwrap().5 <= 0.01);
    assert!(((30.0 - sq(1.0)) - 0.140625).abs() < 1e-6 && best.2 as f64 - top > 10.0);
    assert!(((30.0 - sq(1e6)) - 0.140625 / 1e6).abs() < 1e-12);    // d* = 30 = p*, approached but never reached
    println!("ALL CHECKS PASS");
}
