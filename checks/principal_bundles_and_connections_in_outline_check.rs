// Principal bundle and connection -- the same check as the Python, in Rust.  No crates.
// Part 1, the circle group SO(2) at every point of the globe: a survey drone flies a
// latitude-longitude box; its gyro-held camera frame comes back turned against the compass.
// The turn is found four ways: the line integral of A in two gauges, the area integral
// of F = dA, and a gauge-free carry of the frame in 3D.  Part 2, the group SO(3): a gimbal
// whose connection has dA = 0, so all of its curvature F = dA + A^A is the bracket term.
use std::f64::consts::PI;
type V = [f64; 3];
type M = [[f64; 3]; 3];
const R: f64 = 6371.0; // Earth radius, km (a sphere: a model)

fn f(x: f64) -> f64 { if x.abs() < 5e-9 { 0.0 } else { x } }
fn a_sph(ph: f64, _th: f64, grid: bool, c: f64) -> (f64, f64) { (0.0, -ph.cos() + if grid { c } else { 0.0 }) }
fn legs(n: usize, p1: f64, p2: f64, t0: f64, t1: f64) -> Vec<(f64, f64)> {
    let k = |i: usize| i as f64 / n as f64;
    let mut v = Vec::new();
    for i in 0..n { v.push((p2, t0 + (t1 - t0) * k(i))) }
    for i in 0..n { v.push((p2 - (p2 - p1) * k(i), t1)) }
    for i in 0..n { v.push((p1, t1 - (t1 - t0) * k(i))) }
    for i in 0..n { v.push((p1 + (p2 - p1) * k(i), t0)) }
    v.push((p2, t0));
    v
}
fn line(grid: bool, c: f64, pts: &[(f64, f64)]) -> Vec<f64> { // road 1: integral of A, midpoint rule
    let mut out = vec![0.0];
    for w in pts.windows(2) {
        let ((a, b), (u, v)) = (w[0], w[1]);
        let (ap, at) = a_sph((a + u) / 2.0, (b + v) / 2.0, grid, c);
        let last = out[out.len() - 1];
        out.push(last + ap * (u - a) + at * (v - b));
    }
    out
}
fn area_f(n: usize, pa: f64, pb: f64, ta: f64, tb: f64) -> f64 { // road 2: F = sin(phi) dphi^dtheta
    let (hp, ht) = ((pb - pa) / n as f64, (tb - ta) / n as f64);
    let mut s = 0.0;
    for i in 0..n { for _j in 0..n { s += (pa + (i as f64 + 0.5) * hp).sin() * hp * ht } }
    s
}
fn cap_f(n: usize, pb: f64) -> f64 { (0..n).map(|i| ((i as f64 + 0.5) * pb / n as f64).sin() * pb / n as f64).sum::<f64>() * 2.0 * PI }
fn xyz(ph: f64, th: f64) -> V { [ph.sin() * th.cos(), ph.sin() * th.sin(), ph.cos()] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn unit(a: V) -> V { let n = dot(a, a).sqrt(); [a[0] / n, a[1] / n, a[2] / n] }
fn turn(v: V, n: V, t: f64) -> V {
    let (cv, d) = (cross(n, v), dot(n, v));
    [0, 1, 2].map(|i| v[i] * t.cos() + cv[i] * t.sin() + n[i] * d * (1.0 - t.cos()))
}
fn carry(n: usize, p1: f64, p2: f64, t0: f64, t1: f64) -> f64 { // road 3: gyro frame carried in 3D
    let pts: Vec<V> = legs(n, p1, p2, t0, t1).iter().map(|&(a, b)| xyz(a, b)).collect();
    let north = [-p2.cos() * t0.cos(), -p2.cos() * t0.sin(), p2.sin()];
    let mut v = north;
    for w in pts.windows(2) { v = turn(v, unit(cross(w[0], w[1])), dot(w[0], w[1]).min(1.0).acos()) }
    dot(cross(north, v), pts[0]).atan2(dot(north, v))
}
const I3: M = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
fn mul(a: &M, b: &M) -> M { let mut z = [[0.0; 3]; 3]; for i in 0..3 { for j in 0..3 { for k in 0..3 { z[i][j] += a[i][k] * b[k][j] } } } z }
fn lin(a: &M, b: &M, s: f64) -> M { let mut z = *a; for i in 0..3 { for j in 0..3 { z[i][j] += s * b[i][j] } } z }
fn sm(a: &M, s: f64) -> M { lin(&[[0.0; 3]; 3], a, s) }
fn tr(a: &M) -> M { let mut z = *a; for i in 0..3 { for j in 0..3 { z[i][j] = a[j][i] } } z }
fn hat(w: V) -> M { [[0.0, -w[2], w[1]], [w[2], 0.0, -w[0]], [-w[1], w[0], 0.0]] }
fn vee(m: &M) -> V { [m[2][1], m[0][2], m[1][0]] }
fn br(x: &M, y: &M) -> M { lin(&mul(x, y), &mul(y, x), -1.0) }
fn gap(a: &M, b: &M) -> f64 { let mut g: f64 = 0.0; for i in 0..3 { for j in 0..3 { g = g.max((a[i][j] - b[i][j]).abs()) } } g }
fn ang(r: &M) -> f64 { ((r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0).max(-1.0).min(1.0).acos() }
fn expm(x: &M) -> M { let (mut s, mut t) = (I3, I3); for k in 1..40 { t = sm(&mul(&t, x), 1.0 / k as f64); s = lin(&s, &t, 1.0) } s }
fn fv(v: V) -> String { format!("({:.6}, {:.6}, {:.6})", f(v[0]), f(v[1]), f(v[2])) }
fn square(ax: &M, ay: &M, h: f64) -> M {
    mul(&mul(&expm(&sm(ax, h)), &expm(&sm(ay, h))), &mul(&expm(&sm(ax, -h)), &expm(&sm(ay, -h))))
}
fn ap(ax: &M, ay: &M, lz: &M, b: f64, x: f64, y: f64) -> (M, M) { // g^-1 A g + g^-1 dg, g = exp(b x y Lz)
    let g = expm(&sm(lz, b * x * y));
    let gi = tr(&g);
    (lin(&mul(&mul(&gi, ax), &g), lz, b * y), lin(&mul(&mul(&gi, ay), &g), lz, b * x))
}

fn main() {
    let (p1, p2, t0, t1) = (30f64.to_radians(), 40f64.to_radians(), (-30f64).to_radians(), 0.0);
    let c = 55f64.to_radians().sin();
    let d = t1 - t0;
    let exact = d * (p1.cos() - p2.cos());
    println!("box 50N-60N, 30W-0: legs {:.1}, {:.1}, {:.1}, {:.1} km; area {:.0} km^2", R * p2.sin() * d, R * (p2 - p1), R * p1.sin() * d, R * (p2 - p1), R * R * exact);
    let (pm, tm) = ((p1 + p2) / 2.0, (t0 + t1) / 2.0);
    println!("A_theta at the box centre 55N: compass gauge {:.6}, grid gauge {:.6}", a_sph(pm, tm, false, c).1, f(a_sph(pm, tm, true, c).1));
    let pts = legs(400, p1, p2, t0, t1);
    let (sc, sg) = (line(false, c, &pts), line(true, c, &pts));
    for (name, s) in [("compass", &sc), ("grid", &sg)] {
        println!("{:7} gauge, integral of A by leg: {:.6}, {:.6}, {:.6}, {:.6}; total {:.6} rad", name, s[400], s[800] - s[400], s[1200] - s[800], s[1600] - s[1200], s[1600]);
    }
    println!("closed form d theta (cos 30 - cos 40) = {:.6} rad = {:.6} deg", exact, exact.to_degrees());
    println!("by hand: d theta {:.6} rad, cos 30 deg {:.6}, cos 40 deg {:.6}, c = sin 55 deg {:.6}, K = {:.6}e-8 per km^2; camera heading {:.3} deg", d, p1.cos(), p2.cos(), c, 1e8 / (R * R), 360.0 - exact.to_degrees());
    let (f20, f40) = (area_f(20, p1, p2, t0, t1), area_f(40, p1, p2, t0, t1));
    println!("area integral of F: 20x20 grid {:.9}, 40x40 {:.9}; error ratio {:.2}", f20, f40, (f20 - exact) / (f40 - exact));
    let (c50, c100) = (carry(50, p1, p2, t0, t1), carry(100, p1, p2, t0, t1));
    println!("3D carry: 50 steps a leg {:.9}, 100 steps {:.9}; error ratio {:.2}", c50, c100, (c50 - exact) / (c100 - exact));
    let e = 1e-5;
    let fd: Vec<f64> = [false, true].iter().map(|&g| (a_sph(pm + e, tm, g, c).1 - a_sph(pm - e, tm, g, c).1 - a_sph(pm, tm + e, g, c).0 + a_sph(pm, tm - e, g, c).0) / (2.0 * e)).collect();
    println!("F at the centre by differences: compass {:.6}, grid {:.6}; sin 35 deg = {:.6}", fd[0], fd[1], pm.sin());
    let mut km = vec![0.0];
    for w in pts.windows(2) {
        let ((a, b), (u, v)) = (w[0], w[1]);
        let last = km[km.len() - 1];
        km.push(last + R * ((u - a).powi(2) + (((a + u) / 2.0).sin() * (v - b)).powi(2)).sqrt());
    }
    let idx: Vec<usize> = (0..=1600).step_by(200).collect();
    println!("chart, km     {}", idx.iter().map(|&i| format!("{:6.0}", km[i])).collect::<Vec<_>>().join(" "));
    println!("chart, compass{}", idx.iter().map(|&i| format!("{:7.2}", sc[i].to_degrees())).collect::<Vec<_>>().join(" "));
    println!("chart, grid   {}", idx.iter().map(|&i| format!("{:7.2}", sg[i].to_degrees())).collect::<Vec<_>>().join(" "));
    let q = 1f64.to_radians();
    let (cap_line, cap_area) = (-2.0 * PI * q.cos(), cap_f(1000, q));
    println!("loop at 89N: integral of A (compass) {:.6} deg; area integral of F {:.6} deg; gap {:.6}", cap_line.to_degrees(), cap_area.to_degrees(), (cap_line - cap_area).to_degrees());
    let whole = cap_f(2000, PI);
    println!("whole sphere: integral of F = {:.6} = {:.6} turns", whole, whole / (2.0 * PI));

    let (ly, lz, a) = (hat([0.0, 1.0, 0.0]), hat([0.0, 0.0, 1.0]), 0.1);
    let (ax, ay) = (sm(&ly, a), sm(&lz, a)); // stick east pitches, stick north yaws, 0.1 rad per unit
    let fm = br(&ax, &ay); // dA = 0 here, so F = [A_x, A_y]
    println!("gimbal: A_x = 0.1 Ly, A_y = 0.1 Lz; dA = 0; F_xy = [A_x, A_y] = {} (a roll)", fv(vee(&fm)));
    let mut gs = Vec::new();
    for h in [1.0f64, 0.5] {
        let cc = square(&ax, &ay, h);
        gs.push(gap(&sm(&lin(&cc, &I3, -1.0), 1.0 / (h * h)), &fm));
        println!("square of side {:.1}: holonomy turn {:.6} rad = {:.6} deg; I + h^2 F predicts {:.6}; (H - I)/h^2 - F {:.6}", h, ang(&cc), ang(&cc).to_degrees(), h * h * a * a, gs[gs.len() - 1]);
    }
    println!("error ratio {:.2}", gs[0] / gs[1]);
    let b = 0.5; // gauge change g = exp(0.5 x y Lz)
    let (x0, y0) = (0.5, 0.5);
    let apf = |x: f64, y: f64| ap(&ax, &ay, &lz, b, x, y);
    let dap = sm(&lin(&lin(&apf(x0 + e, y0).1, &apf(x0 - e, y0).1, -1.0), &lin(&apf(x0, y0 + e).0, &apf(x0, y0 - e).0, -1.0), -1.0), 1.0 / (2.0 * e));
    let (a0x, a0y) = apf(x0, y0);
    let aap = br(&a0x, &a0y);
    let fp = lin(&dap, &aap, 1.0);
    let g0 = expm(&sm(&lz, b * x0 * y0));
    let gfg = mul(&mul(&tr(&g0), &fm), &g0);
    let fpv = vee(&fp);
    println!("new gauge at (0.5, 0.5): A'_y = {}; dA' part {}, A'^A' part {}", fv(vee(&a0y)), fv(vee(&dap)), fv(vee(&aap)));
    println!("F' = {}; g^-1 F g = {}; size {:.6}", fv(fpv), fv(vee(&gfg)), dot(fpv, fpv).sqrt());
    let stepped = |n: usize| -> M { // holonomy in the new gauge, path-ordered, midpoint steps
        let (mut hm, h) = (I3, 1.0 / n as f64);
        for (dx, dy, x, y) in [(1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 1.0, 0.0), (-1.0, 0.0, 1.0, 1.0), (0.0, -1.0, 0.0, 1.0)] {
            for k in 0..n {
                let (bx, by) = apf(x + dx * (k as f64 + 0.5) * h, y + dy * (k as f64 + 0.5) * h);
                hm = mul(&hm, &expm(&lin(&sm(&bx, dx * h), &by, dy * h)));
            }
        }
        hm
    };
    let c1 = square(&ax, &ay, 1.0);
    let (h50, h100) = (stepped(50), stepped(100));
    println!("new gauge, stepped holonomy: 50 steps a side off by {:.9}, 100 off by {:.9}; ratio {:.2}; turn {:.6} rad", gap(&h50, &c1), gap(&h100, &c1), gap(&h50, &c1) / gap(&h100, &c1), ang(&h100));
    let big = square(&ax, &ay, 10.0);
    println!("mistake, drop A^A: predicted roll 0.000000 rad; real {:.6} rad", ang(&c1));
    println!("mistake, exp(area x F) on a 10 x 10 square: {:.4} deg; real holonomy {:.4} deg", ang(&expm(&sm(&fm, 100.0))).to_degrees(), ang(&big).to_degrees());
    println!("try, a = 0.2: square of side 1 turns {:.6} rad", ang(&square(&sm(&ly, 0.2), &sm(&lz, 0.2), 1.0)));
    println!("try, box 0N-10N: {:.6} deg; box 60 deg wide: {:.6} deg", (d * (80f64.to_radians().cos() - 90f64.to_radians().cos())).to_degrees(), (2.0 * exact).to_degrees());

    assert!((sc[1600] - exact).abs() < 1e-6 && (sg[1600] - exact).abs() < 1e-6);
    let r2 = (f20 - exact) / (f40 - exact);
    assert!(3.9 < r2 && r2 < 4.1 && (f40 - exact).abs() < 1e-5); // Stokes, by area
    let r3 = (c50 - exact) / (c100 - exact);
    assert!(3.9 < r3 && r3 < 4.1 && (c100 - exact).abs() < 1e-6); // gauge-free carry
    assert!((fd[0] - pm.sin()).abs() < 1e-8 && (fd[1] - pm.sin()).abs() < 1e-8 && a_sph(pm, tm, true, c).1.abs() < 1e-12); // grid A = 0 at 55N
    assert!(((cap_line - cap_area).abs() - 2.0 * PI).abs() < 1e-6 && (whole - 4.0 * PI).abs() < 1e-5);
    assert!(1.95 < gs[0] / gs[1] && gs[0] / gs[1] < 2.05 && (ang(&c1) - 0.01).abs() < 1e-4); // holonomy -> I + h^2 F
    assert!(gap(&fp, &gfg) < 1e-8 && gap(&h100, &c1) < 1e-5);
    println!("ALL CHECKS PASS");
}
