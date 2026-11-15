// Compactness and Tychonoff -- the same check as the Python, in Rust.  No crates.
// A point of the circle is a fraction of a turn, from 0 (the glue point) up to
// 1, so every test is exact.  Part 1 finds the smallest finite subcover of one
// cover of the circle three ways.  Part 2 removes the glue point and watches
// that fail.  Part 3 tests the infinite cube of dials on 20 coordinates: it
// illustrates, it does not prove.  Part 4 checks the finite cases of Zorn's
// lemma and of Kelley's step on every case, so those finite cases are proved.
use std::cmp::Ordering;

#[derive(Clone, Copy, Debug)]
struct Fr { p: i64, q: i64 }                       // p/q in lowest terms, q > 0
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(p: i64, q: i64) -> Fr { let g = gcd(p, q).max(1) * q.signum(); Fr { p: p / g, q: q / g } }
impl PartialEq for Fr { fn eq(&self, o: &Fr) -> bool { self.p * o.q == o.p * self.q } }
impl Eq for Fr {}
impl PartialOrd for Fr { fn partial_cmp(&self, o: &Fr) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Fr { fn cmp(&self, o: &Fr) -> Ordering { (self.p * o.q).cmp(&(o.p * self.q)) } }
fn add(a: Fr, b: Fr) -> Fr { fr(a.p * b.q + b.p * a.q, a.q * b.q) }
fn sub(a: Fr, b: Fr) -> Fr { fr(a.p * b.q - b.p * a.q, a.q * b.q) }
fn show(a: Fr) -> String { if a.q == 1 { format!("{}", a.p) } else { format!("{}/{}", a.p, a.q) } }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn arc(n: i64) -> (Fr, Fr) {                       // U_0 round the glue point; U_n for n >= 1
    if n == 0 { (fr(-1, 10), fr(1, 10)) } else { (fr(1, n + 2), fr(1, n)) }
}
fn inside(t: Fr, n: i64) -> bool {                 // is the point t, 0 <= t < 1, in U_n?
    let (a, b) = arc(n);
    let u = sub(t, fr(1, 1));                      // an arc may run past the glue point
    (a < t && t < b) || (a < u && u < b)
}
fn modone(e: Fr) -> Fr { fr(e.p.rem_euclid(e.q), e.q) }
fn covers(ns: &[i64]) -> bool {                    // test every arc end and every gap
    let mut ends: Vec<Fr> = ns.iter().flat_map(|&n| { let (a, b) = arc(n); vec![modone(a), modone(b)] }).collect();
    ends.push(fr(0, 1));
    ends.sort();
    ends.dedup();
    let mut tests = ends.clone();
    for i in 0..ends.len() {
        let next = if i + 1 < ends.len() { ends[i + 1] } else { add(ends[0], fr(1, 1)) };
        tests.push(modone(fr(ends[i].p * next.q + next.p * ends[i].q, 2 * ends[i].q * next.q)));
    }
    tests.iter().all(|&t| ns.iter().any(|&n| inside(t, n)))
}
fn names(ns: &[i64]) -> String { ns.iter().map(|n| format!("U_{}", n)).collect::<Vec<_>>().join(", ") }

fn main() {
    let pool: Vec<i64> = (0..14).collect();        // U_0 .. U_13; every later arc sits in (0, 1/14), inside U_0
    println!("Part 1: the circle in turns; U_0 = (-1/10, 1/10), U_n = (1/(n+2), 1/n)");
    let (mut reach, mut walk) = (arc(0).1, vec![0i64]);   // road 1: walk round from the glue point
    while reach <= add(fr(1, 1), arc(0).0) {
        let n = *pool.iter().filter(|&&m| inside(reach, m)).max_by_key(|&&m| arc(m).1).unwrap();
        walk.push(n);
        reach = arc(n).1;
    }
    println!("road 1, walk from the glue point: {} arcs: {}", walk.len(), names(&walk));
    let pick = |mask: u32| -> Vec<i64> { pool.iter().copied().filter(|&n| mask >> n & 1 == 1).collect() };
    let best = (1..15u32).find(|&k| (0..1u32 << 14).any(|s| s.count_ones() == k && covers(&pick(s)))).unwrap();
    let smallest: Vec<Vec<i64>> = (0..1u32 << 14).filter(|&s| s.count_ones() == best && covers(&pick(s))).map(pick).collect();
    println!("road 2, search U_0..U_13, smallest selections first: {} arcs; {} cover of that size: {}",
             best, smallest.len(), names(&smallest[0]));
    let mut witness = vec![fr(0, 1)];
    witness.extend((2..11).map(|k| fr(1, k)));
    let hits: Vec<usize> = witness.iter().map(|&t| pool.iter().filter(|&&n| inside(t, n)).count()).collect();
    println!("road 3, points 0, 1/2, 1/3, ..., 1/10: arcs holding each: {}",
             hits.iter().map(|h| h.to_string()).collect::<Vec<_>>().join(" "));
    let first_ten: Vec<i64> = (0..10).collect();
    println!("each needs its own arc, so at least {} arcs; U_0..U_9 cover: {}", witness.len(), yn(covers(&first_ten)));

    println!("Part 2: the glue point removed; U_1, U_2, U_3, ... still cover what is left");
    for big_n in [10i64, 100, 1000] {
        let miss = fr(1, big_n + 2);
        assert!(!(1..=big_n).any(|n| inside(miss, n)) && inside(miss, big_n + 1));
        println!("  U_1..U_{} miss the point {} turn = {} degrees; U_{} holds it",
                 big_n, show(miss), show(fr(360, big_n + 2)), big_n + 1);
    }
    let zero_left = !(1..=1000).any(|n| inside(fr(0, 1), n));
    let gone = (1..2000).find(|&n| inside(fr(1, 1000), n)).unwrap();
    println!("  leftover after U_1..U_n: the closed arc [0, 1/(n+2)]; 0 in none of U_1..U_1000: {}", yn(zero_left));
    println!("  with 0 removed, the leftovers lose the point 1/1000 at n = {}: no common point", gone);
    let open_gone = (1..2000i64).find(|&n| !(fr(0, 1) < fr(1, 1000) && fr(1, 1000) < fr(1, n))).unwrap();
    println!("mistake, open arcs (0, 1/n) in the whole circle: 0 in none; 1/1000 gone at n = {}", open_gone);

    println!("Part 3: the cube of dials [0, 1]^N, on its first 20 dials");
    let d = 20usize;
    let e = |n: usize| -> Vec<Fr> { (1..=d).map(|i| fr((i == n) as i64, 1)).collect() };
    let half = fr(1, 2);
    let mut near = Vec::new();
    for m in [3usize, 10] {
        let held: Vec<usize> = (1..=d).filter(|&n| e(n)[..m].iter().all(|&x| x < half)).collect();
        println!("  open set 'dials 1..{} below 1/2' round 0 holds e_n for {} of n = 1..{}, from n = {}",
                 m, held.len(), d, held[0]);
        near.push(held.len());
    }
    let in_box = (1..=d).filter(|&n| e(n).iter().all(|&x| x < half)).count();
    let mut sup = Vec::new();
    for a in 1..=d { for b in 1..=d { if a != b {
        sup.push(e(a).iter().zip(e(b).iter()).map(|(&x, &y)| if x > y { sub(x, y) } else { sub(y, x) }).max().unwrap());
    } } }
    sup.sort();
    sup.dedup();
    println!("mistake, box 'every dial below 1/2': holds e_n for {} of n = 1..{}", in_box, d);
    println!("mistake, largest-gap distance between e_m and e_n, m != n: always {}", show(sup[0]));
    let k = 8u32;                                  // box for pattern s: dial i in [0, 2/3) or (1/3, 1]
    let in_pattern = |c: u32, s: u32| (0..k).all(|i| {
        let x = fr((c >> i & 1) as i64, 1);
        if s >> i & 1 == 0 { x < fr(2, 3) } else { x > fr(1, 3) }
    });
    let mut per_corner: Vec<usize> = (0..1u32 << k).map(|c| (0..1u32 << k).filter(|&s| in_pattern(c, s)).count()).collect();
    per_corner.sort();
    per_corner.dedup();
    println!("mistake, box topology: on {} dials {} corners, each in exactly {} of the {} boxes, so all {} are needed",
             k, 1u32 << k, per_corner[0], 1u32 << k, 1u32 << k);

    println!("Part 4: finite cases, every case checked");
    let fip = |f: u32| -> bool {                   // a family is a mask over the 8 subsets of {a, b, c}
        (1..256u32).filter(|&g| g & f == g).all(|g| (0..8u32).filter(|&a| g >> a & 1 == 1).fold(7u32, |acc, a| acc & a) != 0)
    };
    let good: Vec<u32> = (0..256u32).filter(|&f| fip(f)).collect();
    let incl_excl = 3 * 16 - 3 * 4 + 2;
    let top: Vec<u32> = good.iter().copied().filter(|&f| !good.iter().any(|&g| g != f && g & f == f)).collect();
    let by_point = top.iter().all(|&f| (0..3).any(|x| f == (0..8u32).filter(|&a| a >> x & 1 == 1).fold(0, |acc, a| acc | 1 << a)));
    let decides = top.iter().all(|&f| (0..8u32).all(|a| f >> a & 1 == 1 || f >> (7 - a) & 1 == 1));
    println!("Zorn, 3 points: 256 families of subsets; {} have the FIP (inclusion-exclusion {}); {} maximal",
             good.len(), incl_excl, top.len());
    println!("  each maximal one is the {} sets holding one point: {}; holds A or its outside: {}",
             top[0].count_ones(), yn(by_point), yn(decides));
    let m = 10u32;                                 // ten boxes of two socks, plus the extra point p
    let mut masks = vec![0u64; 1 << m];
    for code in 0..3u32.pow(m) {                   // digit 0 left, 1 right, 2 the point p
        let (mut c, mut key) = (code, 0usize);
        for i in 0..m { if c % 3 != 2 { key |= 1 << i; } c /= 3; }
        masks[key] += 1;
    }
    let common: Vec<u64> = (0..1usize << m).map(|t| (0..1usize << m).filter(|&mm| mm & t == t).map(|mm| masks[mm]).sum()).collect();
    let formula = (0..1usize << m).all(|t| { let s = t.count_ones(); common[t] == 2u64.pow(s) * 3u64.pow(m - s) });
    let least = *common.iter().min().unwrap();
    println!("Kelley, {} boxes of 2 socks plus p: {} points; all {} subfamilies of F_1..F_{} meet: {}; smallest common set {} = the full picks",
             m, 3u32.pow(m), 1u32 << m, m, yn(least > 0), least);
    println!("  common points of F_1, F_2, F_3: {}; of all {}: {}", common[7], m, common[(1 << m) - 1]);
    assert!(walk == vec![0, 9, 8, 7, 6, 5, 4, 3, 2, 1] && smallest == vec![first_ten.clone()]);   // roads 1, 2
    assert!(hits == vec![1; 10] && best as usize == witness.len());                // road 3 lower bound
    assert!(zero_left && gone == 999 && open_gone == 1000);
    assert!(near == vec![d - 3, d - 10] && in_box == 0 && sup == vec![fr(1, 1)]);
    assert!(per_corner == vec![1] && good.len() == incl_excl && top.len() == 3 && by_point);
    assert!(formula && common[(1 << m) - 1] == 1 << m && decides);
    let fig: Vec<String> = (0..10).map(|n| { let (a, b) = arc(n);
        format!("U_{} {}..{}", n, show(fr(360 * a.p, a.q)), show(fr(360 * b.p, b.q))) }).collect();
    println!("figure, arcs in degrees from east: {}", fig.join("; "));
    println!("ALL CHECKS PASS");
}
