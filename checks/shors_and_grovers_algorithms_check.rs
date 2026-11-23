// Shor and Grover -- the same check as the Python, in Rust.  No crates.  The
// state-vector idea (a list of complex amplitudes, one per basis state,
// rewritten by each gate) is the one the Qubits card explains.  Toy sizes:
// 15 and 21 are insecure on purpose.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                       // a small complex number
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn norm2(self) -> f64 { self.re * self.re + self.im * self.im }
}
const ZERO: C = C { re: 0.0, im: 0.0 };

fn gcd(mut a: i64, mut b: i64) -> i64 {             // Euclid's algorithm, written out
    while b != 0 { (a, b) = (b, a % b) } a
}

fn powmod(a: i64, e: i64, n: i64) -> i64 {          // a multiplied in e times, wrapped at n
    let mut out = 1;
    for _ in 0..e { out = out * a % n } out
}

fn order(a: i64, n: i64) -> i64 {                   // road one: multiply until the powers return to 1
    let (mut r, mut p) = (1, a % n);
    while p != 1 { p = p * a % n; r += 1 } r
}

fn qft(v: &mut Vec<C>, t: usize) -> Vec<C> {        // road two: the QFT as a circuit of gates
    let q = 1usize << t;
    let s = 1.0 / 2f64.sqrt();
    for j in (0..t).rev() {                         // top qubit first
        for x in 0..q {                             // Hadamard on qubit j
            if x >> j & 1 == 0 {
                let (a0, a1) = (v[x], v[x | 1 << j]);
                (v[x], v[x | 1 << j]) = (a0.add(a1).scale(s), a0.sub(a1).scale(s));
            }
        }
        for k in (0..j).rev() {                     // controlled phase: angle pi / 2^(j-k)
            let ang = PI / (1u64 << (j - k)) as f64;
            let ph = C { re: ang.cos(), im: ang.sin() };
            for x in 0..q {
                if x >> j & 1 == 1 && x >> k & 1 == 1 { v[x] = v[x].mul(ph) }
            }
        }
    }
    let mut out = vec![ZERO; q];                    // swap the qubit order end for end
    for x in 0..q {
        let rev = (0..t).map(|b| (x >> b & 1) << (t - 1 - b)).sum::<usize>();
        out[rev] = v[x];
    }
    out
}

fn dft(v: &[C], q: usize) -> Vec<C> {               // the same transform as the direct sum over x
    let roots: Vec<C> = (0..q).map(|m| { let a = 2.0 * PI * m as f64 / q as f64; C { re: a.cos(), im: a.sin() } }).collect();
    (0..q).map(|y| (0..q).fold(ZERO, |acc, x| acc.add(v[x].mul(roots[x * y % q]))).scale(1.0 / (q as f64).sqrt())).collect()
}

fn shor_probs(n: i64, a: i64, t: usize) -> (Vec<f64>, Vec<(i64, Vec<C>)>) {
    let q = 1usize << t;
    let mut rows: Vec<(i64, Vec<C>)> = Vec::new();  // work-register value, counting amplitudes
    let mut p = 1;
    for x in 0..q {                                 // the state x, a^x mod n, written straight down
        let i = match rows.iter().position(|r| r.0 == p) { Some(i) => i, None => { rows.push((p, vec![ZERO; q])); rows.len() - 1 } };
        rows[i].1[x] = C { re: 1.0 / (q as f64).sqrt(), im: 0.0 };
        p = p * a % n;
    }
    let mut probs = vec![0.0; q];
    for r in &rows { let f = qft(&mut r.1.clone(), t); for y in 0..q { probs[y] += f[y].norm2() } }
    (probs, rows)
}

fn convergents(mut y: i64, mut q: i64) -> Vec<i64> { // Euclid on y/q: each convergent's denominator
    let (mut dens, mut d0, mut d1) = (Vec::new(), 1, 0);
    while q != 0 {
        let c = y / q;
        (y, q, d0, d1) = (q, y - c * q, d1, c * d1 + d0);
        dens.push(d1);
    }
    dens
}

fn read_period(y: i64, q: i64, a: i64, n: i64) -> i64 { // first small denominator d with a^d = 1 mod n
    convergents(y, q).into_iter().find(|&d| d < n && powmod(a, d, n) == 1).unwrap_or(0)
}

fn shor(n: i64, a: i64, t: usize) -> (Vec<f64>, Vec<(i64, Vec<C>)>, i64, f64, i64) {
    let (q, r) = (1usize << t, order(a, n));
    let (probs, rows) = shor_probs(n, a, t);
    let pw: Vec<i64> = (1..=r).map(|e| powmod(a, e, n)).collect();
    let mut ws: Vec<i64> = rows.iter().map(|r| r.0).collect(); ws.sort();
    println!("Shor, N = {}, a = {}: powers {:?}, period by multiplying {}", n, a, pw, r);
    println!("counting register {} qubits, Q = {}; work values {:?}; total probability {:.4}", t, q, ws, probs.iter().sum::<f64>());
    let mut idx: Vec<usize> = (0..q).collect();
    idx.sort_by(|&u, &w| probs[w].partial_cmp(&probs[u]).unwrap());
    let mut peaks: Vec<usize> = idx[..r as usize].to_vec(); peaks.sort();
    for &y in &peaks {
        let rs = match read_period(y as i64, q as i64, a, n) { 0 => "none".to_string(), d => d.to_string() };
        println!("  y = {:3}    {:<25} {:.4}  denominators {:?}  period read {}", y, "█".repeat((100.0 * probs[y]).round() as usize), probs[y], convergents(y as i64, q as i64), rs);
    }
    let inside: f64 = peaks.iter().map(|&y| probs[y]).sum(); // every other y, as one more bar; one block = 0.01
    println!("  other {:3}  {:<25} {:.4}", q - r as usize, "█".repeat((100.0 * (1.0 - inside)).round() as usize), 1.0 - inside);
    let win: f64 = (0..q).filter(|&y| read_period(y as i64, q as i64, a, n) == r).map(|y| probs[y]).sum();
    let h = powmod(a, r / 2, n);
    println!("chance one run reads the period: {:.4}; outside the {} peaks: {:.4}", win, r, 1.0 - inside);
    println!("{}^{} mod {} = {}; gcd({}, {}) = {}; gcd({}, {}) = {}", a, r / 2, n, h, h - 1, n, gcd(h - 1, n), h + 1, n, gcd(h + 1, n));
    (probs, rows, r, win, h)
}

fn main() {
    let (_p15, rows15, _r15, win15, h15) = shor(15, 7, 8);
    let row7 = &rows15.iter().find(|r| r.0 == 7).unwrap().1;
    let (direct, circuit) = (dft(row7, 256), qft(&mut row7.clone(), 8));
    let gap = (0..256).map(|y| direct[y].sub(circuit[y]).norm2().sqrt()).fold(0.0, f64::max);
    println!("QFT circuit, {} Hadamards and {} phase gates, against the direct sum, gap below 1e-9: {}", 8, 8 * 7 / 2, if gap < 1e-9 { "yes" } else { "no" });
    let mut good = 0;
    for a in 2..15 {
        if gcd(a, 15) == 1 {
            let r = order(a, 15);
            let h = powmod(a, r / 2, 15);
            let ok = r % 2 == 0 && h != 14;
            good += ok as i64;
            println!("  a = {:2}: period {}, a^(r/2) mod 15 = {:2}, gcds {} and {}{}", a, r, h, gcd(h - 1, 15), gcd(h + 1, 15), if ok { "" } else { "  (fails)" });
        }
    }
    println!("bases that split 15: {} of 7", good);
    let (p21, _rows21, r21, win21, _h21) = shor(21, 2, 9);
    let p64 = shor_probs(21, 2, 6).0;
    let w64: f64 = (0..64).filter(|&y| read_period(y, 64, 2, 21) == 6).map(|y| p64[y as usize]).sum();
    println!("register too small, N = 21, Q = 64: chance one run reads the period {:.4}", w64);

    let (m, key) = (1024usize, 700usize);
    let theta = (1.0 / (m as f64).sqrt()).asin();
    let best = (PI / (4.0 * theta)) as i64;
    let mut v = vec![1.0 / (m as f64).sqrt(); m];
    let mut sim = Vec::new();                       // road one: the 1024 amplitudes, gate by gate
    for _ in 0..51 {
        sim.push(v[key] * v[key]);
        v[key] = -v[key];                           // oracle U_f: flip the key's sign
        let mean = v.iter().sum::<f64>() / m as f64;
        v = v.iter().map(|x| 2.0 * mean - x).collect(); // diffusion: reflect every amplitude about the mean
    }
    let form: Vec<f64> = (0..51).map(|k| ((2 * k + 1) as f64 * theta).sin().powi(2)).collect();
    let mut u = vec![1.0 / (m as f64).sqrt(); m];
    for _ in 0..25 { u[key] = -u[key] }             // mistake 4: the oracle alone, no diffusion
    println!("Grover, M = {}, key {}: theta = asin(1/32) = {:.6}, best rounds floor(pi/(4 theta)) = {}", m, key, theta, best);
    for k in (0..51).step_by(5) { println!("  rounds {:2}: simulated {:.4}  formula {:.4}", k, sim[k], form[k]) }
    println!("rounds 25: {:.4}; rounds 32: {:.4}; oracle only, 25 rounds: {:.6}", sim[25], sim[32], u[key] * u[key]);
    println!("classical, one look at a time: average {:.1} looks; looks for 0.9995: {:.0}", (m as f64 + 1.0) / 2.0, (0.9995 * m as f64).ceil());
    let th4 = 0.5f64.asin();
    println!("two qubits, M = 4: best rounds {}, success {:.4}", (PI / (4.0 * th4)) as i64, (3.0 * th4).sin().powi(2));
    for s in [10, 20, 30, 40] {
        let th = 2f64.powf(-(s as f64) / 2.0).asin();
        println!("  M = 2^{}: Grover rounds {}, classical average {:.1}", s, (PI / (4.0 * th)) as i64, ((1u64 << s) as f64 + 1.0) / 2.0);
    }
    println!("mistake 1, a = 14: 14^1 mod 15 = 14 = 15 - 1, gcds {} and {}", gcd(13, 15), gcd(15, 15));
    println!("mistake 2, y = 128 read as 1/2: 7^2 mod 15 = {}, not 1", powmod(7, 2, 15));
    println!("mistake 3, {} rounds instead of {}: success {:.4}", 32, best, sim[32]);
    assert!((0..51).all(|k| (sim[k] - form[k]).abs() < 1e-9));        // simulation against closed form
    assert!(gap < 1e-9);                                               // circuit against direct sum
    assert!(read_period(64, 256, 7, 15) == order(7, 15) && order(7, 15) == 4);
    assert!(gcd(h15 - 1, 15) * gcd(h15 + 1, 15) == 15 && gcd(h15 - 1, 15) != 1 && gcd(h15 - 1, 15) != 15);
    assert!((win15 - 0.5).abs() < 1e-9 && best == 25 && good == 6);
    assert!(read_period(85, 512, 2, 21) == r21 && r21 == 6 && win21 > 0.3 && w64 < 0.3 && (p21.iter().sum::<f64>() - 1.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
