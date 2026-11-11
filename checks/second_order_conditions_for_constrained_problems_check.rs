// Second-order conditions on a pipe's capacity surface, checked five ways.
// No crates.  Maximise the power a water main delivers, P = C*q*H, written
// as minimising f0 = -P, subject to f1 = H + R*q^2 - RATING <= 0.
const C: f64 = 0.00981; // kW per (L/s * m): water weighs 9.81 kN per m^3, 1 L/s = 0.001 m^3/s
const R: f64 = 0.000125; // m of friction head per (L/s)^2: 20 m lost at 400 L/s
const RATING: f64 = 60.0; // m of head the main is rated for at the pump end
type M2 = [[f64; 2]; 2];

fn power(q: f64, h: f64) -> f64 { C * q * h }
fn f0(q: f64, h: f64) -> f64 { -power(q, h) }
fn f1(q: f64, h: f64) -> f64 { h + R * q * q - RATING }
fn grad_f0(q: f64, h: f64) -> [f64; 2] { [-C * h, -C * q] }
fn grad_f1(q: f64, _h: f64, r: f64) -> [f64; 2] { [2.0 * r * q, 1.0] }
fn hess_f0() -> M2 { [[0.0, -C], [-C, 0.0]] }
fn hess_f1(r: f64) -> M2 { [[2.0 * r, 0.0], [0.0, 0.0]] }
fn add(a: M2, b: M2, s: f64) -> M2 {
    let mut m = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { m[i][j] = a[i][j] + s * b[i][j] } }
    m
}
fn quad(m: M2, d: [f64; 2]) -> f64 {
    let mut s = 0.0;
    for i in 0..2 { for j in 0..2 { s += d[i] * m[i][j] * d[j] } }
    s
}
fn dot(u: [f64; 2], v: [f64; 2]) -> f64 { u[0] * v[0] + u[1] * v[1] }
fn eig2(m: M2) -> (f64, f64) { // eigenvalues of a symmetric 2x2 matrix, smallest first
    let c = (m[0][0] + m[1][1]) / 2.0;
    let s = ((m[0][0] - m[1][1]) * (m[0][0] - m[1][1]) / 4.0 + m[0][1] * m[0][1]).sqrt();
    (c - s, c + s)
}
fn on_surface(q: f64, r: f64, rating: f64) -> f64 { rating - r * q * q } // H on the surface
fn best(r: f64, rating: f64) -> (f64, f64) { // dP/dq along the surface = C*(rating - 3*r*q^2) = 0
    let q = (rating / (3.0 * r)).sqrt();
    (q, on_surface(q, r, rating))
}
fn tangent(q: f64, r: f64) -> [f64; 2] { // a step of 10 L/s that keeps f1 = 0 to first order
    let g = grad_f1(q, 0.0, r);
    [10.0, -10.0 * g[0] / g[1]]
}
fn f(x: f64, n: usize) -> String { format!("{:.*}", n, x) }

fn main() {
    // ---- road 1: KKT, then the critical cone and the Lagrangian's curvature on it ----
    let (q, h) = best(R, RATING);
    let (g0, g1) = (grad_f0(q, h), grad_f1(q, h, R));
    let lam = -g0[1] / g1[1]; // the H-row of grad f0 + lam * grad f1 = 0
    let res = [g0[0] + lam * g1[0], g0[1] + lam * g1[1]];
    let w = add(hess_f0(), hess_f1(R), lam); // Hessian of the Lagrangian f0 + lam*f1
    let d = tangent(q, R);
    let (part_f0, part_bend) = (quad(hess_f0(), d), lam * quad(hess_f1(R), d));
    let along = quad(w, d);
    println!("maximise P = {:.5}*q*H kW subject to H + {:.6}*q^2 <= {:.0} m", C, R, RATING);
    println!("x* = ({} L/s, {} m), friction {} m, P = {} kW", f(q, 1), f(h, 4), f(R * q * q, 4), f(power(q, h), 4));
    println!("grad f0 = ({}, {}), grad f1 = ({}, {})", f(g0[0], 4), f(g0[1], 4), f(g1[0], 4), f(g1[1], 4));
    println!("lambda = {} kW per m of rating; KKT residual {}, {}", f(lam, 4), f(res[0].abs(), 6), f(res[1].abs(), 6));
    let (hh, mut worst) = (1e-3, 0.0f64); // derivatives against central differences
    let fns: [(fn(f64, f64) -> f64, [f64; 2]); 2] = [(f0, g0), (f1, g1)];
    for (func, gr) in fns.iter() {
        let nd = [(func(q + hh, h) - func(q - hh, h)) / (2.0 * hh), (func(q, h + hh) - func(q, h - hh)) / (2.0 * hh)];
        worst = worst.max((nd[0] - gr[0]).abs()).max((nd[1] - gr[1]).abs());
    }
    println!("gradients against central differences: largest gap {:.1e}", worst);
    println!("Hessian of the Lagrangian: {}, {} / {}, {}", f(w[0][0], 6), f(w[0][1], 6), f(w[1][0], 6), f(w[1][1], 6));
    println!("critical cone: lambda > 0, so 0.1*dq + dH = 0: d = ({}, {})", f(d[0], 1), f(d[1], 1));
    println!("along the surface d'Wd = {} (cost) + {} (bend) = {} kW", f(part_f0, 4), f(part_bend, 4), f(along, 4));
    let (out, inn) = ([10.0, 1.0], [-10.0, -1.0]);
    println!("across, outward (10, 1): d'Wd = {}, pump-end head +{} m: not allowed", f(quad(w, out), 4), f(dot(g1, out), 4));
    println!("across, inward (-10, -1): d'Wd = {}, P falls {} kW at first order", f(quad(w, inn), 4), f(dot(g0, inn), 4));
    // ---- road 2: walk along the surface itself and take a second difference ----
    let fs: Vec<f64> = [q - 10.0, q, q + 10.0].iter().map(|&x| f0(x, on_surface(x, R, RATING))).collect();
    let second = fs[0] - 2.0 * fs[1] + fs[2];
    println!("road 2, second difference of f0 along the surface: {} kW", f(second, 4));
    let acc = [0.0, -2.0 * R * d[0] * d[0]]; // the path H = 60 - R*q^2 bends by this much
    println!("bend: path acceleration (0, {}) m; grad f0 . a = {} = lambda * d'(Hess f1)d = {}",
             f(acc[1], 3), f(dot(g0, acc), 4), f(part_bend, 4));
    for step in [10.0, 50.0] {
        let loss = power(q, h) - power(q + step, on_surface(q + step, R, RATING));
        println!("slide {} L/s along: true power loss {} kW, quadratic model {} kW",
                 f(step, 0), f(loss, 4), f(0.5 * along * (step / 10.0) * (step / 10.0), 4));
    }
    // ---- road 3: the bordered Hessian, a determinant that needs no tangent ----
    let b = [[0.0, g1[0], g1[1]], [g1[0], w[0][0], w[0][1]], [g1[1], w[1][0], w[1][1]]];
    let det = b[0][0] * (b[1][1] * b[2][2] - b[1][2] * b[2][1]) - b[0][1] * (b[1][0] * b[2][2] - b[1][2] * b[2][0])
        + b[0][2] * (b[1][0] * b[2][1] - b[1][1] * b[2][0]);
    println!("road 3, bordered Hessian determinant {} (negative: a strict minimum of f0)", f(det, 6));
    // ---- road 4: every feasible point on a 1 L/s by 0.1 m grid ----
    let (mut top, mut arg, mut n) = (-1.0, (0.0, 0.0), 0);
    for i in 0..701 {
        for j in 0..601 {
            let (qq, hq) = (i as f64, j as f64 / 10.0);
            if f1(qq, hq) <= 1e-9 {
                n += 1;
                if power(qq, hq) > top { top = power(qq, hq); arg = (qq, hq); }
            }
        }
    }
    println!("road 4, {} feasible grid points: best ({}, {}), P = {} kW", n, f(arg.0, 0), f(arg.1, 1), f(top, 4));
    println!("drop q, H >= 0: q = H = -1000 gives f1 = {} m, P = {} kW", f(f1(-1000.0, -1000.0), 1), f(power(-1000.0, -1000.0), 2));
    // ---- road 5: lambda read back as a price, by moving the rating ----
    let pr: Vec<f64> = [-1.0, 1.0].iter().map(|s| { let (a, c) = best(R, RATING + s); power(a, c) }).collect();
    let price = (pr[1] - pr[0]) / 2.0;
    println!("road 5, (P*(61 m) - P*(59 m)) / 2 = {} kW per m", f(price, 5));
    // ---- what breaks ----
    let (e0, ew) = (eig2(hess_f0()), eig2(w));
    println!("mistake 1, Hessian of f0 alone, every direction: {}, {} -> 'saddle'", f(e0.0, 6), f(e0.1, 6));
    println!("mistake 2, Lagrangian Hessian, every direction: {}, {} -> 'no minimum'", f(ew.0, 6), f(ew.1, 6));
    println!("mistake 3, bend dropped: along-surface curvature {}, model loss {} kW; lambda's sign flipped {}",
             f(part_f0, 4), f(part_f0 / 2.0, 4), f(part_f0 - part_bend, 4));
    let q3 = 300.0;
    let h3 = on_surface(q3, R, RATING);
    let lam3 = -grad_f0(q3, h3)[1];
    let curv3 = quad(add(hess_f0(), hess_f1(R), lam3), tangent(q3, R));
    let slope3 = C * (RATING - 3.0 * R * q3 * q3);
    println!("mistake 4, at q = {}, H = {}: curvature {} > 0, yet P still rises {} kW per L/s",
             f(q3, 0), f(h3, 2), f(curv3, 4), f(slope3, 4));
    // ---- try changing ----
    for (label, r, rating) in [("rating 80 m", R, 80.0), ("pipe twice as rough", 2.0 * R, RATING)] {
        let (qa, ha) = best(r, rating);
        let la = C * qa;
        let wa = add(hess_f0(), hess_f1(r), la);
        println!("try, {}: x* = ({}, {}), P = {} kW, lambda = {}, friction share {}, d'Wd = {}", label,
                 f(qa, 1), f(ha, 2), f(power(qa, ha), 2), f(la, 4), f(r * qa * qa / rating, 4), f(quad(wa, tangent(qa, r)), 4));
    }
    println!("figure, x*=({},{}), surface (0,60)-({},0), contours qH={} through x* and {}, tangent ({},{})-({},{})",
             f(q, 1), f(h, 1), f((RATING / R).sqrt(), 1), f(q * h, 0), f(q * h / 2.0, 0), f(q - 100.0, 0), f(h + 10.0, 0), f(q + 100.0, 0), f(h - 10.0, 0));

    assert!((q - 400.0).abs() < 1e-9 && (h - 40.0).abs() < 1e-9); // one-third rule: 20 m of 60 lost
    assert!(lam > 0.0 && res[0].abs().max(res[1].abs()) < 1e-12); // KKT, with the right sign
    assert!(worst < 1e-6); // gradients agree with differences
    assert!(along > 0.0 && (second - along).abs() < 1e-9); // road 1 = road 2: positive curvature
    assert!((dot(g0, acc) - part_bend).abs() < 1e-12); // the bend is lambda times f1's curvature
    assert!(det < 0.0 && (det + along / 100.0).abs() < 1e-12); // road 3 agrees with road 1
    assert!(arg == (400.0, 40.0) && (top - power(q, h)).abs() < 1e-9); // road 4: no grid point beats x*
    assert!(f1(-1000.0, -1000.0) <= 0.0 && power(-1000.0, -1000.0) > top); // the floors q, H >= 0 matter
    assert!((price - lam).abs() < 1e-4); // road 5: lambda is the rating's price
    assert!(ew.0 < 0.0 && quad(w, inn) < 0.0); // the Lagrangian's full-space test misleads
    assert!(slope3 > 0.0 && curv3 > 0.0); // curvature alone proves nothing
    println!("ALL CHECKS PASS");
}
