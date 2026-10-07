// Null sets and almost everywhere -- the check behind the card.  Rust std
// only.  A dart lands uniformly on a board of radius 1 m, so the chance of a
// region is its area divided by pi.  Four roads: exact chances against a
// simulated dart, a countable cover by list against its closed form, pi by a
// series against a grid count, and a completion built two ways.
use std::collections::{BTreeMap, BTreeSet, HashSet};

fn splitmix64(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn gcd(a: i64, b: i64) -> i64 {
    let (mut a, mut b) = (a.abs(), b.abs());
    while b != 0 {
        let t = a % b;
        a = b;
        b = t;
    }
    a
}

fn arctan_inv(n: f64) -> f64 {
    let (mut total, mut term, mut k, mut sign) = (0.0, 1.0 / n, 1.0, 1.0);
    while term > 1e-18 {
        total += sign * term / k;
        term /= n * n;
        k += 2.0;
        sign = -sign;
    }
    total
}

fn unit(bits: u64) -> f64 {
    (2 * (bits >> 11)) as f64 / 9007199254740992.0 - 1.0
}

fn main() {
    let pi_series = 16.0 * arctan_inv(5.0) - 4.0 * arctan_inv(239.0);
    let r_big: i64 = 1_000_000;
    let (mut x, mut cells) = (r_big, 0i64);
    for y in 0..r_big {
        while x * x + y * y >= r_big * r_big {
            x -= 1;
        }
        cells += x + 1;
    }
    let pi_upper = 4.0 * cells as f64 / (r_big * r_big) as f64; // corner inside
    let pi_lower = 4.0 * (cells - 2 * r_big) as f64 / (r_big * r_big) as f64; // wholly inside
    println!("board area by Machin's series: {:.6} m^2", pi_series);
    println!("board area by 1-micron cells: between {:.6} and {:.6} m^2", pi_lower, pi_upper);

    let n = 200_000usize;
    let radii = [0.5, 0.2, 0.1, 0.05, 0.02, 0.01];
    let (mut state, mut darts) = (20260929u64, Vec::new());
    while darts.len() < n {
        let (s1, a) = splitmix64(state);
        let (s2, b) = splitmix64(s1);
        state = s2;
        let (px, py) = (unit(a), unit(b));
        if px * px + py * py <= 1.0 {
            darts.push(px * px + py * py);
        }
    }
    println!("darts thrown {}, seed 20260929", n);
    println!("r, P(within r of centre) exact, simulated, P(within r of rim) exact, simulated");
    let mut worst: f64 = 0.0;
    for &r in radii.iter() {
        let (c, m) = (r * r, 1.0 - (1.0 - r) * (1.0 - r));
        let sc = darts.iter().filter(|&&d| d < r * r).count() as f64 / n as f64;
        let sm = darts.iter().filter(|&&d| d > (1.0 - r) * (1.0 - r)).count() as f64 / n as f64;
        for (e, s) in [(c, sc), (m, sm)] {
            worst = worst.max((s - e).abs() / (e * (1.0 - e) / n as f64).sqrt());
        }
        println!("{:.2}, {:.4}, {:.4}, {:.4}, {:.4}", r, c, sc, m, sm);
    }
    println!("largest gap, in standard errors: {:.2}", worst);
    let at_centre = darts.iter().filter(|&&d| d == 0.0).count();
    println!("darts landing exactly on the centre: {} of {}", at_centre, n);

    let eps = 0.001f64;
    let (mut seen, mut listed, mut grid_count) = (HashSet::new(), 0usize, 0usize);
    println!("eps = 0.001; denominator up to D, rational points listed K, cover area total");
    for q in 1..7i64 {
        for p1 in -q..=q {
            for p2 in -q..=q {
                if p1 * p1 + p2 * p2 <= q * q {
                    let (g1, g2) = (gcd(p1, q), gcd(p2, q)); // road one: reduce
                    if seen.insert((p1 / g1, q / g1, p2 / g2, q / g2)) {
                        listed += 1;
                    }
                    if gcd(gcd(p1, p2), q) == 1 {
                        grid_count += 1; // road two: gcd test
                    }
                }
            }
        }
        let by_list: f64 = (1..=listed).map(|k| eps / 2f64.powi(k as i32)).sum();
        let closed = eps * (1.0 - 1.0 / 2f64.powi(listed as i32));
        assert!((by_list - closed).abs() < 1e-18 && listed == grid_count);
        println!("D={}, K={}, cover {:.10} m^2, chance at most {:.10}", q, listed, by_list, by_list / pi_series);
    }

    println!("diameter covered by n squares of side 2/n: n, total area 4/n, chance at most");
    for k in [10.0f64, 100.0, 1000.0] {
        println!("n={}, {:.4} m^2, {:.6}", k, 4.0 / k, 4.0 / k / pi_series);
    }

    let names = ["centre", "rim", "inner", "outer"];
    let f: BTreeMap<u8, u8> = [(0, 0), (3, 0), (12, 1), (15, 1)].iter().cloned().collect();
    let nulls: Vec<u8> = f.iter().filter(|&(_, &p)| p == 0).map(|(&a, _)| a).collect();
    let mut pairs = BTreeSet::new();
    for (&a, &p) in f.iter() {
        for &nn in nulls.iter() {
            for m in 0..16u8 {
                if m & !nn == 0 {
                    pairs.insert((a | m, p));
                }
            }
        }
    }
    let road1: BTreeMap<u8, u8> = pairs.iter().cloned().collect();
    let mut road2 = BTreeMap::new();
    for e in 0..16u8 {
        for (&a, &p) in f.iter() {
            for &b in f.keys() {
                let gap = b & !a;
                if a & !e == 0 && e & !b == 0 && f.get(&gap) == Some(&0) {
                    road2.insert(e, p);
                }
            }
        }
    }
    let closed_up = road1.keys().all(|&e| road1.keys().all(|&g| road1.contains_key(&(15 ^ e)) && road1.contains_key(&(e | g))));
    let label = |e: u8| format!("{{{}}}", (0..4).filter(|i| e >> i & 1 == 1).map(|i| names[i]).collect::<Vec<_>>().join(", "));
    println!("scorer's sigma-algebra: {} sets; its completion: {} sets of 16", f.len(), road1.len());
    for (&e, &p) in road1.iter() {
        println!("  {}: {}", label(e), p);
    }
    println!("completion closed under complement and union: {}", if closed_up { "yes" } else { "no" });
    println!("not in the completion: {}, {}, {}", label(4), label(8), label(5));

    let mut on_rational = 0;
    for i in 0..1000u64 {
        let v = unit(splitmix64(i).1);
        if (v * 9007199254740992.0).fract() == 0.0 {
            on_rational += 1; // a whole number over 2^53
        }
    }
    println!("simulated coordinates that are rational: {} of 1000", on_rational);
    println!("figure, board r=100px at (120,120); centre discs 50, 20, 10 px; rim band 90-100 px");

    assert!(pi_lower < pi_series && pi_series < pi_upper); // two roads to the area
    assert!(worst < 4.0); // simulation within 4 SE
    assert!(road1 == road2 && pairs.len() == 8 && road1.len() == 8 && closed_up); // one value each
}
