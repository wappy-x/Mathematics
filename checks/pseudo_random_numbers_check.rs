// Random numbers from a computer -- the same check as the Python, in Rust.  No
// crates: every generator is written out here.  Roads: rule against brute
// force, stepping against jumping ahead against published values, and
// statistical tests whose own yardstick is checked against a printed table.
use std::collections::{BTreeSet, HashMap};
const P: u64 = (1 << 31) - 1;

fn lcg(a: u64, c: u64, m: u64, mut x: u64, n: usize) -> Vec<u64> {   // n outputs of (a x + c) mod m
    (0..n).map(|_| { x = (a * x + c) % m; x }).collect()
}

fn cycle(a: u64, c: u64, m: u64, mut x: u64) -> u64 {   // length of the loop the seed falls into
    let (mut seen, mut n) = (HashMap::new(), 0u64);
    while !seen.contains_key(&x) {
        seen.insert(x, n);
        x = (a * x + c) % m;
        n += 1;
    }
    n - seen[&x]
}

fn powmod(mut b: u64, mut e: u64, m: u64) -> u64 {      // square-and-multiply, to jump ahead
    let mut r = 1;
    while e > 0 {
        if e & 1 == 1 { r = r * b % m }
        b = b * b % m;
        e >>= 1;
    }
    r
}

struct Mt { s: Vec<u32>, i: usize }                     // MT19937, Matsumoto and Nishimura 1998
impl Mt {
    fn new(seed: u32) -> Mt {
        let mut s = vec![seed];
        for i in 1..624u32 {
            let p = s[i as usize - 1];
            s.push(1812433253u32.wrapping_mul(p ^ (p >> 30)).wrapping_add(i));
        }
        Mt { s, i: 624 }
    }
    fn next32(&mut self) -> u32 {
        if self.i == 624 {                              // refill all 624 words at once
            for k in 0..624 {
                let y = (self.s[k] & 0x80000000) | (self.s[(k + 1) % 624] & 0x7FFFFFFF);
                self.s[k] = self.s[(k + 397) % 624] ^ (y >> 1) ^ (0x9908B0DF * (y & 1));
            }
            self.i = 0;
        }
        let mut y = self.s[self.i];
        self.i += 1;
        y ^= y >> 11; y ^= (y << 7) & 0x9D2C5680; y ^= (y << 15) & 0xEFC60000;
        y ^ (y >> 18)
    }
    fn u(&mut self) -> f64 { self.next32() as f64 / 4294967296.0 }
}

fn splitmix(state: u64) -> (u64, u64) {                 // SplitMix64: a counter, then a scrambler
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (state ^ (state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, z ^ (z >> 31))
}

fn chi2(draw: &mut dyn FnMut() -> f64) -> (Vec<u64>, f64) {   // counts in 10 bins, and the statistic
    let mut obs = vec![0u64; 10];
    for _ in 0..10000 { obs[(draw() * 10.0) as usize] += 1 }
    (obs.clone(), obs.iter().map(|&o| (o as f64 - 1000.0).powi(2) / 1000.0).sum())
}

fn pvalue(x: f64) -> f64 {                              // chance a true uniform scores above x,
    let g = 3.5 * 2.5 * 1.5 * 0.5 * std::f64::consts::PI.sqrt();   // 9 degrees of freedom, Simpson
    let f = |t: f64| t.powf(3.5) * (-t / 2.0).exp() / (2f64.powf(4.5) * g);
    let h = x / 2000.0;
    let mut acc = 0.0;
    for j in 1..2000 { acc += (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(j as f64 * h) }
    1.0 - (f(0.0) + f(x) + acc) * h / 3.0
}

fn stream(a: u64, m: u64, mut x: u64) -> impl FnMut() -> f64 {   // LCG without increment, u in [0, 1)
    move || { x = a * x % m; x as f64 / m as f64 }
}

fn darts(seed: u32) -> (f64, f64) {                     // the house example: darts at a unit square
    let (mut g, mut hits, n) = (Mt::new(seed), 0u64, 100000.0);
    for _ in 0..100000 {
        let (x, y) = (g.u(), g.u());
        if x * x + y * y < 1.0 { hits += 1 }
    }
    let p = hits as f64 / n;
    (4.0 * p, 4.0 * (p * (1.0 - p) / n).sqrt())
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn fl(v: &[u64], m: f64, d: usize) -> String {
    v.iter().map(|&x| format!("{:.*}", d, x as f64 / m)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let toy = lcg(5, 3, 16, 7, 16);
    let mut pairs: Vec<(u64, u64)> = (0..16).map(|i| (if i == 0 { 7 } else { toy[i - 1] }, toy[i])).collect();
    pairs.sort();
    let lines: Vec<u64> = pairs.iter().map(|&(x, y)| x + 3 * y).collect::<BTreeSet<u64>>().into_iter().collect();
    let bits: Vec<u64> = toy[..12].iter().map(|x| x & 1).collect();
    println!("toy,x -> (5x + 3) mod 16,seed 7,outputs {:?},cycle {}", toy, cycle(5, 3, 16, 7));
    println!("toy,u = x/16,first four {},last bits {:?}", fl(&toy[..4], 16.0, 4), bits);
    println!("figure,pairs {:?},values of x + 3y {:?}", pairs, lines);
    let mut rule_ok = true;
    for m in [16u64, 64] {
        let all: Vec<(u64, u64)> = (0..m).flat_map(|a| (0..m).map(move |c| (a, c))).collect();
        let brute: Vec<(u64, u64)> = all.iter().copied().filter(|&(a, c)| cycle(a, c, m, 0) == m).collect();
        let rule: Vec<(u64, u64)> = all.iter().copied().filter(|&(a, c)| c % 2 == 1 && a % 4 == 1).collect();
        rule_ok = rule_ok && brute == rule;
        println!("full cycle,m {},pairs by brute force {},by the rule {},same pairs {}", m, brute.len(), rule.len(), yn(brute == rule));
    }
    println!("cycle,(5x + 2) mod 16 from 7: {},(3x + 3) mod 16 from 7: {},(x + 1) mod 16: {} {:?}",
             cycle(5, 2, 16, 7), cycle(3, 3, 16, 7), cycle(1, 1, 16, 7), lcg(1, 1, 16, 7, 6));
    let (step, jump) = (lcg(16807, 0, P, 1, 10000)[9999], powmod(16807, 10000, P));
    println!("minstd,x -> 16807x mod (2^31 - 1),seed 1,10000th by stepping {},by jumping {},published 1043618065", step, jump);
    let mut g = Mt::new(5489);
    let mt_out: Vec<u32> = (0..10000).map(|_| g.next32()).collect();
    println!("mt19937,seed 5489,first {},10000th {},published 10000th 4123659995", mt_out[0], mt_out[9999]);
    let (mut s, mut sm) = (0u64, Vec::new());
    for _ in 0..10000 { let (s2, z) = splitmix(s); s = s2; sm.push(z); }
    let jump_sm = splitmix(9999u64.wrapping_mul(0x9E3779B97F4A7C15)).1;   // the counter jumps straight there
    println!("splitmix64,seed 0,first {:016x},10000th by stepping {:016x},by jumping {:016x}", sm[0], sm[9999], jump_sm);
    println!("chi-square,table 5% point for 9 degrees of freedom 16.919,p by Simpson {:.4}", pvalue(16.919));
    let mut mt = Mt::new(20260929);
    let mut tests: Vec<(&str, Box<dyn FnMut() -> f64>)> = vec![("mt19937 seed 20260929", Box::new(move || mt.u())),
        ("minstd seed 1", Box::new(stream(16807, P, 1))), ("randu seed 1", Box::new(stream(65539, 1 << 31, 1)))];
    let mut pv = Vec::new();
    for (name, draw) in tests.iter_mut() {
        let (obs, x2) = chi2(draw.as_mut());
        pv.push(pvalue(x2));
        println!("uniformity,{},10000 draws in 10 bins (1000 expected in each) {:?},chi-square {:.2},p {:.4}", name, obs, x2, pv[pv.len() - 1]);
    }
    let low = (1..=100u32).filter(|&sd| { let mut g = Mt::new(sd); pvalue(chi2(&mut || g.u()).1) < 0.05 }).count();
    println!("uniformity,mt19937 seeds 1 to 100,tests with p below 0.05: {} of 100", low);
    let r: Vec<i64> = lcg(65539, 0, 1 << 31, 1, 10002).iter().map(|&x| x as i64).collect();
    let mut g = Mt::new(20260929);
    let w: Vec<i64> = (0..10002).map(|_| (g.next32() >> 1) as i64).collect();
    let comb = |v: &Vec<i64>, i: usize| 9 * v[i] - 6 * v[i + 1] + v[i + 2];
    let on = (0..10000).filter(|&i| comb(&r, i).rem_euclid(1 << 31) == 0).count();
    let planes = (0..10000).map(|i| comb(&r, i).div_euclid(1 << 31)).collect::<BTreeSet<i64>>().len();
    let on_mt = (0..10000).filter(|&i| comb(&w, i).rem_euclid(1 << 31) == 0).count();
    println!("triples,randu,9x - 6y + z a multiple of 2^31 in {} of 10000,planes {},mt19937 {} of 10000", on, planes, on_mt);
    let (s1, s2) = (lcg(16807, 0, P, 1, 1000), lcg(16807, 0, P, 2, 1000));
    let twice = s1.iter().zip(&s2).filter(|&(a, b)| *b == 2 * a % P).count();
    println!("seeds,minstd seed 1 {},seed 2 {},seed-2 output = 2 x seed-1 output mod m in {} of 1000",
             fl(&s1[..3], P as f64, 6), fl(&s2[..3], P as f64, 6), twice);
    let ((a1, se1), (a2, _), (b1, seb)) = (darts(20260929), darts(20260929), darts(20260930));
    let pi = std::f64::consts::PI;
    println!("darts,100000 each,seed 20260929 run 1 {:.5} ({} hits),run 2 {:.5},se {:.5}", a1, (a1 * 25000.0).round() as u64, a2, se1);
    println!("darts,seed 20260930 {:.5},se {:.5},pi {:.5},gap between seeds {:.5}", b1, seb, pi, (a1 - b1).abs());
    assert!(toy.iter().copied().collect::<BTreeSet<u64>>().len() == 16 && pairs.iter().all(|&(x, y)| (x + 3 * y) % 16 == 9));
    assert!(rule_ok && cycle(5, 2, 16, 7) == 8 && cycle(3, 3, 16, 7) == 8);   // rule = brute force; broken rule halves
    assert!(step == 1043618065 && jump == 1043618065);                 // three roads to minstd's 10000th
    assert!(mt_out[9999] == 4123659995 && sm[9999] == jump_sm);          // published value; counter jump
    assert!((pvalue(16.919) - 0.05).abs() < 1e-4);                     // own integrator = printed table
    assert!(on == 10000 && planes == 15 && on_mt < 5);                 // a^2 = 6a - 9 predicts the planes
    assert!(twice == 1000);                                            // algebra predicts the seed clone
    assert!((a1 * 25000.0).round() as u64 == 78464 && a1 != b1);       // the Python run's hits; new seed, new run
    assert!((a1 - pi).abs() < 4.0 * se1 && (b1 - pi).abs() < 4.0 * seb);
    assert!(pv.iter().all(|&p| p > 0.001) && low <= 14);               // 5 in 100 expected, sd about 2
    println!("ALL CHECKS PASS");
}
