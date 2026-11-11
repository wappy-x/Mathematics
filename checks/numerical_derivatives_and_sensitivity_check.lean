-- Numerical derivatives: for a function with a continuous third derivative across the bumped range, the central difference misses the derivative by exactly h^2/6 times a third derivative at some inside point, the forward difference (with a continuous second derivative) by h/2 times a second derivative, and with prices off by at most η the central error is at most h^2 M₃/6 + η/h.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Set

theorem nd_open {f : ℝ → ℝ} {U : Set ℝ} (hU : IsOpen U) {n : ℕ}
    (hf : ContDiffOn ℝ (n + 1 : ℕ) f U) :
    (∀ x ∈ U, HasDerivAt f (deriv f x) x) ∧ ContDiffOn ℝ (n : ℕ) (deriv f) U := by
  refine ⟨fun x hx => ?_, hf.deriv_of_isOpen hU (by push_cast; exact le_rfl)⟩
  exact ((hf.differentiableOn (by simp)).differentiableAt (hU.mem_nhds hx)).hasDerivAt

#print axioms nd_open

/-- **The central error law.** Let h > 0 and let C have a continuous third derivative on the
whole bumped range from S - h to S + h. Then the central difference
(C(S + h) - C(S - h)) / (2h) differs from the true derivative C'(S) by exactly h^2/6 times the
third derivative C'''(ξ) at some point ξ strictly between S - h and S + h. -/
theorem central_difference_error (C : ℝ → ℝ) (S h : ℝ) (hh : 0 < h)
    (hC : ContDiffOn ℝ 3 C (Icc (S - h) (S + h))) :
    ∃ ξ ∈ Ioo (S - h) (S + h),
      (C (S + h) - C (S - h)) / (2 * h) - deriv C S = h ^ 2 / 6 * iteratedDeriv 3 C ξ := by
  have hU : ContDiffOn ℝ (2 + 1 : ℕ) C (Ioo (S - h) (S + h)) := hC.mono Ioo_subset_Icc_self
  obtain ⟨h1, hU2⟩ := nd_open isOpen_Ioo hU
  obtain ⟨h2, hU1⟩ := nd_open (n := 1) isOpen_Ioo hU2
  obtain ⟨h3, -⟩ := nd_open (n := 0) isOpen_Ioo hU1
  set D1 := deriv C
  set D2 := deriv D1
  set D3 := deriv D2
  have hcC : ContinuousOn C (Icc (S - h) (S + h)) := hC.continuousOn
  set K := (C (S + h) - C (S - h) - 2 * h * D1 S) / h ^ 3 with hK
  -- step 1: Rolle on g
  set g : ℝ → ℝ := fun t => C (S + t) - C (S - t) - 2 * t * D1 S - K * t ^ 3 with hg
  set g' : ℝ → ℝ := fun t => D1 (S + t) + D1 (S - t) - 2 * D1 S - K * (3 * t ^ 2) with hg'
  set g'' : ℝ → ℝ := fun t => D2 (S + t) - D2 (S - t) - K * (6 * t) with hg''
  have hmemp : ∀ t, 0 < t → t < h → S + t ∈ Ioo (S - h) (S + h) := fun t h0 h1 =>
    ⟨by linarith, by linarith⟩
  have hmemm : ∀ t, 0 < t → t < h → S - t ∈ Ioo (S - h) (S + h) := fun t h0 h1 =>
    ⟨by linarith, by linarith⟩
  obtain ⟨t1, ht1, hgt1⟩ : ∃ c ∈ Ioo 0 h, g' c = 0 := by
    refine exists_hasDerivAt_eq_zero (f := g) hh ?_ ?_ ?_
    · have hp : ContinuousOn (fun t => C (S + t)) (Icc 0 h) :=
        hcC.comp (continuousOn_const.add continuousOn_id)
          (fun t ht => ⟨by linarith [ht.1], by linarith [ht.2]⟩)
      have hm : ContinuousOn (fun t => C (S - t)) (Icc 0 h) :=
        hcC.comp (continuousOn_const.sub continuousOn_id)
          (fun t ht => ⟨by linarith [ht.2], by linarith [ht.1]⟩)
      exact ((hp.sub hm).sub (by fun_prop)).sub (by fun_prop)
    · simp only [hg, hK]
      field_simp
      ring_nf
    · intro t ht
      have a := (h1 (S + t) (hmemp t ht.1 ht.2)).comp_const_add S t
      have b := (h1 (S - t) (hmemm t ht.1 ht.2)).comp_const_sub S t
      have c := ((hasDerivAt_id t).mul_const (2 * D1 S))
      have d := ((hasDerivAt_pow 3 t).const_mul K)
      convert ((a.sub b).sub c).sub d using 1
      · ext s; simp [hg]; ring
      · simp [hg']
  -- step 2: Rolle on g'
  obtain ⟨t2, ht2, hgt2⟩ : ∃ c ∈ Ioo 0 t1, g'' c = 0 := by
    refine exists_hasDerivAt_eq_zero (f := g') ht1.1 ?_ ?_ ?_
    · intro t ht
      have hcon : ∀ y ∈ Ioo (S - h) (S + h), ContinuousAt D1 y := fun y hy =>
        (h2 y hy).continuousAt
      have hp : ContinuousAt (fun t => D1 (S + t)) t :=
        (hcon (S + t) ⟨by linarith [ht.1], by linarith [ht.2, ht1.2]⟩).comp
          (continuousAt_const.add continuousAt_id)
      have hm : ContinuousAt (fun t => D1 (S - t)) t :=
        (hcon (S - t) ⟨by linarith [ht.2, ht1.2], by linarith [ht.1]⟩).comp
          (continuousAt_const.sub continuousAt_id)
      exact (((hp.add hm).sub continuousAt_const).sub (by fun_prop)).continuousWithinAt
    · rw [hgt1]; simp only [hg']; ring_nf
    · intro t ht
      have a := (h2 (S + t) (hmemp t ht.1 (ht.2.trans ht1.2))).comp_const_add S t
      have b := (h2 (S - t) (hmemm t ht.1 (ht.2.trans ht1.2))).comp_const_sub S t
      have d := (((hasDerivAt_pow 2 t).const_mul 3).const_mul K)
      convert ((a.add b).sub (hasDerivAt_const t (2 * D1 S))).sub d using 1
      · simp [hg'']; ring
  -- step 3: MVT on D2
  have ht2h : t2 < h := ht2.2.trans ht1.2
  obtain ⟨ξ, hξ, hD3⟩ := exists_hasDerivAt_eq_slope D2 D3 (a := S - t2) (b := S + t2)
    (by linarith [ht2.1])
    (fun y hy => (h3 y ⟨by linarith [hy.1], by linarith [hy.2]⟩).continuousAt.continuousWithinAt)
    (fun y hy => h3 y ⟨by linarith [hy.1], by linarith [hy.2]⟩)
  refine ⟨ξ, ⟨by linarith [hξ.1], by linarith [hξ.2]⟩, ?_⟩
  have hit : iteratedDeriv 3 C ξ = D3 ξ := by
    rw [iteratedDeriv_eq_iterate]; rfl
  rw [hit, hD3]
  have e2 : D2 (S + t2) - D2 (S - t2) = K * (6 * t2) := by
    simp only [hg''] at hgt2; linarith
  have ed : S + t2 - (S - t2) = 2 * t2 := by ring
  rw [e2, ed, hK]
  have : t2 ≠ 0 := ht2.1.ne'
  field_simp

/-- **The forward error law.** Let h > 0 and let C have a continuous second derivative on the
bumped range from S - h to S + h. Then the forward difference (C(S + h) - C(S)) / h differs
from the true derivative C'(S) by exactly h/2 times the second derivative C''(ξ) at some point
ξ strictly between S and S + h. -/
theorem forward_difference_error (C : ℝ → ℝ) (S h : ℝ) (hh : 0 < h)
    (hC : ContDiffOn ℝ 2 C (Icc (S - h) (S + h))) :
    ∃ ξ ∈ Ioo S (S + h),
      (C (S + h) - C S) / h - deriv C S = h / 2 * iteratedDeriv 2 C ξ := by
  have hU : ContDiffOn ℝ (1 + 1 : ℕ) C (Ioo (S - h) (S + h)) := hC.mono Ioo_subset_Icc_self
  obtain ⟨h1, hU1⟩ := nd_open isOpen_Ioo hU
  obtain ⟨h2, -⟩ := nd_open (n := 0) isOpen_Ioo hU1
  set D1 := deriv C
  set D2 := deriv D1
  have hcC : ContinuousOn C (Icc (S - h) (S + h)) := hC.continuousOn
  set K := (C (S + h) - C S - h * D1 S) / h ^ 2 with hK
  set g : ℝ → ℝ := fun t => C (S + t) - C S - t * D1 S - K * t ^ 2 with hg
  set g' : ℝ → ℝ := fun t => D1 (S + t) - D1 S - K * (2 * t) with hg'
  obtain ⟨t1, ht1, hgt1⟩ : ∃ c ∈ Ioo 0 h, g' c = 0 := by
    refine exists_hasDerivAt_eq_zero (f := g) hh ?_ ?_ ?_
    · have hp : ContinuousOn (fun t => C (S + t)) (Icc 0 h) :=
        hcC.comp (continuousOn_const.add continuousOn_id)
          (fun t ht => ⟨by linarith [ht.1], by linarith [ht.2]⟩)
      exact ((hp.sub continuousOn_const).sub (by fun_prop)).sub (by fun_prop)
    · simp only [hg, hK]
      field_simp
      ring_nf
    · intro t ht
      have a := (h1 (S + t) ⟨by linarith [ht.1], by linarith [ht.2]⟩).comp_const_add S t
      have c := ((hasDerivAt_id t).mul_const (D1 S))
      have d := ((hasDerivAt_pow 2 t).const_mul K)
      convert ((a.sub (hasDerivAt_const t (C S))).sub c).sub d using 1
      · ext s; simp [hg]
      · simp [hg']
  obtain ⟨ξ, hξ, hD2⟩ := exists_hasDerivAt_eq_slope D1 D2 (a := S) (b := S + t1)
    (by linarith [ht1.1])
    (fun y hy => (h2 y ⟨by linarith [hy.1], by linarith [hy.2, ht1.2]⟩).continuousAt.continuousWithinAt)
    (fun y hy => h2 y ⟨by linarith [hy.1], by linarith [hy.2, ht1.2]⟩)
  refine ⟨ξ, ⟨hξ.1, by linarith [hξ.2, ht1.2]⟩, ?_⟩
  have hit : iteratedDeriv 2 C ξ = D2 ξ := by
    rw [iteratedDeriv_eq_iterate]; rfl
  rw [hit, hD2]
  have e2 : D1 (S + t1) - D1 S = K * (2 * t1) := by
    simp only [hg'] at hgt1; linarith
  have ed : S + t1 - S = t1 := by ring
  rw [e2, ed, hK]
  have : t1 ≠ 0 := ht1.1.ne'
  field_simp

/-- **Truncation plus rounding, for the central difference.** Let h > 0, let C have a
continuous third derivative on the bumped range from S - h to S + h, and let M₃ bound the
size of C''' inside that range. If the two computed prices Ĉ(S + h) and Ĉ(S - h) are each off
from the true prices by at most η, then the central difference of the computed prices is
within h^2 M₃/6 + η/h of the true derivative C'(S): a truncation part that shrinks with the
step and a rounding part that grows as the step shrinks. -/
theorem central_difference_total_error (C Ĉ : ℝ → ℝ) (S h η M₃ : ℝ) (hh : 0 < h)
    (hC : ContDiffOn ℝ 3 C (Icc (S - h) (S + h)))
    (hM : ∀ x ∈ Ioo (S - h) (S + h), |iteratedDeriv 3 C x| ≤ M₃)
    (hup : |Ĉ (S + h) - C (S + h)| ≤ η) (hdown : |Ĉ (S - h) - C (S - h)| ≤ η) :
    |(Ĉ (S + h) - Ĉ (S - h)) / (2 * h) - deriv C S| ≤ h ^ 2 * M₃ / 6 + η / h := by
  obtain ⟨ξ, hξ, he⟩ := central_difference_error C S h hh hC
  have hb := hM ξ hξ
  have key : (Ĉ (S + h) - Ĉ (S - h)) / (2 * h) - deriv C S =
      ((Ĉ (S + h) - C (S + h)) - (Ĉ (S - h) - C (S - h))) / (2 * h) +
        h ^ 2 / 6 * iteratedDeriv 3 C ξ := by
    rw [← he]; field_simp; ring
  rw [key]
  have h2 : 0 < 2 * h := by linarith
  have t1 : |((Ĉ (S + h) - C (S + h)) - (Ĉ (S - h) - C (S - h))) / (2 * h)| ≤ η / h := by
    rw [abs_div, abs_of_pos h2, div_le_div_iff₀ h2 hh]
    have := abs_sub (Ĉ (S + h) - C (S + h)) (Ĉ (S - h) - C (S - h))
    nlinarith
  have t2 : |h ^ 2 / 6 * iteratedDeriv 3 C ξ| ≤ h ^ 2 * M₃ / 6 := by
    rw [abs_mul, abs_of_nonneg (by positivity)]
    have : 0 ≤ h ^ 2 / 6 := by positivity
    nlinarith
  exact (abs_add_le _ _).trans (by linarith)

-- The kink: the expiry value max(S - 100, 0) bumped at S = 100. Forward gives 1 and central
-- gives 1/2, at a $1 bump and at a 1e-6 bump alike.
example : (max ((100 : ℚ) + 1 - 100) 0 - max ((100 : ℚ) - 100) 0) / 1 = 1 := by norm_num
example : (max ((100 : ℚ) + 1 - 100) 0 - max ((100 : ℚ) - 1 - 100) 0) / (2 * 1) = 1 / 2 := by
  norm_num
example : (max ((100 : ℚ) + 1 / 10 ^ 6 - 100) 0 - max ((100 : ℚ) - 100) 0) / (1 / 10 ^ 6) = 1 := by
  norm_num
example : (max ((100 : ℚ) + 1 / 10 ^ 6 - 100) 0 - max ((100 : ℚ) - 1 / 10 ^ 6 - 100) 0)
    / (2 * (1 / 10 ^ 6)) = 1 / 2 := by
  norm_num

-- Cent quotes, one-cent bump each way: one cent of quote change over a two-cent span is 1/2.
example : (1 / 100 : ℚ) / (2 * (1 / 100)) = 1 / 2 := by norm_num

#print axioms central_difference_error
#print axioms forward_difference_error
#print axioms central_difference_total_error
