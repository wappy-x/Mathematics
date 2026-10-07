// Jensen's inequality -- the same check as the Python, in Rust.  No crates;
// std gives ln, exp and sqrt, nothing more.  The fund: each year a fair coin
// turns every $1 into $1.50 (up 50%) or $0.60 (down 40%).  Three roads: exact
// sums over the two outcomes, all 1,024 ten-year paths enumerated one by one,
// and a seeded simulation printed with its standard error.
const UP: f64 = 1.5;
const DOWN: f64 = 0.6;
const YEARS: u32 = 10;

fn e(f: &dyn Fn(f64) -> f64, law: &[(f64, f64)]) -> f64 {    // chance-weighted average of f
    law.iter().fold(0.0, |acc, &(x, p)| acc + p * f(x))
}

fn choose(n: u64, k: u64) -> u64 {                          // C(n, k) by the product rule
    let mut out = 1;
    for i in 0..k { out = out * (n - i) / (i + 1) }
    out
}

struct SplitMix64(u64);                                     // seed 20260928
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn show(label: &str, vals: &[f64], d: usize) {
    let parts: Vec<String> = vals.iter().map(|v| format!("{:.*}", d, v)).collect();
    println!("{}: {}", label, parts.join(", "));
}

fn list(label: &str, vals: &[f64], d: usize) { show(&format!("figure, {}", label), vals, d) }

fn main() {
    let fund = [(UP, 0.5), (DOWN, 0.5)];                    // (growth factor, chance)
    let index = [(0.80, 0.25), (1.08, 0.50), (1.30, 0.25)]; // second case: a calmer year
    let swing = [(-0.40, 0.5), (0.10, 0.5)];                // returns fed to a cube

    // ---- one year: square, then logarithm ----
    let m = e(&|x| x, &fund);
    let sq = e(&|x| x * x, &fund);
    let var = e(&|x| (x - m) * (x - m), &fund);             // road two: the definition
    let tan_sq = |x: f64| m * m + 2.0 * m * (x - m);        // supporting line of x^2 at m
    let (mlog, logm) = (e(&|x: f64| x.ln(), &fund), m.ln());
    let tan_log = |x: f64| logm + (x - m) / m;              // tangent of ln at m, above ln
    let typical = mlog.exp();
    show("mean growth E[X]", &[m], 6);
    show("mean of squares E[X^2], square of mean", &[sq, m * m], 6);
    show("gap, and Var(X) as average squared distance", &[sq - m * m, var], 6);
    show("x^2 minus its line at m, at 1.5 and 0.6", &[UP * UP - tan_sq(UP), DOWN * DOWN - tan_sq(DOWN)], 6);
    show("mean of logs E[ln X], log of mean ln E[X]", &[mlog, logm], 6);
    show("log gap", &[logm - mlog], 6);
    show("tangent of ln at m, at 1.5 and 0.6", &[tan_log(UP), tan_log(DOWN)], 6);
    show("ln itself at 1.5 and 0.6", &[UP.ln(), DOWN.ln()], 6);
    show("typical growth exp(E[ln X]), and sqrt(1.5 x 0.6)", &[typical, (UP * DOWN).sqrt()], 6);
    show("drag rule mu - var/2, and the true E[ln X]", &[(m - 1.0) - var / 2.0, mlog], 6);
    show("1.5^2, 0.6^2, 1.5 - m, var/2, 1.5 x 0.6", &[UP * UP, DOWN * DOWN, UP - m, var / 2.0, UP * DOWN], 6);

    // ---- ten years: every path, then the counting formula ----
    let (mut tot_w, mut tot_lw, mut below) = (0.0, 0.0, 0u64);
    for path in 0..(1u32 << YEARS) {
        let mut w = 1.0;
        for year in 0..YEARS { w *= if (path >> year) & 1 == 1 { UP } else { DOWN } }
        tot_w += w;
        tot_lw += f64::ln(w);
        if w < 1.0 { below += 1 }
    }
    let paths = (1u32 << YEARS) as f64;
    let y = YEARS as u64;
    let by_count: u64 = (0..=y)
        .filter(|&k| k as f64 * UP.ln() + (y - k) as f64 * DOWN.ln() < 0.0)
        .map(|k| choose(y, k)).sum();
    let mut mean_formula = 1.0;
    for _ in 0..YEARS { mean_formula *= m }
    println!("ten years, {} paths; ending below the start: {} by enumeration, {} by counting", 1u32 << YEARS, below, by_count);
    show("mean wealth per $1: enumerated, formula 1.05^10", &[tot_w / paths, mean_formula], 6);
    show("mean log wealth: enumerated, 10 x E[ln X]", &[tot_lw / paths, YEARS as f64 * mlog], 6);
    show("chance of ending below the start", &[below as f64 / paths], 6);
    show("$100 in: mean, median (5 up, 5 down), best path", &[100.0 * mean_formula, 100.0 * (UP * DOWN).powi(5), 100.0 * UP.powi(YEARS as i32)], 2);

    // ---- ten years: seeded simulation ----
    let n = 200000;
    let mut rng = SplitMix64(20260928);
    let (mut s1, mut s2, mut l1, mut l2, mut lo) = (0.0, 0.0, 0.0, 0.0, 0u64);
    for _ in 0..n {
        let mut w = 1.0;
        for _ in 0..YEARS { w *= if rng.uniform() < 0.5 { UP } else { DOWN } }
        s1 += w; s2 += w * w; l1 += f64::ln(w); l2 += f64::ln(w) * f64::ln(w);
        if w < 1.0 { lo += 1 }
    }
    let nf = n as f64;
    let (sm, sl, sp) = (s1 / nf, l1 / nf, lo as f64 / nf);
    let (se_m, se_l, se_p) = (((s2 / nf - sm * sm) / nf).sqrt(), ((l2 / nf - sl * sl) / nf).sqrt(), (sp * (1.0 - sp) / nf).sqrt());
    println!("simulation: {} paths of {} years, SplitMix64 seed 20260928", n, YEARS);
    show("  mean wealth, standard error", &[sm, se_m], 6);
    show("  mean wealth off the exact value, in standard errors", &[(sm - tot_w / paths) / se_m], 6);
    show("  mean log wealth, standard error", &[sl, se_l], 6);
    show("  chance below the start, standard error", &[sp, se_p], 6);

    // ---- second case: a calmer year ----
    let m2 = e(&|x| x, &index);
    let v2 = e(&|x| (x - m2) * (x - m2), &index);
    let ml2 = e(&|x: f64| x.ln(), &index);
    show("calmer year: E[X], E[X^2] - E[X]^2, Var(X)", &[m2, e(&|x| x * x, &index) - m2 * m2, v2], 6);
    show("calmer year: E[ln X], ln E[X], gap, var/(2 m^2)", &[ml2, m2.ln(), m2.ln() - ml2, v2 / (2.0 * m2 * m2)], 6);

    // ---- what breaks: a cube on returns that are mostly negative ----
    let er = e(&|r| r, &swing);
    let er3 = e(&|r| r * r * r, &swing);
    show("cube, returns -40% or +10%: E[R^3], (E[R])^3", &[er3, er * er * er], 6);

    // ---- the charts ----
    let xs: Vec<f64> = (0..19).map(|i| 0.6 + 0.05 * i as f64).collect();
    let slope = (UP.ln() - DOWN.ln()) / (UP - DOWN);
    list("x", &xs, 2);
    list("ln x", &xs.iter().map(|x| x.ln()).collect::<Vec<f64>>(), 2);
    list("chord", &xs.iter().map(|x| DOWN.ln() + slope * (x - DOWN)).collect::<Vec<f64>>(), 2);
    list("tangent", &xs.iter().map(|&x| tan_log(x)).collect::<Vec<f64>>(), 2);
    let (mut wm, mut wt, mut a, mut b) = (100.0, 100.0, vec![], vec![]);
    for _ in 0..=YEARS { a.push(wm); b.push(wt); wm *= m; wt *= typical }
    list("mean $", &a, 2);
    list("typical $", &b, 2);

    assert!(((sq - m * m) - var).abs() < 1e-12);                     // shortcut against definition
    assert!(((m - 1.0) - var / 2.0 - mlog).abs() < 0.002);         // drag rule is close
    assert!(fund.iter().chain(index.iter()).all(|&(x, _)| x * x >= tan_sq(x) && x.ln() <= tan_log(x)));
    assert!(sq > m * m && mlog < logm && ml2 < m2.ln());             // Jensen, both directions
    assert!((tot_w / paths - mean_formula).abs() < 1e-12 && below == by_count);
    assert!((sm - tot_w / paths).abs() < 4.0 * se_m && (sl - tot_lw / paths).abs() < 4.0 * se_l);
    assert!((sp - below as f64 / paths).abs() < 4.0 * se_p);         // simulation agrees
    assert!(er3 < er * er * er);                                     // no convexity, no Jensen
    println!("ALL CHECKS PASS");
}
