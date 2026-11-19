// Lie algebra and the exponential map -- the same check as the Python, in Rust.
// No crates.  A drone's gyro reads a steady body turn rate w (rad/s); held for
// t = 1 s it becomes a finished turn R = exp(t [w]x).  R is reached by three
// roads: the power series, Rodrigues' closed form, and many small steps.
// Then brackets: by matrix products, by the cross product, and by a gimbal loop.
use std::f64::consts::PI;
type M = [[f64; 3]; 3];
type V = [f64; 3];
const I3: M = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];

fn mul(a: &M, b: &M) -> M {
    let mut z = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { for k in 0..3 { z[i][j] += a[i][k] * b[k][j] } } }
    z
}
fn lin(a: &M, b: &M, s: f64) -> M {                 // a + s b
    let mut z = *a;
    for i in 0..3 { for j in 0..3 { z[i][j] += s * b[i][j] } }
    z
}
fn sc(a: &M, s: f64) -> M { lin(&[[0.0; 3]; 3], a, s) }
fn tr(a: &M) -> M { let mut z = *a; for i in 0..3 { for j in 0..3 { z[i][j] = a[j][i] } } z }
fn hat(w: V) -> M { [[0.0, -w[2], w[1]], [w[2], 0.0, -w[0]], [-w[1], w[0], 0.0]] }   // [w]x
fn vee(a: &M) -> V { [a[2][1], a[0][2], a[1][0]] }                                  // undoes hat
fn gap(a: &M, b: &M) -> f64 { let mut g: f64 = 0.0; for i in 0..3 { for j in 0..3 { g = g.max((a[i][j] - b[i][j]).abs()) } } g }
fn br(x: &M, y: &M) -> M { lin(&mul(x, y), &mul(y, x), -1.0) }                     // [X, Y] = XY - YX
fn det(a: &M) -> f64 {
    a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
        + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0])
}
fn angle(r: &M) -> f64 { ((r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0).max(-1.0).min(1.0).acos() }   // from the trace
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn app(a: &M, v: V) -> V { let mut z = [0.0; 3]; for i in 0..3 { for j in 0..3 { z[i] += a[i][j] * v[j] } } z }
fn norm(v: V) -> f64 { (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt() }

fn expm(x: &M) -> M {                               // road 1: I + X + X^2/2! + ... term by term
    let (mut s, mut term) = (I3, I3);
    for k in 1..40 {
        term = sc(&mul(&term, x), 1.0 / k as f64);
        s = lin(&s, &term, 1.0);
    }
    s
}
fn rodrigues(w: V, t: f64) -> M {                   // road 2: I + sin(th) K + (1 - cos(th)) K^2
    let th = norm(w) * t;
    let k = hat([w[0] * t / th, w[1] * t / th, w[2] * t / th]);
    lin(&lin(&I3, &k, th.sin()), &mul(&k, &k), 1.0 - th.cos())
}
fn steps(x: &M, n: usize) -> M {                    // road 3: n small gyro updates R <- R (I + X/n)
    let (mut r, s) = (I3, lin(&I3, x, 1.0 / n as f64));
    for _ in 0..n { r = mul(&r, &s) }
    r
}
fn loop_c(e: f64) -> M {                            // pitch e, yaw e, pitch back, yaw back
    let (ly, lz) = (hat([0.0, 1.0, 0.0]), hat([0.0, 0.0, 1.0]));
    mul(&mul(&expm(&sc(&ly, e)), &expm(&sc(&lz, e))), &mul(&expm(&sc(&ly, -e)), &expm(&sc(&lz, -e))))
}

fn f(x: f64) -> f64 { if x.abs() < 5e-13 { 0.0 } else { x } }
fn fv(v: V) -> String { format!("({:.6}, {:.6}, {:.6})", f(v[0]), f(v[1]), f(v[2])) }
fn fm(a: &M) -> String { format!("[{}]", a.iter().map(|r| format!("[{:.6}, {:.6}, {:.6}]", f(r[0]), f(r[1]), f(r[2]))).collect::<Vec<_>>().join(", ")) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let (w, t): (V, f64) = ([0.3, 0.4, 1.2], 1.0);
    let wm = hat(w);
    let th = norm(w) * t;
    let axis = [w[0] / th, w[1] / th, w[2] / th];
    let (r, rr) = (expm(&wm), rodrigues(w, t));
    let (e1000, e2000) = (steps(&wm, 1000), steps(&wm, 2000));
    println!("rate w = (0.3, 0.4, 1.2) rad/s held {:.0} s: angle {:.6} rad = {:.6} deg, axis {}", t, th, th.to_degrees(), fv(axis));
    println!("[w]x = {}", fm(&wm));
    println!("road 1, series:    R = {}", fm(&r));
    println!("road 2, Rodrigues: R = {}; agree to 1e-12: {}", fm(&rr), yn(gap(&r, &rr) < 1e-12));
    println!("by hand: sin(1.3) = {:.6}, 1 - cos(1.3) = {:.6}; K^2 entry (2, 1) = {:.6}; entry (2, 1) = {:.6} + {:.6} = {:.6}", th.sin(), 1.0 - th.cos(),
             axis[1] * axis[0], th.sin() * axis[2], (1.0 - th.cos()) * axis[0] * axis[1], th.sin() * axis[2] + (1.0 - th.cos()) * axis[0] * axis[1]);
    println!("road 3, 1000 steps: off by {:.6}, det {:.6}", gap(&e1000, &r), det(&e1000));
    println!("road 3, 2000 steps: off by {:.6}, det {:.6}; error ratio {:.2}", gap(&e2000, &r), det(&e2000), gap(&e1000, &r) / gap(&e2000, &r));
    println!("R^T R - I largest entry {:.6}; det R = {:.6}", gap(&mul(&tr(&r), &r), &I3), det(&r));
    println!("R times the axis = {}; [w]x times the axis = {}", fv(app(&r, axis)), fv(app(&wm, axis)));
    println!("trace R = {:.6} = 1 + 2 cos(1.3); angle back from the trace {:.6} rad", r[0][0] + r[1][1] + r[2][2], angle(&r));
    let half = mul(&expm(&sc(&wm, 0.4)), &expm(&sc(&wm, 0.6)));
    println!("e^(0.4 [w]x) e^(0.6 [w]x) equals e^([w]x): {}", yn(gap(&half, &r) < 1e-12));
    let dq: Vec<f64> = [0.01, 0.005].iter().map(|&h| gap(&sc(&lin(&expm(&sc(&wm, h)), &I3, -1.0), 1.0 / h), &wm)).collect();
    println!("tangent at I: (R(h) - I)/h minus [w]x, h = 0.01: {:.6}, h = 0.005: {:.6}; ratio {:.2}", dq[0], dq[1], dq[0] / dq[1]);
    let times: Vec<f64> = (0..11).map(|k| 0.1 * k as f64).collect();
    let noses: Vec<V> = times.iter().map(|&s| app(&expm(&sc(&wm, s)), [1.0, 0.0, 0.0])).collect();
    println!("nose, t (s)  {}", times.iter().map(|s| format!("{:6.1}", s)).collect::<Vec<_>>().join(" "));
    for (i, name) in ["x", "y", "z"].iter().enumerate() {
        println!("nose, {}      {}", name, noses.iter().map(|n| format!("{:6.3}", f(n[i]))).collect::<Vec<_>>().join(" "));
    }

    let (lx, ly, lz) = (hat([1.0, 0.0, 0.0]), hat([0.0, 1.0, 0.0]), hat([0.0, 0.0, 1.0]));
    println!("[Lx, Ly] = Lz: {}; [Ly, Lz] = Lx: {}; [Lz, Lx] = Ly: {}", yn(gap(&br(&lx, &ly), &lz) == 0.0), yn(gap(&br(&ly, &lz), &lx) == 0.0), yn(gap(&br(&lz, &lx), &ly) == 0.0));
    println!("[Ly, Lz] = {}", fm(&br(&ly, &lz)));
    let g: V = [0.0, 0.5, 0.0];                     // the gimbal's pitch rate, rad/s
    let b = br(&wm, &hat(g));
    println!("[[w]x, [g]x] for g = (0.0, 0.5, 0.0): vector {}; w x g = {}; skew: {}", fv(vee(&b)), fv(cross(w, g)), yn(gap(&tr(&b), &sc(&b, -1.0)) == 0.0));
    let mut lp: Vec<(f64, f64)> = Vec::new();
    for e in [0.1_f64, 0.05] {
        let c = loop_c(e);
        let v = vee(&lin(&c, &tr(&c), -1.0));
        let n = norm(v);
        lp.push((angle(&c), gap(&sc(&lin(&c, &I3, -1.0), 1.0 / (e * e)), &lx)));
        println!("gimbal loop eps = {} rad = {:.6} deg: net turn {:.6} rad = {:.6} deg about {}; (C - I)/eps^2 minus Lx: {:.6}",
                 e, e.to_degrees(), angle(&c), angle(&c).to_degrees(), fv([v[0] / n, v[1] / n, v[2] / n]), lp[lp.len() - 1].1);
    }
    println!("gimbal loop error ratio {:.2}", lp[0].1 / lp[1].1);

    let mut ee = wm;
    for i in 0..3 { for j in 0..3 { ee[i][j] = wm[i][j].exp() } }
    let seq = mul(&mul(&expm(&sc(&lx, 0.3)), &expm(&sc(&ly, 0.4))), &expm(&sc(&lz, 1.2)));
    let e100 = steps(&wm, 100);
    let r3 = expm(&sc(&wm, 3.0));
    let bch = gap(&mul(&expm(&sc(&ly, 0.1)), &expm(&sc(&lz, 0.1))), &expm(&sc(&lin(&ly, &lz, 1.0), 0.1)));
    let off = angle(&mul(&tr(&r), &seq));
    println!("mistake, e of each entry: det {:.6}, R^T R - I largest entry {:.6}", det(&ee), gap(&mul(&tr(&ee), &ee), &I3));
    println!("mistake, roll 0.3 then pitch 0.4 then yaw 1.2: off by {:.6} rad = {:.6} deg", off, off.to_degrees());
    let u: V = [0.8, -0.6, 0.0];                    // a unit vector at right angles to the axis
    println!("mistake, 100 plain steps: det {:.6}; a unit vector at right angles to the axis ends {:.6} long", det(&e100), norm(app(&e100, u)));
    println!("mistake, angle from the trace after 3 s: {:.6} rad, not {:.6}; 2 pi - 3.9 = {:.6}", angle(&r3), 3.0 * th, 2.0 * PI - 3.0 * th);
    println!("mistake, e^(0.1 Ly) e^(0.1 Lz) against e^(0.1 (Ly + Lz)): gap {:.6}", bch);
    let back = expm(&sc(&wm, 2.0 * PI / th));
    println!("try, hold for 2 pi / 1.3 = {:.6} s: gap from I {:.6}", 2.0 * PI / th, gap(&back, &I3));
    println!("try, gimbal loop eps = 0.2: net turn {:.6} rad; w x (0, 0, 0.5) = {}", angle(&loop_c(0.2)), fv(cross(w, [0.0, 0.0, 0.5])));

    assert!(gap(&r, &rr) < 1e-12);                                         // series = Rodrigues
    assert!(gap(&mul(&tr(&r), &r), &I3) < 1e-12 && (det(&r) - 1.0).abs() < 1e-12);   // a rotation
    assert!((angle(&r) - 1.3).abs() < 1e-12 && (angle(&r3) - (2.0 * PI - 3.9)).abs() < 1e-12);
    let ratio = gap(&e1000, &r) / gap(&e2000, &r);
    assert!(1.95 < ratio && ratio < 2.05);                                 // steps converge, first order
    assert!(gap(&half, &r) < 1e-12);                                       // one-parameter subgroup
    assert!(1.95 < dq[0] / dq[1] && dq[0] / dq[1] < 2.05);                 // tangent at I is [w]x
    assert!(gap(&br(&ly, &lz), &lx) < 1e-15 && gap(&b, &hat(cross(w, g))) < 1e-15);
    assert!(1.95 < lp[0].1 / lp[1].1 && lp[0].1 / lp[1].1 < 2.05 && (lp[0].0 - 0.01).abs() < 1e-4);
    println!("ALL CHECKS PASS");
}
