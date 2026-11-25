// Systems of conservation laws -- the same check as the Python, in Rust.  No crates.
// Dam break on a flat channel: water 2 m deep behind the gate, 1 m in front, both at
// rest, g = 9.81 m/s^2.  Unknowns per metre of channel width: depth h, flow hu, dye h*phi.
const G: f64 = 9.81;
const HL: f64 = 2.0;
const HR: f64 = 1.0;
const T: f64 = 5.0;
fn sq(x: f64) -> f64 { x.sqrt() }
fn bore_u(h: f64, h0: f64) -> f64 { (h - h0) * sq(G / 2.0 * (h + h0) / (h * h0)) } // Hugoniot locus
fn u_left(h: f64) -> f64 { // wave curve of family 1 from the reservoir: fan if h < HL, else shock
    if h <= HL { 2.0 * (sq(G * HL) - sq(G * h)) } else { -bore_u(h, HL) }
}
fn u_right(h: f64) -> f64 { // wave curve of family 3 into the still water ahead
    if h >= HR { bore_u(h, HR) } else { -2.0 * (sq(G * HR) - sq(G * h)) }
}
fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 {
    for _ in 0..200 {
        let m = 0.5 * (a + b);
        if (f(a) > 0.0) == (f(m) > 0.0) { a = m } else { b = m }
    }
    0.5 * (a + b)
}
fn flux(u: &[f64; 3]) -> [f64; 3] {
    let (h, m, z) = (u[0], u[1], u[2]);
    [m, m * m / h + G * h * h / 2.0, m * z / h]
}
fn lam(v: &[f64; 3], k: f64) -> f64 { v[1] / v[0] + (k - 2.0) * sq(G * v[0]) }
struct S { hs: f64, us: f64, cs: f64, cl: f64, s: f64 }
fn exact(p: &S, x: f64, t: f64) -> (f64, f64, f64) {
    if x < -p.cl * t { return (HL, 0.0, 1.0); }
    if x < (p.us - p.cs) * t {
        let c = (2.0 * p.cl - x / t) / 3.0;
        return (c * c / G, x / t + c, 1.0);
    }
    if x < p.us * t { return (p.hs, p.us, 1.0); }
    if x < p.s * t { return (p.hs, p.us, 0.0); }
    (HR, 0.0, 0.0)
}
fn grid(p: &S, n: usize) -> (f64, f64, f64, f64, f64, f64) {
    let dx = 100.0 / n as f64;
    let xs: Vec<f64> = (0..n).map(|i| -50.0 + (i as f64 + 0.5) * dx).collect();
    let mut w: Vec<[f64; 3]> = xs.iter().map(|&x| if x < 0.0 { [HL, 0.0, HL] } else { [HR, 0.0, 0.0] }).collect();
    let mut t = 0.0;
    while t < T - 1e-12 {
        let sp: Vec<f64> = w.iter().map(|v| (v[1] / v[0]).abs() + sq(G * v[0])).collect();
        let dt = (0.45 * dx / sp.iter().cloned().fold(f64::MIN, f64::max)).min(T - t);
        let mut wx = vec![w[0]]; wx.extend(w.iter().cloned()); wx.push(w[n - 1]);
        let fx: Vec<[f64; 3]> = wx.iter().map(flux).collect();
        let mut spx = vec![sp[0]]; spx.extend(sp.iter().cloned()); spx.push(sp[n - 1]);
        let mut fh = Vec::with_capacity(n + 1);
        for i in 0..=n {
            let a = spx[i].max(spx[i + 1]);
            let mut f = [0.0; 3];
            for k in 0..3 { f[k] = 0.5 * (fx[i][k] + fx[i + 1][k]) - 0.5 * a * (wx[i + 1][k] - wx[i][k]); }
            fh.push(f);
        }
        for i in 0..n { for k in 0..3 { w[i][k] = w[i][k] - dt / dx * (fh[i + 1][k] - fh[i][k]); } }
        t += dt;
    }
    let err = w.iter().zip(&xs).map(|(v, &x)| (v[0] - exact(p, x, T).0).abs()).sum::<f64>() * dx;
    let fan = w.iter().zip(&xs).filter(|(_, &x)| x < -5.0).map(|(v, &x)| (v[0] - exact(p, x, T).0).abs()).sum::<f64>() * dx;
    let mid: Vec<f64> = w.iter().zip(&xs).filter(|(_, &x)| -8.0 <= x && x <= 2.0).map(|(v, _)| v[0]).collect();
    let dye = w.iter().zip(&xs).find(|(v, _)| v[2] / v[0] < 0.5).unwrap().1;
    let vol = w.iter().map(|v| v[0]).sum::<f64>() * dx;
    let ink = w.iter().map(|v| v[2]).sum::<f64>() * dx;
    (err, fan, mid.iter().sum::<f64>() / mid.len() as f64, *dye, vol, ink)
}
fn main() {
    let hs = bisect(&|h| u_left(h) - u_right(h), 0.5, 3.0);
    let us = u_right(hs);
    let (cl, cs, cr) = (sq(G * HL), sq(G * hs), sq(G * HR));
    let s_mass = hs * us / (hs - HR);
    let s_mom = (hs * us * us + G * (hs * hs - HR * HR) / 2.0) / (hs * us);
    println!("middle state: depth {:.4} m, speed {:.4} m/s", hs, us);
    println!("in short: middle {:.3} m at {:.3} m/s; bore {:.3} m high at {:.3} m/s", hs, us, hs - HR, s_mass);
    println!("hand: c_L {:.4}, c_* {:.4}, c_R {:.4} m/s; h*u* {:.4} m^2/s; h* - h_R {:.4} m; bore factor {:.4} per s",
             cl, cs, cr, hs * us, hs - HR, sq(G / 2.0 * (hs + HR) / (hs * HR)));
    println!("bore speed from mass {:.4} m/s, from momentum {:.4} m/s", s_mass, s_mom);
    // Road 1: eigenvalues by formula, against a Jacobian built by centred differences
    let (u, e) = ([hs, hs * us, hs * 0.5], 1e-6);
    let mut j = [[0.0; 3]; 3];
    for c in 0..3 {
        let (mut up, mut um) = (u, u); up[c] += e; um[c] -= e;
        let (fp, fm) = (flux(&up), flux(&um));
        for i in 0..3 { j[i][c] = (fp[i] - fm[i]) / (2.0 * e); }
    }
    let lams = [us - cs, us, us + cs];
    let vecs = [[1.0, us - cs, 0.5], [0.0, 0.0, 1.0], [1.0, us + cs, 0.5]];
    let mut res: f64 = 0.0;
    for (l, r) in lams.iter().zip(&vecs) { for i in 0..3 {
        let jr: f64 = (0..3).map(|k| j[i][k] * r[k]).sum();
        res = res.max((jr - l * r[i]).abs());
    } }
    println!("speeds in the middle: {:.4}, {:.4}, {:.4} m/s; largest |J r - lam r| {:.6}", lams[0], lams[1], lams[2], res);
    let mut dl = [0.0; 3];
    for k in 0..3 {
        let r = vecs[k];
        let (mut a, mut b) = (u, u);
        for i in 0..3 { a[i] = u[i] + e * r[i]; b[i] = u[i] - e * r[i]; }
        dl[k] = (lam(&a, k as f64 + 1.0) - lam(&b, k as f64 + 1.0)) / (2.0 * e);
    }
    println!("grad lam . r: family 1 {:.4}, family 2 {:.4}, family 3 {:.4} (per s)", dl[0], dl[1], dl[2]);
    println!("family 1 by formula {:.4}, family 3 {:.4}", -1.5 * cs / hs, 1.5 * cs / hs);
    // Lax entropy test on the bore, and the Riemann invariants
    println!("Lax: {:.4} > {:.4} > {:.4}, and {:.4} > {:.4} m/s", us + cs, s_mass, cr, s_mass, us);
    println!("u + 2c: reservoir {:.4}, middle {:.4} m/s", 2.0 * cl, us + 2.0 * cs);
    println!("u - 2c: middle {:.4}, ahead {:.4}; change across bore {:.4} m/s", us - 2.0 * cs, -2.0 * cr, us - 2.0 * cs + 2.0 * cr);
    let edges = [-cl * T, (us - cs) * T, us * T, s_mass * T];
    println!("at 5 s: fan from {:.2} to {:.2} m, dye front {:.2} m, bore {:.2} m", edges[0], edges[1], edges[2], edges[3]);
    let p = S { hs, us, cs, cl, s: s_mass };
    let (hf, uf, _) = exact(&p, -15.0, T);
    println!("fan at -15 m, 5 s: x/t -3.0 m/s, c {:.4} m/s, u {:.4} m/s, depth {:.4} m", (2.0 * cl + 3.0) / 3.0, uf, hf);
    // Road 2: the fan obeys both equations; centred-difference residual at x = -15 m
    let q = |x: f64, t: f64| { let (h, v, _) = exact(&p, x, t); [h, h * v, h * v * v + G * h * h / 2.0] };
    let mut row = Vec::new();
    for d in [0.1, 0.05] {
        let r1 = (q(-15.0, T + d)[0] - q(-15.0, T - d)[0] + q(-15.0 + d, T)[1] - q(-15.0 - d, T)[1]) / (2.0 * d);
        let r2 = (q(-15.0, T + d)[1] - q(-15.0, T - d)[1] + q(-15.0 + d, T)[2] - q(-15.0 - d, T)[2]) / (2.0 * d);
        row.push((r1.abs(), r2.abs()));
    }
    println!("fan residual at -15 m, 5 s, steps 0.1 and 0.05: mass {:.6}, {:.6} m/s; momentum {:.6}, {:.6} m^2/s^2",
             row[0].0, row[1].0, row[0].1, row[1].1);
    // Road 3: a grid that knows nothing of fans or bores (Rusanov's averaged flux)
    let (mut errs, mut fans) = (Vec::new(), Vec::new());
    let (mut mid, mut dye, mut vol, mut ink) = (0.0, 0.0, 0.0, 0.0);
    for n in [200usize, 400, 800] {
        let g = grid(&p, n);
        errs.push(g.0); fans.push(g.1); mid = g.2; dye = g.3; vol = g.4; ink = g.5;
        println!("grid {} cells: depth error {:.4} m^2, middle depth {:.4} m, dye front {:.2} m, water {:.4} m^2, dye {:.4} m^2",
                 n, g.0, g.2, g.3, g.4, g.5);
    }
    let (r1, r2) = (errs[0] / errs[1], errs[1] / errs[2]);
    println!("error ratio per halving: {:.3} and {:.3}; observed order {:.2} and {:.2}", r1, r2, r1.log2(), r2.log2());
    let bores: Vec<f64> = errs.iter().zip(&fans).map(|(a, b)| a - b).collect();
    for (name, v) in [("fan side, x < -5 m:", &fans), ("bore side, x >= -5 m:", &bores)] {
        println!("{} depth error {:.4}, {:.4}, {:.4} m^2; ratio per halving {:.3} and {:.3}", name, v[0], v[1], v[2], v[0] / v[1], v[1] / v[2]);
    }
    // What breaks
    let h2 = bisect(&|h| -bore_u(h, HL) - bore_u(h, HR), 0.5, 3.0);
    let u2 = bore_u(h2, HR);
    let s1 = h2 * u2 / (h2 - HL);
    println!("breaks: two shocks: depth {:.4} m, upstream jump at {:.4} m/s, but Lax needs {:.4} > s1 > {:.4}", h2, s1, -cl, u2 - sq(G * h2));
    let uvel = |h: f64| (h - HR) * sq(2.0 * G / (h + HR));
    let h3 = bisect(&|h| u_left(h) - uvel(h), 0.5, 3.0);
    println!("breaks: conserve speed, not momentum: depth {:.4} m, bore {:.4} m/s", h3, h3 * uvel(h3) / (h3 - HR));
    let cb = sq(G * 1.5);
    println!("breaks: linearise about 1.5 m: speed {:.4} m/s, bore {:.4} m/s", G * 0.5 / cb, cb);
    println!("breaks: dye carried at the bore speed: {:.2} m at 5 s, not {:.2} m", s_mass * T, us * T);
    println!("breaks: dry channel ahead: no middle state; front at 2 c_L = {:.4} m/s, where c = 0 and lam1 = lam2 = lam3", 2.0 * cl);
    let hh: Vec<f64> = (0..11).map(|i| 1.0 + i as f64 / 10.0).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, depth h m: {}", join(hh.iter().map(|h| format!("{:.1}", h)).collect()));
    println!("chart, family 1:  {}", join(hh.iter().map(|&h| format!("{:.2}", u_left(h))).collect()));
    println!("chart, family 3:  {}", join(hh.iter().map(|&h| format!("{:.2}", u_right(h))).collect()));
    println!("bars, depth at 5 s: {}", join((-6..=6).map(|i| format!("{}:{:.3}", i * 5, exact(&p, (i * 5) as f64, T).0)).collect()));
    println!("figure, x at 5 s: {:.2} {:.2} {:.2} {:.2}", edges[0], edges[1], edges[2], edges[3]);
    assert!((hs - 1.4538).abs() < 1e-4 && (us - 1.3058).abs() < 1e-4);            // the spec's numbers
    assert!((s_mass - s_mom).abs() < 1e-9 && (us + 2.0 * cs - 2.0 * cl).abs() < 1e-9); // Hugoniot, invariant
    assert!(res < 1e-6 && (dl[0] + 1.5 * cs / hs).abs() < 1e-6 && dl[1].abs() < 1e-6 && (dl[2] - 1.5 * cs / hs).abs() < 1e-6);
    assert!(us + cs > s_mass && s_mass > cr && s_mass > us && s1 > -cl); // Lax fails
    assert!((0..2).all(|k| { let r = if k == 0 { row[0].0 / row[1].0 } else { row[0].1 / row[1].1 }; 3.5 < r && r < 4.5 }));
    assert!(errs[0] > errs[1] && errs[1] > errs[2] && (mid - hs).abs() < 0.01 && (dye - us * T).abs() < 1.0);
    assert!(bores[0] / bores[1] > 1.85 && bores[1] / bores[2] > 1.85 && fans[0] / fans[1] < 1.7 && fans[1] / fans[2] < 1.7);
    assert!((vol - 150.0).abs() < 1e-9 && (ink - 100.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
