// Time and space classes -- the check behind the card.  Rust std only, no crates.
// Costs are counted steps and comparisons, never a stopwatch.  The puzzle is a
// 4 by 4 sudoku (digits 1 to 4, boxes 2 by 2) with 8 blank cells, written 0.
use std::collections::{BTreeMap, HashMap, HashSet};
const PUZZLE: [u32; 16] = [0, 0, 3, 4, 0, 4, 0, 2, 2, 0, 4, 0, 4, 3, 0, 0];
const D: usize = 4;
type Rules = HashMap<(&'static str, char), (char, char, &'static str)>;

fn commas(v: u128) -> String {                     // 65536 -> "65,536"
    let s = v.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    out
}

fn bits(v: usize) -> usize { format!("{:b}", v).len() } // how many bits write the number v

fn rows(g: &[u32]) -> String {
    (0..D).map(|r| g[r * D..r * D + D].iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" "))
        .collect::<Vec<_>>().join(" / ")
}

fn units() -> Vec<Vec<usize>> {
    let mut u: Vec<Vec<usize>> = (0..D).map(|r| (0..D).map(|c| r * D + c).collect()).collect();
    u.extend((0..D).map(|c| (0..D).map(|r| r * D + c).collect::<Vec<_>>()));
    for br in [0, 2] { for bc in [0, 2] {
        u.push((0..2).flat_map(|i| (0..2).map(move |j| (br + i) * D + bc + j)).collect());
    } }
    u
}

fn full_check(g: &[u32], us: &[Vec<usize>]) -> (bool, u64) { // every pair in every unit, no early exit
    let (mut comps, mut good) = (0u64, true);
    for u in us { for a in 0..D { for b in a + 1..D {
        comps += 1;
        good = good && g[u[a]] != g[u[b]];
    } } }
    (good, comps)
}

fn back(g: &mut Vec<u32>, k: usize, blanks: &[usize], us: &[Vec<usize>], tests: &mut u64, out: &mut Vec<Vec<u32>>) {
    if k == blanks.len() { out.push(g.clone()); return; }
    let i = blanks[k];
    for v in 1..=D as u32 {
        *tests += 1;
        if us.iter().filter(|u| u.contains(&i)).all(|u| u.iter().all(|&j| g[j] != v)) {
            g[i] = v; back(g, k + 1, blanks, us, tests, out); g[i] = 0;
        }
    }
}

// Halts when no row applies.  Returns steps, cells visited, values seen, and
// the step at which a whole configuration first repeats (watch = true only).
fn run(rules: &Rules, word: &str, start: &'static str, watch: bool) -> (u64, usize, u64, Option<u64>) {
    let mut tape: BTreeMap<i64, char> = word.chars().enumerate().map(|(i, c)| (i as i64, c)).collect();
    let (mut head, mut state, mut steps, mut seen) = (0i64, start, 0u64, 1u64);
    let mut cells: HashSet<i64> = HashSet::from([0]);
    let mut configs: HashSet<(&str, i64, Vec<(i64, char)>)> = HashSet::new();
    while let Some(&(w, m, nxt)) = rules.get(&(state, *tape.get(&head).unwrap_or(&'_'))) {
        if steps >= 10_000_000 { break; }
        if watch {
            let key = (state, head, tape.iter().filter(|x| *x.1 != '_').map(|(a, b)| (*a, *b)).collect());
            if configs.contains(&key) { return (steps, cells.len(), seen, Some(steps)); }
            configs.insert(key);
        }
        if state == "carry" && nxt == "right" { seen += 1; } // one more value of the counter
        state = nxt;
        tape.insert(head, w);
        head += if m == 'R' { 1 } else { -1 };
        steps += 1;
        cells.insert(head);
    }
    (steps, cells.len(), seen, None)
}

fn sci(x: f64) -> String { let e = x.floor(); format!("{:.2} x 10^{}", 10f64.powf(x - e), e as i64) }

fn main() {
    let us = units();
    let blanks: Vec<usize> = (0..D * D).filter(|&i| PUZZLE[i] == 0).collect();
    // ---- road 1: brute force, a base-4 odometer over the blanks ----
    let (mut digits, mut fillings, mut comps, mut found) = (vec![1u32; blanks.len()], 0u64, 0u64, Vec::new());
    loop {
        let mut g = PUZZLE.to_vec();
        for (i, v) in blanks.iter().zip(&digits) { g[*i] = *v; }
        let (good, c) = full_check(&g, &us);
        fillings += 1; comps += c;
        if good { found.push(g); }
        let mut k = digits.len() as i64 - 1;
        while k >= 0 && digits[k as usize] == D as u32 { digits[k as usize] = 1; k -= 1; }
        if k < 0 { break; }
        digits[k as usize] += 1;
    }
    let b = blanks.len() as u32;
    let per = (3 * D * D * (D - 1) / 2) as u64;
    println!("grid {} x {}, {} blanks; puzzle by rows (0 = blank): {}", D, D, b, rows(&PUZZLE));
    println!("input length: {} cells x {} bits = {} bits", D * D, bits(D), D * D * bits(D));
    println!("road 1, brute force: fillings tried {} = 4^{}; comparisons {} = {} x {}", commas(fillings as u128), b, commas(comps as u128), commas(fillings as u128), per);
    println!("road 1, solutions found {}: {}", found.len(), rows(&found[0]));
    assert!(fillings == 4u64.pow(b) && comps == 4u64.pow(b) * per && found.len() == 1);

    // ---- road 2: backtracking, place a digit only if it clashes with nothing so far ----
    let (mut tests, mut sols) = (0u64, Vec::new());
    back(&mut PUZZLE.to_vec(), 0, &blanks, &us, &mut tests, &mut sols);
    println!("road 2, backtracking: same single solution {}; digits tested {}", if sols == found { "yes" } else { "no" }, tests);
    assert!(sols == found);

    // ---- road 3: the enumeration on a tape: a base-4 counter over b cells ----
    let mut counter: Rules = HashMap::new();
    for c in ['1', '2', '3', '4'] { counter.insert(("right", c), (c, 'R', "right")); }
    for (k, v) in [(("right", '_'), ('_', 'L', "carry")), (("carry", '4'), ('1', 'L', "carry")),
                   (("carry", '1'), ('2', 'R', "right")), (("carry", '2'), ('3', 'R', "right")),
                   (("carry", '3'), ('4', 'R', "right")), (("carry", '_'), ('_', 'R', "done"))] { counter.insert(k, v); }
    let formula = |k: u32| 2 * (4u64.pow(k + 1) - 1) / 3;
    println!("tape counter on b blanks: steps, cells used, values seen, steps by 2(4^(b+1) - 1)/3, configuration bound");
    for k in 1..=8u32 {
        let (steps, cells, seen, _) = run(&counter, &"1".repeat(k as usize), "right", false);
        let bound = 3 * cells as u128 * 5u128.pow(cells as u32);
        println!("  b {}  steps {:>7}  cells {:>2}  values {:>6}  formula {:>7}  bound {:>13}", k, commas(steps as u128), cells, commas(seen as u128), commas(formula(k) as u128), commas(bound));
        assert!(steps == formula(k) && cells == k as usize + 2 && seen == 4u64.pow(k) && steps as u128 <= bound);
    }

    println!("sizes: d, input bits n, log10 of d^(d^2) fillings, log10 of 2^n, n^4, comparisons per check");
    let mut chart = Vec::new();
    for d in [4usize, 9, 16, 25, 36] {
        let n = d * d * bits(d);
        let (f, e) = ((d * d) as f64 * (d as f64).log10(), n as f64 * 2f64.log10());
        chart.push((f, e));
        println!("  d {:>2}  n {:>5}  {:8.2}  {:8.2}  {:>22}  {:>7}", d, commas(n as u128), f, e, commas((n as u128).pow(4)), commas((3 * d * d * (d - 1) / 2) as u128));
        assert!(f <= e); // a filling is one string of n bits
    }
    println!("9 x 9 with 17 givens: 64 blanks, 9^64 = {} fillings; 324^4 = {}", sci(64.0 * 9f64.log10()), commas(324u128.pow(4)));

    // ---- what breaks ----
    println!("wrong: one fixed 9 x 9 grid, all blank: 9^81 = {} fillings, a constant", sci(81.0 * 9f64.log10()));
    println!("wrong: backtracking's {} tests on this puzzle read as the worst case, against {} fillings", tests, commas(fillings as u128));
    let (s8, c8, _, _) = run(&counter, &"1".repeat(8), "right", false);
    println!("wrong: counting space as time: 8 blanks use {} cells but {} steps", c8, commas(s8 as u128));
    let mut looping = counter.clone();
    looping.insert(("carry", '_'), ('_', 'R', "right")); // overflow restarts the count
    for k in [2u32, 8] {
        let (_, cells, _, rep) = run(&looping, &"1".repeat(k as usize), "right", true);
        let rep = rep.unwrap();
        println!("wrong: no halting row, b {}: {} cells, configuration repeats at step {}, so it never halts", k, cells, commas(rep as u128));
        assert!(rep == formula(k) && rep as u128 <= 3 * cells as u128 * 5u128.pow(cells as u32));
    }
    let (steps, cells, _, _) = run(&counter, &"1".repeat(9), "right", false);
    println!("try: counter on 9 blanks: {} steps, {} cells", commas(steps as u128), cells);
    assert!(steps == formula(9) && cells == 11);
    println!("chart, log10 fillings {}", chart.iter().map(|c| format!("{:.1}", c.0)).collect::<Vec<_>>().join(" "));
    println!("chart, log10 2^n      {}", chart.iter().map(|c| format!("{:.1}", c.1)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
