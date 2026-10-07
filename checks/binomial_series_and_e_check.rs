// The binomial series and e -- the check behind the card.  No crates.
// Road one: a series, term by term.  Road two never touches it: Heron's root,
// a dollar compounded a million times, a direct count of clean draws.
const N: usize = 1000000;

fn binom_terms(a: f64, x: f64, count: usize) -> Vec<f64> {
    let (mut terms, mut c, mut p) = (Vec::new(), 1.0, 1.0); // C(a, k) x^k
    for k in 0..count {
        terms.push(c * p);
        c = c * (a - k as f64) / (k as f64 + 1.0); // next coefficient
        p = p * x; // next power
    }
    terms
}

fn heron(s: f64) -> f64 { // road two to a root: average y and s / y
    let mut y = s;
    for _ in 0..60 { y = (y + s / y) / 2.0; }
    y
}

fn exp_sum(x: f64, count: usize) -> f64 { // 1 + x + x^2/2! + ..., count terms
    let (mut total, mut term) = (0.0, 1.0);
    for k in 0..count { total += term; term = term * x / (k as f64 + 1.0); }
    total
}

fn ladder(step: f64, times: usize) -> f64 { // (1 + step) multiplied in
    let mut y = 1.0;
    for _ in 0..times { y = y * (1.0 + step); }
    y
}

fn clean(n: usize, pos: usize, used: u32) -> u64 { // nobody on their own name
    if pos == n { return 1; }
    (0..n).filter(|&j| j != pos && used >> j & 1 == 0).map(|j| clean(n, pos + 1, used | 1 << j)).sum()
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let t = binom_terms(0.5, 0.1, 6);
    let sums: Vec<f64> = (0..6).map(|k| t[..k + 1].iter().sum()).collect();
    let (root, root2) = (binom_terms(0.5, 0.1, 20).iter().sum::<f64>(), heron(1.1));
    println!("C(1/2, k), k = 0..5: {}", join(&binom_terms(0.5, 1.0, 6), 8));
    println!("terms, k = 0..5: {}", join(&t, 10));
    println!("partial sums:    {}", join(&sums, 10));
    println!("root of 1.1: 20 terms {:.12}, Heron {:.12}", root, root2);
    println!("error after 4 terms {:.10}, first term left out {:.10}", sums[3] - root2, -t[4]);
    let far: Vec<f64> = [5, 10, 20].iter().map(|&m| binom_terms(0.5, 3.0, m).iter().sum()).collect();
    println!("root of 4, x = 3, by 5, 10, 20 terms: {}", join(&far, 2));
    println!("no k! in the coefficients, 4 terms: {:.6}", t.iter().zip([1.0, 1.0, 2.0, 6.0]).map(|(v, f)| v * f).sum::<f64>());
    let (e, e2) = (exp_sum(1.0, 20), ladder(1.0 / N as f64, N));
    let (inv, inv2) = (exp_sum(-1.0, 20), ladder(-1.0 / N as f64, N));
    println!("e: series {:.12}, compounded {} times {:.12}", e, N, e2);
    println!("1/e: series {:.12}, (1 - 1/{})^{} {:.12}", inv, N, N, inv2);
    println!("series at 1 times series at -1: {:.12}", e * inv);
    let s1: Vec<f64> = (1..9).map(|n| exp_sum(1.0, n + 1)).collect();
    let s2: Vec<f64> = (1..9).map(|n| ladder(1.0 / n as f64, n)).collect();
    println!("chart, series to 1/n!, n = 1..8: {}", join(&s1, 2));
    println!("chart, (1 + 1/n)^n, n = 1..8:    {}", join(&s2, 2));
    println!("n  counted       n!/e  share     gap to 1/e  bound 1/(n+1)!");
    let mut fact = 1.0;
    for n in 1..10 {
        fact *= n as f64;
        let d = clean(n, 0, 0);
        let share = d as f64 / fact;
        let bound = 1.0 / (fact * (n as f64 + 1.0));
        if (4..=8).contains(&n) {
            println!("{}  {:7}  {:10.3}  {:.6}  {:+.6}   {:.6}", n, d, fact * inv, share, share - inv, bound);
        }
        assert!((share - inv).abs() < bound); // counted share within the tail bound
    }
    println!("signs dropped, six people: 720 x {:.6} = {:.0}", exp_sum(1.0, 7), 720.0 * exp_sum(1.0, 7));
    assert!((root - root2).abs() < 1e-14); // binomial series against Heron
    assert!((e - e2).abs() < 2e-6); // series against compounding
    assert!((inv - inv2).abs() < 1e-6); // alternating series against discounting
}
