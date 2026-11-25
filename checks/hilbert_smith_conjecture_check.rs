// Hilbert-Smith conjecture -- the same check as the Python, in Rust.  No crates.
// The 3-adic integers are modelled by their last N = 6 digits, the clock Z/729;
// the circle is modelled by angles in hundredths of a degree.
// Roads: brute-force search against a counting formula, at every step.
use std::collections::BTreeSet;
const N: u32 = 6;
const M: i64 = 729; // six 3-adic digits, 729 points

fn val(x: i64) -> u32 { // how many 3s divide x (N if x = 0)
    let x = x.rem_euclid(M);
    if x == 0 { return N; }
    (0..N).find(|&k| x % 3i64.pow(k + 1) != 0).unwrap()
}
fn digit(x: i64, k: u32) -> i64 { x / 3i64.pow(k) % 3 }
fn pos(x: i64) -> i64 { // the Cantor map, in units of 1/5^6
    (0..N).map(|k| 2 * digit(x, k) * 5i64.pow(N - 1 - k)).sum()
}
fn start(x: i64, n: u32) -> i64 { (0..n).map(|k| 2 * digit(x, k) * 5i64.pow(N - 1 - k)).sum() }
fn show(x: i64) -> String { (0..N).rev().map(|k| digit(x, k).to_string()).collect() }

fn main() {
    let half = (0..M).find(|x| 2 * x % M == 1).unwrap();
    println!("-1 is ...{}, 1/2 is ...{}, check 2 x {} = {} = 1 + {}", show(M - 1), show(half), half, 2 * half, M);
    println!("3-adic size: |1| = 1, |3| = 1/3, |81| = 1/{}, |162| = 1/{}", 3i64.pow(val(81)), 3i64.pow(val(162)));

    // 1. The Cantor picture: level n has 3^n pieces, each 1/5^n long, with gaps between.
    println!("level, pieces, piece length, total length, smallest gap");
    let p5 = 5i64.pow(N);
    for n in 0..4u32 {
        let starts: Vec<i64> = (0..3i64.pow(n)).map(|x| start(x, n)).collect::<BTreeSet<_>>().into_iter().collect();
        let l = 5i64.pow(N - n);
        let gap = starts.windows(2).map(|w| w[1] - (w[0] + l)).min().unwrap_or(0);
        let g = if n > 0 { format!("{}/{}", gap, p5) } else { "none".to_string() };
        println!("  {}, {}, 1/{}, {}/{}, {}", n, starts.len(), 5i64.pow(n), 3i64.pow(n), 5i64.pow(n), g);
        assert!(starts.len() as i64 == 3i64.pow(n) && (n == 0 || gap == 5i64.pow(N - n)) && starts[starts.len() - 1] + l <= p5);
    }
    let (mut lo, mut hi) = (vec![p5; N as usize], vec![0i64; N as usize]); // line against 3-adic distance
    for x in 0..M {
        for y in x + 1..M {
            let (v, d) = (val(y - x) as usize, (pos(y) - pos(x)).abs());
            lo[v] = lo[v].min(d);
            hi[v] = hi[v].max(d);
        }
    }
    println!("agree in last v digits: 3-adic distance, line distance range (units of 1/5^6)");
    for v in 0..N as usize {
        println!("  v = {}: 1/{}, {} to {}", v, 3i64.pow(v as u32), lo[v], hi[v]);
        assert!(lo[v] == 5i64.pow(N - 1 - v as u32) + 1 && hi[v] == 5i64.pow(N - v as u32) - 1); // tail bound
    }
    assert!((0..N as usize - 1).all(|v| hi[v + 1] < lo[v])); // closer 3-adically = closer on the line
    let px = |p: i64| format!("{:.2}", 20.0 + 480.0 * p as f64 / p5 as f64);
    let rows: Vec<String> = [1u32, 2, 3].iter()
        .map(|&n| (0..3i64.pow(n)).map(|x| px(start(x, n))).collect::<Vec<_>>().join(" ")).collect();
    println!("figure,{};widths {:.1} {:.1} {:.2}", rows.join(";"), 480.0 / 5.0, 480.0 / 25.0, 480.0 / 125.0);

    // 2. Small subgroups: every subgroup of the clock, found by generating, against divisors.
    let mut subs: Vec<BTreeSet<i64>> = (0..M).map(|g| (0..M).map(|k| g * k % M).collect())
        .collect::<BTreeSet<_>>().into_iter().collect();
    subs.sort_by(|a, b| b.len().cmp(&a.len()));
    println!("subgroups of Z/{} found by search: {}; divisors of {}: {}", M, subs.len(), M, (1..=M).filter(|d| M % d == 0).count());
    for h in &subs {
        let n = h.iter().map(|&x| val(x)).min().unwrap();
        let s = if h.len() > 1 { "s" } else { "" };
        println!("  3^{} Z: {} point{}, index {}, every point of size at most 1/{}", n, h.len(), s, M as usize / h.len(), 3i64.pow(n));
        let ball: BTreeSet<i64> = (0..M).filter(|&x| val(x) >= n).collect();
        assert!(*h == ball && h.len() as i64 == 3i64.pow(N - n)); // ball = subgroup
    }
    let ball: Vec<i64> = (0..M).filter(|&x| val(x) >= 1).collect();
    assert!(ball.iter().all(|&a| val(-a) >= 1 && ball.iter().all(|&b| val(a + b) >= 1))); // closed
    let least = (1..M).map(|k| val(81 * k)).min().unwrap(); // fewest 3s dividing any multiple
    println!("multiples of 81 stay small: largest size among 81k is 1/{}", 3i64.pow(least));
    let orders: Vec<i64> = [6u32, 7, 8].iter()
        .map(|&m| (1..=3i64.pow(m)).find(|k| 81 * k % 3i64.pow(m) == 0).unwrap()).collect();
    println!("order of 81 in Z/3^N for N = 6, 7, 8: {}", orders.iter().map(|o| o.to_string()).collect::<Vec<_>>().join(", "));
    assert!(orders == vec![9, 27, 81] && orders.iter().zip([6u32, 7, 8]).all(|(&o, m)| o == 3i64.pow(m - 4)) && least == 4);

    // 3. No small subgroups in the circle: every angle in the quarter-turn ball escapes it.
    let q: i64 = 9000; // 90.00 degrees, in hundredths
    let mut esc = Vec::new();
    for a in 1..q {
        let (mut k, mut t) = (1i64, a);
        while t.min(36000 - t) < q {
            k += 1;
            t = (t + a) % 36000;
        }
        esc.push(k);
    }
    assert!((1..q).all(|a| esc[(a - 1) as usize] == (q + a - 1) / a)); // brute force = ceil(9000 / a)
    println!("circle: all {} angles 0.01 to {:.2} degrees escape the ball of {} degrees; 1 degree after {} steps, 0.01 degrees after {}",
             esc.len(), (q - 1) as f64 / 100.0, q / 100, esc[99], esc[0]);

    // 4. Any homomorphism from the clock to the circle: a subgroup landing in the ball lands on 0.
    let (mut inball, mut trivial, mut formula) = (0, 0, 0);
    for j in 0..M { // x -> j x / 729 of a turn
        for n in 0..=N {
            let img: BTreeSet<i64> = (0..M).map(|k| j * 3i64.pow(n) * k % M).collect();
            if img.iter().all(|&i| i.min(M - i) * 4 < M) {
                inball += 1;
                if img.len() == 1 && img.contains(&0) { trivial += 1; }
            }
            if j * 3i64.pow(n) % M == 0 { formula += 1; }
        }
    }
    println!("homomorphisms x -> jx/729 turn, subgroups 3^n Z: {} images inside the ball, {} of them just 0", inball, trivial);
    assert!(inball == trivial && trivial == formula);

    // 5. What breaks.
    let ker: Vec<i64> = (0..M).filter(|x| x % 27 == 0).collect(); // x acts as a turn of x/27
    println!("turn by x/27: {} of {} points act as no turn at all (kernel 27Z, index {}); step {:.2} degrees",
             ker.len(), M, M as usize / ker.len(), 36000.0 / 27.0 / 100.0);
    let (mut orbit, mut x) = (1, 1i64); // adding 1, the odometer, on the Cantor set
    while x != 0 {
        x = (x + 1) % M;
        orbit += 1;
    }
    println!("adding 1 on the Cantor set: one orbit of {} points; ...{} + 1 = ...{}", orbit, show(M - 1), show(0));
    let fixers: Vec<i64> = (0..M).filter(|&g| (0..M).any(|y| (y + g) % M == y)).collect();
    assert!(orbit == M && fixers == vec![0] && ker.len() == 27);
    println!("dimension n, Yang's orbit-space dimension n + 2, status 2026-11-24");
    for (n, s) in [(1, "proved, 1955"), (2, "proved, 1955"), (3, "proved, 2013"), (4, "open")] {
        let up = if n == 4 { " and up" } else { "" };
        println!("  {}{}, {}{}, {}", n, up, n + 2, up, s);
    }
    println!("ALL CHECKS PASS");
}
