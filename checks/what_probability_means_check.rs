// What probability means -- the same check as the Python, in Rust.  No crates.
// A 30 percent chance of rain, read three ways: as a long-run frequency, as the
// fair price of a $1 ticket, and as a stated belief that a score rewards.
// Random draws come from SplitMix64, written out, seed 20260928, so both
// programs draw exactly the same days and print exactly the same numbers.
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                // a number in [0, 1), 53 random bits
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
const P: f64 = 0.30;                              // the forecast: 30 percent chance of rain
fn brier_exact(q: f64, p: f64) -> f64 { p * ((1.0 - q) * (1.0 - q)) + (1.0 - p) * (q * q) }
fn join(v: &[f64], digits: usize) -> String {
    v.iter().map(|x| format!("{:.*}", digits, x)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let mut rng = SplitMix64 { s: 20260928 };
    // ---- road 1: frequency.  100,000 days on which the chance of rain really is 0.30 ----
    const DAYS: usize = 100000;
    let checks = [10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000];
    let (mut rain, mut wet, mut freqs): (Vec<u8>, u64, Vec<f64>) = (Vec::new(), 0, Vec::new());
    println!("road 1, frequency: days  rainy  share rainy  standard error");
    for d in 1..=DAYS {
        let y: u8 = if rng.uniform() < P { 1 } else { 0 };   // 1 = measurable rain that day
        rain.push(y); wet += y as u64;
        if checks.contains(&d) {
            let se = (P * (1.0 - P) / d as f64).sqrt();
            let f = wet as f64 / d as f64;
            freqs.push(f);
            println!("  {:>6} {:>6} {:>12.4} {:>15.4}", d, wet, f, se);
        }
    }
    let f_all = wet as f64 / DAYS as f64;
    let se_all = (P * (1.0 - P) / DAYS as f64).sqrt();
    println!("chart, share rainy: {}", join(&freqs, 2));
    let mean = |g: &dyn Fn(u8) -> f64| rain.iter().fold(0.0, |acc, &y| acc + g(y)) / DAYS as f64;

    // ---- road 2: price.  A ticket pays $1 if it rains; odds of 7 to 3 against rain ----
    let payout = mean(&|y| if y == 1 { 1.0 } else { 0.0 });   // one ticket a day
    println!("road 2, price: fair price of a $1 rain ticket, from the chance   {:.2}", P);
    println!("  average payout per ticket over the 100,000 days            {:.4}", payout);
    let odds_against = (1.0 - P) / P;
    println!("  odds against rain, (1 - p) / p                               {:.4}", odds_against);
    let win = 7.0;                                            // stake $3 at 7 to 3: win $7
    let exact_gain = 0.0 + P * win + (1.0 - P) * -3.0;        // weigh both outcomes
    let sim_gain = mean(&|y| if y == 1 { win } else { -3.0 });
    println!("  weighed by hand: 0.30 x {:.4} = {:.4} against 0.70 x 3 = {:.4}", win, P * win, (1.0 - P) * 3.0);
    println!("  $3 on rain at 7 to 3: average gain, both outcomes weighed  {:.4}", exact_gain);
    println!("  $3 on rain at 7 to 3: average gain over the days {:.4} (se {:.4})", sim_gain, 10.0 * se_all);
    let even = mean(&|y| if y == 1 { 1.0 } else { -1.0 });   // $1 at even money
    println!("  $1 on rain at even money: average gain over the days {:.4} (se {:.4})", even, 2.0 * se_all);
    let prices = [("rain", 0.30), ("no rain", 0.60)];          // an incoherent bookmaker
    let cost: f64 = prices.iter().fold(0.0, |a, t| a + t.1);
    for weather in ["rain", "no rain"] {                       // enumerate what can happen
        let paid = prices.iter().filter(|t| t.0 == weather).fold(0.0, |a, _| a + 1.0);
        println!("  buy both tickets for ${:.2}, weather is {:<8}: buyer nets {:+.2}", cost, weather, paid - cost);
    }
    let sure_wins = |a: f64, b: f64| -> usize {  // holdings of -5 to 5 of each ticket (negative = sold) netting > 0 in both weathers
        let mut n = 0;
        for h in -5..=5 {
            for k in -5..=5 {
                let (h, k) = (h as f64, k as f64);
                if (h - (h * a + k * b)).min(k - (h * a + k * b)) > 1e-9 { n += 1; }
            }
        }
        n
    };
    let coherent_wins: usize = (0..=100).map(|c| sure_wins(c as f64 / 100.0, 1.0 - c as f64 / 100.0)).sum(); // every price pair summing to 1
    let book_wins = sure_wins(prices[0].1, prices[1].1);
    println!("  searched 121 holdings at each of 101 price pairs summing to 1: {} win in both weathers", coherent_wins);
    println!("  searched 121 holdings at the bookmaker's prices, sum {:.2}: {} win in both weathers", cost, book_wins);

    // ---- road 3: belief.  The Brier score: (forecast - what happened)^2, averaged ----
    let curve: Vec<f64> = (0..11).map(|k| brier_exact(k as f64 / 10.0, P)).collect();
    println!("road 3, belief: expected Brier score for forecasts 0.0 to 1.0 when the chance is 0.30");
    println!("  {}", join(&curve, 2));
    println!("  squared misses: forecast 0.30 costs {:.4} if rain, {:.4} if dry; 0.50 costs {:.4}", 0.7f64 * 0.7, 0.3f64 * 0.3, 0.5f64 * 0.5);
    let mut best_k = 0;                                        // search, no calculus
    for k in 1..=1000 {
        if brier_exact(k as f64 / 1000.0, P) < brier_exact(best_k as f64 / 1000.0, P) { best_k = k; }
    }
    let best = best_k as f64 / 1000.0;
    println!("  forecast with the lowest expected score, searched on a 0.001 grid  {:.3}", best);
    for q in [0.0, 0.3, 0.5] {
        let s = mean(&|y| (q - y as f64) * (q - y as f64));
        println!("  forecast {:.1}: score over the days {:.4}, expected {:.4}", q, s, brier_exact(q, P));
    }
    let sim03 = mean(&|y| (0.3 - y as f64) * (0.3 - y as f64));
    let se03 = 0.4 * (P * (1.0 - P) / DAYS as f64).sqrt();  // 0.49 or 0.09: spread 0.4 per day

    // ---- calibration: two forecasters, 2,000 days at each stated chance ----
    println!("calibration: said  honest: rained  overconfident: really  rained  se");
    let (mut honest_ok, mut over_bad, mut hb, mut ob) = (true, 0, 0.0, 0.0);
    let (mut hon_line, mut over_line, mut said_line) = (Vec::new(), Vec::new(), Vec::new());
    const N: usize = 2000;
    for k in 1..10 {
        let said = k as f64 / 10.0;
        let truth = 0.5 + 0.6 * (said - 0.5);                  // the overconfident forecaster exaggerates
        let (mut h, mut o) = (0u64, 0u64);
        for _ in 0..N {
            let yh = if rng.uniform() < said { 1.0 } else { 0.0 };
            let yo = if rng.uniform() < truth { 1.0 } else { 0.0 };
            h += yh as u64; o += yo as u64;
            hb += (said - yh) * (said - yh); ob += (said - yo) * (said - yo);
        }
        let se = (said * (1.0 - said) / N as f64).sqrt();
        let (hf, of) = (h as f64 / N as f64, o as f64 / N as f64);
        honest_ok = honest_ok && (hf - said).abs() < 4.0 * se;
        if (of - said).abs() > 4.0 * se { over_bad += 1; }
        hon_line.push(hf); over_line.push(of); said_line.push(said);
        println!("  {:>15.1} {:>15.4} {:>22.2} {:>7.4} {:.4}", said, hf, truth, of, se);
    }
    println!("chart, stated chance: {}", join(&said_line, 2));
    println!("chart, honest: {}", join(&hon_line, 2));
    println!("chart, overconfident: {}", join(&over_line, 2));
    let days = (9 * N) as f64;
    println!("  Brier score over the 18,000 days: honest {:.4}, overconfident {:.4}", hb / days, ob / days);

    // ---- mistakes ----
    println!("mistake: odds 3 to 7 read as 3/7 = {:.4}; right: 3/(3 + 7) = {:.4}", 3.0 / 7.0, 3.0 / 10.0);
    println!("mistake: judged on 10 days, share rainy {:.2}, standard error {:.4}", freqs[0], (P * (1.0 - P) / 10.0).sqrt());

    assert!((f_all - P).abs() < 4.0 * se_all);                 // frequency agrees with the chance
    assert!(coherent_wins == 0);                               // no holding beats prices that sum to 1
    assert!(book_wins > 0);                                    // the incoherent bookmaker can be beaten
    assert!((sim_gain - exact_gain).abs() < 4.0 * 10.0 * se_all); // the days agree with both outcomes weighed
    assert!(best == P);                                        // honesty minimises the score
    assert!((sim03 - brier_exact(0.3, P)).abs() < 4.0 * se03); // days against the formula
    assert!(honest_ok);                                        // the honest forecaster is calibrated
    assert!(over_bad >= 6);                                    // the overconfident one is not
    assert!(hb < ob);                                          // and it scores worse
    println!("ALL CHECKS PASS");
}
