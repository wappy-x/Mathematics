// Regular value theorem -- the check behind the card.  std only, no crates.
// $10,000 split as x, y, z dollars in funds with yearly swings of 10%, 20% and 30%,
// taken as independent.  F = (total, risk squared) = (x + y + z, (0.1x)^2 + (0.2y)^2 + (0.3z)^2).
// Road one: the rank test, dF and its 2 x 2 minors.  Road two: a chart from the
// implicit function theorem, solved by Newton and by the quadratic formula.
// Road three: the loop drawn with no derivatives, as a sphere cut by a plane.
use std::f64::consts::PI;
type V3 = [f64; 3];
const SIG: V3 = [0.1, 0.2, 0.3];
const TOTAL: f64 = 10000.0;
const RISK: f64 = 900.0;

fn f(p: V3) -> (f64, f64) {
    let mut s = 0.0;
    for i in 0..3 { s += (SIG[i] * p[i]).powi(2); }
    (0.0 + p[0] + p[1] + p[2], s)
}
fn df(p: V3) -> [V3; 2] { [[1.0, 1.0, 1.0], [2.0 * SIG[0] * SIG[0] * p[0], 2.0 * SIG[1] * SIG[1] * p[1], 2.0 * SIG[2] * SIG[2] * p[2]]] }
fn minors(j: [V3; 2]) -> V3 { // columns (x, y), (x, z), (y, z)
    let pr = [(0, 1), (0, 2), (1, 2)];
    let mut m = [0.0; 3];
    for (k, &(i, l)) in pr.iter().enumerate() { m[k] = j[0][i] * j[1][l] - j[0][l] * j[1][i]; }
    m
}
fn cross(a: V3, b: V3) -> V3 { [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]] }
fn dot(a: V3, b: V3) -> f64 { 0.0 + a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn unit(a: V3) -> V3 { let n = dot(a, a).sqrt(); [a[0] / n, a[1] / n, a[2] / n] }
fn v(a: &[f64], d: usize) -> String {
    format!("({})", a.iter().map(|c| format!("{:.*}", d, c)).collect::<Vec<_>>().join(", "))
}
fn maxabs(a: V3) -> f64 { a.iter().fold(0.0f64, |m, c| m.max(c.abs())) }

fn chart_newton(z: f64, mut x: f64, mut y: f64) -> (f64, f64) { // road two: F = c for (x, y), z held
    for _ in 0..50 {
        let f1 = x + y + z - TOTAL;
        let f2 = (0.1 * x).powi(2) + (0.2 * y).powi(2) + (0.3 * z).powi(2) - RISK.powi(2);
        let (a, b) = (0.02 * x, 0.08 * y); // block dF/d(x, y) = [[1, 1], [a, b]]
        let det = b - a;
        let (nx, ny) = (x - (b * f1 - f2) / det, y - (-a * f1 + f2) / det);
        x = nx; y = ny;
    }
    (x, y)
}
fn chart_exact(z: f64) -> (f64, f64) { // same chart, quadratic formula, root nearer p
    let (s, q) = (TOTAL - z, RISK.powi(2) - (0.3 * z).powi(2)); // x + y = s, 0.01x^2 + 0.04y^2 = q
    let (a, b, c) = (0.05, -0.08 * s, 0.04 * s * s - q);
    let x = (-b - (b * b - 4.0 * a * c).sqrt()) / (2.0 * a);
    (x, s - x)
}

fn main() {
    let p: V3 = [6000.0, 3000.0, 1000.0];
    let j = df(p);
    println!("swings {} %, squared {}; total {:.0}, risk {:.0}; n - k = 3 - 2 = 1",
             v(&[100.0 * SIG[0], 100.0 * SIG[1], 100.0 * SIG[2]], 0), v(&[SIG[0] * SIG[0], SIG[1] * SIG[1], SIG[2] * SIG[2]], 2), TOTAL, RISK);
    println!("split p = {}: total {:.0}, risk squared {:.0}, risk {:.2}", v(&p, 0), f(p).0, f(p).1, f(p).1.sqrt());
    println!("dF_p rows {} and {}", v(&j[0], 0), v(&j[1], 0));
    let m = minors(j);
    println!("minors (x,y) (x,z) (y,z): {:.0} {:.0} {:.0}, rank 2", m[0], m[1], m[2]);
    let t = cross(j[0], j[1]);
    println!("tangent = row 1 x row 2 = {}; per $1 into z: {}", v(&t, 0), v(&[t[0] / t[2], t[1] / t[2], t[2] / t[2]], 2));
    assert!(dot(t, j[0]).abs() < 1e-9 && dot(t, j[1]).abs() < 1e-9);

    let ift = ((j[1][2] - j[1][1]) / (j[1][1] - j[1][0]), (j[1][0] - j[1][2]) / (j[1][1] - j[1][0]));
    println!("implicit function slopes dx/dz, dy/dz = {:.4}, {:.4}", ift.0, ift.1);
    let mut sl = (0.0, 0.0);
    for h in [100.0f64, 10.0] {
        let (a, b) = (chart_newton(1000.0 + h, 6000.0, 3000.0), chart_newton(1000.0 - h, 6000.0, 3000.0));
        sl = ((a.0 - b.0) / (2.0 * h), (a.1 - b.1) / (2.0 * h));
        println!("  Newton chart, step {:.0}: slopes {:.6}, {:.6}", h, sl.0, sl.1);
    }
    assert!((sl.0 - ift.0).abs() < 1e-4 && (sl.1 - ift.1).abs() < 1e-4);
    let (xn, yn) = chart_newton(1100.0, 6000.0, 3000.0);
    let (xe, ye) = chart_exact(1100.0);
    assert!((xn - xe).abs() < 1e-6 && (yn - ye).abs() < 1e-6);
    let lin = [6000.0 + 100.0 * ift.0, 3000.0 + 100.0 * ift.1, 1100.0];
    println!("z = 1100: chart gives x, y = {:.2}, {:.2} (quadratic formula {:.2}, {:.2})", xn, yn, xe, ye);
    println!("  straight-line trade {} has risk {:.2}", v(&lin, 2), f(lin).1.sqrt());

    let w = [1.0 / SIG[0], 1.0 / SIG[1], 1.0 / SIG[2]]; // road three: u = 0.1x, v = 0.2y, w = 0.3z
    let nh = unit(w);
    let d = TOTAL / dot(w, w).sqrt(); // distance from origin to the budget plane
    let r = (RISK.powi(2) - d * d).sqrt();
    println!("risk coordinates of p {}; plane normal {}", v(&[SIG[0] * p[0], SIG[1] * p[1], SIG[2] * p[2]], 0), v(&nh, 6));
    println!("plane distance = least risk {:.6} (6000/7 = {:.6}); circle radius {:.2}", d, 6000.0 / 7.0, r);
    let sw = 0.0 + 1.0 / SIG[0].powi(2) + 1.0 / SIG[1].powi(2) + 1.0 / SIG[2].powi(2);
    let lag = [TOTAL * (1.0 / SIG[0].powi(2)) / sw, TOTAL * (1.0 / SIG[1].powi(2)) / sw, TOTAL * (1.0 / SIG[2].powi(2)) / sw];
    println!("least-risk split (Lagrange) {}, risk {:.6}", v(&lag, 2), f(lag).1.sqrt());
    assert!((f(lag).1.sqrt() - d).abs() < 1e-6);
    let e1 = unit([-nh[1], nh[0], 0.0]); let e2 = cross(nh, e1);
    let lp = |th: f64| -> V3 {
        let mut q = [0.0; 3];
        for i in 0..3 { q[i] = (d * nh[i] + r * (th.cos() * e1[i] + th.sin() * e2[i])) / SIG[i]; }
        q
    };

    let n = 7200usize;
    let pts: Vec<V3> = (0..n).map(|k| lp(2.0 * PI * k as f64 / n as f64)).collect();
    let err = pts.iter().fold(0.0f64, |m, q| m.max((f(*q).0 - TOTAL).abs()).max((f(*q).1 - RISK.powi(2)).abs()));
    let low = pts.iter().fold(f64::INFINITY, |m, q| m.min(maxabs(minors(df(*q)))));
    println!("loop, {} points: every one solves F = c to within 1e-6; smallest largest-minor {:.2}", n, low);
    assert!(err < 1e-6 && low > 1.0);
    let where_zero = |k: usize, mut a: f64, mut b: f64| -> V3 { // bisection on a sign change of minor k
        for _ in 0..60 {
            let c = (a + b) / 2.0;
            if (minors(df(lp(a)))[k] > 0.0) == (minors(df(lp(c)))[k] > 0.0) { a = c; } else { b = c; }
        }
        lp(a)
    };
    let mut fails: Vec<V3> = Vec::new();
    for &(k, name, i) in &[(2usize, "x", 0usize), (1, "y", 1), (0, "z", 2)] {
        let ch: Vec<usize> = (0..n).filter(|&jj| (minors(df(pts[jj]))[k] > 0.0) != (minors(df(pts[(jj + 1) % n]))[k] > 0.0)).collect();
        let mut fp: Vec<V3> = ch.iter().map(|&jj| where_zero(k, 2.0 * PI * jj as f64 / n as f64, 2.0 * PI * (jj + 1) as f64 / n as f64)).collect();
        fp.sort_by(|a, b| a[i].partial_cmp(&b[i]).unwrap());
        fails.extend(fp.iter().cloned());
        let hw = r * (1.0 - nh[i].powi(2)).sqrt();
        let cf = ((d * nh[i] - hw) / SIG[i], (d * nh[i] + hw) / SIG[i]);
        println!("chart over {} fails at {} points, {} = {:.2} and {:.2} (closed form {:.2}, {:.2})",
                 name, ch.len(), name, fp[0][i], fp[1][i], cf.0, cf.1);
        assert!(ch.len() == 2 && (fp[0][i] - cf.0).abs() < 1e-6 && (fp[1][i] - cf.1).abs() < 1e-6);
    }
    let yp = [SIG[0] * p[0] - d * nh[0], SIG[1] * p[1] - d * nh[1], SIG[2] * p[2] - d * nh[2]]; // p from the centre
    let thp = dot(yp, e2).atan2(dot(yp, e1));
    let (q1, q0) = (lp(thp + 1e-6), lp(thp - 1e-6));
    let vel = [q1[0] - q0[0], q1[1] - q0[1], q1[2] - q0[2]];
    let at = lp(thp); let gap = maxabs([at[0] - p[0], at[1] - p[1], at[2] - p[2]]);
    println!("loop at angle {:.6} rad meets p (gap {:.6}); its velocity, scaled: {}", thp, gap,
             v(&[vel[0] / vel[2], vel[1] / vel[2], vel[2] / vel[2]], 3));
    let cx = cross(unit(vel), unit(t));
    assert!(gap < 1e-6 && dot(cx, cx).sqrt() < 1e-6);
    let edges: Vec<String> = fails.iter().map(|q| v(&q[1..], 0)).collect();
    println!("figure, (y, z): p {}, centre {}, chart edges {}", v(&p[1..], 0), v(&lag[1..], 0), edges.join(" "));

    println!("what breaks:");
    let jl = df(lag);
    println!("  risk {:.2}: one split, largest minor {:.6}, rank 1, dimension 0 not 1", d, maxabs(minors(jl)));
    assert!(maxabs(minors(jl)) < 1e-6);
    println!("  risk 850.00: radius squared {:.2} < 0, no split at all", 850.0f64.powi(2) - d * d);
    println!("  total twice (dollars, cents): minors {}, rank 1, the set is a plane",
             v(&minors([[1.0, 1.0, 1.0], [100.0, 100.0, 100.0]]), 0));
    let g = 2.0 * (f(p).0 - TOTAL);
    println!("  (x + y + z - 10000)^2 = 0: differential {}, a plane, test silent", v(&[g, g, g], 0));
    let rg = 6371.0f64;
    println!("globe x^2 + y^2 + z^2 = {:.0}^2: |dF| = 2R = {:.0} km, never 0, dimension 3 - 1 = 2", rg, 2.0 * rg);
    let mut mm: Vec<Vec<f64>> = Vec::new(); // O(3): dF_I(H) = H + H^T, 9 inputs, 6 outputs
    for a in 0..9 {
        let h: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|l| if 3 * i + l == a { 1.0 } else { 0.0 }).collect()).collect();
        let mut row = Vec::new();
        for i in 0..3 { for l in i..3 { row.push(h[i][l] + h[l][i]); } }
        mm.push(row);
    }
    let mut rank = 0;
    for col in 0..6 {
        let piv = (rank..9).find(|&i| mm[i][col].abs() > 1e-12);
        let Some(pv) = piv else { continue };
        mm.swap(rank, pv);
        for i in 0..9 {
            if i != rank {
                let fct = mm[i][col] / mm[rank][col];
                let base = mm[rank].clone();
                for (a, b) in mm[i].iter_mut().zip(base.iter()) { *a = *a - fct * b; }
            }
        }
        rank += 1;
    }
    println!("O(3): A^T A = I, 9 entries, rank of dF_I {}, dimension {}", rank, 9 - rank);
    assert!(rank == 6);
    println!("ALL CHECKS PASS");
}
