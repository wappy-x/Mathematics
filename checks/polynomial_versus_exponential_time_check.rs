// Polynomial or exponential -- the same check as the Python file, in Rust.  std only, no crates.
// A van's round of 40 stops.  Every cost is a count of named steps, never a stopwatch;
// the times below are those counts divided by an assumed 10^9 steps a second.
// The road chart is synthetic: SplitMix64, seed 2026, each road 5 to 60 miles.
const N: usize = 40;
const RATE: f64 = 1e9;
const HOUR: u128 = 3600 * 1_000_000_000;

fn rand(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn commas(x: u128) -> String {
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn sci(mut x: f64) -> String {
    let mut e = 0;
    while x >= 10.0 { x /= 10.0; e += 1; }
    format!("{:.2} x 10^{}", x, e)
}
fn span(steps: f64) -> String {
    let s = steps / RATE;
    let units = [("million years", 31557600e6), ("years", 31557600.0), ("days", 86400.0),
                 ("hours", 3600.0), ("minutes", 60.0), ("seconds", 1.0)];
    for (unit, size) in units {
        if s >= size {
            let v = format!("{:.1}", s / size);
            let (int, frac) = v.split_at(v.len() - 2);
            return format!("{}{} {}", commas(int.parse().unwrap()), frac, unit);
        }
    }
    format!("{:.0} microseconds", s * 1e6)
}
fn table(d: &Vec<Vec<u64>>, n: usize) -> (Vec<Vec<u64>>, u128) {
    let mut t: Vec<Vec<u64>> = d[..n].iter().map(|r| r[..n].to_vec()).collect();
    let mut checks = 0u128;
    for k in 0..n { for i in 0..n { for j in 0..n {
        checks += 1;
        if t[i][k] + t[k][j] < t[i][j] { t[i][j] = t[i][k] + t[k][j]; }
    } } }
    (t, checks)
}
fn set_by_set(t: &Vec<Vec<u64>>, n: usize) -> (u64, u128, u128) {
    let sets = 1usize << (n - 1);
    let mut best = vec![u64::MAX; sets * n];
    let (mut recs, mut adds) = (0u128, 0u128);
    for s in 1..sets {
        for j in 1..n {
            if (s >> (j - 1)) & 1 == 0 { continue; }
            let r = s & !(1 << (j - 1));
            recs += 1;
            if r == 0 { best[s * n + j] = t[0][j]; continue; }
            let mut v = u64::MAX;
            for i in 1..n {
                if (r >> (i - 1)) & 1 == 1 {
                    adds += 1;
                    let c = best[r * n + i] + t[i][j];
                    if c < v { v = c; }
                }
            }
            best[s * n + j] = v;
        }
    }
    let full = sets - 1;
    let tour = (1..n).map(|j| best[full * n + j] + t[j][0]).min().unwrap();
    (tour, recs, adds + (n as u128) - 1)
}
fn go(t: &Vec<Vec<u64>>, last: usize, left: &Vec<usize>, miles: u64) -> u64 {
    if left.is_empty() { return miles + t[last][0]; }
    left.iter().map(|&x| {
        let rest: Vec<usize> = left.iter().copied().filter(|&y| y != x).collect();
        go(t, x, &rest, miles + t[last][x])
    }).min().unwrap()
}
fn hk_adds(n: u128) -> u128 { let m = n - 1; m * (m - 1) * (1u128 << (m - 2)) + m }
fn largest(cost: &dyn Fn(u128) -> u128, budget: u128) -> u128 {
    let mut n = 1;
    while cost(n + 1) <= budget { n += 1; }
    n
}

fn main() {
    let mut state = 2026u64;
    let mut d = vec![vec![0u64; N]; N];
    for i in 0..N { for j in i + 1..N { let r = 5 + rand(&mut state) % 56; d[i][j] = r; d[j][i] = r; } }
    let (t40, checks40) = table(&d, N);
    assert!(checks40 == (N as u128).pow(3) && table(&d, 20).1 == 8000);
    for i in 0..N { for j in 0..N { for k in 0..N { assert!(t40[i][j] <= t40[i][k] + t40[k][j]); } } }
    for n in 6..10 {
        let rest: Vec<usize> = (1..n).collect();
        assert_eq!(set_by_set(&t40, n).0, go(&t40, 0, &rest, 0));
    }
    println!("set-by-set exact round on the first n stops: steps counted, and growth");
    let mut prev = 0u128;
    for n in 8..15usize {
        let (miles, recs, adds) = set_by_set(&t40, n);
        assert!(adds == hk_adds(n as u128) && recs == (n as u128 - 1) << (n - 2));
        let grow = if prev > 0 { format!("  x{:.3}", adds as f64 / prev as f64) } else { String::new() };
        println!("  n {:2}  cheapest {:3} miles  records {:>7}  steps {:>9}{}", n, miles, commas(recs), commas(adds), grow);
        prev = adds;
    }
    println!("the 40-stop round, steps counted or by formula");
    let rows = [("distance table, n^3 (counted)", checks40), ("every set of stops, 2^n", 1u128 << N),
                ("set-by-set exact round", hk_adds(N as u128))];
    for (label, c) in rows { println!("  {:31} {:>22}   {}", label, commas(c), span(c as f64)); }
    let mut brute40 = 1.0f64;
    for k in 2..N { brute40 *= k as f64; }
    println!("  listing every round, 39!/2       {:>21}   {} years", sci(brute40 / 2.0), sci(brute40 / 2.0 / RATE / 31557600.0));
    println!("  2^40 / 40^3 = {}", commas((1u128 << N) / (N as u128).pow(3)));
    println!("  one more stop: 41^3 = {} (x{:.3}), 2^41 = {} (x2)", commas(41u128.pow(3)), 68921.0 / 64000.0, commas(1u128 << 41));
    for n in [50u128, 60, 80] {
        println!("  n = {}: n^3 {};  2^n {};  set-by-set {}", n, span(n.pow(3) as f64), span((1u128 << n) as f64), span(hk_adds(n) as f64));
    }
    let lead: Vec<u128> = (1u128..121).filter(|&n| (1u128 << n) <= n.pow(3)).collect();
    println!("crossing: n^3 >= 2^n for n = {} to {}; 2^9 = {} <= 9^3 = {}; 2^10 = {} > 10^3 = {}; for n^5 it is n = 23",
             lead[0], lead[lead.len() - 1], 1 << 9, 9 * 9 * 9, 1 << 10, 1000);
    assert!(lead == (2u128..10).collect::<Vec<u128>>() && (4u128..121).all(|n| (n + 1).pow(3) < 2 * n.pow(3)));
    assert_eq!((1u128..121).filter(|&n| (1u128 << n) <= n.pow(5)).max().unwrap(), 22);
    println!("largest n inside a budget, by search and by formula");
    let cube = |n: u128| n.pow(3);
    let pow2 = |n: u128| if n >= 127 { u128::MAX } else { 1u128 << n };
    for (name, budget) in [("1 hour", HOUR), ("1 hour, 1000x faster", 1000 * HOUR), ("1 day", 24 * HOUR)] {
        let (c, e) = (largest(&cube, budget), largest(&pow2, budget));
        assert!(c == (budget as f64).powf(1.0 / 3.0).floor() as u128 && e == (budget as f64).log2().floor() as u128);
        println!("  {:21} n^3: {:>7}   2^n: {}", name, commas(c), e);
    }
    println!("what breaks: n = 8 looks fine: 2^8 = {} < 8^3 = {}", 1 << 8, 8 * 8 * 8);
    println!("what breaks: 1000x faster buys 2^n {} stops, not {}", largest(&pow2, 1000 * HOUR), 10 * 41);
    println!("what breaks: 40^2 = {}, not 2^40", commas(40 * 40));
    println!("what breaks: n^3 on 1,000,000 tracks = {} = {}; n^2 = {}", sci(1e18), span(1e18), span(1e12));
    let s82 = ((1u128 << 82) + HOUR - 1) / HOUR; // least speed-up that fits 82 stops
    assert!(largest(&pow2, s82 * HOUR) == 82 && largest(&pow2, (s82 - 1) * HOUR) == 81);
    println!("what breaks: 82 stops in one hour, by speed alone, needs {}x = {}", commas(s82), sci(s82 as f64));
    let ns: Vec<u32> = (1..9).map(|k| 10 * k).collect();
    println!("chart, n          {}", ns.iter().map(|n| format!("{:7}", n)).collect::<String>());
    println!("chart, log10 n^3  {}", ns.iter().map(|&n| format!("{:7.2}", 3.0 * (n as f64).log10())).collect::<String>());
    println!("chart, log10 2^n  {}", ns.iter().map(|&n| format!("{:7.2}", n as f64 * 2f64.log10())).collect::<String>());
    println!("chart, one hour   {:7.2}", (HOUR as f64).log10());
    println!("ALL CHECKS PASS");
}
