// Worst-of autocallable on three house shares -- the check behind the card. std only.
// Road 1: Monte Carlo with a Cholesky factor. Road 2: nested quadrature at correlation 1 (one share).
// Road 3: one-factor quadrature for the last quarter, against Monte Carlo with common random numbers.
const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T3: usize = 3; const PRICE: f64 = 98.0;
const CALL: f64 = 100.0; const KNOCK: f64 = 70.0; const OTHERS: f64 = 120.0; const TLEFT: f64 = 0.25; const BUMP: f64 = 2.0;
const PI: f64 = std::f64::consts::PI;

fn ncdf(x: f64) -> f64 { // normal CDF from a written-out erfc (Chebyshev fit, error below 1.2e-7)
    let z = x.abs() / 2f64.sqrt(); let t = 1.0 / (1.0 + 0.5 * z); let e = t * (-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418 + t * (-0.18628806
        + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277))))))))).exp();
    if x >= 0.0 { 1.0 - 0.5 * e } else { 0.5 * e }
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
struct Rng { x: u64, spare: Option<f64> } // splitmix64 uniforms, Box-Muller normals
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn g(&mut self) -> f64 {
        if let Some(v) = self.spare.take() { return v; }
        let a = (-2.0 * self.u().ln()).sqrt(); let b = 2.0 * PI * self.u();
        self.spare = Some(a * b.sin()); a * b.cos()
    }
}
fn cholesky(rho: f64) -> [[f64; 3]; 3] { // 3 by 3, every pair at rho
    let mut l = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..=i {
        let mut acc = 0.0; for k in 0..j { acc += l[i][k] * l[j][k]; }
        let s = (if i == j { 1.0 } else { rho }) - acc;
        l[i][j] = if i == j { s.sqrt() } else { s / l[j][j] };
    } }
    l
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64; let m = xs.iter().fold(0.0, |s, x| s + x) / n;
    (m, (xs.iter().fold(0.0, |s, x| s + (x - m) * (x - m)) / (n - 1.0) / n).sqrt())
}
fn note_mc(rho: f64, n: usize, seed: u64) -> Vec<(f64, f64)> { // per path: (no-coupon value, coupon-years)
    let l = if rho < 1.0 { cholesky(rho) } else { [[1.0, 0.0, 0.0], [1.0, 0.0, 0.0], [1.0, 0.0, 0.0]] };
    let mut g = Rng { x: seed, spare: None }; let mut out = Vec::with_capacity(n);
    for _ in 0..n {
        let mut x = [0.0f64; 3]; let mut done: Option<(f64, f64)> = None; let (mut w, mut df) = (0.0, 0.0);
        for yr in 1..=T3 {
            let z = [g.g(), g.g(), g.g()];
            for i in 0..3 { x[i] = x[i] + R - Q - 0.5 * SIG * SIG + SIG * (0.0 + l[i][0] * z[0] + l[i][1] * z[1] + l[i][2] * z[2]); }
            w = 100.0 * x[0].min(x[1]).min(x[2]).exp(); df = (-R * yr as f64).exp();
            if done.is_none() && w >= CALL { done = Some((100.0 * df, yr as f64 * df)); }
        }
        out.push(done.unwrap_or((df * (if w >= KNOCK { 100.0 } else { w }), 0.0)));
    }
    out
}
fn fair(p: &[(f64, f64)]) -> (f64, f64, f64, f64) { // value is A + 100 c B on every path
    let n = p.len() as f64;
    let a = p.iter().fold(0.0, |s, x| s + x.0) / n; let b = p.iter().fold(0.0, |s, x| s + x.1) / n;
    let c = (PRICE - a) / (100.0 * b);
    let v: Vec<f64> = p.iter().map(|x| x.0 + 100.0 * c * x.1).collect();
    (a, b, c, mean_se(&v).1 / (100.0 * b))
}
fn note_rho1(c: f64, n: usize) -> f64 { // one share, backwards: closed form in the last year, Simpson before that
    let mu = R - Q - 0.5 * SIG * SIG; let df = (-R).exp();
    let up = |s: f64, k: f64| ncdf(((s / k).ln() + mu) / SIG);
    let v2 = |s: f64| df * ((100.0 + 300.0 * c) * up(s, CALL) + 100.0 * (up(s, KNOCK) - up(s, CALL))
        + s * (R - Q).exp() * (1.0 - ncdf(((s / KNOCK).ln() + mu) / SIG + SIG)));
    let roll = |s: f64, k: f64, vnext: &dyn Fn(f64) -> f64| {
        let zs = ((CALL / s).ln() - mu) / SIG;
        let tail = simpson(&|z: f64| vnext(s * (mu + SIG * z).exp()) * (-z * z / 2.0).exp(), -8.0, zs, n);
        df * ((100.0 + 100.0 * k * c) * up(s, CALL) + tail / (2.0 * PI).sqrt())
    };
    roll(100.0, 1.0, &|s: f64| roll(s, 2.0, &v2))
}
fn quad(levels: [f64; 3], sigs: [f64; 3], c: f64) -> f64 { // last quarter: condition on the shared factor
    let (rho, nm, nx) = (0.5f64, 100, 100); let (a, b) = (rho.sqrt(), (1.0 - rho).sqrt());
    let given = |m: f64| {
        let mut mus = [0.0; 3]; let mut sds = [0.0; 3];
        for i in 0..3 { let s = sigs[i];
            mus[i] = (levels[i] / 100.0).ln() + (R - Q - 0.5 * s * s) * TLEFT + s * TLEFT.sqrt() * a * m;
            sds[i] = s * TLEFT.sqrt() * b; }
        let fw = |x: f64| { let mut p = 1.0; for i in 0..3 { p = p * (1.0 - ncdf(((x / 100.0).ln() - mus[i]) / sds[i])); } 1.0 - p };
        100.0 + 300.0 * c * (1.0 - fw(CALL)) - (100.0 - KNOCK) * fw(KNOCK) - simpson(&fw, 1e-6, KNOCK, nx)
    };
    (-R * TLEFT).exp() * simpson(&|m: f64| given(m) * (-m * m / 2.0).exp(), -8.0, 8.0, nm) / (2.0 * PI).sqrt()
}
fn mc_last(draws: &[[f64; 3]], levels: [f64; 3], sigs: [f64; 3], c: f64) -> Vec<f64> {
    let pay = |w: f64| if w >= CALL { 100.0 + 300.0 * c } else if w >= KNOCK { 100.0 } else { w };
    draws.iter().map(|d| { let mut w = f64::INFINITY;
        for i in 0..3 { let s = sigs[i]; w = w.min(levels[i] * ((R - Q - 0.5 * s * s) * TLEFT + s * TLEFT.sqrt() * d[i]).exp()); }
        (-R * TLEFT).exp() * pay(w) }).collect()
}
fn corr_draws(n: usize, seed: u64, l: &[[f64; 3]; 3]) -> Vec<[f64; 3]> {
    let mut g = Rng { x: seed, spare: None };
    (0..n).map(|_| { let z = [g.g(), g.g(), g.g()]; let mut o = [0.0; 3];
        for i in 0..3 { o[i] = 0.0 + l[i][0] * z[0] + l[i][1] * z[1] + l[i][2] * z[2]; } o }).collect()
}

fn main() {
    println!("house: three shares, each at its start level 100, vol 20%, dividend 2%, bank 5%; target price 98");
    let l = cholesky(0.5);
    println!("cholesky at 0.5: rows {}", l.iter().map(|r| format!("({:.6}, {:.6}, {:.6})", r[0], r[1], r[2])).collect::<Vec<_>>().join(" "));
    for i in 0..3 { for j in 0..3 { assert!(((0..3).map(|k| l[i][k] * l[j][k]).sum::<f64>() - if i == j { 1.0 } else { 0.5 }).abs() < 1e-12); } }
    let n3 = 100000; let rhos = [0.0, 0.3, 0.5, 0.8, 1.0]; let mut res = Vec::new();
    for &rho in &rhos {
        let p = note_mc(rho, n3, 2026); let (a, b, c, se) = fair(&p);
        println!("rho {:.1}: no-coupon value {:.4}, coupon-years {:.4}, fair coupon {:.2}% (se {:.2}%)", rho, a, b, 100.0 * c, 100.0 * se);
        res.push((p, c, se)); }
    let c5 = res[2].1; let val = |p: &Vec<(f64, f64)>| p.iter().fold(0.0, |s, x| s + (x.0 + 100.0 * c5 * x.1)) / n3 as f64;
    let vals: Vec<f64> = (1..5).map(|i| val(&res[i].0)).collect();
    let vs: Vec<String> = (1..5).map(|i| format!("{:.1} -> {:.4}", rhos[i], vals[i - 1])).collect();
    println!("note at the 0.5 fair coupon, by correlation: {}", vs.join(", "));
    let (up, dn) = (val(&note_mc(0.55, n3, 2026)), val(&note_mc(0.45, n3, 2026)));
    println!("correlation sensitivity at 0.5, common draws: {:+.4} per 0.01", (up - dn) / 10.0);
    let a1 = note_rho1(0.0, 200); let b1 = (note_rho1(1.0, 200) - a1) / 100.0; let c1 = (PRICE - a1) / (100.0 * b1);
    println!("rho 1.0 by quadrature: no-coupon value {:.4}, coupon-years {:.4}, fair coupon {:.2}%", a1, b1, 100.0 * c1);
    assert!((res[4].1 - c1).abs() < 3.0 * res[4].2, "Monte Carlo at correlation 1 misses the one-share quadrature");
    assert!(res[1].1 > res[2].1 + 5.0 * res[2].2 && res[2].1 + 5.0 * res[2].2 > res[3].1 + 10.0 * res[3].2, "fair coupon not falling in rho");
    assert!(vals[0] < vals[1] && vals[1] < vals[2] && up > dn, "the holder is not long correlation");
    println!("last quarter: other two shares at {:.0}, coupon {:.2}%, bump {:.0} points, vega per vol point; called at year 3 pays {:.2}, a step of {:.2}", OTHERS, 100.0 * c5, BUMP, 100.0 + 300.0 * c5, 300.0 * c5);
    let grid: Vec<i32> = (56..114).step_by(3).collect(); let mut rows: [Vec<f64>; 4] = Default::default();
    let base = [SIG; 3]; let bumped = [SIG + 0.01, SIG, SIG];
    for &lv in &grid { let lv = lv as f64;
        let v = quad([lv, OTHERS, OTHERS], base, c5); let u = quad([lv + BUMP, OTHERS, OTHERS], base, c5); let d = quad([lv - BUMP, OTHERS, OTHERS], base, c5);
        rows[0].push(v); rows[1].push((u - d) / (2.0 * BUMP)); rows[2].push((u - 2.0 * v + d) / (BUMP * BUMP));
        rows[3].push(quad([lv, OTHERS, OTHERS], bumped, c5) - v); }
    println!("chart,level,{}", grid.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(","));
    for (k, name) in ["value", "delta", "gamma", "vega"].iter().enumerate() {
        let xs: Vec<String> = rows[k].iter().map(|x| if k == 0 { format!("{:.2}", x) } else { format!("{:.3}", x) }).collect();
        println!("chart,{},{}", name, xs.join(","));
    }
    let draws = corr_draws(100000, 77, &l); let fresh = corr_draws(100000, 78, &l); let fresh2 = corr_draws(100000, 79, &l);
    for &lv in &[62, 74, 89, 107] {
        let i = grid.iter().position(|&g| g == lv).unwrap(); let lf = lv as f64;
        let lev = [[lf, OTHERS, OTHERS], [lf + BUMP, OTHERS, OTHERS], [lf - BUMP, OTHERS, OTHERS]];
        let (v, u, d) = (mc_last(&draws, lev[0], base, c5), mc_last(&draws, lev[1], base, c5), mc_last(&draws, lev[2], base, c5));
        let vg = mc_last(&draws, lev[0], bumped, c5);
        let de = mean_se(&u.iter().zip(&d).map(|(a, b)| (a - b) / (2.0 * BUMP)).collect::<Vec<f64>>());
        let ga = mean_se(&(0..v.len()).map(|j| (u[j] - 2.0 * v[j] + d[j]) / (BUMP * BUMP)).collect::<Vec<f64>>());
        let ve = mean_se(&vg.iter().zip(&v).map(|(a, b)| a - b).collect::<Vec<f64>>());
        println!("level {}: common draws delta {:.3} ({:.3}), gamma {:+.3} ({:.3}), vega {:+.3} ({:.3}); quadrature {:.3}, {:+.3}, {:+.3}",
            lv, de.0, de.1, ga.0, ga.1, ve.0, ve.1, rows[1][i], rows[2][i], rows[3][i]);
        for (est, rf) in [(de, rows[1][i]), (ga, rows[2][i]), (ve, rows[3][i])] {
            assert!((est.0 - rf).abs() < 4.0 * est.1 + 0.002, "common-draw Greek misses the quadrature"); }
        if lv == 74 {
            let fu = mean_se(&mc_last(&fresh, lev[1], base, c5)); let fd = mean_se(&mc_last(&fresh2, lev[2], base, c5));
            let fv = mean_se(&mc_last(&fresh, lev[0], bumped, c5)); let b = mean_se(&v);
            println!("mistake, fresh draws for the bumped legs at 74: gamma {:+.3} ({:.3}), vega {:+.3} ({:.3})",
                (fu.0 - 2.0 * b.0 + fd.0) / (BUMP * BUMP), (fu.1 * fu.1 + 4.0 * b.1 * b.1 + fd.1 * fd.1).sqrt() / (BUMP * BUMP), fv.0 - b.0, fv.1.hypot(b.1));
            let wide = (quad([84.0, OTHERS, OTHERS], base, c5) - 2.0 * rows[0][i] + quad([64.0, OTHERS, OTHERS], base, c5)) / 100.0;
            println!("mistake, a 10-point bump across the barrier at 74: gamma {:+.3}", wide);
        }
    }
    println!("mistake, price on one share (correlation 1): fair coupon {:.2}% against {:.2}%", 100.0 * c1, 100.0 * c5);
    println!("mistake, assume independent shares (correlation 0): fair coupon {:.2}%", 100.0 * res[0].1);
    let flips: Vec<i32> = (1..grid.len()).filter(|&i| (rows[2][i] > 0.0) != (rows[2][i - 1] > 0.0)).map(|i| grid[i]).collect();
    println!("gamma changes sign between {}", flips.iter().map(|f| format!("{} and {}", f - 3, f)).collect::<Vec<_>>().join(", "));
    let drift = (R - Q + 0.5 * SIG * SIG) * TLEFT; let kink = KNOCK * (-drift - KNOCK / (100.0 - KNOCK) * SIG * SIG * TLEFT).exp();
    println!("one share: gamma changes sign at {:.2} (pure step at 70), {:.2} (step plus sold call at 70), {:.2} (step at 100)", KNOCK * (-drift).exp(), kink, CALL * (-drift).exp());
    let at = |x: i32| grid.iter().position(|&g| g == x).unwrap(); let inside = |x: f64, i: usize| ((flips[i] - 3) as f64) < x && x <= flips[i] as f64;
    let ratio: Vec<f64> = [62, 74, 89, 107].iter().map(|&x| rows[3][at(x)] / (0.01 * SIG * TLEFT * x as f64 * x as f64 * rows[2][at(x)])).collect();
    println!("vega over 0.01 sigma T level^2 gamma at 62, 74, 89, 107: {}", ratio.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", "));
    assert!(ratio.iter().all(|&x| 0.8 < x && x < 1.1), "vega does not follow gamma");
    assert!(flips.len() == 3 && inside(kink, 0) && inside(CALL * (-drift).exp(), 2), "sign changes misplaced");
    println!("ALL CHECKS PASS");
}
