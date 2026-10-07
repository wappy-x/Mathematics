// Roots -- the same check as the Python, in Rust.  No crates.  A square bed
// that must cover 50 square metres, and a cube tank that must hold 8,000
// litres.  Each root is found by dividing and averaging, then squared or
// cubed back to see whether it lands on what was asked for.
fn sqroot(a: f64, mut guess: f64) -> [f64; 4] {   // divide and average, four rounds
    let mut out = [0.0f64; 4];
    for i in 0..4 { guess = (guess + a / guess) / 2.0; out[i] = guess; }
    out
}
fn cuberoot(a: f64) -> f64 {     // same idea, weighted: two parts old guess, one part a/(guess x guess)
    let mut x = a;
    for _ in 0..60 { x = (2.0 * x + a / (x * x)) / 3.0; }
    x
}
fn main() {
    let steps = sqroot(50.0, 7.0);
    let (bed, tank) = (steps[2], cuberoot(8.0));
    let litre = 20.0 / 10.0;               // no root: 20 litre cubes to an edge, a tenth of a metre each
    let face = tank * tank;                // 8 to the 2/3: cube root, then multiplied by itself
    let mut head = format!("{:<36}", "squares of sides 4 to 8 metres");
    for s in [4.0f64, 5.0, 6.0, 7.0, 8.0] { head.push_str(&format!("{:>5.0}", s * s)); }
    println!("{}", head);
    for (name, v) in [("guess 7, divide and average", steps[0]), ("round two, closer", steps[1]),
                      ("round three, and it settles", bed), ("that side squared, back to 50", bed * bed),
                      ("the minus twin", -bed), ("the minus twin squared", (-bed) * (-bed)),
                      ("tank side, cube root of 8", tank), ("tank side the litre way, 20 dm", litre),
                      ("one face of the tank, 8 to the 2/3", face)] {
        println!("{:<36}{:>18.12}", name, v);
    }
    println!("mistakes: 25 metres a side covers {}; 8,000 cubic metres gives a side of {:.0}",
             25 * 25, cuberoot(8000.0));
    assert!((bed * bed - 50.0).abs() < 1e-9 && ((-bed) * (-bed) - 50.0).abs() < 1e-9 && steps[3] == bed);
    assert!((tank - litre).abs() < 1e-9 && (tank * tank * tank - 8.0).abs() < 1e-9 && 20 * 20 * 20 == 8000);
    assert!((face - 4.0).abs() < 1e-9 && (steps[0] - 7.071428571428571).abs() < 1e-15);
    println!("ALL CHECKS PASS");
}
