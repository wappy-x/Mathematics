// Partial derivatives -- the check behind the card.  std only.
// A house loses heat through walls and windows: Q(t, g) = DT ((A - g) / R(t) + U g)
// watts, where t is cm of insulation, g is square metres of glass (glass replaces
// wall), and R(t) = 0.5 + t / 4 is the wall's resistance.  Each rate is reached by
// two roads: raw difference quotients over shrinking steps, and the hand formula.
const A: f64 = 120.0;
const DT: f64 = 20.0;
const U: f64 = 2.5;
const T0: f64 = 6.0;
const G0: f64 = 20.0;

fn r(t: f64) -> f64 { 0.5 + t / 4.0 } // wall resistance, m2 K per W
fn q(t: f64, g: f64) -> f64 { DT * ((A - g) / r(t) + U * g) } // heat loss, watts
fn qt(t: f64, g: f64, h: f64) -> f64 { (q(t + h, g) - q(t, g)) / h } // freeze glass, step insulation
fn qg(t: f64, g: f64, k: f64) -> f64 { (q(t, g + k) - q(t, g)) / k } // freeze insulation, step glass
fn qt_f(t: f64, g: f64) -> f64 { -DT * (A - g) / (4.0 * r(t) * r(t)) } // hand formula, W per cm
fn qg_f(t: f64) -> f64 { DT * (U - 1.0 / r(t)) } // hand formula, W per m2
fn bx(t: f64, g: f64, h: f64, k: f64) -> f64 { (q(t + h, g + k) - q(t + h, g) - q(t, g + k) + q(t, g)) / (h * k) }
fn gg(x: f64, y: f64) -> f64 { if x == 0.0 && y == 0.0 { 0.0 } else { x * y * (x * x - y * y) / (x * x + y * y) } }

fn main() {
    println!("model: {:.0} m2 of wall in all, {:.0} C warmer inside, glass {} W per m2 per C, wall resistance {} + {} per cm (0.01 m / 0.04)",
        A, DT, U, r(0.0), r(1.0) - r(0.0));
    println!("heat loss at t = 6 cm, g = 20 m2: {:.2} W (wall resistance {:.2}, walls {:.2}, glass {:.2})",
        q(T0, G0), r(T0), DT * (A - G0) / r(T0), DT * U * G0);
    for (h, lab) in [(1.0, "1"), (0.1, "0.1"), (0.01, "0.01"), (0.001, "0.001")] {
        let v = qt(T0, G0, h);
        println!("insulation step {} cm: quotient {:.4} W per cm, algebra {:.4}, off by {:.4}",
            lab, v, -1000.0 / (8.0 + h), (v - qt_f(T0, G0)).abs());
        assert!((v - (-1000.0 / (8.0 + h))).abs() < 1e-8); // raw road == hand algebra
    }
    let gs: Vec<String> = [1.0, 0.1, 0.01].iter().map(|&k| format!("{:.4}", qg(T0, G0, k))).collect();
    println!("glass steps 1, 0.1, 0.01 m2: quotients {}; formula {:.4} W per m2", gs.join(", "), qg_f(T0));
    assert!((qg(T0, G0, 0.01) - qg_f(T0)).abs() < 1e-8 && (qt(T0, G0, 1e-6) - qt_f(T0, G0)).abs() < 1e-3);
    let (mut lo, mut hi) = (0.0_f64, 1.0_f64); // halve to the widest step within 0.1
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (qt(T0, G0, mid) - qt_f(T0, G0)).abs() <= 0.1 { lo = mid } else { hi = mid }
    }
    println!("to land within 0.1 W per cm of -125: widest step by halving {:.6} cm; algebra 0.8/124.9 = {:.6}", lo, 0.8 / 124.9);
    for (s, lab) in [(1.0, "1"), (0.1, "0.1"), (0.001, "0.001")] {
        println!("mixed, four corners {} cm by {} m2: {:.6} W per cm per m2", lab, lab, bx(T0, G0, s, s));
    }
    let tg = (qt_f(T0, G0 + 1e-6) - qt_f(T0, G0)) / 1e-6; // insulation rate, stepped in glass
    let gt = (qg_f(T0 + 1e-6) - qg_f(T0)) / 1e-6; // glass rate, stepped in insulation
    println!("mixed, insulation then glass {:.4}; glass then insulation {:.4}; hand {:.4}", tg, gt, DT / (4.0 * r(T0) * r(T0)));
    assert!((tg - 1.25).abs() < 1e-4 && (gt - 1.25).abs() < 1e-4 && (bx(T0, G0, 1e-3, 1e-3) - 1.25).abs() < 1e-3);
    println!("one more cm: exact change {:.2} W, the rate predicts {:.2} W", q(7.0, G0) - q(T0, G0), qt_f(T0, G0));
    println!("second case, t = 14 cm: insulation {:.4} (step 0.001: {:.4}) W per cm; glass {:.4} W per m2",
        qt_f(14.0, G0), qt(14.0, G0, 0.001), qg_f(14.0));
    let (e, n) = (1e-7, 1e-3); // inner step far below outer step
    let xy = ((gg(e, n) - gg(0.0, n)) / e - (gg(e, 0.0) - gg(0.0, 0.0)) / e) / n; // x first, then y
    let yx = ((gg(n, e) - gg(n, 0.0)) / e - (gg(0.0, e) - gg(0.0, 0.0)) / e) / n; // y first, then x
    println!("counterexample G at the origin: x then y {:.6}, y then x {:.6}", xy, yx);
    assert!((xy + 1.0).abs() < 1e-4 && (yx - 1.0).abs() < 1e-4); // hand limits: -1 and +1
    let qw = |t: f64, g: f64| DT * (A / r(t) + U * g); // mistake: glass added on top of 120 m2 of wall
    println!("mistake, walls kept at 120 m2: glass rate {:.2} W per m2, mixed {:.2}", qw(T0, G0 + 1.0) - qw(T0, G0),
        qw(T0 + 1.0, G0 + 1.0) - qw(T0 + 1.0, G0) - qw(T0, G0 + 1.0) + qw(T0, G0));
    for g in [20.0, 40.0] {
        let pts: Vec<String> = (0..9).map(|i| format!("{:.2}", q(2.0 * i as f64, g))).collect();
        println!("chart, g = {}: {}; slope at 6 cm {:.2}", g, pts.join(" "), qt_f(T0, g));
    }
    println!("ALL CHECKS PASS");
}
