// Bayes' rule -- the check behind the card.  Rust std only, no crates.
// A screening test: 1% of people carry the condition, the test flags 99% of
// carriers and 1% of non-carriers.  Every number quoted on the card is printed.
// Roads: the formula, an exact count over equally likely cases, the odds form,
// and a seeded simulation with its standard error.

fn bayes(p: f64, s: f64, f: f64) -> f64 {
    // road 1: the formula
    s * p / (s * p + f * (1.0 - p))
}

fn by_odds(p: f64, s: f64, f: f64) -> f64 {
    // road 3: odds times likelihood ratio
    let after = (p / (1.0 - p)) * (s / f);
    after / (1.0 + after)
}

fn row(label: &str, v: f64) {
    println!("{:<44} {:>12.6}", label, v);
}

struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (z >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let (base, hit, false_alarm) = (0.01_f64, 0.99_f64, 0.01_f64);

    // ---- road 1: formula ----
    let pe = hit * base + false_alarm * (1.0 - base);
    let post = bayes(base, hit, false_alarm);
    row("formula  carrier and positive 0.99*0.01", hit * base);
    row("formula  clear and positive 0.01*0.99", false_alarm * (1.0 - base));
    row("formula  P(E) = 0.99*0.01 + 0.01*0.99", pe);
    row("formula  P(H|E)", post);

    // ---- road 2: count over 100 x 100 equally likely cases ----
    let (mut pos, mut carriers_pos) = (0u64, 0u64);
    for status in 0..100 {
        for test in 0..100 {
            let carrier = status == 0;
            let positive = if carrier { test != 0 } else { test == 0 };
            if positive {
                pos += 1;
                if carrier { carriers_pos += 1; }
            }
        }
    }
    let count_post = carriers_pos as f64 / pos as f64;
    println!("count    cases 10000, positive {}, carriers among them {}", pos, carriers_pos);
    row("count    P(H|E) = carriers / positives", count_post);

    // ---- road 3: odds ----
    row("odds     before, 1 to 99", base / (1.0 - base));
    row("odds     likelihood ratio 0.99 / 0.01", hit / false_alarm);
    row("odds     after", (base / (1.0 - base)) * (hit / false_alarm));
    row("odds     P(H|E) = odds / (1 + odds)", by_odds(base, hit, false_alarm));

    // ---- road 4: seeded simulation (SplitMix64, seed 20260928) ----
    let mut rng = SplitMix64(20260928);
    let (n, mut sim_pos, mut sim_car) = (400000u64, 0u64, 0u64);
    for _ in 0..n {
        let carrier = rng.uniform() < base;
        let positive = rng.uniform() < if carrier { hit } else { false_alarm };
        if positive {
            sim_pos += 1;
            if carrier { sim_car += 1; }
        }
    }
    let est = sim_car as f64 / sim_pos as f64;
    let se = (est * (1.0 - est) / sim_pos as f64).sqrt();
    println!("simulate people {}, positive {}, carriers among them {}", n, sim_pos, sim_car);
    row("simulate P(H|E) estimate", est);
    row("simulate standard error", se);

    // ---- a second, independent positive: count over 100^3 equally likely cases ----
    let (mut both, mut both_car, mut repeat, mut repeat_car) = (0u64, 0u64, 0u64, 0u64);
    for status in 0..100 {
        let carrier = status == 0;
        for t1 in 0..100 {
            let p1 = if carrier { t1 != 0 } else { t1 == 0 };
            if p1 {
                // a repeat of the same sample copies t1
                repeat += 1;
                if carrier { repeat_car += 1; }
            }
            for t2 in 0..100 {
                let p2 = if carrier { t2 != 0 } else { t2 == 0 };
                if p1 && p2 {
                    both += 1;
                    if carrier { both_car += 1; }
                }
            }
        }
    }
    let two_count = both_car as f64 / both as f64;
    let two_odds = by_odds(post, hit, false_alarm);
    println!("second   cases 1000000, both positive {}, carriers {}", both, both_car);
    row("second   count P(H|E1,E2)", two_count);
    row("second   odds 1 x 99 = 99, P(H|E1,E2)", two_odds);

    // ---- house example: two dice.  H = first die 6, E = total 10 ----
    let (mut ten, mut ten_six) = (0u32, 0u32);
    for a in 1..=6 {
        for b in 1..=6 {
            if a + b == 10 {
                ten += 1;
                if a == 6 { ten_six += 1; }
            }
        }
    }
    let dice_count = ten_six as f64 / ten as f64;
    // P(E) by total probability over the first die, not from the count above
    let mut dice_pe = 0.0_f64;
    for a in 1..=6 {
        let k = (1..=6).filter(|b| a + b == 10).count();
        dice_pe += (1.0 / 6.0) * (k as f64 / 6.0);
    }
    let dice_formula = (1.0 / 6.0) * (1.0 / 6.0) / dice_pe;
    row("dice     count P(first 6 | total 10)", dice_count);
    row("dice     formula (1/6)(1/6)/(3/36)", dice_formula);

    // ---- what breaks ----
    row("wrong: hit rate read as the answer", hit);
    row("wrong: healthy positives left out of P(E)", hit * base / (hit * base));
    row("wrong: probability (not odds) times 99", base * hit / false_alarm);
    row("wrong: same, at a 2% base rate", 0.02 * hit / false_alarm);
    row("  right, at a 2% base rate", bayes(0.02, hit, false_alarm));
    row("wrong: repeat of one sample as 2nd test", two_odds);
    row("  right, repeat of one sample (count)", repeat_car as f64 / repeat as f64);
    row("court: innocent matches, 1 in 10000 of 1e6", 1e6 / 10000.0);

    // ---- try changing ----
    row("try: base rate 10%", bayes(0.10, hit, false_alarm));
    row("try: false alarms 0.1%", bayes(base, hit, 0.001));
    row("try: likelihood ratio 0.99 / 0.001", hit / 0.001);
    row("try: hit rate 90%", bayes(base, 0.90, false_alarm));
    row("try: base rate 50%", bayes(0.50, hit, false_alarm));

    // ---- chart: the same test at other base rates (percent) ----
    for b in ["0.1", "0.5", "1", "2", "5", "10", "20", "50"] {
        let r: f64 = b.parse().unwrap();
        println!("sweep    base rate {:>4}%  ->  P(H|E) {:6.2}%", b, 100.0 * bayes(r / 100.0, hit, false_alarm));
    }
    println!("figure, tree: 10000 -> 100 carriers (99 pos, 1 neg), 9900 not (99 pos, 9801 neg)");

    // ---- asserts: each side is reached by a different road ----
    assert!(carriers_pos == 99 && pos == 198); // the count, against the tree
    assert!((post - count_post).abs() < 1e-12); // formula vs count
    assert!((by_odds(base, hit, false_alarm) - count_post).abs() < 1e-12); // odds vs count
    assert!((est - post).abs() < 4.0 * se); // simulation vs formula
    assert!((two_count - two_odds).abs() < 1e-12); // two tests: count vs odds
    assert!((repeat_car as f64 / repeat as f64 - two_odds).abs() > 0.4); // a repeat is not a second test
    assert!((dice_count - dice_formula).abs() < 1e-12); // dice: count vs formula
    println!("all checks passed");
}
