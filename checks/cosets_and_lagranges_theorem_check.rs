// Cosets and Lagrange's theorem -- the same check as the Python, in Rust.  No
// crates.  The group is the 12-hour clock: the hours 0 to 11, added and
// wrapped at 12.  The subgroup is H = 0, 3, 6, 9.  Its blocks are built twice,
// by roads that share no arithmetic, and the clock's units then give Euler.
const N: i64 = 12;

fn slide(members: &[i64], g: i64) -> Vec<i64> {    // road one: shift a whole set by g
    let mut out: Vec<i64> = members.iter().map(|&m| (g + m).rem_euclid(N)).collect();
    out.sort();
    out
}

fn translates(members: &[i64]) -> Vec<Vec<i64>> {  // the distinct shifted copies
    let mut out: Vec<Vec<i64>> = Vec::new();
    for g in 0..N {
        let c = slide(members, g);
        if !out.contains(&c) { out.push(c) }
    }
    out.sort();
    out
}

fn gcd(mut a: i64, mut b: i64) -> i64 {            // Euclid's algorithm, written out here
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn power(a: i64, k: i64) -> i64 {                  // a multiplied in k times, wrapped at 12
    let mut out = 1;
    for _ in 0..k { out = out * a % N }
    out
}

fn order(a: i64) -> i64 {                          // the first count of multiplies reading 1
    let mut k = 1;
    while power(a, k) != 1 { k += 1 }
    k
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let (h, k_set): (Vec<i64>, Vec<i64>) = (vec![0, 3, 6, 9], vec![0, 3, 6, 7]);
    let blocks = translates(&h);
    let mut by_remainder: Vec<Vec<i64>> =
        (0..3).map(|r| (0..N).filter(|x| x % 3 == r).collect()).collect();
    by_remainder.sort();
    let index = blocks.len() as i64;
    let mut hours: Vec<i64> = blocks.iter().flatten().copied().collect();
    hours.sort();
    let coprime: Vec<i64> = (0..N).filter(|&a| gcd(a, N) == 1).collect();       // road one
    let units: Vec<i64> = (0..N).filter(|&a| (0..N).any(|b| a * b % N == 1)).collect();
    let phi = coprime.len() as i64;
    let orders: Vec<i64> = units.iter().map(|&a| order(a)).collect();
    let powers: Vec<i64> = units.iter().map(|&a| power(a, phi)).collect();
    let copies = translates(&k_set);
    println!("clock size {}; subgroup H = {:?}, size {}; distinct blocks {}", N, h, h.len(), index);
    for b in &blocks { println!("{} + H  ->  {:?}", b[0], b) }
    println!("the same three blocks, by remainder after dividing by 3: {}", yn(blocks == by_remainder));
    println!("every hour exactly once: {} blocks x {} hours = {}", index, h.len(), index * h.len() as i64);
    println!("shift 4 names the block shift 1 names: {}, and 4 - 1 = 3 sits in H", yn(slide(&h, 4) == slide(&h, 1)));
    println!("hours sharing no factor with 12, by gcd: {:?}; phi(12) = {}", coprime, phi);
    println!("the same hours, by hunting a multiplying partner: {:?}", units);
    println!("orders of {:?} under multiplication: {:?}", units, orders);
    println!("every order divides phi(12): {}", yn(orders.iter().all(|d| phi % d == 0)));
    println!("each unit multiplied in {} times: {:?}", phi, powers);
    println!("mistake 1, block size read as the block count: 4 x 4 = {}, not {}", h.len() * h.len(), N);
    println!("mistake 2, K = {:?} is no subgroup: {} shifted copies x {} hours = {} slots for {} hours",
             k_set, copies.len(), k_set.len(), copies.len() * k_set.len(), N);
    println!("mistake 3, every hour taken as a multiplier: 2 multiplied in {} times = {}, not 1", N, power(2, N));
    assert!(blocks == by_remainder);                                  // two roads, one partition
    assert!(hours == (0..N).collect::<Vec<i64>>() && index * h.len() as i64 == N);
    assert!(coprime == units && phi == 4);                            // two roads to the units
    assert!(orders == vec![1, 2, 2, 2] && units.iter().all(|&a| power(a, phi) == 1));
    println!("ALL CHECKS PASS");
}
