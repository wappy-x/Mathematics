// Counting by multiplying series -- the same check as the Python, in Rust.  No
// crates.  Making 50 cents from pennies, nickels, dimes and quarters is the
// coefficient of x^50 in 1/((1-x)(1-x^5)(1-x^10)(1-x^25)).  Road one multiplies
// the four series and collects like powers; road two counts coin piles instead.
const N: usize = 50;
const COINS: [usize; 4] = [1, 5, 10, 25];
fn mul(a: &[i64], b: &[i64], top: usize) -> Vec<i64> {   // a_i * b_j onto degree i + j
    let mut out = vec![0i64; top + 1];
    for (i, &ai) in a.iter().enumerate() {
        for (j, &bj) in b.iter().enumerate() {
            if ai != 0 && bj != 0 && i + j <= top { out[i + j] += ai * bj }
        }
    }
    out
}
fn factor(v: usize, top: usize, least: usize) -> Vec<i64> {   // one kind of coin
    let mut f = vec![0i64; top + 1];
    let mut m = least;
    while m * v <= top { f[m * v] = 1; m += 1 }
    f
}
fn product(coins: &[usize], top: usize, least: usize) -> Vec<i64> {   // road one
    let mut out = vec![0i64; top + 1];
    out[0] = 1;
    for &v in coins { out = mul(&out, &factor(v, top, least), top) }
    out
}
fn piles(target: i64, coins: &[usize]) -> i64 {   // road two: no series named
    if coins.is_empty() { return if target == 0 { 1 } else { 0 } }
    let v = coins[0] as i64;
    (0..=target / v).map(|m| piles(target - m * v, &coins[1..])).sum()
}
fn choose(m: usize, r: usize) -> i64 {            // Pascal's rule, written out here
    let mut row = vec![1i64];
    for _ in 0..m {
        let mut next = vec![1i64];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]) }
        next.push(1);
        row = next;
    }
    row[r]
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn join(v: &[i64], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(sep) }

fn main() {
    let ways = product(&COINS, N, 0);
    let row: Vec<i64> = (0..=N).step_by(5).map(|n| ways[n]).collect();
    let by_piles: Vec<i64> = (0..=N).step_by(5).map(|n| piles(n as i64, &COINS)).collect();
    let growing: Vec<i64> = (1..=COINS.len()).map(|i| product(&COINS[..i], N, 0)[N]).collect();
    let quartered: Vec<i64> = (0..3).map(|d| piles(N as i64 - 25 * d, &COINS[..3])).collect();
    let die = factor(1, 6, 1);                    // one die: x^1 + ... + x^6
    let dice = mul(&die, &die, 12);
    let pairs = (1..7).filter(|d| (1..7).contains(&(7 - d))).count() as i64;
    let threefold = product(&[1, 1, 1], 5, 0);
    let blind = product(&[1, 1, 1, 1], N, 0)[N];
    let spread = (N / 5 + 1) * (N / 10 + 1) * (N / 25 + 1);   // nickels x dimes x quarters
    let added: i64 = COINS.iter().map(|&v| factor(v, N, 0)[N]).sum();
    println!("making {} cents from pennies (1), nickels (5), dimes (10), quarters (25)", N);
    println!("road one, the coefficient of x^{} in the product of four series: {}", N, ways[N]);
    println!("road two, counting the coin piles, no series named: {}", piles(N as i64, &COINS));
    println!("one kind added at a time, the count at {} cents: {}", N, join(&growing, ", "));
    println!("ways to make 0, 5, 10 ... {} cents: {:?}", N, row);
    println!("the same eleven counts by counting piles: {}", yn(row == by_piles));
    println!("by hand, split on the quarters: {} = {}", join(&quartered, " + "), quartered.iter().sum::<i64>());
    println!("two dice, (x + x^2 + ... + x^6) squared: coefficient of x^7 = {}", dice[7]);
    println!("the same pairs listed by hand: {}; every coefficient added: {}", pairs, dice.iter().sum::<i64>());
    println!("three unlimited kinds, total 5: series {}, stars and bars C(7, 2) = {}", threefold[5], choose(7, 2));
    println!("mistake 1, the {} x {} x {} pile counts multiplied as if free: {}, not {}",
             N / 5 + 1, N / 10 + 1, N / 25 + 1, spread, ways[N]);
    println!("mistake 2, the four series added instead of multiplied: {}", added);
    println!("mistake 3, every factor started at its own coin: {}", product(&COINS, N, 1)[N]);
    println!("mistake 4, coin values ignored, stars and bars alone: C(53, 3) = {}", blind);
    assert!(ways[N] == piles(N as i64, &COINS) && row == by_piles);
    assert!(ways[N] == 49 && growing == vec![1, 11, 36, 49] && quartered.iter().sum::<i64>() == 49);
    assert!(threefold[5] == choose(7, 2) && blind == choose(N + 3, 3));
    assert!(dice[7] == pairs && dice.iter().sum::<i64>() == 36);
    println!("ALL CHECKS PASS");
}
