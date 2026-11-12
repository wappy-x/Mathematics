// Seeds -- the same check as the Python, in Rust.  No crates, no rand: the
// generator is SplitMix64, written out.  Roads: the Python and Rust runs pin
// each other's numbers; the overlap formula meets brute force on a toy generator;
// the first output on the Random numbers card; estimates held to a few standard errors.
use std::collections::HashSet;
const GAMMA: u64 = 0x9E3779B97F4A7C15;
const MASTER: u64 = 20261111;
const WORKERS: usize = 4;
const DARTS: usize = 100000; // darts per worker, two draws per dart

fn mix(mut z: u64) -> u64 { // SplitMix64's scrambler
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

trait Gen { fn u(&mut self) -> f64; fn state(&self) -> u64; }
struct Stream { state: u64, used: usize } // one stream: a counter stepped by GAMMA, then mixed
impl Stream {
    fn new(state: u64) -> Self { Stream { state, used: 0 } }
    fn next(&mut self) -> u64 {
        self.state = self.state.wrapping_add(GAMMA);
        self.used += 1;
        mix(self.state)
    }
}
impl Gen for Stream { // top 53 bits: exact in both languages
    fn u(&mut self) -> f64 { (self.next() >> 11) as f64 * (1.0 / 9007199254740992.0) }
    fn state(&self) -> u64 { self.state }
}
struct Lcg { x: u64 } // the 32-bit LCG of the Monte Carlo pricing card
impl Gen for Lcg {
    fn u(&mut self) -> f64 { self.x = (1664525 * self.x + 1013904223) % (1 << 32); (self.x as f64 + 0.5) / 4294967296.0 }
    fn state(&self) -> u64 { self.x }
}

fn seeds(master: u64, n: usize) -> Vec<u64> { // stream seeds: the first n outputs from the master
    let mut g = Stream::new(master);
    (0..n).map(|_| g.next()).collect()
}

fn darts(g: &mut dyn Gen, n: usize, mut starts: Option<&mut HashSet<u64>>) -> (u64, Vec<f64>) {
    let (mut hits, mut dist) = (0u64, Vec::with_capacity(n)); // n darts at the unit square
    for _ in 0..n {
        if let Some(s) = starts.as_mut() { s.insert(g.state()); }
        let (x, y) = (g.u(), g.u());
        if x * x + y * y < 1.0 { hits += 1; }
        dist.push((x * x + y * y).sqrt());
    }
    (hits, dist)
}

fn total(xs: &[f64]) -> f64 { let mut s = 0.0; for x in xs { s += x; } s } // left to right

fn disc_mean(g: &mut Stream, n: usize) -> f64 { // part A: n points in the unit disc, by rejection
    let (mut tot, mut got) = (0.0, 0);
    while got < n {
        let (x, y) = (2.0 * g.u() - 1.0, 2.0 * g.u() - 1.0);
        if x * x + y * y < 1.0 { tot += (x * x + y * y).sqrt(); got += 1; }
    }
    tot / n as f64
}

fn two_parts(n_a: usize, shared: bool) -> (f64, usize, f64) { // part A, then part B: 10000 darts
    let s = seeds(MASTER, 2);
    let mut a = Stream::new(s[0]);
    let mean_a = disc_mean(&mut a, n_a);
    let used = a.used;
    let mut own = Stream::new(s[1]);
    let b: &mut Stream = if shared { &mut a } else { &mut own };
    (mean_a, used, 4.0 * darts(b, 10000, None).0 as f64 / 10000.0)
}

fn pi_se(h: u64, n: usize) -> f64 { let p = h as f64 / n as f64; 4.0 * (p * (1.0 - p) / n as f64).sqrt() }

fn main() {
    println!("splitmix64,seed 0,first output {:016x},Random numbers card e220a8397b1dcdaf", Stream::new(0).next());
    let s = seeds(MASTER, WORKERS);
    let hexs: Vec<String> = s.iter().map(|x| format!("{:016x}", x)).collect();
    println!("streams,master seed {},stream seeds {}", MASTER, hexs.join(", "));
    let runs: Vec<(u64, Vec<f64>)> = s.iter().map(|&x| darts(&mut Stream::new(x), DARTS, None)).collect();
    let n = WORKERS * DARTS;
    let h: u64 = runs.iter().map(|r| r.0).sum();
    let (est, se) = (4.0 * h as f64 / n as f64, pi_se(h, n));
    for k in 0..WORKERS {
        println!("worker {},{} darts,hits {},estimate {:.5}", k, DARTS, runs[k].0, 4.0 * runs[k].0 as f64 / DARTS as f64);
    }
    println!("answer,pi from {} darts,hits {},share {:.5},estimate {:.5},se {:.5},bits {:016x}", n, h, h as f64 / n as f64, est, se, est.to_bits());
    println!("answer,pi {:.5},estimate below pi by {:.5}", std::f64::consts::PI, std::f64::consts::PI - est);
    println!("record,generator splitmix64,master seed {},streams {} seeded from the master,draws {},answer {:.5} +- {:.5}",
             MASTER, WORKERS, 2 * n, est, se);
    let mut ginv = GAMMA;
    for _ in 0..6 { ginv = ginv.wrapping_mul(2u64.wrapping_sub(GAMMA.wrapping_mul(ginv))); } // Newton
    let pos: Vec<u64> = s.iter().map(|x| x.wrapping_mul(ginv)).collect(); // stream starts on the loop
    let mut gap = u64::MAX;
    for i in 0..WORKERS { for j in 0..WORKERS { if i != j { gap = gap.min(pos[j].wrapping_sub(pos[i])); } } }
    let l = 2 * DARTS;
    println!("loop,gamma x inverse mod 2^64 = {},nearest two stream starts {} draws apart,each stream uses {}",
             GAMMA.wrapping_mul(ginv), gap, l);
    let two64 = 18446744073709551616.0f64;
    let pair = (2 * l - 1) as f64 / two64;
    println!("overlap bound,{} streams of {},pairs {},2L - 1 = {},per pair {:.1e},any pair {:.1e}", WORKERS, l, WORKERS * (WORKERS - 1) / 2, 2 * l - 1, pair, (WORKERS * (WORKERS - 1)) as f64 / 2.0 * pair);
    let big = 10000.0 * 9999.0 / 2.0 * (2e9 - 1.0);
    println!("overlap bound,10000 streams of 10^9,pairs {},64-bit loop {:.5} (1 in {:.0}),128-bit loop {:.1e}",
             10000u64 * 9999 / 2, big / two64, two64 / big, big / (two64 * two64));
    let segs: Vec<HashSet<u64>> = (0..256u64).map(|mut x| (0..10).map(|_| { x = (5 * x + 3) % 256; x }).collect()).collect();
    let clash = segs.iter().map(|a| segs.iter().filter(|b| !a.is_disjoint(b)).count()).sum::<usize>();
    println!("toy,(5x + 3) mod 256,ordered seed pairs whose 10-draw segments share a state {} of 65536,formula 256 x 19 = {},probability {:.4}",
             clash, 256 * 19, clash as f64 / 65536.0);
    let all: Vec<f64> = runs.iter().flat_map(|r| r.1.iter().copied()).collect();
    let parts: Vec<f64> = runs.iter().map(|r| total(&r.1)).collect();
    let (d_ser, d_par) = (total(&all) / n as f64, total(&parts) / n as f64);
    let exact = (2f64.sqrt() + (1.0 + 2f64.sqrt()).ln()) / 3.0;
    let ulps = (d_ser.to_bits() as i64 - d_par.to_bits() as i64).abs();
    println!("sum order,mean distance one pass {:?},four partial sums {:?},apart by {} ulp,exact {:.5}", d_ser, d_par, ulps, exact);
    let rev: Vec<f64> = runs.iter().rev().flat_map(|r| r.1.iter().copied()).collect(); // workers reversed
    let d_rev = total(&rev) / n as f64;
    println!("sum order,one pass with the workers in reverse order {:?},apart by {} ulp", d_rev,
             (d_ser.to_bits() as i64 - d_rev.to_bits() as i64).abs());
    let same: Vec<u64> = (0..WORKERS).map(|_| darts(&mut Stream::new(MASTER), DARTS, None).0).collect();
    let ss: u64 = same.iter().sum();
    println!("mistake,every worker seeded {},hits {:?},estimate {:.5},claimed se {:.5},true se {:.5}",
             MASTER, same, 4.0 * ss as f64 / n as f64, pi_se(ss, n), pi_se(same[0], DARTS));
    let (mut starts, mut hb) = (HashSet::new(), 0u64);
    for k in 0..WORKERS { // jumped by darts, not draws
        let jump = MASTER.wrapping_add(((k * DARTS) as u64).wrapping_mul(GAMMA));
        hb += darts(&mut Stream::new(jump), DARTS, Some(&mut starts)).0;
    }
    println!("mistake,jump ahead by {} draws not {},distinct darts {} of {},estimate {:.5}", DARTS, l, starts.len(), n, 4.0 * hb as f64 / n as f64);
    let hl = darts(&mut Lcg { x: MASTER }, n, None).0;
    println!("mistake,seed {} recorded without its generator,32-bit LCG gives {:.5}", MASTER, 4.0 * hl as f64 / n as f64);
    let (p1, p2, p3, p4) = (two_parts(10000, true), two_parts(5000, true), two_parts(10000, false), two_parts(5000, false));
    for (name, pa, pb) in [("one shared stream", p1, p2), ("own streams", p3, p4)] {
        println!("parts,{},A 10000 points used {} draws,B {:.4},A 5000 points used {} draws,B {:.4}", name, pa.1, pa.2, pb.1, pb.2);
    }
    println!("parts,A mean distance in the disc {:.5},exact 2/3", p3.0);
    assert_eq!(Stream::new(0).next(), 0xE220A8397B1DCDAF); // as on the Random numbers card
    assert!(h == 314064 && format!("{:016x}", est.to_bits()) == "40092007dd441355"); // pinned by Python
    assert!((est - std::f64::consts::PI).abs() < 4.0 * se); // pi, within 4 standard errors
    assert!((d_ser - exact).abs() < 4.0 * 0.29 / (n as f64).sqrt()); // closed form, sd about 0.285
    assert!((p3.0 - 2.0 / 3.0).abs() < 4.0 * 0.24 / 100.0); // disc: sd about 0.236
    assert_eq!(GAMMA.wrapping_mul(ginv), 1); // Newton found the inverse
    assert!(gap > l as u64); // no two streams can meet
    assert_eq!(clash, 256 * (2 * 10 - 1)); // brute force = (2L - 1) per seed
    assert!((d_ser - d_par).abs() > 0.0 && (d_ser - d_par).abs() < 1e-14); // order moves bits
    assert!((d_ser - d_rev).abs() > 0.0 && (d_ser - d_rev).abs() < 1e-14); // so does worker order
    assert!(same.iter().all(|&x| x == same[0])); // one seed, four identical runs
    assert_eq!(runs.iter().map(|r| r.0).collect::<HashSet<u64>>().len(), WORKERS); // own seeds: four runs
    assert_eq!(starts.len(), n - (WORKERS - 1) * DARTS / 2); // half of each block repeated
    assert!(p3.2 == p4.2 && p1.2 != p2.2); // own stream: B does not move
    assert!(p3.2 != 4.0 * darts(&mut Stream::new(s[0]), 10000, None).0 as f64 / 10000.0); // and B's stream is not A's
    println!("ALL CHECKS PASS");
}
