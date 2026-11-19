// Exterior derivative on the valley wind -- the check behind the card.  std only, no crates.
// x east, y north, z up, in metres; the mast M stands at (200, 300, 50).  Three roads:
// (1) the rule by hand, (2) sums round small boxes with no derivatives at all,
// (3) one general d by central differences, in the map chart and in a terrain-following chart.
use std::collections::BTreeMap;
use std::rc::Rc;
type Pt = [f64; 3];
type Coef = Rc<dyn Fn(&Pt) -> f64>;
type Form = BTreeMap<Vec<usize>, Coef>; // sorted index list -> coefficient; 0, 1, 2 stand for dx, dy, dz
const M: Pt = [200.0, 300.0, 50.0];
const MS: Pt = [200.0, 300.0, 30.0]; // the mast in the terrain chart
const H: f64 = 0.01;

fn p_(p: &Pt) -> f64 { 0.001 * p[0] - 0.0006 * p[1] + 0.004 * p[2] } // east wind, m/s
fn q_(p: &Pt) -> f64 { 4.0 + 0.0003 * p[1] + 0.01 * p[2] - 0.000004 * p[0] * p[0] } // north wind
fn r_(p: &Pt) -> f64 { 0.0005 * p[0] - 0.0013 * p[2] } // upward wind
fn t_(p: &Pt) -> f64 { 20.0 + 0.003 * p[0] - 0.0065 * p[2] } // air temperature, degC
fn wind(k: usize, p: &Pt) -> f64 { [p_, q_, r_][k](p) }
fn cl(v: f64) -> f64 { if v.abs() < 1e-8 { 0.0 } else { v } }
fn f6(vs: &[f64]) -> String { vs.iter().map(|v| format!("{:.6}", cl(*v))).collect::<Vec<_>>().join(" ") }

// road 1: the rule by hand, each rate read off the formulas above
fn hand(p: &Pt) -> ([f64; 3], [f64; 3], f64, [f64; 3], f64) {
    let (px, py, pz, qx, qy, qz, rx, ry, rz) = (0.001, -0.0006, 0.004, -0.000008 * p[0], 0.0003, 0.01, 0.0005, 0.0, -0.0013);
    ([0.003, 0.0, -0.0065], [ry - qz, pz - rx, qx - py], px + qy + rz, [px, qy, rz], qx + py)
}
fn partial(f: &dyn Fn(&Pt) -> f64, j: usize, p: &Pt, h: f64) -> f64 {
    let (mut a, mut b) = (*p, *p); a[j] += h; b[j] -= h;
    (f(&a) - f(&b)) / (2.0 * h)
}
fn d(form: &Form) -> Form { d_rule(form, true) }
fn d_rule(form: &Form, signed: bool) -> Form { // road 3: the one rule, for every degree; signed = false drops the sign rule
    let mut terms: BTreeMap<Vec<usize>, Vec<(f64, Coef, usize)>> = BTreeMap::new();
    for (i_, f) in form {
        for j in 0..3 {
            if i_.contains(&j) { continue; } // dx^j wedge dx^j = 0
            let sign = if !signed || i_.iter().filter(|&&i| i < j).count() % 2 == 0 { 1.0 } else { -1.0 };
            let mut jj = i_.clone(); jj.push(j); jj.sort();
            terms.entry(jj).or_default().push((sign, f.clone(), j));
        }
    }
    terms.into_iter().map(|(jj, t)| {
        let c: Coef = Rc::new(move |p: &Pt| t.iter().map(|(s, f, j)| s * partial(&**f, *j, p, H)).sum());
        (jj, c)
    }).collect()
}
fn det(m: &Vec<Vec<f64>>) -> f64 { // Laplace expansion along the first row; the empty matrix has det 1
    if m.is_empty() { return 1.0; }
    (0..m.len()).map(|c| {
        let minor: Vec<Vec<f64>> = m[1..].iter().map(|r| r.iter().enumerate().filter(|(k, _)| *k != c).map(|(_, v)| *v).collect()).collect();
        if c % 2 == 0 { m[0][c] * det(&minor) } else { -m[0][c] * det(&minor) }
    }).sum()
}
fn chart(q: &Pt, k: f64) -> Pt { [q[0], q[1], q[2] + k * q[0] * q[0]] } // s: height above the floor k x^2
fn pull(form: &Form, k: f64) -> Form { // pullback to (x, y, s): coefficients times Jacobian minors
    let deg = form.keys().next().unwrap().len();
    let sets: Vec<Vec<usize>> = match deg { 0 => vec![vec![]], 1 => vec![vec![0], vec![1], vec![2]],
        2 => vec![vec![0, 1], vec![0, 2], vec![1, 2]], _ => vec![vec![0, 1, 2]] };
    sets.into_iter().map(|a| {
        let form = form.clone(); let a2 = a.clone();
        let c: Coef = Rc::new(move |q: &Pt| {
            let jm: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|b| partial(&|u: &Pt| chart(u, k)[i], b, q, H)).collect()).collect();
            form.iter().map(|(i_, f)| f(&chart(q, k)) * det(&i_.iter().map(|&i| a2.iter().map(|&b| jm[i][b]).collect()).collect())).sum()
        });
        (a, c)
    }).collect()
}
fn mk(v: Vec<(Vec<usize>, Coef)>) -> Form { v.into_iter().collect() }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h / 3.0 * (g(a) + g(b) + (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h)).sum::<f64>())
}
fn pt(moves: &[(usize, f64)]) -> Pt { let mut p = M; for &(ax, amt) in moves { p[ax] += amt; } p }
fn circ(i: usize, j: usize, l: f64) -> f64 { // walk the l-square round M in the plane of axes i, j
    let a = l / 2.0;
    simpson(&|u| wind(i, &pt(&[(i, u), (j, -a)])) - wind(i, &pt(&[(i, u), (j, a)])), -a, a, 4)
        + simpson(&|v| wind(j, &pt(&[(i, a), (j, v)])) - wind(j, &pt(&[(i, -a), (j, v)])), -a, a, 4)
}
fn outflow(k: usize, l: f64) -> f64 { // net air leaving the l-cube through its two faces across axis k
    let o: Vec<usize> = (0..3).filter(|&m| m != k).collect(); let (i, j, a) = (o[0], o[1], l / 2.0);
    simpson(&|u| simpson(&|v| wind(k, &pt(&[(k, a), (i, u), (j, v)])) - wind(k, &pt(&[(k, -a), (i, u), (j, v)])), -a, a, 4), -a, a, 4)
}
fn fx(x: f64, y: f64) -> f64 { if x == 0.0 && y == 0.0 { 0.0 } else { y * (x.powi(4) + 4.0 * x * x * y * y - y.powi(4)) / (x * x + y * y).powi(2) } }
fn fy(x: f64, y: f64) -> f64 { if x == 0.0 && y == 0.0 { 0.0 } else { x * (x.powi(4) - 4.0 * x * x * y * y - y.powi(4)) / (x * x + y * y).powi(2) } }

fn main() {
    let temp = mk(vec![(vec![], Rc::new(t_) as Coef)]);
    let omega = mk(vec![(vec![0], Rc::new(p_) as Coef), (vec![1], Rc::new(q_) as Coef), (vec![2], Rc::new(r_) as Coef)]);
    let phi = mk(vec![(vec![1, 2], Rc::new(p_) as Coef), (vec![0, 2], Rc::new(|p: &Pt| -q_(p)) as Coef), (vec![0, 1], Rc::new(r_) as Coef)]);
    let (gt, curl, div, own, swapped) = hand(&M);
    println!("mast M (200, 300, 50) m: wind {} m/s, T {:.6} degC", f6(&[p_(&M), q_(&M), r_(&M)]), t_(&M));
    let rate = gt[0] * p_(&M) + gt[2] * r_(&M);
    println!("road 1, dT = gradient (dx dy dz): {} degC/m; dT(wind) {:.7} degC/s = {:.6} degC/h", f6(&gt), rate, rate * 3600.0);
    println!("road 1, d omega = curl (dy^dz dz^dx dx^dy): {} per s; spin {} rad/s", f6(&curl), f6(&curl.map(|c| c / 2.0)));
    let turn = 2.0 * 3.141592653589793 / (curl[0] / 2.0).abs();
    println!("  rates (x y z): P 0.001000 -0.000600 0.004000; Q {:.6} 0.000300 0.010000; R 0.000500 0.000000 -0.001300", -0.000008 * M[0]);
    println!("  east-west spin: a turn in {:.1} s = {:.1} min", turn, turn / 60.0);
    println!("road 1, d Phi = div (dx^dy^dz): {} per s = {} + {} + {}", f6(&[div]), f6(&[own[0]]), f6(&[own[1]]), f6(&[own[2]]));
    let (g0, g1, g2) = (d(&temp), d(&omega), d(&phi));
    let row = |f: &Form, p: &Pt| [f[&vec![1, 2]](p), -f[&vec![0, 2]](p), f[&vec![0, 1]](p)];
    let r30: Vec<f64> = (0..3).map(|i| g0[&vec![i]](&M)).collect();
    let (r31, r32) = (row(&g1, &M), g2[&vec![0, 1, 2]](&M));
    println!("road 3, general d: dT {}; d omega {}; d Phi {}", f6(&r30), f6(&r31), f6(&[r32]));
    let hv = [gt[0], gt[1], gt[2], curl[0], curl[1], curl[2], div];
    let rv = [r30[0], r30[1], r30[2], r31[0], r31[1], r31[2], r32];
    for (a, b) in hv.iter().zip(rv.iter()) { assert!((a - b).abs() < 1e-9); }

    let l = 10.0;
    let seg = [(t_(&pt(&[(0, l)])) - t_(&M)) / l, (t_(&pt(&[(2, l)])) - t_(&M)) / l];
    let cs = [circ(1, 2, l), circ(2, 0, l), circ(0, 1, l)];
    let fl = [outflow(0, l), outflow(1, l), outflow(2, l)];
    println!("road 2, 10 m east and up: T changes {} degC/m", f6(&seg));
    println!("road 2, 10 m squares: circulation {} m^2/s; per area {}", f6(&cs), f6(&cs.map(|c| c / (l * l))));
    println!("road 2, 10 m cube: outflow east-west {}, north-south {}, top-bottom {}, total {} m^3/s",
             f6(&[fl[0]]), f6(&[fl[1]]), f6(&[fl[2]]), f6(&[fl[0] + fl[1] + fl[2]]));
    assert!((seg[0] - gt[0]).abs() < 1e-12 && (seg[1] - gt[2]).abs() < 1e-12);
    for k in 0..3 { assert!((cs[k] / (l * l) - curl[k]).abs() < 1e-12); } // Stokes in the small, degree 1
    for k in 0..3 { assert!((fl[k] / (l * l * l) - own[k]).abs() < 1e-12); } // Stokes in the small, degree 2
    let cs100 = [circ(1, 2, 100.0) / 1e4, circ(2, 0, 100.0) / 1e4, circ(0, 1, 100.0) / 1e4];

    let (pt_, pw, pp) = (pull(&temp, 0.0005), pull(&omega, 0.0005), pull(&phi, 0.0005));
    let dpw = d(&pw);
    let hd = |k: usize, sg: f64| -> Coef { Rc::new(move |p: &Pt| sg * hand(p).1[k]) };
    let pdw = pull(&mk(vec![(vec![1, 2], hd(0, 1.0)), (vec![0, 2], hd(1, -1.0)), (vec![0, 1], hd(2, 1.0))]), 0.0005);
    println!("terrain chart s = z - 0.0005 x^2: at M floor {:.0} m, s = {:.0} m, floor slope {:.6}", 0.0005 * MS[0] * MS[0], MS[2], 0.001 * MS[0]);
    let dpt = d(&pt_);
    let pg: Vec<f64> = (0..3).map(|i| dpt[&vec![i]](&MS)).collect();
    println!("  dT pulled back (dx dy ds): {} degC/m", f6(&pg));
    println!("  omega pulled back (dx dy ds): {} m/s", f6(&(0..3).map(|i| pw[&vec![i]](&MS)).collect::<Vec<_>>()));
    println!("  d(pulled-back omega) (dy^ds ds^dx dx^dy): {}", f6(&row(&dpw, &MS)));
    println!("  pulled-back d omega  (dy^ds ds^dx dx^dy): {}", f6(&row(&pdw, &MS)));
    let vol = pull(&mk(vec![(vec![0, 1, 2], Rc::new(|_: &Pt| 1.0) as Coef)]), 0.0005);
    println!("  d(pulled-back Phi) {}; Jacobian determinant {:.6}", f6(&[d(&pp)[&vec![0, 1, 2]](&MS)]), vol[&vec![0, 1, 2]](&MS));
    for (a, b) in row(&dpw, &MS).iter().zip(row(&pdw, &MS).iter()) { assert!((a - b).abs() < 1e-9); } // d commutes with pullback
    assert!((pg[0] - (gt[0] + gt[2] * 0.2)).abs() < 1e-9 && (pg[2] - gt[2]).abs() < 1e-9);
    let test = mk(vec![(vec![0], Rc::new(|p: &Pt| p_(p) + 0.001 * p[1] * p[2]) as Coef), (vec![1], Rc::new(q_) as Coef), (vec![2], Rc::new(r_) as Coef)]);
    let ptest = pull(&test, 0.0005); // test: a mixed second rate, 0.001
    let mut dd: Vec<f64> = Vec::new();
    for f in [&temp, &omega, &test] { for v in d(&d(f)).values() { dd.push(v(&M)); } }
    for f in [&pw, &ptest] { for v in d(&d(f)).values() { dd.push(v(&MS)); } }
    let ddmax = dd.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    println!("d(d .) of T, omega, omega + 0.001 yz dx; of pulled-back omega, omega + 0.001 yz dx: largest coefficient {:.9}", cl(ddmax));
    assert!(ddmax < 1e-9);

    let rule = (fy(1e-4, 0.0) - fy(-1e-4, 0.0)) / 2e-4 - (fx(0.0, 1e-4) - fx(0.0, -1e-4)) / 2e-4;
    let a = 0.5e-3;
    let bx = (simpson(&|u| fx(u, -a) - fx(u, a), -a, a, 256) + simpson(&|v| fy(a, v) - fy(-a, v), -a, a, 256)) / (2.0 * a * 2.0 * a);
    let naive = d(&mk((0..3).map(|i| (vec![i], Rc::new(move |q: &Pt| wind(i, &chart(q, 0.0005))) as Coef)).collect()));
    println!("breaks: commuting wedge, up part {}; dx^dz for dz^dx, d Phi {}; chart without dz = ds + 0.2 dx, ds^dx {}",
             f6(&[swapped]), f6(&[own[0] - own[1] + own[2]]), f6(&[-naive[&vec![0, 2]](&MS)]));
    println!("breaks: pinched f = xy(x^2-y^2)/(x^2+y^2) at 0: rule gives d(df) {}, box gives {}", f6(&[rule]), f6(&[bx]));
    assert!((rule - 2.0).abs() < 1e-9 && bx.abs() < 1e-8 && (swapped - d_rule(&omega, false)[&vec![0, 1]](&M)).abs() < 1e-9);
    let w2 = mk(vec![(vec![0], Rc::new(p_) as Coef), (vec![1], Rc::new(|p: &Pt| q_(p) + 0.01 * p[2]) as Coef), (vec![2], Rc::new(r_) as Coef)]);
    println!("try: mast at x = 400 m, up part {}; floor 0.001 x^2, slope {:.6}, terrain dx^dy {}; shear 0.02, dy^dz {}",
             f6(&[hand(&[400.0, 300.0, 50.0]).1[2]]), 0.002 * MS[0], f6(&[d(&pull(&omega, 0.001))[&vec![0, 1]](&MS)]), f6(&[d(&w2)[&vec![1, 2]](&M)]));
    println!("try: 100 m squares, per area {}", f6(&cs100));
    for k in 0..3 { assert!((cs100[k] - curl[k]).abs() < 1e-12); }
    println!("ALL CHECKS PASS");
}
