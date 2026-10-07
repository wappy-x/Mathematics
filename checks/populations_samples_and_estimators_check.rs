// Samples and estimators -- the check behind the card, in Rust, std only.
// A poll of 1,000 voters reads 52 percent.  The checks fix the electorate's
// true share at 0.52 and ask what the rule "count the yeses, divide by n" does
// over every possible poll.  Roads: the formula, the exact law of the count,
// a seeded simulation of 2,000 polls, and every sample from a town of 25.
const P: f64 = 0.52; const RY: f64 = 0.5; const RN: f64 = 0.6;
const N: usize = 1000; const POLLS: usize = 2000; const SEED: u64 = 20260928; // N: poll size (n on the card)

fn splitmix64(s: u64) -> (u64, u64) { // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn uniform(s: u64) -> (u64, f64) { // a draw in [0, 1) from 53 random bits
    let (s, z) = splitmix64(s);
    (s, (z >> 11) as f64 * 2f64.powi(-53))
}

fn laws(c: f64, sizes: &[usize]) -> Vec<(usize, Vec<f64>)> { // exact law of the yes count, one voter at a time
    let (mut law, mut out) = (vec![1.0f64], Vec::new());
    for n in 1..=*sizes.iter().max().unwrap() {
        law = (0..=n)
            .map(|k| (if k < n { law[k] * (1.0 - c) } else { 0.0 }) + (if k > 0 { law[k - 1] * c } else { 0.0 }))
            .collect();
        if sizes.contains(&n) { out.push((n, law.clone())); }
    }
    out
}

fn get(ls: &[(usize, Vec<f64>)], n: usize) -> &Vec<f64> {
    &ls.iter().find(|(m, _)| *m == n).unwrap().1
}

fn moments(law: &[f64], f: &dyn Fn(usize) -> f64) -> (f64, f64) { // mean and SD of f(count) under a law
    let mut m = 0.0;
    for (k, q) in law.iter().enumerate() { m += q * f(k); }
    let mut v = 0.0;
    for (k, q) in law.iter().enumerate() { v += q * (f(k) - m) * (f(k) - m); }
    (m, v.sqrt())
}

fn within(law: &[f64], lo: i64, hi: i64) -> f64 { // chance the count lies in lo..hi
    let mut t = 0.0;
    for k in lo.max(0)..=hi.min(law.len() as i64 - 1) { t += law[k as usize]; }
    t
}

fn row(label: &str, v: f64) { println!("{:<50} {:>10.6}", label, v); }

fn main() {
    let q = P * RY / (P * RY + (1.0 - P) * RN); // the share among voters who answer
    let sizes = [100usize, 200, 400, 1000];
    let (honest, biased) = (laws(P, &sizes), laws(q, &[N]));
    let share = |n: usize| move |k: usize| k as f64 / n as f64;
    let (h_mean, h_sd) = moments(get(&honest, N), &share(N));
    let (b_mean, b_sd) = moments(get(&biased, N), &share(N));
    let (l_mean, l_sd) = moments(get(&honest, N), &|k| (k as f64 + 1.0) / (N as f64 + 2.0));
    let (f_mean, f_sd) = moments(&[1.0 - P, P], &share(1));

    let (mut state, mut hs, mut hs2, mut hin, mut bs, mut bs2) = (SEED, 0.0f64, 0.0f64, 0usize, 0.0f64, 0.0f64);
    let nf = N as f64;
    for _ in 0..POLLS {
        let mut yes = 0i64;
        for _ in 0..N {
            let (s, u) = uniform(state); state = s;
            yes += (u < P) as i64;
        }
        let a = yes as f64 / nf;
        hs += a;
        hs2 += a * a;
        hin += ((yes - 520).abs() <= 30) as usize;
        let (mut yes, mut answered) = (0i64, 0usize);
        while answered < N { // ask until 1,000 voters have answered
            let (s, u) = uniform(state);
            let (s, v) = uniform(s); state = s;
            if v < (if u < P { RY } else { RN }) {
                answered += 1;
                yes += (u < P) as i64;
            }
        }
        let a = yes as f64 / nf;
        bs += a;
        bs2 += a * a;
    }
    let pf = POLLS as f64;
    let (sim_h, sim_b) = (hs / pf, bs / pf);
    let sim_hsd = (hs2 / pf - sim_h * sim_h).sqrt();
    let sim_bsd = (bs2 / pf - sim_b * sim_b).sqrt();
    let (se_h, se_b) = (sim_hsd / pf.sqrt(), sim_bsd / pf.sqrt());

    let (town, yes_n, n5) = (25usize, 13usize, 5.0f64); // every sample of 5 from a town of 25
    let (mut count, mut s1, mut s2, mut holds0) = (0.0f64, 0.0f64, 0.0f64, 0usize);
    for a in 0..town {
        for b in a + 1..town {
            for c in b + 1..town {
                for d in c + 1..town {
                    for e in d + 1..town {
                        let k = [a, b, c, d, e].iter().filter(|&&x| x < yes_n).count() as f64;
                        count += 1.0;
                        s1 += k / n5;
                        s2 += (k / n5) * (k / n5);
                        holds0 += (a == 0) as usize;
                    }
                }
            }
        }
    }
    let (t_mean, t_var) = (s1 / count, s2 / count - (s1 / count) * (s1 / count));
    let fpc = (town as f64 - n5) / (town as f64 - 1.0);

    row("formula: p(1 - p)", P * (1.0 - P));
    row("formula: SD of the share, sqrt(p(1-p)/n)", (P * (1.0 - P) / nf).sqrt());
    row("exact law: chance within 3 points of 0.52", within(get(&honest, N), 490, 550));
    row("simulated 2,000 polls: mean share", sim_h);
    row("  its standard error", se_h);
    row("simulated: SD of the share", sim_hsd);
    row("simulated: share of polls within 3 points", hin as f64 / pf);
    println!("biased: answering, yes {:.3} + no {:.3} = {:.6}", P * RY, (1.0 - P) * RN, P * RY + (1.0 - P) * RN);
    row("biased: yes share among answerers, formula", q);
    row("biased: bias, that minus 0.52", q - P);
    row("biased exact law: chance within 3 points of 0.52", within(get(&biased, N), 490, 550));
    row("biased simulated 2,000 polls: mean share", sim_b);
    row("  its standard error", se_b);
    println!("chart, noise: n, SD by formula, SD by exact law (bias stays -0.0455)");
    for n in [100usize, 200, 400, 1000, 2000, 4000, 10000] {
        let ex = if sizes.contains(&n) { format!("{:.4}", moments(get(&honest, n), &share(n)).1) } else { "-".to_string() };
        println!("chart, {:>5} {:.4} {:>6}", n, (P * (1.0 - P) / n as f64).sqrt(), ex);
    }
    println!("rules on the same poll, exact law:              mean       bias         SD");
    for (name, m, sd) in [("share K/n", h_mean, h_sd), ("first voter only", f_mean, f_sd),
                          ("always 0.5", 0.5, 0.0), ("(K+1)/(n+2)", l_mean, l_sd),
                          ("biased poll's share", b_mean, b_sd)] {
        println!("  {:<40} {:>10.6} {:>10.6} {:>10.6}", name, m, m - P, sd);
    }
    row("clustered, 100 homes of 10: SD by formula", (P * (1.0 - P) / 100.0).sqrt());
    row("clustered: SD by exact law", moments(get(&honest, 100), &share(100)).1);
    row("clustered: chance within 3 points of 0.52", within(get(&honest, 100), 49, 55));
    println!("{:<50} {:>10.0}", "town of 25, 13 yes: samples of 5, counted", count);
    row("town: chance a given voter is in the sample", holds0 as f64 / count);
    row("town: mean of the share over every sample", t_mean);
    row("town: variance of the share, enumerated", t_var);
    row("town: formula p(1-p)/n x (N-n)/(N-1)", P * (1.0 - P) / n5 * fpc);
    row("town: iid formula p(1-p)/n, drawn with replacement", P * (1.0 - P) / n5);
    row("electorate of 1,000,000: factor (N-n)/(N-1)", (1_000_000.0 - nf) / (1_000_000.0 - 1.0));
    println!("chart, bins of one point: centre, honest poll, biased poll, in percent");
    for j in 0..15i64 {
        let kc = 430 + 10 * j;
        println!("chart, {:.2} {:5.2} {:5.2}", kc as f64 / 1000.0,
                 100.0 * within(get(&honest, N), kc - 5, kc + 4), 100.0 * within(get(&biased, N), kc - 5, kc + 4));
    }

    assert!(sizes.iter().all(|&n| (moments(get(&honest, n), &share(n)).1 - (P * (1.0 - P) / n as f64).sqrt()).abs() < 1e-9),
            "exact law vs the formula's noise");
    assert!((h_mean - P).abs() < 1e-9, "exact law vs the formula's mean");
    assert!((b_mean - q).abs() < 1e-9, "biased exact law vs the answerers' share");
    assert!((sim_h - P).abs() < 4.0 * se_h, "simulated honest polls centre on the truth");
    assert!((sim_b - q).abs() < 4.0 * se_b, "simulated biased polls centre on the answerers' share");
    assert!(P - sim_b > 10.0 * se_b, "and far below the truth");
    assert!((sim_hsd - h_sd).abs() < 4.0 * h_sd / (2.0 * pf).sqrt(), "simulated vs exact noise");
    let hw = within(get(&honest, N), 490, 550);
    assert!((hin as f64 / pf - hw).abs() < 4.0 * (hw * (1.0 - hw) / pf).sqrt(), "simulated vs exact within 3 points");
    assert!((t_mean - yes_n as f64 / town as f64).abs() < 1e-12, "town: unbiased without replacement");
    assert!((t_var - P * (1.0 - P) / n5 * fpc).abs() < 1e-12, "town: enumerated vs corrected formula");
    assert!((holds0 as f64 / count - n5 / town as f64).abs() < 1e-12, "every voter equally likely to be drawn");
    assert!((l_mean - (nf * P + 1.0) / (nf + 2.0)).abs() < 1e-9, "shrunk rule's mean by law vs formula");
    println!("ALL CHECKS PASS");
}
