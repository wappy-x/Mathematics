// Extended and unscented filters on a pole swung far from upright -- the check behind the card.  std only.
// Roads: the step's slope matrix by series, by closed form and by finite differences; the unscented step against
// the exact mean of a sine and against 200,000 random draws; every filter scored against simulated truth.
use std::f64::consts::PI;
const DT: f64 = 0.01; const GL: f64 = 16.0;  // 100 hertz; g/l (per s^2) for a pole 9.81/16 = 0.613125 m long
const SA: f64 = 1.0; const SR: f64 = 0.005;  // random angular acceleration sd (rad/s^2); encoder sd (rad)
const TH0: f64 = 0.3;                        // let go 0.3 rad from upright
type V = [f64; 2]; type M = [[f64; 2]; 2];
const P0: M = [[0.05 * 0.05, 0.0], [0.0, 0.5 * 0.5]]; // the filter's start belief
const GV: V = [DT * DT / 2.0, DT]; // what a held angular acceleration of 1 rad/s^2 adds in one step
const R: f64 = SR * SR;

struct Rng(u64); // SplitMix64 bits, Box-Muller normals
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn n(&mut self) -> f64 { let a = 1.0 - self.u(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * self.u()).cos() }
}
fn q(i: usize, j: usize) -> f64 { SA * SA * GV[i] * GV[j] }
fn f(x: V) -> V { // one 0.01 s step of theta'' = 16 sin(theta): RK4 in 4 slices
    let (mut th, mut om, h) = (x[0], x[1], DT / 4.0);
    for _ in 0..4 {
        let (a1, b1) = (om, GL * th.sin());
        let (a2, b2) = (om + h / 2.0 * b1, GL * (th + h / 2.0 * a1).sin());
        let (a3, b3) = (om + h / 2.0 * b2, GL * (th + h / 2.0 * a2).sin());
        let (a4, b4) = (om + h * b3, GL * (th + h * a3).sin());
        th += h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4); om += h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4);
    }
    [th, om]
}
fn jac(th: f64) -> M { // e^(A dt), A = [[0, 1], [k, 0]], k = 16 cos(theta): A^2 = k I
    let k = GL * th.cos();
    let (mut c, mut s, mut t) = (0.0, 0.0, 1.0);
    for m in 0..8 { let m = m as f64; c += t; s += t * DT / (2.0 * m + 1.0); t *= k * DT * DT / ((2.0 * m + 1.0) * (2.0 * m + 2.0)); }
    [[c, s], [k * s, c]]
}
fn fpf(f: &M, p: &M, qf: f64) -> M {
    let (mut fp, mut o) = ([[0.0; 2]; 2], [[0.0; 2]; 2]);
    for i in 0..2 { for j in 0..2 { fp[i][j] = f[i][0] * p[0][j] + f[i][1] * p[1][j]; } }
    for i in 0..2 { for j in 0..2 { o[i][j] = fp[i][0] * f[j][0] + fp[i][1] * f[j][1] + qf * q(i, j); } }
    o
}
fn sigma(x: V, p: &M) -> ([V; 5], [f64; 5]) { // 2n + 1 = 5 points, n + kappa = 3: weights 1/3, then 1/6 each
    let a = p[0][0].sqrt(); let b = p[1][0] / a; let c = (p[1][1] - b * b).max(0.0).sqrt(); let r3 = 3f64.sqrt();
    ([x, [x[0] + r3 * a, x[1] + r3 * b], [x[0] - r3 * a, x[1] - r3 * b], [x[0], x[1] + r3 * c], [x[0], x[1] - r3 * c]],
     [1.0 / 3.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0])
}
fn predict(kind: u8, x: V, p: &M, qf: f64) -> (V, M) {
    if kind == 0 { return (f(x), fpf(&jac(x[0]), p, qf)); } // extended: centre moved exactly, slope at the centre
    if kind == 2 { let fm = jac(0.0); return ([fm[0][0] * x[0] + fm[0][1] * x[1], fm[1][0] * x[0] + fm[1][1] * x[1]], fpf(&fm, p, qf)); }
    let (pts, w) = sigma(x, p); // unscented: push the five points, refit
    let ys: Vec<V> = pts.iter().map(|&pt| f(pt)).collect();
    let (mut m, mut o) = ([0.0; 2], [[0.0; 2]; 2]);
    for i in 0..2 { for j in 0..5 { m[i] += w[j] * ys[j][i]; } }
    for i in 0..2 { for l in 0..2 { for j in 0..5 { o[i][l] += w[j] * (ys[j][i] - m[i]) * (ys[j][l] - m[l]); } o[i][l] += qf * q(i, l); } }
    (m, o)
}
fn correct(x: V, p: &M, y: f64, rr: f64) -> (V, M, f64, f64, V) { // the encoder reads the angle
    let s = p[0][0] + rr * R; let k = [p[0][0] / s, p[1][0] / s]; let nu = y - x[0];
    let pn = [[p[0][0] - k[0] * p[0][0], p[0][1] - k[0] * p[0][1]], [p[1][0] - k[1] * p[0][0], p[1][1] - k[1] * p[0][1]]];
    ([x[0] + k[0] * nu, x[1] + k[1] * nu], pn, nu, s, k)
}
type Rec = (V, M, f64, f64);
fn run(seed: u64, steps: usize, vars: &[(u8, f64, f64)], blind: (usize, usize)) -> Vec<(V, f64, Vec<Rec>)> {
    let (mut r, mut t, mut out) = (Rng(seed), [TH0, 0.0], Vec::new());
    let mut est: Vec<(V, M)> = vars.iter().map(|_| ([TH0, 0.0], P0)).collect();
    for k in 1..=steps {
        let w = SA * r.n(); t = f(t); t = [t[0] + GV[0] * w, t[1] + GV[1] * w];
        let (y, mut rec) = (t[0] + SR * r.n(), Vec::new());
        for (i, &(kind, qf, rr)) in vars.iter().enumerate() {
            let (mut x, mut p) = predict(kind, est[i].0, &est[i].1, qf);
            let (mut nu, mut s) = (f64::NAN, f64::NAN);
            if !(blind.0 <= k && k < blind.1) { let c = correct(x, &p, y, rr); x = c.0; p = c.1; nu = c.2; s = c.3; }
            est[i] = (x, p); rec.push((x, p, nu, s));
        }
        out.push((t, y, rec));
    }
    out
}
fn show(rows: &[(&str, f64)]) { for (l, v) in rows { println!("{:<44} {:>12.6}", l, v); } }
fn fd(x: V) -> M { // finite differences of the actual step, column by column
    let (e, mut o) = (1e-6, [[0.0; 2]; 2]);
    for j in 0..2 { let (mut a, mut b) = (x, x); a[j] += e; b[j] -= e; let (u, d) = (f(a), f(b)); for i in 0..2 { o[i][j] = (u[i] - d[i]) / (2.0 * e); } }
    o
}
fn main() {
    let (fup, fbot, fhor, fd_bot, fd_hor) = (jac(0.0), jac(PI), jac(PI / 2.0), fd([PI, 0.0]), fd([PI / 2.0, 0.0]));
    let mut x = [TH0, 0.0]; for _ in 0..300 { x = f(x); }
    let drift = (x[1] * x[1] / 2.0 + GL * x[0].cos() - GL * TH0.cos()).abs();
    show(&[("pole length l = 9.81 / 16 (m)", 9.81 / GL), ("start angle 0.3 rad in degrees", TH0.to_degrees()), ("wide belief sd 0.5 rad in degrees", 0.5f64.to_degrees()),
        ("slope at upright, cosh 0.04", fup[0][0]), ("  4 sinh 0.04 (per s)", fup[1][0]), ("slope at bottom, cos 0.04", fbot[0][0]),
        ("  -4 sin 0.04 (per s)", fbot[1][0]), ("  by finite differences", fd_bot[1][0]), ("slope at horizontal, angle per rate (s)", fhor[0][1]),
        ("  rate per angle (per s)", fhor[1][0]), ("  by finite differences", fd_hor[1][0]), ("energy drift over 3 s, no noise (per s^2)", drift)]);
    // ---- one extended step by hand, from the start belief ----
    let (xp, pp) = predict(0, [TH0, 0.0], &P0, 1.0); let f1 = jac(TH0);
    let y1 = run(1, 1, &[(0, 1.0, 1.0)], (0, 0))[0].1;
    let (x1, _p1, _nu1, s1, k1) = correct(xp, &pp, y1, 1.0);
    show(&[("step 1: k = 16 cos 0.3 (per s^2)", GL * TH0.cos()), ("step 1: slope, diagonal", f1[0][0]), ("step 1: slope, angle per rate (s)", f1[0][1]),
        ("step 1: slope, rate per angle (per s)", f1[1][0]), ("step 1: predicted angle (rad)", xp[0]), ("step 1: predicted rate (rad/s)", xp[1]),
        ("step 1: predicted angle var", pp[0][0]), ("step 1: predicted covariance", pp[0][1]), ("step 1: reading (rad)", y1), ("step 1: S", s1),
        ("step 1: gain on angle", k1[0]), ("step 1: gain on rate (per s)", k1[1]), ("step 1: angle estimate (rad)", x1[0]), ("step 1: rate estimate (rad/s)", x1[1])]);
    // ---- a wide belief at the horizontal pole: gravity's push 16 sin(theta), angle sd 0.5 rad ----
    let sd = 0.5; let (pts, w) = sigma([PI / 2.0, 0.0], &[[sd * sd, 0.0], [0.0, 0.01]]);
    let pu: Vec<f64> = pts.iter().map(|p| GL * p[0].sin()).collect();
    let mu: f64 = (0..5).map(|j| w[j] * pu[j]).sum();
    let sdu = (0..5).map(|j| w[j] * (pu[j] - mu).powi(2)).sum::<f64>().sqrt();
    let (ex, exsd) = (GL * (-sd * sd / 2.0).exp(), GL * (1.0 - (-sd * sd).exp()) / 2f64.sqrt());
    let mut r = Rng(7); let mc: Vec<f64> = (0..200000).map(|_| GL * (PI / 2.0 + sd * r.n()).sin()).collect();
    let mcm = mc.iter().sum::<f64>() / mc.len() as f64;
    let mcsd = (mc.iter().map(|v| (v - mcm).powi(2)).sum::<f64>() / mc.len() as f64).sqrt();
    show(&[("wide belief: sigma point angle offset (rad)", 3f64.sqrt() * sd), ("  push at the offset points", pu[1]), ("  push, unscented mean", mu),
        ("  push, exact mean 16 exp(-sd^2/2)", ex), ("  push, 200000 draws", mcm), ("  push, extended (tangent) mean", GL), ("  sd, unscented", sdu),
        ("  sd, exact", exsd), ("  sd, 200000 draws", mcsd), ("  sd, extended (tangent)", (GL * (PI / 2.0).cos()).abs() * sd)]);
    // ---- 300 runs of 3 s at 100 hertz, scored from 0.5 s on ----
    let vars = [(0u8, 1.0, 1.0), (1, 1.0, 1.0), (2, 1.0, 1.0), (0, 0.01, 1.0), (0, 0.1, 1.0), (0, 100.0, 1.0), (0, 1.0, 100.0)];
    let names = ["extended filter", "unscented filter", "frozen at upright", "extended, Q / 100", "extended, Q / 10", "extended, Q x 100", "extended, R x 100"];
    let (mut acc, mut n) = ([[0.0f64; 5]; 7], 0.0);
    for seed in 1..=300u64 {
        let out = run(seed, 300, &vars, (0, 0));
        for k in 50..300 {
            let (t, _, rec) = &out[k]; n += 1.0;
            for (i, (x, p, nu, s)) in rec.iter().enumerate() {
                let (z, zp) = (nu / s.sqrt(), out[k - 1].2[i].2 / out[k - 1].2[i].3.sqrt());
                let a = &mut acc[i]; a[0] += (x[0] - t[0]).powi(2); a[1] += (x[1] - t[1]).powi(2); a[2] += z * z; a[3] += z * zp; a[4] += p[1][1];
            }
        }
    }
    let st: Vec<[f64; 5]> = acc.iter().map(|a| [(a[0] / n).sqrt(), (a[1] / n).sqrt(), a[2] / n, a[3] / a[2], (a[4] / n).sqrt()]).collect();
    for (nm, s) in names.iter().zip(&st) { println!("{:<19} angle rms {:.4}  rate rms {:.4}  claimed {:.4}  surprise^2/S {:8.3}  lag-1 {:+.3}", nm, s[0], s[1], s[4], s[2], s[3]); }
    // ---- the encoder drops out after 0.5 s; one reading comes back; runs split by whether the pole tipped over ----
    let (mut drop, mut tl) = ([[[0.0f64; 4]; 2]; 6], [[0.0f64; 8]; 2]); // drop[3 x blind + all / tipped / not tipped][filter]; tl: at 1.7, 2.3, 2.5, 2.9 s
    for (di, &d) in [100usize, 250].iter().enumerate() {
        for seed in 1..=300u64 {
            let out = run(seed, 50 + d, &vars[..2], (51, 50 + d)); let tip = out.iter().any(|o| !(0.0 < o.0[0] && o.0[0] < 2.0 * PI));
            for (i, (_, _, nu, s)) in out.last().unwrap().2.iter().enumerate() {
                for g in [3 * di, 3 * di + if tip { 1 } else { 2 }] { let a = &mut drop[g][i]; a[0] += 1.0; if nu * nu > 9.0 * s { a[1] += 1.0; } a[2] += nu * nu; a[3] += s; }
                if d == 250 { for (j, &k) in [169usize, 229, 249, 289].iter().enumerate() { tl[i][2 * j] += out[k].2[i].1[0][0]; tl[i][2 * j + 1] += (out[k].2[i].0[0] - out[k].0[0]).powi(2); } }
            }
        }
    }
    let ms = |g: usize, i: usize| { let a = drop[g][i]; [(a[2] / a[0]).sqrt(), (a[3] / a[0]).sqrt(), a[1] / a[0]] }; // miss rms, claimed, beyond 3 sd
    for (g, d, lab) in [(0, 1.0, "all"), (3, 2.5, "all"), (4, 2.5, "tipped"), (5, 2.5, "not tipped")] { println!("blind {:.1} s, {:<10} {:3} runs{}", d, lab, drop[g][0][0] as usize, (0..2).map(|i| format!("  {}: miss rms {:6.3} rad, claimed {:.3} rad, beyond 3 sd {:.3}", names[i].split(' ').next().unwrap(), ms(g, i)[0], ms(g, i)[1], ms(g, i)[2])).collect::<String>()); }
    for i in 0..2 { println!("blind 2.5 s, {:<9} claimed / real angle sd (rad) at 1.7, 2.3, 2.5, 2.9 s{}", names[i].split(' ').next().unwrap(), (0..8).step_by(2).map(|j| format!("  {:.3} / {:.3}", (tl[i][j] / 300.0).sqrt(), (tl[i][j + 1] / 300.0).sqrt())).collect::<String>()); }
    // ---- one run (seed 1) for the chart: every 0.1 s ----
    let story = run(1, 300, &vars[..3], (0, 0));
    let line = |lab: &str, g: &dyn Fn(usize) -> f64| {
        let v: Vec<String> = (9..300).step_by(10).map(|k| format!("{:5.1}", g(k))).collect();
        println!("{:<21}{}", lab, v.join(" "));
    };
    line("chart, time (s)", &|k| (k + 1) as f64 * DT);
    line("chart, true rate", &|k| story[k].0[1]);
    line("chart, extended rate", &|k| story[k].2[0].0[1]);
    line("chart, frozen rate", &|k| story[k].2[2].0[1]);
    let e = [[0.04f64.cosh(), 0.04f64.sinh() / 4.0], [4.0 * 0.04f64.sinh(), 0.04f64.cosh()]];
    assert!((0..4).all(|m| (fup[m / 2][m % 2] - e[m / 2][m % 2]).abs() < 1e-14), "series vs cosh-sinh at upright");
    assert!((fbot[1][0] + 4.0 * 0.04f64.sin()).abs() < 1e-14 && (fd_bot[1][0] - fbot[1][0]).abs() < 1e-8, "slope at bottom");
    assert!((fd_hor[1][0] - fhor[1][0]).abs() < 1e-4 && drift < 1e-6, "frozen slope near the step's own; RK4 keeps energy");
    assert!((xp[0] - (TH0 + GL * TH0.sin() * DT * DT / 2.0)).abs() < 1e-6, "predicted angle vs the hand formula");
    assert!((mu - ex).abs() < 0.01 && (mcm - ex).abs() < 4.0 * exsd / 2e5f64.sqrt() && (sdu / exsd - 1.0).abs() < 0.1, "unscented vs exact vs draws");
    assert!((st[0][1] / st[0][4] - 1.0).abs() < 0.03 && (st[0][2] - 1.0).abs() < 0.015 && st[0][3].abs() < 0.01, "extended filter is honest");
    assert!((st[1][1] / st[0][1] - 1.0).abs() < 0.01 && st[2][2] > 100.0, "unscented agrees; frozen filter diverges");
    assert!(st[3][2] > st[4][2] && st[4][2] > st[0][2] && st[3][3] > 0.3 && st[6][2] < 0.1 && st[6][3] > 0.3 && st[5][3] < -0.1, "mis-tuning shows in the surprises");
    assert!(ms(0, 0)[2] < 0.02 && (0..2).all(|i| ms(4, i)[0] > 2.0 * PI && ms(4, i)[1] < 1.25 * ms(5, i)[1]), "both miss the tipped runs; neither claim marks them");
    assert!(ms(5, 0)[0] < ms(5, 1)[0] && ms(5, 1)[0] < ms(5, 1)[1] / 2.0 && (0..2).all(|i| (tl[i][2] / tl[i][3] - 1.0).abs() < 0.2) && 9.0 * tl[0][6] < tl[0][7], "untipped runs; when the claims part");
    println!("ALL CHECKS PASS");
}
