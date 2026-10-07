// Lebesgue-Stieltjes measures -- the same check as the Python, in Rust.  No
// crates.  Exact rationals by hand on i128, and SplitMix64 written out here for
// the simulated claims.  Money in dollars, probabilities as decimals.
use std::cmp::Ordering;
use std::ops::{Add, Mul, Sub};

#[derive(Clone, Copy, Debug)]
struct Q { n: i128, d: i128 }                 // n / d, d > 0, in lowest terms

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1) * d.signum();
    Q { n: n / g, d: d / g }
}
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl PartialEq for Q { fn eq(&self, o: &Q) -> bool { self.n * o.d == o.n * self.d } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) } }

fn int(n: i128) -> Q { q(n, 1) }
fn p0() -> Q { q(3, 10) }                     // 0.3 chance of $0; else even on 0 to 1,000
const TOP: i128 = 1000;

fn f(x: Q) -> Q {                             // distribution function: P(claim <= x)
    if x < int(0) { int(0) } else if x < int(TOP) { p0() + (int(1) - p0()) * x * q(1, TOP) } else { int(1) }
}
fn g(x: Q) -> Q { if x <= int(0) { int(0) } else { f(x) } }   // left-continuous: P(claim < x)
fn h(x: Q) -> Q { f(x) - if x >= int(400) { q(1, 10) } else { int(0) } }   // dips at 400
fn mass(a: Q, b: Q, cdf: fn(Q) -> Q) -> Q { cdf(b) - cdf(a) }   // road one: the formula on (a, b]

fn dec(r: Q) -> String {                      // exact decimal, first 15 places, zeros trimmed
    let (sign, mut num, den) = (if r.n < 0 { "-" } else { "" }, r.n.abs(), r.d);
    let mut out = format!("{}.", num / den);
    num %= den;
    for _ in 0..15 { num *= 10; out += &(num / den).to_string(); num %= den; }
    format!("{}{}", sign, out.trim_end_matches('0').trim_end_matches('.'))
}

const N: i128 = 10000;                        // road two: [0, 1) cut into N equal cells
fn claim_of(w: Q) -> Q { if w < p0() { int(0) } else { int(TOP) * (w - p0()) * q(10, 7) } }

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn join(v: Vec<String>) -> String { v.join(", ") }

fn main() {
    let cells: Vec<Q> = (0..N).map(|k| claim_of(q(2 * k + 1, 2 * N))).collect();   // cell midpoints
    let grid = |test: &dyn Fn(Q) -> bool| q(cells.iter().filter(|&&c| test(c)).count() as i128, N);
    let just_below = q(-1, 1_000_000_000);
    println!("claim: $0 with probability 0.3, otherwise even over $0 to $1000");
    println!("F(-100) = {}, F(0) = {}, F(200) = {}, F(500) = {}, F(1000) = {}",
             dec(f(int(-100))), dec(f(int(0))), dec(f(int(200))), dec(f(int(500))), dec(f(int(1000))));
    let mut xs = vec![int(-200), int(-100), just_below, int(0)];
    xs.extend((1..=11).map(|k| int(100 * k)));
    println!("chart, F at -200, -100, just below 0, 0, 100, 200, ..., 1100: {}",
             join(xs.iter().map(|&x| format!("{:.2}", f(x).n as f64 / f(x).d as f64)).collect()));
    let road1 = mass(int(200), int(500), f);
    let road2 = grid(&|c| int(200) < c && c <= int(500));
    println!("road 1, formula: mu((200, 500]) = F(500) - F(200) = {}", dec(road1));
    println!("road 2, length on [0, 1): {} cells, {} send the claim into (200, 500], mass {}", N, dec(road2 * int(N)), dec(road2));

    let (mut state, n, mut hits, mut zeros) = (2026u64, 100000i128, 0i128, 0i128);
    for _ in 0..n {
        let (r1, r2) = (splitmix(&mut state), splitmix(&mut state));
        if (r1 >> 11) as f64 / 9007199254740992.0 < 0.3 { zeros += 1; continue; }
        let amount = 1000.0 * ((r2 >> 11) as f64 / 9007199254740992.0);
        if 200.0 < amount && amount <= 500.0 { hits += 1; }
    }
    let se = |p: f64| (p * (1.0 - p) / n as f64).sqrt();
    println!("road 3, simulation (SplitMix64, seed 2026): {} claims, {} in (200, 500], share {}; 4 standard errors = {:.5}",
             n, hits, dec(q(hits, n)), 4.0 * se(0.21));
    println!("         claims of exactly $0: {}, share {}; 4 standard errors = {:.5}", zeros, dec(q(zeros, n)), 4.0 * se(0.3));

    let ks = [1u32, 5, 10];
    println!("jump at 0: F(0) - F(0 - 1/2^n), n = 1, 5, 10: {}; point mass {}",
             join(ks.iter().map(|&k| dec(f(int(0)) - f(q(-1, 1 << k)))).collect()), dec(f(int(0))));
    let atom = grid(&|c| c == int(0));
    println!("road 2, cells sending the claim to exactly $0: {}, mass {}", dec(atom * int(N)), dec(atom));
    println!("right limit at 0: F(0 + 1/2^n), n = 1, 5, 10: {}", join(ks.iter().map(|&k| dec(f(q(1, 1 << k)))).collect()));
    println!("no jump at 350: F(350) - F(350 - 1/2^n), n = 1, 5, 10: {}",
             join(ks.iter().map(|&k| dec(f(int(350)) - f(int(350) - q(1, 1 << k)))).collect()));
    println!("claim above a $200 deductible: 1 - F(200) = {}", dec(int(1) - f(int(200))));

    let piece = |k: u32| (q(500, 1 << (k + 1)), q(500, 1 << k));   // (0, 500] cut in halves
    println!("(0, 500] as the pieces (500/2^(k+1), 500/2^k], k = 0, 1, 2, ...");
    for count in [10u32, 20, 40] {
        let total = (0..count).fold(int(0), |s, k| { let (a, b) = piece(k); s + mass(a, b, f) });
        let tail_free = q(7, 10) * (int(500) - q(500, 1 << count)) * q(1, TOP);   // the even part, directly
        assert!(total == tail_free);                                 // two roads to a partial sum
        println!("  sum of the first {} pieces: {}", count, dec(total));
    }
    let (whole_f, whole_g) = (mass(int(0), int(500), f), mass(int(0), int(500), g));
    let open_left = grid(&|c| int(0) < c && c <= int(500));
    println!("right-continuous F: F(500) - F(0) = {}; road 2 on the grid: {}", dec(whole_f), dec(open_left));
    println!("mistake 1, left-continuous G(x) = P(claim < x): G(500) - G(0) = {}, pieces still sum to {}: additivity fails by {}",
             dec(whole_g), dec(whole_f), dec(whole_g - whole_f));
    let closed = grid(&|c| int(0) <= c && c <= int(500));
    println!("mistake 2, closed [0, 500] as F(500) - F(0) = {}; true F(500) - F(0-) = {}; road 2: {}",
             dec(whole_f), dec(f(int(500)) - f(just_below)), dec(closed));
    let slopes = (0..TOP).fold(int(0), |s, x| s + f(int(x + 1)) - f(int(x)));
    println!("mistake 3, density only: slope 0.0007 per dollar summed over (0, 1000) = {}; missing {}, the jump",
             dec(slopes), dec(int(1) - slopes));
    println!("mistake 4, a dip: H = F minus 0.1 from 400 on gives (350, 400] the mass {}", dec(mass(int(350), int(400), h)));

    assert!(road1 == road2 && f(int(0)) == atom);                     // formula against pushforward
    let (sh, sz) = (hits as f64 / n as f64, zeros as f64 / n as f64);
    assert!((sh - 0.21).abs() < 4.0 * se(0.21) && (sz - 0.3).abs() < 4.0 * se(0.3));
    assert!(whole_f == open_left && closed == f(int(500)) && whole_g != open_left);
    assert!(mass(int(350), int(400), h) < int(0) && slopes == grid(&|c| c > int(0)));   // mistakes 4, 3: slopes vs grid
    println!("ALL CHECKS PASS");
}
