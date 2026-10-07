// Pell's equation x^2 - 2y^2 = 1 -- the same check as the Python, in Rust.  No
// crates.  Road one multiplies by 3 + 2 root 2 and reads the whole numbers off.
// Road two searches every bottom number up to 10,000 and asks whether
// 1 + 2y^2 is a perfect square.  The two roads must hand back the same pairs.
const LIMIT: i128 = 10000;

fn isqrt(n: i128) -> i128 {                     // whole-number square root, floor
    let mut k = n;
    while k * k > n {
        k = (k + n / k) / 2;
    }
    k
}

fn norm(p: (i128, i128)) -> i128 {              // x + y root 2 times its conjugate
    p.0 * p.0 - 2 * p.1 * p.1
}

fn forward(x: i128, y: i128) -> (i128, i128) {  // multiply by 3 + 2 root 2
    (3 * x + 4 * y, 2 * x + 3 * y)
}

fn backward(x: i128, y: i128) -> (i128, i128) { // multiply by 3 - 2 root 2
    (3 * x - 4 * y, 3 * y - 2 * x)
}

fn places_right(x: i128, y: i128) -> u32 {      // decimals of x/y that match root 2
    let mut k: u32 = 0;
    while x * 10i128.pow(k + 1) / y == isqrt(2 * 10i128.pow(2 * k + 2)) {
        k += 1;
    }
    k
}

fn is_square(n: i128) -> bool {
    isqrt(n) * isqrt(n) == n
}

fn main() {
    let mut chain: Vec<(i128, i128)> = Vec::new();
    let (mut x, mut y) = forward(1, 0);                 // road one: from 1 + 0 root 2
    while y <= LIMIT {
        chain.push((x, y));
        let step = forward(x, y);
        x = step.0;
        y = step.1;
    }
    let found: Vec<(i128, i128)> = (1..=LIMIT)          // road two: search
        .filter(|t| is_square(1 + 2 * t * t))
        .map(|t| (isqrt(1 + 2 * t * t), t))
        .collect();
    let root2 = 2f64.sqrt();
    let over: Vec<f64> = chain.iter().map(|&(x, y)| x as f64 / y as f64 - root2).collect();
    let places: Vec<u32> = chain.iter().map(|&(x, y)| places_right(x, y)).collect();

    println!("root 2 to seven places: {:.7}", root2);
    for (i, &(x, y)) in chain.iter().enumerate() {
        println!("step {}: ({:>4}, {:>4})  {:>8} - {:>8} = {}   {:>4}/{:<4} = {:.7}   over by {:.10}   places right {}",
                 i + 1, x, y, x * x, 2 * y * y, norm((x, y)),
                 x, y, x as f64 / y as f64, over[i], places[i]);
    }
    println!("search to y = {}: {} pairs, the same list in the same order", LIMIT, found.len());
    let (b1, b2) = (backward(17, 12), backward(3, 2));
    println!("backward step from (17, 12): ({}, {}), from (3, 2): ({}, {})", b1.0, b1.1, b2.0, b2.1);
    println!("overshoot bound at (99, 70): {:.10}, actual {:.10}",
             1.0 / (2.0 * root2 * 70.0 * 70.0), over[2]);
    println!("A4 paper, 297 over 210, reduces to {}/{}: step 3 exactly", 297 / 3, 210 / 3);
    let wrong = [norm((chain[1].0, 2 * chain[1].0 + 3 * chain[0].1)), norm((141, 100)), norm((7, 5))];
    println!("mistakes: 17^2 - 2 x 40^2 = {}, 141^2 - 2 x 100^2 = {}, 7^2 - 2 x 5^2 = {}, none of them 1",
             wrong[0], wrong[1], wrong[2]);
    let square: Vec<i128> = (1..=LIMIT).filter(|t| is_square(1 + 4 * t * t)).collect();
    println!("x^2 - 4y^2 = 1, bottom numbers 1 to {}: {} solutions", LIMIT, square.len());
    assert_eq!(chain, found);
    let backs: Vec<(i128, i128)> = chain[1..].iter().map(|&(x, y)| backward(x, y)).collect();
    assert!(backs.as_slice() == &chain[..chain.len() - 1] && backward(3, 2) == (1, 0));
    assert!(chain.iter().zip(over.iter())
        .all(|(&(_x, y), &o)| o > 0.0 && o < 1.0 / (2.0 * root2 * y as f64 * y as f64)));
    assert!(places == vec![0, 2, 4, 5, 6] && wrong == [-2911, -119, -1] && square.is_empty());
    println!("ALL CHECKS PASS");
}
