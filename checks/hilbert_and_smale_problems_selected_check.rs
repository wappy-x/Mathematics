// Hilbert's and Smale's lists -- the same check as the Python, in Rust.  No crates.
// The ledger: both lists' statuses, typed twice (row by row, and as problem numbers
// under each status) and cross-checked, then tallied.  Then three computations, each
// against a second road: Matiyasevich's 1970 Fibonacci lemma, by direct remainders and
// by the card's formula; limit cycles of a degree-7 field, by a computed return map
// against the exact radii; Newton's method on x^5 - x - 1 against bisection.
const HIL: &str = "SMSVSVSOMSMMMSVOSSSVSSV"; // S answered: proved, M partly, O open, V kind note
const SMA: &str = "OSOOOMOVOMMMOSOMSV";
const BY_STATUS: [[&str; 4]; 2] = [["1 3 5 7 10 14 17 18 19 21 22", "2 9 11 12 13", "8 16", "4 6 15 20 23"],
                                   ["2 14 17", "6 10 11 12 16", "1 3 4 5 7 9 13 15", "8 18"]]; // typed again, by status
const PICKS: [(&str, char, &str, &str); 6] = [
    ("Hilbert 8", 'O', "Riemann hypothesis, Goldbach, twin primes", "open"),
    ("Hilbert 10", 'S', "a test for whole-number solutions", "no test exists: proved 1970"),
    ("Hilbert 16", 'O', "most limit cycles at degree n", "open; degree 2 has at least 4, 1979"),
    ("Smale 3", 'O', "P versus NP", "open"),
    ("Smale 15", 'O', "Navier-Stokes smooth for all time", "open; a 2026-09 forced blow-up claim is unrefereed"),
    ("Smale 17", 'S', "polynomial roots fast on average", "proved: randomised 2009, deterministic 2017")];
const TWO_PI: f64 = 6.283185307179586;

fn fib(m: u64) -> u64 { let (mut a, mut b) = (0u64, 1u64); for _ in 0..m { let t = a + b; a = b; b = t; } a }
fn pow_mod(mut b: u64, mut e: u64, m: u64) -> u64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}
fn p_of(s: f64) -> f64 { (1.0 - s) * (4.0 - s) * (9.0 - s) / 10.0 }
fn field(x: f64, y: f64) -> (f64, f64) { let p = p_of(x * x + y * y); (-y + x * p, x + y * p) }
fn turn(r0: f64) -> f64 {                       // one full turn: theta' = 1, time 2 pi
    let steps = 2000;
    let (mut x, mut y, h) = (r0, 0.0f64, TWO_PI / steps as f64);
    for _ in 0..steps {                         // classical Runge-Kutta, written out
        let k1 = field(x, y);
        let k2 = field(x + h / 2.0 * k1.0, y + h / 2.0 * k1.1);
        let k3 = field(x + h / 2.0 * k2.0, y + h / 2.0 * k2.1);
        let k4 = field(x + h * k3.0, y + h * k3.1);
        x += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        y += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    (x * x + y * y).sqrt() - r0                 // return-map displacement d(r0)
}
fn sci(mut v: f64) -> String {                  // 3 significant digits, same as Python
    let mut e = 0;
    while v < 1.0 { v *= 10.0; e -= 1; }
    format!("{:.2}e{}", v, e)
}
fn f(x: f64) -> f64 { x * x * x * x * x - x - 1.0 }
fn step(x: f64) -> f64 { x - f(x) / (5.0 * x * x * x * x - 1.0) }
fn newton(mut x: f64, root: f64) -> (Vec<f64>, f64) {
    let mut errs = vec![(x - root).abs()];
    while errs[errs.len() - 1] > 1e-12 && errs.len() <= 1000 { x = step(x); errs.push((x - root).abs()); }
    (errs, x)
}
fn join<T: std::fmt::Display>(v: &[T]) -> String { v.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(" ") }

fn main() {
    for (li, (name, codes)) in [("hilbert", HIL), ("smale", SMA)].into_iter().enumerate() {
        let t: Vec<usize> = "SMOV".chars().map(|c| codes.chars().filter(|&x| x == c).count()).collect();
        let spaced: Vec<String> = codes.chars().map(|c| c.to_string()).collect();
        println!("{:<7} 1-{}: {}", name, codes.len(), spaced.join(" "));
        println!("{:<7} tally: proved {}, partly {}, open {}, kind note {}, total {}",
                 name, t[0], t[1], t[2], t[3], t.iter().sum::<usize>());
        let rows: Vec<String> = "SMOV".chars().map(|c| codes.chars().enumerate().filter(|&(_, x)| x == c)
            .map(|(i, _)| (i + 1).to_string()).collect::<Vec<_>>().join(" ")).collect();
        assert!(t.iter().sum::<usize>() == codes.len() && rows == BY_STATUS[li]); // the two typings agree
    }
    println!("on both lists: Hilbert 8 = Smale 1 (Riemann), Hilbert 16 = Smale 13 (limit cycles)");
    let (h, s): (Vec<char>, Vec<char>) = (HIL.chars().collect(), SMA.chars().collect());
    assert!(h[7] == s[0] && h[15] == s[12]);    // one problem, typed in both lists
    for (name, code, what, status) in PICKS {
        let mut parts = name.split(' ');
        let (lst, num) = (parts.next().unwrap(), parts.next().unwrap().parse::<usize>().unwrap());
        assert!((if lst == "Hilbert" { &h } else { &s })[num - 1] == code); // lines match ledger
        println!("{:<11}{:<43}{}", name, what, status);
    }
    println!("unknowns over 0,1,2,...: 1 decidable; 9 undecidable; 2 to 8 open");
    let sols: Vec<(u64, u64)> = (1..=1000u64).flat_map(|b| (0..=b).map(move |a| (a, b)))
        .filter(|&(a, b)| (b * b + 1 == a * b + a * a) || (b * b == a * b + a * a + 1)).collect();
    let nbr: Vec<(u64, u64)> = (0..30).filter(|&k| fib(k + 1) <= 1000).map(|k| (fib(k), fib(k + 1))).collect();
    println!("(b^2 - ab - a^2)^2 = 1 with 0 <= a <= b <= 1000: {} solutions, (F_k, F_k+1) for k = 0..{}", sols.len(), nbr.len() - 1);
    assert!(sols == nbr);                       // neighbouring Fibonacci pairs, and nothing else

    let f5: Vec<u64> = (1..=5).map(|k| fib(5 * k)).collect();
    let r5: Vec<u64> = f5.iter().map(|v| v % 25).collect();
    println!("F_5k for k = 1..5: {} | remainders mod 25: {}", join(&f5), join(&r5));
    let form: Vec<u64> = (1..=5u64).map(|k| k * 5 * 3u64.pow(k as u32 - 1)).collect();
    let fm: Vec<u64> = form.iter().map(|v| v % 25).collect();
    println!("formula k F_5 F_4^(k-1): {} | mod 25: {} | F_25 = 25 x {}", join(&form), join(&fm), fib(25) / 25);
    let (n_max, k_max) = (20u64, 200u64);
    let (mut road1, mut road2, mut rule, mut plain) = (0u64, 0u64, 0u64, 0u64);
    for n in 3..=n_max {
        let (fn_, fm1) = (fib(n), fib(n - 1));
        let sq = fn_ * fn_;
        let (mut a, mut b) = (0u64, 1u64);       // F_m mod F_n^2, stepping m upward
        for m in 1..=n * k_max {
            let t = (a + b) % sq; a = b; b = t;
            if m % n != 0 { continue; }
            let k = m / n;
            let d1 = a == 0;                     // road 1: the remainder itself
            let rem = k * fn_ % sq * pow_mod(fm1, k - 1, sq) % sq; // road 2: the formula
            let d2 = rem == 0;
            let d3 = k % fn_ == 0;               // the rule: F_n divides k
            assert!(rem == a && d1 == d2 && d2 == d3); // formula = true remainder
            road1 += d1 as u64; road2 += d2 as u64; rule += d3 as u64; plain += (a % fn_ == 0) as u64;
        }
    }
    let pairs = (n_max - 2) * k_max;
    println!("pairs 3 <= n <= {}, 1 <= k <= {}: {}; F_n^2 | F_nk in {} (remainder), {} (formula), {} (F_n | k)",
             n_max, k_max, pairs, road1, road2, rule);
    println!("square dropped: F_n | F_nk in {} of {}", plain, pairs);
    println!("n = 2: F_2 = {} divides F_3 = {}, but 2 does not divide 3", fib(2), fib(3));
    println!("n = {}: F_n = {}, so F_n^2 | F_m forces m to be a multiple of {}", n_max, fib(n_max), n_max * fib(n_max));
    assert!(rule == (3..=n_max).map(|n| k_max / fib(n)).sum::<u64>() && plain == pairs);
    assert!(fib(25) == 25 * 3001 && fib(2) == 1);

    let grid: Vec<f64> = (0..11).map(|i| 0.55 + 0.3 * i as f64).collect();
    let d: Vec<f64> = grid.iter().map(|&r| turn(r)).collect();
    println!("r on the ray: {}", grid.iter().map(|r| format!("{:.2}", r)).collect::<Vec<_>>().join(" "));
    println!("d(r) after one turn: {}", d.iter().map(|v| format!("{:.3}", v)).collect::<Vec<_>>().join(" "));
    let mut cycles: Vec<(f64, &str)> = vec![];
    for i in 0..grid.len() - 1 {
        if (d[i] > 0.0) != (d[i + 1] > 0.0) {   // a sign change: a cycle in between
            let (mut lo, mut hi) = (grid[i], grid[i + 1]);
            for _ in 0..40 {
                let mid = (lo + hi) / 2.0;
                if (turn(mid) > 0.0) == (d[i] > 0.0) { lo = mid; } else { hi = mid; }
            }
            cycles.push(((lo + hi) / 2.0, if d[i] > 0.0 { "stable" } else { "unstable" }));
        }
    }
    println!("degree-7 field, cycles found: {}",
             cycles.iter().map(|(r, s)| format!("r = {:.6} {}", r, s)).collect::<Vec<_>>().join("; "));
    let coarse: Vec<bool> = [0.55, 2.65, 3.55].iter().map(|&r| turn(r) > 0.0).collect();
    println!("coarse ray r = 0.55, 2.65, 3.55: sign changes {}", (0..2).filter(|&i| coarse[i] != coarse[i + 1]).count());
    assert!(cycles.len() == 3 && cycles.iter().enumerate().all(|(j, (r, _))| (r - (j as f64 + 1.0)).abs() < 1e-6));

    let (mut lo, mut hi) = (1.0f64, 2.0f64);
    for _ in 0..60 {                            // bisection: f(1) < 0 < f(2)
        let mid = (lo + hi) / 2.0;
        if f(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    let root = lo;
    let (e, _) = newton(1.0, root);
    let c = 10.0 * root * root * root / (5.0 * root * root * root * root - 1.0); // f''/(2 f') at the root
    println!("x^5 - x - 1: root by bisection {:.12}", root);
    println!("Newton from 1, errors: {}", e[..5].iter().map(|&v| sci(v)).collect::<Vec<_>>().join(" "));
    println!("e4 / e3^2 = {:.4}, predicted f''/(2f') = {:.4}", e[4] / (e[3] * e[3]), c);
    let (z, x) = newton(0.0, root);
    let mut lp = vec![x];
    while lp.len() < 10 && (lp.len() < 2 || (lp[lp.len() - 1] - lp[0]).abs() > 1e-9) { lp.push(step(lp[lp.len() - 1])); }
    println!("steps to 1e-12: from 1, {}; from 0, none in {}: it repeats {}", e.len() - 1, z.len() - 1,
             lp[..lp.len() - 1].iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "));
    assert!(f(root).abs() < 1e-12 && (e[4] / (e[3] * e[3]) - c).abs() < 0.02 * c && lp.len() == 4);
    println!("ALL CHECKS PASS");
}
