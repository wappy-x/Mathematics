// Closure, interior and boundary -- the same check as the Python, in Rust.  No
// crates.  Part 1 has no distances: the circle squeezed to four points, top,
// bottom, east and west, with seven open sets.  All 16 subsets are tested, so
// every identity printed there is proved for that space.  Part 2 finds fractions
// in shrinking bands around root 2, exactly, two ways; it illustrates the proof.
// A set of points is a 4-bit mask: top 1, bottom 2, east 4, west 8.
const X: [&str; 4] = ["top", "bottom", "east", "west"];
const EVERY: u8 = 15;
const OPEN: [u8; 7] = [0, 1, 2, 3, 7, 11, 15];

fn show(s: u8) -> String {
    let names: Vec<&str> = (0..4).filter(|i| s & (1 << i) != 0).map(|i| X[i]).collect();
    format!("{{{}}}", names.join(", "))
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn dec(n: i128, k: u32) -> String {                // the whole number n / 10^k, exactly
    let p = 10i128.pow(k);
    format!("{}.{:0w$}", n / p, n % p, w = k as usize)
}
fn interior(a: u8, opens: &[u8]) -> u8 {          // union of the open sets inside a
    opens.iter().filter(|&&u| u & !a == 0).fold(0, |acc, &u| acc | u)
}
fn closure_closed(a: u8, opens: &[u8]) -> u8 {    // road 1: meet of closed sets holding a
    opens.iter().map(|&u| EVERY & !u).filter(|&c| a & !c == 0).fold(EVERY, |acc, c| acc & c)
}
fn closure_touch(a: u8, opens: &[u8]) -> u8 {     // road 2: every open set round x meets a
    (0..4).filter(|&i| opens.iter().all(|&u| u & (1 << i) == 0 || u & a != 0)).fold(0, |acc, i| acc | (1 << i))
}
fn closure_swap(a: u8, opens: &[u8]) -> u8 {      // road 3: the rest of the rest's interior
    EVERY & !interior(EVERY & !a, opens)
}
fn limit_points(a: u8, opens: &[u8]) -> u8 {      // meets a somewhere other than x itself
    (0..4).filter(|&i| opens.iter().all(|&u| u & (1 << i) == 0 || u & a & !(1u8 << i) != 0))
        .fold(0, |acc, i| acc | (1 << i))
}
fn boundary(a: u8, opens: &[u8]) -> u8 { closure_touch(a, opens) & !interior(a, opens) }

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(p: i128, q: i128) -> String { let g = gcd(p, q); format!("{}/{}", p / g, q / g) }
fn isqrt(n: i128) -> i128 {                        // largest whole r with r * r <= n
    let (mut lo, mut hi) = (0i128, (n + 1).min(1i128 << 62));      // keeps mid * mid in range
    while hi - lo > 1 {
        let mid = (lo + hi) / 2;
        if mid * mid <= n { lo = mid } else { hi = mid }
    }
    lo
}
// A band is (lo/d, (lo+1)/d) with d = 10^k.  p/q lies inside when lo*q < p*d < (lo+1)*q.
fn inside(p: i128, q: i128, lo: i128, d: i128) -> bool { lo * q < p * d && p * d < (lo + 1) * q }
fn archimedes(lo: i128, d: i128) -> (i128, i128) { // n past 1/(t - s), then step past s
    let n = d + 1;
    (n * lo / d + 1, n)
}
fn simplest(lo: i128, d: i128) -> (i128, i128) {   // Stern-Brocot: mediants, smallest bottom
    let (mut p1, mut q1, mut p2, mut q2) = (0i128, 1i128, 1i128, 0i128);
    loop {
        let (p, q) = (p1 + p2, q1 + q2);
        if p * d <= lo * q { p1 = p; q1 = q }
        else if p * d >= (lo + 1) * q { p2 = p; q2 = q }
        else { return (p, q) }
    }
}

fn main() {
    let all: Vec<u8> = {
        let mut v: Vec<u8> = (0..16).collect();
        v.sort_by_key(|&s| (s.count_ones(), (0..4).map(|i| 1 - (s >> i & 1)).collect::<Vec<u8>>()));
        v
    };
    let unions = (0..128u32).all(|f| OPEN.contains(&(0..7).filter(|j| f >> j & 1 == 1).fold(0, |acc, j| acc | OPEN[j])));
    let overlaps = OPEN.iter().all(|&u| OPEN.iter().all(|&v| OPEN.contains(&(u & v))));
    let top: u8 = 1;
    println!("Part 1: the circle squeezed to four points: top, bottom, east, west");
    println!("open sets: {}", OPEN.iter().map(|&u| show(u)).collect::<Vec<_>>().join(", "));
    let glued: Vec<u8> = (0..16u8).filter(|&a| a & 12 == 0 || a & 3 == 3).collect();   // quotient rule
    println!("open sets by the gluing rule, east or west only with top and bottom: {}; same family: {}", glued.len(), yn(glued == OPEN));
    println!("every union and every overlap of open sets is open: {}", yn(unions && overlaps));
    println!("A = {{top}}, the open upper arc");
    println!("  interior {}; closure {}; boundary {}; limit points {}", show(interior(top, &OPEN)),
             show(closure_touch(top, &OPEN)), show(boundary(top, &OPEN)), show(limit_points(top, &OPEN)));
    let seq_limits = (0..4).filter(|&i| OPEN.iter().all(|&u| u & (1 << i) == 0 || u & top != 0)).fold(0u8, |a, i| a | (1 << i));
    println!("  the sequence top, top, top, ... converges to {}", show(seq_limits));
    let three = all.iter().all(|&a| closure_closed(a, &OPEN) == closure_touch(a, &OPEN) && closure_touch(a, &OPEN) == closure_swap(a, &OPEN));
    let plus = all.iter().all(|&a| closure_touch(a, &OPEN) == a | limit_points(a, &OPEN));
    let edge = all.iter().all(|&a| boundary(a, &OPEN) == closure_touch(a, &OPEN) & closure_touch(EVERY & !a, &OPEN));
    let dense: Vec<u8> = all.iter().copied().filter(|&a| closure_touch(a, &OPEN) == EVERY).collect();
    println!("all {} subsets: the three roads to the closure agree: {}", all.len(), yn(three));
    println!("all {} subsets: closure = the set plus its limit points: {}", all.len(), yn(plus));
    println!("all {} subsets: boundary = closure of the set, met with closure of the rest: {}", all.len(), yn(edge));
    println!("dense subsets: {} of {}: {}", dense.len(), all.len(), dense.iter().map(|&a| show(a)).collect::<Vec<_>>().join(", "));
    let te: u8 = 5;
    let (indiscrete, discrete): ([u8; 2], Vec<u8>) = ([0, EVERY], (0..16).collect());
    println!("mistake 1, boundary of {{top}} as the set minus its interior: {}", show(top & !interior(top, &OPEN)));
    println!("mistake 2, A = {{top, east}}: closure of the interior {}, interior of the closure {}",
             show(closure_touch(interior(te, &OPEN), &OPEN)), show(interior(closure_touch(te, &OPEN), &OPEN)));
    println!("mistake 3, closure of {{top}}: indiscrete {}, discrete {}",
             show(closure_touch(top, &indiscrete)), show(closure_touch(top, &discrete)));
    // (3/5, 4/5) times 2001/2000: x^2 + y^2 = (9 + 16)/25 * 2001^2 / 2000^2
    let (num, den) = ((9 + 16) * 2001i128 * 2001, 25 * 2000i128 * 2000);
    println!("mistake 4, the circle inside the plane: (3/5, 4/5) pushed out by 1/2000 has x^2 + y^2 = {} = {}, off the circle",
             frac(num, den), dec(num * 100_000_000 / den, 8));
    println!("Part 2: bands around root 2, the diagonal of a 1-metre tile, in metres");
    for k in [3u32, 6, 9, 12] {
        let d = 10i128.pow(k);
        let lo = isqrt(2 * d * d);
        let (am, an) = archimedes(lo, d);
        let (bp, bq) = simplest(lo, d);
        let root_in = lo * lo < 2 * d * d && 2 * d * d < (lo + 1) * (lo + 1);
        println!("width 10^-{}: ({}, {}); root 2 inside: {}; Archimedes {}; simplest {}",
                 k, dec(lo, k), dec(lo + 1, k), yn(root_in), frac(am, an), frac(bp, bq));
        assert!(inside(am, an, lo, d) && inside(bp, bq, lo, d) && root_in);   // in the band
        assert!(bq <= an);                                                    // simplest is smallest
        if k == 3 {
            let none = (1..bq).all(|q| (0..=2 * q).all(|p| !inside(p, q, lo, d)));
            println!("  checked: no fraction with bottom below {} lies in this band: {}", bq, yn(none));
            assert!(none);                                                    // brute force agrees
            println!("  a non-fraction in it: 1.414 + 0.001/root 2 = 1.414{}...", isqrt(100_000_000 / 2));
        }
    }
    assert!(glued == OPEN && unions && overlaps && three && plus && edge);
    assert!(closure_touch(top, &OPEN) == 13 && interior(top, &OPEN) == top);
    assert!(limit_points(top, &OPEN) == 12);                             // top is not its own limit
    assert!(dense.len() == 4 && closure_touch(top, &indiscrete) == EVERY && num != den);
    println!("figure, circle centre (0, 0) radius 1; east (1, 0); west (-1, 0); top arc y > 0; bottom arc y < 0");
    println!("ALL CHECKS PASS");
}
