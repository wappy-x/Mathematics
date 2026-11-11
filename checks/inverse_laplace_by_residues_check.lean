-- Inverting a Laplace transform: for a transform V made of finitely many simple poles left of the line Re s = c and falling like 1/|s|^2, the Bromwich integral up that line gives the residue sum of V(s)e^(st) for t > 0 and 0 for t < 0, and each residue is the limit of (s - a)V(s)e^(st).
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Filter Topology Complex

section IlrHelpers
open MeasureTheory
open scoped FourierTransform

lemma ilr_denom_ne {n : ℕ} (a : Fin n → ℂ) (c : ℝ) (hline : ∀ k, (a k).re < c) (ω : ℝ) (k : Fin n) :
    ((c : ℂ) + ω * I) - a k ≠ 0 := by
  intro h
  have := congrArg Complex.re h
  simp at this
  linarith [hline k]

lemma ilr_continuous {n : ℕ} (a A : Fin n → ℂ) (c : ℝ) (hline : ∀ k, (a k).re < c) :
    Continuous (fun ω : ℝ => ∑ k, A k / (((c : ℂ) + ω * I) - a k)) := by
  refine continuous_finsetSum _ fun k _ => ?_
  exact continuous_const.div (by fun_prop) (fun ω => ilr_denom_ne a c hline ω k)

lemma ilr_integrable {n : ℕ} (a A : Fin n → ℂ) (c : ℝ)
    (hline : ∀ k, (a k).re < c)
    (hfade : ∃ K R₀ : ℝ, ∀ s : ℂ, R₀ ≤ ‖s‖ → ‖∑ k, A k / (s - a k)‖ ≤ K / ‖s‖ ^ 2) :
    Integrable (fun ω : ℝ => ∑ k, A k / (((c : ℂ) + ω * I) - a k)) := by
  obtain ⟨K, R₀, hK⟩ := hfade
  refine (ilr_continuous a A c hline).locallyIntegrable.integrable_of_isBigO_cocompact
    (g := fun ω : ℝ => (1 + ω ^ 2)⁻¹) ?_ (integrable_inv_one_add_sq.integrableAtFilter _)
  apply Asymptotics.IsBigO.of_bound (2 * |K|)
  filter_upwards [tendsto_norm_cocompact_atTop.eventually_ge_atTop (max R₀ 1)] with ω hω
  have hω1 : 1 ≤ |ω| := le_trans (le_max_right _ _) (by simpa using hω)
  have hs : |ω| ≤ ‖(c : ℂ) + ω * I‖ := by
    simpa using Complex.abs_im_le_norm ((c : ℂ) + ω * I)
  have hR : R₀ ≤ ‖(c : ℂ) + ω * I‖ :=
    le_trans (le_max_left _ _) (le_trans (by simpa using hω) hs)
  have hpos : 0 < ω ^ 2 := by
    have : ω ≠ 0 := by rintro rfl; simp at hω1; linarith
    positivity
  have hsq : ω ^ 2 ≤ ‖(c : ℂ) + ω * I‖ ^ 2 := by
    rw [← sq_abs ω]; exact pow_le_pow_left₀ (abs_nonneg _) hs 2
  calc ‖∑ k, A k / (((c : ℂ) + ω * I) - a k)‖ ≤ K / ‖(c : ℂ) + ω * I‖ ^ 2 := hK _ hR
    _ ≤ |K| / ‖(c : ℂ) + ω * I‖ ^ 2 := by gcongr; exact le_abs_self K
    _ ≤ |K| / ω ^ 2 := by gcongr
    _ ≤ 2 * |K| * ‖(1 + ω ^ 2)⁻¹‖ := by
      rw [Real.norm_eq_abs, abs_of_pos (a := (1 + ω ^ 2)⁻¹) (by positivity)]
      have h2 : 1 ≤ ω ^ 2 := by nlinarith [sq_abs ω]
      rw [div_le_iff₀ hpos]
      have : 2 * (1 + ω ^ 2)⁻¹ * ω ^ 2 ≥ 1 := by
        rw [ge_iff_le, mul_assoc, mul_comm, mul_assoc, inv_mul_eq_div, le_div_iff₀ (by positivity)]
        nlinarith
      nlinarith [abs_nonneg K]

noncomputable def ilrG {n : ℕ} (a A : Fin n → ℂ) (c : ℝ) : ℝ → ℂ :=
  Set.indicator (Set.Ioi 0) (fun u : ℝ => ∑ k, A k * exp ((a k - c) * u))

lemma ilr_term_integrable {n : ℕ} (a A : Fin n → ℂ) (c : ℝ) (hline : ∀ k, (a k).re < c)
    (w : ℝ) (k : Fin n) :
    IntegrableOn (fun v : ℝ => A k * exp (((a k - c) - 2 * Real.pi * w * I) * v)) (Set.Ioi 0) := by
  refine (integrableOn_exp_mul_complex_Ioi ?_ 0).const_mul (A k)
  simp; linarith [hline k]

lemma ilr_G_integrable {n : ℕ} (a A : Fin n → ℂ) (c : ℝ) (hline : ∀ k, (a k).re < c) :
    Integrable (ilrG a A c) := by
  unfold ilrG
  rw [integrable_indicator_iff measurableSet_Ioi]
  refine integrable_finsetSum _ fun k _ => ?_
  have := ilr_term_integrable a A c hline 0 k
  simp only [Complex.ofReal_zero, mul_zero, zero_mul, sub_zero] at this
  exact this

lemma ilr_fourier_G {n : ℕ} (a A : Fin n → ℂ) (c : ℝ) (hline : ∀ k, (a k).re < c) (w : ℝ) :
    𝓕 (ilrG a A c) w = ∑ k, A k / (((c : ℂ) + ((2 * Real.pi * w : ℝ) : ℂ) * I) - a k) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  unfold ilrG
  have key : ∀ v : ℝ, exp (((-2 * Real.pi * v * w : ℝ) : ℂ) * I) •
      Set.indicator (Set.Ioi 0) (fun u : ℝ => ∑ k, A k * exp ((a k - c) * u)) v =
      Set.indicator (Set.Ioi 0)
        (fun v : ℝ => ∑ k, A k * exp (((a k - c) - 2 * Real.pi * w * I) * v)) v := by
    intro v
    by_cases hv : v ∈ Set.Ioi 0
    · rw [Set.indicator_of_mem hv, Set.indicator_of_mem hv, smul_eq_mul, Finset.mul_sum]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [mul_left_comm, ← exp_add]
      congr 2
      push_cast
      ring
    · rw [Set.indicator_of_notMem hv, Set.indicator_of_notMem hv, smul_zero]
  simp_rw [key]
  rw [integral_indicator measurableSet_Ioi, integral_finsetSum _
    (fun k _ => ilr_term_integrable a A c hline w k)]
  refine Finset.sum_congr rfl fun k _ => ?_
  have hre : ((a k - c) - 2 * Real.pi * w * I).re < 0 := by simp; linarith [hline k]
  have hne : ((a k - c) - 2 * Real.pi * w * I) ≠ 0 := by
    intro h; rw [h] at hre; simp at hre
  rw [integral_const_mul, integral_exp_mul_complex_Ioi hre 0]
  push_cast
  rw [mul_zero, exp_zero]
  have hne' : (c : ℂ) + 2 * Real.pi * w * I - a k ≠ 0 := by
    intro h; apply hne; linear_combination -h
  field_simp
  ring

lemma ilr_G_continuousAt {n : ℕ} (a A : Fin n → ℂ) (c t : ℝ) (ht : t ≠ 0) :
    ContinuousAt (ilrG a A c) t := by
  unfold ilrG
  rcases lt_or_gt_of_ne ht with h | h
  · refine (continuousAt_const (y := (0 : ℂ))).congr ?_
    filter_upwards [Iio_mem_nhds h] with u hu
    rw [Set.indicator_of_notMem (by simp at hu ⊢; linarith)]
  · have hc : ContinuousAt (fun u : ℝ => ∑ k, A k * exp ((a k - c) * u)) t := by fun_prop
    refine hc.congr ?_
    filter_upwards [Ioi_mem_nhds h] with u hu
    rw [Set.indicator_of_mem hu]

lemma ilr_F_integrable {n : ℕ} (a A : Fin n → ℂ) (c t : ℝ)
    (hline : ∀ k, (a k).re < c)
    (hfade : ∃ K R₀ : ℝ, ∀ s : ℂ, R₀ ≤ ‖s‖ → ‖∑ k, A k / (s - a k)‖ ≤ K / ‖s‖ ^ 2) :
    Integrable (fun ω : ℝ =>
      (∑ k, A k / (((c : ℂ) + ω * I) - a k)) * exp (((c : ℂ) + ω * I) * t)) := by
  refine (ilr_integrable a A c hline hfade).mul_bdd (c := Real.exp (c * t))
    (by fun_prop) (Eventually.of_forall fun ω => ?_)
  rw [Complex.norm_exp]
  simp

lemma ilr_core {n : ℕ} (a A : Fin n → ℂ) (c t : ℝ)
    (hline : ∀ k, (a k).re < c)
    (hfade : ∃ K R₀ : ℝ, ∀ s : ℂ, R₀ ≤ ‖s‖ → ‖∑ k, A k / (s - a k)‖ ≤ K / ‖s‖ ^ 2)
    (ht : t ≠ 0) :
    (1 / (2 * (Real.pi : ℂ))) * ∫ ω : ℝ,
      (∑ k, A k / (((c : ℂ) + ω * I) - a k)) * exp (((c : ℂ) + ω * I) * t) =
      exp ((c : ℂ) * t) * ilrG a A c t := by
  have hFG : 𝓕 (ilrG a A c) = fun w : ℝ =>
      ∑ k, A k / (((c : ℂ) + ((2 * Real.pi * w : ℝ) : ℂ) * I) - a k) :=
    funext (ilr_fourier_G a A c hline)
  have hint : Integrable (𝓕 (ilrG a A c)) := by
    rw [hFG]
    exact (ilr_integrable a A c hline hfade).comp_mul_left' (R := 2 * Real.pi)
      (by positivity)
  have inv := (ilr_G_integrable a A c hline).fourierInv_fourier_eq hint
    (ilr_G_continuousAt a A c t ht)
  rw [Real.fourierInv_eq', hFG] at inv
  have hcv := Measure.integral_comp_mul_left (fun ω : ℝ =>
      (∑ k, A k / (((c : ℂ) + ω * I) - a k)) * exp (((c : ℂ) + ω * I) * t)) (2 * Real.pi)
  have hpt : ∀ w : ℝ, (∑ k, A k / (((c : ℂ) + ((2 * Real.pi * w : ℝ) : ℂ) * I) - a k)) *
      exp (((c : ℂ) + ((2 * Real.pi * w : ℝ) : ℂ) * I) * t) =
      exp ((c : ℂ) * t) * (exp (((2 * Real.pi * inner ℝ w t : ℝ) : ℂ) * I) •
        ∑ k, A k / (((c : ℂ) + ((2 * Real.pi * w : ℝ) : ℂ) * I) - a k)) := by
    intro w
    rw [smul_eq_mul, ← mul_assoc, ← exp_add, mul_comm]
    congr 2
    simp
    ring
  simp only [hpt] at hcv inv
  rw [integral_const_mul, inv] at hcv
  have hpi : (0 : ℝ) < 2 * Real.pi := by positivity
  rw [abs_of_pos (inv_pos.mpr hpi), Complex.real_smul] at hcv
  rw [hcv]
  push_cast
  ring

#print axioms ilr_denom_ne
#print axioms ilr_continuous
#print axioms ilr_integrable
#print axioms ilrG
#print axioms ilr_term_integrable
#print axioms ilr_G_integrable
#print axioms ilr_fourier_G
#print axioms ilr_G_continuousAt
#print axioms ilr_F_integrable
#print axioms ilr_core

end IlrHelpers

/-- The card's main claim, for a transform V(s) = A₁/(s - a₁) + ... + Aₙ/(s - aₙ) with
finitely many simple poles aₖ (Mathlib has no general residue, so V is given by its poles and
their coefficients). If the line Re s = c sits right of every pole, V fades like K/|s|^2 for
large |s|, and t > 0, then the Bromwich integral (1/(2πi)) ∫ V(s)e^(st) ds up the line,
from c - iW to c + iW (so ds = i dω and the factor is 1/(2π)), tends as W grows to the sum of
the residues of V(s)e^(st): each pole aₖ hands back Aₖ e^(aₖ t). -/
theorem bromwich_integral_eq_residue_sum {n : ℕ} (a A : Fin n → ℂ) (c t : ℝ)
    (hline : ∀ k, (a k).re < c)
    (hfade : ∃ K R₀ : ℝ, ∀ s : ℂ, R₀ ≤ ‖s‖ → ‖∑ k, A k / (s - a k)‖ ≤ K / ‖s‖ ^ 2)
    (ht : 0 < t) :
    Tendsto (fun W : ℝ => (1 / (2 * (Real.pi : ℂ))) *
        ∫ ω in (-W)..W, (∑ k, A k / (((c : ℂ) + ω * I) - a k)) * exp (((c : ℂ) + ω * I) * t))
      atTop (𝓝 (∑ k, A k * exp (a k * t))) := by
  have hlim := (MeasureTheory.intervalIntegral_tendsto_integral (ilr_F_integrable a A c t hline hfade)
    tendsto_neg_atTop_atBot tendsto_id).const_mul (1 / (2 * (Real.pi : ℂ)))
  rw [ilr_core a A c t hline hfade ht.ne'] at hlim
  have hval : exp ((c : ℂ) * t) * ilrG a A c t = ∑ k, A k * exp (a k * t) := by
    unfold ilrG
    rw [Set.indicator_of_mem (show t ∈ Set.Ioi 0 from ht), Finset.mul_sum]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [mul_left_comm, ← exp_add]
    congr 2
    ring
  rw [hval] at hlim
  exact hlim

/-- The residue at a simple pole is a limit: if the poles a₁, ..., aₙ are distinct, then
(s - aⱼ) V(s) e^(st) tends to Aⱼ e^(aⱼ t) as s tends to aⱼ. -/
theorem residue_at_simple_pole_eq_limit {n : ℕ} (a A : Fin n → ℂ) (ha : Function.Injective a)
    (t : ℝ) (j : Fin n) :
    Tendsto (fun s : ℂ => (s - a j) * (∑ k, A k / (s - a k)) * exp (s * t))
      (𝓝[≠] (a j)) (𝓝 (A j * exp (a j * t))) := by
  have hlim : Tendsto (fun s : ℂ => (A j + ∑ k ∈ Finset.univ.erase j, (s - a j) * (A k / (s - a k)))
      * exp (s * t)) (𝓝 (a j)) (𝓝 (A j * exp (a j * t))) := by
    have h0 : Tendsto (fun s : ℂ => ∑ k ∈ Finset.univ.erase j, (s - a j) * (A k / (s - a k)))
        (𝓝 (a j)) (𝓝 (∑ k ∈ Finset.univ.erase j, (a j - a j) * (A k / (a j - a k)))) := by
      apply tendsto_finsetSum
      intro k hk
      have hkj : a j - a k ≠ 0 := by
        rw [sub_ne_zero]
        intro h
        exact (Finset.ne_of_mem_erase hk) (ha h).symm
      exact ((tendsto_id.sub tendsto_const_nhds).mul
        (tendsto_const_nhds.div (tendsto_id.sub tendsto_const_nhds) hkj))
    simp only [sub_self, zero_mul, Finset.sum_const_zero] at h0
    have h1 : Tendsto (fun s : ℂ => exp (s * t)) (𝓝 (a j)) (𝓝 (exp (a j * t))) :=
      ((continuous_exp.comp (continuous_id.mul continuous_const)).tendsto (a j))
    simpa using (tendsto_const_nhds.add h0).mul h1
  refine (hlim.mono_left nhdsWithin_le_nhds).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with s hs
  have hs' : s - a j ≠ 0 := sub_ne_zero.mpr hs
  rw [Finset.mul_sum, ← Finset.add_sum_erase _ _ (Finset.mem_univ j), mul_div_cancel₀ _ hs']

/-- Before the switch the signal is 0: under the same conditions but with t < 0, the
Bromwich integral up the line tends to 0 (close the line to the right, where there are no
poles). -/
theorem bromwich_integral_eq_zero_of_neg {n : ℕ} (a A : Fin n → ℂ) (c t : ℝ)
    (hline : ∀ k, (a k).re < c)
    (hfade : ∃ K R₀ : ℝ, ∀ s : ℂ, R₀ ≤ ‖s‖ → ‖∑ k, A k / (s - a k)‖ ≤ K / ‖s‖ ^ 2)
    (ht : t < 0) :
    Tendsto (fun W : ℝ => (1 / (2 * (Real.pi : ℂ))) *
        ∫ ω in (-W)..W, (∑ k, A k / (((c : ℂ) + ω * I) - a k)) * exp (((c : ℂ) + ω * I) * t))
      atTop (𝓝 0) := by
  have hlim := (MeasureTheory.intervalIntegral_tendsto_integral (ilr_F_integrable a A c t hline hfade)
    tendsto_neg_atTop_atBot tendsto_id).const_mul (1 / (2 * (Real.pi : ℂ)))
  rw [ilr_core a A c t hline hfade ht.ne] at hlim
  have hval : exp ((c : ℂ) * t) * ilrG a A c t = 0 := by
    unfold ilrG
    rw [Set.indicator_of_notMem (show t ∉ Set.Ioi 0 by simp; linarith), mul_zero]
  rw [hval] at hlim
  exact hlim

-- Worked numbers for V(s) = 2/(s(s + 2)), poles 0 and -2.
-- Residue at 0 at t = 0: 2/(0 - (-2)) = 1; residue at -2: 2/(-2 - 0) = -1.
example : (2 : ℚ) / (0 - (-2)) = 1 := by norm_num
example : (2 : ℚ) / (-2 - 0) = -1 := by norm_num
-- With e^(st) dropped, the residues of V alone sum to 0.
example : (1 : ℚ) + (-1) = 0 := by norm_num
-- Partial fractions A = 1, B = -1 match V at s = 1 and s = 3: V(1) = 2/3, V(3) = 2/15.
example : (1 : ℚ) / 1 + (-1) / (1 + 2) = 2 / (1 * (1 + 2)) := by norm_num
example : (1 : ℚ) / 3 + (-1) / (3 + 2) = 2 / (3 * (3 + 2)) := by norm_num
example : (2 : ℚ) / (1 * (1 + 2)) = 2 / 3 := by norm_num
-- The figure: 25 units per 1, 0 at x = 220, so -2 at 170, Re s = 1 at 245, arc radius 4 is
-- 100 units, and the arc's leftmost point is at 145.
example : (220 : ℤ) + 25 * (-2) = 170 := by norm_num
example : (220 : ℤ) + 25 * 1 = 245 := by norm_num
example : (25 : ℤ) * 4 = 100 ∧ (245 : ℤ) - 100 = 145 := by norm_num

#print axioms bromwich_integral_eq_residue_sum
#print axioms residue_at_simple_pole_eq_limit
#print axioms bromwich_integral_eq_zero_of_neg
