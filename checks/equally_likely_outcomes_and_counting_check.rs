// Counting chances -- the same check as the Python, in Rust.  No crates.
// A five-card poker hand from a shuffled 52-card deck: the chance of a flush,
// five cards of one suit.  Road 1 counts unordered hands with C(n, k).  Road 2
// counts ordered deals.  Road 3 lists all 2,598,960 hands.  Road 4 deals a
// million hands with a seeded SplitMix64 generator written out here.
fn choose(n: u64, k: u64) -> u64 {       // C(n, k), multiplied and divided in turn
    let mut out = 1;
    for i in 0..k { out = out * (n - i) / (i + 1) }
    out
}

fn falling(n: u64, k: u64) -> u64 {      // n x (n-1) x ... , k factors: ordered picks
    (0..k).map(|i| n - i).product()
}

struct SplitMix64 { s: u64 }             // a small seeded generator, same in Python

impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn below(&mut self, n: u64) -> u64 { // a whole number from 0 to n - 1
        ((self.next() as u128 * n as u128) >> 64) as u64
    }
}

fn commas(x: u64) -> String {            // 2598960 -> 2,598,960
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    out
}

fn main() {
    let shapes = ["5", "4-1", "3-2", "3-1-1", "2-2-1", "2-1-1-1"];
    // Road 1: unordered hands.  Pick the suit, then five of its 13 ranks.
    let hands = choose(52, 5);
    let flush = 4 * choose(13, 5);
    let straight_flush = 4 * 10;         // lowest card ace (low) up to ten, in each suit
    let (p_flush, p_proper) = (flush as f64 / hands as f64, (flush - straight_flush) as f64 / hands as f64);
    let c: Vec<u64> = (0..6).map(|j| choose(13, j)).collect();
    let shape_formula = [4 * c[5], 4 * 3 * c[4] * c[1], 4 * 3 * c[3] * c[2],
                         4 * 3 * c[3] * c[1] * c[1], 4 * 3 * c[2] * c[2] * c[1], 4 * c[2] * c[1].pow(3)];
    // Road 2: ordered deals.  Any first card, then 12 of the 51 left share its suit, ...
    let ordered_all = falling(52, 5);
    let ordered_flush = 52 * falling(12, 4);
    // Road 3: list every hand.  A hand's suit counts are packed as one number in base 6.
    let w: Vec<usize> = (0..52).map(|card: u32| 6usize.pow(card / 13)).collect();
    let mut tally = vec![0u64; 1296];
    for a in 0..48 { for b in a + 1..49 { for d in b + 1..50 { for e in d + 1..51 { for f in e + 1..52 {
        tally[w[a] + w[b] + w[d] + w[e] + w[f]] += 1;
    }}}}}
    let mut shape_listed = [0u64; 6];
    for code in 0..1296usize {
        if tally[code] == 0 { continue }
        let mut counts: Vec<usize> = (0..4).map(|s| code / 6usize.pow(s) % 6).filter(|&x| x > 0).collect();
        counts.sort_by(|x, y| y.cmp(x));
        let name = counts.iter().map(|x| x.to_string()).collect::<Vec<_>>().join("-");
        let k = shapes.iter().position(|&s| s == name).unwrap();
        shape_listed[k] += tally[code];
    }
    let listed_hands: u64 = tally.iter().sum();
    let mut listed_sf = 0;               // straights inside one suit, ranks 0 = two ... 12 = ace
    for p in 0..13 { for q in p + 1..13 { for u in q + 1..13 { for v in u + 1..13 { for x in v + 1..13 {
        if x - p == 4 || (p, q, u, v, x) == (0, 1, 2, 3, 12) { listed_sf += 4 }
    }}}}}
    // Road 4: deal a million hands, five swaps of a partial shuffle each.
    let mut rng = SplitMix64 { s: 20260928 };
    let mut deck: Vec<u64> = (0..52).collect();
    let (deals, mut hits) = (1_000_000u64, 0u64);
    for _ in 0..deals {
        for i in 0..5 {
            let j = i + rng.below(52 - i as u64) as usize;
            deck.swap(i, j);
        }
        let s = deck[0] / 13;
        if (1..5).all(|i| deck[i] / 13 == s) { hits += 1 }
    }
    let p_sim = hits as f64 / deals as f64;
    let se = (p_sim * (1.0 - p_sim) / deals as f64).sqrt();
    // The house example: two dice, 36 ordered pairs, against 11 sums taken as equal.
    let sevens = (1..7).flat_map(|x| (1..7).map(move |y| x + y)).filter(|&t| t == 7).count() as u64;
    let patterns = choose(8, 3);
    let mistake1 = 4 * falling(13, 5);

    println!("road 1, hands C(52, 5) = {}; one suit C(13, 5) = {} / 120 = {}; flushes 4 x {} = {}", commas(hands), commas(falling(13, 5)), commas(c[5]), commas(c[5]), commas(flush));
    println!("P(five of one suit) = {} / {} = {:.7}, about 1 in {:.1}", commas(flush), commas(hands), p_flush, hands as f64 / flush as f64);
    println!("less {} straight flushes: {} / {} = {:.7}, about 1 in {:.1}", straight_flush, commas(flush - straight_flush), commas(hands), p_proper, hands as f64 / (flush - straight_flush) as f64);
    println!("road 2, ordered deals 52x51x50x49x48 = {}; ordered flushes 52x12x11x10x9 = {}", commas(ordered_all), commas(ordered_flush));
    println!("ordered ratio = {:.7}; both counts / 5! = 120: {} and {}", ordered_flush as f64 / ordered_all as f64, commas(ordered_all / 120), commas(ordered_flush / 120));
    println!("road 3, hands listed one by one: {}; five of one suit: {}; straight flushes: {}", commas(listed_hands), commas(shape_listed[0]), listed_sf);
    println!("shape, hands by formula, hands listed, percent of all hands");
    for k in 0..6 {
        println!("shape {}, {}, {}, {:.3}", shapes[k], commas(shape_formula[k]), commas(shape_listed[k]), 100.0 * shape_listed[k] as f64 / hands as f64);
    }
    println!("road 4, {} seeded deals: {} flushes, estimate {:.7}, standard error {:.7}", commas(deals), commas(hits), p_sim, se);
    println!("distance from road 1 in standard errors: {:.2}", (p_sim - p_flush) / se);
    println!("mistake 1, ordered top 4 x 13x12x11x10x9 = {} over unordered {} = {:.4}", commas(mistake1), commas(hands), mistake1 as f64 / hands as f64);
    println!("mistake 2, each later card a fresh 1/4 chance: 0.25^4 = {:.8}, {:.2} times too big", 0.25f64.powi(4), 0.25f64.powi(4) / p_flush);
    println!("mistake 3, the {} suit patterns taken as equal: 4 / {} = {:.4}", patterns, patterns, 4.0 / patterns as f64);
    println!("mistake 4, two dice: 7 in {} of 36 pairs = {:.4}; 11 sums taken as equal gives {:.4}", sevens, sevens as f64 / 36.0, 1.0 / 11.0);
    assert!(listed_hands == hands && shape_listed[0] == flush);         // listing agrees with C(n, k)
    assert!(shape_listed == shape_formula && listed_sf == straight_flush);
    assert!(ordered_flush * hands == flush * ordered_all);              // the two ratios are equal
    assert!((p_sim - p_flush).abs() < 4.0 * se);                        // simulation within 4 errors
    let counted = (0..6).flat_map(|p| (0..6).flat_map(move |q| (0..6).map(move |u| p + q + u))).filter(|&t| t <= 5).count() as u64;
    assert!(sevens == (7 - 1).min(13 - 7) && patterns == counted);      // 56 patterns, counted twice
    println!("ALL CHECKS PASS");
}
