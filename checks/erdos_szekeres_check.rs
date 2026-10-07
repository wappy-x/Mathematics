// Erdos-Szekeres -- the same check as erdos_szekeres_check.py, in Rust.  No crates.  Ten daily
// closing prices of Harlow Cement, all different.  Each day carries two labels: the longest
// strictly rising run of days ending there, and the longest strictly falling one.  Road two
// ignores the labels and tries every set of days instead.
const PRICES: [f64; 10] = [43.20, 42.10, 44.60, 41.65, 43.95, 46.30, 42.88, 45.15, 47.05, 45.70];
const NINE: [f64; 9] = [45.90, 44.30, 43.10, 48.70, 47.20, 46.40, 51.50, 50.10, 49.30];
const R: usize = 4; const N: usize = 10;
fn up(u: f64, v: f64) -> bool { u < v }
fn down(u: f64, v: f64) -> bool { u > v }
fn never_down(u: f64, v: f64) -> bool { u <= v }
fn labels(p: &[f64], ok: fn(f64, f64) -> bool) -> Vec<usize> {   // road one: look back from each day
    let mut out: Vec<usize> = Vec::new();
    for j in 0..p.len() { let v = (0..j).filter(|&i| ok(p[i], p[j])).map(|i| out[i] + 1).max().unwrap_or(1); out.push(v) }
    out
}
fn longest(p: &[f64], ok: fn(f64, f64) -> bool) -> usize {       // road two: all 2^n sets of days
    (0u32..(1u32 << p.len())).map(|m| (0..p.len()).filter(|i| m >> i & 1 == 1).collect::<Vec<usize>>())
        .filter(|d| d.windows(2).all(|w| ok(p[w[0]], p[w[1]]))).map(|d| d.len()).max().unwrap()
}
fn trace(p: &[f64], lab: &[usize], ok: fn(f64, f64) -> bool) -> Vec<usize> {
    let mut k = *lab.iter().max().unwrap();
    let mut j = lab.iter().position(|&v| v == k).unwrap();
    let mut run = vec![j];
    while k > 1 { j = (0..j).find(|&i| lab[i] == k - 1 && ok(p[i], p[j])).unwrap(); run.push(j); k -= 1 }
    run.reverse(); run
}
fn streak(p: &[f64], ok: fn(f64, f64) -> bool) -> usize {        // the wrong reading: days in a row
    let mut runs = vec![1usize];
    for i in 1..p.len() { runs.push(if ok(p[i - 1], p[i]) { runs[i - 1] + 1 } else { 1 }) }
    *runs.iter().max().unwrap()
}
fn show(p: &[f64], run: &[usize], sign: &str) -> String {
    let days: Vec<String> = run.iter().map(|i| (i + 1).to_string()).collect();
    let vals: Vec<String> = run.iter().map(|&i| format!("{:.2}", p[i])).collect();
    format!("days {} at {}", days.join(", "), vals.join(&format!(" {} ", sign)))
}
fn row(name: &str, v: &[usize]) -> String {
    format!("{:<16}{}", name, v.iter().map(|x| format!("{:>6}", x)).collect::<Vec<String>>().join(""))
}
fn prices(p: &[f64]) -> String { p.iter().map(|x| format!("{:.2}", x)).collect::<Vec<String>>().join(" ") }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let tied: Vec<f64> = (0..5).flat_map(|_| [44.00_f64, 43.00]).collect();
    let (a, b) = (labels(&PRICES, up), labels(&PRICES, down));
    let (na, nb) = (labels(&NINE, up), labels(&NINE, down));
    let mut np: Vec<(usize, usize)> = na.iter().zip(&nb).map(|(&x, &y)| (x, y)).collect();
    np.sort();
    let grid = np == (1..=3).flat_map(|i| (1..=3).map(move |j| (i, j))).collect::<Vec<(usize, usize)>>();
    let mut seen: Vec<(usize, usize)> = a.iter().zip(&b).map(|(&x, &y)| (x, y)).collect();
    seen.sort(); seen.dedup();
    let (ta, tb, tna, tnb) = (*a.iter().max().unwrap(), *b.iter().max().unwrap(),
                              *na.iter().max().unwrap(), *nb.iter().max().unwrap());
    let (run_up, run_down) = (trace(&PRICES, &a, up), trace(&PRICES, &b, down));
    let brute = [longest(&PRICES, up), longest(&PRICES, down), longest(&NINE, up), longest(&NINE, down)];
    println!("ten closing prices, day 1 to day 10: {}", prices(&PRICES));
    println!("{}", row("day", &(1..=N).collect::<Vec<usize>>()));
    println!("{}", row("rising label a", &a));
    println!("{}", row("falling label b", &b));
    println!("all {} label pairs different: {}", N, yn(seen.len() == N));
    println!("longest rising run: labels {}, every set of days tried {}", ta, brute[0]);
    println!("longest falling run: labels {}, every set of days tried {}", tb, brute[1]);
    println!("{} x {} = {}, and that is at least the {} days", ta, tb, ta * tb, N);
    println!("the rising run of {}: {}", ta, show(&PRICES, &run_up, "<"));
    println!("the falling run of {}: {}", tb, show(&PRICES, &run_down, ">"));
    println!("boxes if no label passed 3: 3 x 3 = 9, one fewer than the {} days", N);
    println!("nine days, {}: longest rising {}, longest falling {}", prices(&NINE), brute[2], brute[3]);
    println!("its nine label pairs fill the 3 x 3 grid once each: {}", yn(grid));
    println!("mistake 1, runs read as days in a row: longest rising {}, longest falling {}",
             streak(&PRICES, up), streak(&PRICES, down));
    println!("mistake 2, nine days instead of ten: longest rising {}, one short of {}", tna, R);
    println!("mistake 3, only 44.00 and 43.00, alternating: longest rising {}, longest falling {}, longest never-falling {}",
             longest(&tied, up), longest(&tied, down), longest(&tied, never_down));
    assert!((ta, tb) == (brute[0], brute[1]) && (ta, tb) == (4, 3));
    assert!(seen.len() == N && ta * tb >= N);
    assert!(run_up.len() == R && run_up.windows(2).all(|w| PRICES[w[0]] < PRICES[w[1]]) && streak(&PRICES, up) < R);
    assert!((tna, tnb) == (brute[2], brute[3]) && (tna, tnb) == (3, 3) && grid);
    println!("ALL CHECKS PASS");
}
