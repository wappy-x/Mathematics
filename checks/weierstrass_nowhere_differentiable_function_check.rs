// Weierstrass's monster -- the same check as the Python, in Rust.  No crates.
// f(x) = sum over n >= 0 of (3/4)^n phi(4^n x), phi = distance to the nearest
// integer.  Every quotient is reached two ways, and the slope bound is tested.

fn phi(t: f64) -> f64 { (t - t.round()).abs() } // distance to the nearest integer

fn f(x: f64, layers: i32, a: f64) -> f64 { // the first `layers` sawtooth layers
    (0..layers).map(|n| a.powi(n) * phi(4f64.powi(n) * x)).sum()
}

fn tail(n: i32) -> f64 { 2.0 * 0.75f64.powi(n) } // caps 0.5 (3/4)^n left after N layers

fn quotients(layers: i32, a: f64) -> Vec<f64> { // x = 0, step h = 4^-m, m = 1..8
    (1..9).map(|m| { let h = 4f64.powi(-m); (f(h, layers, a) - f(0.0, layers, a)) / h }).collect()
}

fn main() {
    for n in [1, 3, 12] {
        let r: Vec<String> = (0..21).map(|i| format!("{:.2}", f(i as f64 / 20.0, n, 0.75) + 1e-12)).collect();
        println!("chart {} layers: {}", n, r.join(" "));
    }
    let n = (0..100).find(|&k| tail(k) < 0.001).unwrap();
    println!("M-test: caps add to {:.6}; first N with leftover below 0.001: N={}, leftover {:.6}", tail(0), n, tail(n));
    let (mut third, mut p4) = (0.0, 1i64); // p4 = 4^k mod 3
    for k in 0..n { third += 0.75f64.powi(k) * (p4.min(3 - p4) as f64) / 3.0; p4 = p4 * 4 % 3; }
    let gap = 4.0 / 3.0 - third; // closed form: phi(4^n / 3) = 1/3 always
    assert!(gap > 0.0 && gap <= tail(n));
    println!("f(1/3): closed form {:.6}, {} layers {:.6}, gap {:.6}", 4.0 / 3.0, n, third, gap);
    let by_layers: Vec<i64> = quotients(60, 0.75).iter().map(|&q| q as i64).collect();
    let closed: Vec<i64> = (1..9u32).map(|m| (3i64.pow(m) - 1) / 2).collect();
    assert!(quotients(60, 0.75).iter().zip(&closed).all(|(&q, &c)| q == c as f64)); // exact
    println!("x=0, h=4^-m, m=1..8, by layers: {:?}", by_layers);
    println!("x=0, the formula (3^m - 1)/2:   {:?}", closed);
    let shares: Vec<i64> = (0..6).map(|k| (0.75f64.powi(k) * phi(4f64.powi(k) / 64.0) * 64.0) as i64).collect(); // exact
    println!("h=1/64, layer shares in 64ths: {:?} total {}", shares, shares.iter().sum::<i64>());
    let cut: Vec<i64> = quotients(5, 0.75).iter().map(|&q| q as i64).collect();
    println!("only 5 layers: {:?}", cut);
    let slow: Vec<String> = quotients(60, 0.125).iter().map(|q| format!("{:.4}", q)).collect();
    println!("heights (1/8)^n, x=0, step to the right: {}", slow.join(" "));
    for (s, c, side) in [(1.0, 5.0 / 3.0, "right"), (-1.0, 1.0, "left")] { // x = 1/3: by hand, 2 - c / 2^(m-1)
        let q: Vec<f64> = (1..9).map(|m| { let h = s * 4f64.powi(-m); (f(1.0 / 3.0 + h, 60, 0.125) - f(1.0 / 3.0, 60, 0.125)) / h }).collect();
        assert!(q.iter().zip(1..).all(|(&v, m)| (v - (2.0 - c / 2f64.powi(m - 1))).abs() < 1e-9));
        let r: Vec<String> = q.iter().map(|v| format!("{:.4}", v)).collect();
        println!("heights (1/8)^n, x=1/3, step to the {}: {}", side, r.join(" "));
    }
    let (mut signs, mut exact, mut roads, mut bound) = (vec![], vec![], vec![], vec![]);
    for m in 1..9u32 { // x = 3/10, exact, in units of 1/Q
        let (q, p) = (10 * 4i128.pow(m + 1), 3 * 4i128.pow(m + 1));
        let t = p * 4i128.pow(m) % q % (q / 2); // where 4^m x sits on its straight piece
        let s: i128 = if 4 * t <= q { 1 } else { -1 }; // step right or left by 4^-(m+1)
        let d = |p: i128, k: u32| { let r = (p % q) * (4i128.pow(k) % q) % q; r.min(q - r) };
        let dd: Vec<i128> = (0..m + 25).map(|k| d(p + 10 * s, k) - d(p, k)).collect();
        assert!(dd[(m + 1) as usize..].iter().all(|&v| v == 0)); // deeper layers move by a whole number
        let num = s * (0..=m).map(|k| 3i128.pow(k) * 4i128.pow(m + 1 - k) * dd[k as usize]).sum::<i128>();
        assert!(num % q == 0);
        let road: i128 = (0..=m).map(|k| { // road two: the slope of phi at each layer
            let r = 3 * 4i128.pow(k) % 10; // 4^n x = (3 * 4^n)/10, its tenths digit
            let up = if s > 0 { r < 5 } else { 0 < r && r <= 5 };
            3i128.pow(k) * if up { 1 } else { -1 }
        }).sum();
        signs.push(s as i64); exact.push((num / q) as i64); roads.push(road as i64);
        let h = s as f64 * 4f64.powi(-(m as i32 + 1)); // road three: the float sum itself
        let fl = (f(0.3 + h, m as i32 + 2, 0.75) - f(0.3, m as i32 + 2, 0.75)) / h;
        assert!((fl - (num / q) as f64).abs() < 1e-6);
        bound.push((3i64.pow(m) + 1) / 2);
        assert!(exact[exact.len() - 1].abs() >= bound[bound.len() - 1]);
    }
    assert_eq!(exact, roads);
    println!("x=0.3, step sign by m: {:?}", signs);
    println!("x=0.3, quotient by exact layers: {:?}", exact);
    println!("x=0.3, quotient by slope signs:  {:?}", roads);
    println!("x=0.3, proof's floor (3^m + 1)/2: {:?}", bound);
    println!("ALL CHECKS PASS");
}
