// Ideals and quotient rings -- the same check as the Python, in Rust.  No crates.  An
// invoice claims 47 crates at $23 each come to $1,081.  Casting out nines maps the
// whole numbers to Z mod 9, with the multiples of 9 as its kernel; the class of the
// total is reached by three roads, no two sharing a step.  Polynomials follow.
const A: i64 = 47; const B: i64 = 23; const N: i64 = 9;
fn digit_class(mut n: i64) -> i64 {      // a road with no division by 9 in it at all
    while n > 9 {
        let mut s = 0;
        while n > 0 { s += n % 10; n /= 10; }
        n = s;
    }
    if n == 9 { 0 } else { n }
}
fn is_ideal<T: Copy + PartialEq>(ring: &[T], sub: &[T], add: fn(T, T) -> T,
                                 mul: fn(T, T) -> T) -> bool {
    let closed = sub.iter().all(|&a| sub.iter().all(|&b| sub.iter().any(|&c| add(b, c) == a)));
    closed && ring.iter().all(|&r| sub.iter()
        .all(|&a| sub.contains(&mul(r, a)) && sub.contains(&mul(a, r))))
}
fn cadd(a: i64, b: i64) -> i64 { (a + b).rem_euclid(12) }          // the 12-hour clock
fn cmul(a: i64, b: i64) -> i64 { (a * b).rem_euclid(12) }
fn wadd(p: (i64, i64), q: (i64, i64)) -> (i64, i64) { ((p.0 + q.0) % 3, (p.1 + q.1) % 3) }
fn wmul(p: (i64, i64), q: (i64, i64)) -> (i64, i64) { pair_product(p, q, 3) }
fn reduce_poly(c: &[i64]) -> (i64, i64) {  // x^2 + 1 is zero, so x^k becomes -x^(k-2)
    let mut v = c.to_vec();
    while v.len() > 2 {
        let top = v.pop().unwrap();
        let k = v.len() - 2; v[k] -= top;
    }
    (v[0], v[1])
}
fn poly_product(a: &[i64], b: &[i64]) -> (Vec<i64>, (i64, i64)) {
    let mut raw = vec![0; a.len() + b.len() - 1];   // multiply out in full, then reduce
    for i in 0..a.len() { for j in 0..b.len() { raw[i + j] += a[i] * b[j]; } }
    (raw.clone(), reduce_poly(&raw))
}
fn pair_product(a: (i64, i64), b: (i64, i64), m: i64) -> (i64, i64) {   // coordinates
    let (c, d) = (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0);
    if m != 0 { (c.rem_euclid(m), d.rem_euclid(m)) } else { (c, d) }
}
fn reciprocals(n: i64) -> usize {        // how many nonzero classes have a reciprocal
    (1..n).filter(|&a| (1..n).any(|b| (a * b).rem_euclid(n) == 1)).count()
}
fn main() {
    let (total, direct, classes) = (A * B, (A * B) % N, (A % N) * (B % N));
    let mut shifted: Vec<i64> = Vec::new();
    for i in -5..=5 {
        for j in -5..=5 { shifted.push(((A + N * i) * (B + N * j)).rem_euclid(N)); }
    }
    let kernel: Vec<i64> = (0..41).filter(|k| k % N == 0).collect();
    let clock: Vec<i64> = (0..12).collect();
    let world: Vec<(i64, i64)> = (0..3).flat_map(|c| (0..3).map(move |d| (c, d))).collect();
    let consts: Vec<(i64, i64)> = (0..3).map(|c| (c, 0)).collect();
    let ideals = [is_ideal(&clock, &[0, 3, 6, 9], cadd, cmul),
                  is_ideal(&clock, &[0, 4, 6, 8], cadd, cmul), is_ideal(&world, &consts, wadd, wmul)];
    let (raw, poly) = poly_product(&[2, 3], &[4, 1]);
    let (pair, xx) = (pair_product((2, 3), (4, 1), 0), reduce_poly(&[0, 0, 1]));
    let (r9, r7, x1) = (reciprocals(9), reciprocals(7), pair_product((0, 1), (1, 0), 0));
    let mut one = shifted.clone(); one.sort(); one.dedup();
    println!("the invoice: {} x {} = {}", A, B, total);
    println!("class of the total, three roads: remainder of {} is {}; classes {} x {} = {} then \
              {}; digit sums {}", total, direct, A % N, B % N, classes, classes % N, digit_class(total));
    println!("other names, {} x {} = {}, class {}", A + N, B + N, (A + N) * (B + N),
             ((A + N) * (B + N)) % N);
    println!("all {} shifted pairs of names give one class: {:?}", shifted.len(), one);
    println!("the wrong total 1090 has class {} too, so the check passes it", digit_class(1090));
    println!("kernel of casting out nines, 0 to 40: {:?}", kernel);
    println!("ideal test: {{0, 3, 6, 9}} in Z mod 12 {}, {{0, 4, 6, 8}} {}, the constants in the \
              x^2 = -1 world {}", ideals[0], ideals[1], ideals[2]);
    println!("(2 + 3x)(4 + x) multiplied out: {} + {}x + {}x^2", raw[0], raw[1], raw[2]);
    println!("reduced by x^2 + 1: {} + {}x; coordinates: {} + {}x", poly.0, poly.1, pair.0, pair.1);
    println!("x times x reduced: {} + {}x; x times the constant 1: {} + {}x", xx.0, xx.1, x1.0, x1.1);
    println!("zero product among nonzero classes: 3 x 3 = {} in Z mod 9; with a \
              reciprocal: {} of 8 in Z mod 9, {} of 6 in Z mod 7", (3 * 3) % 9, r9, r7);
    assert!(direct == classes % N && classes % N == digit_class(total) && direct == 1);
    assert!(one == vec![direct] && digit_class(1090) == direct && digit_class(1082) != direct);
    assert!(ideals == [true, false, false] && kernel == vec![0,9,18,27,36] && raw == vec![8, 14, 3]);
    assert!(poly == pair && pair == (5, 14) && xx == (-1, 0) && x1 == (0, 1) && r9 == 6 && r7 == 6);
    println!("ALL CHECKS PASS");
}
