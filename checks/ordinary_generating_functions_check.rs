// Generating functions -- the same check as the Python, in Rust.  No crates.  A
// series is a vector of coefficients: the entry at index n is the count hanging
// on x^n.  Two dice are x + x^2 + ... + x^6 twice over; their product is built
// by adding exponents, then checked against a listing of all 36 ordered rolls.
const N: usize = 8;                              // how far the ones series is written

fn poly_mul(a: &[i64], b: &[i64]) -> Vec<i64> {  // road one: every pair, exponents added
    let mut out = vec![0i64; a.len() + b.len() - 1];
    for (i, ai) in a.iter().enumerate() {
        for (j, bj) in b.iter().enumerate() {
            out[i + j] += ai * bj;
        }
    }
    out
}

fn tally_rolls(faces: &[i64]) -> Vec<i64> {      // road two: list the rolls, count totals
    let lo = 2 * faces[0];
    let hi = 2 * faces[faces.len() - 1];
    let mut counts = vec![0i64; (hi - lo + 1) as usize];
    for &u in faces {
        for &v in faces {
            counts[(u + v - lo) as usize] += 1;
        }
    }
    counts
}

fn splits(n: i64, faces: &[i64]) -> Vec<(i64, i64)> {   // the ways to split n across two dice
    faces.iter().filter(|&&k| faces.contains(&(n - k))).map(|&k| (k, n - k)).collect()
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let faces: Vec<i64> = (1..7).collect();            // the six faces of one die
    let mut die = vec![0i64];                          // one way to show each of 1 to 6
    die.extend(vec![1i64; 6]);
    let two = poly_mul(&die, &die);                    // the product series, index = the total
    let totals: Vec<i64> = two[2..].to_vec();          // nothing lands below x^2
    let listed = tally_rolls(&faces);
    let ones = vec![1i64; N + 1];
    let ones_squared: Vec<i64> = poly_mul(&ones, &ones)[..N + 1].to_vec();
    let by_formula: Vec<i64> = (0..=N as i64).map(|n| n + 1).collect();
    let inverse = poly_mul(&[1, -1], &ones);           // (1 - x) times the ones, degree by degree
    let termwise: Vec<i64> = die[1..].iter().map(|&u| u * u).collect();
    let zero_to_five = poly_mul(&vec![1i64; 6], &vec![1i64; 6]);
    let mut added: Vec<i64> = die.iter().map(|&c| 2 * c).collect();
    added.extend(vec![0i64; 6]);
    let cut = poly_mul(&[1, -1], &vec![1i64; 6]);
    let mut want = vec![1i64];
    want.extend(vec![0i64; N]);
    want.push(-1);
    let sum_totals: i64 = totals.iter().sum();
    println!("one die as a series: the counts on x^1 to x^6 = {:?}", &die[1..]);
    println!("two dice, series multiplied: totals 2 to 12 -> {:?}", totals);
    println!("the same counts, by listing all 36 ordered rolls: {:?}", listed);
    println!("two roads agree: {}", yn(totals == listed));
    println!("coefficient of x^7 = {}, from the splits {:?}", two[7], splits(7, &faces));
    println!("the eleven counts sum to {}; 6 faces x 6 faces = {}", sum_totals, 6 * 6);
    println!("the ones squared, n = 0 to {}: {:?}", N, ones_squared);
    println!("the same list, by the count n + 1: {:?}", by_formula);
    println!("(1 - x) times the ones through x^{}: {:?}", N, inverse);
    println!("1 stands alone, the only leftover -1 on x^{}: {}", N + 1, yn(inverse == want));
    println!("mistake 1, the two face lists multiplied term by term: {:?}, {} counts summing to {}, not 36",
             termwise, termwise.len(), termwise.iter().sum::<i64>());
    println!("mistake 2, faces numbered 0 to 5: coefficient of x^7 = {}, not 6", zero_to_five[7]);
    println!("mistake 3, the two series added, not multiplied: coefficient of x^7 = {}, all counts summing to {}",
             added[7], added.iter().sum::<i64>());
    println!("mistake 4, the ones cut off at x^5: (1 - x) times it = {:?}, a leftover -1 on x^6", cut);
    assert!(totals == listed);                                 // series algebra vs 36 listed rolls
    assert!(totals == (2..13).map(|t| splits(t, &faces).len() as i64).collect::<Vec<i64>>()
            && sum_totals == 36);                              // third road, and the grand total
    assert!(ones_squared == by_formula);                       // multiplied out vs the closed count
    assert!(inverse == want);                                  // the inverse, degree by degree
    println!("ALL CHECKS PASS");
}
