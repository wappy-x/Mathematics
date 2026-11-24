// Measure-preserving maps and Poincare recurrence -- the same check as the
// Python, in Rust.  No crates.  Exact fractions where the card claims exact
// values; every claim is reached by two roads that share no arithmetic.

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i64, d: i64 }                       // a fraction n/d in lowest terms

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> Fr { let g = gcd(n, d); Fr { n: n / g, d: d / g } }
fn add(x: Fr, y: Fr) -> Fr { fr(x.n * y.d + y.n * x.d, x.d * y.d) }
fn sub(x: Fr, y: Fr) -> Fr { fr(x.n * y.d - y.n * x.d, x.d * y.d) }
fn half_of(x: Fr) -> Fr { fr(x.n, 2 * x.d) }
fn val(x: Fr) -> f64 { x.n as f64 / x.d as f64 }
fn show(x: Fr) -> String { format!("{}/{}", x.n, x.d) }
fn double_mod1(x: Fr) -> Fr { fr((2 * x.n).rem_euclid(x.d), x.d) }

fn doubling_preimage(a: Fr, b: Fr) -> [(Fr, Fr); 2] {   // road one: two half-length pieces
    let one = fr(1, 1);
    [(half_of(a), half_of(b)), (half_of(add(a, one)), half_of(add(b, one)))]
}

fn grid_share(step: &dyn Fn(u64, u64) -> u64, a: f64, b: f64) -> f64 {   // road two
    let m: u64 = 1 << 20;
    let mut c = 0u64;
    for j in 0..m {
        let y = step(j, m) as f64 / m as f64;
        if a <= y && y < b { c += 1 }
    }
    c as f64 / m as f64
}

fn first_return(mut k: u64, level: u32, cut: u64, steps: u32) -> Option<u32> {
    let m: u64 = 1 << level;                       // cell k of width 2^-level
    for n in 1..=steps {
        k = 2 * k % m;
        if k < cut { return Some(n) }
    }
    None
}

const P: f64 = 0.3;                                // chance of a 1 on each toss
fn chance(word: &str) -> f64 {                     // road one: product of toss chances
    word.chars().fold(1.0, |acc, s| acc * if s == '1' { P } else { 1.0 - P })
}
fn preimage_brute(word: &str) -> f64 {             // road two: every string of 8 tosses
    let mut tot = 0.0;
    for k in 0..(1u32 << 8) {
        let s = format!("{:08b}", k);
        if &s[1..1 + word.len()] == word { tot += chance(&s) }
    }
    tot
}

fn main() {
    let (a, b) = (fr(1, 5), fr(1, 2));
    let pieces = doubling_preimage(a, b);
    let total = add(sub(pieces[0].1, pieces[0].0), sub(pieces[1].1, pieces[1].0));
    println!("doubling map T(x) = 2x mod 1 on [0, 1), sizes measured by length");
    println!("preimage of [0.2, 0.5): [{}, {}) and [{}, {}); lengths {} + {} = {}",
             val(pieces[0].0), val(pieces[0].1), val(pieces[1].0), val(pieces[1].1),
             val(sub(pieces[0].1, pieces[0].0)), val(sub(pieces[1].1, pieces[1].0)), val(total));
    let tests = [(fr(0, 1), fr(1, 2)), (fr(1, 5), fr(1, 2)), (fr(1, 3), fr(3, 4)), (fr(1, 10), fr(9, 10)), (fr(2, 7), fr(5, 7))];
    let exact_ok = tests.iter().all(|&(x, y)| {
        let p = doubling_preimage(x, y);
        add(sub(p[0].1, p[0].0), sub(p[1].1, p[1].0)) == sub(y, x)
    });
    println!("5 test intervals, exact fractions: preimage length = own length: {}", if exact_ok { "yes" } else { "no" });
    let g_double = grid_share(&|j, m| 2 * j % m, 0.2, 0.5);
    println!("grid of 2^20 points: share that T sends into [0.2, 0.5) = {:.6}", g_double);
    let image_len = (0..1u64 << 19).map(|j| (2 * j % (1u64 << 20)) >> 10)       // cells of width 2^-10 hit from [0, 0.5)
        .collect::<std::collections::HashSet<u64>>().len() as f64 / 1024.0;
    println!("forward image of [0, 0.5) under T, by landing cells of width 2^-10: length {:.6}, twice the length", image_len);

    let alpha = 2f64.sqrt() - 1.0;
    let (lo, hi) = ((0.2 - alpha).rem_euclid(1.0), (0.5 - alpha).rem_euclid(1.0));
    println!("rotation by sqrt 2 - 1 = {:.6}: preimage of [0.2, 0.5) is [{:.6}, 1) and [0, {:.6}); lengths {:.6} + {:.6} = {:.6}",
             alpha, lo, hi, 1.0 - lo, hi, 1.0 - lo + hi);
    let shift = (alpha * (1u64 << 20) as f64).round() as u64;
    let g_rot = grid_share(&|j, m| (j + shift) % m, 0.2, 0.5);
    println!("grid of 2^20 points: share that the rotation sends into [0.2, 0.5) = {:.6}", g_rot);

    let mut words: Vec<String> = Vec::new();
    for l in 1..=3usize { for k in 0..(1u32 << l) { words.push(format!("{:0w$b}", k, w = l)) } }
    let shift_ok = words.iter().all(|w| (preimage_brute(w) - chance(w)).abs() < 1e-12);
    println!("coin-toss shift, chance of a 1 = {}: block 10 has chance {:.3}; preimage 010 + 110 = {:.3} + {:.3} = {:.3}",
             P, chance("10"), chance("010"), chance("110"), chance("010") + chance("110"));
    println!("all {} blocks of 1 to 3 tosses, brute force over 2^8 strings: preimage chance = own chance: {}",
             words.len(), if shift_ok { "yes" } else { "no" });

    let (mut x, mut visits) = (fr(1, 3), Vec::new());
    for n in 0..9 { if val(x) < 0.5 { visits.push(n) } x = double_mod1(x) }
    println!("1/3 -> 2/3 -> 1/3: in A = [0, 0.5) at steps {}",
             visits.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "));
    let l: u32 = 12;
    let mut counts = vec![0u64; l as usize];
    for k in 0..(1u64 << (l - 1)) {
        if let Some(n) = first_return(k, l, 1 << (l - 1), l - 1) { counts[n as usize] += 1 }
    }
    let size_a = (1u64 << (l - 1)) as f64;
    let shares: Vec<f64> = (1..7).map(|n| counts[n] as f64 / size_a).collect();
    println!("first return to A at step n = 1..6, share of A, by cells: {}",
             shares.iter().map(|s| format!("{:.6}", s)).collect::<Vec<_>>().join(" "));
    println!("the same, formula 2^-n: {}",
             (1..7).map(|n| format!("{:.6}", 2f64.powi(-n))).collect::<Vec<_>>().join(" "));
    let mean_ret = counts.iter().enumerate().map(|(n, &c)| n as f64 * c as f64).sum::<f64>() / counts.iter().sum::<u64>() as f64;
    println!("mean first return, by cells {:.6}; formula sum of n 2^-n = {:.6} = 1/length of A", mean_ret, (1..61).map(|n| n as f64 * 2f64.powi(-n)).sum::<f64>());
    println!("share of A back by step 11, by cells: {:.6}; formula 1 - 2^-11 = {:.6}",
             counts.iter().sum::<u64>() as f64 / size_a, 1.0 - 2f64.powi(-11));

    let (mut y, mut orbit6) = (fr(1, 6), Vec::new());
    for _ in 0..6 { orbit6.push(show(y)); y = double_mod1(y) }
    let quarter = |s: &String| { let v: Vec<i64> = s.split('/').map(|z| z.parse().unwrap()).collect(); 4 * v[0] >= v[1] };
    let never = orbit6[1..].iter().all(quarter) && orbit6[3] == orbit6[5];     // a 2-cycle above 0.25
    println!("A = [0, 0.25): {} is in A, orbit {}; ever back below 0.25: {}", orbit6[0], orbit6.join(" -> "), if never { "no" } else { "yes" });
    let mut fib: Vec<u64> = vec![0, 1, 1];
    while fib.len() < 20 { let k = fib.len(); fib.push(fib[k - 1] + fib[k - 2]) }
    for n in [2u32, 4, 8, 16] {
        let stay = (0..(1u64 << n)).filter(|&k| first_return(k, n + 2, 1 << n, n).is_none()).count();
        let by_cells = stay as f64 / (1u64 << n) as f64;
        let by_fib = fib[n as usize + 1] as f64 / 2f64.powi(n as i32);
        assert!((by_cells - by_fib).abs() < 1e-12);            // cells against Fibonacci count
        println!("share of [0, 0.25) not back by step {}: cells {:.6}, Fibonacci {}/2^{} = {:.6}",
                 n, by_cells, fib[n as usize + 1], n, by_fib);
    }

    let dist = |n: u64| { let f = (n as f64 * alpha).rem_euclid(1.0); f.min(1.0 - f) };
    let (mut best, mut records) = (1.0f64, Vec::new());
    for n in 1..=100u64 { if dist(n) < best { best = dist(n); records.push((n, best)) } }
    println!("closer than ever before, rotation by sqrt 2 - 1: {}",
             records.iter().map(|(n, d)| format!("{}:{:.6}", n, d)).collect::<Vec<_>>().join(" "));
    const EPS: f64 = 0.01;
    let first = (1..=100u64).find(|&n| dist(n) < EPS).unwrap();
    let (mut pell, mut pp, mut qq) = (Vec::new(), 1u64, 1u64);
    while qq <= 100 {
        pell.push((qq, 1.0 / (pp as f64 + qq as f64 * 2f64.sqrt())));   // p^2 - 2 q^2 = +-1
        let t = pp + 2 * qq; qq += pp; pp = t;
    }
    println!("first step back within {} of 0: {}; {} x alpha = {:.6}, distance {:.6}", EPS, first, first, first as f64 * alpha, dist(first));
    println!("Pell road: 99^2 - 2 x 70^2 = {}; distance 1/(99 + 70 sqrt 2) = {:.6}",
             99i64 * 99 - 2 * 70 * 70, 1.0 / (99.0 + 70.0 * 2f64.sqrt()));
    println!("pigeonhole: 101 arcs of width {} around steps 0..100 total {:.2} > 1, so a return by step 100", EPS, 101.0 * EPS);

    let pre_half = grid_share(&|j, _m| j / 2, 0.0, 0.5);       // grid road: the starts that x -> x/2 sends into [0, 0.5)
    let back = (500u64..1000).filter(|&j| (1..=20u32).any(|n| 2 * j >= 1000 * (1u64 << n))).count();
    let line_back = (1..=1000).filter(|&n| { let p = 0.5 + n as f64; 0.0 <= p && p < 1.0 }).count();
    println!("mistake 1, forward image: [0, 0.5) lands on a set of length {:.6}, so 'T doubles length'", image_len);
    println!("mistake 2, x -> x/2: preimage of [0, 0.5), by the 2^20 grid, has length {:.6} not 0.5; of 500 grid starts in [0.5, 1), back within 20 steps: {}",
             pre_half, back);
    println!("mistake 3, x -> x + 1 on the whole line keeps length; 0.5 back in A = [0, 1) within 1000 steps: {} times", line_back);
    let fx: Vec<String> = [0.1, 0.25, 0.6, 0.75].iter().map(|v: &f64| format!("{}", (60.0 + 280.0 * v).round())).collect();
    let fy: Vec<String> = [0.2, 0.5].iter().map(|v: &f64| format!("{}", (360.0 - 280.0 * v).round())).collect();
    println!("figure, 1 = 280 units, x at 0.1 0.25 0.6 0.75: {}; y at 0.2 0.5: {}", fx.join(" "), fy.join(" "));

    assert!(exact_ok && total == sub(b, a) && shift_ok);                    // formula, exactly
    assert!((g_double - 0.3).abs() < 1e-5 && (g_rot - 0.3).abs() < 1e-5);  // grid road agrees
    assert!(((1.0 - lo + hi) - 0.3).abs() < 1e-12 && (mean_ret - 2.0).abs() < 0.01);
    assert!(shares.iter().enumerate().all(|(i, s)| (s - 2f64.powi(-(i as i32) - 1)).abs() < 1e-12));
    assert!(visits == vec![0, 2, 4, 6, 8] && never);
    assert!(first == 70 && records.iter().map(|r| r.0).collect::<Vec<_>>() == pell.iter().map(|r| r.0).collect::<Vec<_>>());
    assert!(records.iter().zip(pell.iter()).all(|(r, q)| (r.1 - q.1).abs() < 1e-9));
    assert!(image_len == 1.0 && pre_half == 1.0);     // both lengths by the grid: the image doubles, x/2 is not kept
    println!("ALL CHECKS PASS");
}
