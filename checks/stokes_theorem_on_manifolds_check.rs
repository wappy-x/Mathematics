// Stokes on manifolds -- the same check as the Python, in Rust.  No crates.  The manifold M is a
// dome-tent panel: the upper half of a sphere, R = 1.5 m, whose edge (its hem) is the circle on the
// ground.  The valley wind is a one-form w = P dx + Q dy + S dz: a 3 m/s breeze east, plus an eddy
// turning at k = 0.4 per second at the ground and faster higher up.  Stokes: integral of dw over M
// equals integral of w round the hem.  Road A walks the hem.  Road B takes d in space, then pulls it
// back to the globe chart.  Road C pulls w back to a second chart, then takes d there.
use std::f64::consts::PI;
const R: f64 = 1.5;
const K0: f64 = 0.4;
const BREEZE: f64 = 3.0;
type V = [f64; 3];
type Form = dyn Fn(V) -> V;
type Chart = fn(f64, f64) -> V;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for j in 0..=n {
        let wt = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
        s += wt * f(a + j as f64 * h);
    }
    h / 3.0 * s
}
fn wind(p: V) -> V { let k = K0 * (1.0 + p[2] / R); [BREEZE - k * p[1], k * p[0], 0.0] }
fn breeze(_p: V) -> V { [BREEZE, 0.0, 0.0] }
fn angle(p: V) -> V { let s = p[0] * p[0] + p[1] * p[1]; [-p[1] / s, p[0] / s, 0.0] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn rate(f: &dyn Fn(f64) -> V, t: f64) -> V {      // velocity of a moving point, by difference quotient
    let h = 1e-5;
    let (a, b) = (f(t + h), f(t - h));
    [(a[0] - b[0]) / (2.0 * h), (a[1] - b[1]) / (2.0 * h), (a[2] - b[2]) / (2.0 * h)]
}
fn d(w: &Form, p: V) -> V {                        // exterior derivative: the dy^dz, dz^dx, dx^dy parts
    let h = 1e-4;
    let mut j = [[0.0; 3]; 3];
    for c in 0..3 {
        let (mut up, mut dn) = (p, p);
        up[c] += h;
        dn[c] -= h;
        let (a, b) = (w(up), w(dn));
        for i in 0..3 { j[i][c] = (a[i] - b[i]) / (2.0 * h) }
    }
    [j[2][1] - j[1][2], j[0][2] - j[2][0], j[1][0] - j[0][1]]
}
fn edge(w: &Form, c: &dyn Fn(f64) -> V, t0: f64, t1: f64) -> f64 {   // road A: add w along a curve
    simpson(&|t| dot(w(c(t)), rate(c, t)), t0, t1, 64)
}
fn circle(phi: f64, turn: f64) -> impl Fn(f64) -> V {
    move |t| [R * phi.sin() * t.cos(), turn * R * phi.sin() * t.sin(), R * phi.cos()]
}
fn globe(ph: f64, th: f64) -> V { [R * ph.sin() * th.cos(), R * ph.sin() * th.sin(), R * ph.cos()] }
fn stereo(rho: f64, th: f64) -> V {               // chart two: the floor disc, lifted from the bottom pole
    let (u, v, s) = (rho * th.cos(), rho * th.sin(), R * R + rho * rho);
    [2.0 * R * R * u / s, 2.0 * R * R * v / s, R * (R * R - rho * rho) / s]
}
fn d_then_pull(w: &Form, chart: Chart, a0: f64, a1: f64, n: usize) -> f64 {   // road B
    let g = |a: f64, t: f64| {
        let (ra, rt) = (rate(&|s| chart(s, t), a), rate(&|s| chart(a, s), t));
        dot(d(w, chart(a, t)), cross(ra, rt))
    };
    simpson(&|a| simpson(&|t| g(a, t), 0.0, 2.0 * PI, n), a0, a1, n)
}
fn pull(w: &Form, chart: Chart, a: f64, t: f64) -> [f64; 2] {   // the pulled-back form: da, dt parts
    let p = chart(a, t);
    [dot(w(p), rate(&|s| chart(s, t), a)), dot(w(p), rate(&|s| chart(a, s), t))]
}
fn pull_then_d(w: &Form, chart: Chart, a0: f64, a1: f64) -> f64 {           // road C
    let h = 1e-4;
    let g = |a: f64, t: f64| {
        (pull(w, chart, a + h, t)[1] - pull(w, chart, a - h, t)[1]) / (2.0 * h)
            - (pull(w, chart, a, t + h)[0] - pull(w, chart, a, t - h)[0]) / (2.0 * h)
    };
    simpson(&|a| simpson(&|t| g(a, t), 0.0, 2.0 * PI, 96), a0, a1, 96)
}
fn f(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn gee(ph: f64) -> f64 { K0 * R * R * (1.0 + ph.cos()) * ph.sin().powi(2) }
fn three(v: V) -> String { format!("{}, {}, {}", f(v[0]), f(v[1]), f(v[2])) }

fn main() {
    let hand = 2.0 * PI * K0 * R * R;
    let (hem, a_breeze) = (edge(&wind, &circle(PI / 2.0, 1.0), 0.0, 2.0 * PI), edge(&breeze, &circle(PI / 2.0, 1.0), 0.0, 2.0 * PI));
    let (b, c) = (d_then_pull(&wind, globe, 0.0, PI / 2.0, 64), pull_then_d(&wind, stereo, 0.0, R));
    println!("tent radius {:.1} m, R^2 {:.2} m^2; eddy speed at the hem {:.3} m/s; breeze {:.1} m/s east", R, R * R, K0 * R, BREEZE);
    println!("n = 1, breeze form 3 dx along the half hem, east to west: walked {}; endpoints 3x(west) - 3x(east) = {}",
             f(edge(&breeze, &circle(PI / 2.0, 1.0), 0.0, PI)), f(BREEZE * (-R) - BREEZE * R));
    println!("road A, w round the hem: {} m^2/s; the breeze's share {}", f(hem), f(a_breeze));
    println!("road B, d then pull back, globe chart: {}", f(b));
    println!("road C, pull back then d, floor-disc chart: {}", f(c));
    println!("by hand, 2 pi k R^2 = {}", f(hand));
    for deg in [30, 60, 90] {
        let ph = deg as f64 * PI / 180.0;
        println!("cap down to {:2} deg: dw inside {}; w round its edge {}; 2 pi gee {}; gee {}; 1 + cos {}; sin^2 {}", deg,
                 f(d_then_pull(&wind, globe, 0.0, ph, 64)), f(edge(&wind, &circle(ph, 1.0), 0.0, 2.0 * PI)),
                 f(2.0 * PI * gee(ph)), f(gee(ph)), f(1.0 + ph.cos()), f(ph.sin().powi(2)));
    }
    for top in [[0.0, 0.0, R], [R, 0.0, 0.0]] {
        println!("dw at ({:.1}, {:.1}, {:.1}): dy^dz, dz^dx, dx^dy = {}", top[0], top[1], top[2], three(d(&wind, top)));
    }
    for n in [4, 8] {
        let v = d_then_pull(&wind, globe, 0.0, PI / 2.0, n);
        println!("road B with {} Simpson strips a side: {}, error {:.6}", n, f(v), (v - hand).abs());
    }
    let rev = edge(&wind, &circle(PI / 2.0, -1.0), 0.0, 2.0 * PI);
    let vent_in = d_then_pull(&wind, globe, PI / 6.0, PI / 2.0, 64);
    let vent_edge = edge(&wind, &circle(PI / 6.0, -1.0), 0.0, 2.0 * PI);
    println!("break 1, hem walked clockwise from above: {} against {}", f(rev), f(b));
    println!("break 2, vent cut down to 30 deg: dw inside {}; hem alone {}; vent edge walked clockwise {}; both edges {}",
             f(vent_in), f(hem), f(vent_edge), f(hem + vent_edge));
    let ang_in = d_then_pull(&angle, globe, PI / 180.0, PI / 2.0, 64);
    let ang_hem = edge(&angle, &circle(PI / 2.0, 1.0), 0.0, 2.0 * PI);
    println!("break 3, angle form: d at (1, 0.5, 0.8) {}; dw inside, pole cut out {}; hem {}; circle 1 deg from the pole {}",
             three(d(&angle, [1.0, 0.5, 0.8])), f(ang_in), f(ang_hem),
             f(edge(&angle, &circle(PI / 180.0, 1.0), 0.0, 2.0 * PI)));
    let (e, s, cx, cy) = (25.0 * PI / 180.0, 120.0, 240.0, 230.0);   // view 25 deg above the horizon
    let scr = |p: V| [cx + s * p[0], cy - s * (p[1] * e.sin() + p[2] * e.cos())];
    let g45 = globe(PI / 4.0, 0.0);
    let (base, tip) = (scr(g45), scr([g45[0] * (R + 0.5) / R, g45[1] * (R + 0.5) / R, g45[2] * (R + 0.5) / R]));
    let hide = (e.tan() / (PI / 6.0).tan()).asin();   // the vent circle is behind the top from hide to 180 deg - hide
    let (v1, v2) = (scr(circle(PI / 6.0, 1.0)(hide)), scr(circle(PI / 6.0, 1.0)(PI - hide)));
    println!("figure, 120 px per m: hem ry {:.1}; vent cy {:.1} rx {:.1} ry {:.1}; normal {:.1},{:.1} to {:.1},{:.1}; vent hidden {:.1} to {:.1} deg, {:.1},{:.1} to {:.1},{:.1}",
             s * R * e.sin(), scr([0.0, 0.0, R * (PI / 6.0).cos()])[1], s * R * (PI / 6.0).sin(),
             s * R * (PI / 6.0).sin() * e.sin(), base[0], base[1], tip[0], tip[1],
             hide.to_degrees(), 180.0 - hide.to_degrees(), v1[0], v1[1], v2[0], v2[1]);
    assert!((hem - b).abs() < 1e-6 && (hem - c).abs() < 1e-6);          // three roads, one number
    assert!((b - hand).abs() < 1e-6 && a_breeze.abs() < 1e-9);         // the hand count; an exact form round a closed loop
    assert!((vent_in - (hem + vent_edge)).abs() < 1e-6 && (vent_in - (hand - 2.0 * PI * gee(PI / 6.0))).abs() < 1e-6);
    assert!(rev < 0.0 && ang_in.abs() < 1e-6 && (ang_hem - 2.0 * PI).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
