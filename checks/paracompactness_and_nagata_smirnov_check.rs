// Paracompactness, partitions of unity, Nagata-Smirnov -- the check behind the card.  Rust std only.
// The line, covered by U_n = (n - 3/2, n + 3/2).  Survey heights in metres at kilometre markers 0 to 5.
use std::cmp::Ordering;
use std::fmt;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, Debug)]
struct Q { n: i64, d: i64 } // an exact fraction n/d, always in lowest terms with d > 0
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i64) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialEq for Q { fn eq(&self, o: &Q) -> bool { self.n * o.d == o.n * self.d } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) } }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } }
}
impl Q { fn abs(self) -> Q { q(self.n.abs(), self.d) } fn floor(self) -> i64 { self.n.div_euclid(self.d) } fn f(self) -> f64 { self.n as f64 / self.d as f64 } }
fn mx(a: Q, b: Q) -> Q { if a > b { a } else { b } }
fn near(x: Q) -> std::ops::Range<i64> { x.floor() - 3..x.floor() + 4 } // tents and dials vanish beyond these
fn in_u(x: Q, n: i64) -> bool { (x - z(n)).abs() < q(3, 2) }
fn tent(x: Q, n: i64) -> Q { mx(z(0), z(1) - (x - z(n)).abs()) } // zero outside [n - 1, n + 1]
fn psi(x: Q, n: i64) -> Q { // Urysohn dial: 1 on [n-3/5, n+3/5], 0 outside (n-6/5, n+6/5)
    let (da, db) = (mx(z(0), q(6, 5) - (x - z(n)).abs()), mx(z(0), (x - z(n)).abs() - q(3, 5)));
    da / (da + db)
}
fn big_psi(x: Q) -> Q { near(x).fold(z(0), |s, n| s + psi(x, n)) }
fn phi(x: Q, n: i64) -> Q { psi(x, n) / big_psi(x) }
const H: [i64; 6] = [120, 128, 135, 150, 146, 140]; // heights at the markers, metres
fn glue(x: Q, w: fn(Q, i64) -> Q) -> Q { (0..6).fold(z(0), |s, n| s + w(x, n as i64) * z(H[n])) }
fn has(s: (i64, i64), x: Q) -> bool { z(s.0) < x.abs() && x.abs() < z(s.1) } // s = (lo, hi): lo < |x| < hi
fn meets_win(s: (i64, i64), a: Q, b: Q) -> bool { // does s meet the window (a, b)?
    let (m1, m2) = if a < z(0) && z(0) < b { (z(-1), mx(z(0) - a, b)) } else if a.abs() < b.abs() { (a.abs(), b.abs()) } else { (b.abs(), a.abs()) };
    z(s.0) < m2 && m1 < z(s.1)
}
fn ring_refine(cover: &[(i64, i64)], kk: i64) -> Vec<(i64, i64)> {
    (1..=kk).map(|k| { // compact ring C_k: k-1 <= |x| <= k; take the first member holding it, cut to k-2 < |x| < k+1
        let &(lo, hi) = cover.iter().find(|c| c.0 < k - 1 && c.1 > k).unwrap();
        (lo.max(k - 2), hi.min(k + 1))
    }).collect()
}
fn basic(x: Q, r: Q) -> (i64, Q, Q) { // a layer set holding x inside (x - r, x + r)
    let j = (0..40).find(|&j| q(2, 1 << j) <= r).unwrap();
    let t = x * z(1 << j);
    let m = t.floor() + if t - z(t.floor()) > q(1, 2) { 1 } else { 0 };
    (j, q(m - 1, 1 << j), q(m + 1, 1 << j))
}
fn main() {
    let half = q(1, 2);
    let grid: Vec<Q> = (-400..=400).map(|j| q(j, 20)).collect(); // x from -20 to 20 in steps of 0.05
    let ns = -25..26i64;
    let inside: Vec<usize> = grid.iter().map(|&x| ns.clone().filter(|&n| in_u(x, n)).count()).collect();
    let meets: Vec<usize> = grid.iter().map(|&x| ns.clone().filter(|&n| (x - z(n)).abs() < z(2)).count()).collect();
    let (imin, imax, mmax) = (*inside.iter().min().unwrap(), *inside.iter().max().unwrap(), *meets.iter().max().unwrap());
    println!("cover U_n=(n-1.5,n+1.5) on {} grid points: each point in {} to {} sets; a width-1 window meets at most {}", grid.len(), imin, imax, mmax);
    assert!(imin == 2 && imax == 3 && mmax == 4);
    assert!(grid.iter().all(|&x| ns.clone().all(|n| near(x).contains(&n) || tent(x, n) == z(0))));
    assert!(grid.iter().all(|&x| near(x).fold(z(0), |s, n| s + tent(x, n)) == z(1))); // term-by-term sum, exact
    assert!(grid.iter().all(|&x| near(x).fold(z(0), |s, n| s + tent(x, n) * z(n)) == x)); // tents reproduce straight lines
    println!("tents: sum exactly 1 at all {} points; support [n-1,n+1] sits inside U_n with {} to spare", grid.len(), half);
    let x = q(23, 10);
    let inn: Vec<String> = ns.clone().filter(|&n| in_u(x, n)).map(|n| n.to_string()).collect();
    let nz: Vec<String> = ns.clone().filter(|&n| tent(x, n) != z(0)).map(|n| format!("phi_{}={}", n, tent(x, n))).collect();
    println!("x=2.3: in U_n for n = [{}]; nonzero tents {}", inn.join(", "), nz.join(", "));
    assert!(tent(x, 2) == q(7, 10) && tent(x, 3) == q(3, 10));
    println!("heights at markers 0 to {} km: {} m", H.len() - 1, H.iter().map(|v| v.to_string()).collect::<Vec<String>>().join(", "));
    let line = z(H[2]) + (x - z(2)) * z(H[3] - H[2]); // second road: straight line, markers 2 to 3
    println!("glued height at 2.3 km: tents {:.1} m; straight line between markers {:.1} m", glue(x, tent).f(), line.f());
    assert!(glue(x, tent) == line && line == q(279, 2));
    assert!(grid.iter().all(|&x| ns.clone().any(|n| (x - z(n)).abs() < q(3, 5)))); // the shrunk sets W_n still cover
    assert!(grid.iter().all(|&x| z(1) <= big_psi(x) && big_psi(x) <= z(2) && near(x).fold(z(0), |s, n| s + phi(x, n)) == z(1)));
    assert!(grid.iter().all(|&x| ns.clone().all(|n| (x - z(n)).abs() < q(6, 5) || psi(x, n) == z(0))));
    let ps: Vec<Q> = grid.iter().map(|&x| big_psi(x)).collect();
    let pmin = ps.iter().fold(z(9), |a, &b| if b < a { b } else { a });
    let pmax = ps.iter().fold(z(0), |a, &b| mx(a, b));
    println!("dial partition: Psi between {} and {}; after dividing, sum exactly 1 at all {} points; support [n-6/5,n+6/5] inside U_n", pmin, pmax, grid.len());
    println!("dial partition at 2.3: psi_2={} psi_3={} Psi={} phi_2={} phi_3={}; glued height {} = {:.3} m",
             psi(x, 2), psi(x, 3), big_psi(x), phi(x, 2), phi(x, 3), glue(x, phi), glue(x, phi).f());
    assert!(phi(x, 2) == q(6, 11) && glue(x, phi) == q(1560, 11));
    // thinning: the cover V_k = (-k, k) by the proof's ring recipe
    let v: Vec<(i64, i64)> = (1..41).map(|k| (-1, k)).collect();
    let w = ring_refine(&v, 30);
    let in_w: Vec<usize> = grid.iter().map(|&x| w.iter().filter(|&&s| has(s, x)).count()).collect();
    let m_w: Vec<usize> = grid.iter().map(|&x| w.iter().filter(|&&s| meets_win(s, x - half, x + half)).count()).collect();
    let ks: Vec<String> = [10, 100, 1000].iter().map(|&kk| format!("K={}: {}", kk, (1..=kk).filter(|&k| has((-1, k), z(0))).count())).collect();
    println!("V_k=(-k,k): the first K sets all hold 0: {}", ks.join(", "));
    let (wmin, wmax, mwmax) = (*in_w.iter().min().unwrap(), *in_w.iter().max().unwrap(), *m_w.iter().max().unwrap());
    let w3: Vec<String> = w[..3].iter().enumerate().map(|(i, s)| format!("W_{}: {}<|x|<{}", i + 1, s.0, s.1)).collect();
    println!("ring refinement W_k={{k-2<|x|<k+1}}: {}; each point in {} to {} sets, a width-1 window meets at most {}", w3.join(" "), wmin, wmax, mwmax);
    assert!(wmin >= 1 && wmax == 3 && mwmax == 4);
    assert!(w.iter().all(|s| v.iter().any(|t| t.0 <= s.0 && s.1 <= t.1))); // each W_k sits inside some V
    // Nagata-Smirnov layers on the line: layer j holds ((m-1)/2^j, (m+1)/2^j) for every whole m
    let g2: Vec<Q> = (-480..=480).map(|i| q(i, 160)).collect();
    for j in [0u32, 3, 6] {
        let p = 1i64 << j;
        let cnt = |x: Q, t: Q| { let s = x * z(p); (s.floor() - 3..s.floor() + 4).filter(|&m| (s - z(m)).abs() < t).count() };
        let c1 = g2.iter().map(|&x| cnt(x, z(1))).max().unwrap();
        let c2 = g2.iter().map(|&x| cnt(x, q(3, 2))).max().unwrap();
        println!("layer {}: intervals of width {}; each point in at most {}, a window of radius 1/{} meets at most {}", j, q(2, p), c1, 2 * p, c2);
        assert!(c1 == 2 && c2 == 3);
    }
    let (j, a, b) = basic(x, q(1, 10));
    println!("basis at x=2.3, r=0.1: layer {}, interval ({}, {}) = ({}, {})", j, a, b, a.f(), b.f());
    assert!(a < x && x < b && x - q(1, 10) <= a && b <= x + q(1, 10));
    assert!(g2.iter().all(|&y| [half, q(1, 10), q(1, 100)].iter().all(|&r| { let (_, a, b) = basic(y, r); a < y && y < b && y - r <= a && b <= y + r })));
    println!("basis check: a layer set fits inside every ball tested, {} points x 3 radii", g2.len());
    // what breaks
    println!("no normalising: psi_2 + psi_3 at 2.3 = {}, so sum psi*h = {:.1} m, not {:.3} m", big_psi(x), glue(x, psi).f(), glue(x, phi).f());
    assert!(glue(x, psi) == z(260));
    let sup: Vec<Q> = grid.iter().cloned().filter(|&y| tent(y, 2) > z(0)).collect(); // tent 2 is nonzero on (1, 3)
    let ends = (sup[0] - q(1, 20), *sup.last().unwrap() + q(1, 20));
    let ins = |e: Q| if z(1) < e && e < z(3) { "True" } else { "False" };
    println!("open cover (n-1,n+1): support of phi_2 is [{}, {}]; ends inside U_2=(1,3): [{}, {}]", ends.0, ends.1, ins(ends.0), ins(ends.1));
    assert!(ends.0 == z(1) && ends.1 == z(3) && ins(ends.0) == "False" && ins(ends.1) == "False" && (ends.0 - z(2)).abs() < q(3, 2));
    let bars: Vec<String> = (0..H.len() as i64).map(|n| format!("U_{}=({}, {})", n, z(n) - q(3, 2), z(n) + q(3, 2))).collect();
    println!("figure, bars {}; tents peak at (n, 1) for n = 0..{}; at x={} dots {} and {}", bars.join(" "), H.len() - 1, x.f(), tent(x, 2).f(), tent(x, 3).f());
    println!("ALL CHECKS PASS");
}
