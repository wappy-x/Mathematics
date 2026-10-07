// Confounding and Simpson's paradox -- the same check as the Python, in Rust.
// No crates.  Data: Berkeley graduate admissions, autumn 1973, the six
// largest departments (Bickel, Hammel and O'Connell, Science, 1975).
// Roads: counting against mix-weighted averages; the standardised gap by
// formula against reweighting all 4,526 applicant records; the bias formula
// against a seeded simulation of a world where sex has no effect at all.
type C = [f64; 4]; // admitted men, applied men, admitted women, applied women

const DEPTS: [(&str, C); 6] = [("A", [512.0, 825.0, 89.0, 108.0]), ("B", [353.0, 560.0, 17.0, 25.0]),
    ("C", [120.0, 325.0, 202.0, 593.0]), ("D", [138.0, 417.0, 131.0, 375.0]),
    ("E", [53.0, 191.0, 94.0, 393.0]), ("F", [22.0, 373.0, 24.0, 341.0])];

fn se(p: f64, n: f64, q: f64, m: f64) -> f64 { (p * (1.0 - p) / n + q * (1.0 - q) / m).sqrt() }

fn table(groups: &[(&str, &str)]) -> Vec<(String, C)> {
    groups.iter().map(|(k, v)| {
        let mut c = [0.0; 4];
        for i in 0..4 { for d in DEPTS.iter().filter(|d| v.contains(d.0)) { c[i] += d.1[i] } }
        (k.to_string(), c)
    }).collect()
}

fn standardised(strata: &[(String, C)], n: f64) -> (f64, f64, f64) {
    let mut s = [0.0; 2];
    for g in 0..2 { for (_, c) in strata { s[g] += (c[1] + c[3]) / n * c[2 * g] / c[2 * g + 1] } }
    let mut v = 0.0;
    for (_, c) in strata { v += ((c[1] + c[3]) / n).powi(2) * se(c[2] / c[3], c[3], c[0] / c[1], c[1]).powi(2) }
    (s[0], s[1], v.sqrt())
}

fn reweighted(strata: &[(String, C)]) -> [f64; 2] {
    let mut recs: Vec<(usize, usize, f64)> = Vec::new(); // (sex 0 men / 1 women, stratum, admitted)
    for (k, (_, c)) in strata.iter().enumerate() {
        for g in 0..2 {
            for i in 0..c[2 * g + 1] as usize { recs.push((g, k, if i < c[2 * g] as usize { 1.0 } else { 0.0 })) }
        }
    }
    let total = recs.len() as f64;
    let cnt = |f: &dyn Fn(&(usize, usize, f64)) -> bool| recs.iter().filter(|r| f(r)).count() as f64;
    let mut out = [0.0; 2];
    for g in 0..2 { // weight = P(stratum) / P(stratum | sex)
        let n_sex = cnt(&|r| r.0 == g);
        let (mut num, mut den) = (0.0, 0.0);
        for r in recs.iter().filter(|r| r.0 == g) {
            let w = (cnt(&|q| q.1 == r.1) / total) / (cnt(&|q| q.0 == g && q.1 == r.1) / n_sex);
            num += w * r.2;
            den += w;
        }
        out[g] = num / den;
    }
    out
}

struct Rng(u64); // SplitMix64, seed stated
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn world(rng: &mut Rng, sel: [f64; 2], rate: [f64; 2], n: usize) -> [[[f64; 2]; 2]; 2] {
    let mut c = [[[0.0; 2]; 2]; 2]; // [sex][kind] = [admitted, applied]
    for g in 0..2 {
        for _ in 0..n {
            let k = if rng.uniform() < sel[g] { 1 } else { 0 };
            c[g][k][1] += 1.0;
            if rng.uniform() < rate[k] { c[g][k][0] += 1.0 }
        }
    }
    c
}

fn gap(c: &[[[f64; 2]; 2]; 2], kinds: &[usize]) -> (f64, f64) {
    let a: Vec<f64> = (0..2).map(|g| kinds.iter().map(|&k| c[g][k][0]).sum()).collect();
    let n: Vec<f64> = (0..2).map(|g| kinds.iter().map(|&k| c[g][k][1]).sum()).collect();
    (a[1] / n[1] - a[0] / n[0], se(a[1] / n[1], n[1], a[0] / n[0], n[0]))
}

fn main() {
    let six = table(&[("A", "A"), ("B", "B"), ("C", "C"), ("D", "D"), ("E", "E"), ("F", "F")]);
    let two = table(&[("open", "AB"), ("selective", "CDEF")]);
    let pool = table(&[("all six", "ABCDEF")])[0].1;
    let n = pool[1] + pool[3];
    println!("stratum     men admitted/applied  women admitted/applied  gap w-m, points (SE)  share of pool");
    for (k, c) in six.iter().chain(two.iter()).chain([("all six".to_string(), pool)].iter()) {
        let (rm, rw) = (c[0] / c[1], c[2] / c[3]);
        println!("{:<10} {:>5}/{:<5} {:.4}   {:>5}/{:<5} {:.4}   {:+6.1} ({:.1})         {:.4}", k, c[0], c[1], rm,
                 c[2], c[3], rw, 100.0 * (rw - rm), 100.0 * se(rw, c[3], rm, c[1]), (c[1] + c[3]) / n);
    }
    // Road 1 against road 2: the pooled rate, counted, and as a mix-weighted average
    let (p_m, p_w) = (pool[0] / pool[1], pool[2] / pool[3]);
    let mix_m: Vec<f64> = two.iter().map(|(_, c)| c[1] / pool[1]).collect();
    let mix_w: Vec<f64> = two.iter().map(|(_, c)| c[3] / pool[3]).collect();
    let (mut avg_m, mut avg_w, mut inside, mut mixpart) = (0.0, 0.0, 0.0, 0.0);
    for (i, (_, c)) in two.iter().enumerate() {
        avg_m += mix_m[i] * c[0] / c[1];
        avg_w += mix_w[i] * c[2] / c[3];
    }
    println!("pooled rate by counting: men {:.4}, women {:.4}; by mix-weighted average: men {:.4}, women {:.4}", p_m, p_w, avg_m, avg_w);
    let mut bars: Vec<f64> = two.iter().flat_map(|(_, c)| [100.0 * c[0] / c[1], 100.0 * c[2] / c[3]]).collect();
    bars.extend([100.0 * p_m, 100.0 * p_w]);
    println!("bars, percent admitted: {}", bars.iter().map(|b| format!("{:.1}", b)).collect::<Vec<_>>().join(", "));
    println!("applicants {}; share applying to open departments: men {:.4}, women {:.4}; to selective: men {:.4}, women {:.4}",
             n, mix_m[0], mix_w[0], mix_m[1], mix_w[1]);
    // The pooled gap split into a part inside departments and a part from the mix
    for (i, (_, c)) in two.iter().enumerate() { inside += mix_w[i] * (c[2] / c[3] - c[0] / c[1]) }
    for (i, (_, c)) in two.iter().enumerate() { mixpart += (mix_w[i] - mix_m[i]) * c[0] / c[1] }
    println!("pooled gap, points: {:+.2} = inside departments {:+.2} + mix {:+.2}", 100.0 * (p_w - p_m), 100.0 * inside, 100.0 * mixpart);
    for (name, strata) in [("two kinds", &two), ("six departments", &six)] {
        let (sm, sw, sd) = standardised(strata, n);
        let r = reweighted(strata);
        println!("standardised, {}: men {:.4}, women {:.4}, gap {:+.1} points (SE {:.1}); reweighted records: men {:.4}, women {:.4}",
                 name, sm, sw, 100.0 * (sw - sm), 100.0 * sd, r[0], r[1]);
        assert!((sm - r[0]).abs() < 1e-12 && (sw - r[1]).abs() < 1e-12); // formula against records
    }
    let (s2m, s2w, _) = standardised(&two, n);
    let (s6m, s6w, _) = standardised(&six, n);
    // A world where sex has no effect: admission depends on the department kind only
    let (o, s) = (two[0].1, two[1].1);
    let (r_open, r_sel) = ((o[0] + o[2]) / (o[1] + o[3]), (s[0] + s[2]) / (s[1] + s[3]));
    let w_pool = (s[1] + s[3]) / n;
    let bias = (mix_w[1] - mix_m[1]) * (r_sel - r_open);
    println!("department rates, both sexes: open {:.4}, selective {:.4}; pool's selective share {:.4}", r_open, r_sel, w_pool);
    println!("bias formula, no-sex-effect world: ({:.4} - {:.4}) x ({:.4} - {:.4}) = {:+.2} points",
             mix_w[1], mix_m[1], r_sel, r_open, 100.0 * bias);
    let mut rng = Rng(20260929);
    let nsim = 100000;
    println!("simulation: SplitMix64, seed {}, {} applicants of each sex per world", rng.0, nsim);
    let chosen = world(&mut rng, [mix_m[1], mix_w[1]], [r_open, r_sel], nsim);
    let coin = world(&mut rng, [w_pool, w_pool], [r_open, r_sel], nsim);
    for (label, c, target) in [("sexes choose as at Berkeley", &chosen, bias), ("department by lottery", &coin, 0.0)] {
        let ((g_all, s_all), (g_o, s_o), (g_s, s_s)) = (gap(c, &[0, 1]), gap(c, &[0]), gap(c, &[1]));
        println!("  {}: pooled gap {:+.2} (SE {:.2}); inside open {:+.2} (SE {:.2}); inside selective {:+.2} (SE {:.2})",
                 label, 100.0 * g_all, 100.0 * s_all, 100.0 * g_o, 100.0 * s_o, 100.0 * g_s, 100.0 * s_s);
        assert!(g_o.abs() < 4.0 * s_o && g_s.abs() < 4.0 * s_s); // no sex effect inside
        assert!((g_all - target).abs() < 4.0 * s_all);
    }
    // A second world with the same pooled table and the opposite story inside
    let alt: [(&str, C); 2] = [("open", [865.0, 1385.0, 400.0, 800.0]), ("selective", [333.0, 1306.0, 157.0, 1035.0])];
    let mut alt_pool = [0.0; 4];
    for (_, c) in &alt { for i in 0..4 { alt_pool[i] += c[i] } }
    println!("second world: women open 400/800 {:.4}, selective 157/1035 {:.4}; pooled women {}/{}, men {}/{}",
             400.0 / 800.0, 157.0 / 1035.0, alt_pool[2], alt_pool[3], alt_pool[0], alt_pool[1]);
    println!("  gaps inside, points: {}", alt.iter().map(|(k, c)| format!("{} {:+.1}", k, 100.0 * (c[2] / c[3] - c[0] / c[1])))
             .collect::<Vec<_>>().join(", "));
    assert!(alt_pool == pool && alt.iter().all(|(_, c)| c[2] / c[3] < c[0] / c[1]));
    assert!(two.iter().all(|(_, c)| c[2] / c[3] > c[0] / c[1]) && p_w < p_m); // the reversal
    let unweighted = six.iter().map(|(_, c)| c[2] / c[3] - c[0] / c[1]).sum::<f64>() / 6.0;
    println!("what breaks, points: pooled gap read as bias {:+.1} (SE {:.1}); two kinds {:+.1}; unweighted mean of six gaps {:+.1}; six departments {:+.1}",
             100.0 * (p_w - p_m), 100.0 * se(p_w, pool[3], p_m, pool[1]), 100.0 * (s2w - s2m), 100.0 * unweighted, 100.0 * (s6w - s6m));
    assert!((inside + mixpart - (p_w - p_m)).abs() < 1e-12 && (avg_m - p_m).abs() < 1e-12 && (avg_w - p_w).abs() < 1e-12);
    let x = |s: f64| 50.0 + 280.0 * s; // figure: x = share applying to selective
    let y = |r: f64| 190.0 - 170.0 * r; // y = admission rate, 0 at 190, 1 at 20
    let rate = |g: usize, k: usize| two[k].1[2 * g] / two[k].1[2 * g + 1];
    println!("figure, men line ({:.1},{:.1})-({:.1},{:.1}); women line ({:.1},{:.1})-({:.1},{:.1}); men pooled ({:.1},{:.1}); women pooled ({:.1},{:.1})",
             x(0.0), y(rate(0, 0)), x(1.0), y(rate(0, 1)), x(0.0), y(rate(1, 0)), x(1.0), y(rate(1, 1)),
             x(mix_m[1]), y(p_m), x(mix_w[1]), y(p_w));
    println!("ALL CHECKS PASS");
}
