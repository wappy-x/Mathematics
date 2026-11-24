// Nets and filters: the check behind the card.  std only, exact fractions as reduced (top, bottom) pairs.
use std::collections::BTreeSet;

type Q = (i64, i64);
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(a: i64, b: i64) -> Q { let g = gcd(a, b); (a / g, b / g) }
fn sub(x: Q, y: Q) -> Q { q(x.0 * y.1 - y.0 * x.1, x.1 * y.1) }
fn add(x: Q, y: Q) -> Q { q(x.0 * y.1 + y.0 * x.1, x.1 * y.1) }
fn lt(x: Q, y: Q) -> bool { x.0 * y.1 < y.0 * x.1 }
fn show(x: Q) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{}/{}", x.0, x.1) } }
fn dec(x: Q) -> String { // a terminating fraction as a decimal
    for k in 0..7u32 {
        let p = 10i64.pow(k);
        if (x.0 * p) % x.1 == 0 {
            let s = format!("{:0>w$}", (x.0 * p / x.1).abs(), w = k as usize + 1);
            return if k == 0 { s } else { format!("{}.{}", &s[..s.len() - k as usize], &s[s.len() - k as usize..]) };
        }
    }
    panic!("not terminating")
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn has(fm: u32, s: u32) -> bool { fm >> s & 1 == 1 }
fn farey(n: i64) -> BTreeSet<Q> { (1..=n).flat_map(|d| (0..=d).map(move |p| q(p, d))).collect() }
fn phi(k: i64) -> i64 { // totient by the product over primes
    let (mut out, mut m, mut p) = (k, k, 2);
    while p * p <= m {
        if m % p == 0 { out -= out / p; while m % p == 0 { m /= p; } }
        p += 1;
    }
    if m > 1 { out - out / m } else { out }
}

fn main() {
    // Part 1: the net f_F in R^[0,1].  F is a bit mask over 8 sample points.
    let pts: [Q; 8] = [q(1, 8), q(1, 4), q(2, 7), q(1, 3), q(1, 2), q(3, 5), q(3, 4), q(1, 1)];
    let boxm: u32 = (1 << 4) | (1 << 3) | (1 << 2); // 1/2, 1/3, 2/7
    let f = |s: u32, x: Q| -> i64 { if (0..8).any(|i| has(s, i as u32) && pts[i] == x) { 0 } else { 1 } }; // f_F at x
    let in_box = |s: u32| [4usize, 3, 2].iter().all(|&i| lt(q(f(s, pts[i]), 1), q(1, 10)));
    println!("Part 1: R^[0,1], pointwise; f_F is 0 on the finite set F, 1 elsewhere");
    println!("box B round the zero function: |f(x)| < 1/10 at x = 1/2, 1/3, 2/7");
    for (name, s) in [("{}", 0u32), ("{1/2, 1/3}", (1 << 4) | (1 << 3)), ("{1/2, 1/3, 2/7}", boxm)] {
        let vals: Vec<String> = [4usize, 3, 2].iter().map(|&i| f(s, pts[i]).to_string()).collect();
        println!("  F = {}: values at 1/2, 1/3, 2/7: {}; in B: {}", name, vals.join(" "), yn(in_box(s)));
    }
    let least = (0..256u32).all(|a| (0..256u32).all(|b| (0..256u32).filter(|&c| a & c == a && b & c == b) // later, by search
        .min_by_key(|c| c.count_ones()) == Some(a | b))); // road 2: the union
    let tail: Vec<u32> = (0..256u32).filter(|&s| in_box(s)).collect();
    let holds0 = (0..256u32).all(|s| in_box(s) == (s & boxm == boxm));
    assert!(least && holds0);
    assert_eq!(tail.len(), 1 << (8 - 3)); // road 2: count by formula
    println!("8 sample points, 256 finite sets F: least later F, by search, is the union for all 65536 pairs: {}", yn(least));
    println!("  f_F in B for {} of 256 F; exactly those holding the probes: yes; 2^(8-3) = {}", tail.len(), 1 << (8 - 3));
    let single = (0..8u32).filter(|&i| in_box(1 << i)).count();
    assert_eq!(single, 0);
    println!("mistake, singletons only (not directed): f_x in B for {} of 8", single);

    // Part 2: the best sequence, g_n = 0 on every fraction p/q in [0, 1] with q <= n.
    println!("Part 2: the best sequence: g_n is 0 on every fraction p/q in [0, 1] with q <= n");
    let mut sizes = Vec::new();
    for n in [10i64, 100] {
        let (a, b) = (farey(n).len() as i64, 1 + (1..=n).map(phi).sum::<i64>());
        assert_eq!(a, b);
        sizes.push(format!("n = {}: {} (1 + totient sum {})", n, a, b));
    }
    println!("  zero-set sizes: {}", sizes.join("; "));
    let first = (1..=100).find(|&n| farey(n).contains(&q(2, 7))).unwrap();
    assert!(first == 7 && (7..=100).all(|n| farey(n).contains(&q(2, 7))));
    println!("  at x = 2/7: g_n(x) = 1 for n = 1..{}, 0 from n = {} on", first - 1, first);
    assert!(farey(100).iter().all(|&(p, d)| 2 * p * p != d * d));
    println!("  at x = sqrt(2)/2: 2p^2 = q^2 for no p/q with q <= 100, so g_n(x) = 1 for n = 1..100");
    println!("  g_n never enters the box |f(sqrt(2)/2)| < 1/10: checked on n = 1..100");

    // Part 3: the circle in turns.  A = open arc (0, 1/4), p = 1/4 turn.  Arcs of radius 1/n round p.
    println!("Part 3: the circle in turns; A = arc (0, 1/4), p = 1/4 turn = 90 degrees");
    let x_n = |n: i64| sub(q(1, 4), q(1, 2 * n));
    let gap = |n: i64| sub(q(1, 4), x_n(n));
    for n in [10i64, 100, 1000] {
        let x = x_n(n);
        assert!(lt(q(0, 1), x) && lt(x, q(1, 4)) && lt(gap(n), q(1, n)));
        println!("  n = {}: x_n = {} turn = {} degrees", n, show(x), dec(q(360 * x.0, x.1)));
    }
    let entry: Vec<i64> = (1..=2000).filter(|&n| lt(gap(n), q(1, 1000))).collect();
    assert_eq!(entry, (1000 / 2 + 1..=2000).collect::<Vec<i64>>()); // road 2: 1/(2n) < 1/1000 iff n > 500
    println!("  inside the arc of radius 1/1000 round p from n = {} on (checked n = 1..2000)", entry[0]);

    // Part 4: continuity.  h = 1 at the zero function, 0 on A.
    let witness = |s: u32| (9..99).map(|m| q(1, m)).find(|w| !(0..8).any(|i| has(s, i as u32) && pts[i] == *w)).unwrap();
    let hvals: BTreeSet<i64> = (0..256u32).map(|s| if f(s, witness(s)) == 1 { 0 } else { 1 }).collect(); // f_F = 1 there
    assert!(hvals == BTreeSet::from([0]));
    println!("Part 4: h = 1 at the zero function, 0 on A");
    println!("  h(f_F) over all 256 F: [0] (f_F = 1 at {}); h(0) = 1; f_F -> 0 but h(f_F) stays 0", show(witness(255)));

    // Part 5: filters on {a, b, c}, all 256 families of subsets (subsets as bit masks 0..7).
    let x_all = 7u32;
    let and_of = |c: &[u32]| c.iter().fold(x_all, |o, &s| o & s);
    let is_filter = |fm: u32| has(fm, x_all) && !has(fm, 0)
        && (0..8).all(|s| (0..8).all(|t| !(has(fm, s) && has(fm, t)) || has(fm, s & t)))
        && (0..8).all(|s| (0..8).all(|t| !(has(fm, s) && s & t == s) || has(fm, t)));
    let fip = |fm: u32| { let mem: Vec<u32> = (0..8).filter(|&s| has(fm, s)).collect();
        (1..1u32 << mem.len()).all(|c| { let pick: Vec<u32> = (0..mem.len()).filter(|&i| has(c, i as u32)).map(|i| mem[i]).collect(); and_of(&pick) != 0 }) };
    let filters: Vec<u32> = (0..256).filter(|&fm| is_filter(fm)).collect();
    let principal = filters.iter().all(|&fm| { let core = and_of(&(0..8).filter(|&s| has(fm, s)).collect::<Vec<u32>>());
        fm == (0..8).filter(|&t| t & core == core).map(|t| 1u32 << t).sum::<u32>() });
    let maximal = |v: &Vec<u32>| -> Vec<u32> { v.iter().copied().filter(|&g| !v.iter().any(|&h| h != g && h & g == g)).collect() };
    let maxf = maximal(&filters);
    let ultra: Vec<u32> = filters.iter().copied().filter(|&g| (0..8).all(|s| has(g, s) || has(g, x_all ^ s))).collect();
    let fips: Vec<u32> = (0..256).filter(|&fm| fip(fm)).collect();
    let maxfip = maximal(&fips);
    assert!(filters.len() == (1 << 3) - 1 && principal && maxf == ultra && ultra == maxfip && ultra.len() == 3);
    println!("Part 5: filters on {{a, b, c}}, every one of the 256 families checked");
    println!("  filters: {} (one per non-empty core, 2^3 - 1 = 7); each is all sets holding its core: yes", filters.len());
    println!("  ultrafilters: {}, by maximality, by 'S or its outside', and as the maximal FIP families: same 3", ultra.len());

    // Part 6: every topology on {a, b, c}; an ultrafilter at a point converges where every open set holds it.
    let tops: Vec<u32> = (0..256u32).filter(|&t| has(t, 0) && has(t, x_all)
        && (0..8).all(|s| (0..8).all(|u| !(has(t, s) && has(t, u)) || (has(t, s & u) && has(t, s | u))))).collect();
    let limits = |t: u32, pt: u32| -> usize { (0..3).filter(|&c| (0..8).all(|u| !has(t, u) || !has(u, c) || has(u, pt))).count() };
    let conv = tops.iter().all(|&t| (0..3).all(|pt| limits(t, pt) > 0));
    let unique: Vec<u32> = tops.iter().copied().filter(|&t| (0..3).all(|pt| limits(t, pt) == 1)).collect();
    let haus: Vec<u32> = tops.iter().copied().filter(|&t| (0..3).all(|i| (0..3).all(|j| i == j
        || (0..8).any(|u| (0..8).any(|v| has(t, u) && has(t, v) && has(u, i) && has(v, j) && u & v == 0))))).collect();
    assert!(tops.len() == 29 && conv && unique == haus && unique.len() == 1);
    println!("Part 6: all {} topologies on {{a, b, c}}: every ultrafilter converges: yes", tops.len());
    println!("  limits unique in {} topology, the discrete one; Hausdorff ones: {}; same: yes", unique.len(), haus.len());
    println!("  mistake, no Hausdorff: some ultrafilter has two or more limits in {} of {}", tops.len() - unique.len(), tops.len());

    // Part 7: the circle without the glue point; the filter made from the arcs (0, 1/n) turn.  An illustration:
    // r = min(q, 1 - q)/2 makes the arc (q - r, q + r) miss (0, r) by construction.
    println!("Part 7: the circle minus the glue point; the filter of the arcs (0, 1/n) turn");
    for k in [1i64, 6, 11] {
        let c = q(k, 12);
        let rest = sub(q(1, 1), c);
        let r = if lt(c, rest) { q(c.0, 2 * c.1) } else { q(rest.0, 2 * rest.1) };
        assert!(r.0 == 1); // r = 1/n, so (0, r) is one of the filter's sets
        println!("  candidate limit {} turn: arc ({}, {}) misses (0, 1/{})", show(c), show(sub(c, r)), show(add(c, r)), r.1);
    }
    println!("  on the whole circle every arc round 0 holds some (0, 1/n): limit 0, the removed point");

    // Part 8: [0,1]^[0,1] is compact, yet s_n(x) = n-th binary digit of x has no convergent subsequence.
    let x = (1..=8i64).filter(|k| k % 2 == 1).fold(q(0, 1), |a, k| add(a, q(1, 1 << (2 * k))));
    let digits: Vec<i64> = (1..=8i64).map(|k| (x.0 * (1 << (2 * k)) / x.1) % 2).collect(); // road 2: read back
    assert_eq!(digits, (1..=8i64).map(|k| k % 2).collect::<Vec<i64>>());
    println!("Part 8: s_n = n-th binary digit; subsequence n_k = 2k; x = {}", show(x));
    let ds: Vec<String> = digits.iter().map(|d| d.to_string()).collect();
    println!("  s_(2k)(x) for k = 1..8: {}; never settles", ds.join(" "));
    println!("ALL CHECKS PASS");
}
