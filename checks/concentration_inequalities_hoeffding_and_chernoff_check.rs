// Concentration: Hoeffding and Chernoff -- the check behind the card, in Rust, std only.
// 1,000 fair coin flips.  How likely is a share of heads of 0.55 or more?
// Roads: the three bounds by formula; Chernoff and Hoeffding rebuilt by minimising
// over the dial t numerically; the exact binomial tail, summed term by term; and a
// seeded simulation of 200,000 runs.  Then sample sizes, a 1-in-10 coin, what breaks.
const N: i64 = 1000;
const P: f64 = 0.5;
const C: f64 = 0.55;
const EPS: f64 = 0.05;
const RUNS: usize = 200000;
const SEED: u64 = 20260928;

fn splitmix64(s: u64) -> (u64, u64) {
    // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn tail(n: i64, p: f64, k0: i64) -> f64 {
    // exact P(S >= k0) for S ~ Binomial(n, p); lp = ln P(S = k), stepped up one k at a time
    let (mut lp, r, mut total) = (n as f64 * (1.0 - p).ln(), (p / (1.0 - p)).ln(), 0.0);
    for k in 0..=n {
        if k >= k0 { total += lp.exp(); }
        if k < n { lp += ((n - k) as f64 / (k + 1) as f64).ln() + r; }
    }
    total
}

fn first_k(n: i64) -> i64 { (11 * n + 19) / 20 } // smallest whole k with k / n >= 0.55

fn kl(c: f64, p: f64) -> f64 {
    // the Chernoff exponent D(c || p)
    c * (c / p).ln() + (1.0 - c) * ((1.0 - c) / (1.0 - p)).ln()
}

fn golden<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    // minimise a one-hump-down function on [lo, hi]
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(a) < f(b) { hi = b; } else { lo = a; }
    }
    (lo + hi) / 2.0
}

fn log_chernoff(n: i64, p: f64, c: f64, t: f64) -> f64 {
    // ln of e^(-t c n) M(t)^n, M(t) = 1 - p + p e^t
    -t * c * n as f64 + n as f64 * (1.0 - p + p * t.exp()).ln()
}

fn row(label: &str, v: f64) { println!("{:<52} {:>14.10}", label, v); }

fn main() {
    let nf = N as f64;
    let cheb = (P * (1.0 - P) / (nf * EPS * EPS)).min(1.0); // road 1: the three formulas
    let hoef = (-2.0 * nf * EPS * EPS).exp();
    let cher = (-nf * kl(C, P)).exp();
    let t_c = golden(|t| log_chernoff(N, P, C, t), 0.0, 5.0); // road 2: minimise over the dial
    let cher_num = log_chernoff(N, P, C, t_c).exp();
    let t_h = golden(|t| -t * nf * EPS + nf * t * t / 8.0, 0.0, 5.0);
    let hoef_num = (-t_h * nf * EPS + nf * t_h * t_h / 8.0).exp();
    let exact = tail(N, P, first_k(N)); // road 3: sum the binomial law

    let (mut state, mut hits, mut copied) = (SEED, 0usize, 0usize); // road 4: 200,000 seeded runs
    for _ in 0..RUNS {
        let mut heads = 0u32;
        for j in 0..16 {
            // 15 x 64 bits + 40 bits = 1,000 flips
            let (s, z) = splitmix64(state);
            state = s;
            heads += if j < 15 { z } else { z & ((1u64 << 40) - 1) }.count_ones();
            if j == 0 && (z & 1) as f64 >= C { copied += 1; } // broken 1: the run's first flip, copied
        }
        hits += (heads >= 550) as usize;
    }
    let (sim, copy_sim) = (hits as f64 / RUNS as f64, copied as f64 / RUNS as f64);
    let (sim_se, copy_se) = ((sim * (1.0 - sim) / RUNS as f64).sqrt(), (copy_sim * (1.0 - copy_sim) / RUNS as f64).sqrt());

    let grid: Vec<f64> = (-1000..=1000).map(|i| i as f64 / 100.0).collect(); // Hoeffding's lemma
    let ex_fair = grid.iter().map(|t| (t / 2.0).cosh().ln() - t * t / 8.0).fold(f64::MIN, f64::max);
    let ex_tenth = grid.iter()
        .map(|t| (0.9 * (-0.1 * t).exp() + 0.1 * (0.9 * t).exp()).ln() - t * t / 8.0)
        .fold(f64::MIN, f64::max);

    row("1 Chebyshev: 0.25 / (n eps^2)", cheb);
    row("1 Hoeffding exponent: 2 n eps^2", 2.0 * nf * EPS * EPS);
    row("1 Hoeffding: exp(-2 n eps^2)", hoef);
    row("1 Chernoff: D(0.55 || 0.5)", kl(C, P));
    row("1 Chernoff: exp(-n D)", cher);
    row("2 Chernoff by minimising over t: best t", t_c);
    row("2   bound at that t", cher_num);
    row("2 Hoeffding by minimising over t: best t", t_h);
    row("2   bound at that t", hoef_num);
    row("3 exact binomial tail P(S >= 550)", exact);
    row("4 simulated, 200,000 runs: share with S >= 550", sim);
    row("4   its standard error", sim_se);
    row("worked: cosh(0.1), centred coin's M at t = 0.2", 0.1f64.cosh());
    row("worked: exp(0.2^2 / 8), Hoeffding's ceiling for it", 0.005f64.exp());
    row("lemma: largest excess on the grid, fair coin", ex_fair);
    row("lemma: largest excess on the grid, 1-in-10 coin", ex_tenth);
    row("two-sided: Hoeffding 2 exp(-2 n eps^2)", 2.0 * hoef);
    row("two-sided: exact P(|S - 500| >= 50)", 2.0 * exact);
    println!("chart, percent:  n   Chebyshev   Hoeffding   exact");
    for n in (100..=1000).step_by(100) {
        let x = n as f64;
        println!("chart, {:>11}   {:>9.2}   {:>9.2}   {:>5.2}", n, 100.0 * (100.0 / x).min(1.0), 100.0 * (-x / 200.0).exp(), 100.0 * tail(n, P, first_k(n)));
    }
    let ts: Vec<String> = (0..9).map(|i| format!("{:>6.2}", i as f64 / 20.0)).collect();
    println!("chart, t:       {}", ts.join(" "));
    let bs: Vec<String> = (0..9).map(|i| format!("{:>6.2}", 100.0 * log_chernoff(N, P, C, i as f64 / 20.0).exp())).collect();
    println!("chart, bound %: {}", bs.join(" "));
    let n_h = ((100f64).ln() / (2.0 * EPS * EPS)).ceil() as i64;
    let ex_n: Vec<f64> = (1..=1200).map(|n| tail(n, P, first_k(n))).collect();
    let ok: Vec<i64> = (1..=1200).filter(|&n| ex_n[n as usize - 1] <= 0.01).collect();
    let bad: Vec<i64> = (1..=1200).filter(|&n| ex_n[n as usize - 1] > 0.01).collect();
    let last_bad = *bad.last().unwrap();
    println!("99% sure: Chebyshev n = {}, Hoeffding n = {}, exact first n = {}, last n above 0.01 = {}",
        (0.25 / (0.01 * EPS * EPS)).round() as i64, n_h, ok[0], last_bad);
    row(&format!("Hoeffding bound at n = {}", n_h), (-2.0 * n_h as f64 * EPS * EPS).exp());
    row(&format!("Hoeffding bound at n = {}", n_h - 1), (-2.0 * (n_h - 1) as f64 * EPS * EPS).exp());
    row(&format!("exact tail at n = {}", last_bad + 1), ex_n[last_bad as usize]);
    let (ten_ex, ten_ch) = (tail(N, 0.1, 150), (-nf * kl(0.15, 0.1)).exp());
    row("1-in-10 coin, S >= 150: Hoeffding", hoef);
    row("1-in-10 coin: Chernoff exp(-n D(0.15 || 0.1))", ten_ch);
    row("1-in-10 coin: exact tail", ten_ex);
    row("die, 1,000 rolls, eps 0.1: Chebyshev, both sides", 35.0 / 12.0 / (nf * 0.1 * 0.1));
    row("die: Hoeffding, range 1 to 6, both sides", 2.0 * (-2.0 * nf * 0.1 * 0.1 / 25.0).exp());
    let (mut alive, mut stopped, mut law) = (vec![1.0f64], 0.0f64, vec![1.0f64]); // broken 3: look after every flip
    for k in 1..=N as usize {
        // law: the heads count, flip by flip
        alive = (0..=k).map(|s| 0.5 * ((if s < k { alive[s] } else { 0.0 }) + (if s > 0 { alive[s - 1] } else { 0.0 }))).collect();
        law = (0..=k).map(|s| 0.5 * ((if s < k { law[s] } else { 0.0 }) + (if s > 0 { law[s - 1] } else { 0.0 }))).collect();
        if k >= 100 {
            for s in first_k(k as i64) as usize..=k { stopped += alive[s]; alive[s] = 0.0; }
        }
    }
    let law_tail: f64 = law[550..].iter().sum();
    row("3 the same tail, adding one flip at a time", law_tail);
    let copies = [0.0f64, 1.0].iter().filter(|&&face| face >= C).count() as f64 / 2.0; // broken 1
    row("broken 1, one flip copied 1,000 times", copies);
    println!("broken 1, simulated, each run's first flip copied: {:.4} (standard error {:.4})", copy_sim, copy_se);
    row("broken 2, +1/-1 score, width taken as 1: 'bound'", (-2.0 * nf * 0.1 * 0.1).exp());
    row("broken 3, looked at after every flip, 100 to 1,000", stopped);

    assert!((cher_num - cher).abs() < 1e-9 * cher, "Chernoff: closed form vs numerical minimum");
    assert!((hoef_num - hoef).abs() < 1e-9 * hoef, "Hoeffding: closed form vs numerical minimum");
    assert!(ex_fair <= 1e-15, "Hoeffding's lemma holds on the whole grid, fair coin");
    assert!(ex_tenth <= 1e-15, "Hoeffding's lemma holds on the whole grid, 1-in-10 coin");
    assert!((law_tail - exact).abs() < 1e-12, "two exact roads: term by term, flip by flip");
    assert!(exact <= cher, "exact under Chernoff");
    assert!(cher <= hoef, "Chernoff under Hoeffding for a fair coin");
    assert!((1..=1200).all(|n| ex_n[n as usize - 1] <= (100.0 / n as f64).min(1.0)), "exact under Chebyshev");
    assert!((1..=1200).all(|n| ex_n[n as usize - 1] <= (-(n as f64) / 200.0).exp()), "exact under Hoeffding");
    assert!((sim - exact).abs() < 4.0 * sim_se, "simulation vs the exact tail");
    assert!((-2.0 * n_h as f64 * EPS * EPS).exp() <= 0.01, "whole-number n: enough");
    assert!((-2.0 * (n_h - 1) as f64 * EPS * EPS).exp() > 0.01, "whole-number n: one fewer is not");
    assert!(ten_ex <= ten_ch, "Chernoff holds for the 1-in-10 coin");
    assert!(1000.0 * ten_ch < hoef, "Chernoff sees the 1-in-10 coin, Hoeffding does not");
    assert!(copy_sim - 4.0 * copy_se > hoef, "copied flips break the bound, simulated");
    assert!(stopped > hoef, "looking after every flip breaks the bound");
    assert!((-2.0 * nf * 0.1 * 0.1).exp() < exact, "a misdeclared range promises less than the truth");
    println!("ALL CHECKS PASS");
}
