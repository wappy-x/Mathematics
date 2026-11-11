// Big-M and yes-or-no switches -- the same check as the Python, in Rust.  No crates.
// A festival books acts from a shortlist of 12.  The main stage holds 8; a ninth
// act needs stage 2, which costs a fixed £40k to open.  Maximise net takings, £k.
// Road 1 lists every plan.  Road 2 sorts.  The relaxations are solved by a greedy
// fill and certified by a dual price.  Then an either-or rule on set times.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, Debug)]
struct Q(i128, i128);                                  // an exact fraction, den > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl PartialEq for Q { fn eq(&self, o: &Q) -> bool { self.0 * o.1 == o.0 * self.1 } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { (self.0 * o.1).partial_cmp(&(o.0 * self.1)) } }
fn f(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn z(n: i128) -> Q { Q(n, 1) }
fn mx(a: Q, b: Q) -> Q { if a > b { a } else { b } }
fn mn(a: Q, b: Q) -> Q { if a < b { a } else { b } }

const V: [i128; 12] = [62, 55, 48, 41, 37, 33, 30, 26, 18, 14, 11, 6]; // acts A..L, £k
const K: i128 = 8; const S2: i128 = 6; const F: i128 = 40;          // slots, charge

fn best_plan(allowed: &dyn Fn(i128, i128) -> bool) -> (i128, i128, i128) { // road 1
    let mut best: Option<(i128, i128, i128)> = None;
    for mask in 0..(1u32 << V.len()) {
        let n = mask.count_ones() as i128;
        for y in 0..2 {
            if allowed(n, y) {
                let val: i128 = (0..V.len()).filter(|i| mask >> i & 1 == 1).map(|i| V[i]).sum::<i128>() - F * y;
                if best.map_or(true, |b| val > b.0) { best = Some((val, n, y)) }
            }
        }
    }
    best.unwrap()
}

fn relax(m: i128) -> (Q, Q, Q) {                       // greedy fill: past 8 acts each
    let (toll, mut n, mut val) = (q(F, m), z(0), z(0)); // unit of an act costs F/M
    for &v in V.iter() {
        let free = mn(z(1), mx(z(0), z(K) - n));
        let extra = if z(v) > toll { mn(z(1) - free, z(K + m) - n - free) } else { z(0) };
        n = n + free + extra;
        val = val + z(v) * free + (z(v) - toll) * extra;
    }
    (val, n, mx(z(0), (n - z(K)) / z(m)))
}

fn dual_bound(m: i128) -> Q {                         // price pi on n - M*y <= 8
    let pi = q(F, m);
    let mut b = z(K) * pi + mx(z(0), pi * z(m) - z(F));
    for &v in V.iter() { b = b + mx(z(0), z(v) - pi) }
    b
}

fn pct(a: Q, b: i128) -> String { format!("{:.2}%", 100.0 * f(a - z(b)) / b as f64) }

fn main() {
    let (z_ip, n_ip, y_ip) = best_plan(&|n, y| n <= K + S2 * y);  // the real rule
    let shut = best_plan(&|n, y| y == 0 && n <= K);
    let opened = best_plan(&|n, y| y == 1 && n <= K + S2);
    let total: i128 = V.iter().sum();
    let by_sort = (V[..K as usize].iter().sum::<i128>(), V[..((K + S2) as usize).min(V.len())].iter().sum::<i128>() - F); // road 2
    let m_small = (0..=(V.len() as i128).min(K + S2)).map(|n| n - K).max().unwrap();
    let vs: Vec<String> = V.iter().map(|v| v.to_string()).collect();
    println!("acts A-L, net value in £k: {} (sum {})", vs.join(" "), total);
    println!("main stage slots {}; stage 2 opening charge £{}k; plans listed: {}", K, F, (1 << V.len()) * 2);
    println!("road 1, every plan: best £{}k, {} acts, stage 2 open = {}", z_ip, n_ip, y_ip);
    println!("best with stage 2 shut £{}k (acts {}); best with it open £{}k", shut.0, &"ABCDEFGHIJKL"[..K as usize], opened.0);
    println!("road 2, by sorting: shut £{}k, open £{}k", by_sort.0, by_sort.1);
    println!("smallest valid M = most that n - 8 can reach = {}", m_small);
    println!("M        relaxed  y         acts n  toll F/M  dual bound  gap to IP");
    let ms: [i128; 6] = [2, 4, 6, 12, 100, 1_000_000];
    let rows: Vec<(Q, Q, Q)> = ms.iter().map(|&m| relax(m)).collect();
    for (i, &m) in ms.iter().enumerate() {
        let (val, n, y) = rows[i];
        println!("{:<8} {:7.2}  {:.6}  {:6.2}  {:8.5}  {:10.2}  {}", m, f(val), f(y), f(n), f(q(F, m)),
                 f(dual_bound(m)), pct(val, z_ip));
    }
    let (v4, n4, y4) = rows[1];
    println!("tight relaxation by hand: 332 + (18-10) + (14-10) + (11-10) = {:.2}", f(v4));
    let parts: Vec<i128> = V.iter().filter(|&&v| v > 10).map(|&v| v - 10).collect();
    let ps: Vec<String> = parts.iter().map(|p| p.to_string()).collect();
    let psum: i128 = parts.iter().sum();
    println!("price bound at M = 4: 8 x 10 + ({}) = 80 + {} = {}", ps.join(" + "), psum, 80 + psum);
    println!("gap in £k: M = 4 {:.2}, M = 100 {:.2}", f(v4 - z(z_ip)), f(rows[4].0 - z(z_ip)));
    let no_link = best_plan(&|_n, _y| true);
    let too_small = best_plan(&|n, y| n <= K + 2 * y);
    println!("mistake 1, no link from n to y: claims £{}k with {} acts, y = {}", no_link.0, no_link.1, no_link.2);
    println!("mistake 2, M = 2: at most {} acts; best £{}k, {} acts, loses £{}k", K + 2, too_small.0, too_small.1, z_ip - too_small.0);
    println!("mistake 3, M = 100: right plan, but bound {:.2}, gap {}", f(rows[4].0), pct(rows[4].0, z_ip));
    println!("mistake 4, M = 1000000: y = {:.6}, under a 0.00001 tolerance it reads 0; plan claims £{:.5}k, 12 acts, stage 2 shut",
             f(rows[5].2), f(rows[5].0));
    // either-or: headliners A (90 min) and B (60 min) share one sound crew, between
    // 18:00 and 23:00.  Times in quarter hours after 18:00.  w = 1 means A plays first.
    let (da, db, end) = (6i128, 4i128, 20i128);
    let pairs: Vec<(i128, i128)> = (0..=end - da).flat_map(|a| (0..=end - db).map(move |b| (a, b))).collect();
    let truth: Vec<(i128, i128)> = pairs.iter().copied().filter(|&(a, b)| a + da <= b || b + db <= a).collect();
    let m_e = pairs.iter().map(|&(a, b)| (a + da - b).max(b + db - a)).max().unwrap();
    let passes = |a: i128, b: i128, m: i128, w: Q| z(a + da - b) <= z(m) * (z(1) - w) && z(b + db - a) <= z(m) * w;
    let model = |m: i128| -> Vec<(i128, i128)> {
        pairs.iter().copied().filter(|&(a, b)| passes(a, b, m, z(0)) || passes(a, b, m, z(1))).collect() };
    let clash_half = pairs.iter().filter(|p| !truth.contains(p) && passes(p.0, p.1, m_e, q(1, 2))).count();
    println!("either-or: {} start pairs on the quarter hour, {} without a clash", pairs.len(), truth.len());
    println!("smallest valid M = {} quarter hours = {} hours; that model keeps {}", m_e, m_e / 4, model(m_e).len());
    println!("M = 4 hours keeps {}; B at 18:00, A at 21:30 kept: {}", model(16).len(),
             if model(16).contains(&(14, 0)) { "yes" } else { "no" });
    println!("relaxed w = 0.5 with M = 5 hours loosens both rules by {} hours; lets {} of {} clashes through",
             m_e as f64 / 8.0, clash_half, pairs.len() - truth.len());
    let px = |n: Q| 60.0 + 20.0 * f(n);
    let py = |y: Q| 200.0 - 140.0 * f(y);
    println!("figure, tight edge ({:.0},{:.0})-({:.0},{:.0}); loose M=100 edge ({:.0},{:.0})-({:.0},{:.1}); optima ({:.0},{:.0}) and ({:.0},{:.1})",
             px(z(8)), py(z(0)), px(z(12)), py(z(1)), px(z(8)), py(z(0)), px(z(12)), py(q(4, 100)),
             px(n4), py(y4), px(z(12)), py(rows[4].2));
    assert!((z_ip, n_ip, y_ip) == (341, 12, 1) && (shut.0, opened.0) == by_sort);  // two roads
    assert!(ms.iter().all(|&m| relax(m).0 == dual_bound(m)));                     // LP certified
    assert!(m_small == 4 && v4 == z(345) && v4 == z(80 + psum) && y4 == q(3, 4) && too_small.0 == 332);
    assert!((1..5).all(|i| rows[i].0 <= rows[i + 1].0));
    assert!(m_e == 20 && model(m_e) == truth && model(16).len() < truth.len());
    println!("ALL CHECKS PASS");
}
