// Particle filter on a hanging pole whose sensor sees only the size of the angle -- the check behind the card. Std only.
// Roads: closed form, fine grid and particles for the first reading; particles against a two-filter bank.
const GL: f64 = 16.0; const DT: f64 = 0.01; const SV: f64 = 0.05; const SA: f64 = 1.0;
const N: usize = 1000; const NT: f64 = 500.0; const KICK: f64 = 4.893; const STEPS: usize = 1000;
const S0: f64 = 0.5; const W0: f64 = 0.1; const Y0: f64 = 0.6; const PHI0: f64 = -0.6;
type X = (f64, f64); type Rec = (f64, f64, f64, f64, usize, f64); // mean, sd, right-hump weight, ESS, distinct, size of angle
struct Rng(u64);
impl Rng { // SplitMix64 bits, Box-Muller normals
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powf(53.0)
    }
    fn n(&mut self) -> f64 { let u1 = self.u(); let u2 = self.u(); (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos() }
}
fn sum<I: IntoIterator<Item = f64>>(it: I) -> f64 { // the same compensated (Neumaier) sum as Python's built-in sum
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s }; s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn kick(j: usize) -> f64 { if (100..110).contains(&j) { KICK } else { 0.0 } }
fn step(p: f64, w: f64, j: usize, a: f64) -> X { // RK4 over one 0.01 s step, random angular acceleration a held
    let f = |q: f64| -GL * q.sin() - kick(j) * q.cos() + a;
    let (k1p, k1w) = (w, f(p)); let (k2p, k2w) = (w + DT / 2.0 * k1w, f(p + DT / 2.0 * k1p));
    let (k3p, k3w) = (w + DT / 2.0 * k2w, f(p + DT / 2.0 * k2p)); let (k4p, k4w) = (w + DT * k3w, f(p + DT * k3p));
    (p + DT / 6.0 * (k1p + 2.0 * k2p + 2.0 * k3p + k4p), w + DT / 6.0 * (k1w + 2.0 * k2w + 2.0 * k3w + k4w))
}
fn right(x: X, t: X) -> bool { // nearer the true state than its mirror image (-angle, -rate)?
    (x.0 - t.0).powf(2.0) + ((x.1 - t.1) / 4.0).powf(2.0) < (x.0 + t.0).powf(2.0) + ((x.1 + t.1) / 4.0).powf(2.0)
}
fn systematic(wt: &[f64], u: f64) -> Vec<usize> { // one uniform u in [0, 1/n); the index picked by each pointer
    let n = wt.len(); let (mut c, mut j, mut out) = (wt[0], 0usize, vec![]);
    for i in 0..n { while u + i as f64 / n as f64 > c && j < n - 1 { j += 1; c += wt[j]; } out.push(j); } out
}
fn pf(n: usize, thr: f64, jit: bool, tr: &[X], ys: &[f64], keep: &mut Vec<(Vec<f64>, Vec<usize>, Vec<X>)>) -> (Vec<Rec>, usize) {
    let mut rng = Rng(2026); let mut xs: Vec<X> = vec![];
    for _ in 0..n { let a = S0 * rng.n(); xs.push((a, W0 * rng.n())); }
    let mut wt = vec![1.0 / n as f64; n]; let mut rec = vec![]; let mut nres = 0;
    for k in 0..=STEPS {
        if k > 0 { xs = xs.iter().map(|&(p, w)| step(p, w, k - 1, if jit { SA * rng.n() } else { 0.0 })).collect(); }
        wt = wt.iter().zip(&xs).map(|(wi, x)| wi * (-(ys[k] - x.0.abs()).powf(2.0) / (2.0 * SV * SV)).exp()).collect();
        let s = sum(wt.iter().cloned()); wt = wt.iter().map(|wi| wi / s).collect();
        let ess = 1.0 / sum(wt.iter().map(|wi| wi * wi));
        let m = sum(wt.iter().zip(&xs).map(|(wi, x)| wi * x.0)); let size = sum(wt.iter().zip(&xs).map(|(wi, x)| wi * x.0.abs()));
        let sd = sum(wt.iter().zip(&xs).map(|(wi, x)| wi * (x.0 - m).powf(2.0))).sqrt();
        let mut d: Vec<(u64, u64)> = xs.iter().map(|x| (x.0.to_bits(), x.1.to_bits())).collect(); d.sort(); d.dedup();
        rec.push((m, sd, sum(wt.iter().zip(&xs).filter(|(_, x)| right(**x, tr[k])).map(|(wi, _)| *wi)), ess, d.len(), size));
        if ess < thr {
            let idx = systematic(&wt, rng.u() / n as f64);
            if k == 0 && keep.is_empty() { keep.push((wt.clone(), idx.clone(), xs.clone())); }
            xs = idx.iter().map(|&i| xs[i]).collect(); wt = vec![1.0 / n as f64; n]; nres += 1;
        }
    }
    (rec, nres)
}
fn ekf(x: X, p: [f64; 3], y: f64, j: Option<usize>, q: &[f64; 3]) -> (X, [f64; 3], f64) { // P = angle var, cov, rate var
    let (mut x, mut p) = (x, p);
    if let Some(j) = j {
        let k = -GL * x.0.cos() + kick(j) * x.0.sin(); let (c, s) = (1.0 + k * DT * DT / 2.0, DT + k * DT.powf(3.0) / 6.0);
        let (a, b, d) = (p[0], p[1], p[2]); let ks = k * s;
        p = [c * c * a + 2.0 * c * s * b + s * s * d + q[0], c * ks * a + (c * c + s * ks) * b + s * c * d + q[1],
             ks * ks * a + 2.0 * ks * c * b + c * c * d + q[2]];
        x = step(x.0, x.1, j, 0.0);
    }
    let h = ((x.0 > 0.0) as i32 - (x.0 < 0.0) as i32) as f64; let (a, b, d) = (p[0], p[1], p[2]); let s = a + SV * SV;
    let nu = y - x.0.abs(); let (k0, k1) = (h * a / s, h * b / s);
    ((x.0 + k0 * nu, x.1 + k1 * nu), [a - k0 * h * a, b - k0 * h * b, d - k1 * h * b],
     (-nu * nu / (2.0 * s)).exp() / (2.0 * std::f64::consts::PI * s).sqrt())
}
fn sigma(x: X, p: [f64; 3]) -> Vec<X> { // centre, then centre +- sqrt(3) times each column of a square root of P
    let l1 = p[0].sqrt(); let l2 = p[1] / l1; let l3 = (p[2] - l2 * l2).sqrt(); let r = 3f64.sqrt();
    vec![x, (x.0 + r * l1, x.1 + r * l2), (x.0 - r * l1, x.1 - r * l2), (x.0, x.1 + r * l3), (x.0, x.1 - r * l3)]
}
fn wsum(a: &[f64], b: &[f64]) -> f64 { let wu = [1.0 / 3.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0]; sum((0..5).map(|i| wu[i] * a[i] * b[i])) }
fn ukf(x: X, p: [f64; 3], y: f64, j: Option<usize>, q: &[f64; 3]) -> (X, [f64; 3]) { // five sigma points
    let (mut x, mut p) = (x, p); let one = [1.0; 5];
    if let Some(j) = j {
        let ch: Vec<X> = sigma(x, p).iter().map(|c| step(c.0, c.1, j, 0.0)).collect();
        let c0: Vec<f64> = ch.iter().map(|c| c.0).collect(); let c1: Vec<f64> = ch.iter().map(|c| c.1).collect();
        x = (wsum(&one, &c0), wsum(&one, &c1));
        let ep: Vec<f64> = c0.iter().map(|v| v - x.0).collect(); let ew: Vec<f64> = c1.iter().map(|v| v - x.1).collect();
        p = [wsum(&ep, &ep) + q[0], wsum(&ep, &ew) + q[1], wsum(&ew, &ew) + q[2]];
    }
    let ch = sigma(x, p); let yv: Vec<f64> = ch.iter().map(|c| c.0.abs()).collect(); let my = wsum(&one, &yv);
    let ep: Vec<f64> = ch.iter().map(|c| c.0 - x.0).collect(); let ew: Vec<f64> = ch.iter().map(|c| c.1 - x.1).collect();
    let ey: Vec<f64> = yv.iter().map(|v| v - my).collect();
    let s = wsum(&ey, &ey) + SV * SV; let (k0, k1) = (wsum(&ep, &ey) / s, wsum(&ew, &ey) / s); let nu = y - my;
    ((x.0 + k0 * nu, x.1 + k1 * nu), [p[0] - k0 * k0 * s, p[1] - k0 * k1 * s, p[2] - k1 * k1 * s])
}
fn phi(z: f64) -> f64 { // normal CDF, Abramowitz and Stegun 7.1.26 (error below 1.5e-7)
    let x = z.abs() / 2f64.sqrt(); let t = 1.0 / (1.0 + 0.3275911 * x);
    let e = 1.0 - t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429)))) * (-x * x).exp();
    if z >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn list(v: &[f64]) -> String { format!("[{}]", v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ")) }
fn main() {
    let q = [SA * SA * DT.powf(4.0) / 4.0, SA * SA * DT.powf(3.0) / 2.0, SA * SA * DT * DT];
    let mut tr = Rng(1); let mut truth: Vec<X> = vec![(PHI0, 0.0)]; let mut ys = vec![Y0];
    for j in 0..STEPS { let l = truth[j]; let x = step(l.0, l.1, j, SA * tr.n()); truth.push(x); ys.push(x.0.abs() + SV * tr.n()); }
    // ---- road 1: the first reading in closed form, and on a fine grid ----
    let v = S0 * S0 + SV * SV; let (cen, hsd) = (Y0 * S0 * S0 / v, (S0 * S0 * SV * SV / v).sqrt());
    let mw = |s: f64| [SV, SV / 2f64.sqrt()].map(|v| 2.0 * v / (s * s + v * v).sqrt() * (-Y0 * Y0 / (2.0 * (s * s + v * v))).exp());
    let [el, el2] = mw(S0); // mean weight and mean squared weight over a start belief of sd S0
    let g: Vec<f64> = (0..12001).map(|i| -3.0 + i as f64 * 0.0005).collect();
    let gp: Vec<f64> = g.iter().map(|q| (-q * q / (2.0 * S0 * S0)).exp()).collect();
    let gl: Vec<f64> = g.iter().map(|q| (-(Y0 - q.abs()).powf(2.0) / (2.0 * SV * SV)).exp()).collect();
    let z = sum((0..g.len()).map(|i| gp[i] * gl[i])); let gc = sum((0..g.len()).map(|i| gp[i] * gl[i] * g[i].abs())) / z;
    let gsd = (sum((0..g.len()).map(|i| gp[i] * gl[i] * (g[i].abs() - gc).powf(2.0))) / z).sqrt();
    let gneg = sum((0..g.len()).filter(|&i| g[i] < 0.0).map(|i| gp[i] * gl[i])) / z;
    let gess = z * z / sum(gp.iter().cloned()) / sum((0..g.len()).map(|i| gp[i] * gl[i] * gl[i]));
    println!("setup: g/l {:?} 1/s^2 (pole {:?} m), 0.6 rad = {:.1} deg, start sd {:?} rad and {:?} rad/s, step {:?} s, sensor sd {:?} rad, push sd {:?} rad/s^2, {} particles, resample below {}", GL, 9.81 / GL, 0.6f64.to_degrees(), S0, W0, DT, SV, SA, N, NT);
    println!("first reading {:?} rad, closed form: prior + sensor variance {:.4} rad^2, hump centres +-{:.6} rad, hump sd {:.6} rad, each hump 0.500000", Y0, v, cen, hsd);
    println!("first reading {:?} rad, fine grid:   hump centres +-{:.6} rad, hump sd {:.6} rad, negative hump {:.6}", Y0, gc, gsd, gneg);
    println!("weight of a particle at -0.55 / 0.60 / 0.20 rad: {:.6} / 1.000000 / {:.3e}", (-0.05f64.powf(2.0) / (2.0 * SV * SV)).exp(), (-0.4f64.powf(2.0) / (2.0 * SV * SV)).exp());
    println!("mean weight {:.6}, mean squared weight {:.6}, expected ESS fraction: closed form {:.6}, grid {:.6}, so {:.1} particles; start sd 0.6 / 0.8 rad: {}", el, el2, el * el / el2, gess, N as f64 * el * el / el2,
        [mw(0.6), mw(0.8)].map(|[a, b]| format!("{:.1}", N as f64 * a * a / b)).join(" / ") + " particles");
    assert!((gc - cen).abs() < 1e-5 && (gsd - hsd).abs() < 1e-5 && (gneg - 0.5).abs() < 1e-9 && (gess - el * el / el2).abs() < 1e-5);
    let mut keep = vec![]; let (rec, nres) = pf(N, NT, true, &truth, &ys, &mut keep); let (w0, idx0, xs0) = keep[0].clone();
    let mut cp = vec![0usize; N]; for &i in &idx0 { cp[i] += 1; }
    let neg = idx0.iter().filter(|&&i| xs0[i].0 < 0.0).count(); let mut big = 0; for i in 0..N { if w0[i] > w0[big] { big = i; } }
    let within = (0..N).all(|i| (cp[i] as f64 - N as f64 * w0[i]).abs() < 1.0);
    println!("particles after reading 1: ESS {:.1} of {}, so resample; largest N*w {:.3} gets {} copies", rec[0].3, N, N as f64 * w0[big], cp[big]);
    println!("after resampling: {} particles on the negative hump, {} on the positive (split sd from the ESS: {:.1} particles); every copy count within 1 of N*w: {}", neg, N - neg, N as f64 * (0.25 / rec[0].3).sqrt(), if within { "True" } else { "False" });
    assert!(within && (rec[0].3 / N as f64 - el * el / el2).abs() < 0.03 && (neg as f64 - N as f64 / 2.0).abs() < 3.0 * N as f64 * (0.25 / rec[0].3).sqrt());
    let hist: Vec<usize> = (0..20).map(|b| idx0.iter().filter(|&&i| ((xs0[i].0 + 1.0) / 0.1).floor() == b as f64).count()).collect();
    let ex: Vec<f64> = (0..20).map(|b| N as f64 * 0.5 * sum([1.0, -1.0].iter().map(|s| phi((-0.9 + 0.1 * b as f64 - s * cen) / hsd) - phi((-1.0 + 0.1 * b as f64 - s * cen) / hsd)))).collect();
    println!("figure, particles per 0.1 rad bin from -1.0 to 1.0 rad: {:?}", hist);
    println!("figure, exact belief, expected per bin: [{}]", ex.iter().map(|e| format!("{:.0}", e)).collect::<Vec<_>>().join(", "));
    assert!(sum((0..20).filter(|&b| ex[b] > 5.0).map(|b| (hist[b] as f64 - ex[b]).powf(2.0) / ex[b])) * rec[0].3 / (N as f64) < 25.0); // chi-square, scaled by ESS / N
    let toy: Vec<usize> = systematic(&[0.1, 0.4, 0.05, 0.3, 0.15], 0.07).iter().map(|i| i + 1).collect();
    println!("systematic resampling, weights 0.1 0.4 0.05 0.3 0.15, pointers 0.07 + i/5: picks particles {:?}", toy);
    // ---- road 2: the run, particles against a bank of two extended filters, one per hump ----
    let mut bank: Vec<(X, [f64; 3], f64)> = [1.0, -1.0].iter().map(|s| ((s * cen, 0.0), [hsd * hsd, 0.0, W0 * W0], 0.5)).collect();
    let (mut xe, mut pe, _) = ekf((0.001, 0.0), [S0 * S0, 0.0, W0 * W0], Y0, None, &q); let (mut xu, mut pu) = ukf((0.0, 0.0), [S0 * S0, 0.0, W0 * W0], Y0, None, &q);
    let (mut bw, mut be, mut ee, mut ue, mut es, mut us) = (vec![0.5], vec![0.0], vec![xe.0], vec![xu.0], vec![pe[0].sqrt()], vec![pu[0].sqrt()]);
    for k in 1..=STEPS {
        for b in bank.iter_mut() { let (x, p, lik) = ekf(b.0, b.1, ys[k], Some(k - 1), &q); b.0 = x; b.1 = p; b.2 *= lik; }
        let s = sum(bank.iter().map(|b| b.2)); for b in bank.iter_mut() { b.2 /= s; }
        bw.push(sum(bank.iter().filter(|b| right(b.0, truth[k])).map(|b| b.2))); be.push(sum(bank.iter().map(|b| b.2 * b.0 .0)));
        let r = ekf(xe, pe, ys[k], Some(k - 1), &q); xe = r.0; pe = r.1; let r = ukf(xu, pu, ys[k], Some(k - 1), &q); xu = r.0; pu = r.1;
        ee.push(xe.0); ue.push(xu.0); es.push(pe[0].sqrt()); us.push(pu[0].sqrt());
    }
    let rms = |e: &[f64], a: usize, b: usize| (sum((a..=b).map(|k| (e[k] - truth[k].0).powf(2.0))) / (b - a + 1) as f64).sqrt();
    let claim = |s: &[f64], a: usize, b: usize| (sum((a..=b).map(|k| s[k].powf(2.0))) / (b - a + 1) as f64).sqrt();
    let pm: Vec<f64> = rec.iter().map(|r| r.0).collect(); let ps: Vec<f64> = rec.iter().map(|r| r.1).collect();
    println!("t (s) | true angle | particle mean | particle sd | right-hump weight: particles / bank | ESS");
    for k in [0, 50, 100, 110, 115, 120, 150, 1000] { println!("{:.2} | {:+.3} | {:+.3} | {:.3} | {:.3} / {:.3} | {:.1}", k as f64 * DT, truth[k].0, rec[k].0, rec[k].1, rec[k].2, bw[k], rec[k].3); }
    let rw: Vec<f64> = rec.iter().map(|r| r.2).collect();
    for (lab, ws) in [("particles", &rw), ("bank     ", &bw)] { println!("chart, right-hump weight every 0.1 s, {}: {}", lab, list(&(0..21).map(|i| ws[10 * i]).collect::<Vec<_>>())); }
    let mut m0 = [truth[100], (-truth[100].0, -truth[100].1)];
    for j in 100..115 { m0 = [step(m0[0].0, m0[0].1, j, 0.0), step(m0[1].0, m0[1].1, j, 0.0)]; }
    println!("kick: cart {:.3} m/s^2 for 0.1 s; true state and its mirror at 1 s, both swinging toward 0 at {:.3} rad/s, pushed alike, sizes at 1.15 s {:.3} and {:.3} rad", KICK / GL * 9.81, truth[100].1.abs(), m0[0].0.abs(), m0[1].0.abs());
    let dec = |ws: &[f64]| (0..=STEPS).find(|&k| ws[k] > 0.99).unwrap() as f64 * DT;
    println!("right hump passes 0.99 at: particles {:.2} s, bank {:.2} s; resamplings {} in {} readings", dec(&rw), dec(&bw), nres, STEPS + 1);
    let sz = (sum((0..101).map(|k| (rec[k].5 - truth[k].0.abs()).powf(2.0))) / 101.0).sqrt();
    println!("0 to 1 s, rms error: size of angle, particles {:.4}; angle, particle mean {:.4}, extended {:.4}, unscented {:.4} rad", sz, rms(&pm, 0, 100), rms(&ee, 0, 100), rms(&ue, 0, 100));
    println!("unscented at 1 s: angle {:+.6} rad, claims sd {:.4} rad; extended at 1 s: {:+.4} rad, claims sd {:.4} rad", ue[100], us[100], ee[100], es[100]);
    let ep = rms(&pm, 600, STEPS); let cpm = claim(&ps, 600, STEPS); let mir = rms(&ee.iter().map(|v| -v).collect::<Vec<_>>(), 600, STEPS);
    println!("6 to 10 s, rms error / claimed sd: particles {:.4} / {:.4}, bank {:.4}, extended {:.4} / {:.4}, unscented {:.4} / {:.4} rad; extended against the mirror image of the truth {:.4} rad",
        ep, cpm, rms(&be, 600, STEPS), rms(&ee, 600, STEPS), claim(&es, 600, STEPS), rms(&ue, 600, STEPS), claim(&us, 600, STEPS), mir);
    assert!((dec(&rw) - dec(&bw)).abs() < 0.05 && (0..101).all(|k| (bw[k] - 0.5).abs() < 1e-9));
    assert!(ep < 0.02 && 0.67 < ep / cpm && ep / cpm < 1.5 && (ep - rms(&be, 600, STEPS)).abs() < 0.003 && rms(&ee, 600, STEPS) > 0.5 && mir < 0.02);
    for (lab, thr, jit) in [("never resample", 0.0, true), ("no random push", NT, false)] {
        let (r, _) = pf(N, thr, jit, &truth, &ys, &mut keep);
        let e = rms(&r.iter().map(|x| x.0).collect::<Vec<_>>(), 600, STEPS); let c = claim(&r.iter().map(|x| x.1).collect::<Vec<_>>(), 600, STEPS);
        println!("what breaks, {}: ESS at 10 s {:.1}, distinct particles {}, rms error {:.4} / claimed sd {:.4} rad", lab, r[STEPS].3, r[STEPS].4, e, c);
        assert!(e > 2.0 * ep && c < e / 3.0);
    }
    println!("ALL CHECKS PASS");
}
