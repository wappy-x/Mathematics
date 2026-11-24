// The Sylow theorems -- the same check as the Python, in Rust.  No crates.
// The rules (n_p is 1 more than a multiple of p and divides the rest) are set
// against brute force: every subgroup of S4 (shuffle s sends corner i to s[i]),
// every member of a 15-dial, and the 21 maps x -> a x + b on the 7-dial.
use std::collections::BTreeSet;
type P = [usize; 4];
type Sub = BTreeSet<P>;
const E: P = [0, 1, 2, 3];
fn mul(a: &P, b: &P) -> P { [a[b[0]], a[b[1]], a[b[2]], a[b[3]]] }     // b first, then a
fn inv(a: &P) -> P { let mut r = [0; 4]; for i in 0..4 { r[a[i]] = i } r }
fn conj(g: &P, h: &Sub) -> Sub { h.iter().map(|x| mul(&mul(g, x), &inv(g))).collect() }
fn span(gens: &[P]) -> Sub {                                         // close under combining
    let mut s: Sub = gens.iter().copied().chain([E]).collect();
    loop {
        let t: Sub = s.iter().flat_map(|x| s.iter().map(move |y| mul(x, y))).chain(s.iter().copied()).collect();
        if t == s { return s } s = t;
    }
}
fn split(n: usize, p: usize) -> (u32, usize) {                       // n = p^a x m, p not dividing m
    if n % p != 0 { (0, n) } else { let (a, m) = split(n / p, p); (a + 1, m) }
}
fn allowed(n: usize, p: usize) -> Vec<usize> {                       // what the counting rules leave
    let m = split(n, p).1;
    (1..=m).filter(|d| m % d == 0 && d % p == 1).collect()
}
fn choose(n: u64, k: u64) -> u64 { if k == 0 { 1 } else { choose(n, k - 1) * (n - k + 1) / k } }
fn order(f: (usize, usize)) -> usize {                               // f = (a, b) is x -> a x + b mod 7
    let (mut k, mut g) = (1, f);
    while g != (1, 0) { k += 1; g = (f.0 * g.0 % 7, (f.0 * g.1 + f.1) % 7) }
    k
}

fn main() {
    let g: Vec<P> = (0..256).map(|c| [c & 3, c >> 2 & 3, c >> 4 & 3, c >> 6]).filter(|s| (0..4).all(|i| s.contains(&i))).collect();
    let subs: BTreeSet<Sub> = g.iter().flat_map(|a| g.iter().map(move |b| span(&[*a, *b]))).collect();
    let of_size = |k: usize| -> Vec<Sub> { subs.iter().filter(|h| h.len() == k).cloned().collect() };
    let tile = span(&[[1, 2, 3, 0], [0, 3, 2, 1]]);                 // quarter turn and flip of the tile
    let c3 = span(&[[0, 2, 3, 1]]);                                 // corner 0 still, 1 -> 2 -> 3 -> 1
    let order15 = (0..15).filter(|k| (1..15).all(|j| j * k % 15 != 0)).count();
    let (n3, n5) = (allowed(15, 3)[0], allowed(15, 5)[0]);
    let known = 1 + (3 - 1) * n3 + (5 - 1) * n5;
    println!("order 15 = 3 x 5: n_3 may be {:?}, n_5 may be {:?}", allowed(15, 3), allowed(15, 5));
    println!("order 15: 1 identity + {} of order 3 + {} of order 5 = {}; left over {}", (3 - 1) * n3, (5 - 1) * n5, known, 15 - known);
    println!("members of order 15 on a 15-dial, by brute force: {}", order15);
    let prime = |n: usize| (2..n).all(|d| n % d != 0);
    let mut forced: Vec<usize> = (2..60).flat_map(|p| (p + 1..60).map(move |q| (p, q))).filter(|&(p, q)| prime(p) && prime(q) && p * q < 60 && allowed(p * q, p) == vec![1] && allowed(p * q, q) == vec![1]).map(|(p, q)| p * q).collect();
    forced.sort();
    println!("orders p x q under 60 where both counts are forced to 1: {:?}", forced);
    println!("order 24 = 2^3 x 3: n_2 may be {:?}, n_3 may be {:?}", allowed(24, 2), allowed(24, 3));
    println!("S4 by brute force: {} subgroups; size 8: {}; size 3: {}", subs.len(), of_size(8).len(), of_size(3).len());
    let ct: BTreeSet<Sub> = g.iter().map(|x| conj(x, &tile)).collect();
    let cc: BTreeSet<Sub> = g.iter().map(|x| conj(x, &c3)).collect();
    let nt = g.iter().filter(|x| conj(x, &tile) == tile).count();
    let n_3 = g.iter().filter(|x| conj(x, &c3) == c3).count();
    let orbits: BTreeSet<BTreeSet<Sub>> = ct.iter().map(|q| tile.iter().map(|t| conj(t, q)).collect()).collect();
    let mut orbs: Vec<usize> = orbits.iter().map(|o| o.len()).collect(); orbs.sort();
    println!("conjugates of the tile's 8 ways: {}, which the tile's ways sort into orbits of sizes {:?}; of one size-3 subgroup: {}", ct.len(), orbs, cc.len());
    println!("normalisers: sizes {} and {}, so 24 / {} = {} and 24 / {} = {}", nt, n_3, nt, 24 / nt, n_3, 24 / n_3);
    println!("the tile's 8 ways are one of the size-8 subgroups: {}", if subs.contains(&tile) { "yes" } else { "no" });
    for (n, p) in [(24u64, 2u64), (15, 3), (15, 5)] {
        let (a, m) = split(n as usize, p as usize);
        let c = choose(n, p.pow(a));
        println!("subsets of size {} from {}: C({}, {}) = {}, leaves {} on dividing by {}; m = {} leaves {}", p.pow(a), n, n, p.pow(a), c, c % p, p, m, m as u64 % p);
        assert!(c % p == m as u64 % p);
    }
    println!("mistake 1, divides only: n_3 for order 15 may be {:?}", (1..6).filter(|d| 5 % d == 0).collect::<Vec<usize>>());
    let classes: BTreeSet<BTreeSet<Sub>> = of_size(4).iter().map(|h| g.iter().map(|x| conj(x, h)).collect()).collect();
    println!("mistake 2, size 4 is not the largest power of 2: {} subgroups in {} conjugacy classes", of_size(4).len(), classes.len());
    let even: Sub = g.iter().copied().filter(|s| (0..4).flat_map(|i| (i + 1..4).map(move |j| (i, j))).filter(|&(i, j)| s[i] > s[j]).count() % 2 == 0).collect();
    println!("mistake 3, A4 has order 12 but size-6 subgroups: {}", of_size(6).iter().filter(|h| h.is_subset(&even)).count());
    let ords: Vec<usize> = [1, 2, 4].iter().flat_map(|&a| (0..7).map(move |b| order((a, b)))).collect();
    let n21 = ords.iter().filter(|&&o| o == 3).count() / 2;
    println!("mistake 4, order 21: n_3 may be {:?}; the 21 maps x -> a x + b mod 7 have {} size-3 subgroups, largest order {}", allowed(21, 3), n21, ords.iter().max().unwrap());
    assert!(allowed(15, 3) == vec![1] && allowed(15, 5) == vec![1] && order15 == 15 - known);
    assert!(of_size(8).len() == ct.len() && ct.len() == 24 / nt && allowed(24, 2).contains(&ct.len()));
    assert!(of_size(3).len() == cc.len() && cc.len() == 24 / n_3 && allowed(24, 3).contains(&cc.len()));
    assert!(orbs == vec![1, 2] && subs.len() == 30 && of_size(8).into_iter().collect::<BTreeSet<Sub>>() == ct && of_size(3).into_iter().collect::<BTreeSet<Sub>>() == cc);
    assert!(allowed(21, 3).contains(&n21) && *ords.iter().max().unwrap() < 21 && forced == vec![15, 33, 35, 51]);
    println!("ALL CHECKS PASS");
}
