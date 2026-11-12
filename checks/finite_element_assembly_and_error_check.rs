// Assembly and error: a 4 m cable at tension 2000 N carries planters, 20 + 10x N/m.
// Anchored at x = 0 (essential: u = 0); a ring on a post at x = 4 m is pulled down by
// 40 N (natural: T u'(4) = 40). Linear elements. Rust std only.
const T: f64 = 2000.0; const L: f64 = 4.0; const P: f64 = 40.0; const PI: f64 = 3.141592653589793;
const XS: f64 = 4.0 / 3.0; const Q: f64 = 100.0;

fn u_ex(x: f64) -> f64 { (200.0 * x - 10.0 * x * x - 5.0 * x * x * x / 3.0) / T }
fn du_ex(x: f64) -> f64 { (200.0 - 20.0 * x - 5.0 * x * x) / T }

/// Python-style e-notation: 5.998e-03, 7.158e+08.
fn fe(x: f64, prec: usize) -> String {
    let s = format!("{:.*e}", prec, x); let (m, e) = s.split_once('e').unwrap(); let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn assemble(n: usize, a: f64, b: f64, p_end: f64, lamps: &[(f64, f64)], add: bool) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let h = L / n as f64;
    let (mut di, mut off, mut f) = (vec![0.0; n + 1], vec![0.0; n], vec![0.0; n + 1]);
    for e in 0..n {
        let k = T / h;
        if add { di[e] += k; di[e + 1] += k; } else { di[e] = k; di[e + 1] = k; } // bug: overwrite
        off[e] = -k;
        let (fl, fr) = (a + b * e as f64 * h, a + b * (e + 1) as f64 * h);
        f[e] += h * (2.0 * fl + fr) / 6.0;           // integral of f times the left hat
        f[e + 1] += h * (fl + 2.0 * fr) / 6.0;       // integral of f times the right hat
    }
    for &(q, xs) in lamps {                          // a point load shared by the two hats
        let e = ((xs / h) as usize).min(n - 1); let t = (xs - e as f64 * h) / h;
        f[e] += q * (1.0 - t); f[e + 1] += q * t;
    }
    f[n] += p_end; (di, off, f)                      // natural condition: one load entry
}

/// Tridiagonal elimination. Returns (solution or None, pivots up to the first zero).
fn thomas(di: &[f64], off: &[f64], f: &[f64]) -> (Option<Vec<f64>>, Vec<f64>) {
    let (m, mut d, mut r) = (di.len(), di.to_vec(), f.to_vec());
    for i in 1..m {
        if d[i - 1] == 0.0 { return (None, d[..i].to_vec()); }
        let w = off[i - 1] / d[i - 1]; d[i] -= w * off[i - 1]; r[i] -= w * r[i - 1];
    }
    if d[m - 1] == 0.0 { return (None, d); }
    let mut x = vec![0.0; m]; x[m - 1] = r[m - 1] / d[m - 1];
    for i in (0..m - 1).rev() { x[i] = (r[i] - off[i] * x[i + 1]) / d[i]; }
    (Some(x), d)
}

fn solve(n: usize, a: f64, b: f64, p_end: f64, lamps: &[(f64, f64)]) -> Vec<f64> {
    let (di, off, f) = assemble(n, a, b, p_end, lamps, true);
    let (x, _) = thomas(&di[1..], &off[1..], &f[1..]); // essential: drop node 0
    let mut u = vec![0.0]; u.extend(x.unwrap()); u
}

fn gauss() -> [(f64, f64); 4] {
    let g1 = (3.0 / 7.0 - 2.0 / 7.0 * (6.0f64 / 5.0).sqrt()).sqrt();
    let g2 = (3.0 / 7.0 + 2.0 / 7.0 * (6.0f64 / 5.0).sqrt()).sqrt();
    let (w1, w2) = ((18.0 + 30.0f64.sqrt()) / 36.0, (18.0 - 30.0f64.sqrt()) / 36.0);
    [(-g2, w2), (-g1, w1), (g1, w1), (g2, w2)]
}

/// RMS slope error and RMS sag error over the cable, element by element.
fn errors(u: &[f64], uf: &dyn Fn(f64) -> f64, duf: &dyn Fn(f64) -> f64, cuts: &[f64]) -> (f64, f64) {
    let (n, mut s1, mut s0) = (u.len() - 1, 0.0, 0.0); let h = L / n as f64;
    for e in 0..n {
        let (xa, xb) = (e as f64 * h, (e + 1) as f64 * h);
        let mut pts = vec![xa]; for &c in cuts { if xa < c && c < xb { pts.push(c); } } pts.push(xb);
        for j in 0..pts.len() - 1 {
            let (p, q) = (pts[j], pts[j + 1]);
            for &(z, w) in gauss().iter() {
                let x = 0.5 * (p + q) + 0.5 * (q - p) * z; let t = (x - xa) / h;
                let d1 = duf(x) - (u[e + 1] - u[e]) / h;
                let d0 = uf(x) - u[e] * (1.0 - t) - u[e + 1] * t;
                s1 += 0.5 * (q - p) * w * d1 * d1; s0 += 0.5 * (q - p) * w * d0 * d0;
            }
        }
    }
    ((s1 / L).sqrt(), (s0 / L).sqrt())
}

fn join(v: &[f64], f: &dyn Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    // ---- four element matrices added into one system ----
    let (di, off, f) = assemble(4, 20.0, 10.0, P, &[], true);
    println!("element matrix, N/m  {}", join(&[T, -T, -T, T], &|v| format!("{:7.0}", v)));
    for i in 0..5usize {
        let row: Vec<f64> = (0..5usize).map(|j| if j == i { di[i] } else if i.abs_diff(j) == 1 { off[i.min(j)] } else { 0.0 }).collect();
        println!("K row {}              {}", i, join(&row, &|v| format!("{:7.0}", v)));
    }
    println!("nonzeros of 25       {:7}", 3 * 5 - 2);
    println!("F, N                 {}", join(&f, &|v| format!("{:7.3}", v)));
    let u = solve(4, 20.0, 10.0, P, &[]);
    println!("FE sag at nodes, mm  {}", join(&u, &|v| format!("{:7.3}", 1000.0 * v)));
    let ex: Vec<f64> = (0..5).map(|i| u_ex(i as f64)).collect();
    println!("exact sag, mm        {}", join(&ex, &|v| format!("{:7.3}", 1000.0 * v)));
    let (mut carried, mut tele, mut acc) = (vec![0.0; 4], vec![0.0], 0.0);
    for i in (0..4).rev() { acc += f[i + 1]; carried[i] = acc; }
    for i in 0..4 { let last = tele[i]; tele.push(last + carried[i] / T); }
    println!("load carried, N      {}", join(&carried, &|v| format!("{:7.3}", v)));
    println!("telescoped sag, mm   {}", join(&tele, &|v| format!("{:7.3}", 1000.0 * v)));
    let r = di[0] * u[0] + off[0] * u[1] - f[0];
    println!("anchor force, N      {:9.3}   slope there {:.3}", r, -r / T);
    println!("thomas flops 8n-7    n=4: {}   n=1024: {}   dense 2n^3/3: {}", 8 * 4 - 7, 8 * 1024 - 7, fe(2.0 * 1024.0 * 1024.0 * 1024.0 / 3.0, 3));
    let mut se = [0.0; 4];
    for e in 0..4 { for &(z, w) in gauss().iter() { se[e] += 0.5 * w * (du_ex(e as f64 + 0.5 + 0.5 * z) - (u[e + 1] - u[e])); } }
    let mut orth: f64 = 0.0; for i in 1..5 { orth = orth.max((se[i - 1] - if i < 4 { se[i] } else { 0.0 }).abs()); }
    println!("orthogonality, max   {}", fe(orth, 1));
    // ---- what breaks ----
    let (dov, oov, fov) = assemble(4, 20.0, 10.0, P, &[], false);
    let (_, piv_over) = thomas(&dov[1..], &oov[1..], &fov[1..]);
    let no_p = solve(4, 20.0, 10.0, 0.0, &[]);
    let (x3, _) = thomas(&di[1..4], &off[1..3], &f[1..4]);
    let (_, piv) = thomas(&di, &off, &f);
    println!("wrong: overwrite, zero pivot in row {} of 4", piv_over.len());
    println!("wrong: drop 40 N, tip mm    {:9.3}", 1000.0 * no_p[4]);
    println!("wrong: ring fixed, mid mm   {:9.3}", 1000.0 * x3.unwrap()[1]);
    println!("wrong: no anchor, zero pivot in row {} of 5", piv.len());
    // ---- error against element size ----
    let mut c2 = 0.0; for &(z, w) in gauss().iter() { let c = (20.0 + 10.0 * (2.0 + 2.0 * z)) / T; c2 += 2.0 * w * c * c; }
    let rms_curv = (c2 / L).sqrt(); println!("RMS load, N/m        {:9.3}   RMS u'', 1/m {}", T * rms_curv, fe(rms_curv, 4));
    println!("   n      h slope err     bound ratio sag err mm     bound ratio  ord1  ord2 node err m");
    let (mut rows, mut prev): (Vec<(usize, f64, f64, f64, f64, f64, f64)>, Option<(f64, f64)>) = (vec![], None);
    for k in 2..11 {
        let n = 1usize << k; let h = L / n as f64; let u = solve(n, 20.0, 10.0, P, &[]);
        let (e1, e0) = errors(&u, &u_ex, &du_ex, &[]);
        let (b1, b0) = (h / PI * rms_curv, (h / PI) * (h / PI) * rms_curv);
        let mut node: f64 = 0.0; for i in 0..=n { node = node.max((u[i] - u_ex(i as f64 * h)).abs()); }
        let (o1, o0) = match prev { Some((p1, p0)) => ((p1 / e1).log2(), (p0 / e0).log2()), None => (0.0, 0.0) };
        let ords = if prev.is_some() { format!("{:5.3} {:5.3}", o1, o0) } else { "    -     -".to_string() };
        println!("{:4} {:6.4} {} {} {:5.3} {} {} {:5.3} {} {:>8}", n, h, fe(e1, 3), fe(b1, 3), b1 / e1,
                 fe(1000.0 * e0, 3), fe(1000.0 * b0, 3), b0 / e0, ords, fe(node, 1));
        rows.push((n, e1, b1, e0, b0, o1, o0)); prev = Some((e1, e0));
    }
    let mut lamp: Vec<(usize, f64, f64)> = vec![];
    for k in 2..11 {
        let n = 1usize << k; let h = L / n as f64; let u = solve(n, 0.0, 0.0, 0.0, &[(Q, XS)]);
        let (e1, _) = errors(&u, &|x: f64| Q * x.min(XS) / T, &|x: f64| if x < XS { Q / T } else { 0.0 }, &[XS]);
        lamp.push((n, e1, Q / T * (2.0 * h / 9.0 / L).sqrt()));
    }
    println!("lamp n=4 slope err   {}  closed form {}", fe(lamp[0].1, 4), fe(lamp[0].2, 4));
    println!("lamp order 1024/512  {:.3}", (lamp[7].1 / lamp[8].1).log2());
    let uu = solve(4, 20.0, 0.0, 0.0, &[]);
    let (e1u, _) = errors(&uu, &|x: f64| (80.0 * x - 10.0 * x * x) / T, &|x: f64| (80.0 - 20.0 * x) / T, &[]);
    let cf = 20.0 / (2.0 * T) / 3.0f64.sqrt();
    println!("uniform n=4 slope    {}  closed form {}", fe(e1u, 6), fe(cf, 6));
    let (mut s2, be) = (0.0, 5.0 / (3.0 * T)); // planters, n = 4: error on element e is s(1 - s)(a + be s)
    for e in 0..4 { let a = be + (10.0 + 5.0 * e as f64) / T; s2 += (a * a + a * be) / 30.0 + be * be / 105.0; } // its exact integral
    let cs = (s2 / L).sqrt();
    println!("planter n=4 sag, mm  {}  closed form {}", fe(1000.0 * rows[0].3, 6), fe(1000.0 * cs, 6));
    let nodes: Vec<String> = (0..5).map(|i| format!("({},{:.1})", 20 + 80 * i, 40.0 + 500.0 * u_ex(i as f64))).collect();
    println!("figure, node px {}", nodes.join(" "));
    let curve: Vec<f64> = (0..17).map(|j| 40.0 + 500.0 * u_ex(0.25 * j as f64)).collect();
    println!("figure, curve px {}", join(&curve, &|v| format!("{:.1}", v)));
    let chart = |name: &str, v: Vec<f64>| println!("chart, {:<14}{}", name, join(&v, &|x| format!("{:6.2}", x.log10())));
    chart("log10 h", rows.iter().map(|r| L / r.0 as f64).collect());
    chart("log10 slope", rows.iter().map(|r| r.1).collect());
    chart("log10 sag", rows.iter().map(|r| r.3).collect());
    chart("log10 lamp", lamp.iter().map(|r| r.1).collect());
    for i in 0..5 { assert!((u[i] - u_ex(i as f64)).abs() < 1e-15, "nodes = exact sag"); }
    for i in 0..5 { assert!((u[i] - tele[i]).abs() < 1e-15, "force balance = the solve"); }
    assert!((r + 20.0 * 4.0 + 5.0 * 16.0 + P).abs() < 1e-9, "anchor holds all 200 N");
    assert!(rows.iter().all(|r| r.1 <= r.2 && r.3 <= r.4), "true errors under the bounds");
    assert!((rows[8].5 - 1.0).abs() < 0.01 && (rows[8].6 - 2.0).abs() < 0.01, "orders 1 and 2");
    assert!(lamp.iter().all(|r| (r.1 - r.2).abs() < 1e-12), "lamp error = its closed form");
    assert!((e1u - cf).abs() < 1e-15, "error integrator = the uniform-load closed form");
    assert!((rows[0].3 - cs).abs() < 1e-15, "planters' sag error = its exact integral");
    assert!(orth < 1e-15 && piv.len() == 5 && piv_over.len() == 2, "orthogonality; zero pivots");
    println!("ALL CHECKS PASS");
}
