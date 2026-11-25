-- Small doubling: if a finite set of integers has doubling constant K = |A + A| / |A|, then k copies added minus l copies subtracted have at most K^(k+l) |A| members (Plunnecke-Ruzsa), with Ruzsa's triangle inequality and Petridis's lemma on the way.
import Mathlib.Combinatorics.Additive.PluenneckeRuzsa
import Mathlib.Tactic.NormNum

open scoped Pointwise

/-- **Plunnecke-Ruzsa bound.** For every finite set `A` of integers and all `k, l ≥ 0` with
`k + l ≥ 1`, the set `kA - lA` (k copies of `A` added, then l copies subtracted) has at most
`K ^ (k + l) * |A|` members, where `K = |A + A| / |A|` is the doubling constant. -/
theorem plunnecke_ruzsa_bound (A : Finset ℤ) (k l : ℕ) (hkl : 1 ≤ k + l) :
    ((k • A - l • A).card : ℚ) ≤ (((A + A).card : ℚ) / A.card) ^ (k + l) * A.card := by
  obtain rfl | hA := A.eq_empty_or_nonempty
  · rcases Nat.eq_zero_or_pos k with rfl | hk
    · obtain ⟨l, rfl⟩ : ∃ m, l = m + 1 := ⟨l - 1, by omega⟩
      simp [succ_nsmul]
    · obtain ⟨k, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
      simp [succ_nsmul]
  have h := Finset.pluennecke_ruzsa_inequality_nsmul_sub_nsmul_add hA A k l
  have h' : ((k • A - l • A).card : ℚ) ≤
      (((((A + A).card : ℚ≥0) / A.card) ^ (k + l) * A.card : ℚ≥0) : ℚ) := by
    exact_mod_cast h
  simpa using h'

/-- **Ruzsa's triangle inequality.** For any finite sets `X`, `Y`, `Z` of integers,
`|X| |Y - Z| ≤ |X - Y| |X - Z|`, and the same holds with sums on the right:
`|X| |Y - Z| ≤ |X + Y| |X + Z|`. -/
theorem ruzsa_triangle_inequality (X Y Z : Finset ℤ) :
    X.card * (Y - Z).card ≤ (X - Y).card * (X - Z).card ∧
      X.card * (Y - Z).card ≤ (X + Y).card * (X + Z).card := by
  constructor
  · have h := Finset.ruzsa_triangle_inequality_sub_sub_sub Y X Z
    rw [← Finset.card_neg (Y - X), neg_sub, ← Finset.card_neg (Z - X), neg_sub] at h
    rw [Nat.mul_comm]; exact h
  · have h := Finset.ruzsa_triangle_inequality_sub_add_add Y X Z
    rw [add_comm Y X, add_comm Z X, Nat.mul_comm] at h
    exact h

/-- **Petridis's lemma.** Let `A` and `B` be finite sets of integers and `X` a nonempty subset
of `A` whose ratio `K' = |X + B| / |X|` is the least among all nonempty subsets of `A`. Then for
every finite set `C` of integers, `|X + B + C| ≤ K' |X + C|`. -/
theorem petridis_lemma (A B X : Finset ℤ) (hXA : X ⊆ A) (hX : X.Nonempty)
    (hbest : ∀ W ⊆ A, W.Nonempty →
      ((X + B).card : ℚ) / X.card ≤ ((W + B).card : ℚ) / W.card)
    (C : Finset ℤ) :
    ((X + B + C).card : ℚ) ≤ ((X + B).card : ℚ) / X.card * (X + C).card := by
  have hX0 : (0 : ℚ) < X.card := by exact_mod_cast hX.card_pos
  have hcond : ∀ A' ⊆ X, (X + B).card * A'.card ≤ (A' + B).card * X.card := by
    intro A' hA'
    obtain rfl | hne := A'.eq_empty_or_nonempty
    · simp
    have hpos : (0 : ℚ) < A'.card := by exact_mod_cast hne.card_pos
    have := hbest A' (hA'.trans hXA) hne
    rw [div_le_div_iff₀ hX0 hpos] at this
    exact_mod_cast this
  have h := Finset.pluennecke_petridis_inequality_add C hcond
  have e1 : C + X + B = X + B + C := by
    rw [add_comm C X, add_assoc, add_comm C B, ← add_assoc]
  have e2 : C + X = X + C := add_comm _ _
  rw [e1, e2] at h
  have h' : ((X + B + C).card : ℚ) * X.card ≤ (X + B).card * (X + C).card := by
    exact_mod_cast h
  rw [div_mul_eq_mul_div, le_div_iff₀ hX0]
  exact h'

/-- The card's set: 0 to 4 together with 100 to 104. -/
def twoClumps : Finset ℤ := {0, 1, 2, 3, 4, 100, 101, 102, 103, 104}

-- |A| = 10, |A + A| = 27, |A - A| = 27, so K = 27 / 10 = 2.7.
example : twoClumps.card = 10 := by decide +kernel
example : (twoClumps + twoClumps).card = 27 := by decide +kernel
example : (twoClumps - twoClumps).card = 27 := by decide +kernel
-- |3A| = 52 and |2A - 2A| = |4A| = 85.
example : ((3 : ℕ) • twoClumps).card = 52 := by decide +kernel
example : ((2 : ℕ) • twoClumps - (2 : ℕ) • twoClumps).card = 85 := by decide +kernel
example : ((4 : ℕ) • twoClumps).card = 85 := by decide +kernel
-- The ceilings: 52 ≤ 2.7^3 × 10 = 196.83 and 85 ≤ 2.7^4 × 10 = 531.441.
example : (52 : ℚ) ≤ (27 / 10) ^ 3 * 10 ∧ (27 / 10 : ℚ) ^ 3 * 10 = 19683 / 100 := by norm_num
example : (85 : ℚ) ≤ (27 / 10) ^ 4 * 10 ∧ (27 / 10 : ℚ) ^ 4 * 10 = 531441 / 1000 := by norm_num
-- Triangle step with X = A, Y = Z = 2A: 10 × 85 = 850 ≤ |A + 2A|^2 = 52^2 = 2704.
example : (twoClumps + (2 : ℕ) • twoClumps).card = 52 := by decide +kernel
example : twoClumps.card * ((2 : ℕ) • twoClumps - (2 : ℕ) • twoClumps).card = 850 ∧
    850 ≤ 52 * 52 := by decide +kernel
-- Petridis: among all nonempty subsets of A, none has |W + A| / |W| below 27 / 10.
example : ∀ W ∈ twoClumps.powerset, W.Nonempty → 27 * W.card ≤ 10 * (W + twoClumps).card := by
  decide +kernel
-- Freiman's grid: {a + 100 b : 0 ≤ a ≤ 4, 0 ≤ b ≤ 1} has 5 × 2 = 10 members and equals A.
example : (Finset.range 5 ×ˢ Finset.range 2).image (fun p => (p.1 : ℤ) + 100 * p.2) = twoClumps := by
  decide +kernel
-- What breaks: with S = {0, 2, 5, 7, 17}, B = {0, 2}, C = {0, 5} and X = S, |S + B + C| = 13
-- while (|S + B| / |S|) |S + C| = (8 / 5) × 8 = 12.8; the best subset {0, 2} gives 6 ≤ 6.
example : (({0, 2, 5, 7, 17} : Finset ℤ) + {0, 2} + {0, 5}).card = 13 ∧
    (({0, 2, 5, 7, 17} : Finset ℤ) + {0, 2}).card = 8 ∧
    (({0, 2, 5, 7, 17} : Finset ℤ) + {0, 5}).card = 8 ∧ 13 * 5 > 8 * 8 := by decide +kernel
example : (({0, 2} : Finset ℤ) + {0, 2} + {0, 5}).card = 6 ∧
    (({0, 2} : Finset ℤ) + {0, 2}).card = 3 ∧ (({0, 2} : Finset ℤ) + {0, 5}).card = 4 ∧
    6 * 2 ≤ 3 * 4 := by decide +kernel
-- Mistakes: 2A is not "every member doubled" (10 members, not 27), and for T = {0, 1, 3},
-- |T + T| = 6 but |T - T| = 7.
example : (twoClumps.image (fun a => 2 * a)).card = 10 := by decide +kernel
example : (({0, 1, 3} : Finset ℤ) + {0, 1, 3}).card = 6 ∧
    (({0, 1, 3} : Finset ℤ) - {0, 1, 3}).card = 7 := by decide +kernel

#print axioms plunnecke_ruzsa_bound
#print axioms ruzsa_triangle_inequality
#print axioms petridis_lemma
