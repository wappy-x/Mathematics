// Proof against evidence -- the same check as the Python, in Rust.  No crates.
// Polya's claim: L(n) <= 0 for every n >= 2, where lambda(k) is +1 when k has an
// even number of prime factors (counted with repeats), -1 when odd, and L(n) is
// their running sum.  It holds for every n below 906,150,257 and fails there.
use std::collections::HashMap;

fn isqrt(x: u64) -> u64 {
    let mut r = (x as f64).sqrt() as u64;
    while r * r > x { r -= 1; }
    while (r + 1) * (r + 1) <= x { r += 1; }
    r
}
// road 2: sum over d of L(x / d) counts the squares up to x, so
// L(x) = isqrt(x) - (L(x / 2) + L(x / 3) + ... + L(x / x)), grouped by quotient
fn l_far(x: u64, table: &[i64], memo: &mut HashMap<u64, i64>) -> i64 {
    if (x as usize) < table.len() { return table[x as usize]; }
    if let Some(&v) = memo.get(&x) { return v; }
    let (mut r, mut d) = (isqrt(x) as i64, 2u64);
    while d <= x {
        let qt = x / d;
        let last = x / qt;
        r -= (last - d + 1) as i64 * l_far(qt, table, memo);
        d = last + 1;
    }
    memo.insert(x, r);
    r
}
fn factor(mut n: u64) -> Vec<u64> {               // trial division, smallest first
    let (mut f, mut p) = (Vec::new(), 2u64);
    while p * p <= n {
        while n % p == 0 { f.push(p); n /= p; }
        p += 1;
    }
    if n > 1 { f.push(n); }
    f
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // li by a second road: an area
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}
fn sgn(v: i64) -> String { format!("{:+}", v) }
fn join<T: ToString>(v: &[T], sep: &str) -> String {
    v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep)
}
fn main() {
    const U: usize = 1_000_000;                     // road 1: sieve every n up to here
    let mut omega = vec![0u32; U + 1];              // prime factors of n, with repeats
    for p in 2..=U {
        if omega[p] == 0 {                          // nothing divided p: p is prime
            let mut q = p;
            while q <= U {
                let mut m = q;
                while m <= U { omega[m] += 1; m += q; }
                q *= p;
            }
        }
    }
    let mut lam = vec![0i64; U + 1];
    let mut l = vec![0i64; U + 1];
    for k in 1..=U {
        lam[k] = if omega[k] % 2 == 0 { 1 } else { -1 };
        l[k] = l[k - 1] + lam[k];
    }
    println!("lambda(1..10): {}", (1..=10).map(|k| sgn(lam[k])).collect::<Vec<_>>().join(" "));
    println!("L(1..10): {}", join(&l[1..=10], " "));
    println!("L(10^k) for k = 0..6: {}", join(&(0..7).map(|k| l[10usize.pow(k)]).collect::<Vec<_>>(), " "));
    let top = *l[2..].iter().max().unwrap();
    let zeros: Vec<usize> = (2..=U).filter(|&n| l[n] == 0).collect();
    println!("road 1, sieve: largest L(n) for 2 <= n <= {} is {}", U, top);
    println!("road 1, sieve: n with L(n) = 0: {}", join(&zeros, " "));
    let squares: i64 = (1..=U).map(|d| l[U / d]).sum();
    println!("identity at n = {}: sum of L(n // d) = {}, squares up to n = {}", U, squares, isqrt(U as u64));
    let far_1e6 = l_far(U as u64, &l[..10_001], &mut HashMap::new());  // sees L up to 10,000
    println!("road 2, identity from L up to 10000: L({}) = {}", U, far_1e6);
    const N: u64 = 906_150_257;
    let before = l_far(N - 1, &l, &mut HashMap::new());
    let at = l_far(N, &l, &mut HashMap::new());
    println!("road 2, identity: L({}) = {}, L({}) = {}", N - 1, before, N, at);
    let f_n = factor(N);
    let lam_n: i64 = if f_n.len() % 2 == 0 { 1 } else { -1 };
    println!("road 3, trial division: {} = {}, {} prime factors, lambda = {}",
             N, join(&f_n, " x "), f_n.len(), sgn(lam_n));

    let (lo, hi) = (906_100_000u64, 906_600_000u64); // road 4: sieve a window by itself
    let w_len = (hi - lo + 1) as usize;
    let mut rem: Vec<u64> = (lo..=hi).collect();
    let mut cnt = vec![0u32; w_len];
    for p in 2..=isqrt(hi) {
        if omega[p as usize] == 1 {                 // p is prime
            let mut q = p;
            while q <= hi {
                let mut i = ((q - lo % q) % q) as usize;
                while i < w_len { cnt[i] += 1; rem[i] /= p; i += q as usize; }
                q *= p;
            }
        }
    }
    let mut run = l_far(lo - 1, &l, &mut HashMap::new());
    let mut win = Vec::with_capacity(w_len);
    for i in 0..w_len {
        run += if (cnt[i] + (rem[i] > 1) as u32) % 2 == 0 { 1 } else { -1 };
        win.push(run);
    }
    let pos: Vec<u64> = (0..w_len).filter(|&i| win[i] > 0).map(|i| lo + i as u64).collect();
    let peak = *win.iter().max().unwrap();
    let peak_at = lo + win.iter().position(|&v| v == peak).unwrap() as u64;
    const LEH: u64 = 906_180_359;                   // Lehman's 1960 failure, inside the window
    println!("road 4, window {}..{}: L({}) = {}, L({}) = {}", lo, hi, N, win[(N - lo) as usize], LEH, win[(LEH - lo) as usize]);
    println!("road 4: first n in the window with L(n) > 0 is {}, last is {}", pos[0], pos[pos.len() - 1]);
    println!("road 4: {} of {} n in the window have L(n) > 0; largest L = {} at n = {}",
             pos.len(), w_len, peak, peak_at);
    println!("chart, n then L(n), every 25000:");
    for j in (0..21).step_by(4) {
        let row: Vec<String> = (j..(j + 4).min(21))
            .map(|k| format!("{} {}", lo + 25000 * k as u64, win[25000 * k])).collect();
        println!("  {}", row.join("  "));
    }

    let mut w = vec![0u32; U + 1];                  // mistake: count each prime once
    for p in 2..=U {
        if omega[p] == 1 { let mut m = p; while m <= U { w[m] += 1; m += p; } }
    }
    let (mut run_w, mut first_w) = (1i64, None);
    for k in 2..=U {
        run_w += if w[k] % 2 == 0 { 1 } else { -1 };
        if run_w > 0 && first_w.is_none() { first_w = Some((k, run_w)); }
    }
    let first_w = first_w.unwrap();
    println!("mistake, n = 1 allowed: L(1) = {}", l[1]);
    println!("mistake, each prime counted once: running sum first above 0 at n = {}, value {}", first_w.0, first_w.1);
    let f41: Vec<u64> = (0..41u64).map(|n| n * n + n + 41).collect();
    let first_comp = (0..41).find(|&n| factor(f41[n]).len() > 1).unwrap();
    println!("mistake, n^2 + n + 41 prime for n = 0..{}; n = {} gives {} = {}",
             first_comp - 1, first_comp, f41[first_comp], join(&factor(f41[first_comp]), " x "));

    let pi = (2..=U).filter(|&k| omega[k] == 1).count();
    let x = (U as f64).ln();                        // li(x) = gamma + log log x + sum x^k/(k k!)
    let (mut term, mut total) = (1.0f64, 0.5772156649015329 + x.ln());
    for k in 1..200 { term *= x / k as f64; total += term / k as f64; }
    // 1/log t - 1/(t - 1): the spike at t = 1 removed; the removed part adds 0 over 0..2
    let g = |t: f64| if t == 0.0 { 1.0 } else if (t - 1.0).abs() < 1e-6 { 0.5 } else { 1.0 / t.ln() - 1.0 / (t - 1.0) };
    let li2 = simpson(&g, 0.0, 2.0, 2000);
    let li_area = li2 + simpson(&|u: f64| u.exp() / u, 2f64.ln(), (U as f64).ln(), 20000); // t = e^u
    println!("pi({}) = {}, li({}) = {:.1}, li - pi = {:.1}", U, pi, U, total, total - pi as f64);
    println!("li by area: li(2) = {:.3}, li(2) + area under 1/log t from 2 to {} = {:.1}", li2, U, li_area);
    println!("quoted, not computed: Polya 1919; Haselgrove 1958; Lehman 1960; Tanaka 1980, first failure 906150257;");
    println!("  li(x) - pi(x) > 0 for 2 <= x <= 1e19 (Buthe 2018); Littlewood 1914;");
    println!("  four colours: Appel and Haken 1976 (over 300 rules), 633 configurations (1997),");
    println!("  Coq proof (2005, published 2008); Goldbach checked to 4e18 (linked card)");

    assert!(far_1e6 == l[U] && l[U] == -530);         // road 2 against road 1
    assert!(squares == isqrt(U as u64) as i64);         // the identity behind road 2
    assert!(at == win[(N - lo) as usize] && at == 1 && before == 0); // road 2 against road 4
    assert!(at - before == lam_n);                      // step = lambda(N), by trial division
    assert!(top == 0 && pos[0] == N);                   // the slice: L(n) <= 0 below N
    assert!(win[(LEH - lo) as usize] == 1);             // Lehman's failure, from the window sieve
    assert!(f41[40] == 41 * 41 && first_comp == 40);
    assert!(pi == 78498 && total - pi as f64 > 0.0);
    assert!((total - li_area).abs() < 0.01);            // li: series against area
    println!("ALL CHECKS PASS");
}
