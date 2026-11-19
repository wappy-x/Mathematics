// Differential forms and the wedge product -- the same check as the Python, in Rust.
// Standard library only, no crates.  A k-form is a map {sorted index list: coefficient}.
// Road 1: wedge by sorting indices with a sign, evaluate by determinants of minors.
// Road 2: evaluate by the brute-force alternating sum over every ordering of the edges.
// Road 3: geometry: shoelace corners, a grid count, Lagrange's identity, a prism volume.
use std::collections::BTreeMap;
type Form = BTreeMap<Vec<usize>, f64>;

fn perms(n: usize) -> Vec<(Vec<usize>, f64)> {   // every ordering of 0..n-1, with its sign
    if n == 0 { return vec![(vec![], 1.0)]; }
    let mut out = vec![];
    for (p, s) in perms(n - 1) {
        for k in 0..n {                            // insert n-1 at place k: n-1-k swaps
            let mut q = p.clone();
            q.insert(k, n - 1);
            out.push((q, if (n - 1 - k) % 2 == 0 { s } else { -s }));
        }
    }
    out
}

fn sort_sign(mut idx: Vec<usize>) -> (Vec<usize>, f64) {   // bubble sort; each swap flips the sign
    let mut sign = 1.0;
    let n = idx.len();
    for i in 0..n {
        for j in 0..n - 1 - i {
            if idx[j] > idx[j + 1] { idx.swap(j, j + 1); sign = -sign; }
        }
    }
    (idx, sign)
}

fn wedge(a: &Form, b: &Form) -> Form {            // road 1: concatenate, sort, drop repeats
    let mut out = Form::new();
    for (i, x) in a {
        for (j, y) in b {
            let (idx, s) = sort_sign([i.clone(), j.clone()].concat());
            let mut d = idx.clone();
            d.dedup();
            if d.len() == idx.len() { *out.entry(idx).or_insert(0.0) += s * x * y; }
        }
    }
    out.into_iter().filter(|(_, v)| v.abs() > 1e-15).collect()
}

fn det(m: &Vec<Vec<f64>>) -> f64 {                // cofactor expansion along the top row
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|c| {
        let minor: Vec<Vec<f64>> = m[1..].iter().map(|r| [&r[..c], &r[c + 1..]].concat()).collect();
        (if c % 2 == 0 { 1.0 } else { -1.0 }) * m[0][c] * det(&minor)
    }).sum()
}

fn ev(form: &Form, vs: &[&[f64]]) -> f64 {        // road 1: sum of coefficient x minor
    form.iter().map(|(idx, c)| c * det(&idx.iter().map(|&i| vs.iter().map(|v| v[i]).collect()).collect())).sum()
}

fn ev_brute(form: &Form, vs: &[&[f64]]) -> f64 {  // road 2: alternating sum over orderings
    let mut t = 0.0;
    for (idx, c) in form {
        for (p, s) in perms(vs.len()) {
            let mut r = 1.0;
            for j in 0..idx.len() { r *= vs[p[j]][idx[j]]; }
            t += c * s * r;
        }
    }
    t
}

fn one(cs: &[f64]) -> Form {                      // one-form a1 dx^1 + a2 dx^2 + ...
    cs.iter().enumerate().filter(|(_, c)| **c != 0.0).map(|(i, c)| (vec![i], *c)).collect()
}
fn mk(t: &[(&[usize], f64)]) -> Form { t.iter().map(|(k, c)| (k.to_vec(), *c)).collect() }
fn f(v: f64) -> String { format!("{:.4}", v + 0.0) }
fn lst(m: &Form) -> String { format!("[{}]", m.values().map(|v| format!("'{}'", f(*v))).collect::<Vec<_>>().join(", ")) }

fn main() {
    let (x, y, z, t) = (0usize, 1usize, 2usize, 3usize);
    let dxdy = mk(&[(&[x, y], 1.0)]);
    // ---- 1. the rain band on the weather map: edge u, swept by the wind for 3 hours ----
    let (u, v) = ([120.0, 50.0], [30.0, 90.0]);
    let a = ev(&dxdy, &[&u, &v]);
    let c = [[0.0, 0.0], u, [u[0] + v[0], u[1] + v[1]], v];
    let shoe = 0.5 * (0..4).map(|i| { let k = (i + 1) % 4; c[i][0] * c[k][1] - c[k][0] * c[i][1] }).sum::<f64>();
    let grid = |h: f64| -> f64 {                  // count cell centres inside the swept band
        let mut n = 0.0;
        for i in 0..(150.0 / h) as usize {
            for j in 0..(140.0 / h) as usize {
                let (px, py) = ((i as f64 + 0.5) * h, (j as f64 + 0.5) * h);
                let s = (px * v[1] - py * v[0]) / a;
                let tt = (u[0] * py - u[1] * px) / a;
                if 0.0 <= s && s < 1.0 && 0.0 <= tt && tt < 1.0 { n += 1.0; }
            }
        }
        n * h * h
    };
    println!("map: dx^dy(u,v) swept area km2 {}  dx^dy(v,u) {}", f(a), f(ev(&dxdy, &[&v, &u])));
    println!("map: u1v2 u2v1 {} {}  shoelace {}  grid h=2 {}  grid h=1 {}", f(u[0] * v[1]), f(u[1] * v[0]), f(shoe),
             f(grid(2.0)), f(grid(1.0)));
    let (dt, dp) = (one(&[-0.04, 0.03]), one(&[0.01, 0.02]));
    let tp = wedge(&dt, &dp);
    println!("map: dT(u) dT(v) dp(u) dp(v) {} {} {} {}", f(ev(&dt, &[&u])), f(ev(&dt, &[&v])), f(ev(&dp, &[&u])), f(ev(&dp, &[&v])));
    println!("map: dT^dp coefficient {:.6}  on band {}  dp^dT on band {}", tp[&vec![x, y]], f(ev(&tp, &[&u, &v])),
             f(ev(&wedge(&dp, &dt), &[&u, &v])));
    assert!((a - shoe).abs() < 1e-9 && (ev(&dxdy, &[&v, &u]) + a).abs() < 1e-9);
    assert!((grid(1.0) - a).abs() < 0.01 * a);
    assert!((ev(&tp, &[&u, &v]) - (ev(&dt, &[&u]) * ev(&dp, &[&v]) - ev(&dt, &[&v]) * ev(&dp, &[&u]))).abs() < 1e-12);
    // ---- 2. a hillside field in the rain: three shadows kept separately ----
    let (uu, vv) = ([40.0, 10.0, 0.0], [-6.0, 24.0, 18.0]);
    let sh = [ev(&mk(&[(&[y, z], 1.0)]), &[&uu, &vv]), -ev(&mk(&[(&[x, z], 1.0)]), &[&uu, &vv]), ev(&dxdy, &[&uu, &vv])];
    let area = sh.iter().map(|s| s * s).sum::<f64>().sqrt();
    let dot = |p: &[f64], q: &[f64]| p.iter().zip(q).map(|(a, b)| a * b).sum::<f64>();
    let lag = (dot(&uu, &uu) * dot(&vv, &vv) - dot(&uu, &vv).powi(2)).sqrt();
    let q = [1.5, -2.0, -6.0];                    // rain: mm/h east, north, up (falling)
    let rain = mk(&[(&[y, z], q[0]), (&[x, z], -q[1]), (&[x, y], q[2])]);   // q2 dz^dx = -q2 dx^dz
    let w = ev(&rain, &[&uu, &vv]);
    let prism = det(&vec![q.to_vec(), uu.to_vec(), vv.to_vec()]);   // water slab swept in one hour
    println!("hill: shadows dy^dz dz^dx dx^dy m2 {} {} {}", f(sh[0]), f(sh[1]), f(sh[2]));
    println!("hill: true area {}  Lagrange {}  u.v {}", f(area), f(lag), f(dot(&uu, &vv)));
    println!("hill: rain per shadow L/h {} {} {}", f(q[0] * sh[0]), f(q[1] * sh[1]), f(q[2] * sh[2]));
    println!("hill: rain form on field L/h {}  brute {}  prism {}", f(w), f(ev_brute(&rain, &[&uu, &vv])), f(prism));
    println!("hill: depth on slope mm/h {}  level gauge mm/h {}", f(-w / area), f(-q[2]));
    assert!((area - lag).abs() < 1e-9 && (w - prism).abs() < 1e-9);
    assert!((w - ev_brute(&rain, &[&uu, &vv])).abs() < 1e-9);
    let cross = [uu[1] * vv[2] - uu[2] * vv[1], uu[2] * vv[0] - uu[0] * vv[2], uu[0] * vv[1] - uu[1] * vv[0]];   // U x V by components
    assert!((0..3).all(|i| (sh[i] - cross[i]).abs() < 1e-9) && ((0..3).map(|i| q[i] * sh[i]).sum::<f64>() - w).abs() < 1e-9);
    // ---- 3. what breaks ----
    println!("wrong: no sign flip, u1v2+u2v1 {}", f(u[0] * v[1] + u[1] * v[0]));
    println!("wrong: dz^dx read as dx^dz {}", f(q[0] * sh[0] + q[1] * (-sh[1]) + q[2] * sh[2]));
    println!("wrong: ground shadow only {}  water all positive {}", f(q[2] * sh[2]), f((0..3).map(|i| (q[i] * sh[i]).abs()).sum()));
    println!("wrong: edges swapped {}", f(ev(&rain, &[&vv, &uu])));
    let (e1, f1, f2) = ([1.0, 0.0], [0.0, 1.0], [0.0, -1.0]);
    let un = |p: &[f64], q: &[f64]| ev(&dxdy, &[p, q]).abs();
    println!("fails: unsigned area of (e1,f1)+(e1,f2) {}  of (e1,f1+f2) {}", f(un(&e1, &f1) + un(&e1, &f2)),
             f(un(&e1, &[f1[0] + f2[0], f1[1] + f2[1]])));
    // ---- 4. the sign rule ----
    let (al, be) = (one(&[1.0, 2.0, 0.0]), one(&[0.0, 3.0, -1.0]));
    let (ab, ba) = (wedge(&al, &be), wedge(&be, &al));
    println!("rule: a^b {}  b^a {}", lst(&ab), lst(&ba));
    let dz = one(&[0.0, 0.0, 1.0]);
    println!("rule: a^a terms {}  dz^rain {}  rain^dz {}", wedge(&al, &al).len(), f(wedge(&dz, &rain)[&vec![x, y, z]]),
             f(wedge(&rain, &dz)[&vec![x, y, z]]));
    let (p0, p1) = ([3.0, -1.0, 2.0], [0.5, 4.0, 1.0]);
    assert!(ab.iter().all(|(k, v)| (v + ba[k]).abs() < 1e-12) && wedge(&al, &al).is_empty());
    assert!((ev(&ab, &[&p0, &p1]) - (ev(&al, &[&p0]) * ev(&be, &[&p1]) - ev(&al, &[&p1]) * ev(&be, &[&p0]))).abs() < 1e-12);
    // ---- 5. four dimensions: x, y, z, t ----
    let sig = wedge(&one(&[1.0, 2.0, 0.0, 0.0]), &one(&[0.0, 0.0, 3.0, -1.0]));
    let tau = mk(&[(&[x, y], 1.0), (&[z, t], 1.0)]);
    let tt = wedge(&tau, &tau);
    let cnt: Vec<usize> = [2usize, 3, 4, 5].iter()
        .map(|&n| wedge(&one(&vec![1.0; n]), &one(&(1..=n).map(|i| (i * i) as f64).collect::<Vec<_>>())).len()).collect();
    println!("4D: components of a two-form, n = 2 3 4 5: [{}]", cnt.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    assert!(cnt.iter().zip([2usize, 3, 4, 5]).all(|(c, n)| *c == n * (n - 1) / 2));
    println!("4D: sig^sig {} terms;  tau^tau {}", wedge(&sig, &sig).len(), f(tt[&vec![x, y, z, t]]));
    let q4: Vec<Vec<f64>> = (0..4).map(|i| (0..4).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let q4r: Vec<&[f64]> = q4.iter().map(|r| &r[..]).collect();
    println!("4D: tau^tau on the unit box, brute {}", f(ev_brute(&tt, &q4r)));
    assert!(wedge(&sig, &sig).is_empty() && (ev_brute(&tt, &q4r) - 2.0).abs() < 1e-12);
    // ---- 6. try changing ----
    println!("try: wind along the edge {}  parallel isotherms {}", f(ev(&dxdy, &[&u, &[60.0, 25.0]])),
             f(ev(&wedge(&one(&[-0.02, -0.04]), &dp), &[&u, &v])));
    println!("try: crosswind north -4 {}", f(ev(&mk(&[(&[y, z], 1.5), (&[x, z], 4.0), (&[x, y], -6.0)]), &[&uu, &vv])));
    println!("ALL CHECKS PASS");
}
