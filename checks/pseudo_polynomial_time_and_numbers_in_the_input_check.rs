// Pseudo-polynomial time -- the same check as the Python, in Rust with std only.
// A van carries at most 800 kg; five parcels, each taken whole or left.  Three
// roads to the best fee: the capacity table (counting cells), brute force over
// all 32 packings, and a list of reachable (weight, fee) pairs.  Then the same
// parcels in finer units: the answer stays, the table explodes.
const NAMES: [&str; 5] = ["tiles", "timber", "boiler", "piano", "fridge"];
const KG: [u64; 5] = [300, 400, 200, 500, 100];
const FEE: [u64; 5] = [90, 110, 70, 150, 40];
const VAN: u64 = 800;

fn bits(mut x: u64) -> u64 { // binary digits needed to write x (at least 1)
    let mut b = 1;
    while x > 1 { x /= 2; b += 1; }
    b
}
fn table(w: &[u64], v: &[u64], cap: u64) -> (Vec<u64>, u64) { // last row, cells filled
    let cap = cap as usize;
    let (mut row, mut cells) = (vec![0u64; cap + 1], (cap + 1) as u64);
    for i in 0..w.len() {
        let mut new = row.clone();
        for c in 0..=cap {
            cells += 1;
            let wi = w[i] as usize;
            if wi <= c && v[i] + row[c - wi] > new[c] { new[c] = v[i] + row[c - wi]; }
        }
        row = new;
    }
    (row, cells)
}
fn brute(w: &[u64], v: &[u64], cap: u64) -> (u64, usize) { // every one of the 2^k packings
    let (mut best, mut pick, mut found) = (0u64, 0usize, false);
    for s in 0..(1usize << w.len()) {
        let (mut tw, mut tv) = (0, 0);
        for i in 0..w.len() { if s >> i & 1 == 1 { tw += w[i]; tv += v[i]; } }
        if tw <= cap && (!found || tv > best) { best = tv; pick = s; found = true; }
    }
    (best, pick)
}
fn pairs(w: &[u64], v: &[u64], cap: u64) -> (u64, usize) { // reachable pairs, dominated dropped
    let (mut l, mut biggest) = (vec![(0u64, 0u64)], 1usize);
    for i in 0..w.len() {
        let mut m = l.clone();
        for &(a, b) in &l { if a + w[i] <= cap { m.push((a + w[i], b + v[i])); } }
        m.sort_by_key(|&(a, b)| (a, std::cmp::Reverse(b))); // by weight; at equal weight, highest fee first
        l = Vec::new();
        for (a, b) in m { if l.is_empty() || b > l[l.len() - 1].1 { l.push((a, b)); } } // keep a pair only if it pays more
        assert!(l.windows(2).all(|p| p[0].0 < p[1].0 && p[0].1 < p[1].1), "no kept pair is dominated");
        biggest = biggest.max(l.len());
    }
    (l[l.len() - 1].1, biggest)
}
fn size(w: &[u64], v: &[u64], cap: u64) -> u64 { // input length n: binary digits of every number
    w.iter().chain(v.iter()).map(|&x| bits(x)).sum::<u64>() + bits(cap)
}
fn names(pick: usize) -> String {
    (0..5).filter(|i| pick >> i & 1 == 1).map(|i| NAMES[i]).collect::<Vec<_>>().join(" + ")
}
fn join(v: &[String]) -> String { v.join(", ") }

fn main() {
    let list: Vec<String> = (0..5).map(|i| format!("{} {} kg {}", NAMES[i], KG[i], FEE[i])).collect();
    println!("van {} kg; {}", VAN, join(&list));
    let w100: Vec<u64> = KG.iter().map(|x| x / 100).collect();
    let (row, _) = table(&w100, &FEE, VAN / 100);
    for c in 0..9 { assert!(row[c] == brute(&w100, &FEE, c as u64).0, "table row vs brute force"); }
    let r: Vec<String> = row.iter().map(|x| x.to_string()).collect();
    println!("capacity table, 0 to 800 kg in 100 kg steps: {}", r.join(" "));
    let mut res = Vec::new();
    let mut pick = 0;
    for (unit, per) in [("100 kg", 1u64), ("1 kg", 100), ("1 g", 100000)] {
        let w: Vec<u64> = KG.iter().map(|x| x * per / 100).collect();
        let cap = VAN * per / 100;
        let (row, cells) = table(&w, &FEE, cap);
        let (bb, pk) = brute(&w, &FEE, cap);
        let (pp, big) = pairs(&w, &FEE, cap);
        let n = size(&w, &FEE, cap);
        res.push((n, cells));
        pick = pk;
        println!("unit {:>6}: W {:>6}, n {:>3} bits, cells {:>7} = 6 x {}; table {}, brute {}, pairs {} (list <= {})",
                 unit, cap, n, cells, cap + 1, row[cap as usize], bb, pp, big);
        let bw: Vec<String> = w.iter().map(|&x| bits(x).to_string()).collect();
        let bf: Vec<String> = FEE.iter().map(|&x| bits(x).to_string()).collect();
        println!("  binary digits: weights {} | van {} | fees {}", bw.join(" "), bits(cap), bf.join(" "));
        assert!(row[cap as usize] == bb && bb == pp && pp == 260, "three roads must agree");
        assert!(big as u64 <= (1u64 << w.len()).min(cap + 1), "the list stays within 2^k and W + 1");
        assert!(cells == (w.len() as u64 + 1) * (cap + 1), "counted cells must match (k+1)(W+1)");
    }
    println!("best packing: {} = 800 kg, 260", names(pick));
    println!("n grew {} -> {} bits (x{:.2}); cells grew {} -> {} (x{:.0})", res[0].0, res[2].0,
             res[2].0 as f64 / res[0].0 as f64, res[0].1, res[2].1, res[2].1 as f64 / res[0].1 as f64);
    let mut prev = 0u64;
    for j in 0..4 {
        let w: Vec<u64> = KG.iter().map(|x| x << j).collect();
        let cap = VAN << j;
        let (_, cells) = table(&w, &FEE, cap);
        assert!(brute(&w, &FEE, cap).0 == 260 && size(&w, &FEE, cap) == 87 + 6 * j);
        let ratio = cells as f64 / prev as f64;
        assert!(prev == 0 || (1.99 < ratio && ratio < 2.0), "one more bit per number doubles the table");
        let tail = if prev > 0 { format!(", ratio {:.4}", ratio) } else { String::new() };
        println!("doubled {} times: n {} bits, cells counted {}{}", j, size(&w, &FEE, cap), cells, tail);
        prev = cells;
    }
    println!("chart: j, n bits, cells (formula), log10 cells, n^3, log10 n^3");
    let (mut cc, mut cu) = (Vec::new(), Vec::new());
    let cnt: Vec<(u64, u64)> = [0u64, 10].iter().map(|&j| { let w: Vec<u64> = KG.iter().map(|x| x << j).collect(); (size(&w, &FEE, VAN << j), table(&w, &FEE, VAN << j).1) }).collect();
    for j in [0u64, 10, 20, 30, 40] {
        let (n, cells) = (87 + 6 * j, 6 * ((VAN << j) + 1));
        assert!(j > 10 || cnt[(j / 10) as usize] == (n, cells), "chart points 0 and 10 are counted tables");
        cc.push(format!("{:.2}", (cells as f64).log10()));
        cu.push(format!("{:.2}", ((n * n * n) as f64).log10()));
        println!("  {:>2} {:>3} {:>16} {:>5} {:>8} {}", j, n, cells, cc[cc.len() - 1], n * n * n, cu[cu.len() - 1]);
    }
    println!("chart line, table: {}", join(&cc));
    println!("chart line, n^3:   {}", join(&cu));
    assert!(cnt[0].1 < cnt[0].0.pow(3) && cnt[1].1 > cnt[1].0.pow(3), "counted tables: under n^3 at 87 bits, over it at 147");
    for (idx, (unit, per)) in [("1 kg", 100u64), ("1 g", 100000)].into_iter().enumerate() {
        let w: Vec<u64> = KG.iter().map(|x| x * per / 100).collect();
        let cap = VAN * per / 100;
        let (nu, (nb, cells)) = (w.iter().sum::<u64>() + FEE.iter().sum::<u64>() + cap, res[idx + 1]); // marks; binary length and cells counted above
        assert!(cells <= 6 * (nu + 1) && 6 * (nu + 1) <= (nu + 1) * (nu + 1), "unary length bounds the counted table");
        assert!(cells > 6 * (nb + 1), "the same bound fails against the binary length");
        println!("unary, unit {}: n {} marks, cells {} <= (k+1)(n+1) = {}; against binary n {}, (k+1)(n+1) = {} fails", unit, nu, cells, 6 * (nu + 1), nb, 6 * (nb + 1));
    }
    let tru = [330u64, 420, 240, 470, 140];
    let rnd: Vec<u64> = tru.iter().map(|x| (x + 50) / 100).collect();
    let (_, pk) = brute(&rnd, &FEE, VAN / 100);
    let load: u64 = (0..5).filter(|i| pk >> i & 1 == 1).map(|i| tru[i]).sum();
    let (exact, ep) = brute(&tru, &FEE, VAN);
    let (row, cells) = table(&tru, &FEE, VAN);
    assert!(row[VAN as usize] == exact && load > VAN);
    let ew: u64 = (0..5).filter(|i| ep >> i & 1 == 1).map(|i| tru[i]).sum();
    println!("rounded table packs {}: truly {} kg, {} kg over; exact best {} ({}, {} kg) in {} cells",
             names(pk), load, load - VAN, exact, names(ep), ew, cells);
    println!("counting parcels only: k = 5 for both {} and {} cells", res[0].1, res[2].1);
    let total: u64 = FEE.iter().sum();
    let (mut vr, mut vc) = (vec![1_000_000_000u64; total as usize + 1], 0u64); // least weight per exact fee
    vr[0] = 0;
    for i in 0..5 {
        for f in (0..=total as usize).rev() {
            vc += 1;
            let fi = FEE[i] as usize;
            if f >= fi && vr[f - fi] + KG[i] < vr[f] { vr[f] = vr[f - fi] + KG[i]; }
        }
    }
    let best_by_fee = (0..=total as usize).filter(|&f| vr[f] <= VAN).max().unwrap();
    assert!(best_by_fee == 260);
    println!("try: table by fee: best {}, cells {}; in pence {}", best_by_fee, vc + total + 1, 6 * (100 * total + 1));
    let (k2, f2): (Vec<u64>, Vec<u64>) = (KG.iter().chain(KG.iter()).cloned().collect(), FEE.iter().chain(FEE.iter()).cloned().collect());
    let (_, c10) = table(&k2, &f2, VAN);
    println!("try: ten parcels (each twice), 1 kg unit: cells {}, best {}", c10, brute(&k2, &f2, VAN).0);
    let dec = |x: u64| x.to_string().len() as u64;
    let d1: u64 = KG.iter().chain(FEE.iter()).map(|&x| dec(x)).sum::<u64>() + dec(VAN);
    let d2: u64 = KG.iter().map(|&x| dec(x * 1000)).sum::<u64>() + FEE.iter().map(|&x| dec(x)).sum::<u64>() + dec(VAN * 1000);
    println!("try: decimal digits: n {} at 1 kg, {} at 1 g", d1, d2);
    println!("ALL CHECKS PASS");
}
