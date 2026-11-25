// Arthur-Merlin and two provers -- the same check as the Python, in Rust.  No crates.
// Part 1: the Goldwasser-Sipser protocol, with public coins, on the claim "a 4-station
// path and a 4-station star are different networks".  Part 2: the CHSH game, two
// suspects in separate rooms: fixed strategies against a two-qubit state vector.
use std::collections::BTreeSet;
use std::f64::consts::PI;
type G = [(usize, usize); 3];
const PATH: G = [(0, 1), (1, 2), (2, 3)];
const STAR: G = [(0, 1), (0, 2), (0, 3)];
const PATH2: G = [(2, 0), (0, 3), (3, 1)];
struct Rng(u64); // SplitMix64, as on the Interactive proofs card
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn below(&mut self, n: u64) -> u64 { self.next() % n }
    fn unit(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}
fn perms(items: &[usize]) -> Vec<Vec<usize>> { // all 24 renamings of 4 stations
    if items.is_empty() { return vec![vec![]]; }
    let mut out = vec![];
    for i in 0..items.len() {
        let mut rest = items.to_vec(); let x = rest.remove(i);
        for r in perms(&rest) { let mut v = vec![x]; v.extend(r); out.push(v); }
    }
    out
}
struct Kit { all: Vec<Vec<usize>>, pairs: Vec<(usize, usize)> }
impl Kit {
    fn mask(&self, e: &[(usize, usize)], p: &[usize]) -> u64 { // a renamed network as 6 bits
        e.iter().map(|&(a, b)| { let q = (p[a].min(p[b]), p[a].max(p[b]));
            1u64 << self.pairs.iter().position(|&z| z == q).unwrap() }).sum()
    }
    fn lines(&self, h: u64) -> Vec<(usize, usize)> { (0..6).filter(|i| h >> i & 1 == 1).map(|i| self.pairs[i]).collect() }
    fn copies(&self, g: &G) -> BTreeSet<u64> { self.all.iter().map(|p| self.mask(g, p)).collect() }
    fn syms(&self, h: u64) -> Vec<usize> { (0..24).filter(|&k| self.mask(&self.lines(h), &self.all[k]) == h).collect() }
    fn pairset(&self, g0: &G, g1: &G) -> Vec<u64> { // Merlin's set: (copy, symmetry) as 11-bit codes
        let u: BTreeSet<u64> = self.copies(g0).union(&self.copies(g1)).cloned().collect();
        u.iter().flat_map(|&h| self.syms(h).into_iter().map(move |k| h * 32 + k as u64)).collect()
    }
}
fn hsh(rows: &[u64], x: u64) -> u64 { rows.iter().enumerate().map(|(j, r)| (((r & x).count_ones() & 1) as u64) << j).sum() }
fn play(kit: &Kit, rng: &mut Rng, s: &[u64], k: usize, n: usize, show: bool) -> (Vec<bool>, usize) {
    let (mut acc, mut hits) = (vec![], 0);
    for _ in 0..n {
        let rows: Vec<u64> = (0..k).map(|_| rng.below(2048)).collect();
        let y = rng.below(1 << k);
        let found: Vec<u64> = s.iter().cloned().filter(|&x| hsh(&rows, x) == y).collect();
        if show && !found.is_empty() && !acc.iter().any(|&b| b) {
            let (x, h) = (found[0], found[0] >> 5); let p = &kit.all[(x & 31) as usize];
            println!("round {}: target {}; Merlin sends code {}: lines {:?}, a copy of the {}, symmetry ({}, {}, {}, {})", acc.len() + 1, y, x,
                kit.lines(h), if kit.copies(&PATH).contains(&h) { "path" } else { "star" }, p[0], p[1], p[2], p[3]);
        }
        acc.push(!found.is_empty()); hits += found.len();
    }
    (acc, hits)
}
fn tail(t: usize, q: f64, lo: usize) -> f64 { // Pr[at least lo hits in t rounds, each with chance q]
    let (mut term, mut tot) = (1.0f64, 0.0f64);
    for _ in 0..t { term *= 1.0 - q; }
    for k in 0..=t {
        if k >= lo { tot += term; }
        term = term * (t - k) as f64 / (k + 1) as f64 * q / (1.0 - q);
    }
    tot
}
fn win(x: usize, y: usize, a: usize, b: usize) -> bool { (a ^ b) == (x & y) }
fn chances(al: f64, be: f64) -> [f64; 4] { // read A at angle al, B at be, on (|00> + |11>)/sqrt 2
    let s2 = 1.0 / 2f64.sqrt();
    let mut v = [s2, 0.0, 0.0, s2]; // state vector as on the Qubits card; index 2a + b
    for &(bit, th) in [(2usize, al), (1, be)].iter() {
        let (c, s) = (th.cos(), th.sin());
        for i in 0..4 {
            if i & bit == 0 { let j = i | bit; let (vi, vj) = (v[i], v[j]); v[i] = c * vi + s * vj; v[j] = -s * vi + c * vj; }
        }
    }
    [v[0] * v[0], v[1] * v[1], v[2] * v[2], v[3] * v[3]]
}
const Q: [(usize, usize); 4] = [(0, 0), (0, 1), (1, 0), (1, 1)];
fn qwin(al: &[f64; 2], be: &[f64; 2]) -> f64 {
    Q.iter().map(|&(x, y)| { let p = chances(al[x], be[y]); (0..4).filter(|&i| win(x, y, i >> 1, i & 1)).map(|i| p[i]).sum::<f64>() }).sum::<f64>() / 4.0
}
fn main() {
    // ---- part 1: public coins prove "the set is big"
    let pairs: Vec<(usize, usize)> = (0..4).flat_map(|a| (a + 1..4).map(move |b| (a, b))).collect();
    let kit = Kit { all: perms(&[0, 1, 2, 3]), pairs };
    let (c_p, c_s) = (kit.copies(&PATH), kit.copies(&STAR));
    let (s_p, s_s) = (kit.syms(kit.mask(&PATH, &kit.all[0])), kit.syms(kit.mask(&STAR, &kit.all[0])));
    let shared = c_p.intersection(&c_s).count();
    let pp = c_p.union(&kit.copies(&PATH2)).count();
    println!("renamings of 4 stations: {}; symmetries: path {}, star {}", kit.all.len(), s_p.len(), s_s.len());
    println!("labelled copies: path {} = 24 / {}, star {} = 24 / {}, shared {}", c_p.len(), s_p.len(), c_s.len(), s_s.len(), shared);
    println!("copies only: path+star {}, path+path {}, star+star {}", c_p.union(&c_s).count(), pp, c_s.len());
    let (yes, no) = (kit.pairset(&PATH, &STAR), kit.pairset(&PATH, &PATH2));
    println!("(copy, symmetry) pairs: path {}, star {}; claim true {}, claim false {}",
        kit.pairset(&PATH, &PATH).len(), kit.pairset(&STAR, &STAR).len(), yes.len(), no.len());
    let k = 7usize; let t = 1usize << k; let (py, pn) = (yes.len() as f64 / t as f64, no.len() as f64 / t as f64);
    let lo = py - (yes.len() * (yes.len() - 1)) as f64 / 2.0 / (t * t) as f64;
    println!("hash 11 bits to {}: {} targets; true claim hits with chance at least {:.6} - {}/{} = {:.6}",
        k, t, py, yes.len() * (yes.len() - 1) / 2, t * t, lo);
    println!("false claim hits with chance at most {}/{} = {:.6}, whatever Merlin does", no.len(), t, pn);
    let mut rng = Rng(2026);
    let (a_y, h_y) = play(&kit, &mut rng, &yes, k, 20000, true);
    let (a_n, h_n) = play(&kit, &mut rng, &no, k, 20000, false);
    let cnt = |a: &[bool]| a.iter().filter(|&&b| b).count();
    let (r_y, r_n) = (cnt(&a_y) as f64 / 20000.0, cnt(&a_n) as f64 / 20000.0);
    println!("20000 rounds each: true claim accepted {} ({:.4}), false claim {} ({:.4})", cnt(&a_y), r_y, cnt(&a_n), r_n);
    println!("mean hits per round: true {:.4} (exact {:.4}), false {:.4} (exact {:.4})", h_y as f64 / 20000.0, py, h_n as f64 / 20000.0, pn);
    let blocks = |a: &[bool]| a.chunks(100).filter(|c| cnt(c) >= 25).count();
    let (b_y, b_n) = (blocks(&a_y), blocks(&a_n));
    println!("100 rounds at once, accept if 25 or more hit: true claim {} of 200 runs, false claim {} of 200", b_y, b_n);
    println!("chart,rounds,true claim rejected,false claim accepted");
    let errs: Vec<(usize, f64, f64)> = (1..=10).map(|i| 40 * i).map(|n| (n, 1.0 - tail(n, lo, n / 4), tail(n, pn, n / 4))).collect();
    for &(n, e1, e2) in &errs { println!("chart,{},{:.6},{:.6}", n, e1, e2); }
    let mut cheat = 0;
    for _ in 0..20 {
        let rows: Vec<u64> = (0..k).map(|_| rng.below(2048)).collect();
        if no.iter().any(|&x| hsh(&rows, x) == hsh(&rows, no[0])) { cheat += 1; } // Merlin picks the target
    }
    println!("Merlin chooses the target himself: false claim accepted {} of 20", cheat);
    let (a4, _) = play(&kit, &mut rng, &yes, 4, 20000, false);
    let (n4, _) = play(&kit, &mut rng, &no, 4, 20000, false);
    println!("only 16 targets: true claim {:.4}, false claim {:.4}", cnt(&a4) as f64 / 20000.0, cnt(&n4) as f64 / 20000.0);
    assert!(c_p.len() * s_p.len() == 24 && c_s.len() * s_s.len() == 24 && kit.all.len() == 24 && shared == 0);
    assert!(yes.len() == 2 * no.len() && yes.len() == 48 && pp == 12);
    let se = (0.25f64 / 20000.0).sqrt();
    assert!(lo - 4.0 * se < r_y && r_y < py + 4.0 * se && r_n < pn + 4.0 * se && r_n < lo);
    assert!((h_y as f64 / 20000.0 - py).abs() < 0.02 && (h_n as f64 / 20000.0 - pn).abs() < 0.02);
    assert!(b_y > 150 && b_n < 50 && errs[9].1 < 0.01 && errs[9].2 < 0.01 && cheat == 20);
    // ---- part 2: two suspects in separate rooms, the CHSH game
    let det: Vec<usize> = (0..16).map(|s| Q.iter().filter(|&&(x, y)| win(x, y, s >> x & 1, s >> (2 + y) & 1)).count()).collect();
    let (n3, n1, mx, sm) = (det.iter().filter(|&&d| d == 3).count(), det.iter().filter(|&&d| d == 1).count(),
        *det.iter().max().unwrap(), det.iter().sum::<usize>());
    println!("CHSH, 16 fixed strategy pairs: {} win 3 of 4, {} win 1 of 4, best {:.4}, average {:.4}", n3, n1, mx as f64 / 4.0, sm as f64 / 64.0);
    let talk = Q.iter().filter(|&&(x, y)| win(x, y, 0, x & y)).count();
    println!("suspects who hear both questions: win {} of 4", talk);
    let (al, be) = ([0.0, PI / 4.0], [PI / 8.0, -PI / 8.0]);
    let (qw, cf) = (qwin(&al, &be), (PI / 8.0).cos() * (PI / 8.0).cos());
    println!("entangled pair, A at 0 or pi/4, B at pi/8 or -pi/8: win {:.12}; cos^2(pi/8) = {:.12}", qw, cf);
    let mut same = [[0.0f64; 16]; 16];
    for i in 0..16 { for j in 0..16 { let p = chances(i as f64 * PI / 16.0, j as f64 * PI / 16.0); same[i][j] = p[0] + p[3]; } }
    let mut best = f64::MIN;
    for a in 0..16 { for b in 0..16 { for c in 0..16 { for d in 0..16 {
        best = best.max((same[a][c] + same[a][d] + same[b][c] + 1.0 - same[b][d]) / 4.0);
    } } } }
    println!("best over 65536 angle settings in steps of pi/16: {:.12}", best);
    let (mut rng, mut cw, mut qn) = (Rng(7), 0usize, 0usize);
    for _ in 0..100000 {
        let (x, y) = (rng.below(2) as usize, rng.below(2) as usize);
        if win(x, y, 0, 0) { cw += 1; }
        let (p, mut u, mut i) = (chances(al[x], be[y]), rng.unit(), 0usize);
        while i < 3 && u >= p[i] { u -= p[i]; i += 1; }
        if win(x, y, i >> 1, i & 1) { qn += 1; }
    }
    println!("100000 sampled games: best fixed strategy wins {:.4}, entangled pair {:.4}", cw as f64 / 100000.0, qn as f64 / 100000.0);
    for &(name, r) in [("random answers", sm as f64 / 64.0), ("best fixed strategy", mx as f64 / 4.0),
                       ("entangled pair", qw), ("suspects who talk", talk as f64 / 4.0)].iter() {
        println!("{:<20}{:<41}{:.4}", name, "#".repeat((r * 40.0).round() as usize), r);
    }
    let sizes: Vec<String> = [1u32, 2, 3, 4].iter().map(|&q| format!("q = {}: {}", q, 1u64 << (1u64 << (q + 1)))).collect();
    println!("strategy pairs to try, q-bit questions, 1-bit answers: {}", sizes.join(", "));
    assert!(mx == 3 && n3 == 8 && talk == 4 && (qw - (2.0 + 2f64.sqrt()) / 4.0).abs() < 1e-12);
    assert!((best - cf).abs() < 1e-12 && (cw as f64 / 100000.0 - 0.75).abs() < 4.0 * (0.1875f64 / 100000.0).sqrt());
    assert!((qn as f64 / 100000.0 - qw).abs() < 4.0 * (0.125f64 / 100000.0).sqrt() && qn as f64 / 100000.0 > 0.8);
    println!("ALL CHECKS PASS");
}
