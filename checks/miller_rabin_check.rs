// Miller-Rabin -- the same check as miller_rabin_check.py, in Rust.  No crates.  221 =
// 13 x 17, and 220 = 4 x 55, so every chain is one power then one squaring.  174 lies;
// 18 fools the older Fermat test and is caught here; 137 is caught by both.
const N: u64 = 221;
const D: u64 = 55;
fn fast(a: u64, mut e: u64, n: u64) -> u64 {   // square and multiply, on the n clock
    let (mut r, mut b) = (1u64, a % n);
    while e > 0 {
        if e % 2 == 1 { r = r * b % n; }
        b = b * b % n; e /= 2;
    }
    r
}
fn slow(a: u64, e: u64) -> u64 {       // the same power, one multiplication at a time
    let mut r = 1u64;
    for _ in 0..e { r = r * a % N; }
    r
}
fn chain(a: u64) -> [u64; 2] { let f = fast(a, D, N); [f, f * f % N] }   // the base to the 55th, then squared
// not a witness: 1 first, or 220 anywhere
fn passes(c: [u64; 2]) -> bool { c[0] == 1 || c[0] == N - 1 || c[1] == N - 1 }
fn main() {
    println!("221 = 13 x 17, so composite; 220 = 4 x 55, so each chain is a power then a squaring");
    let roots: Vec<u64> = (0..N).filter(|x| x * x % N == 1).collect();
    println!("square roots of 1 here: {:?} -- a prime clock has only 1 and {}", roots, N - 1);
    for a in [174u64, 18, 137] {
        let (c, f) = (chain(a), fast(a, N - 1, N));
        let v = if passes(c) { "liar, says prime" } else { "witness, proves composite" };
        println!("base {:>3}: to the 55th {:>3}, squared {:>3} -> {:<25}; to the 220th {:>3} -> Fermat says {}", a, c[0], c[1], v, f, if f == 1 { "prime" } else { "composite" });
    }
    let liars = (1..N).filter(|&a| passes(chain(a))).count() as u64;
    let fermat = (1..N).filter(|&a| fast(a, N - 1, N) == 1).count() as u64;
    println!("of the 220 bases, {} fool Fermat but only {} fool Miller-Rabin; a quarter of 220 is {}", fermat, liars, (N - 1) / 4);
    let (c561, lie561): (Vec<u64>, usize) = ((0..4).map(|k| fast(2, 35 << k, 561)).collect(), (1..561u64).filter(|&a| fast(a, 35, 561) == 1 || (0..4).any(|k| fast(a, 35 << k, 561) == 560)).count());
    println!("561 = 3 x 11 x 17, a Carmichael number: 560 = 16 x 35, base 2's chain {:?} shows 67, a third root of 1, so a witness; {} of 560 bases lie", c561, lie561);
    assert!(chain(174) == [47, 220] && chain(18) == [86, 103] && chain(137) == [188, 205]);
    assert!((1..N).all(|a| fast(a, D, N) == slow(a, D)) && [174u64, 18, 137].iter().all(|&a| fast(a, 220, N) == slow(a, 220)));
    assert!(13 * 17 == N && fermat == 16 && 4 * liars <= N - 1 && liars == 6 && c561 == vec![263, 166, 67, 1] && 67 * 67 % 561 == 1 && lie561 == 10);
    println!("ALL CHECKS PASS");
}
