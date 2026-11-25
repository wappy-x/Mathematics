-- Neutral geometry: if two angles of every triangle add to less than 180 degrees and Legendre's move keeps the angle sum while halving an angle, then no triangle's angles add to more than 180 degrees.
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Geometry.Euclidean.Triangle

/-
Mathlib has no axiom system for neutral (absolute) geometry, so the
Saccheri-Legendre theorem cannot be stated there with the parallel postulate
left out. This file states the logical core of the card's proof instead.
The triangles are any type `T`; `A t`, `B t`, `C t` are a triangle's corner
angles in degrees. The two hypotheses are exactly the two neutral facts the
card proves without parallels (Step 1 and Step 2), and the real numbers supply
Archimedes' axiom. The flat (Euclidean) case is stated with Mathlib's own
`EuclideanGeometry.angle`.
-/

open EuclideanGeometry

/-- **Halving beats any excess (Archimedes' axiom, Step 3).** However large an
angle `a` and however small a positive excess `p`, some number `n` of halvings
brings `a / 2 ^ n` below `p`. -/
theorem exists_halving_lt_excess (a p : ℝ) (hp : 0 < p) :
    ∃ n : ℕ, a / 2 ^ n < p := by
  obtain ⟨n, hn⟩ := exists_nat_gt (a / p)
  refine ⟨n, ?_⟩
  have h2 : (0 : ℝ) < 2 ^ n := by positivity
  have hle : (n : ℝ) < 2 ^ n := by exact_mod_cast Nat.lt_two_pow_self
  rw [div_lt_iff₀ h2]
  rw [div_lt_iff₀ hp] at hn
  nlinarith

/-- **Saccheri-Legendre, the card's argument.** Suppose that in every triangle
the two corners other than `A` add to less than 180 degrees (the exterior angle
theorem, Step 1), and that Legendre's move turns any triangle into one with the
same angle sum whose corner `A` is at most half the old one (Step 2). Then every
triangle's three angles add to at most 180 degrees. -/
theorem angle_sum_le_180_of_legendre_move {T : Type*} (A B C : T → ℝ)
    (two_angles_lt : ∀ t, B t + C t < 180)
    (legendre_move : ∀ t, ∃ t', A t' + B t' + C t' = A t + B t + C t ∧ A t' ≤ A t / 2) :
    ∀ t, A t + B t + C t ≤ 180 := by
  intro t
  have iter : ∀ n : ℕ, ∃ t', A t' + B t' + C t' = A t + B t + C t ∧ A t' ≤ A t / 2 ^ n := by
    intro n
    induction n with
    | zero => exact ⟨t, rfl, by simp⟩
    | succ n ih =>
      obtain ⟨t₁, hs₁, ha₁⟩ := ih
      obtain ⟨t₂, hs₂, ha₂⟩ := legendre_move t₁
      refine ⟨t₂, hs₂.trans hs₁, ?_⟩
      calc A t₂ ≤ A t₁ / 2 := ha₂
        _ ≤ (A t / 2 ^ n) / 2 := by linarith
        _ = A t / 2 ^ (n + 1) := by rw [pow_succ, div_div]
  by_contra hgt
  rw [not_le] at hgt
  have hp : 0 < A t + B t + C t - 180 := by linarith
  obtain ⟨n, hn⟩ := exists_halving_lt_excess (A t) _ hp
  obtain ⟨t', hs, ha⟩ := iter n
  have := two_angles_lt t'
  linarith

/-- **The flat case.** In Euclid's plane (any real inner product space), a
triangle's angles add to at most a half-turn, `π` radians, as neutral geometry
promises; here two distinct corners are enough. -/
theorem euclidean_angle_sum_le_pi {V P : Type*} [NormedAddCommGroup V]
    [InnerProductSpace ℝ V] [MetricSpace P] [NormedAddTorsor V P]
    (p₁ p₂ p₃ : P) (h : p₂ ≠ p₁) :
    ∠ p₁ p₂ p₃ + ∠ p₂ p₃ p₁ + ∠ p₃ p₁ p₂ ≤ Real.pi := by
  exact (angle_add_angle_add_angle_eq_pi p₃ h).le

-- The card's worked numbers: a claimed 181-degree triangle with a 60-degree corner.
-- Six halvings of 60 get below the 1-degree excess: 60/64 = 15/16 < 1.
example : (60 : ℚ) / 2 ^ 6 = 15 / 16 := by norm_num
example : (60 : ℚ) / 2 ^ 6 < 1 := by norm_num
-- Five halvings are not enough: 60/32 = 1.875 is not below 1.
example : ¬ ((60 : ℚ) / 2 ^ 5 < 1) := by norm_num
-- The whole-number form: 2^5 ≤ 60 < 2^6, so exactly 6 halvings are needed.
example : 2 ^ 5 ≤ 60 ∧ 60 < 2 ^ 6 := by decide
-- After six halvings the other two corners hold 181 - 15/16 = 180 + 1/16 > 180.
example : (181 : ℚ) - 60 / 2 ^ 6 = 180 + 1 / 16 := by norm_num
example : (181 : ℚ) - 60 / 2 ^ 6 > 180 := by norm_num
-- Stopping at five halvings leaves 181 - 60/32 = 179.125 < 180: no clash.
example : (181 : ℚ) - 60 / 2 ^ 5 < 180 := by norm_num
-- Try changing: a claimed 180.5 degrees needs 7 halvings (60/128 < 1/2 but 60/64 is not).
example : (60 : ℚ) / 2 ^ 7 < 1 / 2 ∧ ¬ ((60 : ℚ) / 2 ^ 6 < 1 / 2) := by norm_num
example : (361 / 2 : ℚ) - 60 / 2 ^ 7 = 180 + 1 / 32 := by norm_num

#print axioms angle_sum_le_180_of_legendre_move
#print axioms exists_halving_lt_excess
#print axioms euclidean_angle_sum_le_pi
