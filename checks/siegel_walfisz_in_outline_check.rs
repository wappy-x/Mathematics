// Siegel-Walfisz -- the check behind the card.  std only.  Primes below a million split into
// the classes mod 7 by a sieve and by trial division; li(x) by its series and by Simpson's rule;
// L(s, chi) for the quadratic character mod 7 by Euler-Maclaurin and, at s = 1, by a closed form;
// then what an exceptional zero would cost and why the modulus must stay small.
const X: usize = 1_000_000;
const Q: usize = 7;
const GAMMA: f64 = 0.5772156649015329; // Euler's constant, quoted

fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn isqrt(n: usize) -> usize { let mut r = (n as f64).sqrt() as usize; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn classes(ps: &[usize], q: usize) -> Vec<usize> { let mut c = vec![0; q]; for &p in ps { c[p % q] += 1; } c }
fn li_series(x: f64) -> f64 { // li(x) = gamma + ln ln x + sum (ln x)^n / (n n!)
    let (u, mut term, mut s, mut n) = (x.ln(), 1.0f64, 0.0f64, 0.0f64);
    loop {
        n += 1.0; term *= u / n; s += term / n;
        if term / n < 1e-17 * s { return GAMMA + u.ln() + s; }
    }
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut inner = 0.0;
    for k in 1..m { inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    h / 3.0 * (f(a) + f(b) + inner)
}
fn lchi(s: f64, chi: &[i64]) -> f64 { // sum of chi(n) n^-s: head plus Euler-Maclaurin tail
    let (n_head, qf) = (40usize, Q as f64);
    let mut tot = 0.0;
    for a in 1..Q {
        let y = (Q * n_head + a) as f64;
        let mut head = 0.0;
        for n in 0..n_head { head += ((Q * n + a) as f64).powf(-s); }
        let integ = if (s - 1.0).abs() < 1e-12 { -y.ln() / qf } else { y.powf(1.0 - s) / (qf * (s - 1.0)) };
        let tail = y.powf(-s) / 2.0 + qf * s / 12.0 * y.powf(-s - 1.0)
            - qf.powi(3) * s * (s + 1.0) * (s + 2.0) / 720.0 * y.powf(-s - 3.0);
        tot += chi[a] as f64 * (head + integ + tail);
    }
    tot
}
fn modpow(mut b: usize, mut e: usize, m: usize) -> usize { let mut r = 1; b %= m; while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r }

fn main() {
    let mut flag = vec![true; X + 1]; flag[0] = false; flag[1] = false; // road 1: sieve
    for p in 2..1001 { if flag[p] { let mut m = p * p; while m <= X { flag[m] = false; m += p; } } }
    let primes: Vec<usize> = (0..=X).filter(|&p| flag[p]).collect();
    let small: Vec<usize> = (2..1001).filter(|&p| (2..isqrt(p) + 1).all(|d| p % d != 0)).collect();
    let is_prime_td = |n: usize| -> bool { // road 2: trial division
        for &d in &small { if d * d > n { return true; } if n % d == 0 { return false; } }
        true
    };
    let td: Vec<usize> = (2..=X).filter(|&n| is_prime_td(n)).collect();
    let (c7, t7) = (classes(&primes, Q), classes(&td, Q));
    println!("primes below 10^6: sieve {}; trial division {}", primes.len(), td.len());
    let join = |c: &Vec<usize>| (0..Q).map(|a| format!("class {} {}", a, c[a])).collect::<Vec<_>>().join("; ");
    println!("mod 7, sieve: {}", join(&c7));
    println!("mod 7, trial division: {}", join(&t7));
    let xf = X as f64; let lx = xf.ln();
    let li_off = simpson(|u: f64| u.exp() / u, 2f64.ln(), lx, 20000);
    let (li_a, li_b) = (li_series(xf), li_off + li_series(2.0));
    println!("li(10^6): series {:.2}; Simpson from 2 plus li(2) {:.2}; offset Li(10^6) {:.2}; li minus pi {:.2}",
        li_a, li_b, li_off, li_a - primes.len() as f64);
    let six = &c7[1..]; let (mn, mx) = (*six.iter().min().unwrap(), *six.iter().max().unwrap());
    let pred = li_a / 6.0; let mean = (primes.len() - 1) as f64 / 6.0;
    println!("prediction li(x)/6 = {:.2}; mean of the six classes {:.2}; smallest {}, largest {}", pred, mean, mn, mx);
    println!("spread {} primes = {:.2} percent of the mean; class / prediction from {:.5} to {:.5}",
        mx - mn, 100.0 * (mx - mn) as f64 / mean, mn as f64 / pred, mx as f64 / pred);
    let mut chi = vec![0i64; Q]; // Euler's criterion: a^3 mod 7
    for a in 1..Q { chi[a] = if modpow(a, 3, Q) == 1 { 1 } else { -1 }; }
    let sq: Vec<String> = (1..Q).filter(|&a| chi[a] == 1).map(|a| a.to_string()).collect();
    let res: usize = (1..Q).filter(|&a| chi[a] == 1).map(|a| c7[a]).sum();
    let non: usize = (1..Q).filter(|&a| chi[a] == -1).map(|a| c7[a]).sum();
    println!("squares mod 7: [{}]; their classes {}; the other three {}; lead {}; sqrt(x)/ln x = {:.2}",
        sq.join(", "), res, non, non - res, xf.sqrt() / lx);
    let phi = |q: usize| (1..=q).filter(|&a| gcd(a, q) == 1).count();
    let mut worst = std::collections::HashMap::new();
    let qs: Vec<usize> = (3..14).chain([101, 1009, 9973]).collect();
    for &q in &qs {
        let c = classes(&primes, q);
        let k: Vec<usize> = (0..q).filter(|&a| gcd(a, q) == 1).map(|a| c[a]).collect();
        let m = k.iter().sum::<usize>() as f64 / k.len() as f64;
        let w = k.iter().map(|&v| (v as f64 / m - 1.0).abs()).fold(0.0, f64::max);
        worst.insert(q, w);
        println!("q = {}: phi {}; mean per class {:.2}; smallest {}; largest {}; worst miss {:.2} percent",
            q, phi(q), m, k.iter().min().unwrap(), k.iter().max().unwrap(), 100.0 * w);
    }
    let k9 = classes(&primes, 9973)[1..].to_vec(); // q = 9973: the scatter of small counts
    let m9 = k9.iter().sum::<usize>() as f64 / k9.len() as f64;
    let sd9 = (k9.iter().map(|&v| (v as f64 - m9).powi(2)).sum::<f64>() / k9.len() as f64).sqrt();
    println!("q = 9973: mean {:.2}; standard deviation {:.2}, {:.0} percent of the mean; (ln x)^4 = {:.0}, so q = 9973 is inside the range for A = 4",
        m9, sd9, 100.0 * sd9 / m9, lx.powi(4));
    let grid: Vec<(f64, f64)> = (0..51).map(|k| { let s = 0.5 + k as f64 / 100.0; (lchi(s, &chi), s) }).collect();
    let parts: Vec<String> = grid.iter().step_by(10).map(|(v, s)| format!("sigma {:.1} {:.6}", s, v)).collect();
    println!("L(sigma, chi) mod 7: {}", parts.join("; "));
    let gmin = grid.iter().cloned().fold((f64::INFINITY, 0.0), |a, b| if b.0 < a.0 { b } else { a });
    println!("smallest on 51 points from 0.5 to 1: {:.6} at sigma {:.2}", gmin.0, gmin.1);
    let sum_ac: i64 = (1..Q).map(|a| a as i64 * chi[a]).sum();
    let closed = -std::f64::consts::PI / (Q as f64).powf(1.5) * sum_ac as f64;
    let mut direct = 0.0; for n in 1..=700_000usize { direct += chi[n % Q] as f64 / n as f64; }
    let l1 = lchi(1.0, &chi);
    println!("L(1, chi): Euler-Maclaurin {:.6}; closed form pi/sqrt(7) {:.6}; partial sum to 700000 {:.6}", l1, closed, direct);
    let cost: Vec<String> = [0.99, 0.9, 0.75, 0.6].iter().map(|&b: &f64| { let v = li_series(xf.powf(b)) / 6.0;
        format!("beta {} {:.0}, {:.0}", b, v, -6.0 * v) }).collect();
    println!("a real zero at beta: primes moved per class li(x^beta)/6, squares minus the rest: {}", cost.join("; "));
    for e in [6.0f64, 12.0, 100.0] {
        let l = e * 10f64.ln(); let qq = l * l;
        println!("x = 10^{}: ln x {:.2}; q up to (ln x)^2 = {:.2}; exponent ln x / q^(1/4) there {:.2} = sqrt(ln x) {:.2}; at q = x^0.1 {:.4}",
            e, l, qq, l / qq.powf(0.25), l.sqrt(), l / 10f64.powf(e * 0.1 / 4.0));
    }
    let np = primes.len() as f64;
    println!("breaks: class 0 holds {}; divide by 7 not 6: {:.2} ({:.1} percent low); x/ln x over 6: {:.2} ({:.1} percent low)",
        c7[0], np / 7.0, 100.0 * (1.0 - np / 7.0 / mean), xf / lx / 6.0, 100.0 * (1.0 - xf / lx / 6.0 / mean));
    assert!(primes.len() == 78498 && td.len() == 78498 && c7 == t7); // two roads to every class count
    assert!((li_a - li_b).abs() < 1e-4 && (li_a - 78627.55).abs() < 0.006 && (li_off - 78626.50).abs() < 0.006); // house table
    assert!(((mx - mn) as f64) / mean < 0.004 && c7[0] == 1); // six classes agree; 7 alone in class 0
    assert!((l1 - closed).abs() < 1e-9 && (direct - closed).abs() < 1e-5); // L(1, chi) three ways
    assert!(gmin.0 > 0.5); // no real zero on the grid
    let small_w = (3..14).map(|q| worst[&q]).fold(0.0, f64::max);
    assert!(small_w < 0.005 && 0.005 < worst[&101] && worst[&101] < worst[&1009] && worst[&1009] < worst[&9973]);
    println!("ALL CHECKS PASS");
}
