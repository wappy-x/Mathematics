// Ordered picks -- the same check as the Python, in Rust.  No crates.  Eight
// runners, three medals in order: gold, silver, bronze.  The count is reached by
// three roads that share no arithmetic -- counting down, dividing factorials,
// and writing every podium out -- and a squad of 20 repeats the test bigger.
const RUNNERS: u64 = 8;
const MEDALS: u64 = 3;
const SQUAD: u64 = 20;
const TAKERS: u64 = 5;
const NAMES: &str = "ABCDEFGH";
fn factorial(m: u64) -> u64 {              // written out, since no crate is used
    let mut out = 1;
    for i in 2..=m { out *= i }
    out
}
fn falling(n: u64, k: u64) -> u64 {        // road one: k factors, counting down
    let mut out = 1;
    for i in 0..k { out *= n - i }
    out
}
fn by_factorials(n: u64, k: u64) -> u64 { factorial(n) / factorial(n - k) }  // road two
fn lists(pool: &str, k: u64, repeats: bool) -> Vec<String> {   // road three: write every pick down
    if k == 0 { return vec![String::new()] }
    let mut out: Vec<String> = Vec::new();
    for (i, r) in pool.chars().enumerate() {
        let rest: String = if repeats { pool.to_string() }
            else { pool.chars().enumerate().filter(|p| p.0 != i).map(|p| p.1).collect() };
        for tail in lists(&rest, k - 1, repeats) { out.push(format!("{}{}", r, tail)) }
    }
    out
}
fn commas(v: u64) -> String {              // 1860480 -> 1,860,480
    let s = v.to_string();
    if s.len() <= 3 { s } else { format!("{},{}", commas(v / 1000), &s[s.len() - 3..]) }
}
fn sorted(word: &str) -> Vec<char> {       // the same letters, put in alphabetical order
    let mut c: Vec<char> = word.chars().collect();
    c.sort();
    c
}
fn main() {
    let tiny = lists(&NAMES[..3], 2, false);
    let podiums = lists(NAMES, MEDALS, false);
    let repeated = lists(NAMES, MEDALS, true);
    let mut unordered: Vec<String> = podiums.iter().map(|p| sorted(p).into_iter().collect()).collect();
    unordered.sort(); unordered.dedup();
    let mut once: Vec<String> = podiums.clone();
    once.sort(); once.dedup();
    let running: Vec<u64> = (1..=TAKERS).map(|i| falling(SQUAD, i)).collect();
    let shown: Vec<String> = running.iter().map(|&v| commas(v)).collect();
    let recurrence = SQUAD * falling(SQUAD - 1, TAKERS - 1);
    println!("3 runners A, B, C, two medals in order: 3 x 2 = {}", tiny.len());
    println!("the six lists: {}", tiny.join(", "));
    println!("{} runners, {} medals in order -- counting down: 8 x 7 x 6 = {}",
             RUNNERS, MEDALS, falling(RUNNERS, MEDALS));
    println!("road 2, factorials: 8! / 5! = {} / {} = {}", commas(factorial(RUNNERS)),
             factorial(RUNNERS - MEDALS), by_factorials(RUNNERS, MEDALS));
    println!("road 3, every podium written out: {}", podiums.len());
    println!("the first three podiums listed: {}", podiums[..3].join(", "));
    println!("repeats allowed, written out: 8 x 8 x 8 = {}", repeated.len());
    println!("the same podiums with the order forgotten: {}, and {} x 3! = {}",
             unordered.len(), unordered.len(), unordered.len() as u64 * factorial(MEDALS));
    println!("squad of {}, {} takers -- running product: {}", SQUAD, TAKERS, shown.join(", "));
    println!("road 2, factorials: 20! / 15! = {}", commas(by_factorials(SQUAD, TAKERS)));
    println!("road 3, one kick then a smaller pick: 20 x P(19, 4) = {}", commas(recurrence));
    println!("repeats allowed: 20^5 = {}", commas(SQUAD.pow(TAKERS as u32)));
    println!("mistake 1, dividing by 3! as well: {}, not {}", unordered.len(), falling(RUNNERS, MEDALS));
    println!("mistake 2, letting one runner take two medals: {}, not {}", repeated.len(), falling(RUNNERS, MEDALS));
    println!("mistake 3, dividing by 3! instead of 5!: 8! / 3! = {}, not {}",
             commas(factorial(RUNNERS) / factorial(MEDALS)), falling(RUNNERS, MEDALS));
    assert!(podiums.len() as u64 == falling(RUNNERS, MEDALS)
            && falling(RUNNERS, MEDALS) == by_factorials(RUNNERS, MEDALS));
    assert!(podiums.iter().all(|p| { let mut c = sorted(p); c.dedup(); c.len() as u64 == MEDALS })
            && once.len() == podiums.len());
    assert!(unordered.len() as u64 * factorial(MEDALS) == podiums.len() as u64
            && repeated.len() as u64 == RUNNERS.pow(MEDALS as u32));
    assert!(running[running.len() - 1] == by_factorials(SQUAD, TAKERS)
            && recurrence == by_factorials(SQUAD, TAKERS) && recurrence == 1860480);
    println!("ALL CHECKS PASS");
}
