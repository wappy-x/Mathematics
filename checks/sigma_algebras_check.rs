// Sigma-algebras -- the same check as the Python, in Rust.  No crates.
// A weather station logs rain (R) or dry (D) on each of three days: 8 outcomes.
// A set of outcomes is an 8-bit mask, bit i for outcome w[i]; a family of sets
// is a membership table over every mask.  Three roads to each station's family:
// (1) test all 256 sets against the report, (2) close its yes/no questions under
// the rules, (3) count the report's blocks and raise 2 to that power.  Then every
// family on 1 to 4 points is tested against the rules, beside the partitions.
type Report = fn(&str) -> String;

fn broken_rule(fam: &[bool]) -> &'static str {         // the three rules, in order
    let full = fam.len() - 1;
    let sets: Vec<usize> = (0..fam.len()).filter(|&s| fam[s]).collect();
    if !fam[full] { return "rule 1, whole space missing"; }
    if sets.iter().any(|&a| !fam[full ^ a]) { return "rule 2, a complement missing"; }
    if sets.iter().any(|&a| sets.iter().any(|&b| !fam[a | b])) { return "rule 3, a union missing"; }
    "none"
}

fn size(fam: &[bool]) -> usize { fam.iter().filter(|&&x| x).count() }

fn settled(w: &[String], report: Report) -> Vec<bool> {  // road 1: the sets the report decides
    let n = w.len();
    let mut same = Vec::new();
    for i in 0..n { for j in 0..n { if report(&w[i]) == report(&w[j]) { same.push((i, j)) } } }
    (0..1usize << n).map(|s| same.iter().all(|&(i, j)| (s >> i & 1) == (s >> j & 1))).collect()
}

fn close(questions: &[usize], full: usize) -> Vec<bool> { // road 2: apply rules 1-3 until nothing is new
    let mut fam = vec![false; full + 1];
    fam[full] = true;
    for &q in questions { fam[q] = true; }
    loop {
        let sets: Vec<usize> = (0..=full).filter(|&s| fam[s]).collect();
        let mut grew = false;
        for &a in &sets {
            let mut add = vec![full ^ a];
            for &b in &sets { add.push(a | b); }
            for c in add { if !fam[c] { fam[c] = true; grew = true; } }
        }
        if !grew { return fam; }
    }
}

fn blocks(w: &[String], report: Report) -> usize {      // road 3: outcomes grouped by report
    let mut seen: Vec<String> = w.iter().map(|x| report(x)).collect();
    seen.sort();
    seen.dedup();
    seen.len()
}

fn show(w: &[String], mask: usize) -> String {
    let names: Vec<&str> = (0..w.len()).filter(|&i| mask >> i & 1 == 1).map(|i| w[i].as_str()).collect();
    format!("{{{}}}", names.join(" "))
}

fn nothing(_: &str) -> String { String::new() }
fn day1(w: &str) -> String { w[..1].to_string() }
fn days12(w: &str) -> String { w[..2].to_string() }
fn whole(w: &str) -> String { w.to_string() }
fn count(w: &str) -> String { w.matches('R').count().to_string() }
fn week(w: &str) -> String { w.contains('R').to_string() }
fn count12(w: &str) -> String { w[..2].matches('R').count().to_string() }
fn two_plus(w: &str) -> String { (w.matches('R').count() >= 2).to_string() }
fn day3(w: &str) -> String { w[2..3].to_string() }

fn count_sigma(n: usize) -> usize {                     // test every family of subsets of n points
    let m = 1usize << n;
    (0..1usize << m).filter(|code| {
        let fam: Vec<bool> = (0..m).map(|s| code >> s & 1 == 1).collect();
        broken_rule(&fam) == "none"
    }).count()
}

fn main() {
    let mut w: Vec<String> = Vec::new();
    for a in ['D', 'R'] { for b in ['D', 'R'] { for c in ['D', 'R'] { w.push(format!("{}{}{}", a, b, c)) } } }
    w.sort_by_key(|x| x.matches('R').count());           // stable, as Python's sorted
    let n = w.len();
    let full = (1usize << n) - 1;
    let where_ = |t: &dyn Fn(&str) -> bool| -> usize { (0..n).filter(|&i| t(&w[i])).map(|i| 1usize << i).sum() };
    let rain: Vec<usize> = (0..3).map(|d| where_(&|x: &str| x.as_bytes()[d] == b'R')).collect();
    let at_least: Vec<usize> = (1..4).map(|k| where_(&|x: &str| x.matches('R').count() >= k)).collect();
    let stations: Vec<(&str, Report, Vec<usize>)> = vec![
        ("no report", nothing, vec![]),
        ("day 1 so far", day1, rain[..1].to_vec()),
        ("days 1-2 so far", days12, rain[..2].to_vec()),
        ("full log", whole, rain.clone()),
        ("rain-day count", count, at_least.clone()),
        ("any rain this week", week, at_least[..1].to_vec())];
    println!("outcomes, by rain days: {}", w.join(" "));
    println!("{:<20}{:>7}{:>8}{:>8}{:>10}  rule broken", "station", "blocks", "road 1", "road 2", "2^blocks");
    let mut fams: Vec<(&str, Vec<bool>)> = Vec::new();
    for (name, report, questions) in &stations {
        let (f1, f2, k) = (settled(&w, *report), close(questions, full), blocks(&w, *report));
        println!("{:<20}{:>7}{:>8}{:>8}{:>10}  {}", name, k, size(&f1), size(&f2), 1usize << k, broken_rule(&f1));
        assert!(f1 == f2, "{}", name);                   // decided-by-report equals closed-up questions
        assert!(size(&f1) == 1usize << k, "{}", name);   // the block count predicts the size
        assert!(broken_rule(&f1) == "none", "{}", name); // and the three rules hold
        fams.push((name, f1));
    }
    let fam = |name: &str| -> Vec<bool> { fams.iter().find(|p| p.0 == name).unwrap().1.clone() };
    println!("the weekly station settles:");
    let wk = fam("any rain this week");
    let mut members: Vec<usize> = (0..=full).filter(|&s| wk[s]).collect();
    members.sort_by_key(|s| s.count_ones());
    for s in members { println!("    {}", show(&w, s)); }
    let (mut wi, mut wj) = (0, 0);
    'search: for i in 0..n { for j in i + 1..n {
        if week(&w[i]) == week(&w[j]) && (rain[1] >> i & 1) != (rain[1] >> j & 1) { wi = i; wj = j; break 'search; }
    } }
    println!("'rain on day 2' is not settled weekly: {} and {} report alike, differ on day 2", w[wi], w[wj]);
    assert!(!wk[rain[1]]);
    for chain in [["no report", "day 1 so far", "days 1-2 so far", "full log"],
                  ["no report", "any rain this week", "rain-day count", "full log"]] {
        let nested = (0..3).all(|t| { let (a, b) = (fam(chain[t]), fam(chain[t + 1])); (0..=full).all(|s| !a[s] || b[s]) });
        let sizes: Vec<String> = chain.iter().map(|c| size(&fam(c)).to_string()).collect();
        println!("nested: {} -> {}", sizes.join(" inside "), if nested { "yes" } else { "no" });
        assert!(nested);                                     // more information settles more
    }

    let bad_list = [0, full, rain[0], rain[1]];
    let mut bad = vec![false; full + 1];
    for &s in &bad_list { bad[s] = true; }
    let miss_c = bad_list.iter().filter(|&&a| !bad[full ^ a]).count();
    let mut unions: Vec<usize> = Vec::new();
    for &a in &bad_list { for &b in &bad_list { if !bad[a | b] && !unions.contains(&(a | b)) { unions.push(a | b) } } }
    let closed = close(&bad_list, full);
    println!("non-example (empty, whole, rain day 1, rain day 2): {}", broken_rule(&bad));
    println!("  {} complements and {} union missing; closed up it has {} sets, the days 1-2 family: {}",
             miss_c, unions.len(), size(&closed), if closed == fam("days 1-2 so far") { "yes" } else { "no" });
    assert!(miss_c == 2 && unions.len() == 1 && closed == fam("days 1-2 so far"));
    println!("mistake, crediting the weekly station with every set: {} claimed, {} settled", full + 1, size(&wk));
    println!("mistake, counting blocks as sets for the rain-day count: {} claimed, {} settled",
             blocks(&w, count), size(&fam("rain-day count")));

    let mut binom = vec![vec![0u64; 9]; 9];                  // Pascal's triangle, written out
    for a in 0..9 { binom[a][0] = 1; for b in 1..=a { binom[a][b] = binom[a - 1][b - 1] + if b < a { binom[a - 1][b] } else { 0 }; } }
    let mut bell: Vec<u64> = vec![1];                        // partitions of n points, by recurrence
    for m in 0..8 { let next = (0..=m).map(|k| binom[m][k] * bell[k]).sum(); bell.push(next); }
    let brute: Vec<u64> = (1..5).map(|m| count_sigma(m) as u64).collect();
    let tested: Vec<u64> = (1..5).map(|m| 1u64 << (1u64 << m)).collect();
    println!("families tested on 1, 2, 3, 4 points: {:?}", tested);
    println!("sigma-algebras found by testing:      {:?}", brute);
    println!("partitions of 1 to 8 points:          {:?}", &bell[1..]);
    println!("sigma-algebras on the station's 8 outcomes: {}", bell[8]);
    assert!(brute[..] == bell[1..5]);                        // rule-testing and partition-counting agree

    let days = [10u32, 100, 1000];
    let ins: Vec<u32> = days.iter().map(|&m| (1..=m).filter(|d| d % 2 == 0).count() as u32).collect();
    let outs: Vec<String> = days.iter().zip(&ins).map(|(m, e)| (m - e).to_string()).collect();
    let ins_s: Vec<String> = ins.iter().map(|e| e.to_string()).collect();
    println!("first rain on an even day, days 1-10/100/1000: in {} out {}", ins_s.join("/"), outs.join("/"));
    for (name, report) in [("try: rain count on days 1-2", count12 as Report),
                           ("try: rain on at least two days", two_plus), ("try: day 3 only reported", day3)] {
        println!("{:<32} blocks {}, sets {}", name, blocks(&w, report), size(&settled(&w, report)));
    }
    for (name, report) in [("full log", whole as Report), ("rain-day count", count), ("any rain this week", week)] {
        let mut xs = vec![20];
        for i in 0..n { if i == n - 1 || report(&w[i]) != report(&w[i + 1]) { xs.push(20 + 40 * (i + 1)); } }
        let xs: Vec<String> = xs.iter().map(|x| x.to_string()).collect();
        println!("figure, {}: block edges at x = {}", name, xs.join(" "));
    }
    println!("ALL CHECKS PASS");
}
