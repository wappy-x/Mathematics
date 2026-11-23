// Sunflowers and union-closed families -- the check behind the card.
// std only. Sets are bitmasks: bit k set means point k is in.
// Every search is written out; asserts check instances and two roads agreeing.

fn pts(m: u64) -> String {                   // the points of a bitmask, from 1
    let v: Vec<String> = (0..31).filter(|k| m >> k & 1 == 1).map(|k| (k + 1).to_string()).collect();
    format!("[{}]", v.join(", "))
}
fn bits(ks: &[u64]) -> u64 { ks.iter().map(|k| 1u64 << (k - 1)).sum() }
fn flower(a: u64, b: u64, c: u64) -> bool { a & b == a & c && a & c == b & c }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn list(v: &[u64]) -> String {
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}
fn fact(n: u64) -> u64 { (1..=n).product() }
fn edges(n: u64) -> Vec<u64> {
    let mut e = vec![];
    for i in 1..=n { for j in i + 1..=n { e.push(bits(&[i, j])); } }
    e
}
fn brute(n: u64) -> u64 {                    // road 1: every set of edges
    let e = edges(n);
    let m = e.len();
    let mut bad = vec![];
    for i in 0..m { for j in i + 1..m { for k in j + 1..m {
        if flower(e[i], e[j], e[k]) { bad.push((1u64 << i) | (1 << j) | (1 << k)); }
    } } }
    (0..1u64 << m).filter(|s| bad.iter().all(|t| s & t != *t)).map(|s| s.count_ones() as u64).max().unwrap()
}
fn grow(e: &[u64], chosen: &mut Vec<u64>, start: usize, best: &mut usize) {
    *best = (*best).max(chosen.len());
    for i in start..e.len() {
        if chosen.len() + e.len() - i <= *best { return; }
        let mut ok = true;
        for a in 0..chosen.len() { for b in a + 1..chosen.len() {
            if flower(chosen[a], chosen[b], e[i]) { ok = false; }
        } }
        if ok { chosen.push(e[i]); grow(e, chosen, i + 1, best); chosen.pop(); }
    }
}
fn search(n: u64) -> u64 {                   // road 2: grow sunflower-free sets
    let e = edges(n);
    let mut best = 0;
    grow(&e, &mut vec![], 0, &mut best);
    best as u64
}
fn share(f: &[u64], n: u64) -> (u64, u64) {  // best element: (its count, |F|)
    let c = (0..n).map(|k| f.iter().filter(|s| *s >> k & 1 == 1).count() as u64).max().unwrap();
    (c, f.len() as u64)
}
fn h(q: f64) -> f64 { -q * q.log2() - (1.0 - q) * (1.0 - q).log2() }

fn main() {
    let (a, b, c) = (bits(&[1, 2, 3]), bits(&[1, 2, 4]), bits(&[1, 2, 5]));
    println!("routes {} {} {} cores {} {} {} sunflower {}", pts(a), pts(b), pts(c), pts(a & b), pts(a & c), pts(b & c), py(flower(a, b, c)));
    let (x, y, z) = (bits(&[1, 2, 3]), bits(&[1, 2, 4]), bits(&[1, 3, 4]));
    println!("near miss {} {} {} cores {} {} {} sunflower {}", pts(x), pts(y), pts(z), pts(x & y), pts(x & z), pts(y & z), py(flower(x, y, z)));
    assert!(flower(a, b, c) && !flower(x, y, z) && x & y & z == bits(&[1]));

    let er: Vec<u64> = (1..5).map(|w| fact(w) * (1u64 << w)).collect();
    println!("Erdos-Rado bound, p=3, w=1..4: {}", list(&er));
    assert_eq!(er, vec![2, 8, 48, 384]);

    let bf: Vec<u64> = (3..7).map(brute).collect();
    let se: Vec<u64> = (3..8).map(search).collect();
    println!("largest 3-sunflower-free graph, brute force, n=3..6: {}", list(&bf));
    println!("largest 3-sunflower-free graph, search, n=3..7: {}", list(&se));
    assert!(bf[..] == se[..4] && se == vec![3, 4, 5, 6, 6]);

    let t: Vec<u64> = [[1, 2], [1, 3], [2, 3], [4, 5], [4, 6], [5, 6]].iter().map(|p| bits(p)).collect();
    let extra: Vec<u64> = edges(6).into_iter().filter(|e| !t.contains(e)).collect();
    let mut hits = 0;
    for &e in &extra {
        let mut hit = false;
        for i in 0..t.len() { for j in i + 1..t.len() { if flower(t[i], t[j], e) { hit = true; } } }
        if hit { hits += 1; }
    }
    let star: Vec<String> = t.iter().filter(|&&s| s & bits(&[1, 4]) == bits(&[1])).take(2).map(|&s| pts(s)).collect();
    println!("two triangles: {} edges; missing edges that force a sunflower: {} of {}", t.len(), hits, extra.len());
    println!("seventh edge [1, 4] with [{}] core [1]", star.join(", "));
    assert!(hits == extra.len() && hits == 9);

    let mut p = vec![];
    for &u in &t { for &v in &t { p.push(u | v << 6); } }
    let (mut triples, mut trip) = (0u64, 0u64);
    for i in 0..p.len() { for j in i + 1..p.len() { for k in j + 1..p.len() {
        triples += 1;
        if flower(p[i], p[j], p[k]) { trip += 1; }
    } } }
    println!("product family, w=4: {} sets, {} triples, sunflowers among them: {}", p.len(), triples, trip);
    assert!(p.len() == 36 && trip == 0);

    println!("log10 bars, p=3: w, construction 6^(w/2), Erdos-Rado w!2^w");
    for w in (2..11).step_by(2) {
        let (lo, hi) = (6u64.pow(w as u32 / 2), fact(w) * (1u64 << w));
        println!("w={:2} {:6} {:.3} {:11} {:.3}", w, lo, (lo as f64).log10(), hi, (hi as f64).log10());
    }

    let mut u = vec![];
    for &x in &[0, a] { for &y in &[0, b] { for &z in &[0, c] {
        let s = x | y | z;
        if s != 0 && !u.contains(&s) { u.push(s); }
    } } }
    let cnt: Vec<u64> = (0..5).map(|k| u.iter().filter(|s| *s >> k & 1 == 1).count() as u64).collect();
    println!("route combinations: {} sets; stop counts 1..5: {}", u.len(), list(&cnt));
    assert!(u.iter().all(|x| u.iter().all(|y| u.contains(&(x | y)))) && cnt == vec![7, 7, 4, 4, 4]);

    for n in 1..5u64 {
        let (mut total, mut withe, mut sing, mut ok) = (0, 0, 0, true);
        let mut worst = (1u64, 1u64);
        for f in 0..1u64 << (1 << n) {
            let fam: Vec<u64> = (0..1u64 << n).filter(|s| f >> s & 1 == 1).collect();
            if !fam.iter().all(|x| fam.iter().all(|y| f >> (x | y) & 1 == 1)) { continue; }
            total += 1;
            if fam.contains(&0) { withe += 1; }
            if fam.iter().any(|&s| s != 0) {
                let sh = share(&fam, n);
                if sh.0 * worst.1 < worst.0 * sh.1 { worst = sh; }
            }
            if fam.iter().any(|s| s.count_ones() == 1) {
                sing += 1;
                for &x in fam.iter().filter(|s| s.count_ones() == 1) {
                    if 2 * fam.iter().filter(|&&s| s & x != 0).count() < fam.len() { ok = false; }
                }
            }
        }
        println!("n={}: union-closed families {}, with empty set {}, lowest best share {}/{}, singleton rule holds in {}: {}",
                 n, total, withe, worst.0, worst.1, sing, py(ok));
        assert!(2 * withe == total && 2 * worst.0 == worst.1 && ok);
    }

    for f in [vec![bits(&[1]), bits(&[2]), bits(&[3])], vec![0]] {
        let (c, m) = share(&f, 3);
        let shown: Vec<String> = f.iter().map(|&s| pts(s)).collect();
        println!("breaks: [{}] best share {}/{} = {:.6}", shown.join(", "), c, m, c as f64 / m as f64);
    }

    let (mut lo, mut hi) = (0.1f64, 0.45f64);  // H(2p-p^2) - H(p): + at 0.1, - at 0.45
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if h(2.0 * mid - mid * mid) > h(mid) { lo = mid; } else { hi = mid; }
    }
    let exact = (3.0 - 5f64.sqrt()) / 2.0;
    println!("entropy crossing: bisection {:.12}, closed form (3-sqrt5)/2 {:.12}, H there {:.12}", lo, exact, h(exact));
    assert!((lo - exact).abs() < 1e-12 && (2.0 * exact - exact * exact - (1.0 - exact)).abs() < 1e-15);
    println!("Gilmer 0.01, a week later {:.5}, Frankl asks 0.5", exact);
    let cen: Vec<String> = [270.0f64, 30.0, 150.0].iter()   // the figure: petal centres 75 px out
        .map(|d| format!("({:.1},{:.1})", 210.0 + 75.0 * d.to_radians().cos(), 170.0 + 75.0 * d.to_radians().sin())).collect();
    println!("figure, centre (210,170), core radius 34, petal centres 75 px out: {}", cen.join(" "));
    println!("ALL CHECKS PASS");
}
