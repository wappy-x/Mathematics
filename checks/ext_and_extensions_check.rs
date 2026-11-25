// Ext and extensions -- the same check as the Python, in Rust.  No crates.
// Ext^i(Z/m, N) over the integers, by four roads that share no step: the short
// free resolution, a wider free resolution, an injective resolution through
// Q/Z, and a brute-force count of the extensions themselves as symmetric carry
// rules (cocycles).  Then the glued groups E, the universal coefficient theorem
// on a disc glued four times round a loop, the ring Z/4, and what breaks.
use std::collections::BTreeSet;

fn gcd(a: i64, b: i64) -> i64 {
    let (mut a, mut b) = (a.abs(), b.abs());
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn sizes<T: Ord + Clone>(dom: &[T], f: &dyn Fn(&T) -> T, zero: &T) -> (usize, usize) {
    let image: BTreeSet<T> = dom.iter().map(|x| f(x)).collect();   // kernel and cokernel sizes
    let kernel = dom.iter().filter(|x| f(x) == *zero).count();
    (kernel, dom.len() / image.len())
}

fn road_short(m: i64, n: i64) -> (usize, usize) {       // the map Z/n --m--> Z/n
    let dom: Vec<i64> = (0..n).collect();
    sizes(&dom, &|x| m * x % n, &0)
}

fn road_wide(m: i64, n: i64) -> (usize, usize) {        // Z^2 --(1,-1),(m,0)--> Z^2 -> Z/m
    let dom: Vec<(i64, i64)> = (0..n).flat_map(|u| (0..n).map(move |v| (u, v))).collect();
    sizes(&dom, &|p| ((p.0 - p.1).rem_euclid(n), m * p.0 % n), &(0, 0))
}

fn road_injective(m: i64, n: i64) -> (usize, usize) {   // Hom(Z/m, Q/Z) --n--> itself; k means k/m
    let dom: Vec<i64> = (0..m).collect();
    sizes(&dom, &|k| n * k % m, &0)
}

fn road_z(m: i64) -> (usize, usize) {                   // N = Z by 0 -> Z -> Q -> Q/Z, fractions a/b with b <= 12
    let hom_q: BTreeSet<(i64, i64)> = (1..=12).flat_map(|b| (-12..=12).map(move |a| (a, b)))
        .filter(|&(a, b)| m * a == 0 && gcd(a, b) == 1).collect();
    let hom_qz: BTreeSet<(i64, i64)> = (1..=12).flat_map(|b| (0..b).map(move |a| (a, b)))
        .filter(|&(a, b)| m * a % b == 0).map(|(a, b)| (a / gcd(a, b), b / gcd(a, b))).collect();
    let image: BTreeSet<(i64, i64)> = hom_q.iter().map(|&(a, b)| (a.rem_euclid(b), b)).collect();
    (hom_q.iter().filter(|&&(_, b)| b == 1).count(), hom_qz.len() / image.len())
}

fn road_cocycles(m: usize, n: i64) -> (usize, usize, usize, usize) {
    let pairs: Vec<(usize, usize)> = (1..m).flat_map(|a| (a..m).map(move |b| (a, b))).collect();
    let (mut count, mut vals) = (0usize, vec![0i64; pairs.len()]);
    loop {                                               // every table of values, as a counter in base n
        let mut t = vec![vec![0i64; m]; m];
        for (k, &(a, b)) in pairs.iter().enumerate() { t[a][b] = vals[k]; t[b][a] = vals[k]; }
        let ok = (1..m).all(|a| (1..m).all(|b| (1..m).all(|c|
            (t[a][b] + t[(a + b) % m][c] - t[b][c] - t[a][(b + c) % m]).rem_euclid(n) == 0)));
        if ok { count += 1 }
        let mut i = 0;
        while i < vals.len() && vals[i] == n - 1 { vals[i] = 0; i += 1 }
        if i == vals.len() { break }
        vals[i] += 1;
    }
    let (mut bounds, mut homs) = (BTreeSet::new(), 0usize);   // coboundaries of g with g(0) = 0
    for code in 0..n.pow(m as u32 - 1) {
        let mut g = vec![0i64];
        for j in 0..(m as u32 - 1) { g.push(code / n.pow(j) % n) }
        let d: Vec<i64> = pairs.iter().map(|&(a, b)| (g[a] + g[b] - g[(a + b) % m]).rem_euclid(n)).collect();
        if d.iter().all(|&x| x == 0) { homs += 1 }
        bounds.insert(d);
    }
    (homs, count / bounds.len(), count, bounds.len())
}

fn glued(n0: i64, c: i64, m: i64) -> String {           // E = (N + Z) / <(c, -m)>, by Smith form
    let (d1, det) = (gcd(gcd(n0, c), m), (n0 * m).abs());
    let mut parts: Vec<String> = if det == 0 { vec!["Z".to_string()] } else { vec![] };
    for d in [d1, if det != 0 { det / d1 } else { 0 }] { if d > 1 { parts.push(format!("Z/{}", d)) } }
    if parts.is_empty() { "0".to_string() } else { parts.join(" + ") }
}

fn name(k: usize) -> String { if k == 1 { "0".to_string() } else { format!("Z/{}", k) } }

fn window() -> std::ops::RangeInclusive<i64> { -60..=60 }

fn main() {
    println!("Ext(Z/m, N) by four roads: |Hom| |Ext^1|, then the counts behind the last road");
    let cases: [(i64, i64); 3] = [(4, 6), (4, 9), (3, 3)];
    let mut results = Vec::new();
    for &(m, n) in &cases {
        let (a, b, c, d) = (road_short(m, n), road_wide(m, n), road_injective(m, n), road_cocycles(m as usize, n));
        println!("Z/{} by Z/{}: short {} {}; wide {} {}; injective {} {}; carries {} {} ({} cocycles / {} coboundaries)",
                 m, n, a.0, a.1, b.0, b.1, c.0, c.1, d.0, d.1, d.2, d.3);
        results.push((a, b, c, d));
    }
    println!("Z/4 by Z/6, times 4 on Z/6: {:?}, kernel {:?}, image {:?}", (0..6).map(|x| 4 * x % 6).collect::<Vec<i64>>(),
             (0..6).filter(|x| 4 * x % 6 == 0).collect::<Vec<i64>>(), (0..6).map(|x| 4 * x % 6).collect::<BTreeSet<i64>>().into_iter().collect::<Vec<i64>>());
    for m in [2i64, 3, 4] {                              // N = Z: coker of Z --m--> Z
        let res: BTreeSet<i64> = window().map(|x| x.rem_euclid(m)).collect();
        let homz = window().filter(|x| m * x == 0).count() - 1;
        let (hz, ez) = road_z(m);
        println!("Ext^1(Z/{}, Z): Z/{}Z has {} elements, through Q/Z {}; Hom(Z/{}, Z) = {} nonzero maps, through Q {}",
                 m, m, res.len(), ez, m, homz, hz - 1);
    }
    println!("the glued groups E_c = (N + Z)/<(c, -m)>: c, its class, E");
    for (n0, m) in [(0i64, 2i64), (0, 3), (6, 4), (9, 4), (3, 3)] {
        let nn = if n0 != 0 { n0 } else { m };
        let rows: Vec<String> = (0..nn).map(|c| format!("{}:{}:{}", c, c % gcd(nn, m), glued(n0, c, m))).collect();
        let nname = if n0 == 0 { "Z".to_string() } else { format!("Z/{}", n0) };
        println!("Z/{} by {}: {}", m, nname, rows.join(", "));
    }
    let s_ok: Vec<i64> = [1i64, -1].into_iter()
        .filter(|&s| s * 3 == 3 && (0..3).all(|z: i64| (2 * s * z).rem_euclid(3) == z % 3)).collect();
    println!("equivalences between c = 1 and c = 2 for Z/3 by Z (s = +1 or -1): {}", s_ok.len());
    println!("disc glued 4 times round a loop: H_0 = Z, H_1 = Z/4, H_2 = 0");
    for n in [6i64, 9] {
        let (h1, h2) = road_short(4, n);
        let (hom, ext) = road_injective(4, n);
        println!("coefficients Z/{}: cochains H^1 = {}, H^2 = {}; Hom(H_1) + Ext(H_0) = {} + 0, Hom(H_2) + Ext(H_1) = 0 + {}",
                 n, name(h1), name(h2), name(hom), name(ext));
    }
    let z1 = window().filter(|x| 4 * x == 0).count();          // cochains Z --0--> Z --4--> Z
    let z2 = window().map(|x| x.rem_euclid(4)).collect::<BTreeSet<i64>>().len();
    let (hz, ez) = road_z(4);                                   // Hom(H_1, Z) and Ext(H_1, Z), through Q and Q/Z
    println!("coefficients Z: cochains H^1 = {}, H^2 = {}; Hom(H_1) + Ext(H_0) = {} + 0, Hom(H_2) + Ext(H_1) = 0 + {}",
             name(z1), name(z2), name(hz), name(ez));
    let im2: BTreeSet<i64> = (0..4).map(|x| 2 * x % 4).collect();     // ring Z/4, times 2
    let ker2: BTreeSet<i64> = (0..4).filter(|x| 2 * x % 4 == 0).collect();
    let exact = im2 == ker2;
    let homs: Vec<i64> = (0..2).filter(|v| 4 * v % 2 == 0).collect();
    let ds = [2i64; 6];                                         // d_1 .. d_6, each times 2; Hom(d_i) precomposes
    let ext_z4: Vec<usize> = (0..5).map(|i| {                   // Ext^i = kernel of Hom(d_(i+1)) / image of Hom(d_i)
        let kept = homs.iter().filter(|&&v| ds[i] * v % 2 == 0).count();
        kept / if i > 0 { homs.iter().map(|&v| ds[i - 1] * v % 2).collect::<BTreeSet<i64>>().len() } else { 1 }
    }).collect();
    println!("ring Z/4: kernel of 2 = image of 2: {}; Ext^0..Ext^4(Z/2, Z/2) sizes {:?}", if exact { "yes" } else { "no" }, ext_z4);
    let fake = window().filter(|x| 4 * x == 0).count() - 1;
    println!("mistake 1, 0 -> Z/2 -> Z/4 -> Z/2 as a resolution: Hom(Z/4, Z) has {} nonzero maps, so it reads Ext^1(Z/2, Z) = 0, not Z/2", fake);
    let mids: BTreeSet<String> = (0..3).map(|c| glued(0, c, 3)).collect();
    let classes3 = road_z(3).1;                                 // Ext^1(Z/3, Z), through Q/Z
    println!("mistake 2, Z/3 by Z counted by the group E: {} groups, but {} classes", mids.len(), classes3);
    let same = (0..9).map(|c| glued(9, c, 4)).collect::<BTreeSet<String>>().len();
    println!("mistake 3, Z/4 by Z/9 read as no extension: there is {}, the split one; all 9 values of c give {} group, Z/9 + Z/4 = {}",
             (results[1].0).1, same, glued(9, 0, 4));
    println!("mistake 4, over Z/4 Ext^2(Z/2, Z/2) has {} elements, not 1; Ext^1(Z, Z/2) = 0 since Z is free", ext_z4[2]);
    let h2z = window().filter(|x| 4 * x == 0).count();         // H_2 = kernel of the boundary x4 = 0
    println!("mistake 5, H^2(disc glued 4 times; Z) as Hom(H_2, Z) alone: {}, not {}", name(h2z), name(z2));
    for (k, &(m, n)) in cases.iter().enumerate() {
        let (a, b, c, d) = results[k];
        let g = gcd(m, n) as usize;
        assert!([a, b, c, (d.0, d.1)].iter().all(|&x| x == (g, g)));   // four roads, one answer
        assert!(d.2 == d.3 * g);                                       // cocycles = coboundaries x |Ext|
    }
    assert!(glued(0, 0, 2) == "Z + Z/2" && glued(0, 1, 2) == "Z");    // split and times-2
    assert!((0..6).map(|c| glued(6, c, 4)).collect::<BTreeSet<String>>().len() == 2 && glued(6, 1, 4) == "Z/24");
    assert!(glued(6, 0, 4) == "Z/2 + Z/12" && glued(6, 2, 4) == "Z/2 + Z/12");   // 2 is in 4N: split
    assert!(mids.len() == 2 && classes3 == 3 && s_ok.is_empty() && same == 1 && (z1, z2) == (hz, ez));   // cochains = UCT
    assert!([2i64, 3, 4].iter().all(|&m| road_z(m) == (1, m as usize)));   // Hom(Z/m, Z) = 0, Ext^1 = Z/m
    assert!(exact && ext_z4 == vec![2; 5] && fake == 0);
    println!("ALL CHECKS PASS");
}
