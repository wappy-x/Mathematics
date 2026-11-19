// Vector field and its flow -- the check behind the card.  std only, no crates.
// Model current: the globe turning about the axis through the equator at 80E,
// 7 km a day at the North Pole.  Road one: RK4 steps chart by chart, chart A
// (polar angle, longitude) -> chart B (polar stereographic, km) -> chart A.
// Road two: RK4 in chart B alone.  Road three: the exact flow, a rotation.
const R: f64 = 6371.0;
const OM: f64 = 7.0 / 6371.0;
const D: f64 = std::f64::consts::PI / 180.0;
type V2 = [f64; 2];

fn al() -> f64 { 80.0 * D }
fn xa(s: V2) -> V2 {                                 // field in chart A: (phi', theta'), rad/day
    [-OM * (s[1] - al()).sin(), -OM * (s[1] - al()).cos() / s[0].tan()]
}
fn xb(s: V2) -> V2 {                                 // field in chart B: (u', v'), km/day
    let (u, v, sa, ca) = (s[0], s[1], al().sin(), al().cos());
    let (c, w) = ((4.0 * R * R - u * u - v * v) / (4.0 * R), u * sa - v * ca);
    [OM * (c * sa + w * u / (2.0 * R)), OM * (-c * ca + w * v / (2.0 * R))]
}
fn rk4(f: fn(V2) -> V2, mut s: V2, days: f64, n: usize) -> V2 {  // classical Runge-Kutta, n steps
    let h = days / n as f64;
    for _ in 0..n {
        let k1 = f(s);
        let k2 = f([s[0] + h / 2.0 * k1[0], s[1] + h / 2.0 * k1[1]]);
        let k3 = f([s[0] + h / 2.0 * k2[0], s[1] + h / 2.0 * k2[1]]);
        let k4 = f([s[0] + h * k3[0], s[1] + h * k3[1]]);
        let mut t = [0.0; 2];
        for i in 0..2 { t[i] = s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        s = t;
    }
    s
}
fn a2b(s: V2) -> V2 { let rho = 2.0 * R * (s[0] / 2.0).tan(); [rho * s[1].cos(), rho * s[1].sin()] }
fn b2a(s: V2) -> V2 { [2.0 * ((s[0].powi(2) + s[1].powi(2)).sqrt() / (2.0 * R)).atan(), s[1].atan2(s[0])] }
fn p3(s: V2) -> [f64; 3] { [R * s[0].sin() * s[1].cos(), R * s[0].sin() * s[1].sin(), R * s[0].cos()] }
fn exact(s: V2, t: f64) -> V2 {                      // the flow: turn by OM t about the axis
    let (p, c, n, sa, ca) = (p3(s), (OM * t).cos(), (OM * t).sin(), al().sin(), al().cos());
    let (ap, axp, ax) = (ca * p[0] + sa * p[1], [sa * p[2], -ca * p[2], ca * p[1] - sa * p[0]], [ca, sa, 0.0]);
    let mut q = [0.0; 3];
    for i in 0..3 { q[i] = p[i] * c + axp[i] * n + ax[i] * ap * (1.0 - c); }
    [(q[0].powi(2) + q[1].powi(2)).sqrt().atan2(q[2]), q[1].atan2(q[0])]
}
fn dist(s: V2, t: V2) -> f64 {                       // great-circle distance, km
    let (p, q) = (p3(s), p3(t));
    let ch = ((p[0] - q[0]).powi(2) + (p[1] - q[1]).powi(2) + (p[2] - q[2]).powi(2)).sqrt();
    2.0 * R * (ch / (2.0 * R)).min(1.0).asin()
}
fn lon(x: f64) -> f64 { (x / D + 180.0).rem_euclid(360.0) - 180.0 }
fn ll(s: V2) -> String {                             // latitude and longitude as text
    let l = lon(s[1]);
    format!("{:.2}N {:.2}{}", 90.0 - s[0] / D, l.abs(), if l < 0.0 { "W" } else { "E" })
}
fn e2(x: f64) -> String {                            // Python's .2e: two-digit exponent
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let k: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}
fn chartwise(s: V2, n: usize) -> V2 { rk4(xa, b2a(rk4(xb, a2b(rk4(xa, s, 150.0, n)), 110.0, n)), 105.0, n) }
fn gap2(a: V2, b: V2) -> f64 { ((a[0] - b[0]).powi(2) + (a[1] - b[1]).powi(2)).sqrt() }

fn main() {
    let (sa, ca) = (al().sin(), al().cos());
    let b1 = [13.0 * D, 170.0 * D];                  // buoy 1: 77N 170E
    let b2 = [13.0 * D, 170.0 * D + 5.0 / (R * (13.0 * D).sin())];  // buoy 2: 5 km east of buoy 1
    let (e1, ex2) = (exact(b1, 365.0), exact(b2, 365.0));
    println!("turn rate {:.7} rad/day = {:.5} deg/day; 13 deg to the pole = {:.1} km", OM, OM / D, 13.0 * D * R);
    println!("buoy 1 start {}; reaches the pole on day {:.2}", ll(b1), 13.0 * D / OM);
    println!("exact flow, day 365: {}; arc {:.1} km = {:.3} deg, {:.3} past the pole", ll(e1), OM * 365.0 * R, OM * 365.0 / D, OM * 365.0 / D - 13.0);
    let mut errs = vec![];
    for n in [10usize, 20] {
        let (c1, bb) = (chartwise(b1, n), b2a(rk4(xb, a2b(b1), 365.0, 2 * n)));
        errs.push(dist(c1, e1)); errs.push(dist(bb, e1));
        println!("{} steps a leg: chart by chart {}, off by {} km; chart B alone, {} steps, off by {} km", n, ll(c1), e2(dist(c1, e1)), 2 * n, e2(dist(bb, e1)));
    }
    println!("halving the step cuts the errors {:.1}-fold and {:.1}-fold", errs[0] / errs[2], errs[1] / errs[3]);
    let (mut s_a, mut s_b, mut gap) = (b1, a2b(b1), 0.0f64);  // overlap: A-motion seen in B = B-motion
    for _ in 0..150 {
        s_a = rk4(xa, s_a, 1.0, 2); s_b = rk4(xb, s_b, 1.0, 2);
        gap = gap.max(gap2(a2b(s_a), s_b));
    }
    println!("days 0-150, motion in A mapped into B against motion in B: largest gap below 1e-9 km: {}", if gap < 1e-9 { "yes" } else { "no" });
    let (xa2, uv) = (xa(b2), a2b(b2));
    let (xb2, r) = (xb(uv), (uv[0] * uv[0] + uv[1] * uv[1]).sqrt());
    let (ph, th) = (b2[0], b2[1]);
    let (j1, j2) = (R / (ph / 2.0).cos().powi(2), 2.0 * R * (ph / 2.0).tan());  // d rho/d phi, rho
    let jx = [j1 * th.cos() * xa2[0] - j2 * th.sin() * xa2[1], j1 * th.sin() * xa2[0] + j2 * th.cos() * xa2[1]];
    let (xfa, xfb) = (R * xa2[0], (uv[0] * xb2[0] + uv[1] * xb2[1]) / (r * (1.0 + r * r / (4.0 * R * R))));
    println!("buoy 2 start {}, chart B ({:.3}, {:.3}) km", ll(b2), uv[0], uv[1]);
    println!("  chart A components: phi' {:.8}, theta' {:.8} rad/day", xa2[0], xa2[1]);
    println!("  chart B components: u' {:.6}, v' {:.6} km/day; Jacobian times A: {:.6}, {:.6}", xb2[0], xb2[1], jx[0], jx[1]);
    println!("  Xf, f = distance to the pole: chart A {:.6}, chart B {:.6} km/day", xfa, xfb);
    let p0 = xb([0.0, 0.0]);
    println!("pole in chart B: u' {:.3}, v' {:.3}, speed {:.3} km/day", p0[0], p0[1], (p0[0].powi(2) + p0[1].powi(2)).sqrt());
    for s in [[90.0 * D, al()], [90.0 * D, al() - std::f64::consts::PI]] {
        let x = xa(s);
        println!("still point {}: speed {:.6} km/day", ll(s), ((R * x[0]).powi(2) + (R * s[0].sin() * x[1]).powi(2)).sqrt());
    }
    let sep: Vec<f64> = (0..366).map(|t| dist(exact(b1, t as f64), exact(b2, t as f64))).collect();
    let near = (0..1300).map(|k| exact(b2, 200.0 + k as f64 / 100.0)[0] * R).fold(f64::INFINITY, f64::min);
    let (smin, smax) = (sep.iter().cloned().fold(f64::INFINITY, f64::min), sep.iter().cloned().fold(0.0, f64::max));
    println!("buoys 1 and 2 apart, days 0-365: {:.3} to {:.3} km; buoy 2 passes {:.3} km from the pole", smin, smax, near);
    let lons: Vec<String> = (200..214).map(|d| format!("{:.1}", (exact(b2, d as f64)[1] / D).rem_euclid(360.0))).collect();
    println!("chart, buoy 2 longitude east 0-360, days 200..213: {}", lons.join(" "));
    let ea: Vec<f64> = [73usize, 146, 365].iter().map(|&n| dist(rk4(xa, b2, 365.0, n), ex2)).collect();
    let eb = dist(b2a(rk4(xb, a2b(b2), 365.0, 73)), ex2);
    println!("buoy 2, chart A alone, steps 5, 2.5, 1 days: off by {:.3}, {:.3}, {:.3} km; chart B, 5-day steps: {} km", ea[0], ea[1], ea[2], e2(eb));
    let na = rk4(xa, b1, 365.0, 365);
    println!("mistake, buoy 1 in chart A through the pole: polar angle {:.2} deg, read as {:.2}N", na[0] / D, 90.0 - na[0] / D);
    let n1 = [-OM * R * (170.0 * D).cos(), -OM * R * (170.0 * D).sin()];
    let n2 = [-OM * R * (10.0 * D).cos(), -OM * R * (10.0 * D).sin()];
    let jump = gap2(n1, n2);
    println!("mistake, 'due north at 7 km/day' at the pole, chart B: from 170E ({:.3}, {:.3}), from 10E ({:.3}, {:.3}); jump {:.3} km/day", n1[0], n1[1], n2[0], n2[1], jump);
    let (back, b76) = (exact(e1, -365.0), exact([14.0 * D, 170.0 * D], 365.0));
    let b3 = [13.0 * D, 170.0 * D + 50.0 / (R * (13.0 * D).sin())];
    let e3 = dist(rk4(xa, b3, 365.0, 73), exact(b3, 365.0));
    println!("try, run back 365 days from {}: {}; start 76N 170E: day 365 at {}", ll(e1), ll(back), ll(b76));
    println!("try, buoy 50 km east: chart A 5-day steps off by {:.3} km; speed 14 km/day: pole on day {:.2}", e3, 13.0 * D / (2.0 * OM));
    let sc = 0.14;                                   // figure: px per km, pole at (250, 220)
    let fx = |t: f64| { let b = a2b(exact(b1, t)); [250.0 + sc * (b[0] * sa - b[1] * ca), 220.0 - sc * (b[0] * ca + b[1] * sa)] };
    let pts: Vec<String> = [0.0, 100.0, 300.0, 365.0].iter().map(|&t| format!("{:.1} {:.1}", fx(t)[0], fx(t)[1])).collect();
    println!("figure, buoy 1 px at days 0, 100, 300, 365: {}; 77N circle r {:.1}; 80N circle r {:.1}", pts.join("; "), sc * 2.0 * R * (6.5 * D).tan(), sc * 2.0 * R * (5.0 * D).tan());
    println!("figure, scale {:.2} px/km; 30-day arrow at the pole {:.1} px; 300 km grid {:.1} px", sc, sc * 30.0 * OM * R, sc * 300.0);
    assert!(dist(chartwise(b1, 20), e1) < 1e-8 && dist(b2a(rk4(xb, a2b(b1), 365.0, 40)), e1) < 1e-7);
    assert!((90.0 - e1[0] / D - (90.0 - (OM * 365.0 / D - 13.0))).abs() < 1e-9);  // hand count past the pole
    assert!(14.0 < errs[0] / errs[2] && errs[0] / errs[2] < 18.0);                 // RK4 is fourth order
    assert!(14.0 < errs[1] / errs[3] && errs[1] / errs[3] < 18.0);
    assert!(gap < 1e-9 && (jx[0] - xb2[0]).abs() < 1e-9 && (jx[1] - xb2[1]).abs() < 1e-9);
    assert!((xfa - xfb).abs() < 1e-9 && (xfa + 7.0 * (b2[1] - 170.0 * D).cos()).abs() < 1e-9);
    assert!((smin - 5.0).abs() < 1e-4 && (smax - 5.0).abs() < 1e-4 && (near - 5.0).abs() < 1e-3);
    assert!(ea[0] > 1.0 && eb < 1e-6 && na[0] < 0.0 && jump > 13.0 && dist(back, b1) < 1e-9);
    println!("ALL CHECKS PASS");
}
