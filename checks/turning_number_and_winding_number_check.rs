// Turning and winding numbers -- the same check as the Python, in Rust.  No
// crates.  A 400 m running track (straights 84.39 m, bends of radius 36.80 m
// on the running line) is lapped anticlockwise.  Its turns are counted two
// ways, the heading (turning number) and the arrow from a point (winding
// number), each by an angle sum and by a signed crossing count.
use std::f64::consts::PI;
type P = (f64, f64);
const ELL: f64 = 84.39;
const RHO: f64 = 36.80;
const N: usize = 4000;
const BEND: f64 = PI * RHO;             // length of one bend
const L: f64 = 2.0 * ELL + 2.0 * BEND;  // length of the lap on the running line
const RC: f64 = L / (2.0 * PI);         // radius of a circle of the same length

fn heading(s: f64) -> f64 {             // exact heading, radians from due east, by pieces
    let s = s % L;
    if s < ELL { 0.0 } else if s < ELL + BEND { (s - ELL) / RHO }
    else if s < 2.0 * ELL + BEND { PI } else { PI + (s - 2.0 * ELL - BEND) / RHO }
}

fn track(s: f64) -> P {                 // position, s metres from the home straight's start
    let s = s % L;
    if s < ELL { return (-ELL / 2.0 + s, -RHO) }
    if s < ELL + BEND {
        let t = (s - ELL) / RHO;
        return (ELL / 2.0 + RHO * t.sin(), -RHO * t.cos());
    }
    if s < 2.0 * ELL + BEND { return (ELL / 2.0 - (s - ELL - BEND), RHO) }
    let t = (s - 2.0 * ELL - BEND) / RHO;
    (-ELL / 2.0 - RHO * t.sin(), RHO * t.cos())
}

fn circle(s: f64) -> P { (RC * (s / RC).sin(), -RC * (s / RC).cos()) }

fn angle_sum(pts: &[P], a: P) -> f64 {  // road 2: add up each step's turn of the arrow from a
    let mut tot = 0.0;
    for k in 0..pts.len() {
        let ((x1, y1), (x2, y2)) = (pts[k], pts[(k + 1) % pts.len()]);
        let (x1, y1, x2, y2) = (x1 - a.0, y1 - a.1, x2 - a.0, y2 - a.1);
        tot += (x1 * y2 - y1 * x2).atan2(x1 * x2 + y1 * y2);
    }
    tot
}

fn crossings(pts: &[P], a: P) -> i64 {  // road 3: signed crossings of the ray due east of a
    let mut n = 0;
    for k in 0..pts.len() {
        let ((x1, y1), (x2, y2)) = (pts[k], pts[(k + 1) % pts.len()]);
        let (y1, y2) = (y1 - a.1, y2 - a.1);
        if (y1 < 0.0) != (y2 < 0.0) && x1 + (x2 - x1) * y1 / (y1 - y2) > a.0 {
            n += if y2 >= 0.0 { 1 } else { -1 };
        }
    }
    n
}

fn steps(pts: &[P]) -> Vec<P> {         // the chord directions: a sampled velocity curve
    (0..pts.len()).map(|k| { let q = pts[(k + 1) % pts.len()]; (q.0 - pts[k].0, q.1 - pts[k].1) }).collect()
}

fn turns(pts: &[P]) -> (f64, i64) {     // turning number two ways: the velocity's winding round 0
    (angle_sum(&steps(pts), (0.0, 0.0)) / (2.0 * PI), crossings(&steps(pts), (0.0, 0.0)))
}

fn sweep(pts: &[P]) -> f64 {            // an open path's turn of the arrow from the origin
    pts.windows(2).map(|w| (w[0].0 * w[1].1 - w[0].1 * w[1].0).atan2(w[0].0 * w[1].0 + w[0].1 * w[1].1)).sum()
}

fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn d2(x: f64) -> String { format!("{:.2}", x * 180.0 / PI) }
fn join(v: &[String]) -> String { v.join(", ") }

fn limacon(b: f64, m: usize) -> Vec<P> {
    (0..m).map(|k| { let t = 2.0 * PI * k as f64 / m as f64; let r = b + 20.0 * t.cos(); (r * t.cos(), r * t.sin()) }).collect()
}

fn main() {
    let ss: Vec<f64> = (0..N).map(|k| L * k as f64 / N as f64).collect();
    let lap: Vec<P> = ss.iter().map(|&s| track(s)).collect();
    println!("track: straights {:.2} m, bends of radius {:.2} m, lap {:.2} m", ELL, RHO, L);
    println!("bend {:.2} m long, curvature {:.6} 1/m, heading turned {} rad = {} deg", BEND, 1.0 / RHO, f6(BEND / RHO), d2(BEND / RHO));
    let pieces: Vec<f64> = [(0.0, ELL), (1.0 / RHO, BEND), (0.0, ELL), (1.0 / RHO, BEND)].iter().map(|&(k, ds)| k * ds).collect();
    let psum: f64 = pieces.iter().sum();
    println!("curvature x length, by pieces: {} = {} deg", pieces.iter().map(|&p| d2(p)).collect::<Vec<_>>().join(" + "), d2(psum));
    let c0 = RHO.atan2(ELL / 2.0);      // angle of a straight's end seen from the centre
    let sweeps = [PI - 2.0 * c0, 2.0 * c0, PI - 2.0 * c0, 2.0 * c0];
    let wsum: f64 = sweeps.iter().sum();
    println!("bearing from the centre: a straight's end {:.3} deg off level (half-straight {:.3} m); start {} deg", c0 * 180.0 / PI, ELL / 2.0, d2(PI + c0));
    println!("sight-line sweeps: {} = {} deg", sweeps.iter().map(|&p| d2(p)).collect::<Vec<_>>().join(" + "), d2(wsum));
    let (ta, tc) = turns(&lap);
    println!("sampled lap, {} points: heading angle sum {} rad = {} turns; velocity crossings {}", N, f6(2.0 * PI * ta), f6(ta), tc);
    let (centre, coach): (P, P) = ((0.0, 0.0), (0.0, -50.0));
    for (name, a) in [("centre (0, 0)", centre), ("coach (0, -50)", coach)] {
        println!("winding round the {}: angle sum {} turns; ray crossings {}", name, f6(angle_sum(&lap, a) / (2.0 * PI)), crossings(&lap, a));
    }
    let chart_s: Vec<f64> = (0..11).map(|k| L * k as f64 / 10.0).collect();
    let (mut bear, mut acc) = (Vec::new(), 0.0);
    let mut prev = track(0.0).1.atan2(track(0.0).0);
    for &s in &chart_s {
        let b = track(s).1.atan2(track(s).0);
        acc += (b - prev + PI).rem_euclid(2.0 * PI) - PI;
        prev = b;
        bear.push(acc);
    }
    let mut th: Vec<f64> = chart_s[..10].iter().map(|&s| heading(s)).collect();
    th.push(2.0 * PI);
    println!("chart s (m): {}", join(&chart_s.iter().map(|s| format!("{:.0}", s)).collect::<Vec<_>>()));
    println!("chart track heading turned (deg): {}", join(&th.iter().map(|h| format!("{:.1}", h * 180.0 / PI)).collect::<Vec<_>>()));
    println!("chart circle heading turned (deg): {}", join(&chart_s.iter().map(|s| format!("{:.1}", s / RC * 180.0 / PI)).collect::<Vec<_>>()));
    println!("chart bearing from centre turned (deg): {}", join(&bear.iter().map(|b| format!("{:.1}", b * 180.0 / PI)).collect::<Vec<_>>()));
    println!("deformation: track (u = 0) into a circle of radius {:.2} m (u = 1), both start heading east, same s", RC);
    let mut stages = Vec::new();
    for u in [0.0, 0.25, 0.5, 0.75, 1.0] {
        let pts: Vec<P> = ss.iter().map(|&s| ((1.0 - u) * track(s).0 + u * circle(s).0, (1.0 - u) * track(s).1 + u * circle(s).1)).collect();
        let slow = ss.iter().map(|&s| ((1.0 - u) * heading(s).cos() + u * (s / RC).cos()).hypot((1.0 - u) * heading(s).sin() + u * (s / RC).sin()))
            .fold(f64::INFINITY, f64::min);
        let (t, c) = turns(&pts);
        let (wc, wk) = ((angle_sum(&pts, centre) / (2.0 * PI)).round() as i64, (angle_sum(&pts, coach) / (2.0 * PI)).round() as i64);
        let kc = crossings(&pts, coach);
        stages.push((slow, t.round() as i64, c, wc, wk, kc));
        println!("  u = {:.2}: least speed {}, turning {} (crossings {}), winding round centre {}, round coach {} (crossings {})", u, f6(slow), f6(t), c, wc, wk, kc);
    }
    let eight: Vec<P> = (0..N).map(|k| { let t = 2.0 * PI * k as f64 / N as f64; (60.0 * t.sin(), 30.0 * (2.0 * t).sin()) }).collect();
    let (e_t, e_c) = turns(&eight);
    let e_w: Vec<i64> = [40.0, -40.0].iter().map(|&x| (angle_sum(&eight, (x, 0.0)) / (2.0 * PI)).round() as i64).collect();
    println!("figure-eight (60 sin t, 30 sin 2t) m: turning {} (crossings {}); winding round (40, 0) {}, round (-40, 0) {}", f6(e_t), e_c, e_w[0], e_w[1]);
    let mut lim: Vec<(f64, i64, i64)> = Vec::new();
    for b in [30.0, 20.0, 10.0] {
        let slow = (0..N).map(|k| { let t = 2.0 * PI * k as f64 / N as f64;
            (-20.0 * t.sin() * t.cos() - (b + 20.0 * t.cos()) * t.sin()).hypot(-20.0 * t.sin() * t.sin() + (b + 20.0 * t.cos()) * t.cos()) })
            .fold(f64::INFINITY, f64::min);
        if slow < 1e-9 {
            println!("limacon r = {:.0} + 20 cos t m: least speed {} at the cusp, so no tangent there and no turning number", b, f6(slow));
            lim.push((slow, -99, -99));
            continue;
        }
        let pts = limacon(b, N);
        let (t, c) = turns(&pts);
        let w: Vec<i64> = [5.0, 20.0, 40.0].iter().map(|&x| (angle_sum(&pts, (x, 0.0)) / (2.0 * PI)).round() as i64).collect();
        lim.push((slow, t.round() as i64, c));
        println!("limacon r = {:.0} + 20 cos t m: least speed {}, turning {} (crossings {}); winding round (5, 0), (20, 0), (40, 0): {:?}", b, f6(slow), f6(t), c, w);
    }
    let half = heading(L / 2.0) / (2.0 * PI);
    let st8 = steps(&eight);
    let absk: f64 = (0..N).map(|k| { let ((x1, y1), (x2, y2)) = (st8[k], st8[(k + 1) % N]); (x1 * y2 - y1 * x2).atan2(x1 * x2 + y1 * y2).abs() }).sum::<f64>() / (2.0 * PI);
    let coarse_n = 5;                    // sample points for mistake 3
    let coarse = turns(&limacon(10.0, coarse_n));
    println!("mistake 1, half a lap is no loop: heading turned {} deg = {} turns", d2(2.0 * PI * half), f6(half));
    println!("mistake 2, adding |kappa| on the figure-eight: {} turns, not 0", f6(absk));
    println!("mistake 3, limacon r = 10 + 20 cos t sampled at {} points: turning {}, not 2", coarse_n, f6(coarse.0));
    assert!((2.0 * PI * ta - psum).abs() < 1e-9 && tc == ta.round() as i64 && tc == 1);  // exact pieces vs samples
    assert!((wsum - angle_sum(&lap, centre)).abs() < 1e-9);                                // by hand vs samples
    assert!([(0.0, ELL, sweeps[0]), (ELL, BEND, sweeps[1])].iter().all(|&(a, d, w)| (sweep(&(0..101).map(|k| track(a + d * k as f64 / 100.0)).collect::<Vec<P>>()) - w).abs() < 1e-9));
    assert!(crossings(&lap, centre) == 1 && crossings(&lap, coach) == 0);
    assert!(steps(&lap).iter().all(|d| (d.0.hypot(d.1) - L / N as f64).abs() < 1e-6));   // samples evenly spaced: no jumps
    assert!(stages.iter().all(|st| st.0 > 0.5 && st.1 == 1 && st.2 == 1 && st.3 == 1));
    assert!(stages.iter().all(|st| st.4 == st.5) && stages[0].4 == 0 && stages[4].4 == 1);
    assert!(e_t.round() as i64 == 0 && e_c == 0 && e_w == vec![-1, 1]);
    assert!(lim[0].1 == 1 && lim[0].2 == 1 && lim[2].1 == 2 && lim[2].2 == 2 && lim[1].0 < 1e-9);
    assert!([30.0f64, 20.0, 10.0].iter().zip(&lim).all(|(&b, l)| (l.0 - (b - 20.0).abs()).abs() < 1e-6)); // least speed = |b - 20|, at t = pi
    println!("ALL CHECKS PASS");
}
