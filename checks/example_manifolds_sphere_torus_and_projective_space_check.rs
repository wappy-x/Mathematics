// Sphere, torus and projective plane -- the same check as the Python, in Rust.  No crates.
// Changes of chart: closed form against chart-of-inverse-chart; determinants: closed form
// against central differences; clockwise: count the mirror choices that keep it; Euler
// characteristic: glued meshes counted against curvature summed over the surface.
use std::collections::BTreeSet;
use std::f64::consts::PI;
const R: f64 = 6371.0; // globe radius, km
const A: f64 = 3.0; const B: f64 = 1.5; // doughnut: centre-circle and tube radius, cm
type V3 = [f64; 3];
type P2 = [f64; 2];
type Chart = (Box<dyn Fn(V3) -> P2>, Box<dyn Fn(P2) -> V3>);

fn sph(lat: f64, lon: f64) -> V3 { // latitude N, longitude E in degrees -> point in space, km
    let (p, t) = ((90.0 - lat).to_radians(), lon.to_radians());
    [R * p.sin() * t.cos(), R * p.sin() * t.sin(), R * p.cos()]
}
fn det2(f: &dyn Fn(P2) -> P2, u: P2) -> f64 { // Jacobian determinant, central differences
    let mut c = [[0.0; 2]; 2];
    for i in 0..2 {
        let h = 1e-6 * u[i].abs().max(1.0);
        let (mut up, mut dn) = (u, u); up[i] += h; dn[i] -= h;
        let (a, b) = (f(up), f(dn));
        c[i] = [(a[0] - b[0]) / (2.0 * h), (a[1] - b[1]) / (2.0 * h)];
    }
    c[0][0] * c[1][1] - c[0][1] * c[1][0]
}
fn orientations(ch: &[Chart], samples: &[V3]) -> usize { // mirror choices keeping every det > 0
    let mut dets = vec![];
    for p in samples { for i in 0..ch.len() { for j in 0..ch.len() { if i != j {
        dets.push((i, j, det2(&|u| ch[j].0(ch[i].1(u)), ch[i].0(*p))));
    } } } }
    (0..1usize << ch.len()).filter(|m| {
        let s = |k: usize| if m >> k & 1 == 0 { 1.0 } else { -1.0 };
        dets.iter().all(|&(i, j, d)| s(i) * s(j) * d > 0.0)
    }).count()
}
fn f2(u: P2) -> String { format!("({:.2}, {:.2})", u[0], u[1]) }
fn sn(p: V3) -> P2 { [R * p[0] / (R - p[2]), R * p[1] / (R - p[2])] }
fn ss(p: V3) -> P2 { [R * p[0] / (R + p[2]), R * p[1] / (R + p[2])] }
fn back(u: P2, sgn: f64) -> V3 {
    let s = u[0] * u[0] + u[1] * u[1];
    [2.0 * R * R * u[0] / (s + R * R), 2.0 * R * R * u[1] / (s + R * R), sgn * R * (s - R * R) / (s + R * R)]
}
fn tor(u: P2) -> V3 { let w = A + B * u[1].cos(); [w * u[0].cos(), w * u[0].sin(), B * u[1].sin()] }
fn win(lt: f64, ls: f64, p: V3) -> P2 {
    let (t, s) = (p[1].atan2(p[0]), p[2].atan2((p[0] * p[0] + p[1] * p[1]).sqrt() - A));
    [(t - lt).rem_euclid(2.0 * PI) + lt, (s - ls).rem_euclid(2.0 * PI) + ls]
}
fn mz(p: V3) -> P2 { [R * p[0] / p[2], R * p[1] / p[2]] }
fn mx(p: V3) -> P2 { [R * p[1] / p[0], R * p[2] / p[0]] }
fn my(p: V3) -> P2 { [R * p[0] / p[1], R * p[2] / p[1]] }
type I3 = (i32, i32, i32);
fn neg(v: I3) -> I3 { (-v.0, -v.1, -v.2) }
fn glue<T: Ord + Clone>(s: &BTreeSet<T>, f: &dyn Fn(&T) -> T) -> usize {
    s.iter().map(|x| { let y = f(x); if *x < y { (x.clone(), y) } else { (y, x.clone()) } }).collect::<BTreeSet<_>>().len()
}
fn negset(s: &BTreeSet<I3>) -> BTreeSet<I3> { s.iter().map(|&v| neg(v)).collect() }
fn grid(n: i32, glued: bool) -> (usize, usize, usize) {
    let w = |i: i32| if glued { i % n } else { i };
    let (mut v, mut e, mut f) = (BTreeSet::new(), BTreeSet::new(), BTreeSet::new());
    for i in 0..n { for j in 0..n {
        let sq: Vec<(i32, i32)> = [(0, 0), (1, 0), (1, 1), (0, 1)].iter().map(|&(a, b)| (w(i + a), w(j + b))).collect();
        for k in 0..4 { v.insert(sq[k]); let (x, y) = (sq[k], sq[(k + 1) % 4]); e.insert(if x < y { (x, y) } else { (y, x) }); }
        f.insert(sq.iter().cloned().collect::<BTreeSet<_>>());
    } }
    (v.len(), e.len(), f.len())
}
fn d3(u: &V3, v: &V3) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn kint(r: &dyn Fn(P2) -> V3, s0: f64, s1: f64, t0: f64, t1: f64, n: usize) -> (f64, f64) {
    let (h, ds, dt) = (1e-4, (s1 - s0) / n as f64, (t1 - t0) / n as f64);
    let (mut tot, mut k) = (0.0, 0.0);
    for i in 0..n { for j in 0..n {
        let (s, t) = (s0 + (i as f64 + 0.5) * ds, t0 + (j as f64 + 0.5) * dt);
        let q = |a: f64, b: f64| r([s + a * h, t + b * h]);
        let c = q(0.0, 0.0);
        let m = |f: &dyn Fn(usize) -> f64| [f(0), f(1), f(2)];
        let rs = m(&|x| (q(1.0, 0.0)[x] - q(-1.0, 0.0)[x]) / (2.0 * h));
        let rt = m(&|x| (q(0.0, 1.0)[x] - q(0.0, -1.0)[x]) / (2.0 * h));
        let rss = m(&|x| (q(1.0, 0.0)[x] - 2.0 * c[x] + q(-1.0, 0.0)[x]) / h / h);
        let rtt = m(&|x| (q(0.0, 1.0)[x] - 2.0 * c[x] + q(0.0, -1.0)[x]) / h / h);
        let rst = m(&|x| (q(1.0, 1.0)[x] - q(1.0, -1.0)[x] - q(-1.0, 1.0)[x] + q(-1.0, -1.0)[x]) / (4.0 * h * h));
        let nv = [rs[1] * rt[2] - rs[2] * rt[1], rs[2] * rt[0] - rs[0] * rt[2], rs[0] * rt[1] - rs[1] * rt[0]];
        let da = d3(&nv, &nv).sqrt();
        let (l, mm, nn) = (d3(&rss, &nv) / da, d3(&rst, &nv) / da, d3(&rtt, &nv) / da);
        tot += (l * nn - mm * mm) / (d3(&rs, &rs) * d3(&rt, &rt) - d3(&rs, &rt).powi(2)) * da * ds * dt;
        k = (l * nn - mm * mm) / (da * da);
    } }
    (tot, k)
}
fn ang(a: V3, b: V3, c: V3) -> f64 { // angle at a between great-circle arcs to b and c
    let tg = |x: V3| { let k = d3(&a, &x) / R / R; [x[0] - k * a[0], x[1] - k * a[1], x[2] - k * a[2]] };
    let (tb, tc) = (tg(b), tg(c));
    (d3(&tb, &tc) / (d3(&tb, &tb) * d3(&tc, &tc)).sqrt()).acos()
}
fn main() {
    let city = [("London", 51.5074, -0.1278), ("Tokyo", 35.6762, 139.6503), ("Delhi", 28.6139, 77.2090), ("Sydney", -33.8688, 151.2093)];
    let pts: Vec<V3> = city.iter().map(|c| sph(c.1, c.2)).collect();
    let lon = pts[0];
    let sphc: Vec<Chart> = vec![(Box::new(sn), Box::new(|u| back(u, 1.0))), (Box::new(ss), Box::new(|u| back(u, -1.0)))];
    let (un, us) = (sn(lon), ss(lon));
    let (n2, nus) = (un[0] * un[0] + un[1] * un[1], (us[0] * us[0] + us[1] * us[1]).sqrt());
    let tt = [R * R * un[0] / n2, R * R * un[1] / n2];
    let (dsx, dfx) = (-(R * R / n2).powi(2), det2(&|u| ss(back(u, 1.0)), un));
    println!("globe: R = {:.0} km; London at latitude 51.5074 N, longitude 0.1278 W", R);
    println!("London in space: ({:.2}, {:.2}, {:.2}) km", lon[0], lon[1], lon[2]);
    println!("chart from North Pole: {} km; from South Pole: {} km", f2(un), f2(ss(lon)));
    println!("|u_N| = {:.2} km, |u_S| = {:.2} km; product {:.1} = R^2 = {:.1} km^2", n2.sqrt(), nus, n2.sqrt() * nus, R * R);
    println!("change of chart R^2 u/|u|^2 applied to u_N: {} km", f2(tt));
    println!("det of change, closed form -R^4/|u|^4: {:.6}; differences: {:.6}; length factor {:.6}", dsx, dfx, R * R / n2);
    println!("a point 1 km from the North Pole, chart from North Pole: {:.0} km out", sn(sph(90.0 - (1.0 / R).to_degrees(), 0.0))[0]);
    let mut torc: Vec<Chart> = vec![];
    for lt in [-PI, 0.0] { for ls in [-PI, 0.0] { torc.push((Box::new(move |p| win(lt, ls, p)), Box::new(tor))); } }
    let spr = tor([200f64.to_radians(), 300f64.to_radians()]);
    println!("doughnut: a = {:.1} cm, b = {:.1} cm; sprinkle at theta 200 deg, psi 300 deg", A, B);
    let wd = |k: usize| { let w = torc[k].0(spr); format!("({:.1}, {:.1})", w[0].to_degrees(), w[1].to_degrees()) };
    println!("sprinkle in windows (-pi,pi)^2 and (0,2pi)^2, deg: {}; {}", wd(0), wd(3));
    let dt = det2(&|u| torc[3].0(tor(u)), torc[0].0(spr));
    println!("det of change, closed form 1; differences: {:.6}", dt);
    let ts: Vec<V3> = [(200.0, 300.0), (30.0, 60.0), (120.0, 210.0), (290.0, 100.0)].iter()
        .map(|&(a, b): &(f64, f64)| tor([a.to_radians(), b.to_radians()])).collect();
    let rp: Vec<Chart> = vec![(Box::new(mz), Box::new(|u| [u[0], u[1], R])), (Box::new(mx), Box::new(|u| [R, u[0], u[1]])),
                              (Box::new(my), Box::new(|u| [u[0], R, u[1]]))];
    println!("gnomonic sheet at the North Pole: London {}, its antipode {} km", f2(mz(lon)), f2(mz([-lon[0], -lon[1], -lon[2]])));
    for (c, p) in city.iter().zip(&pts) {
        let [u, v] = mz(*p);
        println!("{}: sheet at pole {}, at 0E {}; formula (RV/U, R^2/U) {}; det R^3/U^3 {:.4}, differences {:.4}", c.0, f2([u, v]), f2(mx(*p)),
                 f2([R * v / u, R * R / u]), (R / u).powi(3), det2(&|w| mx([w[0], w[1], R]), [u, v]));
    }
    let (ns, nt, np) = (orientations(&sphc, &pts), orientations(&torc, &ts), orientations(&rp, &pts));
    println!("mirror choices keeping clockwise: globe {} of 4, doughnut {} of 16, one-sided sheet {} of 8", ns, nt, np);
    let e3: Vec<I3> = vec![(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)];
    let ov: BTreeSet<I3> = e3.iter().cloned().collect();
    let mut oe: BTreeSet<BTreeSet<I3>> = BTreeSet::new();
    for v in &e3 { for w in &e3 { if v.0 * w.0 + v.1 * w.1 + v.2 * w.2 == 0 { oe.insert([*v, *w].into_iter().collect()); } } }
    let mut of: BTreeSet<BTreeSet<I3>> = BTreeSet::new();
    for x in [1, -1] { for y in [1, -1] { for z in [1, -1] { of.insert([(x, 0, 0), (0, y, 0), (0, 0, z)].into_iter().collect()); } } }
    let (gv, ge, gf) = (glue(&ov, &|v| neg(*v)), glue(&oe, &negset), glue(&of, &negset));
    let (cs, cp) = (ov.len() as i64 - oe.len() as i64 + of.len() as i64, gv as i64 - ge as i64 + gf as i64);
    let chi = |g: (usize, usize, usize)| g.0 as i64 - g.1 as i64 + g.2 as i64;
    let (ct, cq) = (chi(grid(4, true)), chi(grid(4, false)));
    println!("Euler count V - E + F: octahedron {} - {} + {} = {}; glued opposite: {} - {} + {} = {}", ov.len(), oe.len(), of.len(), cs, gv, ge, gf, cp);
    println!("Euler count: 4 x 4 grid glued {}; same grid unglued {}", ct, cq);
    let glb = |u: P2| [R * u[0].sin() * u[1].cos(), R * u[0].sin() * u[1].sin(), R * u[0].cos()];
    let (gs, gs50, gp) = (kint(&glb, 0.0, PI, 0.0, 2.0 * PI, 100).0, kint(&glb, 0.0, PI, 0.0, 2.0 * PI, 50).0, kint(&glb, 0.0, PI / 2.0, 0.0, 2.0 * PI, 100).0);
    let g = |a: f64, b: f64| kint(&tor, -PI, PI, a, b, 100).0;
    let (gt, go, gi) = (g(-PI, PI), g(-PI / 2.0, PI / 2.0), g(PI / 2.0, 3.0 * PI / 2.0));
    let (ko, ki) = (kint(&tor, -1e-3, 1e-3, -1e-3, 1e-3, 1).1, kint(&tor, -1e-3, 1e-3, PI - 1e-3, PI + 1e-3, 1).1);
    println!("doughnut K: outer equator {:.6} (closed form {:.6}), inner {:.6} ({:.6}) per cm^2", ko, 1.0 / (B * (A + B)), ki, -1.0 / (B * (A - B)));
    let z6 = |x: f64| (x * 1e6).round() / 1e6 + 0.0; // prints -0.000000 as 0.000000
    println!("integral of K dA / 2pi: globe {:.6}, doughnut {:.6}, one-sided sheet {:.6}", gs / (2.0 * PI), z6(gt / (2.0 * PI)), gp / (2.0 * PI));
    println!("doughnut: outer half {:.6}, inner half {:.6}, 4pi = {:.6}; globe error 50 steps {:.6}, 100 steps {:.6}", go, gi, 4.0 * PI,
             (gs50 - 4.0 * PI).abs(), (gs - 4.0 * PI).abs());
    let tri = [sph(90.0, 0.0), sph(0.0, 0.0), sph(0.0, 90.0)];
    let tot: f64 = (0..3).map(|k| ang(tri[k], tri[(k + 1) % 3], tri[(k + 2) % 3])).sum();
    println!("octant triangle: angles add to {:.4} deg (a flat sheet gives 180); excess x R^2 = {:.0} km^2, one eighth of 4 pi R^2 = {:.0} km^2",
             tot.to_degrees(), (tot - PI) * R * R, PI * R * R / 2.0);
    let ph = 38.4926f64.to_radians();
    println!("figure, 100 units = R; N (120, 30), S (120, 230), London ({:.2}, {:.2}), u_N ({:.2}, 130), u_S ({:.2}, 130)", 120.0 + 100.0 * ph.sin(), 130.0 - 100.0 * ph.cos(), 120.0 + 100.0 * un[0] / R, 120.0 + 100.0 * us[0] / R);

    assert!((tt[0] - us[0]).abs() < 1e-6 && (tt[1] - us[1]).abs() < 1e-6); // formula = chart of inverse
    assert!((dfx - dsx).abs() < 1e-6 && (dt - 1.0).abs() < 1e-6); // determinants: closed form = differences
    assert!((0..2).all(|k| (torc[3].0(spr)[k] - torc[0].0(spr)[k] - 2.0 * PI).abs() < 1e-12)); // torus: a shift by 2 pi
    assert!(pts.iter().all(|p| (mx(*p)[0] - R * mz(*p)[1] / mz(*p)[0]).abs() + (mx(*p)[1] - R * R / mz(*p)[0]).abs() < 1e-6));
    assert!((ns, nt, np) == (2, 2, 0)); // clockwise: kept, kept, impossible
    let rd = |x: f64| (x / (2.0 * PI)).round() as i64;
    assert!((cs, ct, cp) == (rd(gs), rd(gt), rd(gp)) && (cs, ct, cp) == (2, 0, 1));
    assert!((ko - 1.0 / (B * (A + B))).abs() < 1e-5 && (ki + 1.0 / (B * (A - B))).abs() < 1e-5);
    assert!(((tot - PI) * R * R - PI * R * R / 2.0).abs() < 1e-3 * R * R);
    println!("ALL CHECKS PASS");
}
