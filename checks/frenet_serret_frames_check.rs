// Frenet-Serret frame -- the same check as the Python, in Rust.  No crates.
// A camera rig rides a climbing left turn r(t) = L(t, t^2/2, t^3/3), L = 15 m,
// in metres east, north, up.  Its axes T, N, B come by three roads that share
// no step: exact t-derivatives turned into s-derivatives by the chain rule;
// finite differences after relabelling the track by arc length; and the
// Frenet-Serret equations stepped by RK4 from the start of the turn.
type V3 = [f64; 3];
const L: f64 = 15.0; // track scale (m)
const VEL: f64 = 15.0; // train speed (m/s)

fn add(a: V3, b: V3, k: f64) -> V3 { [a[0] + k * b[0], a[1] + k * b[1], a[2] + k * b[2]] }
fn mul(a: V3, k: f64) -> V3 { [k * a[0], k * a[1], k * a[2]] }
fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn size(a: V3) -> f64 { dot(a, a).sqrt() }
fn unit(a: V3) -> V3 { mul(a, 1.0 / size(a)) }
fn f(x: f64, d: i32) -> String {
    let x = if x.abs() < 0.5 * 10f64.powf(-(d as f64)) { 0.0 } else { x };
    format!("{:.*}", d as usize, x)
}
fn vec(a: V3, d: i32) -> String { format!("({}, {}, {})", f(a[0], d), f(a[1], d), f(a[2], d)) }
fn sci(x: f64, d: usize) -> String { // Python's e-format: two-digit exponent with its sign
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_at(s.find('e').unwrap());
    let e: i32 = e[1..].parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn ang(a: V3, b: V3) -> f64 { dot(unit(a), unit(b)).min(1.0).max(-1.0).acos().to_degrees() }
fn dunit(w: V3, wp: V3) -> V3 { // d/dt of w/|w|, for w(t) with derivative wp
    mul(add(mul(wp, dot(w, w)), w, -dot(w, wp)), size(w).powf(-3.0))
}
fn r(t: f64) -> V3 { [L * t, L * t * t / 2.0, L * t.powf(3.0) / 3.0] }
fn speed(t: f64) -> f64 { L * (1.0 + t * t + t.powf(4.0)).sqrt() } // ds/dt
fn exact(t: f64) -> (V3, V3, V3, f64, f64) { // road 1: r' = L(1, t, t^2), r'' = L(0, 1, 2t)
    let (tt, b) = (unit([1.0, t, t * t]), unit([t * t, -2.0 * t, 1.0])); // B along r' x r''
    let q = t.powf(4.0) + 4.0 * t * t + 1.0;
    (tt, cross(b, tt), b, q.sqrt() / (L * (1.0 + t * t + t.powf(4.0)).powf(1.5)), 2.0 / (L * q))
}
fn arc(t: f64) -> f64 { // s(t), metres from the start, by Simpson's rule
    let n = 2000;
    let (h, mut total) = (t / n as f64, speed(0.0) + speed(t));
    for i in 1..n {
        total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * speed(i as f64 * h);
    }
    h / 3.0 * total
}
fn p(s: f64) -> V3 { // the track relabelled by arc length: Newton on s(t) = s
    let mut t = s / L;
    for _ in 0..40 {
        let step = (arc(t) - s) / speed(t);
        t -= step;
        if step.abs() < 1e-14 { break; }
    }
    r(t)
}
fn fd_frame(s: f64, h: f64) -> (V3, V3, V3, f64) { // road 2: differences in s alone
    let (a, b, c) = (p(s - h), p(s), p(s + h));
    let (tt, tp) = (unit(mul(add(c, a, -1.0), 0.5 / h)), mul(add(add(c, b, -2.0), a, 1.0), h.powf(-2.0)));
    let n = unit(tp);
    (tt, n, cross(tt, n), size(tp))
}
fn fd_all(s: f64, h: f64) -> (V3, V3, V3, f64, f64, V3) {
    let (tt, n, b, k) = fd_frame(s, h);
    let (m, pl) = (fd_frame(s - h, h), fd_frame(s + h, h));
    let (bp, np) = (mul(add(pl.2, m.2, -1.0), 0.5 / h), mul(add(pl.1, m.1, -1.0), 0.5 / h));
    (tt, n, b, k, -dot(bp, n), np)
}
type Y = [V3; 4];
fn rhs(t: f64, y: &Y, keep: f64) -> Y {
    let (_, _, _, k, tau) = exact(t);
    let v = speed(t); // d/dt = (ds/dt) d/ds
    [mul(y[1], v), mul(y[2], v * k), mul(add(mul(y[1], -k * keep), y[3], tau), v), mul(y[2], -tau * v)]
}
fn nudge(y: &Y, d: &Y, c: f64) -> Y { [add(y[0], d[0], c), add(y[1], d[1], c), add(y[2], d[2], c), add(y[3], d[3], c)] }
fn ride(t1: f64, n: usize, keep: f64) -> Y { // road 3: RK4 on the Frenet-Serret equations, in t
    let e = exact(0.0);
    let (mut y, h): (Y, f64) = ([[0.0, 0.0, 0.0], e.0, e.1, e.2], t1 / n as f64);
    for i in 0..n {
        let t = i as f64 * h;
        let k1 = rhs(t, &y, keep);
        let k2 = rhs(t + h / 2.0, &nudge(&y, &k1, h / 2.0), keep);
        let k3 = rhs(t + h / 2.0, &nudge(&y, &k2, h / 2.0), keep);
        let k4 = rhs(t + h, &nudge(&y, &k3, h), keep);
        y = nudge(&nudge(&nudge(&nudge(&y, &k1, h / 6.0), &k2, h / 3.0), &k3, h / 3.0), &k4, h / 6.0);
    }
    y
}
fn main() {
    let t1 = 1.0;
    let (tt, n, b, k, tau) = exact(t1);
    let (s1, v1) = (arc(t1), speed(t1));
    let (dtdt, dbdt) = (dunit([1.0, t1, t1 * t1], [0.0, 1.0, 2.0 * t1]), dunit([t1 * t1, -2.0 * t1, 1.0], [2.0 * t1, -2.0, 0.0]));
    let (tp, bp) = (mul(dtdt, 1.0 / v1), mul(dbdt, 1.0 / v1));
    let np = add(mul(tt, -k), b, tau);
    println!("hand point t = 1: position {} m, ds/dt = {} m, arc length from the start s = {} m", vec(r(t1), 4), f(v1, 4), f(s1, 4));
    println!("T = {}, climbing at {} degrees", vec(tt, 4), f(ang(tt, [tt[0], tt[1], 0.0]), 2));
    println!("dT/dt = {}; T' = dT/ds = {} per m", vec(dtdt, 4), vec(tp, 4));
    println!("kappa = |T'| = {} /m, radius 1/kappa = {} m; N = {}", f(size(tp), 4), f(1.0 / size(tp), 2), vec(n, 4));
    println!("B = T x N = {}", vec(b, 4));
    println!("dB/dt = {}; B' = {} per m; tau = -B'.N = {} /m", vec(dbdt, 4), vec(bp, 4), f(-dot(bp, n), 4));
    println!("closed forms: kappa = sqrt(2)/45 = {} /m, tau = 1/45 = {} /m", f(k, 6), f(tau, 6));
    println!("N' = -kappa T + tau B = {} per m", vec(np, 5));
    println!("frame checks: T.N {}, T.B {}, N.B {}, lengths {} {} {}", f(dot(tt, n), 4), f(dot(tt, b), 4), f(dot(n, b), 4),
             f(size(tt), 4), f(size(n), 4), f(size(b), 4));
    let mut errs: Vec<[f64; 3]> = Vec::new();
    for h in [0.4, 0.2] {
        let (t2, _n2, _b2, k2, tau2, np2) = fd_all(s1, h);
        errs.push([(k2 - k).abs(), (tau2 - tau).abs(), size(add(np2, np, -1.0))]);
        let e = errs[errs.len() - 1];
        println!("road 2, arc-length differences, step {} m: kappa {}, tau {}, N' {}", h, f(k2, 6), f(tau2, 6), vec(np2, 5));
        println!("  errors: kappa {}, tau {}, N' {}; T off by {} degrees", sci(e[0], 2), sci(e[1], 2), sci(e[2], 2), sci(ang(t2, tt), 1));
    }
    println!("halving the step cuts the errors by {}, {} and {}", f(errs[0][0] / errs[1][0], 2), f(errs[0][1] / errs[1][1], 2), f(errs[0][2] / errs[1][2], 2));
    let y3 = ride(t1, 200, 1.0);
    let gap = size(add(y3[1], tt, -1.0)).max(size(add(y3[2], n, -1.0))).max(size(add(y3[3], b, -1.0)));
    println!("road 3, RK4 from the start frame, 200 steps: T {}, N {}, B {}", vec(y3[1], 4), vec(y3[2], 4), vec(y3[3], 4));
    println!("  frame misses road 1 by {}; position {} m misses r(1) by {} m", sci(gap, 1), vec(y3[0], 4), sci(size(add(y3[0], r(t1), -1.0)), 1));
    println!("rig at {} m/s: roll about T {} rad/s = {} deg/s; about N 0; about B {} rad/s = {} deg/s", f(VEL, 1),
             f(tau * VEL, 4), f((tau * VEL).to_degrees(), 2), f(k * VEL, 4), f((k * VEL).to_degrees(), 2));
    let spin = VEL * (k * k + tau * tau).sqrt();
    println!("rig total spin V sqrt(kappa^2 + tau^2) = {} rad/s = {} deg/s; push toward N, kappa V^2 = {} m/s^2",
             f(spin, 4), f(spin.to_degrees(), 2), f(k * VEL * VEL, 4));
    for tc in [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5] {
        let e = exact(tc);
        println!("chart, t {}: s {} m, kappa {} /m, tau {} /m", f(tc, 2), f(arc(tc), 2), f(e.3, 4), f(e.4, 4));
    }
    let bad = unit([0.0, 1.0, 2.0 * t1]);
    println!("mistake 1, N along r'': {}; dot with T {}, {} degrees off N", vec(bad, 4), f(dot(bad, tt), 4), f(ang(bad, n), 2));
    println!("mistake 2, |dT/dt| as kappa: {}, radius {} m instead of {} m", f(size(dtdt), 4), f(1.0 / size(dtdt), 2), f(1.0 / k, 2));
    let bflip = cross(n, tt);
    println!("mistake 3, B = N x T: {}; tau = -B'.N comes out {} /m", vec(bflip, 4), f(dot(bp, n), 4));
    let y4 = ride(t1, 200, 0.0);
    println!("mistake 4, N' without -kappa T: at t = 1, T.N = {}, T off by {} degrees", f(dot(y4[1], y4[2]), 4), f(ang(y4[1], tt), 2));
    let c = 1.0 / 450.0; // S-bend y = c x^3: kappa is 0 at x = 0
    let sn = |x: f64| unit(dunit([1.0, 3.0 * c * x * x, 0.0], [0.0, 6.0 * c * x, 0.0])); // N = unit dT/dx
    let (nm, npl) = (sn(-1.0), sn(1.0));
    println!("S-bend y = x^3/450: N at x = -1 m {}, at x = +1 m {}, {} degrees apart", vec(nm, 4), vec(npl, 4), f(ang(nm, npl), 2));
    let o = |q: V3| (70.0 + 8.0 * (q[0] + q[1]) / 2f64.sqrt(), 170.0 - 8.0 * (-q[0] + q[1] + 2.0 * q[2]) / 6f64.sqrt());
    let pts: Vec<String> = (0..16).map(|i| { let z = o(r(i as f64 / 10.0)); format!("{:.1},{:.1}", z.0, z.1) }).collect();
    println!("figure, track: {}", pts.join(" "));
    for tf in [0.0, 1.0] {
        let (e, base) = (exact(tf), o(r(tf)));
        let tips: Vec<String> = [e.0, e.1, e.2].iter().map(|&a| { let z = o(add(r(tf), a, 6.0)); format!("{:.1},{:.1}", z.0, z.1) }).collect();
        println!("figure, frame at t {}: base {:.1},{:.1}; T N B tips {}", f(tf, 1), base.0, base.1, tips.join(" "));
    }
    assert!((k - 2f64.sqrt() / 45.0).abs() < 1e-12 && (tau - 1.0 / 45.0).abs() < 1e-12); // hand values
    assert!((size(tp) - k).abs() < 1e-12 && (-dot(bp, n) - tau).abs() < 1e-12); // chain rule = closed form
    assert!(errs[1][0] < 1e-5 && errs[1][1] < 1e-5 && errs[1][2] < 1e-5); // road 2 agrees
    assert!((0..3).all(|j| 3.5 < errs[0][j] / errs[1][j] && errs[0][j] / errs[1][j] < 4.5)); // error falls as h^2
    assert!(gap < 1e-8 && size(add(y3[0], r(t1), -1.0)) < 1e-6); // road 3 agrees
    assert!(dot(y4[1], y4[2]).abs() > 0.01 && ang(nm, npl) > 179.9); // the failures show
    println!("ALL CHECKS PASS");
}
