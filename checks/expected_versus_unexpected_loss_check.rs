// Expected and unexpected loss -- the check behind the card.  Rust std only.
// A $1 billion loan book, 2% chance of default per loan, 40% lost in a default.
// Road 1: the formula EL = PD x LGD x EAD.
// Road 2: the loss distribution, from the ratio of neighbouring binomial terms
//         (and, for the ten-loan book, all 1024 default patterns listed).
// Road 3: simulated years, same generator as the Python check.
// Money is printed in $ millions.
const BOOK: f64 = 1000.0;
const PD: f64 = 0.02;
const LGD: f64 = 0.40;

fn book_pmf(n: usize, p: f64) -> Vec<f64> {
    let mut d = vec![0.0; n + 1];
    if p == 0.0 { d[0] = 1.0; return d; }
    d[0] = (1.0 - p).powi(n as i32);
    for k in 0..n {
        d[k + 1] = d[k] * (n - k) as f64 / (k + 1) as f64 * p / (1.0 - p);
    }
    d
}

fn mixed_pmf(n: usize, good: f64, bad: f64) -> Vec<f64> {
    let (g, b) = (book_pmf(n, good), book_pmf(n, bad));
    g.iter().zip(b.iter()).map(|(x, y)| 0.9 * x + 0.1 * y).collect()
}

fn mean_sd(d: &[f64], a: f64) -> (f64, f64) {
    let m: f64 = d.iter().enumerate().map(|(k, w)| k as f64 * a * w).sum();
    let v: f64 = d.iter().enumerate().map(|(k, w)| (k as f64 * a - m).powi(2) * w).sum();
    (m, v.sqrt())
}

fn quantile(d: &[f64], a: f64, alpha: f64) -> f64 {
    let mut cum = 0.0;
    for (k, w) in d.iter().enumerate() {
        cum += w;
        if cum >= alpha { return k as f64 * a; }
    }
    (d.len() - 1) as f64 * a
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) + 1) as f64 * (2.0f64).powi(-53)
    }
    fn defaults(&mut self, n: usize, p: f64) -> usize {
        let (mut count, mut pos) = (0usize, -1i64);
        loop {
            pos += 1 + (self.next().ln() / (1.0 - p).ln()) as i64;
            if pos >= n as i64 { return count; }
            count += 1;
        }
    }
}

fn main() {
    let a_big = BOOK / 1000.0 * LGD;
    let mut d_all = vec![0.0; 1001];
    d_all[0] = 0.98;
    d_all[1000] = 0.02;
    let books: Vec<(&str, Vec<f64>, f64, usize)> = vec![
        ("A 10 loans, independent", book_pmf(10, PD), BOOK / 10.0 * LGD, 10),
        ("B 1000 loans, independent", book_pmf(1000, PD), a_big, 1000),
        ("C 1000 loans, bad years", mixed_pmf(1000, 0.01, 0.11), a_big, 1000),
        ("D 1000 loans, all-or-none", d_all, a_big, 1000),
    ];
    println!("{:<27}{:>8}{:>8}{:>8}{:>8}{:>8}{:>8}{:>8}{:>8}{:>8}",
             "book", "EL", "formula", "sd", "q95", "UL95", "q99", "UL99", "q99.9", "UL99.9");
    let mut res = Vec::new();
    for (name, d, a, n) in &books {
        let (el, sd) = mean_sd(d, *a);
        let formula = PD * LGD * (BOOK / *n as f64) * *n as f64;
        let qs: Vec<f64> = [0.95, 0.99, 0.999].iter().map(|al| quantile(d, *a, *al)).collect();
        assert!((d.iter().sum::<f64>() - 1.0).abs() < 1e-12);
        assert!((el - formula).abs() < 1e-9);
        let mut line = format!("{:<27}{:8.2}{:8.2}{:8.2}", name, el, formula, sd);
        for q in &qs { line += &format!("{:8.2}{:8.2}", q, q - el); }
        println!("{}", line);
        res.push((el, sd, qs));
    }

    // book A again, by listing all 1024 default patterns of ten loans
    let mut pat = [0.0f64; 11];
    for mask in 0u32..1024 {
        let k = mask.count_ones() as usize;
        pat[k] += PD.powi(k as i32) * (1.0 - PD).powi(10 - k as i32);
    }
    let da = &books[0].1;
    for k in 0..11 { assert!((pat[k] - da[k]).abs() < 1e-14); }
    for (al, qi) in [(0.99, 1usize), (0.999, 2)] {
        let (mut k, mut c) = (0usize, pat[0]);
        while c < al { k += 1; c += pat[k]; }
        assert!(res[0].2[qi] == 40.0 * k as f64);   // quantile from the pattern count
    }
    println!("A by hand: P(0)={:.6} P(1)={:.6} P(2)={:.6} P(<=1)={:.6} P(<=2)={:.6}",
             pat[0], pat[1], pat[2], pat[0] + pat[1], pat[0] + pat[1] + pat[2]);

    let (g, b) = (book_pmf(1000, 0.01), book_pmf(1000, 0.11));
    println!("C: normal-year EL {:.2}, recession-year EL {:.2}", mean_sd(&g, 0.4).0, mean_sd(&b, 0.4).0);
    println!("per loan: A loss/default {:.2}, EL {:.2}; B loss/default {:.2}, EL {:.4}",
             BOOK / 10.0 * LGD, PD * LGD * BOOK / 10.0, BOOK / 1000.0 * LGD, PD * LGD * BOOK / 1000.0);
    println!("defaults at q99.9: B {}, C {}; average {}; A P(>=3)={:.6}",
             (res[1].2[2] / 0.4).round() as i64, (res[2].2[2] / 0.4).round() as i64,
             (res[1].0 / 0.4).round() as i64, 1.0 - (pat[0] + pat[1] + pat[2]));

    // what breaks
    let (el_c, sd_c, q_c) = (res[2].0, res[2].1, res[2].2.clone());
    let standalone = 1000.0 * (quantile(&[0.98, 0.02], 0.4, 0.999) - PD * LGD);
    assert!((standalone - (res[3].2[2] - res[3].0)).abs() < 1e-9);
    println!("wrong: forgot LGD, PD x EAD       {:8.2}", PD * BOOK);
    println!("wrong: capital = q99.9 of C       {:8.2}  right UL {:8.2}", q_c[2], q_c[2] - el_c);
    println!("wrong: sum of 1000 one-loan UL99.9 {:7.2}", standalone);
    println!("wrong: C read with B's UL99.9     {:8.2}", res[1].2[2] - res[1].0);
    println!("wrong: UL = one sd, book C        {:8.2}", sd_c);

    // how it moves
    for n in [1usize, 10, 100, 1000] {
        let d = book_pmf(n, PD);
        println!("move: {:>4} loans, UL99.9 {:8.2}", n, quantile(&d, BOOK / n as f64 * LGD, 0.999) - PD * LGD * BOOK);
    }
    for bad in [0.02f64, 0.05, 0.08, 0.11, 0.14, 0.20] {
        let good = ((PD - 0.10 * bad) / 0.90).max(0.0);
        let d = mixed_pmf(1000, good, bad);
        println!("move: bad-year PD {:.2}, good {:.4}, UL99.9 {:8.2}", bad, good, quantile(&d, 0.4, 0.999) - 8.0);
    }

    // chart bands, percent per $4 million of loss
    for (key, i) in [("B", 1usize), ("C", 2)] {
        let d = &books[i].1;
        let bands: Vec<String> = (0..17).map(|j| format!("{:.2}", 100.0 * d[10 * j..10 * j + 10].iter().sum::<f64>())).collect();
        println!("chart {}: {}", key, bands.join(", "));
    }

    // road 3: simulated years
    let mut rng = Rng(20260928);
    let years = 200_000usize;
    for (key, i, n, a, mixed) in [("A", 0usize, 10usize, 40.0, false), ("C", 2, 1000, 0.4, true)] {
        let mut hist = vec![0usize; n + 1];
        for _ in 0..years {
            let p = if mixed { if rng.next() < 0.10 { 0.11 } else { 0.01 } } else { PD };
            hist[rng.defaults(n, p)] += 1;
        }
        let d: Vec<f64> = hist.iter().map(|h| *h as f64 / years as f64).collect();
        let (el, _) = mean_sd(&d, a);
        let (q99, q999) = (quantile(&d, a, 0.99), quantile(&d, a, 0.999));
        println!("sim {}, {} years: EL {:8.2}  q99 {:8.2}  q99.9 {:8.2}", key, years, el, q99, q999);
        assert!((el - res[i].0).abs() < 0.02 * res[i].0);
        assert!((q99 - res[i].2[1]).abs() <= 2.0 * a);
        assert!((q999 - res[i].2[2]).abs() <= 3.0 * a);
    }
}
