// Fields -- the same check as the Python, in Rust.  No crates.  On a cycle of n days
// the labels are 0 to n-1, and a*x is read on the cycle.  Reciprocals come by two
// independent roads, trying every label and Euclid's algorithm, and are compared.
const WEEK: i64 = 7;
const SIX: i64 = 6;
const CLOCK: i64 = 12;

fn answers(a: i64, b: i64, n: i64) -> Vec<i64> {      // road one: try every label
    (0..n).filter(|x| a * x % n == b).collect()
}

fn reciprocal(a: i64, n: i64) -> Option<i64> {        // road two: Euclid's algorithm
    let (mut r0, mut r1, mut t0, mut t1) = (n, a % n, 0, 1);   // r0 = t0 jumps of a, plus n's
    while r1 != 0 {
        let q = r0 / r1;
        (r0, r1) = (r1, r0 - q * r1);
        (t0, t1) = (t1, t0 - q * t1);
    }
    if r0 == 1 { Some(t0.rem_euclid(n)) } else { None }        // nothing unless the gcd is 1
}

fn is_prime(n: i64) -> bool {                         // trial division, independent
    n >= 2 && (2..n).all(|d| n % d != 0)
}

fn grid(name: &str, values: &[i64]) {
    let mut line = format!("{:<27}", name);
    for v in values { line.push_str(&format!("{:>4}", v)); }
    println!("{}", line);
}

fn main() {
    let sizes: Vec<i64> = (2..=CLOCK).collect();
    let euclid: Vec<i64> = (1..WEEK).map(|a| reciprocal(a, WEEK).unwrap()).collect();
    let searched: Vec<i64> = (1..WEEK).map(|a| answers(a, 1, WEEK)[0]).collect();
    let units: Vec<Vec<i64>> = sizes.iter()
        .map(|&n| (1..n).filter(|&a| !answers(a, 1, n).is_empty()).collect()).collect();
    let by_search: Vec<i64> = units.iter().map(|u| u.len() as i64).collect();
    let by_euclid: Vec<i64> = sizes.iter()
        .map(|&n| (1..n).filter(|&a| reciprocal(a, n).is_some()).count() as i64).collect();
    let fields: Vec<i64> = sizes.iter().cloned().filter(|&n| by_search[(n - 2) as usize] == n - 1).collect();
    let primes: Vec<i64> = sizes.iter().cloned().filter(|&n| is_prime(n)).collect();
    let pairs: Vec<(i64, i64)> = (1..WEEK).flat_map(|a| (0..WEEK).map(move |b| (a, b))).collect();
    let most = pairs.iter().map(|&(a, b)| answers(a, b, WEEK).len()).max().unwrap();
    let (x, wrong) = (4 * reciprocal(3, WEEK).unwrap() % WEEK, 4 * 4 % WEEK);
    println!("week labels 0 to {}; reciprocals of 1 to {}: {:?}", WEEK - 1, WEEK - 1, euclid);
    println!("reciprocal checks mod {}: 2*4 = {}, 3*5 = {}, 6*6 = {}",
             WEEK, 2 * 4 % WEEK, 3 * 5 % WEEK, 6 * 6 % WEEK);
    println!("3x = 4 mod {}: Euclid road x = {}, search road {:?}", WEEK, x, answers(3, 4, WEEK));
    println!("by hand: 3*5 = {}, {} - {} = {}; 5*4 = {}, {} - {} = {}; 3*6 = {}, {} - {} = {}",
             3 * 5, 3 * 5, 2 * WEEK, 3 * 5 - 2 * WEEK, 5 * 4, 5 * 4, 2 * WEEK, 5 * 4 - 2 * WEEK,
             3 * 6, 3 * 6, 2 * WEEK, 3 * 6 - 2 * WEEK);
    println!("all {} equations a*x = b mod {}, a nonzero: at most {} answer", pairs.len(), WEEK, most);
    println!("zero coefficient mod {}: 0x = 1 has {} answers, 0x = 0 has {}",
             WEEK, answers(0, 1, WEEK).len(), answers(0, 0, WEEK).len());
    println!("3+4 = {} mod {} but 3*4 = {}; that road gives x = {}, and 3*{} = {}, not 4",
             (3 + 4) % WEEK, WEEK, 3 * 4 % WEEK, wrong, wrong, 3 * wrong % WEEK);
    println!("six-day cycle: reciprocals only for {:?}; 2*3 = {}; 2x = 1 answers {:?}; \
              2x = 2 answers {:?}",
             units[(SIX - 2) as usize], 2 * 3 % SIX, answers(2, 1, SIX), answers(2, 2, SIX));
    println!("twelve-hour clock: reciprocals only for {:?}; 3*4 = {}; 3x = 0 answers {:?}",
             units[(CLOCK - 2) as usize], 3 * 4 % CLOCK, answers(3, 0, CLOCK));
    println!("integers: 2k = 1 has {} answers for k from -20 to 20; rationals: \
              (3/4)*(4/3) = {}/{} = 1",
             (-20..=20).filter(|k| 2 * k == 1).count(), 3 * 4, 4 * 3);
    grid("cycle size n", &sizes);
    grid("nonzero labels, n - 1", &sizes.iter().map(|n| n - 1).collect::<Vec<i64>>());
    grid("of those, with a reciprocal", &by_search);
    grid("the same count, by Euclid", &by_euclid);
    println!("cycle sizes that are fields: {:?}", fields);
    println!("primes up to {}, by trial division: {:?}", CLOCK, primes);
    assert!(euclid == searched && euclid == vec![1, 4, 5, 2, 3, 6]);
    assert!(pairs.iter().all(|&(a, b)| answers(a, b, WEEK) == vec![b * reciprocal(a, WEEK).unwrap() % WEEK]));
    assert!(fields == primes && fields == vec![2, 3, 5, 7, 11] && by_search == by_euclid);
    assert!(answers(2, 1, SIX).is_empty() && answers(2, 2, SIX) == vec![1, 4]
        && answers(3, 0, CLOCK) == vec![0, 4, 8]);
    println!("ALL CHECKS PASS");
}
