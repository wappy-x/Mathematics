// The isomorphism theorems and the correspondence theorem -- the same check as the Python, in
// Rust.  No crates.  A group is its table: t[a][b] is a combined with b.  A set of members is a
// bit mask, and a pile (coset) is the mask of one member combined with every member of N.
type T = Vec<Vec<usize>>;
fn mask<I: IntoIterator<Item = usize>>(it: I) -> u64 { it.into_iter().fold(0, |m, i| m | 1 << i) }
fn mem(m: u64) -> Vec<usize> { (0..64).filter(|i| m >> i & 1 == 1).collect() }
fn size(m: u64) -> u32 { m.count_ones() }
fn prod(t: &T, a: u64, b: u64) -> u64 { mask(mem(a).iter().flat_map(|&x| mem(b).into_iter().map(move |y| t[x][y]))) }
fn is_sub(t: &T, s: u64) -> bool { s > 0 && prod(t, s, s) & !s == 0 }   // finite: closed is enough
fn subs(t: &T) -> Vec<u64> { (1..1u64 << t.len()).filter(|&s| is_sub(t, s)).collect() }
fn piles(t: &T, n: u64) -> Vec<u64> {   // each pile once, in order of first appearance
    (0..t.len()).map(|g| prod(t, 1 << g, n)).fold(Vec::new(), |mut p, c| { if !p.contains(&c) { p.push(c) } p })
}
fn quotient(t: &T, n: u64) -> (Vec<u64>, T) {   // a product that is not one whole pile panics
    let p = piles(t, n);
    let q = p.iter().map(|&a| p.iter().map(|&b| p.iter().position(|&c| c == prod(t, a, b)).unwrap()).collect()).collect();
    (p, q)
}
fn union(p: &[u64], m: u64) -> u64 { mem(m).iter().fold(0, |acc, &i| acc | p[i]) }
fn above(t: &T, n: u64) -> Vec<u64> { let p = piles(t, n); (1..1u64 << p.len()).filter(|&m| is_sub(t, union(&p, m))).collect() }
fn diamond(t: &T, h: u64, n: u64) -> (u32, u32, usize, usize, bool) {
    let (hn, ov) = (prod(t, h, n), h & n);
    let pairs = uniq(mem(h).iter().map(|&x| prod(t, 1 << x, ov) << 32 | prod(t, 1 << x, n)).collect());
    let (l, r) = (uniq(pairs.iter().map(|p| p >> 32).collect()), uniq(pairs.iter().map(|p| p & 0xffff_ffff).collect()));
    let all = uniq(mem(hn).iter().map(|&g| prod(t, 1 << g, n)).collect());
    (size(hn), size(ov), r.len(), l.len(), pairs.len() == l.len() && l.len() == r.len() && r == all)
}
fn pile(p: &[u64], x: usize) -> Vec<usize> { mem(*p.iter().find(|&&q| q >> x & 1 == 1).unwrap()) }   // the pile holding x
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn sorted(v: &[u64]) -> Vec<u64> { let mut w = v.to_vec(); w.sort(); w }
fn uniq(v: Vec<u64>) -> Vec<u64> { let mut w = sorted(&v); w.dedup(); w }
fn main() {
    let clock = |n: usize| -> T { (0..n).map(|a| (0..n).map(|b| (a + b) % n).collect()).collect() };
    let (z24, z12) = (clock(24), clock(12));
    let m: Vec<(i32, i32)> = (0..2).flat_map(|f| (0..4).map(move |r| (r, f))).collect();
    let d4: T = m.iter().map(|a| m.iter().map(|b| m.iter().position(|&c| c ==
        ((a.0 + if a.1 == 1 { -b.0 } else { b.0 }).rem_euclid(4), a.1 ^ b.1)).unwrap()).collect()).collect();
    let (k, n4, h6) = (mask([0, 12]), mask((0..24).step_by(4)), mask((0..24).step_by(6)));
    let ((p1, q1), (p3, q3)) = (quotient(&z24, k), quotient(&z24, n4));
    let nk = mask((0..p1.len()).filter(|&i| p1[i] & !n4 == 0));     // the piles inside N: N over K
    let (p2, q2) = quotient(&q1, nk);
    let unpack: Vec<u64> = p2.iter().map(|&a| union(&p1, a)).collect();
    let u: Vec<usize> = unpack.iter().map(|x| p3.iter().position(|y| y == x).unwrap_or(99)).collect();
    let keeps = (0..p2.len()).all(|a| (0..p2.len()).all(|b| u[a] < 99 && u[b] < 99 && u[q2[a][b]] == q3[u[a]][u[b]]));
    let nk_low: Vec<usize> = mem(nk).iter().map(|&i| mem(p1[i])[0]).collect();
    println!("24-hour clock by {:?}: {} piles; those by {:?}: {}; at once by the {} multiples of 4: {}", mem(k), p1.len(), nk_low, p2.len(), size(n4), p3.len());
    println!("N over K: {:?}; 22:00 is in {:?}, which lies in {:?}", mem(nk).iter().map(|&i| mem(p1[i])).collect::<Vec<_>>(), pile(&p1, 22), pile(&p3, 22));
    println!("22:00 reads {}, then {}; at once {}. Two-stage piles unpack to one-stage piles {}, sums kept on {} pairs {}", pile(&p1, 22)[0], pile(&unpack, 22)[0], pile(&p3, 22)[0], tf(sorted(&unpack) == sorted(&p3)), p2.len() * p2.len(), tf(keeps));
    let (dz, dt) = (diamond(&z24, h6, n4), diamond(&d4, mask([0, 4]), mask(0..4)));
    println!("diamond on the clock: H = multiples of 6 ({}), N = multiples of 4 ({}), overlap {}, H + N {} = {} x {} / {}", size(h6), size(n4), dz.1, dz.0, size(h6), size(n4), dz.1);
    println!("  H + N over N: {} piles; H over the overlap: {} piles; matched one to one and onto {}", dz.2, dz.3, tf(dz.4));
    println!("diamond on the tile: H = [r0, r0f], N = the 4 turns, overlap {}, HN {} = {} x {} / {} moves; piles {} and {}, matched {}", dt.1, dt.0, size(mask([0, 4])), size(mask(0..4)), dt.1, dt.2, dt.3, tf(dt.4));
    let (s12, a24, divs): (Vec<u64>, Vec<u64>, Vec<usize>) = (subs(&z12), above(&z24, k), (1..13).filter(|d| 12 % d == 0).collect());
    let mult = sorted(&divs.iter().map(|&d| mask((0..12).step_by(d))).collect::<Vec<u64>>());
    let up = sorted(&a24.iter().map(|&m| mask(mem(union(&p1, m)).into_iter().map(|x| x % 12))).collect::<Vec<u64>>());
    let mut sizes: Vec<u32> = s12.iter().map(|&s| size(s)).collect(); sizes.sort();
    println!("subgroups of the 12-hour clock, brute force over {} subsets: {}, sizes {:?}", 1 << 12, s12.len(), sizes);
    println!("  the multiples of each d in {:?}: the same {} sets {}", divs, divs.len(), tf(s12 == mult));
    println!("  subgroups of the 24-hour clock containing {:?}: {}; read mod 12 they are those {}; pile for pile {}", mem(k), a24.len(), tf(up == s12), tf(a24 == subs(&q1)));
    let (sd4, inv): (Vec<u64>, Vec<usize>) = (subs(&d4), d4.iter().map(|row| row.iter().position(|&x| x == 0).unwrap()).collect());
    let normal: Vec<u64> = sd4.iter().cloned().filter(|&s| (0..8).all(|g| prod(&d4, prod(&d4, 1 << g, s), 1 << inv[g]) == s)).collect();
    println!("tile: {} subgroups, {} of them normal", sd4.len(), normal.len());
    let names = ["r0", "r1", "r2", "r3", "r0f", "r1f", "r2f", "r3f"];
    let mut rows: Vec<(usize, usize, bool)> = Vec::new();
    for &n in &normal {
        let (p, q) = quotient(&d4, n); let sq = subs(&q);
        rows.push((sq.len(), sd4.iter().filter(|&&s| s & n == n).count(), above(&d4, n) == sq));
        let (nm, r) = (mem(n).iter().map(|&i| names[i]).collect::<Vec<_>>().join(", "), rows.last().unwrap());
        println!("  by [{}]: piles {}, subgroups of the quotient {}, tile subgroups containing it {}, matched {}", nm, p.len(), r.0, r.1, tf(r.2));
    }
    let (bad, st) = (mask([0, 4, 8]), prod(&d4, mask([0, 4]), mask([0, 5])));
    let copies = uniq((0..24).map(|g| prod(&z24, 1 << g, bad)).collect()).len();
    println!("mistakes: {:?} in the 24-hour clock is a subgroup {}, {} copies x 3 = {} slots for 24; H + N as {} x {} = {}", mem(bad), tf(is_sub(&z24, bad)), copies, copies * 3, size(h6), size(n4), size(h6) * size(n4));
    println!("  every tile subgroup counted for the quotient by [r0, r2]: {}, not {}; [r0, r0f] times [r0, r1f]: {} moves, a subgroup {}", sd4.len(), rows[1].0, size(st), tf(is_sub(&d4, st)));
    assert!(sorted(&unpack) == sorted(&p3) && p1.len() == 12 && p2.len() == 4 && p3.len() == 4 && keeps);
    assert!(dz.0 * dz.1 == size(h6) * size(n4) && (dz.2, dz.3, dz.4) == (2, 2, true) && dt == (8, 1, 2, 2, true));
    assert!(s12 == mult && s12.len() == 6 && up == s12 && a24 == subs(&q1));
    assert!(sd4.len() == 10 && rows.iter().map(|r| (r.0, r.1)).collect::<Vec<_>>() == vec![(10, 10), (5, 5), (2, 2), (2, 2), (2, 2), (1, 1)] && rows.iter().all(|r| r.2));
    println!("ALL CHECKS PASS");
}
