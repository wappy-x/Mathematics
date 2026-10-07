// Sample spaces and events -- the same check as the Python, in Rust.  No crates.
// Two dice, first and second: the sample space is the 36 ordered pairs.
// An event is a subset.  Road 1 lists outcomes and tests each one.  Road 2
// stores each event as 36 on/off bits and combines events with bit operations.
// Road 3 rolls dice with a SplitMix64 generator written out here.
const FULL: u64 = (1u64 << 36) - 1;

fn omega() -> Vec<(i64, i64)> {                 // first die i, second die j
    let mut v = Vec::new();
    for i in 1..=6 { for j in 1..=6 { v.push((i, j)) } }
    v
}

fn bit(i: i64, j: i64) -> u32 { (6 * (i - 1) + (j - 1)) as u32 }

fn mask(test: &dyn Fn(i64, i64) -> bool) -> u64 {   // road 2: an event as 36 bits
    let mut m = 0u64;
    for (i, j) in omega() { if test(i, j) { m |= 1u64 << bit(i, j) } }
    m
}

fn ones(m: u64) -> u32 { m.count_ones() }
fn seven(i: i64, j: i64) -> bool { i + j == 7 }
fn six(i: i64, j: i64) -> bool { i == 6 || j == 6 }
fn double(i: i64, j: i64) -> bool { i == j }

fn show(outs: &[(i64, i64)]) -> String {
    outs.iter().map(|(i, j)| format!("({},{})", i, j)).collect::<Vec<_>>().join(" ")
}

fn list(test: &dyn Fn(i64, i64) -> bool) -> Vec<(i64, i64)> {  // road 1: listing
    omega().into_iter().filter(|&(i, j)| test(i, j)).collect()
}

struct SplitMix64 { state: u64 }                 // road 3: SplitMix64, seed stated
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    let om = omega();
    let (a, s, d) = (list(&seven), list(&six), list(&double));
    let (ma, ms, md) = (mask(&seven), mask(&six), mask(&double));
    println!("sample space: {} ordered pairs (first die, second die)", om.len());
    println!("A  total is 7     {:2} outcomes: {}", a.len(), show(&a));
    println!("S  a six shows    {:2} outcomes", s.len());
    println!("D  a double       {:2} outcomes", d.len());
    let partner = (1..=6).filter(|i| (1..=6).contains(&(7 - i))).count();
    println!("|A| by listing {}; by one partner per first die {}", a.len(), partner);
    let by_list: Vec<i64> = (2..=12).map(|t| om.iter().filter(|&&(i, j)| i + j == t).count() as i64).collect();
    let by_rule: Vec<i64> = (2..=12).map(|t: i64| 6 - (t - 7).abs()).collect();
    let join = |v: &Vec<i64>| v.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" ");
    println!("totals 2..12, by listing:     {}", join(&by_list));
    println!("totals 2..12, by 6 - |s - 7|: {}", join(&by_rule));
    let tot: Vec<u64> = (2..=12).map(|t| mask(&move |i, j| i + j == t)).collect();
    let (mut cover, mut overlap) = (0u64, 0u32);
    for &m in &tot { overlap += ones(cover & m); cover |= m; }
    println!("the 11 total events cover {} outcomes and overlap in {}", ones(cover), overlap);

    let a_and_s = list(&|i, j| seven(i, j) && six(i, j));
    let a_or_s = list(&|i, j| seven(i, j) || six(i, j));
    let not_a = list(&|i, j| !seven(i, j));
    let nor1 = list(&|i, j| !(seven(i, j) || six(i, j)));
    let nor2 = list(&|i, j| !seven(i, j) && !six(i, j));
    println!("A and S  listing {:2}, bits {:2}: {}", a_and_s.len(), ones(ma & ms), show(&a_and_s));
    println!("A or S   listing {:2}, bits {:2}, inclusion-exclusion {} + {} - {} = {}",
             a_or_s.len(), ones(ma | ms), a.len(), s.len(), a_and_s.len(), a.len() + s.len() - a_and_s.len());
    println!("not A    listing {:2}, bits {:2}", not_a.len(), ones(FULL ^ ma));
    println!("A and D  listing {:2}, bits {:2}", list(&|i, j| seven(i, j) && double(i, j)).len(), ones(ma & md));
    println!("not (A or S) {}; (not A) and (not S) {}; bits {} and {}",
             nor1.len(), nor2.len(), ones(FULL ^ (ma | ms)), ones((FULL ^ ma) & (FULL ^ ms)));
    let mut events: u64 = 1;
    for _ in &om { events *= 2 }                  // each outcome is in or out
    println!("events on this space: 2^36 = {}; largest bit pattern + 1 = {}", events, FULL + 1);
    let split: Vec<i64> = (2..=12).zip(tot.iter())
        .filter(|&(_, &m)| m & ms != 0 && m & (FULL ^ ms) != 0).map(|(t, _)| t).collect();
    println!("totals that 'a six shows' splits: {}", join(&split));

    let mut rng = SplitMix64 { state: 20260928 };
    let n: u64 = 100000;
    let (mut hit7, mut hit34, mut hit33, mut hit_s) = (0u64, 0u64, 0u64, 0u64);
    for _ in 0..n {
        let i = (rng.next() % 6 + 1) as i64;
        let j = (rng.next() % 6 + 1) as i64;
        if i + j == 7 { hit7 += 1 }
        if (i, j) == (3, 4) || (i, j) == (4, 3) { hit34 += 1 }
        if (i, j) == (3, 3) { hit33 += 1 }
        if i == 6 || j == 6 { hit_s += 1 }
    }
    let nf = n as f64;
    let p7 = hit7 as f64 / nf;
    let se = (p7 * (1.0 - p7) / nf).sqrt();
    println!("simulation: {} rolls, SplitMix64 seed 20260928", n);
    println!("  share with total 7   {:.6}, standard error {:.6}", p7, se);
    println!("  exact 6/36           {:.6}, {:.1} standard errors away", 6.0 / 36.0, (p7 - 6.0 / 36.0).abs() / se);
    println!("  share a six shows    {:.6}; exact 11/36 {:.6}", hit_s as f64 / nf, 11.0 / 36.0);
    println!("  share a 3 and a 4    {:.6}; share two 3s {:.6}", hit34 as f64 / nf, hit33 as f64 / nf);
    for (name, wrong) in [("11 totals, equally likely: 1/11", 1.0 / 11.0),
                          ("21 unordered pairs, equally likely: 3/21", 3.0 / 21.0)] {
        println!("mistake, {} = {:.6}, {:.1} standard errors away", name, wrong, (p7 - wrong).abs() / se);
    }
    println!("mistake, A or S by adding: {} + {} = {}, not {}", a.len(), s.len(), a.len() + s.len(), a_or_s.len());
    println!("mistake, a six shows as 6 + 6 = {}, not {}: (6,6) counted twice", 6 + 6, s.len());

    let xy: Vec<String> = a.iter().map(|&(i, j)| format!("({},{})", 45 + 30 * i, 215 - 30 * j)).collect();
    println!("figure, total-7 dots: {}", xy.join(" "));
    println!("figure, grid (60,20) to (240,200); a six shows: column x {}..{}, row y {}..{}",
             45 + 30 * 6 - 15, 45 + 30 * 6 + 15, 215 - 30 * 6 - 15, 215 - 30 * 6 + 15);

    assert!(by_list == by_rule && a.len() == partner && partner == 6);   // listing vs rule
    assert!(ones(ma | ms) as usize == a_or_s.len() && a_or_s.len() == a.len() + s.len() - a_and_s.len() && a_or_s.len() == 15);
    assert!(nor1.len() == ones((FULL ^ ma) & (FULL ^ ms)) as usize && nor1.len() == 21);  // De Morgan
    assert!(ones(cover) == 36 && overlap == 0 && events == FULL + 1);
    assert!((p7 - 6.0 / 36.0).abs() < 4.0 * se && (p7 - 1.0 / 11.0).abs() > 20.0 * se);
    println!("ALL CHECKS PASS");
}
