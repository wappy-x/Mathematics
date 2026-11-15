// Hausdorff and its ladder -- the same check as the Python, in Rust.  No crates.
// Part 1: the line with a doubled origin, where 1/n has two limits.  Part 2: the
// circle in the plane, split by two discs of radius half the gap.  Part 3: two
// closed sets of the line with no fixed gap, split by "nearer to which".  Part 4:
// the K-topology, Hausdorff but not regular.  Part 5: every topology on 3 and 4
// points, sorted onto the ladder; that part is exhaustive, so it is a proof.
// Fractions are (top, bottom) pairs of i128, bottom positive, kept in lowest terms.
type Q = (i128, i128);

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(p: i128, d: i128) -> Q { let g = gcd(p, d).max(1); (p / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { add(a, (-b.0, b.1)) }
fn lt(a: Q, b: Q) -> bool { a.0 * b.1 < b.0 * a.1 }
fn abs(a: Q) -> Q { (a.0.abs(), a.1) }
fn show(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn isqrt(n: i128) -> i128 {                         // largest whole r with r * r <= n
    let (mut lo, mut hi) = (0i128, n + 1);
    while hi - lo > 1 { let mid = (lo + hi) / 2; if mid * mid <= n { lo = mid } else { hi = mid } }
    lo
}
fn dist(x: Q, pts: &[Q]) -> Q {
    pts.iter().map(|&p| abs(sub(x, p))).reduce(|m, d| if lt(d, m) { d } else { m }).unwrap()
}
fn popcount(x: u32) -> u32 { x.count_ones() }
type P = Option<Q>;                                 // a point: Some(real number), or None for the twin 0'
const ZERO: P = Some((0, 1));
const TWIN: P = None;
fn band(c: P, r: Q, z: P) -> bool {                 // is z in the band of radius r round c, 0 or 0'?
    z == c || matches!(z, Some(x) if x.0 != 0 && lt(abs(x), r))
}

fn census(n: usize) -> [u32; 9] {                   // tops T0 T1 T2 reg nor regc norc uniq
    let full: u32 = (1 << n) - 1;
    let masks: Vec<u32> = (1..full).collect();
    let mut st = [0u32; 9];
    for pick in 0u32..(1 << masks.len()) {
        let mut fam = vec![0, full];
        for (k, &m) in masks.iter().enumerate() { if pick >> k & 1 == 1 { fam.push(m) } }
        if fam.iter().any(|&u| fam.iter().any(|&v| !fam.contains(&(u | v)) || !fam.contains(&(u & v)))) { continue }
        let small = |s: u32| *fam.iter().filter(|&&u| u & s == s).min_by_key(|&&u| popcount(u)).unwrap();
        let pts: Vec<u32> = (0..n).map(|i| 1u32 << i).collect();
        let closed: Vec<u32> = fam.iter().map(|&u| full ^ u).collect();
        let pairs: Vec<(u32, u32)> = (0..n).flat_map(|i| (i + 1..n).map(move |j| (1u32 << i, 1u32 << j))).collect();
        let t0 = pairs.iter().all(|&(x, y)| small(x) != small(y));
        let t1 = pts.iter().all(|&x| pts.iter().all(|&y| x == y || small(x) & y == 0));
        let t2 = pairs.iter().all(|&(x, y)| small(x) & small(y) == 0);
        let regc = closed.iter().all(|&c| c == 0 || pts.iter().all(|&x| x & c != 0 || small(x) & small(c) == 0));
        let norc = closed.iter().all(|&c| closed.iter().all(|&d| c == 0 || d == 0 || c & d != 0 || small(c) & small(d) == 0));
        let uniq = (1..=full).all(|s| pts.iter().filter(|&&y| small(y) & s == s).count() <= 1);
        for (k, v) in [true, t0, t1, t2, t1 && regc, t1 && norc, regc, norc, uniq].iter().enumerate() {
            if *v { st[k] += 1 }
        }
    }
    st
}
fn preorders(n: usize) -> (u32, u32, u32) {         // second road: relations x <= y
    let pairs: Vec<(usize, usize)> = (0..n).flat_map(|i| (0..n).filter(move |&j| j != i).map(move |j| (i, j))).collect();
    let (mut tot, mut anti, mut sym) = (0, 0, 0);
    for bits in 0u32..(1 << pairs.len()) {
        let mut r = vec![vec![false; n]; n];
        for i in 0..n { r[i][i] = true }
        for (k, &(i, j)) in pairs.iter().enumerate() { if bits >> k & 1 == 1 { r[i][j] = true } }
        let trans = (0..n).all(|a| (0..n).all(|b| (0..n).all(|d| !(r[a][b] && r[b][d]) || r[a][d])));
        if !trans { continue }
        tot += 1;
        if (0..n).all(|a| (0..n).all(|b| a == b || !(r[a][b] && r[b][a]))) { anti += 1 }
        if (0..n).all(|a| (0..n).all(|b| r[a][b] == r[b][a])) { sym += 1 }
    }
    (tot, anti, sym)
}
fn bell(n: usize) -> u32 {                          // third road: the Bell triangle
    let mut row = vec![1u32];
    for _ in 0..n - 1 {
        let mut nxt = vec![*row.last().unwrap()];
        for &v in &row { let l = *nxt.last().unwrap(); nxt.push(l + v) }
        row = nxt;
    }
    *row.last().unwrap()
}

fn main() {
    println!("Part 1: the line with a doubled origin: every real number, plus a twin 0' of 0");
    println!("near 0: the band (-r, r); near 0': the same band with 0 swapped for 0'");
    for k in [10i128, 100, 1000] {
        let r = q(1, k);
        let formula = r.1 / r.0;                    // whole part of 1/r: n > 1/r gives 1/n < r
        let search = (1i128..10000).find(|&nn| (nn + 1..nn + 3 * k).all(|n| lt((1, n), r))).unwrap();
        let both = (formula + 1..formula + 3 * k).all(|n| band(ZERO, r, Some((1, n))) && band(TWIN, r, Some((1, n))));
        println!("  tolerance 1/{}: cutoff {} by formula, {} by search; later shares 1/n lie in both bands: {}",
                 k, formula, search, yn(both));
        assert!(formula == search && search == k && both);
    }
    let radii: Vec<Q> = (1i128..51).map(|a| (1, a)).collect();
    let half_min = |r: Q, s: Q| -> P { let m = if lt(r, s) { r } else { s }; Some(q(m.0, 2 * m.1)) };
    let meet = radii.iter().all(|&r| radii.iter().all(|&s| band(ZERO, r, half_min(r, s)) && band(TWIN, s, half_min(r, s))));
    let apart = radii.iter().all(|&r| !band(ZERO, r, TWIN) && !band(TWIN, r, ZERO));
    println!("bands round 0 and 0' of radius r and s share the point min(r, s)/2: checked on 2500 pairs: {}", yn(meet));
    println!("  radius 1/10 round 0 and 1/1000 round 0': shared point {}", show(half_min((1, 10), (1, 1000)).unwrap()));
    println!("so 1/n converges to 0 and to 0': two limits; yet each band round one twin misses the other (T1): {}", yn(apart));
    assert!(meet && apart);

    println!("Part 2: the circle in the plane; P = (1, 0), Q = (3/5, 4/5)");
    let (p, qq) = ((50i128, 0i128), (30i128, 40i128)); // in fiftieths
    let gap2 = (p.0 - qq.0).pow(2) + (p.1 - qq.1).pow(2);   // in 1/2500 units
    println!("  gap squared {}; gap 0.{}...; half the gap 0.{}...", show(q(gap2, 2500)), isqrt(8 * 10i128.pow(7)), isqrt(2 * 10i128.pow(7)));
    let shared = |rad2: i128| -> (u32, u32) {     // grid points in both discs, steps of 1/50
        let (mut both, mut in_p) = (0, 0);
        for i in -50i128..101 { for j in -50i128..101 {
            let a = (i - p.0).pow(2) + (j - p.1).pow(2) < rad2;
            let b = (i - qq.0).pow(2) + (j - qq.1).pow(2) < rad2;
            if a && b { both += 1 }
            if a { in_p += 1 }
        } }
        (both, in_p)
    };
    let (none, in_p) = shared(gap2 / 4);
    let (many, _) = shared(gap2);
    println!("  discs of radius half the gap: {} grid points in the disc round P, {} in both", in_p, none);
    println!("  mistake, discs of radius the whole gap: {} grid points in both", many);
    assert!(gap2 == 2000 && none == 0 && in_p > 0 && many > 0);
    let u = |k: i128| 4 * k < 1000 || 4 * k > 3000;         // the circle glued from [0, 1], in thousandths
    let v = |k: i128| 1000 < 4 * k && 4 * k < 3000;
    let glued = u(0) && u(1000) && v(500) && !(0i128..1001).any(|k| u(k) && v(k));
    println!("  [0, 1] with its ends glued: [0, 1/4) and (3/4, 1] hold both ends, (1/4, 3/4) holds 1/2; no shared point among {}: {}", 1001, yn(glued));
    assert!(glued);

    println!("Part 3: C = the whole numbers 2, 3, 4, ...; D = n + 1/n beside each; both closed");
    let cs: Vec<Q> = (2i128..202).map(|n| (n, 1)).collect();
    let ds: Vec<Q> = (2i128..202).map(|n| q(n * n + 1, n)).collect();
    for n in [2i128, 3, 10, 100] {
        let (mut lo, mut hi) = ((n, 1), q(n * n + 1, n));   // bisect for where nearer-to-C stops
        for _ in 0..40 {                                    // width 1/n halved 40 times
            let mid = q(lo.0 * hi.1 + hi.0 * lo.1, 2 * lo.1 * hi.1);
            if lt(dist(mid, &cs), dist(mid, &ds)) { lo = mid } else { hi = mid }
        }
        let switch = q(2 * n * n + 1, 2 * n);
        let close = lt(abs(sub(lo, switch)), (1, 10i128.pow(12)));
        println!("  n = {}: gap 1/{}; nearer-to-C ends at {} by formula; bisection within 10^-12: {}", n, n, show(switch), yn(close));
        assert!(close);
    }
    let w = 100i128;                                     // buffer width 1/w
    let first = (2i128..10000).find(|&n| lt(sub(q(n * n + 1, n), (1, w)), add((n, 1), (1, w)))).unwrap();
    println!("mistake, a fixed buffer of width 1/{} round both sets: buffers first overlap at n = {} (formula {})", w, first, w / 2 + 1);
    assert!(first == w / 2 + 1 && first == 51);

    println!("Part 4: the K-topology; K = {{1/n}}; basic open sets: bands, and bands with K removed");
    for e in [1000i128, 1000000] {
        let x = sub((1, 11), (1, 2 * e));
        let ok = lt(abs(x), (1, 10)) && lt(abs(sub(x, (1, 11))), (1, e)) && x.0 != 1;
        println!("  band (-1/10, 1/10) minus K round 0, band of radius 1/{} round 1/11 in K: share {}, not in K: {}", e, show(x), yn(ok));
        assert!(ok);
    }

    println!("Part 5: every topology on a 3-point and a 4-point set, sorted onto the ladder");
    for n in [3usize, 4] {
        let s = census(n);
        let (tot, anti, sym) = preorders(n);
        println!("{} points: topologies {} (preorders {}); T0 {} (partial orders {}); T1 {}; Hausdorff {}; regular {}; normal {}",
                 n, s[0], tot, s[1], anti, s[2], s[3], s[4], s[5]);
        println!("  every sequence has at most one limit: {}; regular condition alone {} (equivalence relations {}, Bell number {}); normal condition alone {}",
                 s[8], s[6], sym, bell(n), s[7]);
        assert!(s[0] == tot && s[1] == anti && s[6] == sym && sym == bell(n));
        assert!(s[2..6].iter().chain([s[8]].iter()).all(|&v| v == 1));
    }
    println!("ALL CHECKS PASS");
}
