// Rings -- the same check as the Python, in Rust.  No crates.  The twelve readings
// of a 12-hour clock, 0 where 12 sits, are added and multiplied by wrapping at 12.
// Road one hunts by brute force, trying every reading; road two argues from the
// greatest common divisor, written out below.  The two roads share no arithmetic.
const N: i64 = 12;
type Mat = [[i64; 2]; 2];
fn hcf(mut a: i64, mut b: i64) -> i64 {           // greatest common divisor
    while b != 0 { (a, b) = (b, a % b); }
    a
}
fn row(values: &[i64]) -> String {
    values.iter().map(|v| v.to_string()).collect::<Vec<String>>().join(" ")
}
fn times(a: Mat, b: Mat) -> Mat {                 // product of two 2 by 2 matrices
    let mut c = [[0i64; 2]; 2];
    for i in 0..2 { for j in 0..2 { c[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j]; } }
    c
}
fn show(m: Mat) -> String {
    format!("[[{}, {}], [{}, {}]]", m[0][0], m[0][1], m[1][0], m[1][1])
}
fn value(poly: &[i64], x: i64) -> i64 {           // a polynomial at one integer
    let mut total = 0;
    for (k, c) in poly.iter().enumerate() { total += c * x.pow(k as u32); }
    total
}
fn main() {
    let readings: Vec<i64> = (0..N).collect();
    let reach: Vec<i64> = readings.iter().map(|&a| {                        // road one
        let mut seen: Vec<i64> = Vec::new();
        for &x in &readings { if !seen.contains(&(a * x % N)) { seen.push(a * x % N); } }
        seen.len() as i64
    }).collect();
    let reach_hcf: Vec<i64> = readings.iter().map(|&a| N / hcf(a, N)).collect();  // road two
    let undo: Vec<Vec<i64>> = readings.iter().map(|&a|                      // road one
        readings.iter().cloned().filter(|&x| a * x % N == 1).collect()).collect();
    let units: Vec<i64> = readings.iter().cloned().filter(|&a| !undo[a as usize].is_empty()).collect();
    let units_hcf: Vec<i64> = (1..N).filter(|&a| hcf(a, N) == 1).collect();      // road two
    let zd: Vec<i64> = (1..N).filter(|&a| (1..N).any(|b| a * b % N == 0)).collect();
    let partner: Vec<i64> = zd.iter().map(|&a| N / hcf(a, N)).collect();
    let (mut triples, mut spread) = (0i64, 0i64);
    for &a in &readings { for &b in &readings { for &c in &readings {
        triples += 1;
        if a * ((b + c) % N) % N == (a * b + a * c) % N { spread += 1; }
    } } }
    let (p, q) = ([1i64, 1], [-1i64, 1]);         // (x + 1) and (x - 1), constant first
    let mut prod = [0i64; 3];
    for (i, pi) in p.iter().enumerate() { for (j, qj) in q.iter().enumerate() { prod[i + j] += pi * qj; } }
    let agree = (-3..=3).all(|x| value(&prod, x) == value(&p, x) * value(&q, x));
    let no2: Vec<i64> = (-20..=20).filter(|&k| 2 * k == 1).collect();
    let int_units: Vec<i64> = (-20..=20).filter(|&k| (-20..=20).any(|m| k * m == 1)).collect();
    let (am, bm, em, fm): (Mat, Mat, Mat, Mat) = ([[1, 1], [0, 1]], [[1, 0], [1, 1]], [[1, 0], [0, 0]], [[0, 0], [0, 1]]);
    let undos: Vec<i64> = units.iter().map(|&a| undo[a as usize][0]).collect();
    let twos: Vec<i64> = readings.iter().map(|&x| 2 * x % N).collect();
    let solve: Vec<i64> = readings.iter().cloned().filter(|&x| 2 * x % N == 2).collect();
    println!("clock size {}: 3 x 4 = {}, and 5 x 5 = {}", N, 3 * 4 % N, 5 * 5 % N);
    println!("readings reached by multiplying by 0 to 11: {}", row(&reach));
    println!("units by hunting an undo:  {}", row(&units));
    println!("units by the gcd test:     {}", row(&units_hcf));
    println!("the undo of each of them:  {}", row(&undos));
    println!("nonzero zero divisors: {}", row(&zd));
    println!("a partner taking each to zero: {}", row(&partner));
    println!("2 times 0 to 11: {}, and 1 is not there", row(&twos));
    println!("2x = 2 on the clock: x = {}", row(&solve));
    println!("distributivity: of {} triples of readings, {} agree", triples, spread);
    println!("integers: 2k = 1 has {} answers from -20 to 20; the only units are {}", no2.len(), row(&int_units));
    println!("polynomials: (x + 1)(x - 1) has coefficients {} for 1, x, x^2; agrees at \
              every x from -3 to 3: {}", row(&prod), if agree { "yes" } else { "no" });
    println!("A = {} and B = {}", show(am), show(bm));
    println!("AB = {} but BA = {}", show(times(am, bm)), show(times(bm, am)));
    println!("matrix zero divisors: {} times {} = {}", show(em), show(fm), show(times(em, fm)));
    assert!(units == units_hcf && units == vec![1, 5, 7, 11] && reach == reach_hcf);
    assert!(zd == vec![2, 3, 4, 6, 8, 9, 10] && !zd.iter().any(|a| units.contains(a))
        && zd.iter().zip(partner.iter()).all(|(a, b)| a * b % N == 0));
    assert!(spread == triples && triples == 1728 && undo[2].is_empty() && no2.is_empty()
        && int_units == vec![-1, 1]);
    assert!(prod == [-1, 0, 1] && agree && times(am, bm) == [[2, 1], [1, 1]]
        && times(bm, am) == [[1, 1], [1, 2]] && times(em, fm) == [[0, 0], [0, 0]]);
    println!("ALL CHECKS PASS");
}
