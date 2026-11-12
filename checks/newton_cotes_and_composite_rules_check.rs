// Newton-Cotes and composite rules -- the same check as the Python, in Rust.  No crates.
// A day's wind energy (illustrative): wind v(t) = 3 + t(24 - t)/24 m/s at t hours,
// turbine power P = c v^3 kW with c = 0.02, readings every 10 minutes, energy in kWh.
// Road 1: the exact energy from moments of s(1 - s).  Road 2: the 7-point Newton-Cotes
// rule in exact fractions, exact by its degree.  Road 3: five composite rules at four
// spacings, with observed orders.  Every weight is the integral of a Lagrange basis.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                           // a fraction in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn mul(a: Q, b: Q) -> Q { let (g, h) = (gcd(a.n, b.d).max(1), gcd(b.n, a.d).max(1)); q((a.n / g).checked_mul(b.n / h).unwrap(), (a.d / h).checked_mul(b.d / g).unwrap()) }
fn div(a: Q, b: Q) -> Q { mul(a, q(b.d, b.n)) }
fn qi(n: i128) -> Q { Q { n, d: 1 } }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn fr(a: Q) -> String { if a.d > 1 { format!("{}/{}", a.n, a.d) } else { format!("{}", a.n) } }
fn sci(x: f64, d: usize) -> String {                    // 1.2e-5 written 1.2e-05, as Python does
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn v(t: f64) -> f64 { 3.0 + t * (24.0 - t) / 24.0 }
fn p(t: f64) -> f64 { v(t) * v(t) * v(t) / 50.0 }      // kW
fn pq(t: Q) -> Q { let v = add(qi(3), div(mul(t, add(qi(24), q(-t.n, t.d))), qi(24))); div(mul(mul(v, v), v), qi(50)) }
type Rule = (Vec<Q>, Vec<Q>);
fn weights(nodes: &[i128], length: i128) -> Vec<Q> {   // integral of each Lagrange basis over [0, length], per unit width
    nodes.iter().map(|&j| {
        let (mut poly, mut den) = (vec![qi(1)], qi(1));  // coefficients, constant term first
        for &k in nodes.iter().filter(|&&k| k != j) {
            poly.insert(0, qi(0));                       // multiply by (t - k)
            for r in 0..poly.len() - 1 { poly[r] = add(poly[r], mul(qi(-k), poly[r + 1])); }
            den = mul(den, qi(j - k));
        }
        let mut s = qi(0);
        for (r, &c) in poly.iter().enumerate() { s = add(s, mul(c, q(length.pow(r as u32 + 1), r as i128 + 1))); }
        div(div(s, den), qi(length))
    }).collect()
}
fn closed(m: i128) -> Rule { let n: Vec<i128> = (0..=m).collect(); (n.iter().map(|&j| q(j, m)).collect(), weights(&n, m)) }
fn opened(k: i128) -> Rule { let n: Vec<i128> = (1..=k).collect(); (n.iter().map(|&j| q(j, k + 1)).collect(), weights(&n, k + 1)) }
fn apply(rule: &Rule, f: &dyn Fn(f64) -> f64, a: f64, b: f64, panels: usize) -> f64 {
    let hh = (b - a) / panels as f64;
    let mut s = 0.0;
    for pn in 0..panels { for (x, w) in rule.0.iter().zip(&rule.1) { s += fl(*w) * hh * f(a + (pn as f64 + fl(*x)) * hh); } }
    s
}
fn qpow(x: Q, k: usize) -> Q { (0..k).fold(qi(1), |acc, _| mul(acc, x)) }
fn fact(n: i128) -> i128 { (1..=n).product() }
fn join(xs: &[String]) -> String { xs.join(", ") }
fn main() {
    let mut e = qi(0);                                    // road 1: t = 24s, v = 3 + 24u, u = s(1 - s)
    for j in 0..4i128 {
        let c = [1, 3, 3, 1][j as usize] * 3i128.pow(3 - j as u32) * 24i128.pow(j as u32);
        e = add(e, q(c * fact(j) * fact(j), fact(2 * j + 1)));
    }
    let e = mul(q(24, 50), e);
    let ef = fl(e);
    println!("exact energy, road 1: {} kWh = {:.9} kWh; P at 0 h {:.4} kW, at 12 h {:.4} kW", fr(e), ef, p(0.0), p(12.0));
    println!("chart, P in kW at t = 0, 2, ..., 24 h: {}", join(&(0..13).map(|i| format!("{:.2}", p(2.0 * i as f64))).collect::<Vec<_>>()));
    let names = ["midpoint", "trapezoid", "Simpson", "three-eighths", "Boole", "open 2-point", "Milne", "7-point"];
    let rules: Vec<Rule> = vec![opened(1), closed(1), closed(2), closed(3), closed(4), opened(2), opened(3), closed(6)];
    let mut degree = vec![];
    for (name, (xs, ws)) in names.iter().zip(&rules) {
        let mut k = 0;
        while xs.iter().zip(ws).fold(qi(0), |s, (x, w)| add(s, mul(*w, qpow(*x, k)))) == q(1, k as i128 + 1) { k += 1; }
        degree.push(k - 1);
        println!("{:>13}: nodes {}; weights {}; degree {}", name, join(&xs.iter().map(|x| fr(*x)).collect::<Vec<_>>()),
                 join(&ws.iter().map(|w| fr(*w)).collect::<Vec<_>>()), k - 1);
    }
    assert!(degree == vec![1, 1, 3, 3, 5, 1, 3, 7]);      // odd degree from symmetry, every time
    assert!(rules[2].1 == vec![q(1, 6), q(2, 3), q(1, 6)] && rules[4].1 == vec![q(7, 90), q(16, 45), q(2, 15), q(16, 45), q(7, 90)]);
    let r7 = &rules[7];                                  // road 2: one panel, readings every 4 hours
    let e7 = r7.0.iter().zip(&r7.1).fold(qi(0), |s, (x, w)| add(s, mul(mul(*w, qi(24)), pq(mul(qi(24), *x)))));
    let e7f = apply(r7, &p, 0.0, 24.0, 1);
    println!("road 2, 7-point rule on 7 readings, fractions: {} kWh; in floats {:.9}, off by {}", fr(e7), e7f, sci((e7f - ef).abs(), 1));
    assert!(e7 == e && (e7f - ef).abs() < 1e-12);         // degree 7 >= 6: exact, up to rounding
    println!("road 3: errors in kWh (true error) at spacing 40, 20, 10, 5 minutes; observed order");
    let mut errs = vec![];
    for i in 0..5 {
        let m = if i == 0 { 1 } else { rules[i].0.len() - 1 };
        let er: Vec<f64> = [36, 72, 144, 288].iter().map(|n| apply(&rules[i], &p, 0.0, 24.0, n / m) - ef).collect();
        let orders: Vec<f64> = (0..3).map(|k| (er[k] / er[k + 1]).abs().log2()).collect();
        println!("{:>13}: {}; order {}", names[i], join(&er.iter().map(|x| sci(*x, 3)).collect::<Vec<_>>()),
                 join(&orders.iter().map(|o| format!("{:.2}", o)).collect::<Vec<_>>()));
        assert!((orders[2] - (degree[i] + 1) as f64).abs() < 0.05);   // order = degree of exactness + 1
        errs.push(er);
    }
    let bx = (0..72).fold(qi(0), |s, pn| rules[4].0.iter().zip(&rules[4].1).fold(s, |s, (x, w)| add(s, mul(mul(*w, q(1, 3)), pq(mul(add(qi(pn), *x), q(1, 3)))))));
    let bx = fl(add(bx, q(-e.n, e.d)));
    println!("Boole at 5 minutes in exact fractions: error {}; in floats {}", sci(bx, 3), sci(errs[4][3], 3));
    assert!((bx - errs[4][3]).abs() < 1e-13 && bx.abs() > 1e-11);   // rounding moves only the 4th digit
    let floor: Vec<String> = [576, 1152, 2304].iter().map(|n| sci(apply(&rules[4], &p, 0.0, 24.0, n / 4) - ef, 3)).collect();
    println!("rounding floor: Boole at 2.5, 1.25, 0.625 minutes: {}", join(&floor));
    let h2: Vec<f64> = (0..13).map(|i| p(2.0 * i as f64)).collect();   // by hand: 13 readings, 2 hours apart
    let (ends, odd, even) = (h2[0] + h2[12], (1..12).step_by(2).fold(0.0, |s, i| s + h2[i]), (2..11).step_by(2).fold(0.0, |s, i| s + h2[i]));
    let (s12, t12) = (2.0 / 3.0 * (ends + 4.0 * odd + 2.0 * even), 2.0 * (ends / 2.0 + odd + even));
    println!("by hand, 2-hour readings: ends {:.4}, odd sum {:.4}, even inner sum {:.4}; Simpson {:.4}, error {:.4}; trapezoid {:.4}, error {:.4}", ends, odd, even, s12, s12 - ef, t12, t12 - ef);
    assert!((s12 - apply(&rules[2], &p, 0.0, 24.0, 6)).abs() < 1e-12 && (s12 - ef).abs() < (t12 - ef).abs() / 50.0);
    let (t10, s10, b10) = (apply(&rules[1], &p, 0.0, 24.0, 144), apply(&rules[2], &p, 0.0, 24.0, 72), apply(&rules[4], &p, 0.0, 24.0, 36));
    println!("10-minute readings, 145 of them: trapezoid {:.6}, Simpson {:.6}, Boole {:.9} kWh", t10, s10, b10);
    assert!((errs[0][2] / errs[1][2] + 0.5).abs() < 0.01);   // midpoint error: half, opposite sign
    println!("midpoint over trapezoid error at 10 minutes: {:.4}", errs[0][2] / errs[1][2]);
    for i in [1, 2, 4] {
        println!("chart, {} log10 |error| at log10 h = -0.18, -0.48, -0.78, -1.08: {}", names[i],
                 join(&errs[i].iter().map(|x| format!("{:.2}", x.abs().log10())).collect::<Vec<_>>()));
    }
    println!("closed rules: m slices per panel, sum of |weights| per unit width, smallest weight");
    let mut grow = vec![];
    for m in 1..=12i128 {
        let ws = closed(m).1;
        grow.push(ws.iter().fold(qi(0), |s, w| add(s, q(w.n.abs(), w.d))));
        let small = ws.iter().map(|w| fl(*w)).fold(f64::INFINITY, f64::min);
        if [1, 2, 4, 6, 7, 8, 9, 10, 11, 12].contains(&m) { println!("m = {:2}: sum |w| {:.4}, smallest {:.4}", m, fl(grow[m as usize - 1]), small); }
    }
    assert!(grow[..7].iter().all(|g| *g == qi(1)) && fl(grow[7]) > 1.0 && (7..10).all(|i| fl(grow[i]) < fl(grow[i + 2])));
    println!("noise: readings off by up to 0.05 kW move the answer at most 0.05 x 24 x sum |w|: composite {:.2} kWh, one 13-point rule {:.2} kWh",
             0.05 * 24.0, 0.05 * 24.0 * fl(grow[11]));
    let runge = |x: f64| 1.0 / (1.0 + 25.0 * x * x);
    let rr = 0.4 * 5f64.atan();
    println!("bell 1/(1 + 25x^2) on [-1, 1], exact {:.10}; m + 1 equally spaced points", rr);
    let mut bad = vec![];
    for m in [2, 4, 6, 8, 10, 12] {
        let (one, comp) = (apply(&closed(m), &runge, -1.0, 1.0, 1), apply(&closed(2), &runge, -1.0, 1.0, m as usize / 2));
        bad.push(((one - rr).abs(), (comp - rr).abs()));
        println!("m = {:2}: one degree-{} rule error {}; composite Simpson on the same points {}", m, m, sci((one - rr).abs(), 2), sci((comp - rr).abs(), 2));
    }
    assert!(bad[5].0 > bad[2].0 && bad[5].1 < bad[2].1 && bad[2].1 < bad[0].1);   // the one rule worsens, the composite improves
    let t143 = 143.0 / 6.0;                               // one reading lost: 143 slices to 23:50
    let e143 = fl(r7.0.iter().zip(&r7.1).fold(qi(0), |s, (x, w)| add(s, mul(mul(*w, q(143, 6)), pq(mul(q(143, 6), *x))))));
    let h = 1.0 / 6.0;
    let s143 = h / 3.0 * (p(0.0) + p(t143) + (1..143).fold(0.0, |s, i| s + if i % 2 == 1 { 4.0 } else { 2.0 } * p(i as f64 * h)));
    let s142 = apply(&rules[2], &p, 0.0, 142.0 / 6.0, 71) + apply(&rules[1], &p, 142.0 / 6.0, t143, 1);
    let plain = (0..145).fold(0.0, |s, i| s + p(i as f64 * h)) * h;
    println!("mistake, Simpson weights on 143 slices: {:.4} kWh against {:.4}, error {:.4}", s143, e143, s143 - e143);
    println!("repair: Simpson on 142 slices plus one trapezoid slice: {:.4} kWh, error {}", s142, sci(s142 - e143, 2));
    println!("mistake, h in minutes (10, not 1/6 hour): {:.2} 'kWh'", apply(&rules[1], &|t: f64| p(t / 60.0), 0.0, 1440.0, 144));
    println!("mistake, every reading times h, no halved ends: {:.4} kWh, error {:.4}", plain, plain - ef);
    assert!((s143 - e143).abs() > 100.0 * (s142 - e143).abs() && (plain - t10 - h * p(0.0)).abs() < 1e-9);
    assert!((s143 - (s142 - h / 6.0 * (p(142.0 * h) + p(t143)))).abs() < 1e-12);   // last slice weighted h/3, h/3, not h/2, h/2
    println!("ALL CHECKS PASS");
}
