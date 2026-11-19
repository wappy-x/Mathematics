-- The curve mod p: at an odd prime p the curve y^2 = x^3 + ax + b has exactly p + 1 plus the sum of the Legendre symbols of x^3 + ax + b points, O included; mod a prime with p = 2 mod 3 the curve y^2 = x^3 - 2 has exactly p + 1; and a prime breaks the curve exactly when it divides the discriminant.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Basic
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Data.ZMod.Basic

open WeierstrassCurve

/-- The short Weierstrass curve `y^2 = x^3 + a x + b`, as a Mathlib `WeierstrassCurve`
with `a₁ = a₂ = a₃ = 0`, `a₄ = a` and `a₆ = b`. -/
abbrev shortWeierstrass {K : Type*} [CommRing K] (a b : K) : WeierstrassCurve K :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := a, a₆ := b }

/-- `#E(𝔽_p)`: the number of pairs `(x, y)` mod `p` with `y^2 = x^3 + a x + b`, plus one for the
point at infinity `O`. The whole-number coefficients `a` and `b` are read mod `p`. -/
def pointCount (p : ℕ) [NeZero p] (a b : ℤ) : ℕ :=
  (Finset.univ.filter fun xy : ZMod p × ZMod p =>
    xy.2 ^ 2 = xy.1 ^ 3 + (a : ZMod p) * xy.1 + (b : ZMod p)).card + 1

theorem sum_range_eq_sum_zmod (p : ℕ) [NeZero p] {M : Type*} [AddCommMonoid M]
    (f : ZMod p → M) : ∑ n ∈ Finset.range p, f (n : ZMod p) = ∑ x : ZMod p, f x := by
  refine Finset.sum_nbij' (fun n => (n : ZMod p)) ZMod.val ?_ ?_ ?_ ?_ ?_
  · intro n _; simp
  · intro x _; simpa using ZMod.val_lt x
  · intro n hn; simpa using ZMod.val_cast_of_lt (Finset.mem_range.mp hn)
  · intro x _; simp
  · intro n _; rfl

#print axioms sum_range_eq_sum_zmod

theorem natCast_ne_zero_of_lt_prime (p : ℕ) [Fact p.Prime] {n : ℕ} (hn0 : 0 < n) (hnp : n < p) :
    (n : ZMod p) ≠ 0 := by
  intro h
  rw [ZMod.natCast_eq_zero_iff] at h
  exact absurd (Nat.le_of_dvd hn0 h) (by omega)

#print axioms natCast_ne_zero_of_lt_prime

theorem singular_point_of_disc_zero_two : ∀ A B : ZMod 2, -16 * (4 * A ^ 3 + 27 * B ^ 2) = 0 →
    ∃ x y : ZMod 2, y ^ 2 = x ^ 3 + A * x + B ∧
      (y ^ 2 = x ^ 3 + A * x + B → 0 - (3 * x ^ 2 + A) = 0 ∧ 2 * y = 0) := by
  decide

#print axioms singular_point_of_disc_zero_two

theorem singular_point_of_disc_zero_three : ∀ A B : ZMod 3, -16 * (4 * A ^ 3 + 27 * B ^ 2) = 0 →
    ∃ x y : ZMod 3, y ^ 2 = x ^ 3 + A * x + B ∧
      (y ^ 2 = x ^ 3 + A * x + B → 0 - (3 * x ^ 2 + A) = 0 ∧ 2 * y = 0) := by
  decide

#print axioms singular_point_of_disc_zero_three

/-- The counting rule: at an odd prime `p`, each `x` gives `1 + ((x^3 + a x + b)/p)` points, so
the curve `y^2 = x^3 + a x + b` mod `p` has `p + 1 + Σ_{x=0}^{p-1} ((x^3 + a x + b)/p)` points,
`O` included. -/
theorem point_count_eq_p_add_one_add_sum_legendre (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) (a b : ℤ) :
    (pointCount p a b : ℤ) =
      p + 1 + ∑ x ∈ Finset.range p, legendreSym p ((x : ℤ) ^ 3 + a * x + b) := by
  have key : ∀ c : ℤ, ((Finset.univ.filter fun y : ZMod p => y ^ 2 = (c : ZMod p)).card : ℤ) =
      legendreSym p c + 1 := by
    intro c
    rw [← legendreSym.card_sqrts p hp c]
    congr 2
    ext y; simp
  unfold pointCount
  push_cast
  rw [Finset.card_filter, Fintype.sum_prod_type]
  simp only [← Finset.card_filter]
  rw [← sum_range_eq_sum_zmod p (fun x => (Finset.univ.filter fun y : ZMod p =>
      y ^ 2 = x ^ 3 + (a : ZMod p) * x + (b : ZMod p)).card)]
  push_cast
  have h2 : ∀ n ∈ Finset.range p,
      (((Finset.univ.filter fun y : ZMod p =>
        y ^ 2 = (n : ZMod p) ^ 3 + (a : ZMod p) * n + (b : ZMod p)).card : ℕ) : ℤ) =
      legendreSym p ((n : ℤ) ^ 3 + a * n + b) + 1 := by
    intro n _
    rw [← key]
    congr 4
    ext y; push_cast; rfl
  rw [Finset.sum_congr rfl h2, Finset.sum_add_distrib]
  simp
  ring

/-- The primes of bad reduction: read mod a prime `p`, the curve `y^2 = x^3 + a x + b` with
whole-number coefficients has a singular point (a point of the curve where both slopes vanish)
exactly when `p` divides its discriminant `Δ = -16 (4a^3 + 27b^2)`. -/
theorem singular_mod_p_iff_dvd_discriminant (p : ℕ) [Fact p.Prime] (a b : ℤ) :
    (∃ x y : ZMod p, (shortWeierstrass (a : ZMod p) (b : ZMod p)).toAffine.Equation x y ∧
        ¬ (shortWeierstrass (a : ZMod p) (b : ZMod p)).toAffine.Nonsingular x y) ↔
      (p : ℤ) ∣ (shortWeierstrass a b).Δ := by
  have hΔ : (shortWeierstrass a b).Δ = -16 * (4 * a ^ 3 + 27 * b ^ 2) := by
    simp [Δ, b₂, b₄, b₆, b₈]; ring
  rw [hΔ, ← ZMod.intCast_zmod_eq_zero_iff_dvd]
  push_cast
  simp only [Affine.nonsingular_iff', Affine.equation_iff, not_and, not_or, not_not]
  simp only [zero_mul, mul_zero, add_zero]
  generalize (a : ZMod p) = A
  generalize (b : ZMod p) = B
  constructor
  · rintro ⟨x, y, he, hs⟩
    obtain ⟨h1, h2⟩ := hs he
    have hA : A = -3 * x ^ 2 := by linear_combination -h1
    have hB : B = y ^ 2 + 2 * x ^ 3 := by rw [hA] at he; linear_combination -he
    rw [hA, hB]
    linear_combination (-216 * y * (y ^ 2 + 4 * x ^ 3)) * h2
  · intro h
    have hp := (Fact.out : p.Prime)
    by_cases hp2 : p = 2
    · subst hp2
      exact singular_point_of_disc_zero_two A B h
    by_cases hp3 : p = 3
    · subst hp3
      exact singular_point_of_disc_zero_three A B h
    have hp5 : 5 ≤ p := by
      have := hp.two_le
      rcases (show p = 4 ∨ 5 ≤ p by omega) with h4 | h4
      · subst h4; exact absurd hp (by decide)
      · exact h4
    have h2 : (2 : ZMod p) ≠ 0 := by
      exact_mod_cast natCast_ne_zero_of_lt_prime p (n := 2) (by norm_num) (by omega)
    have h3 : (3 : ZMod p) ≠ 0 := by
      exact_mod_cast natCast_ne_zero_of_lt_prime p (n := 3) (by norm_num) (by omega)
    have h' : 4 * A ^ 3 + 27 * B ^ 2 = 0 := by
      have h16 : (-16 : ZMod p) ≠ 0 := by
        rw [show (-16 : ZMod p) = -(2 ^ 4) by norm_num, neg_ne_zero]
        exact pow_ne_zero _ h2
      exact (mul_eq_zero.mp h).resolve_left h16
    by_cases hA : A = 0
    · subst hA
      have hB : B = 0 := by
        have h27 : (27 : ZMod p) ≠ 0 := by
          rw [show (27 : ZMod p) = 3 ^ 3 by norm_num]; exact pow_ne_zero _ h3
        have : 27 * B ^ 2 = 0 := by linear_combination h'
        exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp ((mul_eq_zero.mp this).resolve_left h27)
      subst hB
      exact ⟨0, 0, by ring, fun _ => ⟨by ring, by ring⟩⟩
    · obtain ⟨x, hx⟩ : ∃ x : ZMod p, 2 * A * x + 3 * B = 0 :=
        ⟨-3 * B / (2 * A), by field_simp; ring⟩
      have hX : 3 * x ^ 2 + A = 0 := by
        have h4 : 4 * A ^ 2 ≠ 0 := mul_ne_zero (by
          rw [show (4 : ZMod p) = 2 ^ 2 by norm_num]; exact pow_ne_zero _ h2) (pow_ne_zero _ hA)
        have : 4 * A ^ 2 * (3 * x ^ 2 + A) = 0 := by
          linear_combination h' + 3 * (2 * A * x - 3 * B) * hx
        exact (mul_eq_zero.mp this).resolve_left h4
      have hY : x ^ 3 + A * x + B = 0 := by
        have : 3 * (x ^ 3 + A * x + B) = 0 := by linear_combination x * hX + hx
        exact (mul_eq_zero.mp this).resolve_left h3
      exact ⟨x, 0, by linear_combination -hY, fun _ => ⟨by linear_combination -hX, by ring⟩⟩

/-- Supersingular primes: when the prime `p` leaves 2 on division by 3, cubing shuffles the
remainders mod `p`, and the curve `y^2 = x^3 - 2` has exactly `p + 1` points mod `p`, so `a_p = 0`. -/
theorem point_count_eq_p_add_one_of_mod_three_eq_two (p : ℕ) [Fact p.Prime] (hp : p % 3 = 2) :
    pointCount p 0 (-2) = p + 1 := by
  have hp1 := (Fact.out : p.Prime).one_lt
  set k := (2 * p - 1) / 3 with hk
  have h3k : 3 * k = 2 * p - 1 := by omega
  have hpow : ∀ x : ZMod p, x ^ (3 * k) = x := by
    intro x
    rw [h3k, show 2 * p - 1 = (p - 1) + p by omega, pow_add, ZMod.pow_card, ← pow_succ,
      Nat.sub_add_cancel hp1.le, ZMod.pow_card]
  have hl : ∀ x : ZMod p, (x ^ 3) ^ k = x := fun x => by rw [← pow_mul, hpow]
  have hr : ∀ x : ZMod p, (x ^ k) ^ 3 = x := fun x => by rw [← pow_mul, mul_comm, hpow]
  unfold pointCount
  congr 1
  have hset : (Finset.univ.filter fun xy : ZMod p × ZMod p =>
      xy.2 ^ 2 = xy.1 ^ 3 + ((0 : ℤ) : ZMod p) * xy.1 + ((-2 : ℤ) : ZMod p)) =
      Finset.univ.image fun y : ZMod p => ((y ^ 2 + 2) ^ k, y) := by
    ext ⟨x, y⟩
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_image, Prod.mk.injEq]
    push_cast
    constructor
    · intro h
      rw [show y ^ 2 + 2 = x ^ 3 by linear_combination h, hl]
      exact ⟨rfl, rfl⟩
    · rintro ⟨rfl, -⟩
      rw [hr]; ring
  rw [hset, Finset.card_image_of_injective _ (fun u v h => (Prod.mk.inj h).2), Finset.card_univ,
    ZMod.card]

-- The house point (3, 5) is on y^2 = x^3 - 2.
example : (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num

-- Mod 7 the curve y^2 = x^3 - 2 has 7 points, O included, so a_7 = 8 - 7 = 1.
example : pointCount 7 0 (-2) = 7 := by decide +kernel

-- The values of x^3 - 2 mod 7 for x = 0 to 6 are 5, 6, 6, 4, 6, 4, 4.
example : ((List.range 7).map fun x : ℕ => ((x : ℤ) ^ 3 - 2) % 7) = [5, 6, 6, 4, 6, 4, 4] := by
  decide

-- Euler's test mod 7: 4^3 leaves 1 (a square), 5^3 and 6^3 leave 6, that is -1 (not squares).
example : 4 ^ 3 % 7 = 1 ∧ 5 ^ 3 % 7 = 6 ∧ 6 ^ 3 % 7 = 6 := by norm_num

-- The Legendre symbols agree: (4/7) = +1, (5/7) = -1, (6/7) = -1.
instance fact_prime_seven : Fact (Nat.Prime 7) := ⟨by decide⟩

example : legendreSym 7 4 = 1 ∧ legendreSym 7 5 = -1 ∧ legendreSym 7 6 = -1 := by
  norm_num

-- The counting rule at p = 7: three symbols +1 and four -1 sum to -1, so the count is 8 - 1 = 7.
example : ∑ x ∈ Finset.range 7, legendreSym 7 ((x : ℤ) ^ 3 + 0 * x + -2) = -1 := by
  simp [Finset.sum_range_succ]
  norm_num

-- The six affine points mod 7.
example : (Finset.univ.filter fun xy : ZMod 7 × ZMod 7 => xy.2 ^ 2 = xy.1 ^ 3 - 2) =
    {(3, 2), (3, 5), (5, 2), (5, 5), (6, 2), (6, 5)} := by decide +kernel

-- Hasse's window at p = 7: a_7^2 = 1 is at most 4 * 7 = 28.
example : (7 + 1 - (pointCount 7 0 (-2) : ℤ)) ^ 2 ≤ 4 * 7 := by decide +kernel

-- Mod 13 the count is 19, and a_13^2 = 36 is at most 52.
example : pointCount 13 0 (-2) = 19 ∧ (13 + 1 - 19 : ℤ) ^ 2 ≤ 4 * 13 := by decide +kernel

-- Mod 37 the count is 49, just under the ceiling: a_37^2 = 121 is at most 148.
example : pointCount 37 0 (-2) = 49 ∧ (37 + 1 - 49 : ℤ) ^ 2 ≤ 4 * 37 := by decide +kernel

-- The discriminant of y^2 = x^3 - 2 is -1728 = -(2^6 * 3^3).
example : (shortWeierstrass (0 : ℤ) (-2)).Δ = -1728 ∧ (-1728 : ℤ) = -(2 ^ 6 * 3 ^ 3) := by
  constructor
  · simp [Δ, b₂, b₄, b₆, b₈]
  · norm_num

-- At the bad primes: mod 3 the curve has 4 points, mod 2 it has 3, O included.
example : pointCount 3 0 (-2) = 4 ∧ pointCount 2 0 (-2) = 3 := by decide +kernel

-- The cusps: (2, 0) mod 3 and (0, 0) mod 2 are on the curve with both slopes zero.
example : ((0 : ZMod 3) ^ 2 = 2 ^ 3 - 2 ∧ 2 * (0 : ZMod 3) = 0 ∧ 3 * (2 : ZMod 3) ^ 2 = 0) ∧
    ((0 : ZMod 2) ^ 2 = 0 ^ 3 - 2 ∧ 2 * (0 : ZMod 2) = 0 ∧ 3 * (0 : ZMod 2) ^ 2 = 0) := by decide +kernel

#print axioms point_count_eq_p_add_one_add_sum_legendre
#print axioms singular_mod_p_iff_dvd_discriminant
#print axioms point_count_eq_p_add_one_of_mod_three_eq_two
