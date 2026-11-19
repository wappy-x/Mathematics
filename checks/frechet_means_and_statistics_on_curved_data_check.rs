// Frechet mean -- the same check as the Python, in Rust.  No crates.
// Six rock cores: each gives a compass bearing D and a dip I of its magnetisation.
// Part 1 averages the bearings alone, on the circle.  Part 2 averages the full
// directions, on the sphere, and finds the leading geodesic through the mean.
type V3 = [f64; 3];
const D: [f64; 6] = [340.0, 350.0, 355.0, 5.0, 10.0, 30.0]; // bearing, degrees clockwise from north
const I: [f64; 6] = [50.0, 58.0, 54.0, 63.0, 60.0, 72.0]; // dip, degrees below horizontal
const N: f64 = 6.0;
const R2D: f64 = 180.0 / std::f64::consts::PI;
const D2: f64 = R2D * R2D; // square degrees per square radian

fn sq(x: f64) -> f64 { x * x }
fn wrap(a: f64) -> f64 { (a + 180.0).rem_euclid(360.0) - 180.0 } // into [-180, 180)
fn dot(a: &V3, b: &V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn vec(d: f64, i: f64) -> V3 { // (north, east, down), a unit arrow
    let (d, i) = (d / R2D, i / R2D);
    [i.cos() * d.cos(), i.cos() * d.sin(), i.sin()]
}
fn chart(m: &V3) -> (f64, f64) { ((m[1].atan2(m[0]) * R2D).rem_euclid(360.0), m[2].asin() * R2D) }
fn dist(a: &V3, b: &V3) -> f64 { dot(a, b).min(1.0).max(-1.0).acos() } // radians
fn log(m: &V3, x: &V3) -> V3 { // the arrow at m that aims at x
    let c = dot(m, x).min(1.0).max(-1.0);
    let w = [x[0] - c * m[0], x[1] - c * m[1], x[2] - c * m[2]];
    let s = dot(&w, &w).sqrt();
    if s == 0.0 { return [0.0; 3] }
    [c.acos() * w[0] / s, c.acos() * w[1] / s, c.acos() * w[2] / s]
}
fn exp(m: &V3, v: &V3) -> V3 { // shoot from m along v
    let t = dot(v, v).sqrt();
    if t == 0.0 { return *m }
    let y = [0, 1, 2].map(|k| t.cos() * m[k] + t.sin() * v[k] / t);
    let s = dot(&y, &y).sqrt(); // rescale away rounding drift off the sphere
    y.map(|q| q / s)
}
fn sci(x: f64) -> String { // x as d.dd e-n, the same in Python
    let n = x.log10().floor();
    format!("{:.2}e{}", x / 10f64.powf(n), n as i32)
}
fn frechet(m: &V3, pts: &[V3]) -> f64 { pts.iter().map(|x| sq(dist(m, x))).sum::<f64>() / pts.len() as f64 }
fn sum(it: impl Iterator<Item = f64>) -> f64 { it.fold(0.0, |s, x| s + x) }

fn main() {
    println!("part 1: the six bearings on the circle");
    println!("bearings: {}", D.iter().map(|d| format!("{:.0}", d)).collect::<Vec<_>>().join(", "));
    let naive = sum(D.iter().copied()) / N;
    let m1 = (D[0] + sum(D.iter().map(|d| wrap(d - D[0]))) / N).rem_euclid(360.0); // road 1
    let again = sum(D.iter().map(|d| wrap(d - m1))) / N;
    let f1 = |b: f64| sum(D.iter().map(|d| sq(wrap(d - b)))) / N;
    let (mut scan1, mut fb) = (0.0, f64::INFINITY); // road 2: scan every 0.01 deg
    for k in 0..36000 { let b = k as f64 / 100.0; if f1(b) < fb { fb = f1(b); scan1 = b } }
    let ext1 = (sum(D.iter().map(|d| (d / R2D).sin())).atan2(sum(D.iter().map(|d| (d / R2D).cos()))) * R2D).rem_euclid(360.0);
    println!("average of the numbers: {:.2} deg", naive);
    println!("Frechet mean, one step from {:.0}: {:.2} deg; a second step moves it {:.2} deg", D[0], m1, again.abs());
    println!("turns from 340: {}, sum {:.0}", D.iter().map(|d| format!("{:.0}", wrap(d - D[0]))).collect::<Vec<_>>().join(", "), sum(D.iter().map(|d| wrap(d - D[0]))));
    println!("turns from the mean: {}", D.iter().map(|d| format!("{:.2}", wrap(d - m1))).collect::<Vec<_>>().join(", "));
    println!("Frechet mean, scanning 36000 bearings: {:.2} deg", scan1);
    println!("spread at the mean: {:.2} deg^2, rms {:.2} deg", f1(m1), f1(m1).sqrt());
    println!("spread at the number average: {:.2} deg^2", f1(naive));
    println!("vector average of the bearings: {:.2} deg", ext1);
    let pair = |b: f64| (sq(wrap(0.0 - b)) + sq(wrap(180.0 - b))) / 2.0;
    let (mut p2, mut pf) = (0.0, f64::INFINITY);
    for k in 0..3600 { let b = k as f64 / 10.0; let f = sq(wrap(350.0 - b)) + sq(wrap(10.0 - b)); if f < pf { pf = f; p2 = b } }
    println!("bearings 350 and 10: number average {:.0}, Frechet mean {:.0}", (350.0 + 10.0) / 2.0, p2);
    println!("bearings 0 and 180: spread {:.0} at 90, {:.0} at 270, {:.0} at 0", pair(90.0), pair(270.0), pair(0.0));

    println!("part 2: the six full directions on the sphere");
    let x: Vec<V3> = (0..6).map(|k| vec(D[k], I[k])).collect();
    println!("core  bearing  dip   north   east    down");
    for k in 0..6 {
        println!("{:>4}{:>9.0}{:>5.0}{:>8.4}{:>8.4}{:>8.4}", k + 1, D[k], I[k], x[k][0], x[k][1], x[k][2]);
    }
    let (mut m, mut it) = (x[0], 0); // road 1: average the logs, shoot, repeat
    println!("step    bearing        dip   move (deg)");
    let mut moves = vec![];
    loop {
        let g = [0, 1, 2].map(|k| sum(x.iter().map(|p| log(&m, p)[k])) / N);
        m = exp(&m, &g);
        it += 1;
        let mv = dot(&g, &g).sqrt() * R2D;
        moves.push(mv);
        println!("{:>4}{:>11.6}{:>11.6}   {}", it, chart(&m).0, chart(&m).1, sci(mv));
        if mv < 1e-9 { break }
    }
    let fm = frechet(&m, &x);
    let grid = |d0: f64, i0: f64, h: f64, n: i32| { // road 2: scan a bearing-dip grid
        let mut best = (f64::INFINITY, 0.0, 0.0);
        for a in -n..=n {
            for b in -n..=n {
                let i = (i0 + b as f64 * h).min(90.0).max(-90.0);
                let f = frechet(&vec(d0 + a as f64 * h, i), &x);
                if f < best.0 { best = (f, (d0 + a as f64 * h).rem_euclid(360.0), i) }
            }
        }
        best
    };
    let g1 = grid(180.0, 0.0, 1.0, 180);
    let mut gd = g1;
    for h in [0.1, 0.01, 0.001, 0.0001, 0.00001] { gd = grid(gd.1, gd.2, h, 20) }
    let gap = wrap(gd.1 - chart(&m).0).abs().max((gd.2 - chart(&m).1).abs());
    let gap1 = dist(&m, &vec(g1.1, g1.2)) * R2D;
    println!("whole-sphere grid, 1 deg steps: bearing {:.0}, dip {:.0}, {:.4} deg from road 1", g1.1, g1.2, gap1);
    println!("grid refined to 1e-5 deg: bearing {:.5}, dip {:.5}, {} deg from road 1", gd.1, gd.2, sci(gap));
    println!("Frechet variance {:.2} deg^2, rms angle {:.2} deg", fm * D2, fm.sqrt() * R2D);
    let s = [0, 1, 2].map(|k| sum(x.iter().map(|p| p[k])));
    let rbar = dot(&s, &s).sqrt() / N;
    let e = s.map(|v| v / (N * rbar));
    println!("vector (Fisher) mean: bearing {:.4}, dip {:.4}, length {:.4}, {:.4} deg from the Frechet mean",
             chart(&e).0, chart(&e).1, rbar, dist(&m, &e) * R2D);
    println!("dipole latitude from the mean dip: {:.1} deg", ((chart(&m).1 / R2D).tan() / 2.0).atan() * R2D);
    let (d0, i0) = (chart(&m).0 / R2D, chart(&m).1 / R2D); // unit arrows at the mean: steeper, clockwise
    let ei = [-i0.sin() * d0.cos(), -i0.sin() * d0.sin(), i0.cos()];
    let ed = [-d0.sin(), d0.cos(), 0.0];
    let p: Vec<(f64, f64)> = x.iter().map(|q| { let v = log(&m, q); (dot(&v, &ed) * R2D, dot(&v, &ei) * R2D) }).collect();
    println!("core  clockwise  steeper   (log-map coordinates at the mean, deg)");
    for k in 0..6 { println!("{:>4}{:>10.3}{:>9.3}", k + 1, p[k].0, p[k].1) }
    let sx = sum(p.iter().map(|q| q.0)) / N;
    let sy = sum(p.iter().map(|q| q.1)) / N;
    let a = sum(p.iter().map(|q| sq(q.0))) / N;
    let c = sum(p.iter().map(|q| sq(q.1))) / N;
    let b = sum(p.iter().map(|q| q.0 * q.1)) / N; // C = [[a, b], [b, c]]
    let root = (sq((a - c) / 2.0) + b * b).sqrt();
    let (l1, l2) = ((a + c) / 2.0 + root, (a + c) / 2.0 - root);
    let psi = (l1 - a).atan2(b) * R2D; // angle of the top eigenvector from clockwise
    let u = ((psi / R2D).cos(), (psi / R2D).sin());
    let cu = (a * u.0 + b * u.1, b * u.0 + c * u.1); // the matrix times u, against l1 times u
    println!("centre of the log points: {:.6}, {:.6} deg", sx.abs(), sy.abs());
    println!("covariance: {:.3} {:.3} / {:.3} {:.3} deg^2", a, b, b, c);
    println!("eigenvalues {:.3} and {:.3}, sum {:.3}; leading share {:.1}%", l1, l2, l1 + l2, 100.0 * l1 / (l1 + l2));
    let rate = moves[4] / moves[3]; // the slowest error lies across the leading geodesic
    println!("each move over the one before: {:.5}; leading spread in square radians, over 3: {:.5}", rate, l1 / D2 / 3.0);
    println!("leading direction {:.2} deg from clockwise toward steeper; check C u = ({:.3}, {:.3}), l1 u = ({:.3}, {:.3})",
             psi, cu.0, cu.1, l1 * u.0, l1 * u.1);
    let along = |t: f64| { // road 2: project onto the true great circle
        let w = [0, 1, 2].map(|k| (t / R2D).cos() * ed[k] + (t / R2D).sin() * ei[k]);
        sum(x.iter().map(|q| { let s = dot(q, &w).atan2(dot(q, &m)); s * s })) / N * D2
    };
    let mut best = (f64::NEG_INFINITY, 0.0);
    for k in 0..18000 { let t = k as f64 / 100.0; let f = along(t); if f >= best.0 { best = (f, t) } }
    println!("exact great-circle scan: best {:.2} deg, variance along it {:.3} deg^2", best.1, best.0);
    let ends: Vec<(f64, f64)> = [-1.0, 1.0].iter().map(|sg: &f64| {
        chart(&exp(&m, &[0, 1, 2].map(|k| sg * 2.0 * l1.sqrt() / R2D * (u.0 * ed[k] + u.1 * ei[k]))))
    }).collect();
    println!("two standard deviations, 2 x {:.2} deg, either way: ({:.1}, {:.1}) and ({:.1}, {:.1})", l1.sqrt(), ends[0].0, ends[0].1, ends[1].0, ends[1].1);
    let fx = sum(D.iter().map(|d| wrap(*d))) / N;
    let ibar = sum(I.iter().copied()) / N;
    let fa: Vec<(f64, f64)> = (0..6).map(|k| (wrap(D[k]) - fx, I[k] - ibar)).collect();
    let fc = [sum(fa.iter().map(|q| q.0 * q.0)) / N, sum(fa.iter().map(|q| q.0 * q.1)) / N, sum(fa.iter().map(|q| q.1 * q.1)) / N];
    let flat = 0.5 * (2.0 * fc[1]).atan2(fc[0] - fc[2]) * R2D; // an angle on the raw chart
    let onsph = (flat / R2D).sin().atan2((flat / R2D).cos() * i0.cos()) * R2D; // the same line on the sphere
    let sep = vec(m1, ibar);
    println!("mistake: PCA on raw bearing and dip: {:.2} deg on the chart, {:.2} on the sphere, {:.2} short of {:.2}", flat, onsph, psi - onsph, psi);
    println!("mistake: bearing and dip averaged apart: ({:.2}, {:.2}), {:.3} deg from the mean, spread {:.2} deg^2",
             m1, ibar, dist(&m, &sep) * R2D, frechet(&sep, &x) * D2);
    let sc = 4.0; // figure: 4 px per degree, centre (330, 110)
    println!("figure, log-map pixels: {}", p.iter().map(|q| format!("({:.1},{:.1})", 330.0 + sc * q.0, 110.0 - sc * q.1)).collect::<Vec<_>>().join(" "));
    let l = sc * 2.0 * l1.sqrt(); // two standard deviations, in pixels
    println!("figure, leading line pixels: ({:.1},{:.1}) to ({:.1},{:.1})", 330.0 - l * u.0, 110.0 + l * u.1, 330.0 + l * u.0, 110.0 - l * u.1);
    let mut cd = D.to_vec();
    cd.push(m1);
    cd.push(naive);
    println!("figure, compass pixels: {}", cd.iter().map(|d| format!("({:.1},{:.1})", 100.0 + 70.0 * (d / R2D).sin(), 110.0 - 70.0 * (d / R2D).cos())).collect::<Vec<_>>().join(" "));
    assert!(wrap(m1 - scan1).abs() <= 0.006 && (naive - m1).abs() > 170.0); // two roads; the trap is real
    assert!(gap < 2e-5 && gap1 < 1.0); // iteration against grid
    assert!(((l1 + l2) - fm * D2).abs() < 1e-9 && (cu.0 - l1 * u.0).abs() + (cu.1 - l1 * u.1).abs() < 1e-9); // trace = variance; eigenvector
    assert!(0.05 < (best.1 - psi).abs() && (best.1 - psi).abs() < 0.3 && l1 < best.0 && best.0 < l1 * 1.01); // exact scan: a small tilt, a longer spread
    assert!(pair(90.0) == pair(270.0) && pair(90.0) < pair(0.0)); // antipodes: two means
    assert!((rate / (l1 / D2 / 3.0) - 1.0).abs() < 0.1); // convergence factor as linearising predicts
    println!("ALL CHECKS PASS");
}
