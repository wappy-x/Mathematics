// Projective, injective and flat modules -- the same check as the Python, in Rust.
// No crates.  Part 1: over each ring Z/n, n = 2 to 30, every module Z/m (m > 1, m
// dividing n) is tested by finite search: projective two ways (a section, a summand),
// injective by Baer's criterion, flat by the ideal test, all against gcd(m, n/m) = 1.
// Part 2: over Z, the sequence 0 -> Z -> Z -> Z/2 -> 0 (first map times 2) is fed to
// Hom(P, -), Hom(-, I) and - tensor F, with exact fractions for Q and Q/Z.
use std::collections::BTreeSet;

fn gcd(a: i64, b: i64) -> i64 {
    let (mut a, mut b) = (a.abs(), b.abs());
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

// Part 1.  The ring Z/n acts on the module Z/m by r.x = r*x mod m.
fn section(n: i64, m: i64) -> Vec<i64> {      // the onto map Z/n -> Z/m, 1 -> 1, has s(1) = r
    (0..n).filter(|&r| m * r % n == 0 && r % m == 1).collect()
}

fn summand(n: i64, m: i64) -> bool {          // an idempotent e with e(Z/n) of size m
    (0..n).any(|e| e * e % n == e && n / gcd(e, n) == m)
}

fn baer(n: i64, m: i64, ideals: &[i64]) -> bool { // every map from an ideal dZ/n extends
    for &d in ideals {
        for x in 0..m {                        // d -> x is well defined when (n/d) x = 0
            if (n / d) * x % m == 0 && !(0..m).any(|y| d * y % m == x) { return false }
        }
    }
    true
}

fn ideal_test(n: i64, m: i64) -> bool {       // dZ/n tensor Z/m = Z/m over (n/d)Z/m, x -> d x
    for d in (1..=n).filter(|d| n % d == 0) {
        let zero: BTreeSet<i64> = (0..m).map(|z| (n / d) * z % m).collect();
        if (0..m).any(|x| d * x % m == 0 && !zero.contains(&x)) { return false }
    }
    true
}

fn verdicts(n: i64, m: i64) -> Vec<bool> {
    let divs: Vec<i64> = (1..=n).filter(|d| n % d == 0).collect();
    vec![!section(n, m).is_empty(), summand(n, m), baer(n, m, &divs), ideal_test(n, m)]
}

// Part 2.  Fractions p/q in lowest terms, q > 0; in Q/Z the top is taken mod q.
fn frac(p: i64, q: i64, mod1: bool) -> (i64, i64) {
    let (p, q) = if q < 0 { (-p, -q) } else { (p, q) };
    let g = gcd(p, q);
    let (p, q) = (p / g, q / g);
    if mod1 { (p.rem_euclid(q), q) } else { (p, q) }
}

fn show(f: (i64, i64)) -> String { if f.1 == 1 { format!("{}", f.0) } else { format!("{}/{}", f.0, f.1) } }

fn lst(v: &[String]) -> String { format!("[{}]", v.join(", ")) }

fn main() {
    println!("ring  module  section  summand  Baer  flat  gcd(m, n/m)");
    for (n, m) in [(6, 2), (6, 3), (6, 6), (4, 2), (4, 4), (12, 2), (12, 4), (12, 6)] {
        let v = verdicts(n, m);
        println!("{:<5} {:<6} {:<8} {:<8} {:<5} {:<5} {}", format!("Z/{}", n), format!("Z/{}", m),
                 yn(v[0]), yn(v[1]), yn(v[2]), yn(v[3]), gcd(m, n / m));
    }
    let mut pairs: Vec<(i64, i64)> = Vec::new();
    for n in 2..31 { for m in 2..=n { if n % m == 0 { pairs.push((n, m)) } } }
    let agree = pairs.iter().all(|&(n, m)| verdicts(n, m) == vec![gcd(m, n / m) == 1; 4]);
    let good = pairs.iter().filter(|&&(n, m)| verdicts(n, m)[0]).count();
    let whole_ring_only = pairs.iter().filter(|&&(n, m)| baer(n, m, &[1])).count();
    let crt: BTreeSet<(i64, i64)> = (0..6).map(|x| (x % 2, x % 3)).collect();
    let idem: Vec<i64> = (0..6).filter(|e| e * e % 6 == *e).collect();
    let i3: BTreeSet<i64> = (0..6).map(|r| 3 * r % 6).collect();
    let i4: BTreeSet<i64> = (0..6).map(|r| 4 * r % 6).collect();
    println!("Z/6 -> Z/2 x Z/3, x -> (x mod 2, x mod 3), hits {} of 6 pairs", crt.len());
    println!("idempotents of Z/6: {:?}; 3Z/6 = {:?}, 4Z/6 = {:?}, 3 + 4 = {} mod 6", idem,
             i3.iter().collect::<Vec<_>>(), i4.iter().collect::<Vec<_>>(), (3 + 4) % 6);
    println!("sections of Z/6 -> Z/2: s(1) in {:?}; of Z/4 -> Z/2: s(1) in {:?}", section(6, 2), section(4, 2));
    println!("free Z/6-modules have {:?} members; Z/2 has 2", (0..4).map(|k| 6i64.pow(k)).collect::<Vec<_>>());
    println!("Z/4 on Z/2, ideal 2Z/4, map 2 -> 1: solutions of 2y = 1 in Z/2: {:?}",
             (0..2).filter(|y| 2 * y % 2 == 1).collect::<Vec<i64>>());
    println!("pairs (n, m) checked: {}; all four tests match gcd(m, n/m) = 1: {}; all three hold: {}",
             pairs.len(), yn(agree), good);
    println!("Baer tested on the ideal Z/n alone passes {} of {}", whole_ring_only, pairs.len());

    let qz: Vec<(i64, i64)> = (1..13).flat_map(|d| (0..d).map(move |c| frac(c, d, true)))
        .collect::<BTreeSet<_>>().into_iter().collect();
    let qs: Vec<(i64, i64)> = (1..13).flat_map(|d| (-12..13).map(move |c| frac(c, d, false)))
        .collect::<BTreeSet<_>>().into_iter().collect();
    let zw = -1000i64..1001;
    let hom_z2_z: Vec<i64> = zw.clone().filter(|k| 2 * k == 0).collect();
    let ext_z: Vec<i64> = zw.clone().filter(|y| 2 * y == 1).collect();
    let ext_qz: Vec<String> = qz.iter().filter(|y| frac(2 * y.0, y.1, true) == frac(1, 3, false))
        .map(|&y| show(y)).collect();
    let ker_zz: Vec<i64> = zw.clone().filter(|x| 2 * x == 0).collect();
    let ker_z2: Vec<i64> = (0..2).filter(|x| 2 * x % 2 == 0).collect();
    let ext_z2: Vec<i64> = (0..2).filter(|y| 2 * y % 2 == 1).collect();
    let ker_q: Vec<String> = qs.iter().filter(|x| frac(2 * x.0, x.1, false) == (0, 1)).map(|&x| show(x)).collect();
    let ker_qz: Vec<String> = qz.iter().filter(|x| frac(2 * x.0, x.1, true) == (0, 1)).map(|&x| show(x)).collect();
    let count = |x: (i64, i64), n: i64| (0..n * x.1).filter(|&c| frac(n * c, n * x.1, true) == x).count() as i64;
    let roots: BTreeSet<i64> = qz.iter().flat_map(|&x| (2..13).map(move |n| count(x, n))).collect();
    let roots_ok = qz.iter().all(|&x| (2..13).all(|n| count(x, n) == n));
    let mut lcm = 1i64;
    for k in 1..21 { lcm = lcm * k / gcd(lcm, k) }
    let hom_q_z: Vec<i64> = zw.clone().filter(|k| (1..21).all(|nn| k % nn == 0)).collect();
    let lift_z = (0..2).all(|t| zw.clone().any(|b| b.rem_euclid(2) == t));  // each map Z -> Z/2, 1 -> t, lifts to 1 -> b
    let div_q = qs.iter().all(|&x| (2..13).all(|n| { let y = frac(x.0, n * x.1, false); frac(n * y.0, y.1, false) == x }));
    println!("the sequence 0 -> Z -> Z -> Z/2 -> 0, first map times 2");
    println!("Hom(Z/2, -): maps Z/2 -> Z have f(1) in {:?}, so the identity of Z/2 does not lift", hom_z2_z);
    println!("Hom(-, Z): extend 2 -> 1 from 2Z to Z: solutions of 2y = 1 in -1000..1000: {:?}", ext_z);
    println!("Hom(-, Q/Z): extend 2 -> 1/3 from 2Z to Z: solutions of 2y = 1/3: {}", lst(&ext_qz));
    println!("tensor Z: times 2 on Z, kernel in -1000..1000: {:?}", ker_zz);
    println!("tensor Z/2: times 2 on Z/2, kernel {:?}", ker_z2);
    println!("tensor Q: times 2 on Q, kernel in the window of {} fractions: {}", qs.len(), lst(&ker_q));
    println!("tensor Q/Z: times 2 on Q/Z, kernel {}", lst(&ker_qz));
    println!("Q/Z, {} classes, n = 2..12: n y = x has exactly n solutions every time: {}", qz.len(), yn(roots_ok));
    println!("a map Q -> Z sends 1 to a multiple of 1..20; lcm(1..20) = {}; such f(1) in -1000..1000: {:?}", lcm, hom_q_z);
    println!("module  projective  injective  flat");
    let table = [("Z", lift_z, !ext_z.is_empty(), ker_zz == vec![0]),        // Z lifts
                 ("Q", hom_q_z != vec![0], div_q, ker_q == vec!["0".to_string()]), // Q divides
                 ("Q/Z", ker_qz.len() == 1, roots_ok, ker_qz.len() == 1),     // not flat, so not projective
                 ("Z/2", hom_z2_z != vec![0], !ext_z2.is_empty(), ker_z2.len() == 1)];
    for &(name, p, i, f) in table.iter() {
        println!("{:<7} {:<11} {:<10} {}", name, yn(p), yn(i), yn(f));
    }
    let tor: Vec<i64> = (0..6).filter(|x| 4 * x % 6 == 0).collect();
    let ext = 6 / (0..6).map(|x| 4 * x % 6).collect::<BTreeSet<i64>>().len();
    println!("house example: times 4 on Z/6 has kernel {:?} (Tor) and {} classes left over (Ext)", tor, ext);
    assert!(agree && pairs.len() == 81 && good == 59);               // four roads, one rule
    let all_pairs: BTreeSet<(i64, i64)> = (0..2).flat_map(|a| (0..3).map(move |b| (a, b))).collect();
    assert!(section(6, 2) == vec![3] && section(4, 2).is_empty() && crt == all_pairs);
    assert!(hom_z2_z == vec![0] && ext_z.is_empty() && ext_qz == vec!["1/6", "2/3"]);
    assert!(ker_z2 == vec![0, 1] && ker_q == vec!["0"] && ker_qz == vec!["0", "1/2"]);
    assert!(roots_ok && roots == (2..13).collect::<BTreeSet<i64>>() && hom_q_z == vec![0] && lcm == 232792560);
    assert!(whole_ring_only == pairs.len() && tor == vec![0, 3] && ext == 2 && ker_zz == vec![0]);
    let verdicts_seen: Vec<(bool, bool, bool)> = table.iter().map(|r| (r.1, r.2, r.3)).collect();
    assert!(verdicts_seen == vec![(true, false, true), (false, true, true), (false, true, false), (false, false, false)]);
    println!("ALL CHECKS PASS");
}
