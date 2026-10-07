// Why a new integral -- the same check as the Python, in Rust.  No crates.
// Part 1: a till of 37 coins, $23.45, totalled in the order received and by
// denomination.  Part 2: the rational-minute reading on one hour: 1 when the
// minute count t is a fraction p/q, 0 otherwise.  The code only ever holds
// fractions; what happens at the other times is the proof's job, not the code's.
fn splitmix(state: u64) -> (u64, u64) {             // SplitMix64, written out here
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn usd(cents: u64) -> String { format!("${}.{:02}", cents / 100, cents % 100) } // cents as dollars

fn gcd(mut a: u64, mut b: u64) -> u64 {             // Euclid's algorithm
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn queue(count: usize) -> Vec<(u64, u64)> {         // fractions in [0, 60]: denominator 1, then 2, 3...
    let (mut out, mut q) = (Vec::new(), 1u64);
    while out.len() < count {
        for p in 0..=60 * q {
            if gcd(p, q) == 1 && out.len() < count { out.push((p, q)) }
        }
        q += 1;
    }
    out
}

fn upper_sum(points: &[(u64, u64)], n: u64) -> f64 { // Riemann upper sum of "1 at these points"
    let mut touched = std::collections::BTreeSet::new();
    for &(p, q) in points {
        let (k, r) = (p * n / (60 * q), p * n % (60 * q));
        if k < n { touched.insert(k); }
        if r == 0 && k > 0 { touched.insert(k - 1); }  // on a cut: it touches the slice on its left too
    }
    touched.len() as f64 * 60.0 / n as f64
}

fn upper_brute(points: &[(u64, u64)], n: u64) -> f64 { // road two: slice by slice, exact integer comparison
    let hit = (0..n).filter(|&k| points.iter().any(|&(p, q)| k * 60 * q <= p * n && p * n <= (k + 1) * 60 * q)).count();
    hit as f64 * 60.0 / n as f64
}

fn cover(points: &[(u64, u64)], eps: f64, fixed: f64) -> (f64, f64) { // widths added, clipped union
    let (mut width, mut total, mut spans) = (eps, 0.0f64, Vec::new());
    for &(p, q) in points {
        width = if fixed > 0.0 { fixed } else { width / 2.0 };   // eps/2, eps/4, eps/8 ...
        total += width;
        let c = p as f64 / q as f64;
        spans.push(((c - width / 2.0).max(0.0), (c + width / 2.0).min(60.0)));
    }
    spans.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let (mut union, mut lo, mut hi) = (0.0f64, spans[0].0, spans[0].1);
    for &(a, b) in &spans[1..] {
        if a > hi { union += hi - lo; lo = a; hi = b; } else { hi = hi.max(b); }
    }
    (total, union + hi - lo)
}

fn list(v: &[f64], dp: usize) -> String {
    v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (denoms, counts) = ([100u64, 50, 25, 10, 5, 1], [20usize, 5, 2, 3, 2, 5]);
    let mut coins: Vec<u64> = Vec::new();
    for (v, k) in denoms.iter().zip(counts.iter()) { for _ in 0..*k { coins.push(*v) } }
    let mut state = 2026u64;                          // seed for the order the coins arrived in
    for i in (1..coins.len()).rev() {                 // Fisher-Yates shuffle
        let (s, z) = splitmix(state);
        state = s;
        coins.swap(i, (z % (i as u64 + 1)) as usize);
    }
    let (mut running, mut marks) = (0u64, Vec::new()); // road one: in the order received
    for (i, c) in coins.iter().enumerate() {
        running += c;
        if [10, 20, 30, 37].contains(&(i + 1)) { marks.push(running) }
    }
    let heaps: Vec<(u64, u64)> = denoms.iter().map(|&v| (v, coins.iter().filter(|&&c| c == v).count() as u64)).collect();
    let by_value: u64 = heaps.iter().map(|(v, k)| v * k).sum(); // road two: heaps, count times value
    println!("till: {} coins; order received (cents): {:?}", coins.len(), &coins[..19]);
    println!("  ... continued: {:?}", &coins[19..]);
    println!("running total after 10, 20, 30, 37 coins: {}", marks.iter().map(|&m| usd(m)).collect::<Vec<_>>().join(", "));
    for (v, k) in &heaps { println!("heap of {:>3}c coins: {:>2} coins x {:>3}c = {:>6}", v, k, v, usd(k * v)) }
    let small: Vec<&(u64, u64)> = heaps.iter().filter(|(v, _)| *v <= 25).collect();
    println!("small change, 25c and below: {} coins, {}", small.iter().map(|(_, k)| k).sum::<u64>(),
             usd(small.iter().map(|(v, k)| v * k).sum()));
    println!("by order received: {}   by denomination: {}", usd(running), usd(by_value));
    println!("mistake, counting coins not value: {}; one coin per denomination: {}", coins.len(), usd(denoms.iter().sum()));
    let mut spans = Vec::new();
    let mut x = 20u64;
    for (v, k) in &heaps { spans.push(format!("{}c {}-{}", v, x, x + 8 * k)); x += 8 * k; }
    println!("figure, bar width 8, 0.6 px per cent; heap spans in x: {}", spans.join(", "));

    let fr = queue(10000);
    let halves = fr.iter().position(|&(_, q)| q > 1).unwrap();
    println!("fractions queued: first {}; whole minutes fill places 1 to {}; place {} is {}/{}",
             fr[..3].iter().map(|(p, q)| format!("{}/{}", p, q)).collect::<Vec<_>>().join(", "),
             halves, halves + 1, fr[halves].0, fr[halves].1);
    let reading = |_p: u64, _q: u64| 1.0f64;          // any time the code can hold is p/q, a fraction: reads 1
    let tagged: Vec<f64> = [6u64, 60, 600].iter()     // midpoint of slice k is 60(2k+1)/(2n), a fraction
        .map(|&n| (0..n).map(|k| reading(60 * (2 * k + 1), 2 * n) * 60.0 / n as f64).sum()).collect();
    println!("Riemann sums with midpoint tags, n = 6, 60, 600: {}", list(&tagged, 4));
    let ns = [600u64, 6000, 60000, 600000];
    let ups: Vec<f64> = ns.iter().map(|&n| upper_sum(&fr[..100], n)).collect();
    println!("upper sums, reading switched on at the first 100 fractions, n = 600, 6000, 60000, 600000: {}", list(&ups, 4));
    let brute: Vec<f64> = ns[..2].iter().map(|&n| upper_brute(&fr[..100], n)).collect();
    println!("upper sums again, slice by slice, n = 600, 6000: {}", list(&brute, 4));
    let bounds: Vec<f64> = ns.iter().map(|&n| 2.0 * 100.0 * 60.0 / n as f64).collect();
    println!("bound 2 x 100 x 60 / n:  {}", list(&bounds, 4));
    let rows: Vec<(i32, f64, f64)> = [61usize, 10000].iter().map(|&n| { let (s, u) = cover(&fr[..n], 1.0, 0.0); (n as i32, s, u) }).collect();
    println!("cover of first 10000 fractions, eps = 1 minute: widths add to {:.4}, at most 1: {}; union inside the hour {:.4}",
             rows[1].1, if rows[1].1 <= 1.0 { "yes" } else { "no" }, rows[1].2);
    for eps in [0.01f64, 0.0001] {
        let (s, _) = cover(&fr, eps, 0.0);
        println!("cover of first 10000 fractions, eps = {}: widths add to {:.8}, so 1 x size + 0 x rest <= {:.8}", eps, s, s);
    }
    let (fs, fu) = cover(&fr[..1000], 1.0, 0.1);
    println!("mistake, every width 0.1 for the first 1000: widths add to {:.4}, union inside the hour {:.4}", fs, fu);

    let (mut in_order, mut regrouped, mut sign) = (0.0f64, 0.0f64, 1.0f64); // order matters once signs mix
    for k in 1..=200000u32 { in_order += sign / k as f64; sign = -sign; }
    let (mut odd, mut even) = (1.0f64, 2.0f64);
    for _ in 0..100000 {                              // two positive terms, then one negative
        regrouped += 1.0 / odd + 1.0 / (odd + 2.0) - 1.0 / even;
        odd += 4.0; even += 2.0;
    }
    let (mut ln2, t) = (0.0f64, 1.0f64 / 3.0);         // ln 2 = 2 (t + t^3/3 + t^5/5 + ...), t = 1/3
    for k in 0..40 { ln2 += 2.0 * t.powi(2 * k + 1) / (2 * k + 1) as f64; }
    println!("mistake, 1 - 1/2 + 1/3 - ... in order: {:.4}; two positives per negative: {:.4}", in_order, regrouped);
    println!("ln 2 by its own series: {:.4}; 1.5 x ln 2: {:.4}", ln2, 1.5 * ln2);

    assert!(running == by_value, "two roads to the till");
    assert!(by_value == 2345, "the $23.45 counted in by the till");
    assert!(rows.iter().all(|&(n, s, u)| (s - (1.0 - 0.5f64.powi(n))).abs() < 1e-12 && u <= s), "halving widths");
    assert!(ups.windows(2).all(|w| w[0] > w[1]) && ups.iter().zip(ns.iter()).all(|(u, &n)| *u <= 12000.0 / n as f64));
    assert!(brute[..] == ups[..2], "two roads to the upper sums");
    assert!((in_order - ln2).abs() < 1e-5 && (regrouped - 1.5 * ln2).abs() < 1e-5, "two orders, two sums");
    println!("ALL CHECKS PASS");
}
