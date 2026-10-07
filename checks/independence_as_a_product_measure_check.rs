// Independence as a product -- the same check as the Python, in Rust.  No
// crates; exact fractions by hand on small integers.  A dart lands uniformly on
// a 1 m by 1 m board at (x, y).  Three roads: exact formulas in fractions,
// finite grids listed in full, and 200000 simulated darts from SplitMix64.
use std::fmt;

#[derive(Clone, Copy, PartialEq)]
struct R { n: i64, d: i64 }                        // a fraction n/d, kept in lowest terms, d > 0

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i64, d: i64) -> R { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; R { n: s * n / g, d: s * d / g } }
impl std::ops::Add for R { type Output = R; fn add(self, o: R) -> R { r(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for R { type Output = R; fn sub(self, o: R) -> R { r(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for R { type Output = R; fn mul(self, o: R) -> R { r(self.n * o.n, self.d * o.d) } }
impl fmt::Display for R {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } }
}
fn val(q: R) -> f64 { q.n as f64 / q.d as f64 }
fn show(q: R) -> String { format!("{}/{} = {:.6}", q.n, q.d, val(q)) }
fn mn(a: R, b: R) -> R { if less(a, b) { a } else { b } }
fn less(a: R, b: R) -> bool { a.n * b.d < b.n * a.d }
fn max_r(a: R, b: R) -> R { if less(a, b) { b } else { a } }

fn uniform(state: &mut u64) -> f64 {               // SplitMix64, top 53 bits scaled into [0, 1)
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}

fn g(s: R, t: R) -> R {                            // exact P(x <= s, x + y <= t)
    let one = r(1, 1);
    let full = max_r(r(0, 1), mn(s, t - one));
    let (a, b) = (max_r(r(0, 1), t - one), mn(s, t));
    if less(a, b) { full + t * (b - a) - (b * b - a * a) * r(1, 2) } else { full }
}

fn lower_sum(n: i64, h: fn(i64, i64) -> i64) -> R {  // simple function at each cell's lower-left corner
    let mut s = 0;
    for i in 0..n { for j in 0..n { s += h(i, j) } }
    r(s, n * n * n * n)
}

fn count(pairs: &[(usize, usize)], test: &dyn Fn(usize, usize) -> bool) -> i64 {
    pairs.iter().filter(|&&(u, v)| test(u, v)).count() as i64
}

fn ray_pairs(p: &[(usize, usize)], nv: usize) -> (usize, usize) {
    let mut ok = 0;
    for a in 0..4 { for b in 0..nv {
        ok += (16 * count(p, &|u, v| u <= a && v <= b) == count(p, &|u, _| u <= a) * count(p, &|_, v| v <= b)) as usize;
    } }
    (ok, 4 * nv)
}

fn set_pairs(p: &[(usize, usize)], nv: usize) -> (usize, usize) {
    let mut ok = 0;
    for sa in 0..16usize { for sb in 0..(1usize << nv) {
        ok += (16 * count(p, &|u, v| sa >> u & 1 == 1 && sb >> v & 1 == 1)
               == count(p, &|u, _| sa >> u & 1 == 1) * count(p, &|_, v| sb >> v & 1 == 1)) as usize;
    } }
    (ok, 16 << nv)
}

fn main() {
    let n = 200000usize;
    let mut state: u64 = 20260929;
    let (half, quarter) = (r(1, 2), r(1, 4));
    let (ex, ex2) = (half, r(1, 3));
    let var = ex2 - ex * ex;
    let rays = [(quarter, half), (half, half), (half, r(3, 4)), (r(3, 4), quarter)];
    let (mut sums, mut hits, mut both) = ([0.0f64; 5], [0usize; 11], [0usize; 3]);
    let (mut w_hits, mut uw_sum) = (0usize, 0.0f64);
    for _ in 0..n {
        let x = uniform(&mut state); let y = uniform(&mut state);
        for (k, v) in [x * y, x * y * x * y, x + y, (x + y) * (x + y), x * (x + y)].iter().enumerate() { sums[k] += v }
        for (k, &(s, t)) in rays.iter().enumerate() { hits[k] += (x <= val(s) && y <= val(t)) as usize }
        for (k, c) in [0.25, 0.5, 0.75].iter().enumerate() { hits[4 + k] += (x <= *c) as usize; hits[7 + k] += (y <= *c) as usize }
        hits[10] += (x + y <= 0.5) as usize;
        let u = x - 0.5; let w = u * u;
        both[0] += (x <= 0.5 && x + y <= 0.5) as usize; both[1] += (u <= -0.25) as usize;
        both[2] += (u <= -0.25 && w <= 0.0625) as usize;
        w_hits += (w <= 0.0625) as usize; uw_sum += u * w;
    }
    let nf = n as f64;
    let m: Vec<f64> = sums.iter().map(|v| v / nf).collect();
    let se_xy = ((m[1] - m[0] * m[0]) / nf).sqrt();
    let sim_var = m[3] - m[2] * m[2];
    let marg = |q: R| if q == quarter { 0 } else if q == half { 1 } else { 2 };
    println!("dart: x and y uniform on [0, 1] m; {} simulated darts, seed 20260929", n);
    println!("exact E[x] = 1/2, E[x^2] = 1/3, Var(x) = {}/{}", var.n, var.d);
    println!("exact E[x]E[y] = {}", show(ex * ex));
    let grids = [4i64, 16, 64, 256];
    let low: Vec<R> = grids.iter().map(|&k| lower_sum(k, |i, j| i * j)).collect();
    let parts: Vec<String> = grids.iter().zip(&low).map(|(k, q)| format!("n={} {:.6}", k, val(*q))).collect();
    println!("lower sums of xy, n by n grid: {}", parts.join(", "));
    println!("simulated E[xy] = {:.6}, standard error {:.6}", m[0], se_xy);
    println!("exact Var(x + y) = Var(x) + Var(y) = {}; simulated {:.6}", show(r(2, 1) * var), sim_var);
    for (k, &(s, t)) in rays.iter().enumerate() {
        let sim_prod = hits[4 + marg(s)] as f64 / nf * (hits[7 + marg(t)] as f64 / nf);
        println!("ray rectangle x <= {:.2}, y <= {:.2}: exact {}; simulated joint {:.6}, product {:.6}",
                 val(s), val(t), show(s * t), hits[k] as f64 / nf, sim_prod);
    }
    let cells_ij: Vec<(usize, usize)> = (0..16).map(|c| (c / 4, c % 4)).collect();
    let cells_iw: Vec<(usize, usize)> = (0..16).map(|c| (c / 4, c / 4 + c % 4)).collect();
    let (r_ij, s_ij, r_iw, s_iw) = (ray_pairs(&cells_ij, 4), set_pairs(&cells_ij, 4), ray_pairs(&cells_iw, 7), set_pairs(&cells_iw, 7));
    println!("4 by 4 cells, (column, row): ray pairs multiplying {} of {}; set pairs {} of {}", r_ij.0, r_ij.1, s_ij.0, s_ij.1);
    println!("4 by 4 cells, (column, column + row): ray pairs {} of {}; set pairs {} of {}, from 16 x {} events", r_iw.0, r_iw.1, s_iw.0, s_iw.1, 1 << 7);
    let (c0, w0) = (count(&cells_iw, &|u, _| u == 0), count(&cells_iw, &|_, v| v == 0));
    println!("  one failing pair: column 0 has {}/16, sum 0 has {}/16, both {}/16, product {}/256",
             c0, w0, count(&cells_iw, &|u, v| u == 0 && v == 0), c0 * w0);
    let (gv, fv) = (g(half, half), g(r(1, 1), half));
    println!("pair (x, x + y), rectangle x <= 1/2, x + y <= 1/2: exact {}; product 1/2 x {} = {}", show(gv), fv, show(half * fv));
    println!("  simulated joint {:.6}, product {:.6}", both[0] as f64 / nf, hits[5] as f64 / nf * (hits[10] as f64 / nf));
    for t in [r(1, 1), r(3, 2)] {
        println!("  ray x <= 1/2, x + y <= {:.1}: exact {}, product {}", val(t), show(g(half, t)), show(half * g(r(1, 1), t)));
    }
    let exy2 = ex2 + ex * ex;                     // E[x(x + y)] = E[x^2] + E[x]E[y], since x and y are independent
    let low2 = lower_sum(256, |i, j| i * (i + j));
    println!("E[x(x + y)] exact {}; lower sum n=256 {:.6}; simulated {:.6}; E[x]E[x + y] = 1/2 x {} = {}; covariance {}",
             show(exy2), val(low2), m[4], r(2, 1) * ex, ex * r(2, 1) * ex, exy2 - ex * r(2, 1) * ex);
    println!("mistake, Var(x + x) read as Var(x) + Var(x): {}; true Var(2x) {}", show(r(2, 1) * var), show(r(4, 1) * var));
    let board: Vec<(usize, usize)> = (0..4).map(|c| (c / 2, c % 2)).collect();   // quadrants, 1/4 each
    let p = |evs: &[fn(usize, usize) -> bool]| r(count(&board, &|i, j| evs.iter().all(|e| e(i, j))), 4);
    let (l, b, c): (fn(usize, usize) -> bool, fn(usize, usize) -> bool, fn(usize, usize) -> bool) =
        (|i, _| i == 0, |_, j| j == 0, |i, j| i == j);
    println!("mistake, generators {{L, B}} and {{C}}: P(L and C) = {}, P(B and C) = {}, P(L and B) = {}; P(L and B and C) = {}, not {}",
             p(&[l, c]), p(&[b, c]), p(&[l, b]), p(&[l, b, c]), p(&[l, b]) * p(&[c]));
    let (lo, hi) = (max_r(r(0, 1), quarter), mn(quarter, r(3, 4)));   // {x <= 1/4} meets {1/4 <= x <= 3/4}
    let rect_uw = max_r(r(0, 1), hi - lo);
    println!("mistake, u = x - 1/2, w = u^2: E[uw] = E[u^3] = 0 = E[u]E[w]; simulated E[uw] {:.6}", uw_sum / nf);
    println!("  rectangle u <= -1/4, w <= 1/16: exact {}, product {}; simulated {:.6} and {:.6}",
             rect_uw, quarter * half, both[2] as f64 / nf, both[1] as f64 / nf * (w_hits as f64 / nf));
    println!("figure, 140 px per metre; left square 20..160, right 200..340, top 40, bottom 180; left rectangle 70 by 70 px, area {:.6}; right triangle legs 70 px, area {:.6}",
             val(half * half), val(gv));
    let gap = ex * ex - low[3];
    assert!(less(r(0, 1), gap) && less(gap, r(1, 256)));        // grid lower sums climb to the exact 1/4 within 1/n
    assert!((m[0] - 0.25).abs() < 4.0 * se_xy);                  // 200000 darts agree with E[x]E[y] = 1/4
    assert!((sim_var - val(r(2, 1) * var)).abs() < 0.002);       // about 4.5 standard errors of a sample variance
    assert!(r_ij.0 == r_ij.1 && s_ij.0 == s_ij.1);               // rays multiply, and so does every set pair
    assert!(r_iw.0 < r_iw.1 && s_iw.0 < s_iw.1);                 // a failing ray pair shows up among the sets
    assert!((both[0] as f64 / nf - val(gv)).abs() < 4.0 * (val(gv * (r(1, 1) - gv)) / nf).sqrt());
    assert!(gv != half * fv);                                    // (x, x + y) fails on this rectangle
    let gap2 = exy2 - low2;
    assert!(less(r(0, 1), gap2) && less(gap2, r(2, 256)));      // upper minus lower sum of x^2 + xy is 2/n
    assert!(p(&[l, b, c]) != p(&[l, b]) * p(&[c]));              // pairs multiply, the generated sets do not
    println!("ALL CHECKS PASS");
}
