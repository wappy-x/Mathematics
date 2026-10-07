// The sieve of Eratosthenes -- the same check as the Python twin, in Rust.  No crates.  100 lockers, all open.
// Shut locker 1, keep 2 and slam every second locker after it, then 3, then 5, then 7.  Trial division is road two.
const TOP: usize = 100;
fn sieve(top: usize, shut_prime: bool, shut_one: bool, last: usize) -> (Vec<usize>, Vec<(usize, Vec<usize>, usize)>) {
    let (mut open, mut passes) = (vec![true; top + 1], Vec::new());   // the plain road: slam the multiples
    (open[0], open[1]) = (false, !shut_one);      // locker 1 is shut before any pass
    for p in (2..=top).take_while(|&q| q * q <= top && q <= last) {
        if !open[p] { continue; }
        let start = if shut_prime { p } else { p * p };     // the first locker this pass slams that is still open
        let hit: Vec<usize> = (start..=top).step_by(p).filter(|&k| open[k]).collect();
        for &k in &hit { open[k] = false; }
        passes.push((p, hit, (1..=top).filter(|&n| open[n]).count()));
    }
    ((1..=top).filter(|&n| open[n]).collect(), passes)
}
fn by_trial(n: usize) -> bool { n > 1 && (2..n).all(|d| d * d > n || n % d != 0) }     // the second road
fn divisions(n: usize) -> usize { let (mut c, mut d) = (0, 2); while d * d <= n { c += 1; if n % d == 0 { break; } d += 1; } c }
fn open_count(ps: &[usize]) -> usize { (2..=TOP).filter(|&n| ps.contains(&n) || ps.iter().all(|q| n % q != 0)).count() }
fn join(v: &[usize], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    let (primes, passes) = sieve(TOP, false, true, 99);
    for (p, hit, still) in &passes {
        let shown = if hit.len() <= 6 { join(hit, " ") } else { format!("{} ... {}", join(&hit[..3], " "), hit[hit.len() - 1]) };
        println!("{}'s pass slams {:<21} -- {:>2} lockers, {} still open", p, shown, hit.len(), still);
    }
    println!("next open locker is 11, and 11 x 11 = {} is past {}, so the passes stop", 11 * 11, TOP);
    let counts: Vec<usize> = [&[2][..], &[2, 3], &[2, 3, 5], &[2, 3, 5, 7]].iter().map(|&ps| open_count(ps)).collect();   // one prime at a time
    println!("lockers still open, before any pass and after each: {} {}", TOP - 1, join(&counts, " "));
    println!("the {} open lockers: {}", primes.len(), join(&primes, ", "));
    let (trial, open5): (Vec<usize>, Vec<usize>) = ((1..=TOP).filter(|&n| by_trial(n)).collect(), sieve(TOP, false, true, 5).0);
    println!("trial division, one locker at a time, agrees: {} primes, the same list, after {} divisions", trial.len(), (1..=TOP).map(divisions).sum::<usize>());
    let extra: Vec<usize> = open5.iter().cloned().filter(|n| !primes.contains(n)).collect();   // 49, 77, 91
    println!("stopping after 5's pass: {} open, and {} are not prime", open5.len(), join(&extra, ", "));
    println!("slamming each prime along with its multiples: {} open", sieve(TOP, true, true, 99).0.len());
    println!("leaving locker 1 open: {} open", sieve(TOP, false, false, 99).0.len());
    assert!(primes == trial && primes.len() == 25 && primes[24] == 97);
    assert!(passes.iter().map(|t| t.2).collect::<Vec<usize>>() == counts && counts == vec![50, 34, 28, 25]);
    assert!(open5.len() == 28 && 7 * 7 <= TOP && TOP < 11 * 11);
    println!("ALL CHECKS PASS");
}
