// Least common multiple -- the same check as the Python twin, in Rust.  No crates.  A 6-beat drum
// pattern against an 8-beat bass line: the first beat they both come round on, three roads.
fn walk_to_shared(a: i64, b: i64) -> i64 {   // road one: step along the multiples of a until b goes in too
    let mut m = a;
    while m % b != 0 { m += a; }
    m
}
fn primes_of(n: i64) -> Vec<i64> {           // the prime pieces of n, smallest first: 8 -> 2, 2, 2
    let (mut out, mut n, mut d) = (Vec::new(), n, 2);
    while n > 1 { while n % d == 0 { out.push(d); n /= d; } d += 1; }
    out
}
fn most_of_each(a: i64, b: i64) -> Vec<i64> {  // road three: each prime, as often as the greedier of the two wants it
    let (pa, pb) = (primes_of(a), primes_of(b));
    let count = |v: &Vec<i64>, p: i64| v.iter().filter(|&&q| q == p).count();
    let mut all = [pa.clone(), pb.clone()].concat(); all.sort(); all.dedup();
    let mut out = Vec::new();
    for p in all { for _ in 0..count(&pa, p).max(count(&pb, p)) { out.push(p); } }
    out
}
fn product(fs: &[i64]) -> i64 { fs.iter().product() }
fn show(fs: &[i64], sep: &str) -> String { fs.iter().map(|f| f.to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    let (drum, bass) = (6i64, 8i64);
    let (shared, mult) = (walk_to_shared(drum, bass), most_of_each(drum, bass));
    let g = (1..=drum).filter(|d| drum % d == 0 && bass % d == 0).max().unwrap();   // gcd, from the factor lists
    let (dl, bl): (Vec<i64>, Vec<i64>) = ((1..=shared / drum).map(|k| k * drum).collect(), (1..=shared / bass).map(|k| k * bass).collect());
    println!("road one, step along the multiples -- drum comes round on {};  bass on {}", show(&dl, ", "), show(&bl, ", "));
    println!("the first beat in both lists is {}, and nothing under it is in both (checked 1 to {})", shared, shared - 1);
    println!("road two, the link -- gcd({}, {}) = {}, product {} x {} = {}, and {} / {} = {}", drum, bass, g, drum, bass, drum * bass, drum * bass, g, drum * bass / g);
    println!("road three, from the primes -- {} = {}, {} = {}, most of each = {} = {}", drum, show(&primes_of(drum), " x "), bass, show(&primes_of(bass), " x "), show(&mult, " x "), product(&mult));
    println!("over {} beats the drum plays {} loops and the bass {};  at 120 beats a minute, {} seconds", shared, shared / drum, shared / bass, shared * 60 / 120);
    println!("the three mistakes come out at {}, {} and {}", drum * bass, drum + bass, bass);
    assert!(shared == 24 && shared % drum == 0 && shared % bass == 0);
    assert!((1..shared).all(|m| m % drum != 0 || m % bass != 0));
    assert!(g * shared == drum * bass && drum * bass == 48 && product(&mult) == shared);
    println!("ALL CHECKS PASS");
}
