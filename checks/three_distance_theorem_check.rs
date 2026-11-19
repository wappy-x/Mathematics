// Three distances -- the same check as the Python, in Rust.  No crates.  A
// sequencer adds one hit per bar, alpha = 0.618... of a loop further on each
// time (a step of the golden ratio, 1.618 loops, lands in the same place).  The
// gaps between hits are found by three roads: road 1 sorts the hits and
// measures every gap; road 2 is the neighbour rule, built from the two closest
// returns a and b; road 3 reads the gaps off the Fibonacci numbers, the golden
// ratio's convergent denominators.
const LOOP: f64 = 2000.0; // one 4/4 bar at 120 bpm, in ms

fn frac(x: f64) -> f64 { x - x.floor() } // {x}: the part after the point

fn gaps(pts: &[f64]) -> Vec<f64> { // road 1: sort, measure round the loop
    let mut s = pts.to_vec();
    s.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let mut g: Vec<f64> = (0..s.len() - 1).map(|i| s[i + 1] - s[i]).collect();
    g.push(1.0 - s[s.len() - 1] + s[0]);
    g
}

fn tally(gs: &[f64]) -> Vec<(f64, i64)> { // distinct lengths with their counts
    let mut s = gs.to_vec();
    s.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let mut out: Vec<(f64, i64)> = Vec::new();
    for g in s {
        match out.last_mut() {
            Some(last) if g - last.0 < 1e-9 => last.1 += 1,
            _ => out.push((g, 1)),
        }
    }
    out
}

fn sorted_pos(mut t: Vec<(f64, i64)>) -> Vec<(f64, i64)> {
    t.sort_by(|x, y| x.partial_cmp(y).unwrap());
    t.into_iter().filter(|x| x.1 > 0).collect()
}

fn rule(al: f64, n: i64) -> (i64, i64, f64, f64, Vec<(f64, i64)>) { // road 2
    let a = (1..n).min_by(|&x, &y| frac(x as f64 * al).partial_cmp(&frac(y as f64 * al)).unwrap()).unwrap();
    let b = (1..n).max_by(|&x, &y| frac(x as f64 * al).partial_cmp(&frac(y as f64 * al)).unwrap()).unwrap();
    let (u, v) = (frac(a as f64 * al), 1.0 - frac(b as f64 * al));
    (a, b, u, v, sorted_pos(vec![(u, n - a), (v, n - b), (u + v, a + b - n)]))
}

fn fib_rule(n: i64, phi: f64) -> Vec<(f64, i64)> { // road 3: F_k < n <= F_(k+1)
    let mut f: Vec<i64> = vec![0, 1];
    while *f.last().unwrap() < n { let l = f.len(); f.push(f[l - 1] + f[l - 2]) }
    let k = f.len() - 2;
    let kf = k as f64;
    sorted_pos(vec![(phi.powf(-kf), n - f[k]), (phi.powf(1.0 - kf), n - f[k - 1]), (phi.powf(2.0 - kf), f[k + 1] - n)])
}

fn same(t1: &[(f64, i64)], t2: &[(f64, i64)]) -> bool {
    t1.len() == t2.len() && t1.iter().zip(t2).all(|(x, y)| x.1 == y.1 && (x.0 - y.0).abs() < 1e-9)
}

fn ms(t: &[(f64, i64)]) -> String {
    t.iter().map(|(g, c)| format!("{:.3} ms x {}", g * LOOP, c)).collect::<Vec<_>>().join(", ")
}

fn cfrac(mut x: f64, terms: usize) -> Vec<i64> { // whole part, then flip
    let mut out = Vec::new();
    for _ in 0..terms { out.push(x.floor() as i64); x = 1.0 / (x - x.floor()); }
    out
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn hits(al: f64, n: i64) -> Vec<f64> { (0..n).map(|k| frac(k as f64 * al)).collect() }

fn main() {
    let phi = (1.0 + 5f64.sqrt()) / 2.0;
    let alpha = phi - 1.0;
    let steps = [("golden", alpha), ("sqrt2-1", 2f64.sqrt() - 1.0),
                 ("e-2", 2.718281828459045 - 2.0), ("pi-3", 3.141592653589793 - 3.0)];
    println!("step alpha = {:.12} of a {:.0} ms loop; continued fraction {:?}", alpha, LOOP, cfrac(alpha, 10));
    let mut fib: Vec<i64> = vec![1, 1];
    while fib.len() < 12 { let l = fib.len(); fib.push(fib[l - 1] + fib[l - 2]) }
    println!(" q   q x alpha  nearest  distance   phi^-k     side of the downbeat");
    for (i, &q) in fib[1..9].iter().enumerate() {
        let qa = q as f64 * alpha;
        let d = qa - qa.round();
        println!("{:2} {:10.6} {:5}  {:9.6} {:9.6}    {}", q, qa, qa.round() as i64, d.abs(),
                 phi.powf(-((i + 2) as f64)), if d > 0.0 { "after" } else { "before" });
    }
    let n = 10i64;
    let pts = hits(alpha, n);
    println!("hit of bar n, ms: {}", pts.iter().map(|p| format!("{:.1}", p * LOOP)).collect::<Vec<_>>().join(" "));
    println!("gaps round the loop from the downbeat, ms: {}",
             gaps(&pts).iter().map(|g| format!("{:.1}", g * LOOP)).collect::<Vec<_>>().join(" "));
    let brute = tally(&gaps(&pts));
    let (a, b, u, v, pred) = rule(alpha, n);
    let (p, r) = ((a as f64 * alpha).floor() as i64, (b as f64 * alpha).floor() as i64 + 1);
    println!("road 1, sorted gaps: {} lengths: {}", brute.len(), ms(&brute));
    println!("road 2, a = {}, u = {:.3} ms; b = {}, v = {:.3} ms; counts N-a = {}, N-b = {}, a+b-N = {}",
             a, u * LOOP, b, v * LOOP, n - a, n - b, a + b - n);
    println!("road 3, F = 8 < N <= 13: {}", ms(&fib_rule(n, phi)));
    println!("longest = u + v: {:.3} + {:.3} = {:.3} ms", u * LOOP, v * LOOP, (u + v) * LOOP);
    println!("p = {}, r = {}: a*r - b*p = {}; b*u + a*v = {:.12}", p, r, a * r - b * p, b as f64 * u + a as f64 * v);
    println!(" N  lengths   a   b  shortest, ms  longest, ms");
    for m in 2..15 {
        let t = tally(&gaps(&hits(alpha, m)));
        let (a2, b2, _, _, _) = rule(alpha, m);
        println!("{:2}  {:5}  {:3} {:3}  {:11.3}  {:10.3}", m, t.len(), a2, b2, t[0].0 * LOOP, t[t.len() - 1].0 * LOOP);
    }
    let top = 2000i64;
    let (mut ok, mut det, mut fib_ok, mut worst_golden) = (true, true, true, 0.0);
    for &(name, al) in steps.iter() {
        let (mut w, mut three) = (1.0f64, 0);
        for m in 2..=top {
            let t = tally(&gaps(&hits(al, m)));
            let (a2, b2, _, _, pr) = rule(al, m);
            ok = ok && t.len() <= 3 && same(&t, &pr);
            det = det && a2 * ((b2 as f64 * al).floor() as i64 + 1) - b2 * ((a2 as f64 * al).floor() as i64) == 1;
            if name == "golden" { fib_ok = fib_ok && same(&t, &fib_rule(m, phi)); }
            if t.len() == 3 { three += 1; }
            w = w.max(t[t.len() - 1].0 / t[0].0);
        }
        if name == "golden" { worst_golden = w; }
        println!("{:8} N = 2..{}: three lengths at {} N; worst longest/shortest {:.6}", name, top, three, w);
    }
    println!("continued fraction of pi-3: {:?}", cfrac(steps[3].1, 5));
    println!("road 1 = road 2 at every N, never more than 3 lengths: {}; a*r - b*p = 1 always: {}", yn(ok), yn(det));
    println!("road 1 = road 3 for the golden step, N = 2..{}: {}", top, yn(fib_ok));
    let two: Vec<i64> = (2..101).filter(|&m| tally(&gaps(&hits(alpha, m))).len() == 2).collect();
    println!("N up to 100 with only two lengths: {:?}", two);
    let mut q16: Vec<f64> = (0..n).map(|k| frac(k as f64 * 10.0 / 16.0)).collect();
    q16.sort_by(|x, y| x.partial_cmp(y).unwrap());
    q16.dedup();
    let sq = tally(&gaps(&(0..n).map(|k| frac((k * k) as f64 * alpha)).collect::<Vec<f64>>()));
    let (mut s, mut rnd) = (2026u64, Vec::new());
    for _ in 0..n {
        s = s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        rnd.push(((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0);
    }
    let rt = tally(&gaps(&rnd));
    println!("mistake 1, step rounded to 10/16 of the loop: {} places for {} hits", q16.len(), n);
    println!("mistake 2, bar n at n*n*alpha: {} lengths, longest/shortest {:.6}", sq.len(), sq[sq.len() - 1].0 / sq[0].0);
    println!("mistake 3, {} random places (SplitMix64, seed 2026): {} lengths, longest/shortest {:.6}",
             n, rt.len(), rt[rt.len() - 1].0 / rt[0].0);
    let fib_upto: Vec<i64> = fib[2..].iter().copied().filter(|&f| f <= 100).collect();
    assert!(same(&brute, &pred) && same(&brute, &fib_rule(n, phi)) && a == 5 && b == 8);
    assert!(ok && det && fib_ok && (worst_golden - phi * phi).abs() < 1e-6);
    assert!(two == fib_upto);
    assert!(q16.len() == 8 && sq.len() > 3 && rt.len() as i64 == n);
    println!("ALL CHECKS PASS");
}
