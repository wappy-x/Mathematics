-- Powers and roots: a whole-number power multiplies the angle and powers the length (de Moivre), so every nonzero complex number has exactly n n-th roots, evenly spaced on one circle, and for n at least 2 the n-th roots of 1 add to zero.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.Data.Set.Card

open Complex

theorem cis_eq_exp_helper (x : ℝ) :
    ((Real.cos x : ℂ) + (Real.sin x : ℂ) * I) = exp ((x : ℂ) * I) := by
  rw [exp_mul_I, ← ofReal_cos, ← ofReal_sin]

theorem sqrt_two_sq_helper : ((Real.sqrt 2 : ℝ) : ℂ) ^ 2 = 2 := by
  rw [← ofReal_pow, Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 2)]; norm_num

theorem sqrt_three_sq_helper : ((Real.sqrt 3 : ℝ) : ℂ) ^ 2 = 3 := by
  rw [← ofReal_pow, Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 3)]; norm_num

theorem spinner_sq_helper :
    ((Real.sqrt 2 / 2 : ℝ) + (Real.sqrt 2 / 2 : ℝ) * I : ℂ) ^ 2 = I := by
  push_cast
  linear_combination I / 2 * sqrt_two_sq_helper + (Real.sqrt 2 : ℂ) ^ 2 / 4 * I_sq

/-- **Every nonzero number has exactly n n-th roots, evenly spaced on one circle.**
Let n be a whole number at least 1, and let c be a nonzero complex number with length r = ‖c‖
and angle θ, so c = r (cos θ + i sin θ) (θ is any angle for c: whole turns only change which
root is called k = 0). For k = 0, 1, …, n − 1 put
z_k = r^(1/n) (cos ((θ + 2πk)/n) + i sin ((θ + 2πk)/n)).
Then these n numbers are all different, they are exactly the solutions of z^n = c, and so
z^n = c has exactly n solutions. They all have length r^(1/n), one n-th of a turn apart. -/
theorem nth_roots_of_nonzero_are_n_evenly_spaced (n : ℕ) (hn : 0 < n) (c : ℂ) (hc : c ≠ 0)
    (θ : ℝ) (hθ : c = (‖c‖ : ℂ) * ((Real.cos θ : ℂ) + (Real.sin θ : ℂ) * I)) :
    Function.Injective (fun k : Fin n =>
        ((‖c‖ ^ ((n : ℝ)⁻¹) : ℝ) : ℂ) *
          ((Real.cos ((θ + 2 * Real.pi * (k : ℕ)) / n) : ℂ) +
            (Real.sin ((θ + 2 * Real.pi * (k : ℕ)) / n) : ℂ) * I)) ∧
      Set.range (fun k : Fin n =>
          ((‖c‖ ^ ((n : ℝ)⁻¹) : ℝ) : ℂ) *
            ((Real.cos ((θ + 2 * Real.pi * (k : ℕ)) / n) : ℂ) +
              (Real.sin ((θ + 2 * Real.pi * (k : ℕ)) / n) : ℂ) * I)) =
        {z : ℂ | z ^ n = c} ∧
      Set.ncard {z : ℂ | z ^ n = c} = n := by
  have hn0 : n ≠ 0 := hn.ne'
  set ρ : ℝ := ‖c‖ ^ ((n : ℝ)⁻¹) with hρ
  set ζ : ℂ := exp (2 * Real.pi * I / n) with hζ
  have hprim : IsPrimitiveRoot ζ n := isPrimitiveRoot_exp n hn0
  set z0 : ℂ := (ρ : ℂ) * exp (((θ / n : ℝ) : ℂ) * I) with hz0
  have hf : (fun k : Fin n =>
        ((‖c‖ ^ ((n : ℝ)⁻¹) : ℝ) : ℂ) *
          ((Real.cos ((θ + 2 * Real.pi * (k : ℕ)) / n) : ℂ) +
            (Real.sin ((θ + 2 * Real.pi * (k : ℕ)) / n) : ℂ) * I)) =
      fun k : Fin n => z0 * ζ ^ (k : ℕ) := by
    funext k
    rw [cis_eq_exp_helper, hz0, hζ, ← exp_nat_mul, mul_assoc (ρ : ℂ), ← exp_add]
    congr 2
    push_cast
    field_simp
  have hρpos : 0 < ρ := Real.rpow_pos_of_pos (norm_pos_iff.mpr hc) _
  have hz0ne : z0 ≠ 0 := by
    rw [hz0]
    exact mul_ne_zero (by exact_mod_cast hρpos.ne') (exp_ne_zero _)
  have hz0n : z0 ^ n = c := by
    rw [hz0, mul_pow, ← exp_nat_mul, ← ofReal_pow, hρ,
      Real.rpow_inv_natCast_pow (norm_nonneg c) hn0]
    conv_rhs => rw [hθ, cis_eq_exp_helper]
    congr 2
    push_cast
    field_simp
  have hinj : Function.Injective (fun k : Fin n => z0 * ζ ^ (k : ℕ)) := by
    intro i j hij
    simp only at hij
    have := mul_left_cancel₀ hz0ne hij
    exact Fin.ext (hprim.pow_inj i.isLt j.isLt this)
  have hrange : Set.range (fun k : Fin n => z0 * ζ ^ (k : ℕ)) = {z : ℂ | z ^ n = c} := by
    ext z
    simp only [Set.mem_range, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨k, rfl⟩
      rw [mul_pow, ← pow_mul, mul_comm (k : ℕ) n, pow_mul, hprim.pow_eq_one, one_pow, mul_one,
        hz0n]
    · intro hz
      have : NeZero n := ⟨hn0⟩
      have h1 : (z / z0) ^ n = 1 := by
        rw [div_pow, hz, hz0n, div_self hc]
      obtain ⟨i, hi, hi'⟩ := hprim.eq_pow_of_pow_eq_one h1
      refine ⟨⟨i, hi⟩, ?_⟩
      simp only
      rw [hi']
      field_simp
  rw [hf]
  refine ⟨hinj, hrange, ?_⟩
  rw [← hrange, Set.ncard_range_of_injective hinj, Nat.card_eq_fintype_card, Fintype.card_fin]

/-- **De Moivre's formula.** For every length r, every angle θ (in radians) and every whole
number n, (r (cos θ + i sin θ))^n = r^n (cos nθ + i sin nθ): the power raises the length to
the n-th power and multiplies the angle by n. Negative n is allowed when the number is not 0. -/
theorem de_moivre_power_multiplies_angle (r θ : ℝ) (n : ℤ) (h : 0 ≤ n ∨ r ≠ 0) :
    ((r : ℂ) * ((Real.cos θ : ℂ) + (Real.sin θ : ℂ) * I)) ^ n =
      (r : ℂ) ^ n * ((Real.cos (n * θ) : ℂ) + (Real.sin (n * θ) : ℂ) * I) := by
  rw [cis_eq_exp_helper, cis_eq_exp_helper, mul_zpow, ← exp_int_mul]
  congr 2
  push_cast
  ring

/-- **The n-th roots of 1 add to zero.** For every whole number n at least 2, let
ω = cos (2π/n) + i sin (2π/n), one click of an n-th of a turn. Then
1 + ω + ω^2 + ⋯ + ω^(n−1) = 0. -/
theorem roots_of_unity_sum_to_zero (n : ℕ) (hn : 2 ≤ n) :
    ∑ k ∈ Finset.range n,
        ((Real.cos (2 * Real.pi / n) : ℂ) + (Real.sin (2 * Real.pi / n) : ℂ) * I) ^ k = 0 := by
  have hn0 : n ≠ 0 := by omega
  have hprim : IsPrimitiveRoot (exp (2 * Real.pi * I / n)) n := isPrimitiveRoot_exp n hn0
  have : ((Real.cos (2 * Real.pi / n) : ℂ) + (Real.sin (2 * Real.pi / n) : ℂ) * I) =
      exp (2 * Real.pi * I / n) := by
    rw [cis_eq_exp_helper]
    congr 1
    push_cast
    ring
  rw [this]
  exact hprim.geom_sum_eq_zero (by omega)

-- The card's exact worked values.
-- The spinner's click: the point at 45 degrees is √2/2 + (√2/2) i, and 8 clicks bring it home.
example : ((Real.sqrt 2 / 2 : ℝ) + (Real.sqrt 2 / 2 : ℝ) * I : ℂ) ^ 8 = 1 := by 
  rw [show (8 : ℕ) = 2 * 4 from rfl, pow_mul, spinner_sq_helper, I_pow_four]
-- Two clicks of the spinner reach i, a quarter turn.
example : ((Real.sqrt 2 / 2 : ℝ) + (Real.sqrt 2 / 2 : ℝ) * I : ℂ) ^ 2 = I := by exact spinner_sq_helper
-- Cube −1 + √3 i: length 2 cubed, angle 3 × 120° = 360°, giving 8.
example : ((-1 : ℂ) + (Real.sqrt 3 : ℂ) * I) ^ 3 = 8 := by 
  have h3 := sqrt_three_sq_helper
  have hI := I_sq
  linear_combination (3 - (Real.sqrt 3 : ℂ) * I) * h3 +
    ((Real.sqrt 3 : ℂ) ^ 2 * (-3 : ℂ) + (Real.sqrt 3 : ℂ) ^ 3 * I) * hI
-- The cube roots of 8 are 2 and −1 ± √3 i, and no others.
example : {z : ℂ | z ^ 3 = 8} =
    {2, -1 + (Real.sqrt 3 : ℂ) * I, -1 - (Real.sqrt 3 : ℂ) * I} := by 
  ext z
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
  have hf : z ^ 3 - 8 = (z - 2) * (z - (-1 + (Real.sqrt 3 : ℂ) * I)) *
      (z - (-1 - (Real.sqrt 3 : ℂ) * I)) := by
    linear_combination (2 - z) * sqrt_three_sq_helper + (z - 2) * (Real.sqrt 3 : ℂ) ^ 2 * I_sq
  rw [← sub_eq_zero, hf, mul_eq_zero, mul_eq_zero, sub_eq_zero, sub_eq_zero, sub_eq_zero, or_assoc]
-- The cube roots of 8 add to zero.
example : (2 : ℂ) + (-1 + (Real.sqrt 3 : ℂ) * I) + (-1 - (Real.sqrt 3 : ℂ) * I) = 0 := by ring
-- The roots of z^4 = −16 are ±√2 ± √2 i (length 2, at 45, 135, 225 and 315 degrees).
example : {z : ℂ | z ^ 4 = -16} =
    {(Real.sqrt 2 : ℂ) + (Real.sqrt 2 : ℂ) * I, -(Real.sqrt 2 : ℂ) + (Real.sqrt 2 : ℂ) * I,
      -(Real.sqrt 2 : ℂ) - (Real.sqrt 2 : ℂ) * I, (Real.sqrt 2 : ℂ) - (Real.sqrt 2 : ℂ) * I} := by
  ext z
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
  have h2 : (Real.sqrt 2 : ℂ) ^ 2 = 2 := sqrt_two_sq_helper
  have hf : z ^ 4 - -16 = (z - ((Real.sqrt 2 : ℂ) + (Real.sqrt 2 : ℂ) * I)) *
      (z - (-(Real.sqrt 2 : ℂ) + (Real.sqrt 2 : ℂ) * I)) *
      (z - (-(Real.sqrt 2 : ℂ) - (Real.sqrt 2 : ℂ) * I)) *
      (z - ((Real.sqrt 2 : ℂ) - (Real.sqrt 2 : ℂ) * I)) := by
    linear_combination (-4 * ((Real.sqrt 2 : ℂ) ^ 2 + 2)) * h2 +
      (2 * z ^ 2 * (Real.sqrt 2 : ℂ) ^ 2 - (Real.sqrt 2 : ℂ) ^ 4 * (I ^ 2 - 3)) * I_sq
  rw [← sub_eq_zero, hf, mul_eq_zero, mul_eq_zero, mul_eq_zero, sub_eq_zero, sub_eq_zero,
    sub_eq_zero, sub_eq_zero, or_assoc, or_assoc]
-- ω^3 reaches all 8 sectors (primitive); ω^2 does not, for ω = e^(2πi/8).
example : IsPrimitiveRoot (Complex.exp (2 * Real.pi * I / 8) ^ 3) 8 ∧
    ¬ IsPrimitiveRoot (Complex.exp (2 * Real.pi * I / 8) ^ 2) 8 := by 
  have h := isPrimitiveRoot_exp 8 (by norm_num)
  norm_num only [Nat.cast_ofNat] at h
  refine ⟨h.pow_of_coprime 3 (by decide), ?_⟩
  rw [h.pow_iff_coprime (by norm_num)]
  decide
-- The whole-number reason: 3 and 8 share no factor above 1; 2 and 8 share 2.
example : Nat.Coprime 3 8 ∧ ¬ Nat.Coprime 2 8 := by decide
-- Mistake 2: dividing the length by 3 gives 8/3, whose cube is 512/27, not 8.
example : ((8 : ℚ) / 3) ^ 3 = 512 / 27 ∧ ((8 : ℚ) / 3) ^ 3 ≠ 8 := by norm_num
-- Mistake 3: reading −16 at angle 0 gives 2, whose 4th power is 16, not −16.
example : (2 : ℂ) ^ 4 = 16 ∧ (2 : ℂ) ^ 4 ≠ -16 := by 
  refine ⟨by norm_num, ?_⟩
  intro h
  have := congrArg Complex.re h
  norm_num at this

#print axioms nth_roots_of_nonzero_are_n_evenly_spaced
#print axioms de_moivre_power_multiplies_angle
#print axioms roots_of_unity_sum_to_zero
#print axioms cis_eq_exp_helper
#print axioms sqrt_two_sq_helper
#print axioms sqrt_three_sq_helper
#print axioms spinner_sq_helper
