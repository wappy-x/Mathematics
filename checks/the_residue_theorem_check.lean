-- The residue theorem: the integral of a function, holomorphic except at finitely many isolated points, once anticlockwise round a circle that passes through none of them equals 2πi times the sum of the residues (the 1/(z - a) Laurent coefficients) at the points inside, a general loop weights each residue by its winding number, and a small circle round one point keeps only that point's 1/(z - a) term.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Complex.HasPrimitives
import Mathlib.Analysis.Complex.LocallyUniformLimit
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Analysis.Calculus.Deriv.ZPow
import Mathlib.Analysis.Normed.Group.FunctionSeries

namespace TheResidueTheorem

open Complex MeasureTheory Metric Set

/-- The regular part of a Laurent series. -/
noncomputable def Rser (c : ℤ → ℂ) (a z : ℂ) : ℂ := ∑' n : ℕ, c n * (z - a) ^ n

/-- The principal part of a Laurent series. -/
noncomputable def Pser (c : ℤ → ℂ) (a z : ℂ) : ℂ :=
  ∑' k : ℕ, c (-((k : ℤ) + 1)) * (z - a) ^ (-((k : ℤ) + 1))

lemma negSucc_injective : Function.Injective (fun k : ℕ ↦ -((k : ℤ) + 1)) := by
  intro x y hxy
  simp only [neg_inj, add_left_inj, Nat.cast_inj] at hxy
  exact hxy

lemma summable_of_laurent {f : ℂ → ℂ} {a : ℂ} {c : ℤ → ℂ} {r : ℝ}
    (hL : ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    {s : ℝ} (hs : 0 < s) (hsr : s < r) : Summable fun n : ℤ ↦ ‖c n‖ * s ^ n := by
  have h := (hL (a + s) (by simp [abs_of_pos hs, hs])
    (by simpa [abs_of_pos hs] using hsr)).summable
  rw [← summable_norm_iff] at h
  convert h using 2 with n
  simp [norm_zpow, abs_of_pos hs]

lemma summable_neg_part {c : ℤ → ℂ} {s : ℝ} (h : Summable fun n : ℤ ↦ ‖c n‖ * s ^ n) :
    Summable fun k : ℕ ↦ ‖c (-((k : ℤ) + 1))‖ * s ^ (-((k : ℤ) + 1)) :=
  h.comp_injective negSucc_injective

lemma summable_pos_part {c : ℤ → ℂ} {s : ℝ} (h : Summable fun n : ℤ ↦ ‖c n‖ * s ^ n) :
    Summable fun n : ℕ ↦ ‖c n‖ * s ^ n := by
  have := h.comp_injective Nat.cast_injective
  convert this using 2 with n
  simp [Function.comp, zpow_natCast]

lemma norm_neg_term_le {c : ℤ → ℂ} {a w : ℂ} {s : ℝ} (hs : 0 < s) (hw : s ≤ ‖w - a‖) (k : ℕ) :
    ‖c (-((k : ℤ) + 1)) * (w - a) ^ (-((k : ℤ) + 1))‖
      ≤ ‖c (-((k : ℤ) + 1))‖ * s ^ (-((k : ℤ) + 1)) := by
  rw [norm_mul, norm_zpow]
  apply mul_le_mul_of_nonneg_left _ (norm_nonneg _)
  have : (-((k : ℤ) + 1)) = -(((k + 1 : ℕ)) : ℤ) := by push_cast; ring
  rw [this, zpow_neg, zpow_neg, zpow_natCast, zpow_natCast]
  exact inv_anti₀ (pow_pos hs _) (pow_le_pow_left₀ hs.le hw _)

lemma Rser_differentiableAt {c : ℤ → ℂ} {a : ℂ} {r : ℝ}
    (hsum : ∀ s, 0 < s → s < r → Summable fun n : ℤ ↦ ‖c n‖ * s ^ n) {z : ℂ}
    (hz : ‖z - a‖ < r) : DifferentiableAt ℂ (Rser c a) z := by
  have h0 := norm_nonneg (z - a)
  set s := (‖z - a‖ + r) / 2 with hs_def
  have hs0 : 0 < s := by rw [hs_def]; linarith
  have hsr : s < r := by rw [hs_def]; linarith
  have hzs : ‖z - a‖ < s := by rw [hs_def]; linarith
  have hD : DifferentiableOn ℂ (fun w ↦ ∑' n : ℕ, c n * (w - a) ^ n) (ball a s) := by
    refine differentiableOn_tsum_of_summable_norm (summable_pos_part (hsum s hs0 hsr)) ?_
      isOpen_ball ?_
    · intro n; fun_prop
    · intro n w hw
      rw [mem_ball, dist_eq_norm] at hw
      rw [norm_mul, norm_pow]
      exact mul_le_mul_of_nonneg_left (pow_le_pow_left₀ (norm_nonneg _) hw.le n) (norm_nonneg _)
  exact hD.differentiableAt (isOpen_ball.mem_nhds (by rwa [mem_ball, dist_eq_norm]))

lemma Pser_differentiableAt {c : ℤ → ℂ} {a : ℂ} {r : ℝ} (hr : 0 < r)
    (hsum : ∀ s, 0 < s → s < r → Summable fun n : ℤ ↦ ‖c n‖ * s ^ n) {z : ℂ}
    (hz : z ≠ a) : DifferentiableAt ℂ (Pser c a) z := by
  have hz' : 0 < ‖z - a‖ := norm_pos_iff.2 (sub_ne_zero.2 hz)
  set s := min (‖z - a‖ / 2) (r / 2) with hs_def
  have hs0 : 0 < s := lt_min (by linarith) (by linarith)
  have hsr : s < r := (min_le_right _ _).trans_lt (by linarith)
  have hzs : s < ‖z - a‖ := (min_le_left _ _).trans_lt (by linarith)
  have hU : IsOpen {w : ℂ | s < ‖w - a‖} := isOpen_lt continuous_const (by fun_prop)
  have hD : DifferentiableOn ℂ
      (fun w ↦ ∑' k : ℕ, c (-((k : ℤ) + 1)) * (w - a) ^ (-((k : ℤ) + 1)))
      {w : ℂ | s < ‖w - a‖} := by
    refine differentiableOn_tsum_of_summable_norm (summable_neg_part (hsum s hs0 hsr)) ?_ hU ?_
    · intro k w hw
      have hw' : s < ‖w - a‖ := hw
      have : w - a ≠ 0 := by
        intro h; rw [h, norm_zero] at hw'; linarith
      apply DifferentiableAt.differentiableWithinAt
      apply DifferentiableAt.const_mul
      exact (differentiableAt_id.sub_const a).zpow (Or.inl this)
    · intro k w hw; exact norm_neg_term_le hs0 (le_of_lt hw) k
  exact hD.differentiableAt (hU.mem_nhds hzs)

lemma laurent_split {f : ℂ → ℂ} {a : ℂ} {c : ℤ → ℂ} {r : ℝ}
    (hL : ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    {z : ℂ} (h0 : 0 < ‖z - a‖) (h1 : ‖z - a‖ < r) :
    f z = Rser c a z + Pser c a z := by
  have h := hL z h0 h1
  have hs := h.summable
  have h1' : Summable fun n : ℕ ↦ c n * (z - a) ^ (n : ℤ) :=
    hs.comp_injective Nat.cast_injective
  have h2' : Summable fun n : ℕ ↦ c (-((n : ℤ) + 1)) * (z - a) ^ (-((n : ℤ) + 1)) :=
    hs.comp_injective negSucc_injective
  have := tsum_of_nat_of_neg_add_one (f := fun n : ℤ ↦ c n * (z - a) ^ n) h1' h2'
  rw [← h.tsum_eq, this]
  unfold Rser Pser
  simp only [zpow_natCast]

lemma intervalIntegrable_mul_deriv {γ' F : ℝ → ℂ} {T : ℝ} (hT : 0 ≤ T)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hF : ContinuousOn F (Icc 0 T)) :
    IntervalIntegrable (fun t ↦ F t * γ' t) volume 0 T :=
  hγ'.continuousOn_mul (by rwa [uIcc_of_le hT])

lemma loop_integral_primitive {G g : ℂ → ℂ} {U : Set ℂ} (hG : ∀ z ∈ U, HasDerivAt G (g z) z)
    (hgc : ContinuousOn g U)
    {γ γ' : ℝ → ℂ} {T : ℝ} {E : Finset ℝ} (hT : 0 ≤ T) (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T)
    (hU : ∀ t ∈ Icc 0 T, γ t ∈ U) :
    ∫ t in (0 : ℝ)..T, g (γ t) * γ' t = 0 := by
  have hGc : ContinuousOn (fun t ↦ G (γ t)) (Icc 0 T) := by
    intro t ht
    exact (hG _ (hU t ht)).continuousAt.comp_continuousWithinAt (hγ t ht)
  have key := integral_eq_of_hasDerivAt_off_countable_of_le (fun t ↦ G (γ t))
    (fun t ↦ g (γ t) * γ' t) hT E.finite_toSet.countable hGc ?_
    (intervalIntegrable_mul_deriv hT hγ' (hgc.comp hγ (fun t ht ↦ hU t ht)))
  · rw [key, hclosed, sub_self]
  · intro t ht
    have ht' : t ∈ Icc 0 T := Ioo_subset_Icc_self ht.1
    exact (hG _ (hU t ht')).comp t (hderiv t ht)

lemma zpow_primitive (d b : ℂ) (m : ℤ) (hm : m ≠ -1) :
    ∀ z ∈ {z : ℂ | z ≠ b}, HasDerivAt (fun z ↦ d * (z - b) ^ (m + 1) / ((m : ℂ) + 1))
      (d * (z - b) ^ m) z := by
  intro z hz
  have hz' : z - b ≠ 0 := sub_ne_zero.2 hz
  have hm' : ((m : ℂ) + 1) ≠ 0 := by
    have : ((m + 1 : ℤ) : ℂ) ≠ 0 := Int.cast_ne_zero.2 (by omega)
    push_cast at this; exact this
  have h1 := ((hasDerivAt_zpow (m + 1) (z - b) (Or.inl hz')).comp z
    ((hasDerivAt_id z).sub_const b)).const_mul d |>.div_const ((m : ℂ) + 1)
  convert h1 using 1
  · rfl
  · rw [show m + 1 - 1 = m by ring]
    push_cast
    field_simp

lemma zpow_continuousOn (d b : ℂ) (m : ℤ) :
    ContinuousOn (fun z ↦ d * (z - b) ^ m) {z : ℂ | z ≠ b} := by
  intro z hz
  exact (continuousAt_const.mul ((continuousAt_id.sub continuousAt_const).zpow₀ m
    (Or.inl (sub_ne_zero.2 hz)))).continuousWithinAt

lemma loop_tsum_zero {γ γ' : ℝ → ℂ} {T : ℝ} {E : Finset ℝ} (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T) (b : ℂ)
    (hoff : ∀ t ∈ Icc 0 T, γ t ≠ b)
    (d : ℕ → ℂ) (e : ℕ → ℤ) (he : ∀ k, e k ≠ -1) (u : ℕ → ℝ) (hu : Summable u)
    (hb : ∀ k, ∀ t ∈ Icc 0 T, ‖d k * (γ t - b) ^ e k‖ ≤ u k) :
    ∫ t in (0 : ℝ)..T, (∑' k, d k * (γ t - b) ^ e k) * γ' t = 0 := by
  have hcont : ∀ k, ContinuousOn (fun t ↦ d k * (γ t - b) ^ e k) (Icc 0 T) := fun k ↦
    (zpow_continuousOn (d k) b (e k)).comp hγ (fun t ht ↦ hoff t ht)
  have hint : ∀ k, IntervalIntegrable (fun t ↦ d k * (γ t - b) ^ e k * γ' t) volume 0 T :=
    fun k ↦ intervalIntegrable_mul_deriv hT hγ' (hcont k)
  have hzero : ∀ k, ∫ t in (0 : ℝ)..T, d k * (γ t - b) ^ e k * γ' t = 0 := fun k ↦
    loop_integral_primitive (g := fun z ↦ d k * (z - b) ^ e k) (zpow_primitive (d k) b (e k) (he k))
      (zpow_continuousOn (d k) b (e k)) hT hγ hderiv hγ' hclosed hoff
  have hIcc : ∀ t ∈ uIoc (0 : ℝ) T, t ∈ Icc 0 T := by
    intro t ht; rw [uIoc_of_le hT] at ht; exact Ioc_subset_Icc_self ht
  have hsum := intervalIntegral.hasSum_integral_of_dominated_convergence
    (F := fun k t ↦ d k * (γ t - b) ^ e k * γ' t)
    (f := fun t ↦ (∑' k, d k * (γ t - b) ^ e k) * γ' t)
    (fun k t ↦ u k * ‖γ' t‖) (fun k ↦ (hint k).def'.aestronglyMeasurable) ?_ ?_ ?_ ?_
  · simp only [hzero] at hsum
    exact hsum.unique hasSum_zero
  · refine fun k ↦ Filter.Eventually.of_forall fun t ht ↦ ?_
    rw [norm_mul]
    exact mul_le_mul_of_nonneg_right (hb k t (hIcc t ht)) (norm_nonneg _)
  · exact Filter.Eventually.of_forall fun t _ ↦ hu.mul_right _
  · simp_rw [tsum_mul_right]
    exact hγ'.norm.const_mul _
  · refine Filter.Eventually.of_forall fun t ht ↦ ?_
    exact (Summable.of_norm_bounded hu (fun k ↦ hb k t (hIcc t ht))).hasSum.mul_right _

lemma loop_Pser {γ γ' : ℝ → ℂ} {T : ℝ} {E : Finset ℝ} (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T) (b : ℂ)
    (hoff : ∀ t ∈ Icc 0 T, γ t ≠ b) (c : ℤ → ℂ) {r : ℝ} (hr : 0 < r)
    (hsum : ∀ s, 0 < s → s < r → Summable fun n : ℤ ↦ ‖c n‖ * s ^ n) :
    ∫ t in (0 : ℝ)..T, Pser c b (γ t) * γ' t
      = c (-1) * ∫ t in (0 : ℝ)..T, γ' t / (γ t - b) := by
  obtain ⟨t0, ht0, hmin⟩ := isCompact_Icc.exists_isMinOn (nonempty_Icc.2 hT)
    ((hγ.sub continuousOn_const).norm)
  have hδ : 0 < ‖γ t0 - b‖ := norm_pos_iff.2 (sub_ne_zero.2 (hoff t0 ht0))
  set s := min ‖γ t0 - b‖ (r / 2) with hs_def
  have hs0 : 0 < s := lt_min hδ (by linarith)
  have hsr : s < r := (min_le_right _ _).trans_lt (by linarith)
  have hsγ : ∀ t ∈ Icc 0 T, s ≤ ‖γ t - b‖ := fun t ht ↦ (min_le_left _ _).trans (hmin ht)
  have hS := summable_neg_part (hsum s hs0 hsr)
  have hS1 := hS.comp_injective (add_left_injective 1)
  set d : ℕ → ℂ := fun k ↦ c (-(((k + 1 : ℕ) : ℤ) + 1)) with hd_def
  set e : ℕ → ℤ := fun k ↦ -(((k + 1 : ℕ) : ℤ) + 1) with he_def
  have hsplit : ∀ t ∈ Icc 0 T, Pser c b (γ t) * γ' t
      = c (-1) * (γ t - b)⁻¹ * γ' t + (∑' k, d k * (γ t - b) ^ e k) * γ' t := by
    intro t ht
    have hsm : Summable fun k : ℕ ↦ c (-((k : ℤ) + 1)) * (γ t - b) ^ (-((k : ℤ) + 1)) :=
      Summable.of_norm_bounded hS (fun k ↦ norm_neg_term_le hs0 (hsγ t ht) k)
    unfold Pser
    rw [hsm.tsum_eq_zero_add, add_mul]
    congr 1
    simp
  rw [intervalIntegral.integral_congr (fun t ht ↦ hsplit t (by rwa [uIcc_of_le hT] at ht))]
  have hc1 : ContinuousOn (fun t ↦ c (-1) * (γ t - b)⁻¹) (Icc 0 T) := by
    intro t ht
    exact continuousWithinAt_const.mul
      (((hγ t ht).sub continuousWithinAt_const).inv₀ (sub_ne_zero.2 (hoff t ht)))
  have hb : ∀ k, ∀ t ∈ Icc 0 T, ‖d k * (γ t - b) ^ e k‖
      ≤ ‖c (-(((k + 1 : ℕ) : ℤ) + 1))‖ * s ^ (-(((k + 1 : ℕ) : ℤ) + 1)) :=
    fun k t ht ↦ norm_neg_term_le hs0 (hsγ t ht) (k + 1)
  have hc2 : ContinuousOn (fun t ↦ ∑' k, d k * (γ t - b) ^ e k) (Icc 0 T) :=
    continuousOn_tsum (fun k ↦ (zpow_continuousOn (d k) b (e k)).comp hγ (fun t ht ↦ hoff t ht))
      hS1 hb
  rw [intervalIntegral.integral_add (intervalIntegrable_mul_deriv hT hγ' hc1)
    (intervalIntegrable_mul_deriv hT hγ' hc2)]
  rw [loop_tsum_zero hT hγ hderiv hγ' hclosed b hoff d e ?_ _ hS1 hb, add_zero]
  · rw [← intervalIntegral.integral_const_mul]
    congr 1; funext t; ring
  · intro k; simp only [he_def]; omega

lemma decomp (f : ℂ → ℂ) (S : Finset ℂ) (coeff : ℂ → ℤ → ℂ)
    (hlaurent : ∀ a ∈ S, ∃ r > 0, ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ coeff a n * (z - a) ^ n) (f z)) :
    ∃ g : ℂ → ℂ, (∀ z, z ∉ S → f z = g z + ∑ b ∈ S, Pser (coeff b) b z) ∧
      (∀ z, (z ∈ S ∨ DifferentiableAt ℂ f z) → DifferentiableAt ℂ g z) := by
  classical
  choose! r hr hL using hlaurent
  have hsum : ∀ b ∈ S, ∀ s, 0 < s → s < r b → Summable fun n : ℤ ↦ ‖coeff b n‖ * s ^ n :=
    fun b hb s hs hsr ↦ summable_of_laurent (hL b hb) hs hsr
  have hPd : ∀ b ∈ S, ∀ z, z ≠ b → DifferentiableAt ℂ (Pser (coeff b) b) z :=
    fun b hb z hz ↦ Pser_differentiableAt (hr b hb) (hsum b hb) hz
  refine ⟨fun z ↦ if z ∈ S then Rser (coeff z) z z - ∑ b ∈ S.erase z, Pser (coeff b) b z
    else f z - ∑ b ∈ S, Pser (coeff b) b z, ?_, ?_⟩
  · intro z hz; simp [hz]
  · intro z hz
    by_cases hzS : z ∈ S
    · have hd : DifferentiableAt ℂ
          (fun w ↦ Rser (coeff z) z w - ∑ b ∈ S.erase z, Pser (coeff b) b w) z := by
        apply DifferentiableAt.sub
        · exact Rser_differentiableAt (hsum z hzS) (by simpa using hr z hzS)
        · exact DifferentiableAt.fun_sum fun b hb ↦
            hPd b (Finset.mem_of_mem_erase hb) z (Finset.ne_of_mem_erase hb).symm
      apply hd.congr_of_eventuallyEq
      have hopen : IsOpen (ball z (r z) ∩ ((S.erase z : Set ℂ))ᶜ) :=
        isOpen_ball.inter (S.erase z).finite_toSet.isClosed.isOpen_compl
      filter_upwards [hopen.mem_nhds ⟨mem_ball_self (hr z hzS), by simp⟩] with w hw
      by_cases hwz : w = z
      · subst hwz; simp [hzS]
      · have hwS : w ∉ S := fun hwS ↦ hw.2 (Finset.mem_erase.2 ⟨hwz, hwS⟩)
        have h0 : 0 < ‖w - z‖ := norm_pos_iff.2 (sub_ne_zero.2 hwz)
        have h1 : ‖w - z‖ < r z := by simpa [dist_eq_norm] using hw.1
        simp only [hwS, ite_false]
        rw [laurent_split (hL z hzS) h0 h1, ← Finset.add_sum_erase S _ hzS]
        ring
    · have hf := hz.resolve_left hzS
      have hd : DifferentiableAt ℂ (fun w ↦ f w - ∑ b ∈ S, Pser (coeff b) b w) z :=
        hf.sub (DifferentiableAt.fun_sum fun b hb ↦ hPd b hb z (fun h ↦ hzS (h ▸ hb)))
      apply hd.congr_of_eventuallyEq
      filter_upwards [S.finite_toSet.isClosed.isOpen_compl.mem_nhds hzS] with w hw
      have hw' : w ∉ S := hw
      simp [hw']

lemma circle_eq_loop (F : ℂ → ℂ) (c : ℂ) (R : ℝ) :
    (∮ z in C(c, R), F z)
      = ∫ θ in (0 : ℝ)..2 * Real.pi, F (circleMap c R θ) * deriv (circleMap c R) θ := by
  unfold circleIntegral
  congr 1; funext θ; rw [smul_eq_mul, mul_comm]

lemma circle_Pser {c b : ℂ} {R : ℝ} (hb : b ∈ ball c R) (d : ℤ → ℂ) {r : ℝ} (hr : 0 < r)
    (hsum : ∀ s, 0 < s → s < r → Summable fun n : ℤ ↦ ‖d n‖ * s ^ n) :
    (∮ z in C(c, R), Pser d b z) = 2 * Real.pi * I * d (-1) := by
  have hR : 0 < R := dist_nonneg.trans_lt hb
  have hoff : ∀ θ, circleMap c R θ ≠ b := by
    intro θ h
    have := circleMap_mem_sphere c hR.le θ
    rw [h, mem_sphere] at this; rw [mem_ball] at hb; linarith
  have hγ' : IntervalIntegrable (deriv (circleMap c R)) volume 0 (2 * Real.pi) := by
    have : deriv (circleMap c R) = fun θ ↦ circleMap 0 R θ * I := funext (deriv_circleMap c R)
    rw [this]; exact ((continuous_circleMap 0 R).mul continuous_const).intervalIntegrable _ _
  have key := loop_Pser (E := ∅) (by positivity) (continuous_circleMap c R).continuousOn
    (fun t _ ↦ by rw [deriv_circleMap]; exact hasDerivAt_circleMap c R t) hγ'
    (by simpa using (periodic_circleMap c R 0).symm) b (fun t _ ↦ hoff t) d hr hsum
  have hinv := circleIntegral.integral_sub_inv_of_mem_ball hb
  rw [circle_eq_loop] at hinv ⊢
  rw [key, mul_comm]
  congr 1
  rw [← hinv]; congr 1; funext θ; rw [div_eq_inv_mul]

lemma circle_sum {c : ℂ} {R : ℝ} (S : Finset ℂ) (F : ℂ → ℂ → ℂ)
    (h : ∀ b ∈ S, CircleIntegrable (F b) c R) :
    (∮ z in C(c, R), ∑ b ∈ S, F b z) = ∑ b ∈ S, ∮ z in C(c, R), F b z := by
  unfold circleIntegral
  simp_rw [Finset.smul_sum]
  exact intervalIntegral.integral_finsetSum fun b hb ↦ (h b hb).out

#print axioms negSucc_injective
#print axioms summable_of_laurent
#print axioms summable_neg_part
#print axioms summable_pos_part
#print axioms norm_neg_term_le
#print axioms Rser_differentiableAt
#print axioms Pser_differentiableAt
#print axioms laurent_split
#print axioms intervalIntegrable_mul_deriv
#print axioms loop_integral_primitive
#print axioms zpow_primitive
#print axioms zpow_continuousOn
#print axioms loop_tsum_zero
#print axioms loop_Pser
#print axioms decomp
#print axioms circle_eq_loop
#print axioms circle_Pser
#print axioms circle_sum

/-- The winding number n(γ, a) of a loop γ(t), 0 ≤ t ≤ T, with velocity γ'(t), round the point a:
the integral of dz/(z − a) once round the loop, divided by 2πi. -/
noncomputable def windingNumber (γ γ' : ℝ → ℂ) (T : ℝ) (a : ℂ) : ℂ :=
  (2 * Real.pi * I)⁻¹ * ∫ t in (0 : ℝ)..T, γ' t / (γ t - a)

/-- The card's main claim. Let the loop be the circle of radius R > 0 round c, run once
anticlockwise. Let f be holomorphic (have a complex derivative) at every point on and inside the
circle except at finitely many points (the finite set S), none of them on the circle itself. Near
each such point a, f equals its Laurent series ∑ coeff a n · (z − a)ⁿ over all whole numbers n on
some punctured disc 0 < |z − a| < r; the residue Res(f, a) is the coefficient of 1/(z − a), that
is coeff a (−1). Then the integral of f round the circle is 2πi times the sum of the residues at
the points inside. -/
theorem circle_integral_eq_two_pi_I_mul_sum_residues
    (f : ℂ → ℂ) (c : ℂ) (R : ℝ) (hR : 0 < R) (S : Finset ℂ)
    (hS : (S : Set ℂ) ⊆ ball c R)
    (hf : ∀ z ∈ closedBall c R \ (S : Set ℂ), DifferentiableAt ℂ f z)
    (coeff : ℂ → ℤ → ℂ)
    (hlaurent : ∀ a ∈ S, ∃ r > 0, ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ coeff a n * (z - a) ^ n) (f z)) :
    (∮ z in C(c, R), f z) = 2 * Real.pi * I * ∑ a ∈ S, coeff a (-1) := by
  obtain ⟨g, hfg, hgd⟩ := decomp f S coeff hlaurent
  choose! r hr hL using hlaurent
  have hsum : ∀ b ∈ S, ∀ s, 0 < s → s < r b → Summable fun n : ℤ ↦ ‖coeff b n‖ * s ^ n :=
    fun b hb s hs hsr ↦ summable_of_laurent (hL b hb) hs hsr
  have hsph : ∀ z ∈ sphere c R, z ∉ S := by
    intro z hz hzS
    have h1 := hS hzS
    rw [mem_ball] at h1; rw [mem_sphere] at hz; linarith
  have hgD : ∀ z ∈ closedBall c R, DifferentiableAt ℂ g z := by
    intro z hz
    by_cases hzS : z ∈ S
    · exact hgd z (Or.inl hzS)
    · exact hgd z (Or.inr (hf z ⟨hz, hzS⟩))
  have hPc : ∀ b ∈ S, ContinuousOn (Pser (coeff b) b) (sphere c R) := by
    intro b hb z hz
    exact (Pser_differentiableAt (hr b hb) (hsum b hb)
      (fun h ↦ hsph z hz (by rw [h]; exact hb))).continuousAt.continuousWithinAt
  have hgc : ContinuousOn g (closedBall c R) :=
    fun z hz ↦ (hgD z hz).continuousAt.continuousWithinAt
  have hsumc : ContinuousOn (fun z ↦ ∑ b ∈ S, Pser (coeff b) b z) (sphere c R) :=
    continuousOn_finsetSum S hPc
  rw [circleIntegral.integral_congr (g := fun z ↦ g z + ∑ b ∈ S, Pser (coeff b) b z) hR.le
      (fun z hz ↦ hfg z (hsph z hz)),
    circleIntegral.integral_add ((hgc.mono sphere_subset_closedBall).circleIntegrable hR.le)
      (hsumc.circleIntegrable hR.le),
    circleIntegral_eq_zero_of_differentiable_on_off_countable hR.le countable_empty hgc
      (fun z hz ↦ hgD z (ball_subset_closedBall hz.1)), zero_add,
    circle_sum S _ (fun b hb ↦ (hPc b hb).circleIntegrable hR.le), Finset.mul_sum]
  exact Finset.sum_congr rfl fun b hb ↦ circle_Pser (hS hb) (coeff b) (hr b hb) (hsum b hb)

/-- Winding numbers count. Let f be holomorphic on an open disc except at finitely many points
(the finite set S) inside it, with residue coeff a (−1) at each such point a as above. Let γ(t),
0 ≤ t ≤ T, be a closed loop in the disc made of finitely many smooth pieces (velocity γ' off a
finite set of corners) that passes through none of those points. Then the integral of f round γ is
2πi times the sum of the residues, each weighted by the winding number n(γ, a): each point pays
its toll once per anticlockwise turn round it. -/
theorem loop_integral_eq_two_pi_I_mul_sum_winding_number_mul_residue
    (f : ℂ → ℂ) (c : ℂ) (R : ℝ) (S : Finset ℂ)
    (hS : (S : Set ℂ) ⊆ ball c R)
    (hf : DifferentiableOn ℂ f (ball c R \ (S : Set ℂ)))
    (coeff : ℂ → ℤ → ℂ)
    (hlaurent : ∀ a ∈ S, ∃ r > 0, ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ coeff a n * (z - a) ^ n) (f z))
    (γ γ' : ℝ → ℂ) (T : ℝ) (E : Finset ℝ) (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T)
    (hclosed : γ 0 = γ T)
    (hin : ∀ t ∈ Icc 0 T, γ t ∈ ball c R)
    (hoff : ∀ t ∈ Icc 0 T, γ t ∉ S) :
    ∫ t in (0 : ℝ)..T, f (γ t) * γ' t
      = 2 * Real.pi * I * ∑ a ∈ S, windingNumber γ γ' T a * coeff a (-1) := by
  obtain ⟨g, hfg, hgd⟩ := decomp f S coeff hlaurent
  choose! r hr hL using hlaurent
  have hsum : ∀ b ∈ S, ∀ s, 0 < s → s < r b → Summable fun n : ℤ ↦ ‖coeff b n‖ * s ^ n :=
    fun b hb s hs hsr ↦ summable_of_laurent (hL b hb) hs hsr
  have hgD : ∀ z ∈ ball c R, DifferentiableAt ℂ g z := by
    intro z hz
    by_cases hzS : z ∈ S
    · exact hgd z (Or.inl hzS)
    · exact hgd z (Or.inr (hf.differentiableAt
        ((isOpen_ball.sdiff S.finite_toSet.isClosed).mem_nhds ⟨hz, hzS⟩)))
  obtain ⟨G, hG⟩ := DifferentiableOn.isExactOn_ball
    (fun z hz ↦ (hgD z hz).differentiableWithinAt : DifferentiableOn ℂ g (ball c R))
  have hgc : ContinuousOn g (ball c R) := fun z hz ↦ (hgD z hz).continuousAt.continuousWithinAt
  have hPc : ∀ b ∈ S, ContinuousOn (fun t ↦ Pser (coeff b) b (γ t)) (Icc 0 T) := by
    intro b hb t ht
    exact (Pser_differentiableAt (hr b hb) (hsum b hb)
      (fun h ↦ hoff t ht (by rw [h]; exact hb))).continuousAt.comp_continuousWithinAt (hγ t ht)
  have hcongr : EqOn (fun t ↦ f (γ t) * γ' t)
      (fun t ↦ g (γ t) * γ' t + ∑ b ∈ S, Pser (coeff b) b (γ t) * γ' t) (uIcc 0 T) := by
    intro t ht
    rw [uIcc_of_le hT] at ht
    simp only
    rw [hfg _ (hoff t ht), add_mul, Finset.sum_mul]
  have hPsum : IntervalIntegrable (fun t ↦ ∑ b ∈ S, Pser (coeff b) b (γ t) * γ' t) volume 0 T := by
    convert IntervalIntegrable.sum S (f := fun b t ↦ Pser (coeff b) b (γ t) * γ' t)
      (fun b hb ↦ intervalIntegrable_mul_deriv hT hγ' (hPc b hb)) using 1
    funext t; simp [Finset.sum_apply]
  rw [intervalIntegral.integral_congr hcongr,
    intervalIntegral.integral_add (f := fun t ↦ g (γ t) * γ' t)
      (g := fun t ↦ ∑ b ∈ S, Pser (coeff b) b (γ t) * γ' t)
      (intervalIntegrable_mul_deriv hT hγ' (hgc.comp hγ (fun t ht ↦ hin t ht))) hPsum,
    intervalIntegral.integral_finsetSum
      (fun b hb ↦ intervalIntegrable_mul_deriv hT hγ' (hPc b hb)),
    loop_integral_primitive hG hgc hT hγ hderiv hγ' hclosed hin, zero_add, Finset.mul_sum]
  refine Finset.sum_congr rfl fun b hb ↦ ?_
  rw [loop_Pser hT hγ hderiv hγ' hclosed b (fun t ht h ↦ hoff t ht (by rw [h]; exact hb)) (coeff b) (hr b hb)
    (hsum b hb), windingNumber]
  have h2 := two_pi_I_ne_zero
  field_simp

/-- On a small circle only the 1/(z − a) term survives. If f equals its Laurent series
∑ c n · (z − a)ⁿ on the punctured disc 0 < |z − a| < r, then for every radius ρ with 0 < ρ < r the
integral of f once anticlockwise round the circle of radius ρ round a is 2πi times c (−1), the
residue, whatever ρ is. -/
theorem small_circle_integral_eq_two_pi_I_mul_residue
    (f : ℂ → ℂ) (a : ℂ) (c : ℤ → ℂ) (r : ℝ)
    (hlaurent : ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    (ρ : ℝ) (hρ : 0 < ρ) (hρr : ρ < r) :
    (∮ z in C(a, ρ), f z) = 2 * Real.pi * I * c (-1) := by
  have hr : 0 < r := hρ.trans hρr
  have hsum : ∀ s, 0 < s → s < r → Summable fun n : ℤ ↦ ‖c n‖ * s ^ n :=
    fun s hs hsr ↦ summable_of_laurent hlaurent hs hsr
  have h := circle_integral_eq_two_pi_I_mul_sum_residues f a ρ hρ {a}
    (by intro z hz; simp only [Finset.coe_singleton, mem_singleton_iff] at hz; subst hz
        exact mem_ball_self hρ)
    ?_ (fun _ ↦ c)
    (by intro b hb; rw [Finset.mem_singleton] at hb; subst hb; exact ⟨r, hr, hlaurent⟩)
  · simpa using h
  · intro z hz
    have hza : z ≠ a := by simpa using hz.2
    have hopen : IsOpen {w : ℂ | 0 < ‖w - a‖ ∧ ‖w - a‖ < r} := by
      have hcont : Continuous fun w : ℂ ↦ ‖w - a‖ := by fun_prop
      exact (isOpen_lt continuous_const hcont).inter (isOpen_lt hcont continuous_const)
    have hz' : z ∈ {w : ℂ | 0 < ‖w - a‖ ∧ ‖w - a‖ < r} :=
      ⟨norm_pos_iff.2 (sub_ne_zero.2 hza),
        lt_of_le_of_lt (by simpa [dist_eq_norm] using hz.1) hρr⟩
    have hd : DifferentiableAt ℂ (fun w ↦ Rser c a w + Pser c a w) z :=
      (Rser_differentiableAt hsum hz'.2).add (Pser_differentiableAt hr hsum hza)
    apply hd.congr_of_eventuallyEq
    filter_upwards [hopen.mem_nhds hz'] with w hw
    exact laurent_split hlaurent hw.1 hw.2

/-! The card's worked numbers for f(z) = 1/(z^2 + 1), checked exactly. -/

-- the poles: z^2 + 1 = (z − i)(z + i), zero at i and −i
example : I ^ 2 + 1 = 0 ∧ (-I) ^ 2 + 1 = 0 := by
  constructor <;> simp [I_sq]
-- near i, (z − i) f(z) = 1/(z + i), off the poles
example (z : ℂ) (h1 : z - I ≠ 0) (h2 : z + I ≠ 0) :
    (z - I) * (1 / (z ^ 2 + 1)) = 1 / (z + I) := by
  have h : z ^ 2 + 1 = (z - I) * (z + I) := by ring_nf; simp [I_sq]; ring
  rw [h]
  field_simp
-- the residues: 1/(2i) = −i/2 at i, 1/(−2i) = i/2 at −i
example : (1 : ℂ) / (I + I) = -I / 2 ∧ (1 : ℂ) / (-I - I) = I / 2 := by
  constructor <;> field_simp <;> ring_nf <;> simp [I_sq]
-- the tolls: |z − i| = 1 pays 2πi(−i/2) = π, |z + i| = 1 pays 2πi(i/2) = −π
example : 2 * Real.pi * I * (-I / 2) = Real.pi ∧ 2 * Real.pi * I * (I / 2) = -Real.pi := by
  constructor <;> ring_nf <;> simp [I_sq]
-- |z| = 3 encloses both: 2πi(−i/2 + i/2) = 0; |z| = 1/2 encloses neither: the empty sum, 0
example : 2 * Real.pi * I * (-I / 2 + I / 2) = 0 := by ring
-- twice round |z − i| = 1 gives 2π; clockwise gives −π
example : 2 * Real.pi * I * (2 * (-I / 2)) = 2 * Real.pi ∧
    2 * Real.pi * I * ((-1) * (-I / 2)) = -Real.pi := by
  constructor <;> ring_nf <;> simp [I_sq]
-- mistake: residue at i taken as 1 gives 2πi, not π (summing both residues gives the 0 above, not π)
example : 2 * Real.pi * I * 1 ≠ Real.pi := by
  intro h
  have := congrArg Complex.re h
  simp at this
  exact Real.pi_ne_zero this.symm

#print axioms circle_integral_eq_two_pi_I_mul_sum_residues
#print axioms loop_integral_eq_two_pi_I_mul_sum_winding_number_mul_residue
#print axioms small_circle_integral_eq_two_pi_I_mul_residue

end TheResidueTheorem
