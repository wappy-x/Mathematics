// The law of a random variable -- the same check as the Python, in Rust.  No
// crates.  Omega = (0, 1), probability = length.  The claim map sends a draw
// u to $0 if u <= 0.3, else to (u - 0.3)/0.7 x $1,000.  Exact probabilities
// are whole numbers of ten-thousandths.  Roads: preimage lengths; shelf 2's
// distribution function F; a grid of 100,000 equal tickets pushed forward one
// by one; a SplitMix64 simulation of a different map Y; bisection.
const U: i64 = 10000;                         // probability unit 1/10000
const N: i64 = 100000;                        // grid size
const LO: i64 = -1_000_000;                   // stand-ins for minus and plus infinity
const HI: i64 = 1_000_000;

fn show(k: i64) -> String { format!("{}.{:04}", k / U, k % U) }

fn cdf(t: i64) -> i64 {                       // road 2: shelf 2's F, in 1/10000
    if t < 0 { 0 } else if t < 1000 { 3000 + 7 * t } else { U }
}

fn preimage(a: i64, b: i64) -> i64 {          // road 1: length of {u : a < X(u) <= b}
    let flat = if a < 0 && 0 <= b { 3000 } else { 0 };
    let (lo, hi) = (a.max(0), b.min(1000));   // the ramp, u from 0.3 + 0.0007 lo to 0.3 + 0.0007 hi
    flat + if hi > lo { 7 * (hi - lo) } else { 0 }
}

// ticket i of n sits at u = (2i+1)/(2n); each map returns its value times 140 n
fn xnum(i: i64, n: i64) -> i64 { (((2 * i + 1) * 10 - 6 * n) * 10000).max(0) }
fn ynum(i: i64, n: i64) -> i64 { if (2 * i + 1) * 10 > 14 * n { 0 } else { (2 * i + 1) * 100000 } }
fn fee(i: i64, n: i64) -> i64 { if 20 * i + 10 <= 6 * n { 0 } else { 500 * 140 * n } }
fn flat(i: i64, _n: i64) -> i64 { (2 * i + 1) * 70000 }
fn rnum(i: i64, n: i64) -> i64 { let d = 14000 * n; (xnum(i, n) + d - 1) / d * d }

fn grid(num: fn(i64, i64) -> i64, a: i64, b: i64, n: i64) -> i64 {   // road 3
    let d = 140 * n;
    (0..n).filter(|&i| a * d < num(i, n) && num(i, n) <= b * d).count() as i64
}

fn dollars(v: i64, n: i64) -> String {        // value/(140 n) to cents, rounded half up
    let c = (v * 200 + 140 * n) / (280 * n);
    format!("{}.{:02}", c / 100, c % 100)
}

fn splitmix(state: u64) -> (u64, u64) {      // road 4: SplitMix64, written out here
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn quantile(p: f64) -> f64 {                  // road 5: inf {x : F(x) >= p}, by bisection
    let f = |x: f64| if x < 0.0 { 0.0 } else if x < 1000.0 { 0.3 + 0.0007 * x } else { 1.0 };
    let (mut lo, mut hi) = (-1.0f64, 1001.0f64);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if f(mid) >= p { hi = mid } else { lo = mid }
    }
    hi
}

fn list(v: &[String]) -> String { format!("[{}]", v.join(", ")) }

fn main() {
    // ---- ten tickets: the definition on a space small enough to list ----
    let ten: Vec<i64> = (0..10).map(|i| xnum(i, 10)).collect();
    println!("ten tickets u = 0.05 .. 0.95, each 0.1; X in dollars: {}",
             list(&ten.iter().map(|&v| dollars(v, 10)).collect::<Vec<_>>()));
    let hit: Vec<i64> = (0..10).filter(|&i| 200 * 1400 < ten[i as usize] && ten[i as usize] <= 500 * 1400).collect();
    let mut values = ten.clone();
    values.dedup();
    let zeros = ten.iter().filter(|&&v| v == 0).count() as f64;
    println!("ten tickets: law puts {} on $0 and 0.1 on each of {} other values", zeros / 10.0, values.len() - 1);
    println!("ten tickets: preimage of (200, 500] = tickets {:?}, probability {}", hit, hit.len() as f64 / 10.0);
    let coarse: Vec<Vec<i64>> = vec![vec![], (0..5).collect(), (5..10).collect(), (0..10).collect()];
    println!("coarse sigma-algebra (none, 0-4, 5-9, all) holds tickets {:?}: {}", hit, if coarse.contains(&hit) { "yes" } else { "no" });
    assert!(hit == vec![4, 5, 6] && !coarse.contains(&hit) && zeros == 3.0);

    // ---- the continuous claim: three roads to each probability ----
    let sets = [("{0}", -1, 0), ("(0, 200]", 0, 200), ("(200, 500]", 200, 500),
                ("(-inf, 250]", LO, 250), ("(900, inf)", 900, HI), ("(1000, inf)", 1000, HI)];
    println!("set | preimage length | F(b) - F(a) | grid of 100000 tickets");
    for &(name, a, b) in sets.iter() {
        let g = grid(xnum, a, b, N);
        println!("{} | {} | {} | {:.5}", name, show(preimage(a, b)), show(cdf(b) - cdf(a)), g as f64 / N as f64);
        assert!(preimage(a, b) == cdf(b) - cdf(a) && (g * U - preimage(a, b) * N).abs() <= 2 * U);
    }
    let union = preimage(-1, 0) + preimage(200, 500) + preimage(900, HI);
    let ug = grid(xnum, -1, 0, N) + grid(xnum, 200, 500, N) + grid(xnum, 900, HI, N);
    println!("union {{0}} or (200, 500] or (900, inf): {} by additivity, {:.5} by the grid", show(union), ug as f64 / N as f64);
    assert!(union == cdf(0) - cdf(-1) + cdf(500) - cdf(200) + U - cdf(900) && (ug * U - union * N).abs() <= 6 * U);

    // ---- the distribution function, and a different map with the same law ----
    let ts: Vec<i64> = (-1..=11).map(|k| 100 * k).collect();
    println!("chart t: {:?}", ts);
    println!("chart F_X exact: {}", list(&ts.iter().map(|&t| format!("{:.2}", cdf(t) as f64 / U as f64)).collect::<Vec<_>>()));
    let seed = 2026u64;
    let (mut state, mut draws) = (seed, Vec::new());
    for _ in 0..20000 {
        let (s, z) = splitmix(state);
        state = s;
        let u = (z >> 11) as f64 * 2.0f64.powi(-53);
        draws.push(if u > 0.7 { 0.0 } else { u / 0.7 * 1000.0 });
    }
    let sim: Vec<f64> = ts.iter().map(|&t| draws.iter().filter(|&&y| y <= t as f64).count() as f64 / 20000.0).collect();
    println!("chart F_Y simulated, 20000 draws, seed {}: {}", seed, list(&sim.iter().map(|s| format!("{:.3}", s)).collect::<Vec<_>>()));
    let same = ts.iter().all(|&t| (grid(ynum, LO, t, N) * U - cdf(t) * N).abs() <= 2 * U);
    println!("F_Y by the grid equals F_X at every chart t: {}", if same { "yes" } else { "no" });
    assert!(same);
    assert!(sim.iter().zip(&ts).all(|(s, &t)| (s - cdf(t) as f64 / U as f64).abs() <= 4.0 * 0.0036));

    // ---- X is the quantile map of F ----
    for &p in [0.1f64, 0.3, 0.44, 0.65, 0.9].iter() {
        let x = if p <= 0.3 { 0.0 } else { (p - 0.3) / 0.7 * 1000.0 };
        println!("u = {}: X(u) = {:.2}, smallest x with F(x) >= u = {:.2}", p, x, quantile(p));
        assert!((x - quantile(p)).abs() < 1e-6);
    }

    // ---- three kinds of law from the same draw u ----
    let kinds: [(&str, fn(i64, i64) -> i64, [f64; 4]); 3] = [("discrete, $500 fee", fee, [0.0, 0.3, 0.3, 1.0]),
        ("continuous, $1,000 x u", flat, [0.0, 0.0, 0.25, 0.5]), ("mixed, the claim", xnum, [0.0, 0.3, 0.475, 0.65])]; // closed forms, by hand
    for &(name, f, want) in kinds.iter() {
        let at: Vec<f64> = [-1, 0, 250, 500].iter().map(|&t| grid(f, LO, t, 10000) as f64 / 10000.0).collect();
        println!("{}: F(0-) {:.4}, F(0) {:.4}, F(250) {:.4}, F(500) {:.4}", name, at[0], at[1], at[2], at[3]);
        assert!(at == want);
    }

    // ---- what breaks ----
    let agree = (0..=10).all(|k| grid(rnum, LO, 100 * k, 10000) == grid(xnum, LO, 100 * k, 10000));
    let r25 = grid(rnum, 200, 250, 10000);
    println!("thresholds 0, 100, .., 1000 only: rounded claim R agrees with X there: {}; P(200 < . <= 250) X {}, R {:.4}",
             if agree { "yes" } else { "no" }, show(preimage(200, 250)), r25 as f64 / 10000.0);
    let diff = (0..N).filter(|&i| xnum(i, N) != ynum(i, N)).count() as i64;
    println!("same law, different maps: X and Y differ on {} of {} tickets", diff, N);
    let even: Vec<f64> = [(200, 500), (LO, 0)].iter().map(|&(a, b)| grid(flat, a, b, 10000) as f64 / 10000.0).collect();
    println!("atom dropped, claim read as spread evenly on $0 to $1,000: P((200, 500]) = {:.4}, not {}; P(X <= 0) = {:.4}, not {}",
             even[0], show(preimage(200, 500)), even[1], show(cdf(0)));
    println!("left limit read as F at the jump: F(0-) = {}, F(0) = {}", show(cdf(-1)), show(cdf(0)));
    assert!(agree && r25 == 0 && preimage(200, 250) == 350 && diff == N && even == vec![0.3, 0.0]);
    let px = |u: f64| 50.0 + 280.0 * u;
    let py = |x: f64| 200.0 - 0.17 * x;
    println!("figure, px = 50 + 280u, py = 200 - 0.17X: kink ({:.1}, {:.1}), top ({:.1}, {:.1}), band py {:.1} to {:.1}, preimage px {:.1} to {:.1}",
             px(0.3), py(0.0), px(1.0), py(1000.0), py(200.0), py(500.0), px(0.3 + 0.0007 * 200.0), px(0.3 + 0.0007 * 500.0));
    println!("ALL CHECKS PASS");
}
