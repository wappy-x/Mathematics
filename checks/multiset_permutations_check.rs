// Arranging with repeats -- the same check as the Python, in Rust.  No crates.
// Two lines that repeat: a six-slot drum bar of 3 kicks, 2 snares and 1 hat,
// and the eleven letters of MISSISSIPPI.  Each count is reached three ways that
// share no arithmetic: the factorial formula, a product of binomial
// coefficients built by addition alone, and a listing of the arrangements.
const DRUM: &[u64] = &[3, 2, 1];
const WORD: &[u64] = &[1, 4, 4, 2];
fn factorial(m: u64) -> u64 {                 // road one's only ingredient
    let mut out = 1;
    for i in 2..=m { out *= i }
    out
}
fn by_formula(counts: &[u64]) -> u64 {        // road one: n! divided by each block
    let mut out = factorial(counts.iter().sum());
    for &a in counts { out /= factorial(a) }
    out
}
fn choose(n: u64, k: usize) -> u64 {          // Pascal's triangle: addition only
    let mut row = vec![0u64; n as usize + 1];
    row[0] = 1;
    for r in 1..=n as usize {
        for i in (1..=r).rev() { row[i] += row[i - 1] }
    }
    row[k]
}
fn by_positions(counts: &[u64]) -> (u64, Vec<u64>, Vec<String>) {   // road two: one kind's places at a time
    let (mut left, mut steps, mut labels, mut out) = (counts.iter().sum::<u64>(), Vec::new(), Vec::new(), 1);
    for &a in counts {
        steps.push(choose(left, a as usize)); labels.push(format!("C({},{})", left, a));
        out *= steps[steps.len() - 1]; left -= a;
    }
    (out, steps, labels)
}
fn by_listing(counts: &mut Vec<u64>) -> u64 { // road three: build every arrangement
    if counts.iter().all(|&a| a == 0) { return 1 }
    let mut out = 0;
    for i in 0..counts.len() {
        if counts[i] > 0 { counts[i] -= 1; out += by_listing(counts); counts[i] += 1; }
    }
    out
}
fn main() {
    let ((drum_p, drum_s, drum_c), (word_p, word_s, word_c)) = (by_positions(DRUM), by_positions(WORD));
    let (drum_n, word_n) = (DRUM.iter().sum::<u64>(), WORD.iter().sum::<u64>());
    let (inside_drum, inside_word) = (factorial(drum_n) / by_formula(DRUM), factorial(word_n) / by_formula(WORD));
    let (no_division, by_sum) = (factorial(11), factorial(4) + factorial(4) + factorial(2));
    let one_block = no_division / (factorial(4) * factorial(4));
    let (drum_l, word_l) = (by_listing(&mut DRUM.to_vec()), by_listing(&mut WORD.to_vec()));
    let drum_f = DRUM.iter().map(|a| format!("{}!", a)).collect::<Vec<_>>().join(" x ");
    let word_f = WORD.iter().filter(|&&a| a > 1).map(|a| format!("{}!", a)).collect::<Vec<_>>().join(" x ");
    let join = |v: &[u64]| v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" x ");
    println!("factorials in play: 2! = {}, 3! = {}, 4! = {}, 6! = {}, 11! = {}",
             factorial(2), factorial(3), factorial(4), factorial(6), no_division);
    println!("drum bar, 6 slots: 3 kicks, 2 snares, 1 hat");
    println!("  numbered orderings {}, each bar counted {} = {} times, {} / {} = {}",
             factorial(drum_n), drum_f, inside_drum, factorial(drum_n), inside_drum, by_formula(DRUM));
    println!("  road 2, one kind at a time: {} = {} = {}",
             drum_c.join(" x "), join(&drum_s), drum_p);
    println!("  road 3, distinct bars built one by one: {}", drum_l);
    println!("MISSISSIPPI, 11 letters: M 1, I 4, S 4, P 2");
    println!("  numbered orderings {}, each word counted {} = {} times, {} / {} = {}",
             factorial(word_n), word_f, inside_word, factorial(word_n), inside_word, by_formula(WORD));
    println!("  road 2, one kind at a time: {} = {} = {}",
             word_c.join(" x "), join(&word_s), word_p);
    println!("  road 3, distinct words built one by one: {}", word_l);
    println!("grid paths, 5 steps right and 3 steps up: 8! / (5! 3!) = {}, and C(8,3) = {}",
             by_formula(&[5, 3]), choose(8, 3));
    println!("mistake 1, no division at all: {}", no_division);
    println!("mistake 2, the two P's left undivided: {}", one_block);
    println!("mistake 3, dividing by 4! + 4! + 2! = {}: {}", by_sum, no_division / by_sum);
    println!("mistake 4, counting only where the four S's go, C(11,4): {}", choose(11, 4));
    println!("try changing: 3 kicks and 3 snares gives {}; a second M in MISSISSIPPI gives {}",
             by_formula(&[3, 3]), by_formula(&[2, 4, 4, 2]));
    assert!(by_formula(DRUM) == drum_p && drum_p == drum_l && drum_l == 60);
    assert!(by_formula(WORD) == word_p && word_p == word_l && word_l == 34650);
    assert!(one_block == 2 * by_formula(WORD) && one_block == 69300);
    assert!(by_formula(&[5, 3]) == choose(8, 3) && choose(8, 3) == 56);
    println!("ALL CHECKS PASS");
}
