// ARX identification of the radiator room: the check behind the card.  Rust std only.
// Roads: normal equations vs Gram-Schmidt QR vs recursive least squares; the standard-error formula
// vs 200 simulated days; the bias closed form vs simulation; instrumental variables as the fix.
const A: f64 = 0.9; const B: f64 = 0.5; const SE: f64 = 0.1; const SW: f64 = 0.3; const N: usize = 1440;
type Mat = Vec<Vec<f64>>;
struct Rng(u64); // SplitMix64 and Box-Muller, cosine half only
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u1 = 1.0 - self.unif(); (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.unif()).cos() }
}
fn prbs(n: usize) -> Vec<f64> { // 11-bit shift register, x^11 + x^9 + 1, period 2047
    let (mut reg, mut out) = (0x7FFu32, vec![]);
    for _ in 0..n {
        out.push(if reg & 1 == 1 { 1.0 } else { -1.0 });
        reg = ((reg << 1) | (((reg >> 10) ^ (reg >> 8)) & 1)) & 0x7FF;
    }
    out
}
fn day(rng: &mut Rng, u: &[f64]) -> (Vec<f64>, Vec<f64>) { // true room, cheap thermometer
    let (mut x, mut ym) = (vec![0.0; N], vec![0.0; N]);
    for k in 0..N {
        let e = SE * rng.gauss(); let w = SW * rng.gauss();
        if k > 0 { x[k] = A * x[k - 1] + B * u[k - 1] + e; } ym[k] = x[k] + w;
    }
    (x, ym)
}
fn rows(y: &[f64], u: &[f64], na: usize, nb: usize, s: usize, e: usize) -> (Mat, Vec<f64>) {
    let p = (s..e).map(|k| (1..=na).map(|i| y[k - i]).chain((1..=nb).map(|i| u[k - i])).collect()).collect();
    (p, y[s..e].to_vec())
}
fn solve(m0: &Mat, v: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = v.len();
    let mut m: Mat = (0..n).map(|i| { let mut r = m0[i].clone(); r.push(v[i]); r }).collect();
    for c in 0..n {
        let mut p = c; for r in c + 1..n { if m[r][c].abs() > m[p][c].abs() { p = r; } } m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            for j in 0..=n { m[r][j] -= f * m[c][j]; }
        }
    }
    let mut th = vec![0.0; n];
    for i in (0..n).rev() {
        let s: f64 = (i + 1..n).map(|j| m[i][j] * th[j]).sum(); th[i] = (m[i][n] - s) / m[i][i];
    }
    th
}
fn gram(p: &Mat, z: &Mat) -> Mat { // Z^T Phi
    (0..z[0].len()).map(|i| (0..p[0].len()).map(|j| z.iter().zip(p).map(|(zr, pr)| zr[i] * pr[j]).sum()).collect()).collect()
}
fn zty(z: &Mat, t: &[f64]) -> Vec<f64> {
    (0..z[0].len()).map(|i| z.iter().zip(t).map(|(zr, v)| zr[i] * v).sum()).collect()
}
fn ls(p: &Mat, t: &[f64]) -> Vec<f64> { solve(&gram(p, p), &zty(p, t)) } // road 1
fn iv(p: &Mat, z: &Mat, t: &[f64]) -> Vec<f64> { solve(&gram(p, z), &zty(z, t)) }
fn dot(a: &[f64], b: &[f64]) -> f64 { let mut s = 0.0; for (x, y) in a.iter().zip(b) { s += x * y; } s }
fn qr_ls(p: &Mat, t: &[f64]) -> Vec<f64> { // road 2: modified Gram-Schmidt QR
    let n = p[0].len();
    let mut q: Mat = (0..n).map(|c| p.iter().map(|r| r[c]).collect()).collect();
    let mut r = vec![vec![0.0; n]; n];
    for c in 0..n {
        for j in 0..c {
            r[j][c] = dot(&q[j], &q[c]);
            let qj = q[j].clone(); q[c] = q[c].iter().zip(&qj).map(|(a, b)| a - r[j][c] * b).collect();
        }
        r[c][c] = dot(&q[c], &q[c]).sqrt(); q[c] = q[c].iter().map(|a| a / r[c][c]).collect();
    }
    solve(&r, &(0..n).map(|c| dot(&q[c], t)).collect::<Vec<_>>())
}
fn rls(p: &Mat, t: &[f64]) -> Vec<f64> { // road 3: recursive least squares, P0 = 1e6 I
    let (mut th, mut c) = (vec![0.0, 0.0], vec![vec![1e6, 0.0], vec![0.0, 1e6]]);
    for (f, v) in p.iter().zip(t) {
        let cf: Vec<f64> = (0..2).map(|i| c[i][0] * f[0] + c[i][1] * f[1]).collect();
        let g: Vec<f64> = cf.iter().map(|x| x / (1.0 + f[0] * cf[0] + f[1] * cf[1])).collect();
        let err = v - th[0] * f[0] - th[1] * f[1];
        th = (0..2).map(|i| th[i] + g[i] * err).collect();
        c = (0..2).map(|i| (0..2).map(|j| c[i][j] - g[i] * cf[j]).collect()).collect();
    }
    th
}
fn resid(p: &Mat, t: &[f64], th: &[f64]) -> Vec<f64> { p.iter().zip(t).map(|(r, v)| v - dot(r, th)).collect() }
fn rms(r: &[f64]) -> f64 { (dot(r, r) / r.len() as f64).sqrt() }
fn se(p: &Mat, t: &[f64], th: &[f64]) -> Vec<f64> {
    let (r, n) = (resid(p, t, th), p[0].len());
    let s2 = dot(&r, &r) / (r.len() - n) as f64;
    (0..n).map(|i| (s2 * solve(&gram(p, p), &(0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect::<Vec<_>>())[i]).sqrt()).collect()
}
fn whiteness(r: &[f64]) -> (Vec<f64>, usize) {
    let rho: Vec<f64> = (1..21).map(|l| (l..r.len()).map(|k| r[k] * r[k - l]).sum::<f64>() / dot(r, r)).collect();
    let out = rho.iter().filter(|p| p.abs() > 1.96 / (r.len() as f64).sqrt()).count();
    (rho, out)
}
fn join(v: &[f64], add: f64, d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, add + x)).collect::<Vec<_>>().join(" ") }
fn mean(v: &[f64]) -> f64 { v.iter().sum::<f64>() / v.len() as f64 } fn sd(v: &[f64]) -> f64 { let m = mean(v); (v.iter().map(|a| (a - m) * (a - m)).sum::<f64>() / (v.len() - 1) as f64).sqrt() }

fn main() {
    let mut rng = Rng(2026);
    let u = prbs(N); let (x, ym) = day(&mut rng, &u);
    println!("valve PRBS: {} minutes at 2.5 kW, {} at 0.5 kW", u.iter().filter(|v| **v > 0.0).count(), u.iter().filter(|v| **v < 0.0).count());
    println!("chart valve kW, min 0-60: {}", join(&u[..61], 1.5, 1));
    println!("chart room degC, min 0-60: {}", join(&x[..61], 20.0, 2));
    let (p, t) = rows(&x, &u, 1, 1, 1, N); let (g, gy) = (gram(&p, &p), zty(&p, &t));
    let (th, thq, thr) = (ls(&p, &t), qr_ls(&p, &t), rls(&p, &t)); let s = se(&p, &t, &th);
    println!("Phi^T Phi = [[{:.2}, {:.2}], [{:.2}, {:.2}]]  Phi^T y = [{:.2}, {:.2}]", g[0][0], g[0][1], g[1][0], g[1][1], gy[0], gy[1]);
    println!("1 normal equations  a = {:.4}  b = {:.4}  (se {:.4}, {:.4})", th[0], th[1], s[0], s[1]);
    println!("2 Gram-Schmidt QR   a = {:.4}  b = {:.4}", thq[0], thq[1]);
    println!("3 recursive LS      a = {:.4}  b = {:.4}", thr[0], thr[1]);
    println!("room: gain b/(1-a) = {:.3} degC/kW (true 5.000), lag -1/ln a = {:.2} min (true {:.2})", th[1] / (1.0 - th[0]), -1.0 / th[0].ln(), -1.0 / A.ln());
    assert!((th[0] - A).abs() < 0.01 && (th[1] - B).abs() < 0.01 && (0..2).all(|i| (th[i] - thq[i]).abs() < 1e-4 && (th[i] - thr[i]).abs() < 1e-4));

    // input design: one step against the PRBS, for a second-order model
    let us: Vec<f64> = (0..N).map(|k| if k < 10 { 0.0 } else { 1.0 }).collect(); let (xs, _) = day(&mut rng, &us);
    let pe = |w: &[f64]| { // smallest eigenvalue of the 2x2 table of input lags 1 and 2 (Step 3)
        let c = |i: usize, j: usize| (2..N).map(|k| w[k - i] * w[k - j]).sum::<f64>() / (N - 2) as f64; let (p, q, r) = (c(1, 1), c(2, 2), c(1, 2));
        (p + q) / 2.0 - ((p - q) * (p - q) / 4.0 + r * r).sqrt() };
    let (p2, t2) = rows(&xs, &us, 2, 2, 2, N); let th2 = ls(&p2, &t2); let s2 = se(&p2, &t2, &th2);
    let (pp, tp) = rows(&x, &u, 2, 2, 2, N); let thp = ls(&pp, &tp); let sp = se(&pp, &tp, &thp);
    println!("excitation, smallest eigenvalue: step {:.5}, PRBS {:.4}", pe(&us), pe(&u));
    println!("order 2 from the step: b1 = {:.2} +- {:.2}, b2 = {:.2} +- {:.2}, b1+b2 = {:.3}", th2[2], s2[2], th2[3], s2[3], th2[2] + th2[3]);
    println!("order 2 from the PRBS: b1 = {:.3} +- {:.3}, b2 = {:.3} +- {:.3}, a2 = {:.3}", thp[2], sp[2], thp[3], sp[3], thp[1]);
    assert!(pe(&us) < 0.01 && pe(&u) > 0.9 && s2[2] > 10.0 * sp[2]);

    // order choice: fit on the first 12 hours, score on the last 12
    println!("order  train rms  valid rms  lags outside the whiteness band, of 20");
    let (mut val, mut th1, mut out1, mut out0) = (vec![0.0; 5], vec![], 0, 0);
    for na in 0..5 {
        let nb = na.max(1);
        let (pe_, te) = rows(&x, &u, na, nb, 4, 720); let (pv, tv) = rows(&x, &u, na, nb, 724, N); let tho = ls(&pe_, &te);
        let rv = resid(&pv, &tv, &tho); val[na] = rms(&rv); let out = whiteness(&rv).1;
        println!("({},{})   {:.5}    {:.5}    {}", na, nb, rms(&resid(&pe_, &te, &tho)), val[na], out);
        if na == 1 { th1 = tho; out1 = out; } else if na == 0 { out0 = out; }
    }
    let (mut sim, mut err) = (vec![x[720]], vec![]);
    for k in 721..N { let nx = th1[0] * sim[sim.len() - 1] + th1[1] * u[k - 1]; sim.push(nx); err.push(x[k] - nx); }
    println!("order 1, free run over the last 12 h: rms {:.3} degC", rms(&err));
    println!("chart measured degC, min 720-780: {}", join(&x[720..781], 20.0, 2));
    println!("chart model degC, min 720-780: {}", join(&sim[..61], 20.0, 2));
    assert!(val[1] < 1.01 * val[2].min(val[3]).min(val[4]) && val[0] > 2.0 * val[1] && out1 <= 2 && out0 > 2);

    // coloured noise: the cheap thermometer on the same day
    let (pm, tm) = rows(&ym, &u, 1, 1, 2, N); let thm = ls(&pm, &tm);
    let zm: Mat = (2..N).map(|k| vec![u[k - 2], u[k - 1]]).collect(); let thi = iv(&pm, &zm, &tm);
    let (rho, outm) = whiteness(&resid(&pm, &tm, &thm));
    let vx = (B * B + SE * SE) / (1.0 - A * A); let abar = A * vx / (vx + SW * SW);
    println!("cheap thermometer, LS: a = {:.4} b = {:.4}; gain {:.3} degC/kW, lag {:.2} min", thm[0], thm[1], thm[1] / (1.0 - thm[0]), -1.0 / thm[0].ln());
    println!("  residual lag-1 correlation {:.3}, lags outside the band {} of 20", rho[0], outm);
    println!("  closed form: a -> 0.9 * {:.4} / ({:.4} + {:.2}) = {:.4}", vx, vx, SW * SW, abar);
    println!("  instrumental variables: a = {:.4} b = {:.4}", thi[0], thi[1]);

    // 200 more days: the spread of the white-noise fit, and the bias of the coloured one
    let (mut ag, mut am, mut ai) = (vec![], vec![], vec![]);
    for _ in 0..200 {
        let (xx, yy) = day(&mut rng, &u);
        let (p, t) = rows(&xx, &u, 1, 1, 1, N); ag.push(ls(&p, &t)[0]);
        let (p, t) = rows(&yy, &u, 1, 1, 2, N); am.push(ls(&p, &t)[0]); ai.push(iv(&p, &zm, &t)[0]);
    }
    println!("200 days, good thermometer: mean a {:.4}, spread {:.4} (formula {:.4})", mean(&ag), sd(&ag), s[0]);
    println!("200 days, cheap thermometer: LS mean a {:.4} spread {:.4} (closed form {:.4})", mean(&am), sd(&am), abar);
    println!("200 days, cheap thermometer: IV mean a {:.4} spread {:.4}", mean(&ai), sd(&ai));
    println!("try: thermometer noise 0.1 / 0.5 degC -> a {:.4} / {:.4}; 6 hours of data -> spread about {:.4}", A * vx / (vx + 0.01), A * vx / (vx + 0.25), 2.0 * s[0]);
    assert!((sd(&ag) / s[0] - 1.0).abs() < 0.2 && (mean(&am) - abar).abs() < 0.005 && (mean(&ai) - A).abs() < 0.01 && outm > 3);
    let sq: Vec<f64> = (0..N).map(|k| if k / 20 % 2 == 0 { 1.0 } else { -1.0 }).collect(); // the valve on a 40-minute square wave
    let (pq, tq) = rows(&day(&mut Rng(2026), &sq).0, &sq, 2, 2, 2, N); let (thw, sw) = (ls(&pq, &tq), se(&pq, &tq, &ls(&pq, &tq))); // first day's noise
    println!("try: square wave of period 40 min -> smallest eigenvalue {:.4}; order 2: b1 = {:.3} +- {:.3}", pe(&sq), thw[2], sw[2]);
    println!("ALL CHECKS PASS");
}
