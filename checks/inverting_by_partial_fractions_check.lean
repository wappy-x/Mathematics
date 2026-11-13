-- Inverting: a transform (αs + β)/(s^2 + Ps + Q) whose bottom has no real roots is the Laplace transform of the fading cosine and sine read off the completed square, a real pole A/(s − c) is the transform of A e^(ct), and the complex cover-up split gives the same cosine and sine weights.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open MeasureTheory Set Real

/-- The card's Laplace transform of a real signal `f`, read at a real `s`:
`F(s) = ∫₀^∞ e^(−st) f(t) dt`. -/
noncomputable def laplace (f : ℝ → ℝ) (s : ℝ) : ℝ :=
  ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * f t

lemma damped_pointwise (k ω C D t : ℝ) :
    (((C : ℂ) - (D : ℂ) * Complex.I) * Complex.exp ((-(k : ℂ) + (ω : ℂ) * Complex.I) * t)).re =
      Real.exp (-(k * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t)) := by
  have : (-(k : ℂ) + (ω : ℂ) * Complex.I) * t = ((-(k * t) : ℝ) : ℂ) + ((ω * t : ℝ) : ℂ) * Complex.I := by
    push_cast; ring
  rw [this, Complex.exp_add, Complex.exp_mul_I, ← Complex.ofReal_exp, ← Complex.ofReal_cos,
    ← Complex.ofReal_sin]
  simp only [Complex.mul_re, Complex.mul_im, Complex.sub_re, Complex.sub_im, Complex.add_re,
    Complex.add_im, Complex.ofReal_re, Complex.ofReal_im, Complex.I_re, Complex.I_im]
  ring

lemma damped_laplace (k ω C D : ℝ) (hk : 0 < k) :
    IntegrableOn (fun t : ℝ => Real.exp (-(k * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t)))
        (Ioi 0) ∧
      ∫ t in Ioi (0 : ℝ), Real.exp (-(k * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t)) =
        (C * k + D * ω) / (k ^ 2 + ω ^ 2) := by
  set z : ℂ := -(k : ℂ) + (ω : ℂ) * Complex.I with hz
  have hzre : z.re < 0 := by simp [hz]; linarith
  have hint : IntegrableOn (fun t : ℝ => ((C : ℂ) - (D : ℂ) * Complex.I) * Complex.exp (z * t))
      (Ioi 0) := (integrableOn_exp_mul_complex_Ioi hzre 0).const_mul _
  have hfun : (fun t : ℝ => Real.exp (-(k * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t))) =
      fun t : ℝ => RCLike.re (((C : ℂ) - (D : ℂ) * Complex.I) * Complex.exp (z * t)) := by
    funext t; rw [RCLike.re_to_complex, hz, damped_pointwise]
  rw [hfun]
  refine ⟨hint.re, ?_⟩
  rw [integral_re hint, integral_const_mul, integral_exp_mul_complex_Ioi hzre, RCLike.re_to_complex]
  have hz0 : z ≠ 0 := by intro h; rw [h] at hzre; simp at hzre
  have hden : (k : ℝ) ^ 2 + ω ^ 2 ≠ 0 := by positivity
  rw [show ((C : ℂ) - (D : ℂ) * Complex.I) * (-Complex.exp (z * ((0:ℝ) : ℂ)) / z)
      = ((C * k + D * ω) / (k ^ 2 + ω ^ 2) : ℝ) + ((C * ω - D * k) / (k ^ 2 + ω ^ 2) : ℝ) * Complex.I by
    rw [Complex.ofReal_zero, mul_zero, Complex.exp_zero]
    have hdenC : (k : ℂ) ^ 2 + (ω : ℂ) ^ 2 ≠ 0 := by exact_mod_cast hden
    rw [mul_div_assoc', div_eq_iff hz0, hz]
    push_cast
    field_simp
    linear_combination (-(ω : ℂ) * (C * ω - k * D)) * Complex.I_sq]
  simp only [Complex.add_re, Complex.ofReal_re, Complex.mul_re, Complex.ofReal_im, Complex.I_re,
    Complex.I_im]
  ring

#print axioms damped_pointwise
#print axioms damped_laplace

/-- The card's main claim, for a quadratic bottom with no real roots. Take a proper fraction
`(αs + β)/(s^2 + Ps + Q)` with negative discriminant `P^2 − 4Q < 0`. Complete the square,
`s^2 + Ps + Q = (s + a)^2 + ω^2` with `a = P/2` and `ω = √(Q − P^2/4)`, and rewrite the top as
`C(s + a) + Dω`, so `C = α` and `D = (β − αa)/ω`. Then the signal read off the table,
`y(t) = e^(−at)(C cos ωt + D sin ωt)`, really has this fraction as its transform: at every `s`
where the transform integral exists (`s > −a`) the integral converges and equals the fraction. -/
theorem laplace_completed_square_reading (P Q α β s : ℝ) (hdisc : P ^ 2 - 4 * Q < 0)
    (hs : -(P / 2) < s) :
    let a := P / 2
    let ω := Real.sqrt (Q - P ^ 2 / 4)
    let C := α
    let D := (β - α * a) / ω
    let y : ℝ → ℝ := fun t => Real.exp (-(a * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t))
    IntegrableOn (fun t : ℝ => Real.exp (-(s * t)) * y t) (Ioi 0) ∧
      laplace y s = (α * s + β) / (s ^ 2 + P * s + Q) := by
  intro a ω C D y
  have hk : 0 < s + a := by simp only [a]; linarith
  have hfun : (fun t : ℝ => Real.exp (-(s * t)) * y t) =
      fun t : ℝ => Real.exp (-((s + a) * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t)) := by
    funext t
    simp only [y]
    rw [← mul_assoc, ← Real.exp_add]
    congr 2
    ring
  obtain ⟨hI, hV⟩ := damped_laplace (s + a) ω C D hk
  refine ⟨hfun ▸ hI, ?_⟩
  have hL : laplace y s = ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * y t := rfl
  rw [hL, hfun, hV]
  have hq : 0 < Q - P ^ 2 / 4 := by linarith
  have hω2 : ω ^ 2 = Q - P ^ 2 / 4 := Real.sq_sqrt hq.le
  have hωpos : 0 < ω := Real.sqrt_pos.2 hq
  have hDω : D * ω = β - α * a := by
    simp only [D]
    field_simp
  rw [hDω, hω2]
  simp only [C, a]
  congr 1 <;> ring

/-- The real-pole row: `A/(s − c)` is the transform of `A e^(ct)`. For every weight `A`, every
real pole `c` and every `s > c`, the transform integral converges and equals `A/(s − c)`. -/
theorem laplace_real_pole_reading (A c s : ℝ) (hs : c < s) :
    IntegrableOn (fun t : ℝ => Real.exp (-(s * t)) * (A * Real.exp (c * t))) (Ioi 0) ∧
      laplace (fun t => A * Real.exp (c * t)) s = A / (s - c) := by
  have hfun : (fun t : ℝ => Real.exp (-(s * t)) * (A * Real.exp (c * t))) =
      fun t : ℝ => A * Real.exp ((c - s) * t) := by
    funext t
    rw [mul_left_comm, ← Real.exp_add]
    congr 2
    ring
  have hcs : c - s < 0 := by linarith
  refine ⟨hfun ▸ (integrableOn_exp_mul_Ioi hcs 0).const_mul A, ?_⟩
  have hL : laplace (fun t => A * Real.exp (c * t)) s =
      ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * (A * Real.exp (c * t)) := rfl
  rw [hL, hfun, integral_const_mul, integral_exp_mul_Ioi hcs, mul_zero, Real.exp_zero]
  have : s - c ≠ 0 := by linarith
  have : c - s ≠ 0 := by linarith
  field_simp
  ring

/-- The two splitting routes agree. Let the bottom's roots be `p = −a + iω` and its mirror
image `p̄ = −a − iω`, with `ω > 0`, and let the top be `C(s + a) + Dω`. The cover-up value at `p`,
`r = (C(p + a) + Dω)/(p − p̄)`, equals `(C − iD)/2`; the complex split
`r/(s − p) + r̄/(s − p̄)` equals `(C(s + a) + Dω)/((s + a)^2 + ω^2)` at every `s` other than the
two roots; and in time the pair `2 Re(r e^(pt))` is `e^(−at)(C cos ωt + D sin ωt)`. -/
theorem cover_up_agrees_with_completed_square (a ω C D : ℝ) (hω : 0 < ω) :
    let p : ℂ := -(a : ℂ) + (ω : ℂ) * Complex.I
    let N : ℂ → ℂ := fun s => (C : ℂ) * (s + a) + (D : ℂ) * ω
    let r : ℂ := N p / (p - (starRingEnd ℂ) p)
    r = ((C : ℂ) - (D : ℂ) * Complex.I) / 2 ∧
      (∀ s : ℂ, s ≠ p → s ≠ (starRingEnd ℂ) p →
        r / (s - p) + (starRingEnd ℂ) r / (s - (starRingEnd ℂ) p) =
          N s / ((s + a) ^ 2 + (ω : ℂ) ^ 2)) ∧
      (∀ t : ℝ, 2 * (r * Complex.exp (p * t)).re =
        Real.exp (-(a * t)) * (C * Real.cos (ω * t) + D * Real.sin (ω * t))) := by
  intro p N r
  have hωC : (ω : ℂ) ≠ 0 := by exact_mod_cast hω.ne'
  have hp : (starRingEnd ℂ) p = -(a : ℂ) - (ω : ℂ) * Complex.I := by
    simp only [p, map_add, map_neg, map_mul, Complex.conj_ofReal, Complex.conj_I]; ring
  have hr : r = ((C : ℂ) - (D : ℂ) * Complex.I) / 2 := by
    simp only [r, N, hp, p]
    rw [div_eq_div_iff (by
      intro h
      have : (2 : ℂ) * ω * Complex.I = 0 := by linear_combination h
      simp [hωC] at this) two_ne_zero]
    linear_combination (2 * (ω : ℂ) * D) * Complex.I_sq
  have hrc : (starRingEnd ℂ) r = ((C : ℂ) + (D : ℂ) * Complex.I) / 2 := by
    rw [hr]; simp only [map_div₀, map_sub, map_mul, Complex.conj_ofReal, Complex.conj_I, map_ofNat]
    ring
  refine ⟨hr, ?_, ?_⟩
  · intro s hs1 hs2
    have h1 : s - p ≠ 0 := sub_ne_zero.2 hs1
    have h2 : s - (starRingEnd ℂ) p ≠ 0 := sub_ne_zero.2 hs2
    have hden : (s + a) ^ 2 + (ω : ℂ) ^ 2 = (s - p) * (s - (starRingEnd ℂ) p) := by
      rw [hp]; simp only [p]; linear_combination ((ω : ℂ) ^ 2) * Complex.I_sq
    rw [hden, hrc, hr, div_add_div _ _ h1 h2, div_eq_div_iff (mul_ne_zero h1 h2) (mul_ne_zero h1 h2)]
    rw [hp]; simp only [N, p]
    ring_nf
    simp only [Complex.I_sq, Complex.I_pow_four]
    ring
  · intro t
    rw [← damped_pointwise a ω C D t, hr]
    simp only [p]
    rw [div_mul_eq_mul_div, Complex.div_ofNat_re]
    ring

-- Worked numbers, exact.
-- Test the bottom: 2^2 − 4 × 5 = −16, so s^2 + 2s + 5 has no real roots.
example : (2 : ℤ) ^ 2 - 4 * 5 = -16 := by norm_num
-- Complete the square: s^2 + 2s + 5 = (s + 1)^2 + 4, so a = 1 and ω = 2.
example : ∀ s : ℚ, s ^ 2 + 2 * s + 5 = (s + 1) ^ 2 + 2 ^ 2 := by
  intro s; ring
-- Shift the top: s + 2 = 1 · (s + 1) + (1/2) · 2, so C = 1 and D = 1/2.
example : ∀ s : ℚ, s + 2 = 1 * (s + 1) + (1 / 2) * 2 := by
  intro s; ring
-- The released car starts at 1 cm: e^0 (cos 0 + 0.5 sin 0) = 1.
example : Real.exp (-(1 * 0)) * (Real.cos (2 * 0) + (1 / 2) * Real.sin (2 * 0)) = 1 := by simp
-- Transform back at s = 2: (2 + 2)/(4 + 4 + 5) = 4/13.
example : ((2 : ℚ) + 2) / (2 ^ 2 + 2 * 2 + 5) = 4 / 13 := by norm_num
-- The forward check: the released car's signal has transform 4/13 at s = 2.
example : laplace (fun t => Real.exp (-(1 * t)) * (Real.cos (2 * t) + (1 / 2) * Real.sin (2 * t))) 2
    = 4 / 13 := by
  have hfun : (fun t : ℝ => Real.exp (-(2 * t)) *
      (Real.exp (-(1 * t)) * (Real.cos (2 * t) + (1 / 2) * Real.sin (2 * t)))) =
      fun t : ℝ => Real.exp (-(3 * t)) * (1 * Real.cos (2 * t) + (1 / 2) * Real.sin (2 * t)) := by
    funext t
    rw [← mul_assoc, ← Real.exp_add, show -(2 * t) + -(1 * t) = -(3 * t) by ring, one_mul]
  have hL : laplace (fun t => Real.exp (-(1 * t)) * (Real.cos (2 * t) + (1 / 2) * Real.sin (2 * t))) 2
      = ∫ t in Ioi (0 : ℝ), Real.exp (-(2 * t)) *
        (Real.exp (-(1 * t)) * (Real.cos (2 * t) + (1 / 2) * Real.sin (2 * t))) := rfl
  rw [hL, hfun, (damped_laplace 3 2 1 (1 / 2) (by norm_num)).2]
  norm_num
-- The car's cover-up value: r = (1 + 2i)/(4i) = 1/2 − i/4.
example : ((1 : ℂ) + 2 * Complex.I) / (4 * Complex.I) = 1 / 2 - Complex.I / 4 := by
  rw [div_eq_iff (by simp)]
  linear_combination (1 : ℂ) * Complex.I_sq
-- The push, real pole by cover-up at s = 0: 5/5 = 1, so A = 1.
example : (5 : ℚ) / (0 ^ 2 + 2 * 0 + 5) = 1 := by norm_num
-- The push split: 5/(s(s^2 + 2s + 5)) = 1/s − (s + 2)/(s^2 + 2s + 5) for every s ≠ 0.
example : ∀ s : ℚ, s ≠ 0 →
    5 / (s * (s ^ 2 + 2 * s + 5)) = 1 / s - (s + 2) / (s ^ 2 + 2 * s + 5) := by
  intro s hs
  have : s ^ 2 + 2 * s + 5 ≠ 0 := by nlinarith [sq_nonneg (s + 1)]
  rw [div_sub_div _ _ hs this, div_eq_div_iff (mul_ne_zero hs this) (mul_ne_zero hs this)]
  ring

#print axioms laplace_completed_square_reading
#print axioms laplace_real_pole_reading
#print axioms cover_up_agrees_with_completed_square
