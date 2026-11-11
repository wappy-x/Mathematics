// Subgradients -- the check behind the card.  Rust std only, no crates.
// A roaster needs 100 kg of beans a week.  Kenyan beans cost £9/kg for the first
// 40 kg, £14/kg from 40 to 70 kg and £20/kg past 70 kg; Brazilian beans at £12/kg
// fill the rest.  Roads: the max rule, a brute-force test of the definition,
// one-sided difference slopes, and a full enumeration of the purchase.
const LINES: [(f64, f64); 3] = [(9.0, 0.0), (14.0, -200.0), (20.0, -620.0)]; // C(q) = max of a*q + b
const NEED: f64 = 100.0; // kg needed
const P: f64 = 12.0; // £/kg substitute
const KNEE: f64 = 40.0; // the volume break

fn cost(q: f64) -> f64 { LINES.iter().map(|&(a, b)| a * q + b).fold(f64::MIN, f64::max) }
fn net_with(q: f64, p: f64, c: &dyn Fn(f64) -> f64) -> f64 { c(q) + p * (NEED - q) }
fn net(q: f64) -> f64 { net_with(q, P, &cost) }

fn max_rule(q: f64) -> (f64, f64) { // slopes of the lines that touch the top at q
    let top = cost(q);
    let act: Vec<f64> = LINES.iter().filter(|&&(a, b)| a * q + b == top).map(|&(a, _)| a).collect();
    (act.iter().cloned().fold(f64::MAX, f64::min), act.iter().cloned().fold(f64::MIN, f64::max))
}
fn brute(f: &dyn Fn(f64) -> f64, x: f64, ys: &[f64], gs: &[f64]) -> Vec<f64> {
    gs.iter().cloned().filter(|&g| ys.iter().all(|&y| f(y) - f(x) >= g * (y - x))).collect()
}
fn one_sided(f: &dyn Fn(f64) -> f64, x: f64) -> (f64, f64) {
    let h = 1e-3;
    ((f(x) - f(x - h)) / h, (f(x + h) - f(x)) / h)
}
fn best(f: &dyn Fn(f64) -> f64, qs: &[f64]) -> (f64, f64) {
    let mut q = qs[0];
    for &x in qs { if f(x) < f(q) { q = x; } }
    (q, f(q))
}
fn num(v: f64) -> String { format!("{}", v) }
fn list(f: &dyn Fn(f64) -> f64, qs: &[f64]) -> String {
    qs.iter().map(|&q| num(f(q))).collect::<Vec<_>>().join(", ")
}

fn main() {
    let qs: Vec<f64> = (0..201).map(|i| i as f64 / 2.0).collect();
    let fourq = [0.0, 40.0, 70.0, 100.0];
    println!("Kenyan cost C(q) at 0, 40, 70, 100 kg: {}", list(&cost, &fourq));
    let at40: Vec<String> = LINES.iter().map(|&(a, b)| num(a * KNEE + b)).collect();
    println!("at 40 kg the three lines read {}; 60 kg of Brazilian costs £{}", at40.join(", "), num(P * (NEED - KNEE)));
    let (lo, hi) = max_rule(KNEE);
    let (left, right) = one_sided(&cost, KNEE);
    let g: Vec<f64> = (0..2501).map(|i| i as f64 / 100.0).collect(); // trial slopes £0.00 .. £25.00
    let ok = brute(&cost, KNEE, &qs, &g);
    println!("one-sided slopes of C at 40 kg (h = 0.001): {:.3} and {:.3}", left, right);
    println!("max rule at 40 kg: active slopes {} and {}, so dC(40) = [{}, {}]", lo, hi, lo, hi);
    println!("brute force at 40 kg: g from {:.2} to {:.2} passes ({} of {} tried)", ok[0], ok[ok.len() - 1], ok.len(), g.len());
    let (m55, m70) = (max_rule(55.0), max_rule(70.0));
    println!("max rule at 55 and 70 kg: dC(55) = [{}, {}], dC(70) = [{}, {}]", m55.0, m55.1, m70.0, m70.1);
    assert!((left - lo).abs() < 1e-6 && (right - hi).abs() < 1e-6); // road 1 against road 3
    assert!(ok[0] == lo && ok[ok.len() - 1] == hi && ok.len() == 501); // road 1 against road 2
    assert!(m55 == (14.0, 14.0) && m70 == (14.0, 20.0));

    println!("net cost F(q) at 0, 40, 70, 100 kg: {}", list(&net, &fourq));
    let (dlo, dhi) = (lo - P, hi - P);
    let gf: Vec<f64> = (-1000..1001).map(|i| i as f64 / 100.0).collect();
    let okf = brute(&net, KNEE, &qs, &gf);
    println!("dF(40) = dC(40) - 12 = [{}, {}]; brute force gives [{:.2}, {:.2}]; 0 inside: {}",
             dlo, dhi, okf[0], okf[okf.len() - 1], if dlo <= 0.0 && 0.0 <= dhi { "True" } else { "False" });
    let (qb, fb) = best(&net, &qs);
    println!("enumeration of all 201 half-kilo plans: cheapest at {} kg, £{}", num(qb), num(fb));
    assert!(okf[0] == dlo && okf[okf.len() - 1] == dhi && dlo <= 0.0 && 0.0 <= dhi);
    assert!(qb == KNEE && fb == 1080.0);
    let keep: Vec<f64> = (0..61).map(|p| p as f64 / 2.0)
        .filter(|&p| net_with(KNEE, p, &cost) == best(&|q| net_with(q, p, &cost), &qs).1).collect();
    println!("substitute prices (in 50p steps) at which 40 kg is among the cheapest: £{} to £{}", num(keep[0]), num(keep[keep.len() - 1]));
    for p in [8.0, 15.0] {
        let (q, f) = best(&|q| net_with(q, p, &cost), &qs);
        println!("  substitute at £{}: best buy {} kg of Kenyan, £{}", p, num(q), num(f));
    }
    assert!(keep[0] == lo && keep[keep.len() - 1] == hi);

    let ab = |x: f64| x.abs();
    let xs: Vec<f64> = (-10..11).map(|i| i as f64 / 2.0).collect();
    let g1: Vec<f64> = (-200..201).map(|i| i as f64 / 100.0).collect();
    let (a0, a1) = (brute(&ab, 0.0, &xs, &g1), brute(&ab, 2.5, &xs, &g1));
    println!("|x| at 0: g from {:.2} to {:.2} passes; at 2.5: only {:.2} ({} value)", a0[0], a0[a0.len() - 1], a1[0], a1.len());
    assert!(a0[0] == -1.0 && a0[a0.len() - 1] == 1.0 && a0.len() == 201 && a1 == vec![1.0]);
    let mut y2 = Vec::new();
    for u in -10..11 { for v in -10..11 { y2.push((u as f64 / 2.0, v as f64 / 2.0)); } }
    let mut g2 = Vec::new();
    for u in -8..9 { for v in -8..9 { g2.push((u as f64 / 4.0, v as f64 / 4.0)); } }
    let brute2 = |f: &dyn Fn((f64, f64)) -> f64, x: (f64, f64)| -> Vec<(f64, f64)> {
        g2.iter().cloned().filter(|g| y2.iter().all(|&y| f(y) - f(x) >= g.0 * (y.0 - x.0) + g.1 * (y.1 - x.1))).collect()
    };
    let n1 = |y: (f64, f64)| y.0.abs() + y.1.abs();
    let ninf = |y: (f64, f64)| y.0.abs().max(y.1.abs());
    let (s1, sinf) = (brute2(&n1, (3.0, 0.0)), brute2(&ninf, (3.0, -3.0)));
    println!("||x||_1 at (3, 0): {} of {} trial g pass, g1 = {}, g2 from {} to {}",
             s1.len(), g2.len(), num(s1[0].0), num(s1[0].1), num(s1[s1.len() - 1].1));
    let pass: Vec<String> = sinf.iter().map(|&(a, b)| format!("({}, {})", num(a), num(b))).collect();
    println!("||x||_inf at (3, -3): passing g = {}", pass.join(" "));
    let g11 = s1[s1.len() - 1]; // the subgradient (1, 1) at (3, 0)
    let st = (3.0 - g11.0, 0.0 - g11.1); // one step along minus it
    println!("||x||_1 from (3, 0) along minus ({}, {}) to ({}, {}): {}, was {}",
             num(g11.0), num(g11.1), num(st.0), num(st.1), num(n1(st)), num(n1((3.0, 0.0))));
    assert!(s1 == (-4..5).map(|v| (1.0, v as f64 / 4.0)).collect::<Vec<_>>()); // {1} x [-1, 1]
    assert!(sinf == (0..5).map(|t| (t as f64 / 4.0, t as f64 / 4.0 - 1.0)).collect::<Vec<_>>());

    println!("what breaks:");
    println!("  right slope taken as the derivative: +{} says move left; 38 kg costs £{}", hi - P, num(net(38.0)));
    let wrong = (LINES.iter().map(|l| l.0).fold(f64::MAX, f64::min), LINES.iter().map(|l| l.0).fold(f64::MIN, f64::max));
    let (qw, fw) = best(&|q| net_with(q, 18.0, &cost), &qs);
    println!("  every piece counted, not only active: [{}, {}]; at £18 that keeps 40 kg (£{}), best is {} kg at £{}",
             wrong.0, wrong.1, num(net_with(40.0, 18.0, &cost)), num(qw), num(fw));
    let disc = |q: f64| (14.0 * q).min(9.0 * q + 200.0); // a discount past 40 kg: concave
    let (dl, dr) = one_sided(&disc, KNEE);
    let od = brute(&disc, KNEE, &qs, &g);
    let (qd, fd) = best(&|q| net_with(q, P, &disc), &qs);
    println!("  discount tier: slopes {:.0} then {:.0}, {} subgradients at 40 kg; 40 kg costs £{}, best is {} kg at £{}",
             dl, dr, od.len(), num(net_with(40.0, P, &disc)), num(qd), num(fd));
    assert!(net(38.0) > net(KNEE) && qw == 70.0 && fw < net_with(40.0, 18.0, &cost) && od.is_empty() && qd == 100.0);

    let sx = |q: f64| 40.0 + 2.8 * q; // figure: q 0..100 -> x 40..320
    let sy = |f: f64| 210.0 - 0.425 * (f - 1000.0); // £1000..£1400 -> y 210..40
    let pts: Vec<String> = fourq.iter().map(|&q| format!("{:.1},{:.1}", sx(q), sy(net(q)))).collect();
    let sup: Vec<String> = [-1i32, 0, 1].iter().map(|&s| format!("{:+}:{:.1},{:.1}-{:.1},{:.1}",
        s, sx(20.0), sy(1080.0 - 20.0 * s as f64), sx(60.0), sy(1080.0 + 20.0 * s as f64))).collect();
    println!("figure, F polyline {} | supporting lines {}", pts.join(" "), sup.join(" "));
    println!("ALL CHECKS PASS");
}
