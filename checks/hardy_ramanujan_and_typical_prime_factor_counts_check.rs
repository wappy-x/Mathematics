// Hardy-Ramanujan -- the same check as the Python, in Rust.  No crates.
// A smallest-prime-factor sieve gives omega(n) (distinct primes) and Omega(n)
// (primes with repeats) for every n up to 1,050,000.  Road one counts n by n.
// Road two counts prime by prime and pair by pair (Turan's switch of the order
// of summation).  The two roads must agree exactly; then the prime sums give
// Turan's variance bound, which the direct count must respect.
const N: usize = 1_050_000;
const A: i64 = 950_000;
const B: i64 = 1_050_000;
const X: usize = 1_000_000;

fn com(v: f64, d: usize) -> String {               // thousands commas, d decimals
    let s = format!("{:.*}", d, v);
    let (int, frac) = match s.find('.') { Some(i) => (&s[..i], &s[i..]), None => (&s[..], "") };
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    format!("{}{}", out, frac)
}
fn cnt(d: i64) -> i64 { B / d - (A - 1) / d }     // multiples of d in the window

fn main() {
    let mut spf: Vec<usize> = (0..=N).collect();  // smallest prime factor
    let mut i = 2;
    while i * i <= N {
        if spf[i] == i { let mut j = i * i; while j <= N { if spf[j] == j { spf[j] = i } j += i } }
        i += 1;
    }
    let (mut w, mut ww, mut e, mut tau) = (vec![0i64; N + 1], vec![0i64; N + 1], vec![0i64; N + 1], vec![1i64; N + 1]);
    for n in 2..=N {
        let p = spf[n]; let m = n / p;
        ww[n] = ww[m] + 1;
        e[n] = if spf[m] == p { e[m] + 1 } else { 1 };   // exponent of p in n
        w[n] = w[m] + if e[n] == 1 { 1 } else { 0 };
        tau[n] = tau[m] / e[n] * (e[n] + 1);            // divisor count
    }
    let primes: Vec<i64> = (2..=N).filter(|&p| spf[p] == p).map(|p| p as i64).collect();
    let fac = |mut n: usize| -> String {           // factorisation as text
        let mut out: Vec<String> = Vec::new();
        while n > 1 {
            let (p, mut k) = (spf[n], 0);
            while n % p == 0 { n /= p; k += 1 }
            out.push(if k > 1 { format!("{}^{}", p, k) } else { format!("{}", p) });
        }
        out.join(" x ")
    };
    for n in [999_999usize, X, 1_000_001, 720_720] {
        println!("n = {} = {}: omega = {}, Omega = {}, divisors = {}", com(n as f64, 0), fac(n), w[n], ww[n], tau[n]);
    }
    let c = B - A + 1; let cf = c as f64;
    let win = |v: &Vec<i64>| v[A as usize..=B as usize].to_vec();
    let (wv, wwv) = (win(&w), win(&ww));
    let s1: i64 = wv.iter().sum(); let s2: i64 = wv.iter().map(|v| v * v).sum(); let sw: i64 = wwv.iter().sum();
    let by_p: i64 = primes.iter().map(|&p| cnt(p)).sum();
    let mut pairs: Vec<(i64, i64)> = Vec::new();  // p < q with pq <= B
    for (i, &p) in primes.iter().enumerate() {
        if p * p > B { break }
        for &q in &primes[i + 1..] { if p * q > B { break } pairs.push((p, q)) }
    }
    let by_pq = by_p + 2 * pairs.iter().map(|&(p, q)| cnt(p * q)).sum::<i64>();
    println!("window {} to {}: {} numbers; sum of omega n by n {}, prime by prime {}", com(A as f64, 0), com(B as f64, 0), com(cf, 0), com(s1 as f64, 0), com(by_p as f64, 0));
    println!("sum of omega^2 n by n {}, by primes and {} prime pairs {}", com(s2 as f64, 0), com(pairs.len() as f64, 0), com(by_pq as f64, 0));
    let xf = X as f64;
    let mut h = 0.0;
    for k in (1..=X).rev() { h += 1.0 / k as f64 }
    let gamma = h - xf.ln() - 1.0 / (2.0 * xf) + 1.0 / (12.0 * xf * xf);
    let mut msum = 0.0;
    for &p in &primes { let q = p as f64; msum += (1.0 - 1.0 / q).ln() + 1.0 / q }
    let mm = gamma + msum;
    let l = xf.ln().ln();
    println!("Mertens' constant M = {:.6}; log log 10^6 = {:.6}; log log 10^6 + M = {:.6}", mm, l, l + mm);
    let mean = s1 as f64 / cf; let var = (c * s2 - s1 * s1) as f64 / (c * c) as f64;
    println!("window mean omega = {:.6} (gap {:+.6}, 1/log 10^6 = {:.6}); mean Omega = {:.6}", mean, mean - l - mm, 1.0 / xf.ln(), sw as f64 / cf);
    println!("window variance of omega = {:.6}; standard deviation {:.6}", var, var.sqrt());
    let hist: Vec<i64> = (0..8).map(|k| wv.iter().filter(|&&v| v == k).count() as i64).collect();
    for k in 1..8 {
        let bar = "#".repeat((hist[k] as f64 / 1000.0).round() as usize);
        println!("omega = {}: {:>6} {:<38} {:.4}", k, com(hist[k] as f64, 0), bar, hist[k] as f64 / cf);
    }
    println!("within L/2 of L (omega 2 or 3): {:.4}; omega 2, 3 or 4: {:.4}", (hist[2] + hist[3]) as f64 / cf, (hist[2] + hist[3] + hist[4]) as f64 / cf);
    let t = by_p; let sq: i64 = primes.iter().map(|&p| cnt(p) * cnt(p)).sum();
    let diag: i64 = primes.iter().map(|&p| c * cnt(p) - cnt(p) * cnt(p)).sum();
    let near_pq: i64 = pairs.iter().map(|&(p, q)| cnt(p) * cnt(q)).sum();
    let cov = |keep: &dyn Fn(i64) -> bool| -> i64 { // pairs whose product pq passes the filter
        2 * pairs.iter().filter(|&&(p, q)| keep(p * q)).map(|&(p, q)| c * cnt(p * q) - cnt(p) * cnt(q)).sum::<i64>()
    };
    let (close_s, close_in) = (cov(&|m| m <= c), cov(&|m| m >= A)); let close_m = cov(&|_| true) - close_s - close_in;
    let n_in = pairs.iter().filter(|&&(p, q)| p * q >= A).count();   // pq is itself a window number
    let far = -((t * t - sq) - 2 * near_pq);
    let c2 = (c * c) as f64;
    println!("variance split: each prime alone {:.6}; pairs with pq <= {} {:+.6}; pq up to {} {:+.6}", diag as f64 / c2, com(cf, 0), close_s as f64 / c2, com((A - 1) as f64, 0), close_m as f64 / c2);
    let pi2 = std::f64::consts::PI.powi(2) / 6.0;
    println!("variance split: pq inside the window ({} pairs) {:+.6}; pq > {} {:+.6}; total {:.6}", com(n_in as f64, 0), close_in as f64 / c2, com(B as f64, 0), far as f64 / c2, (diag + close_s + close_m + close_in + far) as f64 / c2);
    println!("shares: 2 | n {:.6}, 3 | n {:.6}, product {:.6}, 6 | n {:.6}; 1031 | n {}, 1033 | n {}, {} | n {}",
             cnt(2) as f64 / cf, cnt(3) as f64 / cf, (cnt(2) * cnt(3)) as f64 / c2, cnt(6) as f64 / cf, cnt(1031), cnt(1033), com((1031 * 1033) as f64, 0), cnt(1031 * 1033));
    let mut gs = 0.0;
    for n in A as usize..=B as usize { gs += (ww[n] - w[n]) as f64 }
    let gap = gs / cf;
    let mut pp1 = 0.0;
    for &p in &primes { pp1 += 1.0 / (p * (p - 1)) as f64 }
    let gx = (ww[1..=X].iter().sum::<i64>() - w[1..=X].iter().sum::<i64>()) as f64 / xf;
    println!("Omega - omega: window mean {:.6}; mean up to 10^6 {:.6}; sum of 1/(p(p-1)) = {:.6}", gap, gx, pp1);
    let px: Vec<i64> = primes.iter().cloned().filter(|&p| p <= X as i64).collect();
    let pin = px.len() as f64;
    let mut s = 0.0;
    for &p in &px { s += 1.0 / p as f64 }
    let sx1: i64 = w[1..=X].iter().sum(); let sx2: i64 = w[1..=X].iter().map(|v| v * v).sum();
    let floor_sum: i64 = px.iter().map(|&p| X as i64 / p).sum();
    let mut d = 0.0;
    for n in 1..=X { let r = w[n] as f64 - l; d += r * r }
    let u = xf * (s * s + s) - 2.0 * l * (xf * s - pin) + xf * l * l;
    println!("n <= 10^6: sum 1/p = {:.6}; mean omega {:.6}, by floor(x/p) {:.6}", s, sx1 as f64 / xf, floor_sum as f64 / xf);
    println!("window mean against n <= 10^6: S - L - M = {:+.6}; mean up to 10^6 + 1/log 10^6 = {:.6}, window {:.6}", s - l - mm, sx1 as f64 / xf + 1.0 / xf.ln(), mean);
    let (nx, xx): (Vec<(i64, i64)>, i64) = (pairs.iter().cloned().filter(|&(p, q)| p * q <= X as i64).collect(), X as i64);
    let far_x = -((sx1 * sx1 - px.iter().map(|&p| (xx / p) * (xx / p)).sum::<i64>()) - 2 * nx.iter().map(|&(p, q)| (xx / p) * (xx / q)).sum::<i64>());
    let h2 = px.iter().fold(0.0, |a, &p| a + 1.0 / (p * p) as f64); let hpq = nx.iter().fold(0.0, |a, &(p, q)| a + 1.0 / (p * q) as f64);
    let heur = s * s - h2 - 2.0 * hpq;
    println!("pairs with pq > 10^6, n <= 10^6: {:+.6}; sum of 1/(pq) over them {:.6}; limit pi^2/6 = {:.6}", far_x as f64 / (xx * xx) as f64, heur, pi2);
    println!("turan: sum omega^2 / x = {:.6} <= S^2 + S = {:.6}; sum omega / x = {:.6} >= S - pi(x)/x = {:.6}", sx2 as f64 / xf, s * s + s, sx1 as f64 / xf, s - pin / xf);
    println!("turan: sum (omega - L)^2 / x = {:.6} <= bound {:.6} = L + {:.6}", d / xf, u / xf, u / xf - l);
    for tt in [1.0f64, 2.0, 3.0] {
        let out = (1..=X).filter(|&n| (w[n] as f64 - l).abs() >= tt * l.sqrt()).count();
        println!("|omega - L| >= {:.1} sqrt(L): share {:.6}; Chebyshev bound {:.6}", tt, out as f64 / xf, u / xf / (tt * tt * l));
    }
    for (a, b) in [(9_500usize, 10_500usize), (99_500, 100_500)] {   // try changing: smaller windows
        let (s, q, k) = (w[a..=b].iter().sum::<i64>(), w[a..=b].iter().map(|v| v * v).sum::<i64>(), (b - a + 1) as i64);
        println!("try: window {} to {}: mean omega {:.6}, variance {:.6}", com(a as f64, 0), com(b as f64, 0), s as f64 / k as f64, (k * q - s * s) as f64 / (k * k) as f64);
    }
    println!("try: 997 x 1009 = {} divides {} window number", com((997 * 1009) as f64, 0), cnt(997 * 1009));
    println!("x | mean omega | variance | log log x | log log x + M");
    let mut chart: Vec<(f64, f64, f64)> = Vec::new();
    for k in 2..7u32 {
        let x = 10usize.pow(k); let xi = x as i64;
        let a1: i64 = w[1..=x].iter().sum(); let a2: i64 = w[1..=x].iter().map(|v| v * v).sum();
        let (mx, vx, ll) = (a1 as f64 / x as f64, (xi * a2 - a1 * a1) as f64 / (xi * xi) as f64, (x as f64).ln().ln());
        chart.push((mx, vx, ll + mm));
        println!("10^{} | {:.6} | {:.6} | {:.6} | {:.6}", k, mx, vx, ll, ll + mm);
    }
    let j = |f: &dyn Fn(&(f64, f64, f64)) -> f64| chart.iter().map(|r| format!("{:.2}", f(r))).collect::<Vec<_>>().join(", ");
    println!("chart, mean: {}", j(&|r| r.0));
    println!("chart, variance: {}", j(&|r| r.1));
    println!("chart, log log x + M: {}", j(&|r| r.2));
    let first7 = (1..=X).find(|&n| w[n] == 7).unwrap();
    println!("largest omega up to 10^6: {}, first at {} = {}", w[1..=X].iter().max().unwrap(), com(first7 as f64, 0), fac(first7));
    for (name, lg) in [("10^9", 9.0 * 10f64.ln()), ("10^80", 80.0 * 10f64.ln()), ("2^1024", 1024.0 * 2f64.ln())] {
        println!("log log {} = {:.4}; plus M = {:.4}", name, lg.ln(), lg.ln() + mm);
    }
    println!("mean omega 10 needs about {} digits", com((10.0 - mm).exp() / 10f64.ln(), 0));
    let mut tw = win(&tau); tw.sort();
    println!("divisors in window: mean {:.4}; median {}; 2^L = {:.4}", tw.iter().sum::<i64>() as f64 / cf, tw[(c / 2) as usize], 2f64.powf(l));
    let mut indep = 0.0;
    for &p in &primes { let f = cnt(p) as f64 / cf; indep += f * (1.0 - f) }
    println!("mistake 1, variance read as log log n: {:.4} against {:.4}", l, var);
    println!("mistake 2, primes independent: variance {:.4} against {:.4}", indep, var);
    println!("mistake 3, count with repeats: mean Omega {:.4} against omega {:.4}", sw as f64 / cf, mean);
    println!("mistake 4, base-10 logs: log10 log10 10^6 = {:.4} against {:.4}", 6f64.log10(), l);
    assert!(s1 == by_p && s2 == by_pq);                                  // two roads, exact
    assert!(diag + close_s + close_m + close_in + far == c * s2 - s1 * s1); // variance split, exact
    assert!((close_s as f64).abs() < 0.01 * c2);                         // this window's small pairs
    assert!(n_in == wv.iter().zip(wwv.iter()).filter(|&(&a, &b)| a == 2 && b == 2).count()); // pq in window = semiprimes
    assert!(-heur <= far_x as f64 / (xx * xx) as f64 && far_x < 0);      // floor(x/p)/x <= 1/p
    assert!(sx1 == floor_sum && px.len() == 78498);                      // pi(10^6), known table
    assert!(sx2 as f64 <= xf * (s * s + s) && sx1 as f64 >= xf * s - pin); // Turan's two steps
    assert!(d <= u && u / xf - l < 1.0);                                 // variance <= L + O(1)
    assert!((mean - sx1 as f64 / xf - 1.0 / xf.ln()).abs() < 0.01 && gx <= pp1 && (gap - pp1).abs() < 0.05); // means
    assert!((mm - 0.261497).abs() < 1e-5 && (s - l - mm).abs() < 0.001); // Mertens' constant and sum
    println!("ALL CHECKS PASS");
}
