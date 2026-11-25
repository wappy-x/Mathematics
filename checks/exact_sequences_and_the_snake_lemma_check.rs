// Exact sequences and the snake lemma, checked by brute force on whole numbers.
// Row: 0 -> Z --times n--> Z --mod n--> Z/n -> 0 (metres -> half-metres -> leftover, for n = 2).
// Snake: multiply every module in the row by m and chase elements.
use std::collections::BTreeSet;

const L: i64 = 360; // a box [0, L) that every modulus here divides

fn w() -> std::ops::RangeInclusive<i64> { -60..=60 } // a window of whole numbers, for searches in Z
fn bw() -> std::ops::Range<i64> { -L..L }             // a wider window, so images cover the box
fn md(a: i64, n: i64) -> i64 { a.rem_euclid(n) }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn index_in_box(image: impl Iterator<Item = i64>) -> i64 {
    // |Z / image| = box points / image points in the box
    L / image.filter(|&y| 0 <= y && y < L).collect::<BTreeSet<i64>>().len() as i64
}

fn cosets(n: i64, sub: &BTreeSet<i64>) -> Vec<BTreeSet<i64>> {
    // the members of (Z/n)/sub, each as a set
    let all: BTreeSet<BTreeSet<i64>> = (0..n).map(|z| sub.iter().map(|s| md(z + s, n)).collect()).collect();
    all.into_iter().collect()
}

fn dict(c: &[(i64, i64)]) -> String {
    let parts: Vec<String> = c.iter().map(|(k, v)| format!("{}: {}", k, v)).collect();
    format!("{{{}}}", parts.join(", "))
}

type Map = Box<dyn Fn(i64) -> i64>;

fn snake(n: i64, m: i64, delta_on: bool) -> (Vec<i64>, Vec<(i64, i64)>, usize) {
    let ker_a: Vec<i64> = w().filter(|&x| m * x == 0).collect();
    let ker_b: Vec<i64> = w().filter(|&y| m * y == 0).collect();
    let ker_c: Vec<i64> = (0..n).filter(|&z| md(m * z, n) == 0).collect();
    let coker_a: Vec<i64> = (0..m).collect();
    let coker_b: Vec<i64> = (0..m).collect();
    let im_c: BTreeSet<i64> = (0..n).map(|z| md(m * z, n)).collect();
    let coker_c = cosets(n, &im_c);
    let cc = coker_c.clone();
    let cls = move |z: i64| cc.iter().position(|k| k.contains(&md(z, n))).unwrap() as i64;
    let mut chase: Vec<(i64, i64)> = Vec::new();
    for &z in &ker_c {
        // lift, push down, pull back, take the class
        let mut classes = BTreeSet::new();
        for t in -3..=3 {
            let y = z + n * t; // lift: y mod n = z
            let x = w().find(|&x| n * x == m * y).unwrap(); // pull back: n x = m y
            classes.insert(md(x, m));
        }
        assert!(classes.len() == 1, "delta depends on the lift");
        chase.push((z, *classes.iter().next().unwrap()));
    }
    let ch = chase.clone();
    let delta = move |z: i64| if delta_on { ch.iter().find(|p| p.0 == z).unwrap().1 } else { 0 };
    let idx: Vec<i64> = (0..coker_c.len() as i64).collect();
    let (d1, d2) = (delta.clone(), delta);
    let (c1, c2, c0) = (cls.clone(), cls.clone(), cls(0));
    // (incoming source, incoming map, spot, outgoing map, zero of the target)
    let spots: Vec<(Vec<i64>, Map, Vec<i64>, Map, i64)> = vec![
        (vec![0], Box::new(|_| 0), ker_a.clone(), Box::new(move |x| n * x), 0),
        (ker_a.clone(), Box::new(move |x| n * x), ker_b.clone(), Box::new(move |y| md(y, n)), 0),
        (ker_b.clone(), Box::new(move |y| md(y, n)), ker_c.clone(), Box::new(d1), 0),
        (ker_c.clone(), Box::new(d2), coker_a.clone(), Box::new(move |x| md(n * x, m)), 0),
        (coker_a.clone(), Box::new(move |x| md(n * x, m)), coker_b.clone(), Box::new(c1), c0),
        (coker_b.clone(), Box::new(c2), idx, Box::new(|_| 0), 0),
    ];
    let exact = spots.iter().filter(|(s, f, spot, g, zero)| {
        let img: BTreeSet<i64> = s.iter().map(|&x| f(x)).collect();
        let ker: BTreeSet<i64> = spot.iter().copied().filter(|&v| g(v) == *zero).collect();
        img == ker
    }).count();
    let sizes = vec![ker_a.len() as i64, ker_b.len() as i64, ker_c.len() as i64,
        index_in_box(bw().map(|x| m * x)), index_in_box(bw().map(|y| m * y)), coker_c.len() as i64];
    (sizes, chase, exact)
}

fn main() {
    // 1. the row is exact, three spots, on the window
    let inj: Vec<i64> = w().filter(|&x| 2 * x == 0).collect();
    let doubles: BTreeSet<i64> = w().map(|x| 2 * x).filter(|&y| -60 <= y && y <= 60).collect();
    let mid = w().filter(|&y| md(y, 2) == 0).collect::<BTreeSet<i64>>() == doubles;
    let onto = w().map(|y| md(y, 2)).collect::<BTreeSet<i64>>() == [0, 1].into_iter().collect();
    println!("row 0 -> Z --x2--> Z --mod 2--> Z/2 -> 0: kernel of x2 {:?}; image of x2 = kernel of mod 2: {}; mod 2 onto: {}",
        inj, py(mid), py(onto));
    assert!(inj == vec![0] && mid && onto);
    let r = 7;
    println!("ruler: {} half-metres = {} metres + leftover {}; half + half = {} half-metres = {} metre, leftover {}; split model (0, 1) + (0, 1) = ({}, {})",
        r, r / 2, r % 2, 1 + 1, (1 + 1) / 2, (1 + 1) % 2, 0, (1 + 1) % 2);
    // 2. not split: no section, no retraction, and Z has no member of order 2
    let sections: Vec<i64> = w().filter(|&y| 2 * y == 0 && md(y, 2) == 1).collect();
    let retractions: Vec<i64> = w().filter(|&c| 2 * c == 1).collect();
    let order2_z: Vec<i64> = w().filter(|&x| 2 * x == 0).collect();
    let order2_split: Vec<(i64, i64)> = w().flat_map(|x| [(x, 0), (x, 1)])
        .filter(|&(x, t)| 2 * x == 0 && md(2 * t, 2) == 0).collect();
    let split_sections: Vec<(i64, i64)> = order2_split.iter().copied().filter(|v| v.1 == 1).collect();
    println!("sections s with s(1) odd and 2 s(1) = 0: {} found; retractions r(x) = c x with r(2) = 1: {} found",
        sections.len(), retractions.len());
    println!("members killed by 2: in Z {}, in Z (+) Z/2 {}; split row sections: {:?}",
        order2_z.len(), order2_split.len(), split_sections);
    assert!(sections.is_empty() && retractions.is_empty() && order2_z.len() == 1 && order2_split.len() == 2);
    assert!(split_sections == vec![(0, 1)]);
    // 3. the snake on the row, multiplied by 2
    let (sizes, chase, exact) = snake(2, 2, true);
    println!("snake n = 2, m = 2: kernels {:?}, cokernels {:?}", &sizes[..3], &sizes[3..]);
    let y = 1;
    let x = w().find(|&x| 2 * x == 2 * y).unwrap();
    println!("  chase of the half: lift to {} half-metre, double to {}, pull back to {} metre, class {} (odd)", y, 2 * y, x, md(x, 2));
    let pulls: Vec<i64> = (-5..8).step_by(2).map(|y| w().find(|&x| 2 * x == 2 * y).unwrap()).collect();
    let pc: BTreeSet<i64> = pulls.iter().map(|&x| md(x, 2)).collect();
    println!("  pull-backs for the lifts -5, -3, ..., 7: {:?}, classes mod 2: {:?}", pulls, pc.iter().collect::<Vec<_>>());
    println!("  delta: {}; same class for lifts 1 + 2t, t = -3..3; exact at {} of 6 spots", dict(&chase), exact);
    assert!(sizes == vec![1, 1, 2, 2, 2, 2] && chase == vec![(0, 0), (1, 1)] && exact == 6);
    // alternating count: |ker a| |ker c| |coker b| = |ker b| |coker a| |coker c|
    let (lhs, rhs) = (sizes[0] * sizes[2] * sizes[4], sizes[1] * sizes[3] * sizes[5]);
    println!("  order count: {} * {} * {} = {}, {} * {} * {} = {}", sizes[0], sizes[2], sizes[4], lhs, sizes[1], sizes[3], sizes[5], rhs);
    assert!(lhs == rhs);
    // 4. the split row 0 -> Z -> Z (+) Z/2 -> Z/2 -> 0, also multiplied by 2: delta is zero
    let ker_b: Vec<(i64, i64)> = w().flat_map(|x| [(x, 0), (x, 1)]).filter(|&(x, _)| 2 * x == 0).collect();
    let img: BTreeSet<(i64, i64)> = bw().filter(|&x| 0 <= 2 * x && 2 * x < L).map(|x| (2 * x, 0)).collect();
    let sub: BTreeSet<i64> = (0..2).map(|z| md(2 * z, 2)).collect();
    let split_sizes = vec![w().filter(|&x| 2 * x == 0).count() as i64, ker_b.len() as i64,
        (0..2).filter(|&z| md(2 * z, 2) == 0).count() as i64, index_in_box(bw().map(|x| 2 * x)),
        2 * L / img.len() as i64, cosets(2, &sub).len() as i64];
    let mut d_split = BTreeSet::new();
    for t in -3..=3 {
        // lift 1 to (2t, 1), double it, pull back through x -> (x, 0)
        let doubled = (2 * (2 * t), md(2 * 1, 2));
        d_split.insert(md(w().find(|&x| (x, 0) == doubled).unwrap(), 2));
    }
    let ds: Vec<String> = d_split.iter().map(|v| v.to_string()).collect();
    println!("split row snake: kernels {:?}, cokernels {:?}, delta(1) = {{{}}}", &split_sizes[..3], &split_sizes[3..], ds.join(", "));
    assert!(split_sizes == vec![1, 2, 2, 2, 4, 2] && d_split == [0].into_iter().collect());
    // 5. the same snake on other rows: gcd(n, m) members in ker c and in coker c
    for (n, m) in [(4, 6), (2, 3)] {
        let (sizes, chase, exact) = snake(n, m, true);
        println!("snake n = {}, m = {}: kernels {:?}, cokernels {:?}, delta {}, exact at {} of 6",
            n, m, &sizes[..3], &sizes[3..], dict(&chase), exact);
        assert!(sizes[2] == gcd(n, m) && sizes[5] == gcd(n, m) && sizes[3] == m && sizes[4] == m && exact == 6);
    }
    // 6. what breaks
    let (_, _, exact0) = snake(2, 2, false);
    println!("mistake, no connecting map (delta = 0): exact at {} of 6 spots", exact0);
    assert!(exact0 == 4);
    println!("mistake, ends equal so middles equal: Z has {} member killed by 2, Z (+) Z/2 has {}", order2_z.len(), order2_split.len());
    let comp_zero = w().all(|x| md(4 * x, 2) == 0);
    let (i_img, i_ker) = (index_in_box(bw().map(|x| 4 * x)), index_in_box(bw().filter(|&y| md(y, 2) == 0)));
    let gap = i_img / i_ker;
    println!("mistake, composite zero only: x4 then mod 2 composes to zero: {}; image index {}, kernel index {}, {} classes left over",
        py(comp_zero), i_img, i_ker, gap);
    assert!(comp_zero && gap == 2);
    // five lemma: no map b from the twisted row to the split row with identity ends
    let maps: Vec<(i64, i64)> = w().flat_map(|p| [(p, 0), (p, 1)]).filter(|&(p, t)| (2 * p, md(2 * t, 2)) == (1, 0)).collect();
    println!("five lemma: maps b with b(1) = (p, t) and identity ends: {} found", maps.len());
    assert!(maps.is_empty());
    // hypothesis dropped: a = times 2, c = identity, b(x) = (x, x mod 2) commutes but is not onto
    let (f, g) = (|x: i64| 2 * x, |y: i64| md(y, 2)); // the twisted row
    let (f2, g2) = (|x: i64| (x, 0), |v: (i64, i64)| v.1); // the split row
    let (a, b, c) = (|x: i64| 2 * x, |y: i64| (y, md(y, 2)), |z: i64| z);
    let comm = w().all(|x| b(f(x)) == f2(a(x)) && g2(b(x)) == c(g(x)));
    let hit: BTreeSet<(i64, i64)> = bw().map(b).collect();
    let box_hits = hit.iter().filter(|v| 0 <= v.0 && v.0 < L).count() as i64;
    let missed = !hit.contains(&(0, 1));
    println!("mistake, five lemma with a = x2: b(x) = (x, x mod 2) commutes {}, misses (0, 1) {}, coker b has {} members",
        py(comm), py(missed), 2 * L / box_hits);
    assert!(comm && missed && 2 * L / box_hits == 2);
    println!("ALL CHECKS PASS");
}
