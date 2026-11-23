// Interactive proofs -- the same check as the Python, in Rust.  No crates.
// Stations A to F are 0 to 5.  RING and TOURIST are one network drawn twice
// (the Graphs card); DECOY has the same station and line counts and tally.
use std::collections::{HashMap, HashSet};
type Map = [(usize, usize); 8];
const RING: Map = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
const TOURIST: Map = [(0, 2), (0, 4), (0, 5), (1, 4), (1, 5), (2, 3), (3, 4), (3, 5)];
const DECOY: Map = [(0, 1), (0, 2), (1, 2), (1, 4), (2, 5), (3, 4), (3, 5), (4, 5)];
const ID: [usize; 6] = [0, 1, 2, 3, 4, 5];
const P: u64 = (1 << 31) - 1; const H: u64 = 1 << 30; // field size; H is 1/2 mod P
struct Rng(u64); // SplitMix64, written out
impl Rng {
    fn below(&mut self, n: u64) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) % n
    }
}
fn perms(items: &[usize]) -> Vec<Vec<usize>> { // all 720 renamings, generated here
    if items.is_empty() { return vec![vec![]]; }
    let mut out = vec![];
    for i in 0..items.len() {
        let mut rest = items.to_vec(); let x = rest.remove(i);
        for r in perms(&rest) { let mut v = vec![x]; v.extend(r); out.push(v); }
    }
    out
}
fn mask(e: &[(usize, usize)], pi: &[usize]) -> u64 { // a renamed map as a set of bits
    e.iter().map(|&(a, b)| 1u64 << (pi[a].min(pi[b]) * 6 + pi[a].max(pi[b]))).sum()
}
fn tally(e: &Map) -> Vec<usize> {
    let mut t: Vec<usize> = (0..6).map(|v| e.iter().filter(|p| p.0 == v || p.1 == v).count()).collect(); t.sort(); t
}
fn triangles(e: &Map) -> usize {
    let s = mask(e, &ID); let bit = |a: usize, b: usize| s & (1u64 << (a * 6 + b)) != 0;
    (0..216).filter(|&t| { let (a, b, c) = (t / 36, t / 6 % 6, t % 6); a < b && b < c && bit(a, b) && bit(a, c) && bit(b, c) }).count()
}
fn shuffle(rng: &mut Rng) -> Vec<usize> { // Fisher-Yates: a random renaming
    let mut p: Vec<usize> = (0..6).collect();
    for i in (1..6).rev() { let j = rng.below(i as u64 + 1) as usize; p.swap(i, j); } p
}
fn round_ok(rng: &mut Rng, maps: [&Map; 2], answer: &dyn Fn(u64) -> u64, shuffled: bool) -> bool {
    let b = rng.below(2);
    let pi = if shuffled { shuffle(rng) } else { ID.to_vec() };
    answer(mask(maps[b as usize], &pi)) == b
}
fn chi(pt: &[u64]) -> [u64; 8] { // weight of each 3-bit corner at a point
    let mut w = [0u64; 8];
    for c in 0..8 {
        let mut x = 1u64;
        for i in 0..3 { x = x * (if (c >> (2 - i)) & 1 == 1 { pt[i] } else { (1 + P - pt[i]) % P }) % P; }
        w[c] = x;
    }
    w
}
fn at_(a: &[[u64; 8]; 8], x: &[u64], y: &[u64]) -> u64 { // the adjacency table, extended smoothly
    let (cx, cy) = (chi(x), chi(y));
    (0..64).map(|t| a[t / 8][t % 8] * cx[t / 8] % P * cy[t % 8] % P).sum::<u64>() % P
}
fn f(a: &[[u64; 8]; 8], z: &[u64]) -> u64 {
    at_(a, &z[0..3], &z[3..6]) * at_(a, &z[3..6], &z[6..9]) % P * at_(a, &z[0..3], &z[6..9]) % P
}
fn corners(k: usize) -> Vec<Vec<u64>> { (0..1u64 << k).map(|c| (0..k).map(|i| (c >> (k - 1 - i)) & 1).collect()).collect() }
fn at(g: &[u64; 3], r: u64) -> u64 { // the degree-2 polynomial through g, at r
    let t0 = g[0] * ((r + P - 1) % P) % P * ((r + P - 2) % P) % P * H % P;
    let t1 = g[1] * r % P * ((r + P - 2) % P) % P;
    let t2 = g[2] * r % P * ((r + P - 1) % P) % P * H % P;
    (t0 + P - t1 + t2) % P
}
fn sumcheck(a: &[[u64; 8]; 8], mut claim: u64, rng: &mut Rng, mut lie: u64, fin: bool, show: usize, who: &str) -> String {
    let mut fixed: Vec<u64> = vec![];
    for i in 0..9 {
        let mut g = [0u64; 3];
        for t in 0..3u64 {
            let mut s = 0;
            for c in corners(8 - i) { let mut z = fixed.clone(); z.push(t); z.extend(c); s = (s + f(a, &z)) % P; }
            g[t as usize] = (s + lie) % P;
        }
        if (g[0] + g[1]) % P != claim { return format!("rejected in round {}", i + 1); }
        let r = rng.below(P); claim = at(&g, r); lie = lie * H % P; fixed.push(r);
        if i < show { println!("{}round {}: g(0) = {}, g(1) = {}, g(2) = {}, r = {}", who, i + 1, g[0], g[1], g[2], r); }
    }
    if !fin { return "accepted after 9 of 9 rounds".to_string(); }
    let v = f(a, &fixed);
    format!("final f = {}, last claim {}: {}", v, claim, if v == claim { "accept" } else { "reject" })
}
fn broken(e: &[(usize, usize)], col: &[usize]) -> usize { e.iter().filter(|&&(a, b)| col[a] == col[b]).count() }
fn best_col(e: &[(usize, usize)], n: usize) -> (usize, usize) {
    (0..1usize << n).map(|c| (broken(e, &(0..n).map(|i| (c >> i) & 1).collect::<Vec<_>>()), c)).min().unwrap()
}
fn lp(n: usize) -> Vec<(usize, usize)> { (0..n).map(|i| (i, (i + 1) % n)).collect() }
fn checks(q: f64) -> usize { let (mut k, mut x) = (0, 1.0f64); while x > 0.01 { k += 1; x *= 1.0 - q; } k }
fn main() {
    // ---- part 1: the sceptic's protocol for "these two maps are different networks"
    let all = perms(&ID);
    let copies = |m: &Map| -> HashSet<u64> { all.iter().map(|p| mask(m, p)).collect() };
    let (c_r, c_d, c_t) = (copies(&RING), copies(&DECOY), copies(&TOURIST));
    let autos = |m: &Map| all.iter().filter(|p| mask(m, p) == mask(m, &ID)).count();
    let (a_r, a_d) = (autos(&RING), autos(&DECOY));
    let shared = |x: &HashSet<u64>, y: &HashSet<u64>| x.intersection(y).count();
    println!("tube maps: 6 stations, 8 lines each; tally ring {:?}, decoy {:?}", tally(&RING), tally(&DECOY));
    println!("triangles: ring {}, tourist {}, decoy {}", triangles(&RING), triangles(&TOURIST), triangles(&DECOY));
    println!("renamings that leave a map unchanged: ring {}, decoy {}", a_r, a_d);
    println!("distinct shuffled copies: ring {} = 720 / {}, decoy {} = 720 / {}, shared {}", c_r.len(), a_r, c_d.len(), a_d, shared(&c_r, &c_d));
    println!("same network (ring, tourist): copies {} and {}, shared {}", c_r.len(), c_t.len(), shared(&c_r, &c_t));
    let mut count: HashMap<u64, [usize; 2]> = HashMap::new();
    for (b, m) in [&RING, &TOURIST].iter().enumerate() { for p in &all { count.entry(mask(*m, p)).or_insert([0, 0])[b] += 1; } }
    let best: usize = count.values().map(|c| c[0].max(c[1])).sum();
    println!("best cheater over all 1440 (coin, renaming) pairs: wins {}, rate {:.6}", best, best as f64 / 1440.0);
    let mut rng = Rng(2026);
    let honest_ans = |h: u64| if c_r.contains(&h) { 0 } else { 1 };
    let honest = (0..20000).filter(|_| round_ok(&mut rng, [&RING, &DECOY], &honest_ans, true)).count();
    println!("honest prover, different maps: {} of 20000 rounds named correctly", honest);
    let guess = |h: u64| if h & (1 << 1) != 0 { 0 } else { 1 }; // "ring if line A-B is drawn"
    let wins = (0..100000).filter(|_| round_ok(&mut rng, [&RING, &TOURIST], &guess, true)).count();
    println!("cheater, same network, one round: {} of 100000, rate {:.6} (exact 0.5)", wins, wins as f64 / 100000.0);
    println!("chart,rounds,simulated,exact");
    let mut sims = vec![];
    for k in 1..9 {
        let alive = (0..20000).filter(|_| (0..k).all(|_| round_ok(&mut rng, [&RING, &TOURIST], &guess, true))).count();
        let s = alive as f64 / 20000.0; sims.push(s);
        println!("chart,{},{:.4},{:.4}", k, s, 0.5f64.powi(k));
    }
    println!("20 rounds: a cheater survives with chance 1 in {}", 1u64 << 20);
    let ring_id = mask(&RING, &ID);
    let blind_ans = move |h: u64| if h == ring_id { 0 } else { 1 };
    let blind = (0..20).filter(|_| round_ok(&mut rng, [&RING, &TOURIST], &blind_ans, false)).count();
    println!("no shuffle (map sent under its own names): cheater names {} of 20", blind);
    assert!(c_r.len() * a_r == 720 && c_d.len() * a_d == 720 && shared(&c_r, &c_d) == 0 && c_r == c_t);
    assert!(triangles(&RING) == 0 && triangles(&TOURIST) == 0 && triangles(&DECOY) == 2 && tally(&RING) == tally(&DECOY));
    assert!(honest == 20000 && best == 720 && blind == 20);
    assert!((wins as f64 / 100000.0 - 0.5).abs() < 4.0 * (0.25f64 / 100000.0).sqrt());
    for (i, s) in sims.iter().enumerate() { let e = 0.5f64.powi(i as i32 + 1); assert!((s - e).abs() < 4.0 * (e / 20000.0).sqrt()); }
    // ---- part 2: sum-check, the engine of IP = PSPACE, on "the decoy has 2 triangles"
    let mut a = [[0u64; 8]; 8];
    for &(x, y) in DECOY.iter() { a[x][y] = 1; a[y][x] = 1; }
    let total = corners(9).iter().fold(0, |s, c| (s + f(&a, c)) % P);
    println!("sum-check on the decoy, 9 variables, field size p = {}", P);
    println!("brute force over 512 corners: {} = 6 x {} triangles", total, triangles(&DECOY));
    let honest_run = sumcheck(&a, total, &mut Rng(7), 0, true, 9, "");
    println!("honest prover, claim 12: {}", honest_run);
    let lie_run = sumcheck(&a, 18, &mut Rng(7), 3, true, 1, "lying prover, ");
    println!("lying prover, claim 18 (3 triangles): {}", lie_run);
    let blind_run = sumcheck(&a, 18, &mut Rng(7), 3, false, 0, "");
    println!("lying prover, verifier skips the final check: {}", blind_run);
    println!("escape chance at most 18 / {}, under 1 in {}", P, P / 18);
    println!("cost,stations,rounds,numbers sent,brute-force terms,table entries read");
    for m in [3u32, 8, 10] { println!("cost,{},{},{},{},{}", 1u64 << m, 3 * m, 9 * m, 8u64.pow(m), 4u64.pow(m)); }
    assert!(total == 6 * triangles(&DECOY) as u64 && honest_run.ends_with("accept") && lie_run.ends_with("reject"));
    assert!(blind_run.starts_with("accepted") && sumcheck(&a, total + 1, &mut Rng(7), 0, true, 0, "") == "rejected in round 1");
    // ---- part 3: spot checks, and why a proof must be rewritten before they work
    let (b_r, b_d, b9) = (best_col(&RING, 6).0, best_col(&DECOY, 6), best_col(&lp(9), 9).0);
    let b1001 = broken(&lp(1001), &(0..1001).map(|i| i % 2).collect::<Vec<_>>());
    println!("2-colouring proofs: ring best breaks {} of 8; decoy best breaks {} of 8", b_r, b_d.0);
    println!("odd loop of 9: best breaks {} of 9 (all 512 colourings); loop of 1001, alternating: breaks {}", b9, b1001);
    let (q_d, q_l) = (b_d.0 as f64 / 8.0, b1001 as f64 / 1001.0);
    println!("one check catches the best wrong proof: decoy {:.6}, loop of 1001 {:.6}", q_d, q_l);
    println!("checks for 99% confidence: decoy {}, loop of 1001 {}", checks(q_d), checks(q_l));
    let col: Vec<usize> = (0..6).map(|i| (b_d.1 >> i) & 1).collect();
    let fooled = (0..10000).filter(|_| (0..17).all(|_| { let (x, y) = DECOY[rng.below(8) as usize]; col[x] != col[y] })).count();
    println!("17 checks on the best decoy colouring, 10000 trials: fooled {:.4}, exact {:.6}", fooled as f64 / 10000.0, 0.75f64.powi(17));
    let sat = (0..8).filter(|c| c & 1 != 0 || c & 2 != 0 || c & 4 != 0).count(); // (x or y or z)
    println!("a 3-literal clause holds on {} of its 8 settings", sat);
    assert!(b_r == 0 && b_d.0 == 2 && b9 == 1 && b1001 == 1);
    assert!(checks(q_d) == 17 && checks(q_l) > 1001 && (fooled as f64 / 10000.0 - 0.75f64.powi(17)).abs() < 4.0 * (0.0075f64 / 10000.0).sqrt());
    println!("ALL CHECKS PASS");
}
