// Vector spaces and subspaces -- the same check as vector_spaces_and_subspaces_check.py,
// in Rust.  Standard library only, no crates.  A recipe is three numbers: grams of
// flour, grams of sugar, grams of butter.  Adding two recipes adds slot by slot;
// scaling multiplies every slot.  Road one walks the eight rules and the three
// subspace tests on named recipes.  Road two reaches the same two verdicts another
// way: one slot of a mix a u + b v is a times that slot of u plus b times that slot
// of v, so a set pinned at "this slot equals c" closes up when c is 0 and comes
// apart when it is not.
// Compile: rustc --edition 2021 -O vector_spaces_and_subspaces_check.rs -o vs_check
type R = [i64; 3];

fn add(u: R, v: R) -> R { [u[0] + v[0], u[1] + v[1], u[2] + v[2]] }
fn scale(a: i64, u: R) -> R { [a * u[0], a * u[1], a * u[2]] }
fn show(u: R) -> String { format!("({}, {}, {})", u[0], u[1], u[2]) }
fn line(name: &str, text: String) { println!("{:<22}{}", name, text); }

fn main() {
    let (short, sponge, oat, zero): (R, R, R, R) =
        ([300, 100, 200], [200, 200, 100], [150, 50, 100], [0, 0, 0]);
    let (a, b) = (2i64, -3i64);
    let (f1, f2): (R, R) = ([300, 0, 200], [100, 0, 50]);      // sugar-free: the sugar slot is 0
    let (g1, g2): (R, R) = ([200, 100, 50], [200, 50, 150]);   // exactly 200 g of flour

    println!("recipes are (flour, sugar, butter) in grams");
    line("shortbread", show(short));
    line("sponge", show(sponge));
    line("oat biscuit", show(oat));
    line("shortbread + sponge", show(add(short, sponge)));
    line("2 x shortbread", show(scale(2, short)));
    line("(2 + -3) x shortbread", show(scale(a + b, short)));

    let rules = [
        add(short, sponge) == add(sponge, short),                                // order
        add(add(short, sponge), oat) == add(short, add(sponge, oat)),            // grouping
        add(short, zero) == short,                                               // a zero
        add(short, scale(-1, short)) == zero,                                    // an opposite
        scale(a, add(short, sponge)) == add(scale(a, short), scale(a, sponge)),  // spread over recipes
        scale(a + b, short) == add(scale(a, short), scale(b, short)),            // spread over numbers
        scale(a, scale(b, short)) == scale(a * b, short),                        // scale twice, or once
        scale(1, short) == short,                                                // scaling by 1
    ];
    let all_hold = rules.iter().all(|&r| r);
    println!("all eight rules on these three, a = {}, b = {}: {}", a, b,
             if all_hold { "OK" } else { "FAILED" });

    line("sugar-free, added", format!("{}   sugar {}", show(add(f1, f2)), add(f1, f2)[1]));
    line("sugar-free, tripled", format!("{}   sugar {}", show(scale(3, f1)), scale(3, f1)[1]));
    line("sugar-free, zero", format!("{}   sugar {}", show(zero), zero[1]));
    line("200 g flour, added", format!("{}   flour {}", show(add(g1, g2)), add(g1, g2)[0]));
    line("200 g flour, tripled", format!("{}   flour {}", show(scale(3, g1)), scale(3, g1)[0]));
    line("200 g flour, zero", format!("{}   flour {}", show(zero), zero[0]));
    line("grams kept positive", format!("the opposite of shortbread is {}", show(scale(-1, short))));

    let sugar_mix = add(scale(a, f1), scale(b, f2))[1];        // road two: one slot of a mix
    let flour_mix = add(scale(a, g1), scale(b, g2))[0];
    println!("second road: the slot of the mix {} u + {} v, worked from the two slots alone", a, b);
    line("sugar of the mix", format!("{} = {} x {} + {} x {}   still sugar-free",
                                     sugar_mix, a, f1[1], b, f2[1]));
    line("flour of the mix", format!("{} = {} x {} + {} x {}   not 200",
                                     flour_mix, a, g1[0], b, g2[0]));

    assert!(add(short, sponge) == [500, 300, 300] && scale(2, short) == [600, 200, 400]);
    assert!(all_hold && scale(a + b, short) == [-300, -100, -200]);
    assert!(add(f1, f2)[1] == 0 && scale(3, f1)[1] == 0 && sugar_mix == 0);
    assert!(add(g1, g2)[0] == 400 && scale(3, g1)[0] == 600 && flour_mix == -200 && zero[0] != 200);
    println!("ALL CHECKS PASS");
}
