// Chi-square tests -- the same check as the Python, in Rust.  No crates.  Two
// questions.  Dice: 60 rolls came out 5, 7, 8, 10, 12, 18; is the die fair?
// Trial: 45 of 100 recovered on the drug, 35 of 100 on placebo; is recovery
// independent of treatment?  Every tail is built here: a gamma series, Simpson's
// rule on the density, an exact sum over every tally, and a seeded simulation
// (SplitMix64, seed 20260928).
use std::f64::consts::PI;

fn phi(z: f64) -> f64 {                               // bell area left of z, Taylor series
    let (mut term, mut total, mut j) = (z, z, 0.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        j += 1.0;
        term *= -z * z * (2.0 * j - 1.0) / (2.0 * j * (2.0 * j + 1.0));
        total += term;
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn gamma_half(a: f64) -> f64 {                        // Gamma(a) for a = 1/2, 1, 3/2, ...
    let (mut g, mut x) = if (2.0 * a) as i64 % 2 == 1 { (PI.sqrt(), 0.5) } else { (1.0, 1.0) };
    while x < a { g *= x; x += 1.0 }
    g
}

fn tail_series(q: f64, df: f64) -> f64 {              // road one: 1 - lower gamma series
    let (a, x) = (df / 2.0, q / 2.0);
    let (mut term, mut total, mut j) = (1.0 / (a * gamma_half(a)), 0.0f64, 0.0);
    while term > 1e-18 * total.max(1e-300) {
        total += term;
        j += 1.0;
        term *= x / (a + j);
    }
    1.0 - (-x + a * x.ln()).exp() * total
}

fn density(t: f64, df: f64) -> f64 {                  // the chi-square density
    ((df / 2.0 - 1.0) * t.ln() - t / 2.0).exp() / (2f64.powf(df / 2.0) * gamma_half(df / 2.0))
}

fn tail_simpson(q: f64, df: f64) -> f64 {             // road two: area from q to q + 200
    let m = 20000;
    let h = 200.0 / m as f64;
    let mut s = density(q, df) + density(q + 200.0, df);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * density(q + i as f64 * h, df) }
    s * h / 3.0
}

fn cut(df: f64) -> f64 {                              // bisection: the tail equals 0.05
    let (mut a, mut b) = (0.0, 100.0);
    for _ in 0..200 {
        let m = 0.5 * (a + b);
        if tail_series(m, df) > 0.05 { a = m } else { b = m }
    }
    0.5 * (a + b)
}

fn tallies(n: usize, k: usize, top: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if k == 1 {                                       // every tally c1 >= c2 >= ... >= ck
        if n <= top { cur.push(n); out.push(cur.clone()); cur.pop(); }
        return;
    }
    for c in (0..=n.min(top)).rev() {
        cur.push(c);
        tallies(n - c, k - 1, c, cur, out);
        cur.pop();
    }
}

fn exact_law(n: usize, k: usize, lf: &[f64]) -> Vec<(f64, f64)> {   // road three
    let mut all = Vec::new();
    tallies(n, k, n, &mut Vec::new(), &mut all);
    let e = n as f64 / k as f64;
    all.iter().map(|t| {
        let mut orders = lf[k];
        let mut seen: Vec<usize> = Vec::new();
        for &v in t { if !seen.contains(&v) { seen.push(v); orders -= lf[t.iter().filter(|&&c| c == v).count()] } }
        let chance = (lf[n] - t.iter().map(|&c| lf[c]).sum::<f64>() - n as f64 * (k as f64).ln() + orders).exp();
        (t.iter().map(|&c| (c as f64 - e).powi(2)).sum::<f64>() / e, chance)
    }).collect()
}

fn pearson(obs: &[f64], ex: &[f64]) -> f64 { obs.iter().zip(ex).map(|(o, e)| (o - e).powi(2) / e).sum() }

fn next64(state: &mut u64) -> u64 {                   // SplitMix64, the same stream as the Python
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut x = *state;
    x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
    x ^ (x >> 31)
}

fn tail_at(law: &[(f64, f64)], x: f64) -> f64 { law.iter().filter(|p| p.0 >= x - 1e-9).map(|p| p.1).sum() }

fn main() {
    let mut lf = vec![0.0f64];
    for i in 1..=200 { let v = lf[i - 1] + (i as f64).ln(); lf.push(v) }
    let dice = [5.0, 7.0, 8.0, 10.0, 12.0, 18.0];
    let q_dice = pearson(&dice, &[10.0; 6]);
    let (c5, c1, small) = (cut(5.0), cut(1.0), 12);        // small: rolls in the small session
    let law60 = exact_law(60, 6, &lf);
    let exact_p = tail_at(&law60, q_dice);
    let mean_q: f64 = law60.iter().map(|p| p.0 * p.1).sum();
    let var_q = law60.iter().map(|p| p.0 * p.0 * p.1).sum::<f64>() - mean_q * mean_q;
    let size60: f64 = law60.iter().filter(|p| p.0 > c5).map(|p| p.1).sum();
    let size12: f64 = exact_law(small, 6, &lf).iter().filter(|p| p.0 > c5).map(|p| p.1).sum();
    let join = |v: Vec<String>| v.join(", ");
    println!("dice: counts {}; expected 10 each", join(dice.iter().map(|o| format!("{}", o)).collect()));
    println!("  gaps squared over 10: {}", join(dice.iter().map(|o| format!("{:.1}", (o - 10.0).powi(2) / 10.0)).collect()));
    println!("  Q = {:.4}, degrees of freedom 5", q_dice);
    println!("  tail, gamma series        {:.6}", tail_series(q_dice, 5.0));
    println!("  tail, Simpson on density  {:.6}", tail_simpson(q_dice, 5.0));
    println!("  tail, exact sum over {} tallies {:.6}", law60.len(), exact_p);
    println!("  exact mean of Q {:.6} (k - 1 = 5); variance {:.6} (2 x 5 x 59/60 = {:.6})", mean_q, var_q, 2.0 * 5.0 * 59.0 / 60.0);
    println!("  5% cut, 5 degrees of freedom {:.4}; 1 degree {:.4}", c5, c1);
    println!("  exact chance fair die rejected at the 5% cut: 60 rolls {:.4}, {} rolls {:.4}", size60, small, size12);
    let (runs, mut hit_p, mut hit_c, mut state) = (20000, 0, 0, 20260928u64);
    for _ in 0..runs {                                // one run = 60 rolls of a fair die
        let mut cnt = [0.0f64; 6];
        for _ in 0..60 { cnt[((next64(&mut state) >> 11) as f64 / 9007199254740992.0 * 6.0) as usize] += 1.0 }
        let q = pearson(&cnt, &[10.0; 6]);
        if q >= q_dice - 1e-9 { hit_p += 1 }
        if q > c5 { hit_c += 1 }
    }
    for (label, h, ex) in [(format!("Q >= {:.1}", q_dice), hit_p, exact_p), ("Q > 5% cut".to_string(), hit_c, size60)] {
        let s = h as f64 / runs as f64;
        let se = (s * (1.0 - s) / runs as f64).sqrt();
        println!("  simulated {:<11}{:.4}  se {:.4}  (sim - exact)/se {:>5.2}", label, s, se, (s - ex) / se);
        assert!((s - ex).abs() < 4.0 * se);                              // simulation agrees
    }
    let xs: Vec<f64> = (0..=10).map(|i| 2.0 * i as f64).collect();
    println!("chart, Q at least  {}", xs.iter().map(|x| format!("{:>6}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, exact %     {}", xs.iter().map(|&x| format!("{:6.2}", 100.0 * tail_at(&law60, x))).collect::<Vec<_>>().join(" "));
    println!("chart, chi-sq 5 %  {}", xs.iter().map(|&x| format!("{:6.2}", if x > 0.0 { 100.0 * tail_series(x, 5.0) } else { 100.0 })).collect::<Vec<_>>().join(" "));
    let (a, b, c, d) = (45.0f64, 55.0f64, 35.0f64, 65.0f64);  // rows: drug, placebo
    let (r, cc, n) = ([a + b, c + d], [a + c, b + d], 200.0);
    let e = [r[0] * cc[0] / n, r[0] * cc[1] / n, r[1] * cc[0] / n, r[1] * cc[1] / n];
    let q_cells = pearson(&[a, b, c, d], &e);
    let q_short = n * (a * d - b * c).powi(2) / (r[0] * r[1] * cc[0] * cc[1]);
    let pool = cc[0] / n;
    let z = (a / 100.0 - c / 100.0) / (pool * (1.0 - pool) * (1.0 / 100.0 + 1.0 / 100.0)).sqrt();
    let bp: Vec<f64> = (0..=100).map(|j| (lf[100] - lf[j] - lf[100 - j] + j as f64 * pool.ln() + (100 - j) as f64 * (1.0 - pool).ln()).exp()).collect();
    let q22 = |x: f64, y: f64| { let s = x + y; if s == 0.0 || s == 200.0 { 0.0 } else { 200.0 * (x - y).powi(2) / (s * (200.0 - s)) } };
    let mut exact_22 = 0.0;
    for x in 0..=100 { for y in 0..=100 { if q22(x as f64, y as f64) >= q_cells - 1e-9 { exact_22 += bp[x] * bp[y] } } }
    println!("trial: expected drug {:.1} {:.1}, placebo {:.1} {:.1}; pooled rate {:.2}", e[0], e[1], e[2], e[3], pool);
    println!("  Q by cells {:.6}; by n(ad - bc)^2 / margins {:.6}; z^2 {:.6} (z = {:.6})", q_cells, q_short, z * z, z);
    println!("  tail, gamma series 1 d.f. {:.6}; Simpson {:.6}; 2(1 - Phi(z)) {:.6}", tail_series(q_cells, 1.0), tail_simpson(q_cells, 1.0), 2.0 * (1.0 - phi(z)));
    println!("  exact tail, both arms binomial at 0.40: {:.6}", exact_22);
    println!("what breaks:");
    println!("  dice, 6 degrees of freedom: p {:.6}, cut {:.4}", tail_series(q_dice, 6.0), cut(6.0));
    println!("  trial, 3 degrees of freedom: p {:.6}", tail_series(q_cells, 3.0));
    let props: Vec<f64> = dice.iter().map(|o| o / 60.0).collect();
    let q_prop = pearson(&props, &[1.0 / 6.0; 6]);
    println!("  dice, proportions fed in: Q {:.6}, p {:.6}", q_prop, tail_series(q_prop, 5.0));
    let twice: Vec<f64> = dice.iter().map(|o| 2.0 * o).collect();
    println!("  dice, every roll written down twice: Q {:.4}, p {:.6}", pearson(&twice, &[20.0; 6]), tail_series(2.0 * q_dice, 5.0));
    assert!((tail_series(q_dice, 5.0) - tail_simpson(q_dice, 5.0)).abs() < 1e-8);   // two roads to one tail
    assert!((mean_q - 5.0).abs() < 1e-9 && (var_q - 2.0 * 5.0 * 59.0 / 60.0).abs() < 1e-8);
    assert!((q_cells - z * z).abs() < 1e-12 && (q_short - q_cells).abs() < 1e-12); // three forms of the 2 x 2
    assert!((tail_series(q_cells, 1.0) - 2.0 * (1.0 - phi(z))).abs() < 1e-10);    // chi-square 1 = z squared
    assert!((exact_p - tail_series(q_dice, 5.0)).abs() < 0.01 && size12 < 0.04);  // close at 60, off at 12
    println!("ALL CHECKS PASS");
}
