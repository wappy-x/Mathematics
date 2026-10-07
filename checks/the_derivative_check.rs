// The derivative -- the check behind the card.  std only.
// The car's odometer reads s(t) = 2 t^2 metres at t seconds.  The speed at
// a = 5 s is reached by two roads: raw average speeds over shrinking windows,
// and the hand algebra 4a + 2h.  Whole-second odometer readings give a third.
const A: f64 = 5.0;
const TOL: f64 = 0.001;

fn s(t: f64) -> f64 { 2.0 * t * t } // the odometer, metres
fn corner(t: f64) -> f64 { if t <= A { s(t) } else { s(A) } } // stops dead at 5 s
fn jump(t: f64) -> f64 { s(t) - if t >= A { s(A) } else { 0.0 } } // trip meter reset at 5 s
fn avg(f: fn(f64) -> f64, a: f64, h: f64) -> f64 { (f(a + h) - f(a)) / h }

fn main() {
    println!("odometer at a = {:.0} s: {:.3} m", A, s(A));
    for h in [1.0, 0.1, 0.01, 0.001, 0.0001, -0.0001, -1.0] {
        let q = avg(s, A, h);
        println!("window {:+.4} s: average {:.6} m/s, off by {:.6}", h, q, (q - 4.0 * A).abs());
        assert!((q - (4.0 * A + 2.0 * h)).abs() < 1e-7); // raw road == algebra road
    }
    let readings: Vec<f64> = (0..7).map(|t| s(t as f64)).collect();
    let per_second: Vec<f64> = (0..6).map(|k| readings[k + 1] - readings[k]).collect();
    let odo = (per_second[4] + per_second[5]) / 2.0;
    let ints = |v: &Vec<f64>| v.iter().map(|x| *x as i64).collect::<Vec<i64>>();
    println!("odometer, seconds 0 to 6: {:?} m", ints(&readings));
    println!("metres in each second: {:?}; mean of the two around 5 s: {:.3} m/s", ints(&per_second), odo);
    assert!((odo - avg(s, A, 1e-6)).abs() < 1e-5); // whole seconds == shrinking window
    let (mut lo, mut hi) = (0.0_f64, 1.0_f64); // halve to the widest window within TOL
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (avg(s, A, mid) - 4.0 * A).abs() <= TOL { lo = mid } else { hi = mid }
    }
    println!("to land within {} m/s of 20: widest window by halving {:.6} s; algebra {:.6} s", TOL, lo, TOL / 2.0);
    assert!((lo - TOL / 2.0).abs() < 1e-9);
    for h in [0.1, 0.01, 0.001] {
        println!("continuity, window {}: gap {:.6} m = {} x {:.6}", h, s(A + h) - s(A), h, avg(s, A, h));
    }
    let (left, right) = (avg(corner, A, -0.001), avg(corner, A, 0.001));
    println!("corner: left average {:.6}, right {:.6} m/s; gaps {:.6} and {:.6} m", left, right,
        (corner(A - 0.001) - corner(A)).abs(), (corner(A + 0.001) - corner(A)).abs());
    assert!(left - right > 19.0); // two one-sided rates: no derivative
    println!("jump: left average {:.4} at -0.001 s, {:.4} at -0.0001 s", avg(jump, A, -0.001), avg(jump, A, -0.0001));
    println!("second case, a = 2 s: window 0.0001 gives {:.6}; algebra 4a = {} m/s", avg(s, 2.0, 0.0001), 4 * 2);
    println!("mistakes: whole trip {:.3} m/s; one-second window {:.3} m/s; answer 20 m/s = {:.0} km/h",
        s(A) / A, avg(s, A, 1.0), 20.0 * 3.6);
    let x = |t: f64| 40.0 + 140.0 * (t - 4.0); // figure: 1 s = 140 units
    let y = |m: f64| 220.0 - 4.0 * (m - 30.0); // 1 m = 4 units, y points down
    let pts = [(4.0, s(4.0)), (5.1, s(4.0) + 16.0 * 1.1), (6.2, s(6.2)), (5.0, 50.0), (6.0, 72.0),
        (4.2, 50.0 - 20.0 * 0.8), (6.2, 50.0 + 20.0 * 1.2), (4.4, 50.0 - 22.0 * 0.6), (6.2, 50.0 + 22.0 * 1.2)];
    let fig: Vec<String> = pts.iter().map(|&(t, m)| format!("({:.1},{:.2})", x(t), y(m))).collect();
    println!("figure, {}", fig.join(" "));
    println!("ALL CHECKS PASS");
}
