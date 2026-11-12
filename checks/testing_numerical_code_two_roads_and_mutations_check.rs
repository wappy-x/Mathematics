// Two roads and a mutation -- the same check as the Python, in Rust.  No crates.
// Road 1: a lookup table of nearest codewords, built by brute force.  Road 2: the
// syndrome.  Five bugs are planted one at a time; each test is scored by its kills.
const GROUPS: [[usize; 4]; 3] = [[1, 3, 5, 7], [2, 3, 6, 7], [4, 5, 6, 7]];
const DATA: [usize; 4] = [3, 5, 6, 7];
type W7 = [u8; 7];

fn bits<const N: usize>(x: usize) -> [u8; N] {
    let mut b = [0u8; N];
    for i in 0..N { b[i] = ((x >> (N - 1 - i)) & 1) as u8; }
    b
}
fn show(b: &[u8]) -> String { b.iter().map(|x| x.to_string()).collect() }

fn encode(m: [u8; 4]) -> W7 {
    let mut c = [0u8; 8];
    for i in 0..4 { c[DATA[i]] = m[i]; }
    for g in GROUPS.iter() { c[g[0]] = (c[g[1]] + c[g[2]] + c[g[3]]) % 2; }
    let mut w = [0u8; 7]; w.copy_from_slice(&c[1..]); w
}
fn dist(a: &W7, b: &W7) -> usize { (0..7).filter(|&i| a[i] != b[i]).count() }

struct Code { mutant: &'static str, codewords: Vec<W7>, table: Vec<W7> }

impl Code {
    fn new() -> Code {
        let codewords: Vec<W7> = (0..16).map(|x| encode(bits::<4>(x))).collect();
        let mut table = Vec::new();
        for x in 0..128 {                       // nearest codeword, by brute force
            let r: W7 = bits::<7>(x);
            let mut best = codewords[0];
            for c in codewords.iter() { if dist(&r, c) < dist(&r, &best) { best = *c; } }
            table.push(best);
        }
        Code { mutant: "", codewords, table }
    }
    fn extract(&self, c: &W7) -> [u8; 4] {     // shared by both roads
        let w = if self.mutant == "M5" { [5, 3, 6, 7] } else { DATA };
        [c[w[0] - 1], c[w[1] - 1], c[w[2] - 1], c[w[3] - 1]]
    }
    fn road1(&self, r: &W7) -> [u8; 4] {
        let mut c = self.table[usize::from_str_radix(&show(r), 2).unwrap()];
        if self.mutant == "M3" && show(r) == "0000011" { c = self.codewords[15]; }
        self.extract(&c)
    }
    fn syndrome(&self, r: &W7) -> usize {
        let mut s = 0;
        for (k, g) in GROUPS.iter().enumerate() {
            let mut sum = 0;
            for &p in g.iter() {
                if self.mutant == "M2" && k == 1 && p == 7 { continue; }
                sum += r[p - 1] as usize;
            }
            s += (sum % 2) << k;
        }
        if self.mutant == "M1" { s = ((s & 1) << 2) | (s & 2) | (s >> 2); }
        s
    }
    fn road2(&self, r: &W7) -> [u8; 4] {
        let (s, mut c) = (self.syndrome(r), *r);
        if s > 0 && self.mutant != "M4" { c[s - 1] ^= 1; }
        self.extract(&c)
    }
    fn test(&self, t: usize, words: &[W7], pin: &W7) -> bool {
        match t {
            0 => words.iter().all(|r| self.road2(r) == self.road2(r)),
            1 => (0..16).all(|x| self.road2(&encode(bits::<4>(x))) == bits::<4>(x)),
            2 => words.iter().all(|r| self.road1(r) == self.road2(r)),
            _ => self.road2(pin) == [0, 1, 0, 0],
        }
    }
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
fn p_catch(w: usize, k: i32) -> f64 { 1.0 - (1.0 - w as f64 / 128.0).powi(k) }
fn k_for(w: usize, goal: f64) -> f64 { ((1.0 - goal).ln() / (1.0 - w as f64 / 128.0).ln()).ceil() }

fn main() {
    let mut code = Code::new();
    let words: Vec<W7> = (0..128).map(|x| bits::<7>(x)).collect();
    let pin: W7 = [1, 0, 0, 1, 1, 1, 0];
    let names = ["T0 tautology: road 2 equals road 2", "T1 round trip, 16 clean codewords",
                 "T2 two roads agree on all 128 words", "T3 pinned hand value 1001110 -> 0100"];
    let mutants = [("M1", "syndrome bits read backwards"), ("M2", "check 2 forgets position 7"),
                   ("M3", "one typo in the table"), ("M4", "decoder forgets to flip"),
                   ("M5", "shared extract swaps d1, d2")];

    println!("codeword for 0100 {}", show(&encode([0, 1, 0, 0])));
    println!("pinned word {} syndrome {} -> road 1 {} road 2 {}", show(&pin), code.syndrome(&pin),
             show(&code.road1(&pin)), show(&code.road2(&pin)));
    let sums: Vec<usize> = GROUPS.iter().map(|g| g.iter().map(|&p| pin[p - 1] as usize).sum()).collect();
    println!("pinned word check sums {} {} {} -> parities {} {} {}", sums[0], sums[1], sums[2],
             sums[0] % 2, sums[1] % 2, sums[2] % 2);
    let d: Vec<String> = code.codewords.iter().map(|c| dist(&pin, c).to_string()).collect();
    println!("distances from pinned word to the 16 codewords {}", d.join(" "));
    let agree = words.iter().filter(|r| code.road1(r) == code.road2(r)).count();
    let mut single = 0;
    for c in code.codewords.iter() {
        for p in 0..7 { let mut r = *c; r[p] ^= 1; if code.syndrome(&r) == p + 1 { single += 1; } }
    }
    println!("clean: roads agree on {} of 128; syndrome = position on {} of 112 one-flip words", agree, single);
    let g_columns = ["1110000", "1001100", "0101010", "1101001"]; // from the Hamming card's G
    assert!((0..4).all(|i| show(&encode(bits::<4>(8 >> i))) == g_columns[i]), "encoder matches G");
    assert!(agree == 128, "the two roads must agree on every word");
    assert!(single == 112, "one flip at position p must give syndrome p");
    assert!((0..4).all(|t| code.test(t, &words, &pin)), "every test passes on clean code");
    assert!(code.syndrome(&pin) == 6, "hand value: the checks name position 6");
    assert!(show(&code.road2(&pin)) == "0100", "hand value: 1001110 decodes to 0100");

    println!();
    println!("mutant   w  T0 T1 T2 T3  pin  what was broken");
    let (mut kills, mut ws, mut any_kill) = ([0; 4], Vec::new(), 0);
    for (m, what) in mutants.iter() {
        code.mutant = m;
        let w = words.iter().filter(|r| code.road1(r) != code.road2(r)).count();
        ws.push(w);
        let mut row = Vec::new();
        for t in 0..4 {
            let caught = !code.test(t, &words, &pin);
            if caught { kills[t] += 1; }
            row.push(if caught { " K" } else { " -" });
        }
        if row[1..].contains(&" K") { any_kill += 1; }
        println!("{:<6}{:>4} {}  {} {}", m, w, row.join(" "), show(&code.road2(&pin)), what);
    }
    code.mutant = "M1";
    let mut flipped = pin; flipped[code.syndrome(&pin) - 1] ^= 1;
    println!("M1 on pinned word: syndrome {} flipped word {} data {}", code.syndrome(&pin), show(&flipped), show(&code.road2(&pin)));
    code.mutant = "";
    println!();
    for t in 0..4 { println!("{:<40} kills {} of 5", names[t], kills[t]); }
    println!("{:<40} kills {} of 5", "T1 + T2 + T3 together", any_kill);
    assert!(kills[1..] == [1, 4, 3], "T1, T2 and T3 kill 1, 4 and 3 of the 5");
    assert!(ws[4] == 0 && any_kill == 5, "two roads miss shared code; the pin catches it");

    let mut rng = SplitMix(20261111);
    println!();
    println!("mutant   w  P(catch), 5 random words  simulated, 20000 runs  words for 99%");
    for i in 0..4 {
        code.mutant = mutants[i].0;
        let bad: Vec<bool> = words.iter().map(|r| code.road1(r) != code.road2(r)).collect();
        let mut hits = 0;
        for _ in 0..20000 {
            if (0..5).map(|_| bad[(rng.next() % 128) as usize]).fold(false, |a, b| a | b) { hits += 1; }
        }
        let (sim, f) = (hits as f64 / 20000.0, p_catch(ws[i], 5));
        println!("{:<6}{:>4}  {:>24.4}  {:>22.4}  {:>13}", mutants[i].0, ws[i], f, sim, k_for(ws[i], 0.99));
        assert!((sim - f).abs() < 4.0 * (f * (1.0 - f) / 20000.0).sqrt(), "simulation must meet the formula");
    }
    let q = 1.0 - 1.0 / 128.0_f64;
    println!("by hand, w = 1: 1 - w/128 = {:.5}, to the 5th = {:.5}, catch = {:.5}", q, q.powi(5), 1.0 - q.powi(5));
    println!("by hand, 99%: ln 0.01 = {:.5}, ln(127/128) = {:.7}, ratio = {:.2}", 0.01_f64.ln(), q.ln(),
             0.01_f64.ln() / q.ln());
    println!();
    let ks = [1, 5, 10, 20, 50, 100, 200, 400, 600];
    println!("chart, words tested k{}", ks.iter().map(|k| format!("{:>7}", k)).collect::<String>());
    for w in [64, 32, 1] {
        println!("chart, w = {:<10}{}", w, ks.iter().map(|&k| format!("{:>7.3}", p_catch(w, k))).collect::<String>());
    }
    println!("ALL CHECKS PASS");
}
