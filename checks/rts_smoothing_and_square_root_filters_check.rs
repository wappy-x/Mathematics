// RTS smoothing and square-root filters on the balancing pendulum -- the same check as rts_smoothing_and_square_root_filters_check.py,
// in Rust, no crates. Roads: RTS vs batch conditioning on all 50 readings, both vs 2000 simulated runs; single-precision updates
// vs double precision.
type M2 = [[f64; 2]; 2]; type V2 = [f64; 2];
const L: f64 = 9.81 / 16.0; const SA: f64 = 1.0; const SR: f64 = 0.005; const N: usize = 50;
const R: f64 = SR * SR; const P0: M2 = [[0.0025, 0.0], [0.0, 0.25]];
struct Md { f: M2, g: V2, gu: V2 }
struct Rng { s: u64 }                                       // SplitMix64 bits, Box-Muller normals (as on The Kalman filter)
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn n(&mut self) -> f64 { let a = 1.0 - self.u(); (-2.0 * a.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.u()).cos() }
}
fn mm(a: &M2, b: &M2) -> M2 { std::array::from_fn(|i| std::array::from_fn(|j| a[i][0] * b[0][j] + a[i][1] * b[1][j])) }
fn tr(a: &M2) -> M2 { [[a[0][0], a[1][0]], [a[0][1], a[1][1]]] }
fn add(a: &M2, b: &M2, s: f64) -> M2 { std::array::from_fn(|i| std::array::from_fn(|j| a[i][j] + s * b[i][j])) }
fn inv(a: &M2) -> M2 { let d = a[0][0] * a[1][1] - a[0][1] * a[1][0]; [[a[1][1] / d, -a[0][1] / d], [-a[1][0] / d, a[0][0] / d]] }
fn mv(a: &M2, v: V2) -> V2 { [a[0][0] * v[0] + a[0][1] * v[1], a[1][0] * v[0] + a[1][1] * v[1]] }
fn qm(m: &Md, q: f64) -> M2 { std::array::from_fn(|i| std::array::from_fn(|j| q * SA * SA * m.g[i] * m.g[j])) }
fn fstep(m: &Md, x: V2, p: &M2, u: f64, y: f64, q: f64) -> (V2, M2, V2, M2) {   // one predict-and-correct step
    let fx = mv(&m.f, x); let xm = [fx[0] + m.gu[0] * u, fx[1] + m.gu[1] * u]; let pm = add(&mm(&mm(&m.f, p), &tr(&m.f)), &qm(m, q), 1.0);
    let s = pm[0][0] + R; let k = [pm[0][0] / s, pm[1][0] / s]; let nu = y - xm[0];
    (xm, pm, [xm[0] + k[0] * nu, xm[1] + k[1] * nu], std::array::from_fn(|i| std::array::from_fn(|j| pm[i][j] - k[i] * pm[0][j])))
}
struct Fw { xf: Vec<V2>, pf: Vec<M2>, xm: Vec<V2>, pm: Vec<M2> }
fn filt(m: &Md, ys: &[f64], us: &[f64], q: f64) -> Fw {     // forward pass; index 0 is the start, 1..N the readings
    let mut w = Fw { xf: vec![[0.0, 0.0]], pf: vec![P0], xm: vec![[0.0; 2]], pm: vec![[[0.0; 2]; 2]] };
    for k in 1..=N { let (a, b, c, d) = fstep(m, w.xf[k - 1], &w.pf[k - 1], us[k], ys[k], q); w.xm.push(a); w.pm.push(b); w.xf.push(c); w.pf.push(d); }
    w
}
fn smooth(m: &Md, w: &Fw, use_u: bool) -> (Vec<V2>, Vec<M2>, Vec<M2>) {   // the RTS backward pass
    let (mut xs, mut ps, mut cs) = (vec![[0.0; 2]; N + 1], vec![[[0.0; 2]; 2]; N + 1], vec![[[0.0; 2]; 2]; N + 1]); xs[N] = w.xf[N]; ps[N] = w.pf[N];
    for k in (0..N).rev() {
        let c = mm(&mm(&w.pf[k], &tr(&m.f)), &inv(&w.pm[k + 1])); cs[k] = c;
        let pred = if use_u { w.xm[k + 1] } else { mv(&m.f, w.xf[k]) };
        let d = mv(&c, [xs[k + 1][0] - pred[0], xs[k + 1][1] - pred[1]]); xs[k] = [w.xf[k][0] + d[0], w.xf[k][1] + d[1]];
        ps[k] = add(&w.pf[k], &mm(&mm(&c, &add(&ps[k + 1], &w.pm[k + 1], -1.0)), &tr(&c)), 1.0);
    }
    (xs, ps, cs)
}
fn run(m: &Md, seed: u64) -> (Vec<V2>, Vec<f64>, Vec<f64>) {   // the cart balances on the right filter's estimates
    let mut r = Rng { s: seed }; let t0 = 0.05 * r.n(); let mut t = [t0, 0.5 * r.n()];
    let (mut ts, mut ys, mut us, mut x, mut p) = (vec![t], vec![0.0], vec![0.0], [0.0, 0.0], P0);
    for _ in 1..=N {
        let u = L * (32.0 * x[0] + 8.0 * x[1]); let w = SA * r.n();
        let ft = mv(&m.f, t); t = [0, 1].map(|i| ft[i] + m.gu[i] * u + m.g[i] * w); let y = t[0] + SR * r.n();
        ts.push(t); ys.push(y); us.push(u); let o = fstep(m, x, &p, u, y, 1.0); x = o.2; p = o.3;
    }
    (ts, ys, us)
}
fn sum(it: impl Iterator<Item = f64>) -> f64 { it.fold(0.0, |a, b| a + b) }
fn batch(m: &Md, ys: &[f64], us: &[f64]) -> Vec<(V2, V2)> {   // condition the joint normal law of all states on all readings
    let (mut fp, mut mu, mut sg) = (vec![[[1.0, 0.0], [0.0, 1.0]]], vec![[0.0, 0.0]], vec![P0]);
    for k in 1..=N {
        fp.push(mm(&m.f, &fp[k - 1])); let a = mv(&m.f, mu[k - 1]); mu.push([a[0] + m.gu[0] * us[k], a[1] + m.gu[1] * us[k]]);
        sg.push(add(&mm(&mm(&m.f, &sg[k - 1]), &tr(&m.f)), &qm(m, 1.0), 1.0));
    }
    let cxy = |k: usize, i: usize| -> V2 { if i <= k { let a = mm(&fp[k - i], &sg[i]); [a[0][0], a[1][0]] } else { let a = mm(&fp[i - k], &sg[k]); [a[0][0], a[0][1]] } };   // covariance of state k with reading i
    let a: Vec<Vec<f64>> = (1..=N).map(|i| (1..=N).map(|j| cxy(j, i)[0] + if i == j { R } else { 0.0 }).collect()).collect();
    let mut lc = vec![vec![0.0; N]; N];                     // Cholesky A = Lc Lc^T, then two triangular solves
    for i in 0..N { for j in 0..=i { let s = a[i][j] - sum((0..j).map(|p| lc[i][p] * lc[j][p])); lc[i][j] = if i == j { s.sqrt() } else { s / lc[j][j] }; } }
    let solve = |b: &[f64]| -> Vec<f64> {                   // forward, then backward substitution
        let mut z = vec![0.0; N];
        for i in 0..N { z[i] = (b[i] - sum((0..i).map(|p| lc[i][p] * z[p]))) / lc[i][i]; }
        for i in (0..N).rev() { z[i] = (z[i] - sum((i + 1..N).map(|p| lc[p][i] * z[p]))) / lc[i][i]; }
        z
    };
    let av = solve(&(1..=N).map(|i| ys[i] - mu[i][0]).collect::<Vec<_>>());
    (0..=N).map(|k| {                                       // mean and the two variances of state k given every reading
        let c: Vec<V2> = (1..=N).map(|i| cxy(k, i)).collect();
        let bb: Vec<Vec<f64>> = (0..2).map(|j| solve(&c.iter().map(|v| v[j]).collect::<Vec<_>>())).collect();
        ([0, 1].map(|j| mu[k][j] + sum((0..N).map(|i| c[i][j] * av[i]))), [0, 1].map(|j| sg[k][j][j] - sum((0..N).map(|i| c[i][j] * bb[j][i]))))
    }).collect()
}
fn sci(v: f64) -> String { format!("{:.3e}", v) }
fn rot(m0: &[Vec<f64>], r: fn(f64) -> f64) -> Vec<Vec<f64>> {   // Givens rotations on columns: lower-triangular T, T T^T = M M^T
    let mut m = m0.to_vec();
    for i in 0..m.len() {
        for k in i + 1..m[0].len() {
            let (a, b) = (m[i][i], m[i][k]); if b == 0.0 { continue; }
            let h = r(r(r(a * a) + r(b * b)).sqrt()); let (c, s) = (r(a / h), r(b / h));
            for row in m.iter_mut() { let (x, y) = (row[i], row[k]); row[i] = r(r(c * x) + r(s * y)); row[k] = r(r(c * y) - r(s * x)); }
        }
    }
    m
}
fn lmin(p: &M2) -> f64 {                                   // smallest eigenvalue of the symmetric part, as det / largest
    let (a, b, d) = (p[0][0], (p[0][1] + p[1][0]) / 2.0, p[1][1]); (a * d - b * b) / ((a + d + ((a - d).powi(2) + 4.0 * b * b).sqrt()) / 2.0)
}
fn cov32(m: &Md, form: &str, r: fn(f64) -> f64) -> (Vec<(usize, f64)>, Option<usize>, M2) {
    let ff: M2 = m.f.map(|row| row.map(r)); let rf = r(1e-8); let mut p: M2 = [[r(P0[0][0]), 0.0], [0.0, r(P0[1][1])]];
    let (mut lf, sr, mut first, mut out): (M2, f64, Option<usize>, Vec<(usize, f64)>) = ([[r(0.05), 0.0], [0.0, r(0.5)]], r(1e-8f64.sqrt()), None, Vec::new());
    for k in 1..=300 {
        if form == "square root" {                          // predict: rotate [F L]; correct: rotate [[sqrt R, H L], [0, L]]
            let fl: Vec<Vec<f64>> = (0..2).map(|i| (0..2).map(|j| r(r(ff[i][0] * lf[0][j]) + r(ff[i][1] * lf[1][j]))).collect()).collect();
            let lm = rot(&fl, r); let post = rot(&[vec![sr, lm[0][0], 0.0], vec![0.0, lm[0][0], 0.0], vec![0.0, lm[1][0], lm[1][1]]], r);
            lf = [[post[1][1], 0.0], [post[2][1], post[2][2]]]; p = mm(&lf, &tr(&lf));
        } else {
            let fp: M2 = std::array::from_fn(|i| std::array::from_fn(|j| r(r(ff[i][0] * p[0][j]) + r(ff[i][1] * p[1][j]))));
            let pm: M2 = std::array::from_fn(|i| std::array::from_fn(|j| r(r(fp[i][0] * ff[j][0]) + r(fp[i][1] * ff[j][1]))));
            let s = r(pm[0][0] + rf); let kk = [r(pm[0][0] / s), r(pm[1][0] / s)];
            if form == "plain" { p = std::array::from_fn(|i| std::array::from_fn(|j| r(pm[i][j] - r(kk[i] * pm[0][j])))); } else {   // Joseph
                let a = [[r(1.0 - kk[0]), 0.0], [r(-kk[1]), 1.0]]; let ap: M2 = std::array::from_fn(|i| std::array::from_fn(|j| r(r(a[i][0] * pm[0][j]) + r(a[i][1] * pm[1][j]))));
                p = std::array::from_fn(|i| std::array::from_fn(|j| r(r(r(ap[i][0] * a[j][0]) + r(ap[i][1] * a[j][1])) + r(r(kk[i] * kk[j]) * rf))));
            }
        }
        if first.is_none() && lmin(&p) < 0.0 { first = Some(k); }
        if k % 50 == 0 { out.push((k, lmin(&p))); }
    }
    (out, first, p)
}
fn main() {
    let (ch, sh) = (0.04_f64.cosh(), 0.04_f64.sinh()); let g = [(ch - 1.0) / 16.0, sh / 4.0];
    let m = Md { f: [[ch, sh / 4.0], [4.0 * sh, ch]], g, gu: [-g[0] / L, -g[1] / L] };
    // ---- one record of 50 readings (seed 1): forward filter, backward pass, batch conditioning ----
    let (ts, ys, us) = run(&m, 1); let w = filt(&m, &ys, &us, 1.0); let (xs, ps, cs) = smooth(&m, &w, true); let bt = batch(&m, &ys, &us);
    let (c, d) = (cs[49], add(&ps[50], &w.pm[50], -1.0)); let t = [c[1][0].powi(2) * d[0][0], 2.0 * c[1][0] * c[1][1] * d[0][1], c[1][1].powi(2) * d[1][1]];
    for (lab, v) in [("reading 1 (rad)", ys[1]), ("C49 rate<-angle (1/s)", c[1][0]), ("C49 rate<-rate", c[1][1]),
                     ("D50 angle var x1e6", 1e6 * d[0][0]), ("D50 angle-rate cov x1e6", 1e6 * d[0][1]), ("D50 rate var x1e6", 1e6 * d[1][1]),
                     ("term c10^2 D00 x1e6", 1e6 * t[0]), ("term 2 c10 c11 D01 x1e6", 1e6 * t[1]), ("term c11^2 D11 x1e6", 1e6 * t[2]),
                     ("step 49 filtered rate var x1e6", 1e6 * w.pf[49][1][1]), ("step 49 smoothed rate var x1e6", 1e6 * ps[49][1][1]),
                     ("  by batch conditioning", 1e6 * bt[49].1[1]), ("step 50 angle: smoothed - predicted", xs[50][0] - w.xm[50][0]),
                     ("step 50 rate: smoothed - predicted", xs[50][1] - w.xm[50][1]), ("step 49 filtered rate (rad/s)", w.xf[49][1]),
                     ("step 49 smoothed rate (rad/s)", xs[49][1]), ("  by batch conditioning", bt[49].0[1]), ("step 49 true rate (rad/s)", ts[49][1])] { println!("{:<40} {:>12.6}", lab, v); }
    let mx = |a: f64, b: f64| if b > a { b } else { a };
    let gap = (0..=N).map(|k| mx((xs[k][0] - bt[k].0[0]).abs(), (xs[k][1] - bt[k].0[1]).abs()) + mx((ps[k][0][0] - bt[k].1[0]).abs(), (ps[k][1][1] - bt[k].1[1]).abs())).fold(f64::MIN, mx);
    println!("largest gap, RTS vs batch, over all 51 steps   {}", sci(gap));
    let row = |f: &dyn Fn(usize) -> String| (5..=N).step_by(5).map(f).collect::<Vec<_>>().join(" ");
    println!("step              {}", row(&|k| format!("{:6}", k)));
    for (lab, p) in [("rate sd, filtered ", &w.pf), ("rate sd, smoothed ", &ps)] { println!("{}{}", lab, row(&|k| format!("{:6.3}", p[k][1][1].sqrt()))); }
    for (lab, x) in [("seed 1 true rate  ", &ts), ("seed 1 filter rate", &w.xf), ("seed 1 smooth rate", &xs)] { println!("{}{}", lab, row(&|k| format!("{:6.2}", x[k][1]))); }
    println!("step 25 rate variance, smoothed / filtered, Q x1 x10 x100: {}", [1.0, 10.0, 100.0].map(|q| { let f = filt(&m, &ys, &us, q); format!("{:.3}", smooth(&m, &f, true).1[25][1][1] / f.pf[25][1][1]) }).join(" "));
    // ---- 2000 records: actual errors against the claimed sd, and two broken smoothers ----
    let (mut acc, mut n, mut last) = ([0.0f64; 4], 0.0, (Vec::new(), Vec::new()));
    for seed in 1..=2000u64 {
        let (ts, ys, us) = run(&m, seed); let (fw, fq) = (filt(&m, &ys, &us, 1.0), filt(&m, &ys, &us, 0.01)); n += N as f64;
        let ests = [fw.xf.clone(), smooth(&m, &fw, true).0, smooth(&m, &fw, false).0, smooth(&m, &fq, true).0];
        for (i, e) in ests.iter().enumerate() { acc[i] += sum((1..=N).map(|k| (e[k][1] - ts[k][1]).powi(2))); }
        last = (ys, us);
    }
    let pq = smooth(&m, &filt(&m, &last.0, &last.1, 0.01), true).1;
    let cl: Vec<f64> = [&w.pf, &ps, &ps, &pq].iter().map(|p| (sum((1..=N).map(|k| p[k][1][1])) / N as f64).sqrt()).collect();
    let st: Vec<f64> = acc.iter().map(|a| (a / n).sqrt()).collect();
    let nm = ["forward filter", "RTS smoother", "smoother, G u left out", "smoother, Q 100x too small"];
    for i in 0..4 { println!("{:<27} rate rms {:.4}  claimed {:.4} rad/s", nm[i], st[i], cl[i]); }
    // ---- single precision: a precise encoder (R = 1e-8 rad^2), no modelled push (Q = 0), 300 steps of the covariance alone ----
    let (f64r, f32r): (fn(f64) -> f64, fn(f64) -> f64) = (|v| v, |v| v as f32 as f64);
    let rf = cov32(&m, "plain", f64r); let forms = ["plain", "Joseph", "square root"];
    let res: Vec<_> = forms.iter().map(|fm| cov32(&m, fm, f32r)).collect();
    println!("smallest eigenvalue   step {}", rf.0.iter().map(|(k, _)| format!("{:>11}", k)).collect::<String>());
    let names = ["double precision".to_string(), "single, plain".to_string(), "single, Joseph".to_string(), "single, square root".to_string()];
    for (nm, o) in names.iter().zip([&rf, &res[0], &res[1], &res[2]]) {
        let fi = match o.1 { Some(k) => k.to_string(), None => "never".to_string() };
        println!("{:<26} {}   first negative: {}", nm, o.0.iter().map(|(_, v)| format!("{:>11}", sci(*v))).collect::<String>(), fi);
    }
    let l300 = rf.0[5].1; let lmx = rf.2[0][0] + rf.2[1][1] - l300;   // largest eigenvalue: trace minus smallest
    println!("step 300: largest eigenvalue {}, ratio {}; for the factor {}", sci(lmx), sci(lmx / l300), sci((lmx / l300).sqrt()));
    println!("single-precision unit roundoff {}; per-step shrink of the smallest, steps 250 to 300: {:.6}, e^-0.08 = {:.6}", sci(2.0f64.powi(-24)), (l300 / rf.0[4].1).powf(0.02), (-0.08f64).exp());
    assert!(gap < 1e-10, "RTS backward pass vs batch conditioning on all 50 readings");
    assert!((1..N).all(|k| (0..2).all(|j| ps[k][j][j] < w.pf[k][j][j])) && (0..2).all(|j| (w.pf[N][j][j] - bt[N].1[j]).abs() < 1e-12), "smoothed below filtered; filter equals batch at the end");
    assert!((0..2).all(|i| (st[i] / cl[i] - 1.0).abs() < 0.03), "simulated errors vs the claimed sd: filter and smoother");
    assert!(st[2] > 3.0 * cl[2] && st[3] > 3.0 * cl[3], "broken smoothers claim far less error than they make");
    assert!(rf.0.iter().zip(&res[2].0).all(|(a, b)| (b.1 / a.1 - 1.0).abs() < 0.01), "single-precision square root vs double");
    assert!(rf.1.is_none() && res[0].1.is_some() && res[1].1.is_some(), "double holds; plain and Joseph go negative");
    assert!((cov32(&m, "square root", f64r).0[5].1 / l300 - 1.0).abs() < 1e-3, "square-root form vs plain form, both in double");
    println!("ALL CHECKS PASS");
}
