// Product measure -- the same check as the Python, in Rust.  No crates.
// Exact sums on the coarse board are done in whole hundredths (i64).
// A dart lands uniformly on a 1 m by 1 m board; the disc of radius 0.5 m
// centred at (0.5, 0.5) should have chance pi/4.  Roads: vertical sections,
// horizontal sections by bisection, inner and outer grid squares, polar
// coordinates with the Jacobian r, SplitMix64 darts, a six-cell board.

fn atan_inv(k: f64) -> f64 {                 // arctan(1/k) by its series
    let (mut s, mut t, mut n, mut sign) = (0.0, 1.0 / k, 1.0, 1.0);
    while t > 1e-18 {
        s += sign * t / n;
        t /= k * k; n += 2.0; sign = -sign;
    }
    s
}
fn inside(x: f64, y: f64) -> bool { (x - 0.5).powi(2) + (y - 0.5).powi(2) <= 0.25 }
fn sec_len(x: f64) -> f64 { 2.0 * (0.25 - (x - 0.5).powi(2)).max(0.0).sqrt() }
fn edge(y: f64, mut lo: f64, mut hi: f64, want_in_at_hi: bool) -> f64 {
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if inside(mid, y) == want_in_at_hi { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}
fn vertical(n: usize) -> f64 {               // sum of section length x slice width
    let mut tot = 0.0;
    for i in 0..n { tot += sec_len((i as f64 + 0.5) / n as f64); }
    tot / n as f64
}
fn horizontal(n: usize) -> f64 {             // never uses the square-root formula
    let mut tot = 0.0;
    for j in 0..n {
        let y = (j as f64 + 0.5) / n as f64;
        tot += edge(y, 0.5, 1.0, false) - edge(y, 0.0, 0.5, true);
    }
    tot / n as f64
}
fn far_near(i: i64, n: i64) -> (i64, i64) {
    let (a, b) = ((2 * i - n).abs(), (2 * i + 2 - n).abs());
    (a.max(b), if 2 * i <= n && n <= 2 * i + 2 { 0 } else { a.min(b) })
}
fn grid(n: i64) -> (f64, f64) {              // squares of side 1/n, scaled by 2n
    let (mut inner, mut outer) = (0i64, 0i64);
    for i in 0..n {
        let (fx, nx) = far_near(i, n);
        for j in 0..n {
            let (fy, ny) = far_near(j, n);
            if fx * fx + fy * fy <= n * n { inner += 1; }
            if nx * nx + ny * ny < n * n { outer += 1; }
        }
    }
    (inner as f64 / (n * n) as f64, outer as f64 / (n * n) as f64)
}
struct Mix(u64);                             // SplitMix64, uniform in [0, 1)
impl Mix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn sci(x: f64) -> String {                   // 7.6e-03, as Python prints it
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn j(v: &[String]) -> String { v.join(", ") }

fn main() {
    let pi = 16.0 * atan_inv(5.0) - 4.0 * atan_inv(239.0);   // Machin's formula
    let area = pi / 4.0;
    println!("pi by Machin's formula: {:.9}; the disc's area pi/4 = {:.6}, to four places {:.4}", pi, area, area);
    println!("sections at x = 0.1, 0.2, 0.5: {}", j(&[0.1, 0.2, 0.5].iter().map(|&x| format!("{:.4}", sec_len(x))).collect::<Vec<_>>()));
    println!("chart, x: {}", j(&(0..11).map(|i| format!("{:.1}", i as f64 / 10.0)).collect::<Vec<_>>()));
    println!("chart, section length: {}", j(&(0..11).map(|i| format!("{:.2}", sec_len(i as f64 / 10.0))).collect::<Vec<_>>()));
    let ns = [10usize, 100, 1000, 10000];
    let mut v = [0.0; 4];
    let mut h = [0.0; 4];
    for (k, &n) in ns.iter().enumerate() {
        v[k] = vertical(n); h[k] = horizontal(n);
        println!("n = {:5}: vertical sections {:.9}, horizontal by bisection {:.9}, error {}", n, v[k], h[k], sci(v[k] - area));
    }
    let mut g = Vec::new();
    for &n in &[10i64, 100, 1000] {
        let (a, b) = grid(n);
        g.push((a, b));
        println!("grid {:4} x {:<4}: inner squares {:.6} <= area <= touching squares {:.6}", n, n, a, b);
    }
    let mut polar = 0.0;                     // r from 0 to 0.5, theta from 0 to 2 pi
    for k in 0..1000 { polar += (k as f64 + 0.5) * 0.0005 * 0.0005; }
    polar *= 2.0 * pi;
    println!("polar, integral of r dr dtheta: {:.6}; without the Jacobian r: {:.6}", polar, 0.5 * 2.0 * pi);
    let (mut rng, n_darts) = (Mix(2026), 200000);
    let mut hits = 0;
    for _ in 0..n_darts {
        let (x, y) = (rng.next(), rng.next());
        if inside(x, y) { hits += 1; }
    }
    let frac = hits as f64 / n_darts as f64;
    let se = (area * (1.0 - area) / n_darts as f64).sqrt();
    println!("darts: {} of {} in the disc, fraction {:.4}, standard error {:.4}", hits, n_darts, frac, se);
    // ---- a coarse board listed in full: x bands 0.2, 0.5, 0.3; y bands 0.4, 0.6 (tenths) ----
    let (mu, nu) = ([2i64, 5, 3], [4i64, 6]);
    let has = |e: u32, i: usize, jj: usize| e >> (2 * i + jj) & 1 == 1;   // cell (i, j) is bit 2i + j
    let order_x = |e: u32| (0..3).map(|i| mu[i] * (0..2).filter(|&jj| has(e, i, jj)).map(|jj| nu[jj]).sum::<i64>()).sum::<i64>();
    let order_y = |e: u32| (0..2).map(|jj| nu[jj] * (0..3).filter(|&i| has(e, i, jj)).map(|i| mu[i]).sum::<i64>()).sum::<i64>();
    let cells = |e: u32| (0..6).filter(|&c| e >> c & 1 == 1).map(|c| mu[c / 2] * nu[c % 2]).sum::<i64>();
    let agree = (0..64u32).filter(|&e| order_x(e) == order_y(e) && order_y(e) == cells(e)).count();
    let mut rects = std::collections::BTreeSet::new();
    for a in 0..8u32 { for b in 0..4u32 {
        let mut e = 0u32;
        for i in 0..3 { for jj in 0..2 { if a >> i & 1 == 1 && b >> jj & 1 == 1 { e |= 1 << (2 * i + jj); } } }
        rects.insert(e);
    } }
    let pi_sys = rects.iter().all(|&a| rects.iter().all(|&b| rects.contains(&(a & b))));
    let mut sig = rects.clone();
    loop {
        let mut new = std::collections::BTreeSet::new();
        for &a in &sig { new.insert(63 ^ a); for &b in &sig { new.insert(a | b); } }
        if new.is_subset(&sig) { break; }
        sig.extend(new);
    }
    let e: u32 = (0..6).filter(|&c| c / 2 == 1 || c % 2 == 1).map(|c| 1u32 << c).sum();   // middle band or high band
    println!("coarse board: {} distinct rectangles, closed under overlap: {}; they generate {} sets", rects.len(), if pi_sys { "yes" } else { "no" }, sig.len());
    println!("all 64 events: x-order, y-order and cell sums agree on {}", agree);
    println!("middle band or high band: x-order {:.2}, y-order {:.2}", order_x(e) as f64 / 100.0, order_y(e) as f64 / 100.0);
    let px: Vec<String> = (0..3).map(|i| format!("{:.2}", (mu[i] * (0..2).filter(|&jj| has(e, i, jj)).map(|jj| nu[jj]).sum::<i64>()) as f64 / 100.0)).collect();
    let py: Vec<String> = (0..2).map(|jj| format!("{:.2}", (nu[jj] * (0..3).filter(|&i| has(e, i, jj)).map(|i| mu[i]).sum::<i64>()) as f64 / 100.0)).collect();
    println!("  x-order pieces {}; y-order pieces {}", j(&px), j(&py));
    // ---- what breaks ----
    println!("section lengths added without the width 1/n: n = 10 gives {:.4}, n = 100 gives {:.4}", 10.0 * v[0], 100.0 * v[1]);
    let diag: Vec<(f64, f64)> = (0..1000).map(|i| (i as f64 + 0.5) / 1000.0).map(|t| (t, t)).collect(); // counting on y is not sigma-finite
    let d1 = diag.iter().map(|&(x, _)| diag.iter().filter(|&&(u, _)| u == x).count()).sum::<usize>() as f64 / 1000.0; // count each vertical section, times width 1/1000
    let d2: f64 = diag.iter().map(|&(_, y)| { // each horizontal section [y, y]: its length, counted once
        let s: Vec<f64> = diag.iter().filter(|&&(_, v)| v == y).map(|&(u, _)| u).collect();
        s.iter().cloned().fold(f64::MIN, f64::max) - s.iter().cloned().fold(f64::MAX, f64::min)
    }).sum();
    println!("diagonal at 1000 points, lambda x counting: vertical order {:.6}, horizontal order {:.6}", d1, d2);
    let nq = (1..31i64).map(|q| (0..=q).filter(|&p| gcd(p, q) == 1).count()).sum::<usize>();
    let mut cover = 0.0;
    for k in 1..=nq as i32 { cover += 0.01 / 2f64.powi(k); }   // k-th strip 0.01 / 2^k wide
    println!("rational-x strip: {} rationals with denominator <= 30, strips of total area {:.6} = 0.01 x (1 - 2^-{})", nq, cover, nq);
    let s = sec_len(0.2);
    println!("figure, x = 80 + 200u, y = 220 - 200v: centre (180, 120), radius 100; section at u = 0.2 from ({:.0}, {:.0}) to ({:.0}, {:.0})",
             80.0 + 200.0 * 0.2, 220.0 - 200.0 * (0.5 - s / 2.0), 80.0 + 200.0 * 0.2, 220.0 - 200.0 * (0.5 + s / 2.0));
    assert!((v[3] - area).abs() < 3e-7);                          // sections against Machin's pi
    assert!((0..4).all(|k| (h[k] - v[k]).abs() < 1e-9));          // the other order; by symmetry it checks the ends
    assert!(g.iter().all(|&(a, b)| a < area && area < b) && g[2].1 - g[2].0 < 0.01);
    assert!((frac - v[3]).abs() < 4.0 * se);                      // darts against the sections
    assert!(agree == 64 && pi_sys && sig.len() == 64);            // finite board, every event
    assert!((polar - v[3]).abs() < 3e-7);                         // the Jacobian road
    println!("ALL CHECKS PASS");
}
