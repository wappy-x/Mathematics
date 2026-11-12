// Cholesky -- the check behind the card.  std only; nothing used holds an answer.  Three shares,
// volatilities 20%, 30%, 25%, correlations 0.6, 0.28, 0.5: a covariance matrix in percent squared.
// Factor it as L L^T, count flops against LU, solve with it, walk to the edge, and mix random draws.
type M = Vec<Vec<f64>>;
const SPOTS: [f64; 3] = [80.0, 100.0, 120.0];
const N: usize = 20000; const SEED: u64 = 20261111; const BIG: u64 = 500;
const DIAL: [f64; 7] = [375.0, 675.0, 697.5, 701.25, 702.0, 705.0, 712.5]; // a23 = 750 x rho23
const TWO53: f64 = 9007199254740992.0;
fn cov(a23: f64) -> M { vec![vec![400.0, 360.0, 140.0], vec![360.0, 900.0, a23], vec![140.0, a23, 625.0]] }
fn chol(a: &M) -> (Option<M>, f64, u64) { // column by column; None at a pivot <= 0
    let (n, mut f, mut s) = (a.len(), 0u64, 0.0);
    let mut l = vec![vec![0.0; n]; n];
    for j in 0..n {
        s = a[j][j];
        for k in 0..j { s -= l[j][k] * l[j][k]; f += 2; }
        if s <= 0.0 { return (None, s, f); }
        l[j][j] = s.sqrt(); f += 1;
        for i in j + 1..n {
            let mut t = a[i][j];
            for k in 0..j { t -= l[i][k] * l[j][k]; f += 2; }
            l[i][j] = t / l[j][j]; f += 1;
        }
    }
    (Some(l), s, f)
}
fn lu_flops(a: &M) -> u64 { // elimination, counted as on the LU card
    let (mut m, n, mut f) = (a.clone(), a.len(), 0u64);
    for k in 0..n {
        for i in k + 1..n {
            let r = m[i][k] / m[k][k]; f += 1;
            for j in k + 1..n { m[i][j] -= r * m[k][j]; f += 2; }
        }
    }
    f
}
fn chol_solve(l: &M, b: &[f64]) -> (Vec<f64>, Vec<f64>) { // forward L y = b, then back L^T x = y
    let (n, mut y, mut x) = (b.len(), vec![0.0; b.len()], vec![0.0; b.len()]);
    for i in 0..n { let mut s = b[i]; for k in 0..i { s -= l[i][k] * y[k]; } y[i] = s / l[i][i]; }
    for i in (0..n).rev() { let mut s = y[i]; for k in i + 1..n { s -= l[k][i] * x[k]; } x[i] = s / l[i][i]; }
    (x, y)
}
fn det3(m: &M) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn cramer(m: &M, b: &[f64]) -> Vec<f64> { // exact on these entries until the final division
    (0..3).map(|c| {
        let mc: M = (0..3).map(|i| (0..3).map(|j| if j == c { b[i] } else { m[i][j] }).collect()).collect();
        det3(&mc) / det3(m)
    }).collect()
}
fn kappa1(m: &M) -> f64 { // ||A||_1 times ||A^-1||_1, the inverse by Cramer's rule
    let cols: Vec<Vec<f64>> = (0..3).map(|c| cramer(m, &(0..3).map(|i| if i == c { 1.0 } else { 0.0 }).collect::<Vec<_>>())).collect();
    let na = (0..3).map(|c| (0..3).fold(0.0, |s, i| s + m[i][c].abs())).fold(f64::MIN, f64::max);
    let ni = cols.iter().map(|col| col.iter().fold(0.0, |s, v| s + v.abs())).fold(f64::MIN, f64::max);
    na * ni
}
fn backward(a: &M, l: &M) -> f64 { // worst |A - L L^T| entry over sqrt(a_ii a_jj)
    let (n, mut w) = (a.len(), 0.0f64);
    for i in 0..n { for j in 0..n {
        let mut s = 0.0;
        for k in 0..n { s += l[i][k] * l[j][k]; }
        w = w.max((s - a[i][j]).abs() / (a[i][i] * a[j][j]).sqrt());
    } }
    w
}
fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) >> 11
}
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn row(label: &str, vals: &[f64]) { println!("{:<44}{}", label, vals.iter().map(|v| format!("{:>12.6}", v)).collect::<String>()); }
fn srow(label: &str, vals: &[f64]) { println!("{:<44}{}", label, vals.iter().map(|v| format!("{:>12}", sci(*v))).collect::<String>()); }
fn comma(k: u64) -> String {
    let (s, mut out) = (k.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn fc(n: u64) -> u64 { (2 * n * n * n + 3 * n * n + n) / 6 } // Cholesky flops, square roots included
fn fl(n: u64) -> u64 { (4 * n * n * n - 3 * n * n - n) / 6 } // LU flops
fn main() {
    let a = cov(375.0);
    let (lo, _, f3) = chol(&a); let l = lo.unwrap();
    let h32: f64 = 249.0 / 24.0;
    let hand = vec![vec![20.0, 0.0, 0.0], vec![18.0, 24.0, 0.0], vec![7.0, h32, (625.0 - 49.0 - h32 * h32).sqrt()]];
    let (mut hand_gap, mut growth): (f64, f64) = (0.0, 0.0);
    for i in 0..3 { for j in 0..3 { hand_gap = hand_gap.max((l[i][j] - hand[i][j]).abs()); growth = growth.max(l[i][j].abs() / a[i][i].sqrt()); } }
    for i in 0..3 { row(&format!("L row {}, then pivot {}", i + 1, i + 1), &[l[i][0], l[i][1], l[i][2], l[i][i] * l[i][i]]); }
    row("gap to hand factor; max |l_ij|/sqrt(a_ii)", &[hand_gap, growth]);
    let d: M = cov(702.0).iter().map(|r| r.iter().map(|v| v / 10000.0).collect()).collect(); // the edge matrix, written in decimals
    let (ldo, pd, _) = chol(&d); let ld = ldo.clone().unwrap();
    let u = 1.0 / TWO53; let gamma = 4.0 * u / (1.0 - 4.0 * u);
    srow("backward error: A, decimal edge; gamma_4", &[backward(&a, &l), backward(&d, &ld), gamma, backward(&d, &ld) / gamma]);
    let (w1, (wc, yc)) = (cramer(&a, &[1.0; 3]), chol_solve(&l, &[1.0; 3]));
    let gc = (0..3).map(|i| (wc[i] - w1[i]).abs() / w1[i].abs()).fold(0.0, f64::max);
    let sw = wc.iter().fold(0.0, |s, v| s + v);
    let mv: Vec<f64> = wc.iter().map(|v| v / sw).collect();
    let mut var = 0.0; for i in 0..3 { for j in 0..3 { var += mv[i] * a[i][j] * mv[j]; } }
    srow("forward step y, from L y = ones", &yc);
    srow("back step x = A^-1 ones, from L^T x = y", &wc);
    srow("worst relative gap to Cramer's rule", &[gc]);
    row("minimum-variance weights", &mv);
    row("w^T A w, 1/(1^T A^-1 1), volatility", &[var, 1.0 / sw, var.sqrt()]);
    let b: M = (0..40).map(|i| (0..40).map(|j| (i.min(j) + 1) as f64).collect()).collect(); // a random walk's covariance: L is all ones
    let (lbo, _, f40) = chol(&b); let lb = lbo.unwrap();
    let mut ones_gap: f64 = 0.0;
    for i in 0..40 { for j in 0..40 { ones_gap = ones_gap.max((lb[i][j] - if j <= i { 1.0 } else { 0.0 }).abs()); } }
    for (n, c, lf) in [(3u64, f3, lu_flops(&a)), (40, f40, lu_flops(&b))] {
        println!("n = {:<3} flops counted: Cholesky {:>7}  LU {:>7}   formulas {:>7} {:>7}", n, comma(c), comma(lf), comma(fc(n)), comma(fl(n)));
    }
    println!("n = {} Cholesky {}  LU {}  ratio {:.6}  two solves {}", BIG, comma(fc(BIG)), comma(fl(BIG)), fc(BIG) as f64 / fl(BIG) as f64, comma(2 * BIG * BIG));
    let mut dial = Vec::new();
    for a23 in DIAL {
        let (lm, p, _) = chol(&cov(a23));
        let dd = det3(&cov(a23)) / 230400.0;
        dial.push((p, dd, lm.is_some()));
        let k = if dd > 0.0 { sci(kappa1(&cov(a23))) } else { "none".to_string() };
        println!("rho23 {:.6}  third pivot {:>11.6}  det/det2 {:>11.6}  kappa1 {:>9}  {}", a23 / 750.0, p, dd, k, if lm.is_some() { "passes" } else { "fails" });
    }
    for t in 0..10 {
        let (lt, _, _) = chol(&cov(750.0 * 0.104 * t as f64));
        println!("figure, rho23 {:.3}, L33 {:.2}", 0.104 * t as f64, match lt { Some(m) => m[2][2], None => 0.0 });
    }
    println!("edge in percent^2: third pivot {:.6}, {}; det2 = {:.0}", dial[4].0, if dial[4].0 <= 0.0 { "fails" } else { "passes" }, 400.0f64 * 900.0 - 360.0 * 360.0);
    println!("edge in decimals: third pivot {}, L33 {}, {}", sci(pd), sci(ld[2][2]), if ldo.is_some() { "passes" } else { "fails" });
    let (mut state, mut sxx) = (SEED, [[0.0f64; 3]; 3]);
    let mut first: Option<([f64; 3], [f64; 3])> = None;
    for _ in 0..N {
        let mut z = [0.0f64; 3];
        for i in 0..3 {
            let mut t = 0.0;
            for _ in 0..12 { t += splitmix(&mut state) as f64 / TWO53; }
            z[i] = t - 6.0; // 12 uniforms minus 6: mean 0, variance 1
        }
        let mut v = [0.0f64; 3]; // correlated shocks, percent
        for i in 0..3 { for k in 0..3 { v[i] += l[i][k] * z[k]; } }
        if first.is_none() { first = Some((z, v)); }
        for i in 0..3 { for j in 0..3 { sxx[i][j] += v[i] * v[j]; } }
    }
    let s: Vec<Vec<f64>> = sxx.iter().map(|r| r.iter().map(|v| v / N as f64).collect()).collect();
    let (z0, v0) = first.unwrap();
    row("first draw z", &z0);
    row("first draw v = L z, percent", &v0);
    row("prices a year on, from $80, $100, $120", &(0..3).map(|i| SPOTS[i] * (v0[i] / 100.0 - a[i][i] / 20000.0).exp()).collect::<Vec<_>>()); // lognormal, no drift
    for i in 0..3 { row(&format!("sample covariance row {}, {} draws", i + 1, N), &s[i]); }
    let mut se: f64 = 0.0;
    for i in 0..3 { for j in 0..3 {
        se = se.max((s[i][j] - a[i][j]).abs() / ((a[i][i] * a[j][j] + a[i][j] * a[i][j]) / N as f64).sqrt());
    } }
    row("worst gap to A, in standard errors", &[se]);
    let mut tl = [[0.0f64; 3]; 3];
    for i in 0..3 { for j in 0..3 { for k in 0..3 { tl[i][j] += l[k][i] * l[k][j]; } } }
    row("wrong: L^T as the mixer, volatilities", &[tl[0][0].sqrt(), tl[1][1].sqrt(), tl[2][2].sqrt()]);
    row("wrong: L^T as the mixer, correlation 1-2", &[tl[0][1] / (tl[0][0] * tl[1][1]).sqrt()]);
    assert!(hand_gap < 1e-12 && growth <= 1.0); // the factor by hand; no entry above its diagonal's root
    assert!(backward(&d, &ld) <= gamma); // the rounding bound holds
    assert!(gc < 1e-13 && (var - 1.0 / sw).abs() < 1e-9);
    assert!(ones_gap == 0.0 && (f3, f40, lu_flops(&b)) == (fc(3), fc(40), fl(40)));
    assert!(dial.iter().all(|(p, dd, _)| (p - dd).abs() < 1e-9)); // last pivot = det / leading 2 by 2 det
    assert!(dial.iter().map(|d| d.2).collect::<Vec<_>>() == [true, true, true, true, false, false, false] && pd > 0.0); // the verdicts
    assert!(se < 4.0);
    println!("ALL CHECKS PASS");
}
