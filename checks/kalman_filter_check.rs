// Kalman filter on the balancing pendulum -- the same check as kalman_filter_check.py, in Rust.
// Roads: the gain formula and its Riccati recursion; a brute-force search over fixed gains;
// the information (precision) form of the correction; 2000 simulated runs; innovation statistics.
type M2 = [[f64; 2]; 2];
const DT: f64 = 0.01; const L: f64 = 9.81 / 16.0;    // 100 hertz; pole length l (m), so g/l = 16 per s^2
const SA: f64 = 1.0; const SR: f64 = 0.005;          // random angular acceleration sd (rad/s^2); encoder sd (rad)
const R: f64 = SR * SR; const P0: M2 = [[0.05 * 0.05, 0.0], [0.0, 0.5 * 0.5]];
struct Model { f: M2, g: [f64; 2], gu: [f64; 2], q: M2 }
struct Rng { s: u64 }                  // SplitMix64 bits, Box-Muller normals
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn n(&mut self) -> f64 {
        let a = 1.0 - self.u();
        (-2.0 * a.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.u()).cos()
    }
}
fn predict(m: &Model, x: [f64; 2], p: &M2, u: f64, q: f64, use_u: f64) -> ([f64; 2], M2) {
    let f = &m.f;
    let xn = [f[0][0] * x[0] + f[0][1] * x[1] + use_u * m.gu[0] * u, f[1][0] * x[0] + f[1][1] * x[1] + use_u * m.gu[1] * u];
    let fp: M2 = std::array::from_fn(|i| std::array::from_fn(|j| f[i][0] * p[0][j] + f[i][1] * p[1][j]));
    (xn, std::array::from_fn(|i| std::array::from_fn(|j| fp[i][0] * f[j][0] + fp[i][1] * f[j][1] + q * m.q[i][j])))
}
fn correct(x: [f64; 2], p: &M2, y: f64, kf: Option<[f64; 2]>) -> ([f64; 2], M2, f64, f64, [f64; 2]) {
    let s = p[0][0] + R;                           // the encoder reads the angle only: H = [1, 0]
    let k = kf.unwrap_or([p[0][0] / s, p[1][0] / s]);
    let (nu, a) = (y - x[0], [[1.0 - k[0], 0.0], [-k[1], 1.0]]);   // Joseph form: right for any gain
    let ap: M2 = std::array::from_fn(|i| std::array::from_fn(|j| a[i][0] * p[0][j] + a[i][1] * p[1][j]));
    let pn: M2 = std::array::from_fn(|i| std::array::from_fn(|j| ap[i][0] * a[j][0] + ap[i][1] * a[j][1] + k[i] * k[j] * R));
    ([x[0] + k[0] * nu, x[1] + k[1] * nu], pn, nu, s, k)
}
fn inv2(p: &M2) -> M2 { let d = p[0][0] * p[1][1] - p[0][1] * p[1][0]; [[p[1][1] / d, -p[0][1] / d], [-p[1][0] / d, p[0][0] / d]] }
fn info_correct(x: [f64; 2], p: &M2, y: f64) -> ([f64; 2], M2) {   // precisions add; means weighted by precision
    let i = inv2(p);
    let pn = inv2(&[[i[0][0] + 1.0 / R, i[0][1]], [i[1][0], i[1][1]]]);
    let b = [i[0][0] * x[0] + i[0][1] * x[1] + y / R, i[1][0] * x[0] + i[1][1] * x[1]];
    ([pn[0][0] * b[0] + pn[0][1] * b[1], pn[1][0] * b[0] + pn[1][1] * b[1]], pn)
}
fn bend(t: [f64; 2], u: f64, w: f64) -> [f64; 2] {   // the curved pole: theta'' = 16 sin theta - (u/l) cos theta + w, RK4
    let f = |s: [f64; 2]| [s[1], 16.0 * s[0].sin() - u / L * s[0].cos() + w]; let (h, mut t) = (DT / 10.0, t);
    for _ in 0..10 {
        let k1 = f(t); let k2 = f([t[0] + h / 2.0 * k1[0], t[1] + h / 2.0 * k1[1]]); let k3 = f([t[0] + h / 2.0 * k2[0], t[1] + h / 2.0 * k2[1]]);
        let k4 = f([t[0] + h * k3[0], t[1] + h * k3[1]]); t = [0, 1].map(|i| t[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]));
    }
    t
}
type Var = (f64, f64, Option<[f64; 2]>);
struct Step { t: [f64; 2], y: f64, fd: f64, rec: Vec<([f64; 2], f64, f64)> }
fn run(m: &Model, seed: u64, steps: usize, vars: &[Var], th0: f64, curved: bool) -> Vec<Step> {   // variant 0 drives the cart
    let mut r = Rng { s: seed };
    let t0 = th0 + P0[0][0].sqrt() * r.n();
    let mut t = [t0, P0[1][1].sqrt() * r.n()];
    let mut est: Vec<([f64; 2], M2)> = vars.iter().map(|_| ([th0, 0.0], P0)).collect();
    let (mut out, mut yprev): (Vec<Step>, Option<f64>) = (Vec::new(), None);
    for _ in 1..=steps {
        let u = L * (32.0 * est[0].0[0] + 8.0 * est[0].0[1]);          // a = l (32 th + 8 om), from Pole placement
        let w = SA * r.n();
        let f = &m.f;
        t = if curved { bend(t, u, w) } else { [f[0][0] * t[0] + f[0][1] * t[1] + m.gu[0] * u + m.g[0] * w, f[1][0] * t[0] + f[1][1] * t[1] + m.gu[1] * u + m.g[1] * w] };
        let y = t[0] + SR * r.n();
        let mut rec = Vec::new();
        for (i, &(q, use_u, k)) in vars.iter().enumerate() {
            let (x, p) = predict(m, est[i].0, &est[i].1, u, q, use_u);
            let (x, p, nu, s, _) = correct(x, &p, y, k);
            est[i] = (x, p); rec.push((x, nu, s));
        }
        let fd = match yprev { Some(yp) => (y - yp) / DT, None => 0.0 }; out.push(Step { t, y, fd, rec }); yprev = Some(y);
    }
    out
}
fn show(label: &str, v: f64) { println!("{:<44} {:>12.6}", label, v); }
fn cost(m: &Model, k: [f64; 2]) -> f64 {           // steady error of a fixed gain, iterated to rest
    let mut e = P0;
    for _ in 0..1500 { e = correct([0.0, 0.0], &predict(m, [0.0, 0.0], &e, 0.0, 1.0, 1.0).1, 0.0, Some(k)).1; }
    e[0][0] / (DT * DT) + e[1][1]
}
fn main() {
    let (ch, sh) = (0.04_f64.cosh(), 0.04_f64.sinh()); let g = [(ch - 1.0) / 16.0, sh / 4.0];
    let q: M2 = std::array::from_fn(|i| std::array::from_fn(|j| SA * SA * g[i] * g[j]));
    let m = Model { f: [[ch, sh / 4.0], [4.0 * sh, ch]], g, gu: [-g[0] / L, -g[1] / L], q };
    // ---- step 1, by hand ----
    let (xp, pp) = predict(&m, [0.0, 0.0], &P0, 0.0, 1.0, 1.0);
    let y1 = run(&m, 1, 1, &[(1.0, 1.0, None)], 0.0, false)[0].y;
    let (x1, p1, _nu1, s1, k1) = correct(xp, &pp, y1, None);
    let (xi, pi) = info_correct(xp, &pp, y1);
    for (lab, v) in [("pole length l (m)", L), ("push: angular acceleration sd (rad/s^2)", SA), ("F: cosh 0.04", m.f[0][0]), ("F: sinh 0.04 / 4 (s)", m.f[0][1]), ("F: 4 sinh 0.04 (per s)", m.f[1][0]),
                     ("G: angle per m/s^2 of cart", m.gu[0]), ("G: rate per m/s^2 of cart", m.gu[1]),
                     ("Q: angle sd added per step (rad)", m.q[0][0].sqrt()), ("Q: rate sd added per step", m.q[1][1].sqrt()),
                     ("step 1 predicted angle var P-", pp[0][0]), ("step 1 predicted rate var", pp[1][1]),
                     ("step 1 predicted covariance", pp[0][1]), ("step 1 reading y1 (rad)", y1), ("step 1 S = P- + R", s1),
                     ("step 1 gain on angle", k1[0]), ("step 1 gain on rate (per s)", k1[1]),
                     ("step 1 angle estimate", x1[0]), ("  by precisions", xi[0]), ("step 1 rate estimate", x1[1]),
                     ("  by precisions", xi[1]), ("step 1 rate sd after", p1[1][1].sqrt()), ("  by precisions", pi[1][1].sqrt())] { show(lab, v); }
    // ---- the steady gain: Riccati recursion, then a brute-force search over fixed gains ----
    let (mut p, mut settle) = (P0, Vec::new());
    let (mut sinf, mut kinf) = (0.0, [0.0, 0.0]);
    for k in 1..=1000 {
        let pm = predict(&m, [0.0, 0.0], &p, 0.0, 1.0, 1.0).1;
        let c = correct([0.0, 0.0], &pm, 0.0, None); (p, sinf, kinf) = (c.1, c.3, c.4);
        if [1, 2, 3, 5, 10, 20, 50, 100].contains(&k) { settle.push((k, kinf[1], p[1][1].sqrt(), pm[1][1].sqrt())); }
    }
    println!("settling, step      {}", settle.iter().map(|s| format!("{:>8}", s.0)).collect::<String>());
    println!("  gain on rate      {}", settle.iter().map(|s| format!("{:>8.3}", s.1)).collect::<String>());
    println!("  rate sd predicted {}", settle.iter().map(|s| format!("{:>8.4}", s.3)).collect::<String>());
    println!("  rate sd (rad/s)   {}", settle.iter().map(|s| format!("{:>8.4}", s.2)).collect::<String>());
    let (mut ks, mut step, mut rounds) = ([0.5, 5.0], [0.1, 1.0], 0); let mut best = cost(&m, ks);
    while step[0] > 1e-7 && rounds < 200 {          // pattern search; it needs 35 rounds, give up after 200
        let mut moved = false; rounds += 1;
        for i in 0..2 {
            for sgn in [1.0, -1.0] {
                let mut trial = ks; trial[i] += sgn * step[i];
                if trial[0] < 1.0 { let c = cost(&m, trial); if c < best { ks = trial; best = c; moved = true; } }
            }
        }
        if !moved { step = [step[0] / 2.0, step[1] / 2.0]; }
    }
    for (lab, v) in [("steady gain on angle", kinf[0]), ("  by search", ks[0]), ("steady gain on rate (per s)", kinf[1]),
                     ("  by search", ks[1]), ("steady angle sd (rad)", p[0][0].sqrt()), ("steady rate sd (rad/s)", p[1][1].sqrt()),
                     ("steady innovation sd (rad)", sinf.sqrt()), ("rate sd from differencing (rad/s)", (2.0 * R).sqrt() / DT)] { show(lab, v); }
    // ---- 2000 runs of 2 seconds: errors and surprises over the last second ----
    let vars: [Var; 4] = [(1.0, 1.0, None), (0.01, 1.0, None), (1.0, 0.0, None), (1.0, 1.0, Some([2.0 * kinf[0], 2.0 * kinf[1]]))];
    let names = ["the filter", "Q 100 times too small", "input left out of predict", "twice the steady gain"];
    let (mut acc, mut fd2, mut n) = ([[0.0_f64; 4]; 4], 0.0, 0.0);
    for seed in 1..=2000u64 {
        let out = run(&m, seed, 200, &vars, 0.0, false);
        for k in 100..200 {
            let st = &out[k]; n += 1.0; fd2 += (st.fd - st.t[1]).powi(2);
            for (i, &(x, nu, s)) in st.rec.iter().enumerate() {
                let (z, zp) = (nu / s.sqrt(), out[k - 1].rec[i].1 / out[k - 1].rec[i].2.sqrt());
                let a = &mut acc[i];
                a[0] += (x[0] - st.t[0]).powi(2); a[1] += (x[1] - st.t[1]).powi(2); a[2] += z * z; a[3] += z * zp;
            }
        }
    }
    let st: Vec<[f64; 4]> = acc.iter().map(|a| [(a[0] / n).sqrt(), (a[1] / n).sqrt(), a[2] / n, a[3] / a[2]]).collect();
    for (nm, v) in names.iter().zip(&st) {
        println!("{:<26} angle rms {:.6}  rate rms {:.4}  surprise^2/S {:.3}  lag-1 {:+.3}", nm, v[0], v[1], v[2], v[3]);
    }
    println!("differencing the encoder   rate rms {:.4}", (fd2 / n).sqrt());
    // ---- one run (seed 1) for the chart: every 0.1 s ----
    let story = run(&m, 1, 200, &vars[..1], 0.0, false); let pick: [(&str, fn(&Step, usize) -> f64); 4] = [("chart, time (s)", |_, k| (k + 1) as f64 * DT), ("chart, true rate", |o, _| o.t[1]),
                                                    ("chart, filter rate", |o, _| o.rec[0].0[1]), ("chart, differenced", |o, _| o.fd)];
    for (lab, f) in pick {
        let row: Vec<String> = (9..200).step_by(10).map(|k| format!("{:5.2}", f(&story[k], k))).collect();
        println!("{:<19}{}", lab, row.join(" "));
    }
    let (mut e, mut t, a): (M2, M2, M2) = ([[1.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]], [[0.0, DT], [16.0 * DT, 0.0]]);
    for j in 1..15 { t = std::array::from_fn(|i| std::array::from_fn(|c| (t[i][0] * a[0][c] + t[i][1] * a[1][c]) / j as f64)); for i in 0..2 { for c in 0..2 { e[i][c] += t[i][c]; } } }
    assert!((0..4).all(|z| (e[z / 2][z % 2] - m.f[z / 2][z % 2]).abs() < 1e-14), "cosh-sinh step vs the series");
    assert!((0..2).all(|i| (x1[i] - xi[i]).abs() < 1e-12) && (p1[1][1] - pi[1][1]).abs() < 1e-12, "gain form vs precisions");
    assert!((kinf[0] - ks[0]).abs() < 1e-5 && (kinf[1] - ks[1]).abs() < 1e-4, "Riccati gain vs brute-force search");
    assert!((st[0][1] / p[1][1].sqrt() - 1.0).abs() < 0.03 && (st[0][0] / p[0][0].sqrt() - 1.0).abs() < 0.03, "simulated vs P");
    assert!((st[0][2] - 1.0).abs() < 0.015 && st[0][3].abs() < 0.01, "the filter's surprises: right size, uncorrelated");
    assert!(st[1][2] > 1.5 && st[1][3] > 0.3 && st[3][3] < -0.1, "mis-tuned filters leave a pattern in the surprises");
    assert!(((fd2 / n).sqrt() / ((2.0 * R).sqrt() / DT) - 1.0).abs() < 0.02, "differencing noise vs its formula");
    assert!(st.iter().all(|v| v[1] >= st[0][1]), "no variant beats the filter on the rate");
    assert!(step[0] <= 1e-7, "the brute-force gain search did not settle");
    let mut cs = Vec::new();                       // 200 runs from a 0.5 rad lean, first 0.5 s: straight pole, then curved pole
    for cv in [false, true] {
        let o: Vec<Step> = (1..=200u64).flat_map(|seed| run(&m, seed, 50, &vars[..1], 0.5, cv)).collect(); let n = o.len() as f64;
        cs.push(((o.iter().map(|s| (s.rec[0].0[1] - s.t[1]).powi(2)).sum::<f64>() / n).sqrt(), o.iter().map(|s| s.rec[0].1.powi(2) / s.rec[0].2).sum::<f64>() / n));
    }
    println!("from 0.5 rad, first 0.5 s: straight pole rate rms {:.4} surprise^2/S {:.3}; curved pole {:.4} and {:.3}", cs[0].0, cs[0].1, cs[1].0, cs[1].1);
    assert!((cs[0].1 - 1.0).abs() < 0.05 && cs[1].1 > 1.15, "straight pole: right-sized surprises; curved pole: too big");
    println!("ALL CHECKS PASS");
}
