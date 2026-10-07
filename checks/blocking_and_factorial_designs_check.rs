// Blocking and a 2 x 2 factorial: fertiliser and watering -- the check behind the card.
// Std only. Roads: contrasts on cell means, least squares by Gaussian elimination,
// every complete randomisation enumerated, a seeded simulation (SplitMix64).
use std::f64::consts::PI;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
    fn shuffle(&mut self, a: &mut Vec<usize>) {                  // Fisher-Yates
        for i in (1..a.len()).rev() { let j = (self.uniform() * (i + 1) as f64) as usize; a.swap(i, j); }
    }
}
const NAMES: [&str; 4] = ["neither", "fert", "water", "both"];
const SIGN: [[f64; 4]; 3] = [[-1., 1., -1., 1.], [-1., -1., 1., 1.], [1., -1., -1., 1.]];
fn effects(m: &[f64]) -> [f64; 3] {
    let mut e = [0.0; 3];
    for (i, s) in SIGN.iter().enumerate() { e[i] = s.iter().zip(m).fold(0.0, |a, (s, x)| a + s * x) / 2.0; }
    e
}
fn combos(items: &[usize], k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for i in 0..items.len() {
        for mut rest in combos(&items[i + 1..], k - 1) { rest.insert(0, items[i]); out.push(rest); }
    }
    out
}
fn solve(a: Vec<Vec<f64>>, b: Vec<f64>) -> Vec<f64> {         // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = a.into_iter().zip(b).map(|(mut r, v)| { r.push(v); r }).collect();
    for i in 0..n {
        let mut p = i;
        for t in i + 1..n { if m[t][i].abs() > m[p][i].abs() { p = t; } }
        m.swap(i, p);
        for t in i + 1..n {
            let (f, row) = (m[t][i] / m[i][i], m[i].clone());
            for (x, c) in m[t].iter_mut().zip(row) { *x -= f * c; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let s: f64 = (i + 1..n).fold(0.0, |a, t| a + m[i][t] * x[t]);
        x[i] = (m[i][n] - s) / m[i][i];
    }
    x
}
fn ms(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64; let m = xs.iter().fold(0.0, |a, x| a + x) / n;
    (m, (xs.iter().fold(0.0, |a, x| a + (x - m) * (x - m)) / (n - 1.0)).sqrt())
}
fn main() {
    let mut g = Rng(20260929);
    let (truth, strip, sigma) = ([20.0, 24.0, 26.0, 36.0], [-4.0, 0.0, 4.0], 1.5f64);
    let y = [[17.0, 19.0, 22.0, 34.0], [19.0, 24.0, 27.0, 35.0], [23.0, 31.0, 29.0, 39.0]];
    let (r, n, rf) = (3usize, 12usize, 3.0);
    // road 1: contrasts on cell means, sums of squares by formula
    let cell: Vec<f64> = (0..4).map(|k| (0..r).fold(0.0, |a, j| a + y[j][k]) / rf).collect();
    let blk: Vec<f64> = y.iter().map(|row| row.iter().fold(0.0, |a, v| a + v) / 4.0).collect();
    let grand = blk.iter().fold(0.0, |a, b| a + b) / rf;
    let eff = effects(&cell);
    let (mut res_ss, mut within_ss) = (0.0, 0.0);
    for j in 0..r { for k in 0..4 {
        res_ss += (y[j][k] - blk[j] - cell[k] + grand).powi(2);
        within_ss += (y[j][k] - cell[k]).powi(2);
    } }
    let strip_ss = 4.0 * blk.iter().fold(0.0, |a, b| a + (b - grand).powi(2));
    let (s2_b, s2_u) = (res_ss / ((r - 1) * 3) as f64, within_ss / (4 * (r - 1)) as f64);
    let (se_b, se_u) = ((s2_b / rf).sqrt(), (s2_u / rf).sqrt());
    // road 2: least squares on strip indicators and +/-1 columns
    let (mut xm, mut yv) = (vec![], vec![]);
    for j in 0..r { for k in 0..4 {
        let (xf, xw) = (if k == 1 || k == 3 { 1.0 } else { -1.0 }, if k == 2 || k == 3 { 1.0 } else { -1.0 });
        let mut row: Vec<f64> = (0..r).map(|b| if b == 0 || j == b { 1.0 } else { 0.0 }).collect();
        row.extend([xf, xw, xf * xw]); xm.push(row); yv.push(y[j][k]);
    } }
    let p = xm[0].len();
    let xtx: Vec<Vec<f64>> = (0..p).map(|a| (0..p).map(|b| xm.iter().fold(0.0, |s, row| s + row[a] * row[b])).collect()).collect();
    let xty: Vec<f64> = (0..p).map(|a| xm.iter().zip(&yv).fold(0.0, |s, (row, v)| s + row[a] * v)).collect();
    let beta = solve(xtx.clone(), xty);
    let ls_eff = [2.0 * beta[p - 3], 2.0 * beta[p - 2], 2.0 * beta[p - 1]];
    let ls_res = xm.iter().zip(&yv).fold(0.0, |s, (row, v)| {
        let fit = row.iter().zip(&beta).fold(0.0, |a, (x, b)| a + x * b);
        s + (v - fit) * (v - fit)
    });
    let ls_se: Vec<f64> = (p - 3..p).map(|a| 2.0 * (ls_res / 6.0 * solve(xtx.clone(), (0..p).map(|t| if t == a { 1.0 } else { 0.0 }).collect())[a]).sqrt()).collect();
    // road 3: every complete randomisation of the 12 plots, strips ignored
    let base: Vec<f64> = strip.iter().flat_map(|&b| [b; 4]).collect();
    let bmean = base.iter().fold(0.0, |a, b| a + b) / n as f64;
    let sb2 = base.iter().fold(0.0, |a, b| a + (b - bmean).powi(2)) / (n - 1) as f64;   // S_b^2
    let (mut tot, mut tot2, mut cnt, all) = (0.0, 0.0, 0u64, (0..n).collect::<Vec<usize>>());
    let mean3 = |gr: &[usize]| gr.iter().fold(0.0, |a, &i| a + base[i]) / 3.0;
    for g0 in combos(&all, 3) {
        let rest: Vec<usize> = all.iter().copied().filter(|i| !g0.contains(i)).collect();
        for g1 in combos(&rest, 3) {
            let rest2: Vec<usize> = rest.iter().copied().filter(|i| !g1.contains(i)).collect();
            for g2 in combos(&rest2, 3) {
                let g3: Vec<usize> = rest2.iter().copied().filter(|i| !g2.contains(i)).collect();
                let fb = (-mean3(&g0) + mean3(&g1) - mean3(&g2) + mean3(&g3)) / 2.0;
                tot += fb; tot2 += fb * fb; cnt += 1;
            }
        }
    }
    let (enum_mean, enum_var) = (tot / cnt as f64, tot2 / cnt as f64 - (tot / cnt as f64).powi(2));
    let order: Vec<Vec<usize>> = (0..r).map(|_| { let mut o = vec![0, 1, 2, 3]; g.shuffle(&mut o); o }).collect(); // field plan
    // road 4: seeded simulation of R seasons, blocked and completely randomised
    let big_r = 20000usize;
    let (mut fb_sim, mut fc_sim, mut s2_sim) = (vec![], vec![], vec![]);
    for _ in 0..big_r {
        let mut yb = [[0.0; 4]; 3];
        for j in 0..r { for k in 0..4 { yb[j][k] = truth[k] + strip[j] + sigma * g.normal(); } }
        let cb: Vec<f64> = (0..4).map(|k| (0..r).fold(0.0, |a, j| a + yb[j][k]) / rf).collect();
        let bb: Vec<f64> = yb.iter().map(|row| row.iter().fold(0.0, |a, v| a + v) / 4.0).collect();
        let gb = bb.iter().fold(0.0, |a, b| a + b) / rf;
        fb_sim.push(effects(&cb)[0]);
        s2_sim.push((0..12).fold(0.0, |a, i| a + (yb[i / 4][i % 4] - bb[i / 4] - cb[i % 4] + gb).powi(2)) / 6.0);
        let (mut lab, mut tc): (Vec<usize>, _) = ((0..4).flat_map(|k| vec![k; r]).collect(), [0.0; 4]);
        g.shuffle(&mut lab);
        for i in 0..n { tc[lab[i]] += truth[lab[i]] + base[i] + sigma * g.normal(); }
        fc_sim.push(effects(&tc.map(|t| t / rf))[0]);
    }
    let ((mb, sdb), (mc, sdc), (m2, sd2)) = (ms(&fb_sim), ms(&fc_sim), ms(&s2_sim));
    let (ex_b, ex_c) = ((sigma * sigma / rf).sqrt(), ((sigma * sigma + sb2) / rf).sqrt());
    let (rr, te, nf) = (big_r as f64, effects(&truth), n as f64);
    println!("true effects       F {:.4}  W {:.4}  I {:.4}  strips {:.1} {:.1} {:.1}  sigma {:.1}", te[0], te[1], te[2], strip[0], strip[1], strip[2], sigma);
    let cm: Vec<String> = (0..4).map(|k| format!("{} {:.4}", NAMES[k], cell[k])).collect();
    println!("cell means, kg     {}", cm.join("  "));
    println!("strip means, kg    {:.4}  {:.4}  {:.4}  grand {:.4}", blk[0], blk[1], blk[2], grand);
    for (i, name) in ["fertiliser", "watering", "interaction"].iter().enumerate() {
        println!("{:<12} contrast {:8.4}  least squares {:8.4}  SE {:.4}", name, eff[i], ls_eff[i], se_b);
    }
    println!("fertiliser effect, dry plots {:.4}  watered plots {:.4}", cell[1] - cell[0], cell[3] - cell[2]);
    println!("additive guess for both {:.4}  observed {:.4}", cell[1] + cell[2] - cell[0], cell[3]);
    println!("residual SS, formula {:.4}  least squares {:.4}  df {}", res_ss, ls_res, (r - 1) * 3);
    println!("blocked analysis    s^2 {:.4}  s {:.4}  SE of an effect {:.4}", s2_b, s2_b.sqrt(), se_b);
    println!("strips ignored      s^2 {:.4}  s {:.4}  SE of an effect {:.4}", s2_u, s2_u.sqrt(), se_u);
    println!("strip SS {:.4}  within-cell SS {:.4}", strip_ss, within_ss);
    println!("S_b^2, spread of plot baselines {:.4}", sb2);
    println!("enumerated randomisations {}  mean {:.4}  variance {:.4}  S_b^2/r {:.4}", cnt, enum_mean, enum_var, sb2 / rf);
    println!("exact SD of F-hat: blocked {:.4}  completely randomised {:.4}  variance ratio {:.4}", ex_b, ex_c, ex_c * ex_c / (ex_b * ex_b));
    println!("simulated {} seasons: blocked mean {:.4} SD {:.4} (+/- {:.4})", big_r, mb, sdb, sdb / (2.0 * rr).sqrt());
    println!("  completely randomised mean {:.4} SD {:.4} (+/- {:.4})", mc, sdc, sdc / (2.0 * rr).sqrt());
    println!("  mean s^2 {:.4} (+/- {:.4})  true sigma^2 {:.4}", m2, sd2 / rr.sqrt(), sigma * sigma);
    println!("one at a time, 12 plots: SE {:.4}  factorial SE {:.4}  plots to match {}", (6.0 * sigma * sigma / nf).sqrt(), (4.0 * sigma * sigma / nf).sqrt(), 6 * n / 4);
    println!("chart, dry then watered, unfertilised {:.2} {:.2}, fertilised {:.2} {:.2}", cell[0], cell[2], cell[1], cell[3]);
    for (j, nm) in ["top", "middle", "bottom"].iter().enumerate() {
        let parts: Vec<String> = order[j].iter().map(|&k| format!("{} {}", NAMES[k], y[j][k])).collect();
        println!("figure, {} strip at y={}, plots 70 x 60 at x=70,140,210,280: {}", nm, 20 + 70 * j, parts.join(", "));
    }
    for i in 0..3 { assert!((eff[i] - ls_eff[i]).abs() < 1e-9, "contrast vs least squares"); }
    assert!((res_ss - ls_res).abs() < 1e-9, "residual SS: formula vs least squares");
    for se in &ls_se { assert!((se - se_b).abs() < 1e-9, "SE of an effect: sqrt(s^2 / r) vs least squares"); }
    assert!((within_ss - res_ss - strip_ss).abs() < 1e-9, "strips ignored: their SS joins the residual");
    assert!((enum_var - sb2 / rf).abs() < 1e-9, "enumerated variance vs S_b^2 / r");
    assert!(enum_mean.abs() < 1e-9, "over all randomisations the strips add no bias to F-hat");
    assert!((sdb / ex_b - 1.0).abs() < 0.025, "blocked: simulated SD vs sigma / sqrt(r)");
    assert!((sdc / ex_c - 1.0).abs() < 0.025, "randomised: simulated SD vs sqrt((sigma^2 + S_b^2) / r)");
    for (m, sd) in [(mb, sdb), (mc, sdc)] { assert!((m - te[0]).abs() < 4.0 * sd / rr.sqrt(), "both designs: F-hat centred on the true effect"); }
    assert!((m2 - sigma * sigma).abs() < 4.0 * sd2 / rr.sqrt(), "residual variance with (r-1)*3 df is unbiased");
    println!("ALL CHECKS PASS");
}
