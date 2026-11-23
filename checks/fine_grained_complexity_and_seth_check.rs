// Fine-grained complexity and SETH -- the same check as the Python, in Rust.
// No crates.  Edit distance is computed two ways (the quadratic table and a
// diagonal search that never fills the table), and the first link of the SETH
// chain, CNF-SAT to orthogonal vectors by split and list, is built and checked
// against brute force over every assignment.  The second link's gadgets, from
// orthogonal vectors to edit distance, are built and measured on the same vectors.
use std::collections::HashMap;

fn ed_table(x: &[u8], y: &[u8]) -> Vec<Vec<usize>> {          // road one: the quadratic table
    let mut t = vec![vec![0usize; y.len() + 1]; x.len() + 1];
    for i in 0..=x.len() { t[i][0] = i }
    for j in 0..=y.len() { t[0][j] = j }
    for i in 1..=x.len() {
        for j in 1..=y.len() {
            let sub = t[i - 1][j - 1] + (x[i - 1] != y[j - 1]) as usize;
            t[i][j] = (t[i - 1][j] + 1).min(t[i][j - 1] + 1).min(sub);
        }
    }
    t
}

fn ed_diag(x: &[u8], y: &[u8]) -> (i64, i64) {                // road two: furthest reach per diagonal
    let (n, m) = (x.len() as i64, y.len() as i64);
    let mut cells = 0i64;
    let slide = |mut i: i64, k: i64, cells: &mut i64| {
        *cells += 1;
        while i < n && i + k < m && x[i as usize] == y[(i + k) as usize] { i += 1; *cells += 1 }
        i
    };
    let mut reach: HashMap<i64, i64> = HashMap::new();
    reach.insert(0, slide(0, 0, &mut cells));
    let mut d = 0i64;
    while *reach.get(&(m - n)).unwrap_or(&-1) < n {
        d += 1;
        let mut new = HashMap::new();
        for k in -d.min(n)..=d.min(m) {
            let g = |q: i64| *reach.get(&q).unwrap_or(&-9);
            let best = (g(k) + 1).max(g(k + 1) + 1).max(g(k - 1));
            new.insert(k, slide(best.min(n).min(m - k).max(-k).max(0), k, &mut cells));
        }
        reach = new;
    }
    (d, cells)
}

fn splitmix(state: u64) -> (u64, u64) {                        // SplitMix64, seed stated below
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

const F: [[i64; 3]; 8] = [[1, 2, 4], [-1, 3, 5], [1, -2, 6], [1, 2, -4], [1, -2, -6], [-1, 2, -5], [-1, -2, -5], [-1, -2, 5]];

fn true_lit(l: i64, bits: &[i64], first: i64) -> bool {        // is literal l true under these bits?
    let v = l.abs() - first;
    v >= 0 && v < bits.len() as i64 && (bits[v as usize] == 1) == (l > 0)
}
fn vector(bits: &[i64], first: i64, flip: bool) -> Vec<i64> {  // coordinate j is 1 when clause j is open
    F.iter().map(|c| ((c.iter().any(|&l| true_lit(l, bits, first))) == flip) as i64).collect()
}
fn join(v: &[i64]) -> String { v.iter().map(|b| b.to_string()).collect() }
fn dot0(p: &[i64], q: &[i64]) -> bool { p.iter().zip(q).map(|(a, b)| a * b).sum::<i64>() == 0 }

fn main() {
    let (x, y) = ("GATTACA", "GCATGCA");
    let t = ed_table(x.as_bytes(), y.as_bytes());
    println!("hand pair {} against {}, table rows (row i = first i letters of {}):", x, y, x);
    for row in &t { println!("  {}", row.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" ")) }
    let (dd, dcells) = ed_diag(x.as_bytes(), y.as_bytes());
    println!("edit distance: table {}, diagonal road {}; cells: table {}, diagonal {}", t[7][7], dd, x.len() * y.len(), dcells);
    let b4 = ["A", "C", "G", "T"];
    let mut words: Vec<String> = vec![String::new()];
    for a in b4 { for b in b4 { for c in b4 { words.push(format!("{}{}{}", a, b, c)) } } }
    let mut short: Vec<String> = words[1..].iter().flat_map(|w| vec![w[..1].to_string(), w[..2].to_string()]).collect();
    short.sort(); short.dedup(); words.extend(short);
    let agree = words.iter().all(|u| words.iter().all(|v|
        ed_table(u.as_bytes(), v.as_bytes())[u.len()][v.len()] as i64 == ed_diag(u.as_bytes(), v.as_bytes()).0));
    println!("every pair of DNA strings up to 3 letters ({} strings, {} pairs): roads agree {}", words.len(), words.len() * words.len(), if agree { "yes" } else { "no" });
    for (name, n) in [("virus genome", 30000u64), ("bacterial genome", 4600000), ("human genome", 3100000000), ("visitor log", 10000000)] {
        println!("table cells for two {}s, n = {}: n^2 = {}", name, n, n * n);
    }
    let (mut s, mut a) = (2026u64, Vec::new());                // two 1,000-base strands from seed 2026
    for _ in 0..2000 { let (s2, r) = splitmix(s); s = s2; a.push(b"ACGT"[(r % 4) as usize]) }
    let u: Vec<u8> = a[..1000].to_vec();
    let mut v = u.clone();
    for _ in 0..3 {                                            // three point mutations
        let (s2, r) = splitmix(s); s = s2;
        let p = (r % 1000) as usize;
        let old = b"ACGT".iter().position(|&c| c == v[p]).unwrap() as u64;
        v[p] = b"ACGT"[((old + 1 + (r >> 8) % 3) % 4) as usize];
    }
    let w: Vec<u8> = a[1000..].to_vec();
    let (near_t, (near_d, near_c)) = (ed_table(&u, &v)[1000][1000] as i64, ed_diag(&u, &v));
    let (far_t, (far_d, far_c)) = (ed_table(&u, &w)[1000][1000] as i64, ed_diag(&u, &w));
    println!("3 mutations in 1000 bases: distance {} (table) {} (diagonal); cells 1000000 against {}", near_t, near_d, near_c);
    println!("two unrelated 1000-base strands: distance {} (table) {} (diagonal); cells 1000000 against {}", far_t, far_d, far_c);

    let n_vars = 6u32;
    let halves: Vec<Vec<i64>> = (0..8).map(|b: i64| vec![b >> 2 & 1, b >> 1 & 1, b & 1]).collect();
    let av: Vec<Vec<i64>> = halves.iter().map(|h| vector(h, 1, false)).collect();
    let bv: Vec<Vec<i64>> = halves.iter().map(|h| vector(h, 4, false)).collect();
    let lit = |l: i64| format!("{}x{}", if l > 0 { "" } else { "~" }, l.abs());
    println!("formula: {}", F.iter().map(|c| format!("({})", c.iter().map(|&l| lit(l)).collect::<Vec<_>>().join(" | "))).collect::<Vec<_>>().join(" & "));
    let show = |vs: &Vec<Vec<i64>>| (0..8).map(|i| format!("{}:{}", join(&halves[i]), join(&vs[i]))).collect::<Vec<_>>().join(" ");
    println!("A vectors (x1 x2 x3): {}", show(&av));
    println!("B vectors (x4 x5 x6): {}", show(&bv));
    let mut brute = Vec::new();
    let mut ortho = Vec::new();
    for i in 0..8 {
        for j in 0..8 {
            let full: Vec<i64> = halves[i].iter().chain(halves[j].iter()).copied().collect();
            if F.iter().all(|c| c.iter().any(|&l| true_lit(l, &full, 1))) { brute.push(join(&full)) }
            if dot0(&av[i], &bv[j]) { ortho.push(join(&full)) }
        }
    }
    println!("brute force over {} assignments: {} satisfy; orthogonal pairs among {}: {}", 1u64 << n_vars, brute.len(), av.len() * bv.len(), ortho.len());
    println!("satisfying assignments: {}", brute.join(" "));
    let af: Vec<Vec<i64>> = halves.iter().map(|h| vector(h, 1, true)).collect();
    let bf: Vec<Vec<i64>> = halves.iter().map(|h| vector(h, 4, true)).collect();
    let flipped = (0..8).map(|i| (0..8).filter(|&j| dot0(&af[i], &bf[j])).count()).sum::<usize>();
    println!("mistake 1, coordinate 1 when the clause is satisfied: {} orthogonal pairs, not {}", flipped, brute.len());

    let (g1, g2) = (["201112", "200012"], ["200112", "211112"]); // Backurs-Indyk coordinate gadgets for a 0 and a 1, runs of 2s cut to 1
    let ed = |p: &str, q: &str| ed_table(p.as_bytes(), q.as_bytes())[p.len()][q.len()] as i64;
    let cg: Vec<i64> = (0..4).map(|k| ed(g1[k / 2], g2[k % 2])).collect();
    let glue = |g: &[&str; 2], v: &[i64]| v.iter().map(|&c| g[c as usize]).collect::<String>();
    let (r3, r4) = ("3".repeat(20), "4".repeat(20));
    let vg1 = |a: &[i64]| format!("{}{}{}{}{}", r4, glue(&g1, &[&[0i64][..], a].concat()), r3, glue(&g1, &[1, 0, 0, 0, 0, 0, 0, 0, 0]), r4);
    let vg2 = |b: &[i64]| format!("{}{}{}", r3, glue(&g2, &[&[1i64][..], b].concat()), r3);
    let mut pairs = Vec::new(); // (dot product, joined gadgets' distance, vector gadgets' distance), all 64 pairs
    for i in 0..8 { for j in 0..8 { pairs.push((av[i].iter().zip(&bv[j]).map(|(p, q)| p * q).sum::<i64>(), ed(&glue(&g1, &av[i]), &glue(&g2, &bv[j])), ed(&vg1(&av[i]), &vg2(&bv[j])))) } }
    let (l9, e_s) = (9 * g1[0].len() as i64, 2 * 20 + 9 * g1[0].len() as i64 + 9); // the paper's 2 l1 + l + d, with d = 9 places
    println!("coordinate gadgets: A 0 {}, A 1 {}, B 0 {}, B 1 {}; distances 0-0 0-1 1-0 1-1: {}", g1[0], g1[1], g2[0], g2[1], cg.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "));
    let (lo_j, hi_j) = (pairs.iter().map(|p| p.1).min().unwrap(), pairs.iter().map(|p| p.1).max().unwrap());
    println!("joined gadgets: {} against {} (dot 0) {}, against {} (dot 1) {}; all 64 pairs 8 + 2 x shared 1s, from {} to {}", join(&av[5]), join(&bv[0]), pairs[40].1, join(&bv[2]), pairs[42].1, lo_j, hi_j);
    let set = |k: bool| { let mut v: Vec<i64> = pairs.iter().filter(|p| (p.0 > 0) == k).map(|p| p.2).collect(); v.sort(); v.dedup(); v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") };
    println!("vector gadgets, runs of 20, second set for {}, {} letters per 9 places: distance {} on all {} orthogonal pairs, {} on all {} others; formula 2 x 20 + {} + 9 = {}",
             join(&[1, 0, 0, 0, 0, 0, 0, 0, 0]), l9, set(false), pairs.iter().filter(|p| p.0 == 0).count(), set(true), pairs.iter().filter(|p| p.0 > 0).count(), l9, e_s);

    let (eps, nn) = (0.1f64, 60u32);
    println!("N = {}: brute force 2^{} = {}; split gives n = 2^{} = {} vectors per side", nn, nn, 1u64 << nn, nn / 2, 1u64 << (nn / 2));
    println!("edit distance in n^{:.1} would give SAT in 2^{:.1} = {} times a polynomial, {} times fewer", 2.0 - eps, (1.0 - eps / 2.0) * nn as f64, 1u64 << 57, (1u64 << nn) / (1u64 << 57));
    println!("mistake 2, split 10 and 50: pad to n = 2^50, so n^{:.1} = 2^{:.1}, worse than 2^{}", 2.0 - eps, 50.0 * (2.0 - eps), nn);
    println!("mistake 3, near-identical strands: diagonal road {} cells, {} times fewer than the table", near_c, 1000000 / near_c);
    let ns: Vec<f64> = (3..10).map(|e| 10f64.powi(e)).collect();
    let line = |f: &dyn Fn(f64) -> f64| ns.iter().map(|&n| format!("{:.2}", f(n))).collect::<Vec<_>>().join(", ");
    println!("chart n: {}", (3..10).map(|e| format!("10^{}", e)).collect::<Vec<_>>().join(", "));
    println!("chart log10 n^2: {}", line(&|n| 2.0 * n.log10()));
    println!("chart log10 n^2/log2 n: {}", line(&|n| 2.0 * n.log10() - n.log2().log10()));
    println!("chart log10 n^1.9: {}", line(&|n| 1.9 * n.log10()));
    let (mut lo, mut hi) = (10.0f64, 200.0f64);                 // n = 2^s with n^0.1 = log2 n, by bisection
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if 0.1 * mid < mid.log2() { lo = mid } else { hi = mid }
    }
    println!("n^1.9 drops below n^2/log2 n only past n = 2^{:.1}", lo);

    let mut bs = brute.clone(); bs.sort();
    let mut os = ortho.clone(); os.sort();
    assert!(t[7][7] == 3 && dd == 3 && agree);                 // two roads, hand pair and all short pairs
    assert!(near_t == near_d && far_t == far_d && near_t <= 3); // two roads on 1,000-base strands
    assert!(bs == os && brute.len() == 4);                     // split and list matches brute force
    assert!(flipped != brute.len() && near_c * 50 < 1000000);  // the broken versions really break
    assert!(cg == vec![1, 1, 1, 3] && pairs.iter().all(|p| p.1 == 8 + 2 * p.0)); // coordinate and joined gadgets
    assert!(pairs.iter().all(|p| p.2 == e_s + 2 * p.0.min(1)));  // the paper's vector-gadget formula, every pair
    assert!(58.0 < lo && lo < 60.0 && (0.1 * lo - lo.log2()).abs() < 1e-6); // crossover where n^0.1 = log2 n
    println!("ALL CHECKS PASS");
}
