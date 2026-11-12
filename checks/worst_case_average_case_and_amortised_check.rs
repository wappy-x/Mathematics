// Worst, average and amortised cost -- the check behind the card.  std only.
// A playlist array that doubles when it fills.  Cost is counted in element writes and
// comparisons, never timed.  Every number on the card is printed here.
const N: u64 = 1_000_000; // tracks added to the playlist, one at a time

fn c(x: u64) -> String { // 1000000 -> "1,000,000"
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}

fn cf(x: f64, d: usize) -> String { // a decimal with thousands commas
    let s = format!("{:.*}", d, x);
    let (int, frac) = s.split_at(s.find('.').unwrap());
    format!("{}{}", c(int.parse().unwrap()), frac)
}

fn new_cap(cap: u64) -> u64 { if cap == 0 { 1 } else { 2 * cap } } // double when full

// Really build the array: copy every element on a resize, count every write.
fn append_run(n: u64) -> (u64, u64, u64, u64, i64, Vec<u64>) {
    let (mut slots, mut size, mut total, mut worst): (Vec<u64>, u64, u64, u64) = (Vec::new(), 0, 0, 0);
    let (mut bank, mut resizes, mut first) = (0i64, 0u64, Vec::new());
    for i in 0..n {
        let mut cost = 1; // writing the new track's id
        if size == slots.len() as u64 { // full: allocate a bigger block, copy all across
            let mut bigger = vec![0u64; new_cap(slots.len() as u64) as usize];
            for j in 0..size as usize { bigger[j] = slots[j]; cost += 1; }
            slots = bigger;
            resizes += 1;
        }
        slots[size as usize] = i;
        size += 1;
        total += cost;
        worst = worst.max(cost);
        bank += 3 - cost as i64; // charge 3 per append, pay the true cost
        let phi = 2 * size as i64 - slots.len() as i64;
        assert!(bank >= phi && phi >= 0); // savings cover the potential, every step
        if i < 20 { first.push(cost); }
    }
    for k in [0, 1, n / 2, n - 1] { assert!(slots[k as usize] == k); } // nothing lost
    (total, worst, slots.len() as u64, resizes, bank, first)
}

fn count_run(n: u64, grow: fn(u64) -> u64) -> u64 { // second simulator: counts, moves nothing
    let (mut size, mut cap, mut total) = (0u64, 0u64, 0u64);
    for _ in 0..n {
        if size == cap { total += size; cap = grow(cap); }
        total += 1;
        size += 1;
    }
    total
}

fn doubling_formula(n: u64) -> u64 { // n writes + copies 1 + 2 + 4 + ... below n
    let bits = 64 - (n - 1).leading_zeros();
    n + (1u64 << bits) - 1
}

fn search(lst: &[i64], target: i64) -> u64 {
    let mut comps = 0;
    for &x in lst {
        comps += 1;
        if x == target { return comps; }
    }
    comps // absent: every slot checked
}

fn thrash(shrink_at: u64) -> f64 { // 10 add/undo pairs at a full 524,288-slot array
    let (mut size, mut cap, mut total) = (1u64 << 19, 1u64 << 19, 0u64);
    for _ in 0..10 {
        total += 1;
        if size == cap { total += size; cap *= 2; }
        size += 1;
        total += 1; // the undo
        size -= 1;
        if size <= cap / shrink_at { total += size; cap /= 2; }
    }
    total as f64 / 20.0
}

fn main() {
    // ---- amortised: one million appends ----
    let (total, worst, cap, resizes, bank, first) = append_run(N);
    println!("playlist array, doubling, n = 1,000,000 appends, cost = element writes");
    println!("{:34}{:>14}", "writes of new tracks", c(N));
    println!("{:34}{:>14}", "copies during resizes", c(total - N));
    println!("{:34}{:>14}", "total, counted in the real run", c(total));
    println!("{:34}{:>14}", "total, second simulator", c(count_run(N, new_cap)));
    println!("{:34}{:>14}", "total, closed form", c(doubling_formula(N)));
    println!("{:34}{:>14}", "resizes", resizes);
    println!("{:34}{:>14}", "final capacity", c(cap));
    println!("{:34}{:>14}", "worst single append", c(worst));
    println!("{:34}{:>14.2}", "amortised cost per append", total as f64 / N as f64);
    println!("{:34}{:>14}", "bank left from 3 per append", c(bank as u64));
    println!("{:34}{:>14}", "potential 2 x size - capacity", c(2 * N - cap));
    let big = 1_048_577u64; // one past a power of two: the bound is tight
    let tb = doubling_formula(big);
    println!("tight case n = {}: total {}, per append {:.6}", c(big), c(tb), tb as f64 / big as f64);
    assert!(total == doubling_formula(N) && total == count_run(N, new_cap) && total == 2_048_575);
    assert!(worst == (1u64 << (63 - (N - 1).leading_zeros())) + 1 && worst == 524_289 && cap == 1_048_576);
    assert!(total <= 3 * N && tb == count_run(big, new_cap) && tb == 3_145_728 && tb < 3 * big);
    let full = count_run(1 << 20, new_cap); // exactly full: 2^20 appends
    assert!(doubling_formula(1 << 20) == full && full == 2_097_151);
    let mut run = vec![0u64];
    for &x in &first { let last = *run.last().unwrap(); run.push(last + x); }
    let costs: Vec<String> = first.iter().map(|x| x.to_string()).collect();
    println!("chart, cost of appends 1 to 20: {}", costs.join(", "));
    let avgs: Vec<String> = (1..21).map(|i| format!("{:.2}", run[i] as f64 / i as f64)).collect();
    println!("chart, running average: {}", avgs.join(", "));

    // ---- worst against average: find a track by checking slots in order ----
    let small: Vec<i64> = (0..1000).collect();
    let every: Vec<u64> = small.iter().map(|&t| search(&small, t)).collect(); // exhaustive
    let playlist: Vec<i64> = (0..N as i64).collect();
    let (best, last, absent) = (search(&playlist, 0), search(&playlist, N as i64 - 1), search(&playlist, -1));
    let (mut summed, mut skew10) = (0u64, 0u64); // slot pos costs pos comparisons
    for pos in 1..=N { // every slot, one by one
        summed += pos; // each slot equally likely
        skew10 += pos * if pos > N - 10_000 { 901 } else { 1 }; // 9 in 10 for the newest 10,000 (x 10N)
    }
    let every_sum: u64 = every.iter().sum();
    let every_max = *every.iter().max().unwrap();
    println!();
    println!("linear search, n = 1,000,000 tracks, cost = comparisons");
    println!("{:40}{:>12}", "best case, track in slot 1", c(best));
    println!("{:40}{:>12}", "worst case, track in the last slot", c(last));
    println!("{:40}{:>12}", "worst case, track absent", c(absent));
    println!("{:40}{:>12}", "average, every slot equally likely", cf(summed as f64 / N as f64, 1));
    println!("{:40}{:>12}", "average, formula (n + 1) / 2", cf((N + 1) as f64 / 2.0, 1));
    println!("{:40}{:>12}", "mean slot of the newest 10,000", cf((2 * N - 9_999) as f64 / 2.0, 1));
    println!("{:40}{:>12}", "average, 9 in 10 for newest 10,000", cf(skew10 as f64 / (10 * N) as f64, 1));
    println!("small playlist n = 1,000, every track searched: average {:.1}, worst {}",
             every_sum as f64 / 1000.0, c(every_max));
    assert!(best == 1 && last == N && absent == N && summed * 2 == N * (N + 1));
    assert!(every_sum * 2 == 1000 * 1001 && every_max == 1000);
    assert!(skew10 * 2 == 9 * N * (2 * N - 9_999) + N * (N + 1)); // 0.9 x newest mean + 0.1 x all

    // ---- what breaks ----
    let fixed = count_run(N, |cap| cap + 1000); // grow by a fixed 1,000 slots
    let x15 = count_run(N, |cap| (cap + (cap + 1) / 2).max(1)); // grow by half instead of doubling
    let k = (N - 1) / 1000;
    let (half, quarter) = (thrash(2), thrash(4));
    println!();
    println!("fixed +1,000 growth: total {}, closed form {}, per append {:.2}",
             c(fixed), c(N + 1000 * k * (k + 1) / 2), fixed as f64 / N as f64);
    println!("growth x1.5 instead of x2: total {}, per append {:.2}", c(x15), x15 as f64 / N as f64);
    println!("shrink at half full, 10 add/undo pairs at 524,288 tracks: per op {}", cf(half, 2));
    println!("shrink at quarter full, same 20 operations: per op {}", cf(quarter, 2));
    println!("worst append quoted as the per-append cost: predicts {} writes", c(worst * N));
    assert!(fixed == N + 1000 * k * (k + 1) / 2 && fixed == 500_500_000 && 3 * N < x15 && x15 <= 4 * N);
    assert!(half == ((1u64 << 19) + 1) as f64 && quarter * 20.0 == ((1u64 << 19) + 20) as f64);
    println!("ALL CHECKS PASS");
}
