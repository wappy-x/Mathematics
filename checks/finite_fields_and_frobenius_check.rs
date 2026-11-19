// Finite fields and Frobenius -- the same check as the Python, in Rust.  No crates.
// A byte is a polynomial over GF(2): bit i is the coefficient of x^i, so hex 1b is
// x^4 + x^3 + x + 1.  The field is every byte, wrapped by MOD = 11b, the polynomial
// x^8 + x^4 + x^3 + x + 1.  Frobenius squares.  Subfields are found by Frobenius and
// again by spanning each byte's powers; automorphisms are found by root search; and
// a second field, wrapped by OTHER = 11d, is renamed onto the first.
use std::collections::BTreeSet;
const DEG: u32 = 8;
const MOD: usize = 0x11B;
const OTHER: usize = 0x11D;
const SIZE: usize = 1 << DEG;

fn mul(mut u: usize, mut v: usize, md: usize) -> usize { // shift and XOR, fold at md
    let mut out = 0;
    while v != 0 {
        if v & 1 == 1 { out ^= u }
        v >>= 1;
        u <<= 1;
        if (u >> DEG) & 1 == 1 { u ^= md }
    }
    out
}
fn bits(a: usize) -> u32 { usize::BITS - a.leading_zeros() }
fn pmod(mut a: usize, b: usize) -> usize {          // remainder of polynomial a by b, over GF(2)
    while a != 0 && bits(a) >= bits(b) { a ^= b << (bits(a) - bits(b)) }
    a
}
fn irreducible(f: usize) -> bool {                  // trial division by every g of degree 1 .. deg f / 2
    (2..(1usize << ((bits(f) - 1) / 2 + 1))).all(|g| pmod(f, g) != 0)
}
struct F { t: Vec<usize> }
impl F {
    fn m(&self, a: usize, b: usize) -> usize { self.t[a * SIZE + b] }
    fn frob(&self, mut a: usize, k: u32) -> usize { for _ in 0..k { a = self.m(a, a) } a }
    fn inv(&self, a: usize) -> usize { (1..DEG).fold(1, |out, k| self.m(out, self.frob(a, k))) } // a^(2 + 4 + ... + 128) = a^254
    fn at(&self, f: usize, r: usize) -> usize {     // f evaluated at the byte r, by Horner's rule
        let mut out = 0;
        for i in (0..bits(f)).rev() { out = self.m(out, r) ^ ((f >> i) & 1) }
        out
    }
    fn rename(&self, src: usize, r: usize) -> (Vec<usize>, bool) { // send x to r
        let mut pw = vec![1usize];
        for _ in 0..DEG - 1 { let p = self.m(*pw.last().unwrap(), r); pw.push(p) }
        let out: Vec<usize> = (0..SIZE).map(|a| (0..DEG as usize).filter(|i| (a >> i) & 1 == 1)
            .fold(0, |s, i| s ^ pw[i])).collect();
        let distinct = out.iter().collect::<BTreeSet<_>>().len() == SIZE;
        let ok = distinct && (0..SIZE).all(|a| (0..SIZE).all(|b|
            out[mul(a, b, src)] == self.m(out[a], out[b])));
        (out, ok)
    }
    fn span(&self, a: usize) -> Vec<usize> {        // GF(2)-span of the powers of a
        let (mut s, mut p) = (BTreeSet::from([0usize]), 1usize);
        for _ in 0..SIZE {
            if !s.contains(&p) { let add: Vec<usize> = s.iter().map(|x| x ^ p).collect(); s.extend(add) }
            p = self.m(p, a);
            if p == 1 { break }
        }
        s.into_iter().collect()
    }
    fn powers(&self, a: usize) -> Vec<usize> {      // 1, a, a^2, ... until the return to 1
        let mut out = vec![1usize];
        while self.m(*out.last().unwrap(), a) != 1 && out.len() < SIZE {
            let p = self.m(*out.last().unwrap(), a);
            out.push(p);
        }
        out
    }
}
fn hx(xs: &[usize]) -> String { xs.iter().map(|x| format!("{:02x}", x)).collect::<Vec<_>>().join(" ") }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn poly(v: usize) -> String { (0..bits(v)).rev().filter(|i| (v >> i) & 1 == 1).map(|i| match i { 0 => "1".to_string(), 1 => "x".to_string(), _ => format!("x^{}", i) }).collect::<Vec<_>>().join(" + ") }
fn commas(n: usize) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    out
}

fn main() {
    let divs: Vec<u32> = (1..=DEG).filter(|d| DEG % d == 0).collect();
    let f = F { t: (0..SIZE * SIZE).map(|i| mul(i / SIZE, i % SIZE, MOD)).collect() };
    let recip = (1..SIZE).all(|a| (0..SIZE).any(|b| f.m(a, b) == 1));
    let recip254 = (1..SIZE).all(|a| f.m(f.inv(a), a) == 1);
    let additive = (0..SIZE).all(|a| (0..SIZE).all(|b| f.frob(a ^ b, 1) == f.frob(a, 1) ^ f.frob(b, 1)));
    let order = (1..SIZE as u32).find(|&k| (0..SIZE).all(|a| f.frob(a, k) == a)).unwrap_or(0);
    let mut orb = vec![2usize];
    while f.frob(*orb.last().unwrap(), 1) != 2 && orb.len() < SIZE { let x = f.frob(*orb.last().unwrap(), 1); orb.push(x) }
    let roots: Vec<usize> = (0..SIZE).filter(|&r| f.at(MOD, r) == 0).collect();
    let autos: Vec<(Vec<usize>, bool)> = roots.iter().map(|&r| f.rename(MOD, r)).collect();
    let mut as_frob: Vec<i64> = autos.iter().filter(|(_, ok)| *ok).map(|(t, _)| (0..DEG)
        .find(|&k| (0..SIZE).all(|a| t[a] == f.frob(a, k))).map(|k| k as i64).unwrap_or(-1)).collect();
    as_frob.sort();
    let fixed: Vec<Vec<usize>> = (0..=DEG).map(|d| (0..SIZE).filter(|&a| f.frob(a, d) == a).collect()).collect();
    let mut by_span: Vec<Vec<usize>> = (1..SIZE).map(|a| f.span(a)).collect::<BTreeSet<_>>().into_iter().collect();
    by_span.sort_by_key(|s| s.len());
    let g = (2..SIZE).find(|&a| f.powers(a).len() == SIZE - 1).unwrap_or(1);
    let gpow = f.powers(g);
    let mut gf4: Vec<usize> = vec![0];
    gf4.extend((0..SIZE - 1).step_by((SIZE - 1) / 3).map(|k| gpow[k]));
    gf4.sort();
    let orbits: BTreeSet<Vec<usize>> = (0..SIZE).map(|a| (0..DEG).map(|k| f.frob(a, k))
        .collect::<BTreeSet<_>>().into_iter().collect()).collect();
    let n_orb: Vec<usize> = divs.iter().map(|&d| orbits.iter().filter(|o| o.len() == d as usize).count()).collect();
    let n_irr: Vec<usize> = divs.iter().map(|&d| ((1usize << d)..(2usize << d)).filter(|&p| irreducible(p)).count()).collect();
    let oroots: Vec<usize> = (0..SIZE).filter(|&r| f.at(OTHER, r) == 0).collect();
    let renamings: Vec<bool> = oroots.iter().map(|&r| f.rename(OTHER, r).1).collect();
    let bad = (1usize << DEG) | 1;                  // x^8 + 1 = (x + 1)^8: reducible
    let no_recip = (1..SIZE).filter(|&a| !(0..SIZE).any(|b| mul(a, b, bad) == 1)).count();
    let even = (1..SIZE).filter(|a| a.count_ones() % 2 == 0).count();
    let clock = (0..SIZE).filter(|a| !(0..SIZE).any(|b| a * b % SIZE == 1)).count();
    let cube = |a: usize| f.m(f.m(a, a), a);
    let mut quart = 0;
    for b in 0..5 { for c in 0..5 { for d in 0..5 { for e in 0..5 {
        if ((b + d) % 5, (c + e + b * d) % 5, (b * e + c * d) % 5, c * e % 5) == (0, 0, 0, 3) { quart += 1 }
    } } } }
    let lin = (0..5i64).filter(|a| (a.pow(4) - 2) % 5 == 0).count();
    let sumdn: usize = divs.iter().zip(&n_irr).map(|(&d, &n)| d as usize * n).sum();
    let sizes: Vec<usize> = by_span.iter().map(|s| s.len()).collect();
    let same = by_span == divs.iter().map(|&d| fixed[d as usize].clone()).collect::<Vec<_>>();

    println!("field: bytes wrapped by {:x}; irreducible by trial division: {}; {} elements", MOD, yn(irreducible(MOD)), SIZE);
    println!("every nonzero byte has a reciprocal: {}; a^{} = a^2 a^4 ... a^{} is it, for all {}: {}", yn(recip), SIZE - 2, SIZE / 2, SIZE - 1, yn(recip254));
    let b8 = f.frob(2, 3);
    println!("Frob(02) = {:02x}, Frob(03) = {:02x}, 02^8 = {:02x}; Frob({:02x}) = {} before the wrap, {:02x} after", f.frob(2, 1), f.frob(3, 1), b8, b8, poly(mul(b8, b8, 0)), f.frob(2, 4));
    println!("Frob(a + b) = Frob(a) + Frob(b) for all {} pairs: {}", commas(SIZE * SIZE), yn(additive));
    println!("smallest k with Frob^k = identity: {}; so a^{} = a for every byte", order, SIZE);
    println!("orbit of 02 under Frob: {}", hx(&orb));
    println!("roots of {:x} found by trying all {} bytes: {}", MOD, SIZE, hx(&roots));
    println!("symmetries made by sending 02 to a root: {} of {}; each is Frob^k for k = {:?}",
             autos.iter().filter(|(_, ok)| *ok).count(), roots.len(), as_frob);
    println!("bytes fixed by Frob^d, d = 1..{}: {:?}", DEG, (1..=DEG as usize).map(|d| fixed[d].len()).collect::<Vec<_>>());
    println!("subfields found by spanning powers: sizes {:?}", sizes);
    println!("the same sets Frob^d fixes for d = {:?}: {}", divs, yn(same));
    println!("generator g = {:02x}, of order {}", g, SIZE - 1);
    println!("GF(4) inside: {}; as 0, 1, g^85, g^170: {}; its two new bytes add to {:02x}", hx(&fixed[2]), hx(&gf4), gf4[2] ^ gf4[3]);
    println!("GF(16) inside: {}", hx(&fixed[4]));
    println!("Frobenius orbits of size {:?}: {:?}; {} orbits in all", divs, n_orb, orbits.len());
    println!("irreducible polynomials of degree {:?}, by trial division: {:?}", divs, n_irr);
    println!("sum of degree x count: {} = {}", divs.iter().zip(&n_irr).map(|(d, n)| format!("{}*{}", d, n))
             .collect::<Vec<_>>().join(" + "), sumdn);
    println!("second field {:x} irreducible: {}; its roots in the first: {}", OTHER, yn(irreducible(OTHER)), hx(&oroots));
    println!("renamings x -> root that respect + and x on all pairs: {} of {}", renamings.iter().filter(|&&b| b).count(), oroots.len());
    println!("mistake 1, wrap by {:x} = (x + 1)^8: {} nonzero bytes have no reciprocal (nonzero bytes with an even count of 1 bits: {})", bad, no_recip, even);
    println!("mistake 2, the clock mod {}: {} numbers have no reciprocal; (1 + 1)^2 = {}, 1^2 + 1^2 = {}", SIZE, clock, 4 % SIZE, 2 % SIZE);
    println!("mistake 3, an 8-element subfield: a^8 = a holds for {} bytes: {}", fixed[3].len(), hx(&fixed[3]));
    println!("mistake 4, cubing for squaring: (02 + 01)^3 = {:02x}, 02^3 + 01^3 = {:02x}", cube(3), cube(2) ^ cube(1));
    println!("house: x^4 - 2 over GF(5): {} roots, {} splittings into two quadratics: irreducible", lin, quart);
    assert!(irreducible(MOD) && recip && recip254 && additive && order == DEG);
    let mut so = orb.clone(); so.sort();
    assert!(so == roots && roots.len() == DEG as usize && as_frob == (0..DEG as i64).collect::<Vec<_>>());
    assert!(same && sizes == divs.iter().map(|&d| 1usize << d).collect::<Vec<_>>());
    assert!(gf4 == fixed[2] && gf4[2] ^ gf4[3] == 1 && n_orb == n_irr && sumdn == SIZE);
    assert!(irreducible(OTHER) && renamings.iter().all(|&b| b) && oroots.len() == DEG as usize);
    assert!(no_recip == even && clock == SIZE / 2 && fixed[3].len() == 1 << (if DEG % 3 == 0 { 3 } else { 1 }));
    assert!(cube(3) != cube(2) ^ cube(1) && lin == 0 && quart == 0);
    println!("ALL CHECKS PASS");
}
