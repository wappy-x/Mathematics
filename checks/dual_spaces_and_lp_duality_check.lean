-- Dual spaces: for 1 ≤ p < ∞ every bounded functional on ℓ^p and on L^p is a weighted sum or integral against weights in the conjugate space, with norm exactly their q-size, and a transpose keeps the operator's norm and has the annihilator of the range as its kernel.
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.Analysis.Normed.Operator.Bilinear
import Mathlib.MeasureTheory.Function.LpSpace.Complete
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.Normed.Lp.lpHolder
import Mathlib.Analysis.Normed.Module.HahnBanach
import Mathlib.Analysis.SpecialFunctions.Pow.Continuity
import Mathlib.Basic.Real.Sign
import Mathlib.MeasureTheory.Function.Holder
import Mathlib.MeasureTheory.Function.AEEqOfIntegral
import Mathlib.MeasureTheory.Function.SimpleFuncDenseLp
import Mathlib.MeasureTheory.Function.StronglyMeasurable.Lp
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.MeasureTheory.Order.Group.Lattice
import Mathlib.MeasureTheory.VectorMeasure.Decomposition.RadonNikodym

open scoped ENNReal
open MeasureTheory Matrix

/-! Helper lemmas for the three theorems below. -/

section Helpers

open Filter Topology
open scoped symmDiff

lemma aux_sign (a Q : ℝ) (hQ : 1 < Q) :
    Real.sign a * |a| ^ (Q - 1) * a = |a| ^ Q ∧ |Real.sign a * |a| ^ (Q - 1)| = |a| ^ (Q - 1) := by
  have hQ0 : Q ≠ 0 := by linarith
  have hQ1 : Q - 1 ≠ 0 := by linarith
  have hnn : 0 ≤ |a| ^ (Q - 1) := Real.rpow_nonneg (abs_nonneg a) _
  rcases lt_trichotomy a 0 with h | h | h
  · have ha : |a| ≠ 0 := abs_ne_zero.mpr h.ne
    have key : |a| ^ (Q - 1) * |a| = |a| ^ Q := by rw [Real.rpow_sub_one ha, div_mul_cancel₀ _ ha]
    rw [Real.sign_of_neg h]
    refine ⟨?_, ?_⟩
    · rw [← key]
      rw [abs_of_neg h]; ring
    · rw [abs_mul]; simp [abs_of_nonneg hnn]
  · subst h; simp [Real.sign_zero, Real.zero_rpow hQ0, Real.zero_rpow hQ1]
  · have ha : |a| ≠ 0 := abs_ne_zero.mpr h.ne'
    have key : |a| ^ (Q - 1) * |a| = |a| ^ Q := by rw [Real.rpow_sub_one ha, div_mul_cancel₀ _ ha]
    rw [Real.sign_of_pos h]
    refine ⟨?_, ?_⟩
    · rw [← key]
      rw [abs_of_pos h]; ring
    · rw [abs_mul]; simp [abs_of_nonneg hnn]

lemma lp_weights_mem {p q : ℝ≥0∞} [Fact (1 ≤ p)] [Fact (1 ≤ q)]
    [p.HolderConjugate q] (hp : p ≠ ∞) (φ : StrongDual ℝ (lp (fun _ : ℕ => ℝ) p))
    (w : ℕ → ℝ) (hw : ∀ n, w n = φ (lp.single p n (1:ℝ))) :
    ∃ h : Memℓp w q, ‖(⟨w, h⟩ : lp (fun _ : ℕ => ℝ) q)‖ ≤ ‖φ‖ := by
  have hp0 : 0 < p := zero_lt_one.trans_le Fact.out
  by_cases hq : q = ∞
  · subst hq
    have hb : ∀ n, ‖w n‖ ≤ ‖φ‖ := fun n => by
      calc ‖w n‖ ≤ ‖φ‖ * ‖(lp.single p n (1:ℝ) : lp (fun _ : ℕ => ℝ) p)‖ := by
            rw [hw]; exact φ.le_opNorm _
        _ = ‖φ‖ := by rw [lp.norm_single hp0]; simp
    refine ⟨memℓp_infty ⟨‖φ‖, ?_⟩, lp.norm_le_of_forall_le (norm_nonneg _) hb⟩
    rintro _ ⟨n, rfl⟩; exact hb n
  · have hpq : p.toReal.HolderConjugate q.toReal :=
      ENNReal.HolderConjugate.toReal_of_ne_top hp hq
    set P := p.toReal
    set Q := q.toReal
    have hQ1 : 1 < Q := hpq.symm.lt
    have hP0 : 0 < P := hpq.pos
    have hQ0 : 0 < Q := hpq.symm.pos
    have hPQ : (Q - 1) * P = Q := hpq.symm.sub_one_mul_conj
    have hsum : ∀ s : Finset ℕ, ∑ i ∈ s, ‖w i‖ ^ Q ≤ ‖φ‖ ^ Q := by
      intro s
      set c : ℕ → ℝ := fun i => Real.sign (w i) * |w i| ^ (Q - 1) with hc
      set x := ∑ i ∈ s, lp.single p i (c i) with hxdef
      set S := ∑ i ∈ s, ‖w i‖ ^ Q with hSdef
      have hS0 : 0 ≤ S := Finset.sum_nonneg fun i _ => by positivity
      have hφx : φ x = S := by
        rw [hxdef, map_sum, hSdef]
        refine Finset.sum_congr rfl fun i _ => ?_
        have : (lp.single p i (c i) : lp (fun _ : ℕ => ℝ) p) = c i • lp.single p i (1:ℝ) := by
          rw [← lp.single_smul]; simp
        rw [this, map_smul, smul_eq_mul, Real.norm_eq_abs, ← hw]
        exact (aux_sign (w i) Q hQ1).1
      have hxn : ‖x‖ ^ P = S := by
        rw [hxdef, lp.norm_sum_single hP0]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [Real.norm_eq_abs, (aux_sign (w i) Q hQ1).2, ← Real.rpow_mul (abs_nonneg _), hPQ,
          Real.norm_eq_abs]
      have hx : ‖x‖ = S ^ P⁻¹ := by
        rw [← hxn, ← Real.rpow_mul (norm_nonneg _), mul_inv_cancel₀ hP0.ne', Real.rpow_one]
      have hle : S ≤ ‖φ‖ * S ^ P⁻¹ := by
        calc S = φ x := hφx.symm
          _ ≤ ‖φ x‖ := le_abs_self _
          _ ≤ ‖φ‖ * ‖x‖ := φ.le_opNorm x
          _ = ‖φ‖ * S ^ P⁻¹ := by rw [hx]
      rcases hS0.eq_or_lt with h0 | hpos
      · rw [← h0]; positivity
      · have hsplit : S = S ^ P⁻¹ * S ^ Q⁻¹ := by
          rw [← Real.rpow_add hpos, hpq.inv_add_inv_eq_one, Real.rpow_one]
        have hPpos : 0 < S ^ P⁻¹ := Real.rpow_pos_of_pos hpos _
        have h1 : S ^ Q⁻¹ ≤ ‖φ‖ := by
          have hle' : S ^ P⁻¹ * S ^ Q⁻¹ ≤ S ^ P⁻¹ * ‖φ‖ := by
            calc S ^ P⁻¹ * S ^ Q⁻¹ = S := hsplit.symm
              _ ≤ ‖φ‖ * S ^ P⁻¹ := hle
              _ = _ := mul_comm _ _
          exact le_of_mul_le_mul_left hle' hPpos
        calc S = (S ^ Q⁻¹) ^ Q := (Real.rpow_inv_rpow hS0 hQ0.ne').symm
          _ ≤ ‖φ‖ ^ Q := Real.rpow_le_rpow (by positivity) h1 hQ0.le
    have hmem : Memℓp w q := memℓp_gen' hsum
    refine ⟨hmem, lp.norm_le_of_forall_sum_le hQ0 (norm_nonneg _) fun s => hsum s⟩

variable {α : Type*} [MeasurableSpace α] {μ : Measure α} {p q : ℝ≥0∞}

lemma aux_rpow (a Q : ℝ) (hQ : 1 < Q) :
    a * |a| ^ (Q - 2) * a = |a| ^ Q ∧ |a * |a| ^ (Q - 2)| = |a| ^ (Q - 1) := by
  have hQ0 : Q ≠ 0 := by linarith
  have hQ1 : Q - 1 ≠ 0 := by linarith
  rcases eq_or_ne a 0 with rfl | ha
  · simp [Real.zero_rpow hQ0, Real.zero_rpow hQ1]
  · have hpos : 0 < |a| := abs_pos.mpr ha
    refine ⟨?_, ?_⟩
    · have : a * |a| ^ (Q - 2) * a = |a| ^ (2 : ℝ) * |a| ^ (Q - 2) := by
        rw [Real.rpow_two, sq_abs]; ring
      rw [this, ← Real.rpow_add hpos]; ring_nf
    · rw [abs_mul, abs_of_nonneg (Real.rpow_nonneg (abs_nonneg a) _)]
      have : |a| * |a| ^ (Q - 2) = |a| ^ (1 + (Q - 2)) := by
        rw [Real.rpow_add hpos, Real.rpow_one]
      rw [this]; ring_nf

lemma ind_congr {s t : Set α} (hs : MeasurableSet s) (ht : MeasurableSet t) (hμs : μ s ≠ ∞)
    (hμt : μ t ≠ ∞) (hst : s = t) (c : ℝ) :
    indicatorConstLp p hs hμs c = indicatorConstLp p ht hμt c := by
  subst hst; rfl

lemma ind_smul_one {s : Set α} (hs : MeasurableSet s) (hμs : μ s ≠ ∞) (c : ℝ) :
    indicatorConstLp p hs hμs c = c • indicatorConstLp p hs hμs (1 : ℝ) := by
  ext1
  filter_upwards [indicatorConstLp_coeFn (p := p) (hs := hs) (hμs := hμs) (c := c),
    indicatorConstLp_coeFn (p := p) (hs := hs) (hμs := hμs) (c := (1:ℝ)),
    Lp.coeFn_smul c (indicatorConstLp p hs hμs (1 : ℝ))] with x h1 h2 h3
  rw [h1, h3, Pi.smul_apply, h2]
  by_cases hx : x ∈ s <;> simp [hx]

variable [Fact (1 ≤ p)] [Fact (1 ≤ q)] [p.HolderConjugate q]

lemma lpPair_apply (g : Lp ℝ q μ) (f : Lp ℝ p μ) :
    ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) g f
      = ∫ a, g a * f a ∂μ := by
  rw [ContinuousLinearMap.lpPairing_eq_integral]; rfl

lemma lpPair_norm_le (g : Lp ℝ q μ) :
    ‖ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) g‖ ≤ ‖g‖ := by
  refine ContinuousLinearMap.opNorm_le_bound _ (norm_nonneg _) fun f => ?_
  rw [lpPair_apply]
  set B := ContinuousLinearMap.mul ℝ ℝ
  have h1 : ∫ a, g a * f a ∂μ = ∫ a, (B.holder 1 g f) a ∂μ :=
    integral_congr_ae (B.coeFn_holder (r := 1) g f).symm
  rw [h1, ← L1.integral_eq_integral]
  calc ‖L1.integral (B.holder 1 g f)‖ ≤ ‖B.holder 1 g f‖ := L1.norm_integral_le _
    _ ≤ ‖B‖ * ‖g‖ * ‖f‖ := B.norm_holder_apply_apply_le g f
    _ ≤ 1 * ‖g‖ * ‖f‖ := by gcongr; exact ContinuousLinearMap.opNorm_mul_le ℝ ℝ
    _ = ‖g‖ * ‖f‖ := by ring

lemma lpPair_indicator (g : Lp ℝ q μ) {s : Set α} (hs : MeasurableSet s) (hμs : μ s ≠ ∞) :
    ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) g
      (indicatorConstLp p hs hμs (1 : ℝ)) = ∫ x in s, g x ∂μ := by
  rw [lpPair_apply, ← integral_indicator hs]
  refine integral_congr_ae ?_
  filter_upwards [indicatorConstLp_coeFn (p := p) (hs := hs) (hμs := hμs) (c := (1:ℝ))]
    with x hx
  rw [hx]
  by_cases hxs : x ∈ s <;> simp [hxs]

lemma clm_ext_indicator (hp : p ≠ ∞) (ψ₁ ψ₂ : StrongDual ℝ (Lp ℝ p μ))
    (h : ∀ s (hs : MeasurableSet s) (hμs : μ s ≠ ∞),
      ψ₁ (indicatorConstLp p hs hμs (1 : ℝ)) = ψ₂ (indicatorConstLp p hs hμs (1 : ℝ))) :
    ψ₁ = ψ₂ := by
  ext f
  induction f using Lp.induction hp with
  | indicatorConst c hs hμs =>
    rw [Lp.simpleFunc.coe_indicatorConst, ind_smul_one, map_smul, map_smul, h]
  | add hf hg _ h1 h2 => rw [map_add, map_add, h1, h2]
  | isClosed => exact isClosed_eq ψ₁.continuous ψ₂.continuous

lemma exists_indicator_clm {T : Set α} (hT : MeasurableSet T) :
    ∃ M : Lp ℝ p μ →L[ℝ] Lp ℝ p μ, ‖M‖ ≤ 1 ∧ ∀ f, M f =ᵐ[μ] T.indicator f := by
  let Mlin : Lp ℝ p μ →ₗ[ℝ] Lp ℝ p μ :=
    { toFun := fun f => ((Lp.memLp f).indicator hT.nullMeasurableSet).toLp (T.indicator f)
      map_add' := fun f g => by
        rw [← MemLp.toLp_add]
        apply MemLp.toLp_congr
        filter_upwards [Lp.coeFn_add f g] with x hx
        by_cases hxT : x ∈ T <;> simp [hxT]; exact hx
      map_smul' := fun c f => by
        rw [← MemLp.toLp_const_smul]
        apply MemLp.toLp_congr
        filter_upwards [Lp.coeFn_smul c f] with x hx
        by_cases hxT : x ∈ T <;> simp [hxT, hx] }
  have hbound : ∀ f, ‖Mlin f‖ ≤ 1 * ‖f‖ := by
    intro f
    rw [one_mul]
    show ‖((Lp.memLp f).indicator hT.nullMeasurableSet).toLp (T.indicator f)‖ ≤ ‖f‖
    rw [Lp.norm_toLp, Lp.norm_def]
    exact ENNReal.toReal_mono (Lp.eLpNorm_ne_top f) (eLpNorm_indicator_le _ hT.nullMeasurableSet)
  refine ⟨Mlin.mkContinuous 1 hbound, LinearMap.mkContinuous_norm_le _ zero_le_one _, ?_⟩
  intro f
  rw [LinearMap.mkContinuous_apply]
  exact MemLp.coeFn_toLp ((Lp.memLp f).indicator hT.nullMeasurableSet)

lemma norm_le_lpPair (hp : p ≠ ∞) (hσ : p = 1 → SigmaFinite μ) (g : Lp ℝ q μ) :
    ‖g‖ ≤ ‖ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) g‖ := by
  set Λ := ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) with hΛ
  set C := ‖Λ g‖ with hC
  by_cases hq : q = ∞
  · have hp1 : p = 1 := (ENNReal.HolderConjugate.eq_top_iff_eq_one q p).mp hq
    have := hσ hp1
    have hint : ∀ s, MeasurableSet s → μ s < ∞ → IntegrableOn g s μ := by
      intro s hs hμs
      have : Fact (μ s < ∞) := ⟨hμs⟩
      exact ((Lp.memLp g).restrict s).integrable Fact.out
    have hb : ∀ s, MeasurableSet s → μ s < ∞ → |∫ x in s, g x ∂μ| ≤ C * μ.real s := by
      intro s hs hμs
      rw [← lpPair_indicator (p := p) g hs hμs.ne]
      calc ‖Λ g (indicatorConstLp p hs hμs.ne (1 : ℝ))‖
          ≤ C * ‖indicatorConstLp p hs hμs.ne (1 : ℝ)‖ := (Λ g).le_opNorm _
        _ = C * μ.real s := by
          rw [norm_indicatorConstLp (by rw [hp1]; exact one_ne_zero) hp, hp1]; simp
    have h1 : 0 ≤ᵐ[μ] fun x => C - g x := by
      refine ae_nonneg_of_forall_setIntegral_nonneg_of_sigmaFinite
        (fun s hs hμs => (integrableOn_const hμs.ne).sub (hint s hs hμs)) fun s hs hμs => ?_
      rw [integral_sub (integrableOn_const hμs.ne) (hint s hs hμs), setIntegral_const,
        smul_eq_mul]
      have := hb s hs hμs
      have := le_abs_self (∫ x in s, g x ∂μ)
      nlinarith
    have h2 : 0 ≤ᵐ[μ] fun x => C + g x := by
      refine ae_nonneg_of_forall_setIntegral_nonneg_of_sigmaFinite
        (fun s hs hμs => (integrableOn_const hμs.ne).add (hint s hs hμs)) fun s hs hμs => ?_
      rw [integral_add (integrableOn_const hμs.ne) (hint s hs hμs), setIntegral_const,
        smul_eq_mul]
      have := hb s hs hμs
      have := neg_abs_le (∫ x in s, g x ∂μ)
      nlinarith
    have hbd : ∀ᵐ x ∂μ, ‖(g : α → ℝ) x‖ ≤ C := by
      filter_upwards [h1, h2] with x hx1 hx2
      simp only [Pi.zero_apply] at hx1 hx2
      rw [Real.norm_eq_abs, abs_le]; constructor <;> linarith
    have key : ∀ r : ℝ≥0∞, r = ∞ → eLpNorm (g : α → ℝ) r μ ≤ ENNReal.ofReal C := by
      rintro r rfl
      rw [eLpNorm_exponent_top (Lp.aestronglyMeasurable g)]; exact eLpNormEssSup_le_of_ae_bound hbd
    have := key q hq
    rw [Lp.norm_def]
    exact ENNReal.toReal_le_of_le_ofReal (norm_nonneg _) this
  · have hpq : p.toReal.HolderConjugate q.toReal :=
      ENNReal.HolderConjugate.toReal_of_ne_top hp hq
    set P := p.toReal with hPdef
    set Q := q.toReal with hQdef
    have hQ1 : 1 < Q := hpq.symm.lt
    have hP0 : 0 < P := hpq.pos
    have hPQ : (Q - 1) * P = Q := hpq.symm.sub_one_mul_conj
    have hq0 : q ≠ 0 := (zero_lt_one.trans_le (Fact.out : 1 ≤ q)).ne'
    have hgm : StronglyMeasurable (g : α → ℝ) := Lp.stronglyMeasurable g
    set f0 : α → ℝ := fun x => g x * |g x| ^ (Q - 2) with hf0def
    have hf0m : AEStronglyMeasurable f0 μ :=
      (hgm.measurable.mul (hgm.measurable.abs.pow_const _)).aestronglyMeasurable
    have hnorm_f0 : (fun x => ‖f0 x‖) = fun x => ‖(g : α → ℝ) x‖ ^ (Q - 1) := by
      funext x; simp only [hf0def, Real.norm_eq_abs]; exact (aux_rpow (g x) Q hQ1).2
    have hpQ : p * ENNReal.ofReal (Q - 1) = q := by
      rw [← ENNReal.ofReal_toReal hp, ← ENNReal.ofReal_mul hP0.le, mul_comm, hPQ,
        hQdef, ENNReal.ofReal_toReal hq]
    have heLp : eLpNorm f0 p μ = eLpNorm g q μ ^ (Q - 1) := by
      rw [← eLpNorm_norm f0 hf0m, hnorm_f0,
        eLpNorm_norm_rpow _ (Lp.aestronglyMeasurable g) (by linarith : 0 < Q - 1), hpQ]
    have hf0 : MemLp f0 p μ := by
      rw [memLp_iff, heLp]; exact ENNReal.rpow_lt_top_of_nonneg (by linarith) (Lp.eLpNorm_ne_top g)
    have hF : ‖hf0.toLp f0‖ = ‖g‖ ^ (Q - 1) := by
      rw [Lp.norm_toLp, heLp, ← ENNReal.toReal_rpow, ← Lp.norm_def]
    have hΛF : Λ g (hf0.toLp f0) = ‖g‖ ^ Q := by
      rw [hΛ, lpPair_apply]
      have hc : ∫ a, g a * (hf0.toLp f0) a ∂μ = ∫ a, ‖(g : α → ℝ) a‖ ^ Q ∂μ := by
        refine integral_congr_ae ?_
        filter_upwards [hf0.coeFn_toLp] with x hx
        rw [hx, hf0def, Real.norm_eq_abs, ← (aux_rpow (g x) Q hQ1).1]
        ring
      rw [hc]
      have he := (Lp.memLp g).eLpNorm_eq_integral_rpow_norm hq0 hq
      have hI : 0 ≤ ∫ a, ‖(g : α → ℝ) a‖ ^ Q ∂μ := integral_nonneg fun _ => by positivity
      rw [Lp.norm_def, he, ENNReal.toReal_ofReal (by positivity), ← hQdef,
        ← Real.rpow_mul hI, inv_mul_cancel₀ (by linarith), Real.rpow_one]
    have hle : ‖g‖ ^ Q ≤ C * ‖g‖ ^ (Q - 1) := by
      rw [← hΛF, ← hF]; exact (le_abs_self _).trans ((Λ g).le_opNorm _)
    rcases (norm_nonneg g).eq_or_lt with h0 | hpos
    · rw [← h0]; exact norm_nonneg _
    · have hsplit : ‖g‖ ^ Q = ‖g‖ ^ (Q - 1) * ‖g‖ := by
        rw [← Real.rpow_add_one hpos.ne']; ring_nf
      rw [hsplit, mul_comm C] at hle
      exact le_of_mul_le_mul_left hle (Real.rpow_pos_of_pos hpos _)

lemma key_bound (hp : p ≠ ∞) (hσ : p = 1 → SigmaFinite μ) (φ : StrongDual ℝ (Lp ℝ p μ))
    {A : Set α} (hA : MeasurableSet A) (hμA : μ A < ∞) {h : α → ℝ}
    (hm : StronglyMeasurable h) (h0 : ∀ x ∉ A, h x = 0)
    (hrep : ∀ F (hF : MeasurableSet F) (hμF : μ F ≠ ∞), F ⊆ A →
      ∫ x in F, h x ∂μ = φ (indicatorConstLp p hF hμF (1 : ℝ))) :
    eLpNorm h q μ ≤ ENNReal.ofReal ‖φ‖ := by
  set Λ := ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) with hΛ
  set T : ℕ → Set α := fun n => A ∩ {x | |h x| ≤ n} with hTdef
  have hTm : ∀ n, MeasurableSet (T n) := fun n =>
    hA.inter (measurableSet_le hm.measurable.abs measurable_const)
  have hTA : ∀ n, T n ⊆ A := fun n => Set.inter_subset_left
  have hμT : ∀ n, μ (T n) < ∞ := fun n => (measure_mono (hTA n)).trans_lt hμA
  have hbound : ∀ n, eLpNorm ((T n).indicator h) q μ ≤ ENNReal.ofReal ‖φ‖ := by
    intro n
    have hmem : MemLp ((T n).indicator h) q μ := by
      rw [memLp_indicator_iff_restrict (hTm n).nullMeasurableSet]
      have : Fact (μ (T n) < ∞) := ⟨hμT n⟩
      refine MemLp.of_bound hm.aestronglyMeasurable.restrict n ?_
      rw [ae_restrict_iff' (hTm n)]
      exact Eventually.of_forall fun x hx => by rw [Real.norm_eq_abs]; exact hx.2
    set G := hmem.toLp _ with hG
    obtain ⟨M, hMn, hM⟩ := exists_indicator_clm (p := p) (μ := μ) (hTm n)
    have heq : Λ G = φ.comp M := by
      apply clm_ext_indicator hp
      intro s hs hμs
      have hμsT : μ (s ∩ T n) ≠ ∞ := ne_top_of_le_ne_top hμs (measure_mono Set.inter_subset_left)
      rw [hΛ, lpPair_indicator, ContinuousLinearMap.comp_apply]
      have hMs : M (indicatorConstLp p hs hμs (1 : ℝ))
          = indicatorConstLp p (hs.inter (hTm n)) hμsT (1 : ℝ) := by
        ext1
        filter_upwards [hM (indicatorConstLp p hs hμs (1 : ℝ)),
          indicatorConstLp_coeFn (p := p) (hs := hs) (hμs := hμs) (c := (1:ℝ)),
          indicatorConstLp_coeFn (p := p) (hs := hs.inter (hTm n)) (hμs := hμsT) (c := (1:ℝ))]
          with x h1 h2 h3
        rw [h1, h3]
        by_cases hxT : x ∈ T n
        · rw [Set.indicator_of_mem hxT, h2]
          by_cases hxs : x ∈ s <;> simp [hxs, hxT]
        · rw [Set.indicator_of_notMem hxT, Set.indicator_of_notMem (show x ∉ s ∩ T n from fun hx => hxT hx.2)]
      rw [hMs, ← hrep _ _ _ (Set.inter_subset_right.trans (hTA n))]
      calc ∫ x in s, G x ∂μ = ∫ x in s, (T n).indicator h x ∂μ :=
            integral_congr_ae (ae_restrict_of_ae hmem.coeFn_toLp)
        _ = ∫ x in s ∩ T n, h x ∂μ := setIntegral_indicator (hTm n)
    have h1 : ‖G‖ ≤ ‖φ‖ := by
      calc ‖G‖ ≤ ‖Λ G‖ := norm_le_lpPair hp hσ G
        _ = ‖φ.comp M‖ := by rw [heq]
        _ ≤ ‖φ‖ * ‖M‖ := ContinuousLinearMap.opNorm_comp_le _ _
        _ ≤ ‖φ‖ * 1 := by gcongr
        _ = ‖φ‖ := mul_one _
    calc eLpNorm ((T n).indicator h) q μ = ENNReal.ofReal ‖G‖ := by
          rw [hG, Lp.norm_toLp, ENNReal.ofReal_toReal hmem.eLpNorm_ne_top]
      _ ≤ ENNReal.ofReal ‖φ‖ := ENNReal.ofReal_le_ofReal h1
  refine Lp.eLpNorm_le_of_ae_tendsto (u := atTop) (Eventually.of_forall hbound)
    (fun n => (hm.indicator (hTm n)).aestronglyMeasurable) hm.aestronglyMeasurable
    (Eventually.of_forall fun x => ?_)
  by_cases hxA : x ∈ A
  · obtain ⟨N, hN⟩ := exists_nat_ge |h x|
    refine tendsto_const_nhds.congr' ?_
    filter_upwards [eventually_ge_atTop N] with n hn
    have hxn : |h x| ≤ n := hN.trans (Nat.cast_le.mpr hn)
    rw [Set.indicator_of_mem (show x ∈ T n from ⟨hxA, hxn⟩)]
  · have : ∀ n, (T n).indicator h x = h x := fun n => by
      rw [Set.indicator_of_notMem (show x ∉ T n from fun hx => hxA hx.1), h0 x hxA]
    simp only [this]
    exact tendsto_const_nhds

lemma fin_rep (hp : p ≠ ∞) (φ : StrongDual ℝ (Lp ℝ p μ))
    {A : Set α} (hA : MeasurableSet A) (hμA : μ A < ∞) :
    ∃ h : α → ℝ, StronglyMeasurable h ∧ (∀ x ∉ A, h x = 0) ∧ Integrable h μ ∧
      ∀ F (hF : MeasurableSet F) (hμF : μ F ≠ ∞), F ⊆ A →
        ∫ x in F, h x ∂μ = φ (indicatorConstLp p hF hμF (1 : ℝ)) := by
  classical
  have hp0 : p ≠ 0 := (zero_lt_one.trans_le (Fact.out : 1 ≤ p)).ne'
  have hfin : ∀ F, μ (F ∩ A) ≠ ∞ := fun F =>
    ne_top_of_le_ne_top hμA.ne (measure_mono Set.inter_subset_right)
  set m : Set α → ℝ := fun F => if hF : MeasurableSet F then
    φ (indicatorConstLp p (hF.inter hA) (hfin F) (1 : ℝ)) else 0 with hmdef
  have hm_meas : ∀ F (hF : MeasurableSet F),
      m F = φ (indicatorConstLp p (hF.inter hA) (hfin F) (1 : ℝ)) := fun F hF => by
    simp [hmdef, hF]
  have hm_empty : m ∅ = 0 := by
    rw [hm_meas ∅ MeasurableSet.empty]
    have : indicatorConstLp p (MeasurableSet.empty.inter hA) (hfin ∅) (1 : ℝ)
        = indicatorConstLp p MeasurableSet.empty (by simp) (1 : ℝ) :=
      ind_congr _ _ _ _ (Set.empty_inter A) 1
    rw [this, indicatorConstLp_empty, map_zero]
  have hsum : ∀ ⦃f : ℕ → Set α⦄, (∀ i, MeasurableSet (f i)) → Pairwise (Function.onFun Disjoint f) →
      HasSum (fun i => m (f i)) (m (⋃ i, f i)) := by
    intro f hf hd
    have hfinsum : ∀ s : Finset ℕ, ∑ i ∈ s, m (f i) = φ (indicatorConstLp p
        ((s.measurableSet_biUnion fun i _ => hf i).inter hA) (hfin _) (1 : ℝ)) := by
      intro s
      induction s using Finset.induction_on with
      | empty =>
        rw [Finset.sum_empty]
        have : indicatorConstLp p
            (((∅ : Finset ℕ).measurableSet_biUnion fun i _ => hf i).inter hA) (hfin _) (1 : ℝ)
            = indicatorConstLp p MeasurableSet.empty (by simp) (1 : ℝ) :=
          ind_congr _ _ _ _ (by simp) 1
        rw [this, indicatorConstLp_empty, map_zero]
      | insert j s hj ih =>
        rw [Finset.sum_insert hj, ih, hm_meas _ (hf j), ← map_add,
          ← indicatorConstLp_disjoint_union]
        · congr 1
          apply ind_congr
          ext x
          simp only [Set.mem_union, Set.mem_inter_iff, Set.mem_iUnion, Finset.mem_insert,
            exists_prop]
          constructor
          · rintro (⟨h1, h2⟩ | ⟨⟨i, hi, h1⟩, h2⟩)
            · exact ⟨⟨j, Or.inl rfl, h1⟩, h2⟩
            · exact ⟨⟨i, Or.inr hi, h1⟩, h2⟩
          · rintro ⟨⟨i, hi | hi, h1⟩, h2⟩
            · subst hi; exact Or.inl ⟨h1, h2⟩
            · exact Or.inr ⟨⟨i, hi, h1⟩, h2⟩
        · rw [Set.disjoint_left]
          rintro x ⟨hx1, -⟩ ⟨hx2, -⟩
          simp only [Set.mem_iUnion, exists_prop] at hx2
          obtain ⟨i, hi, hx2⟩ := hx2
          have hij : j ≠ i := fun h => hj (h ▸ hi)
          exact Set.disjoint_left.mp (hd hij) hx1 hx2
    have hU : MeasurableSet (⋃ i, f i) := MeasurableSet.iUnion hf
    rw [HasSum, hm_meas _ hU]
    refine Tendsto.congr (fun s => (hfinsum s).symm) ?_
    refine (φ.continuous.tendsto _).comp ?_
    refine tendsto_indicatorConstLp_set hp ?_
    have htot : ∑' i, μ (f i ∩ A) ≠ ∞ := by
      rw [← measure_iUnion (fun i j hij => (hd hij).mono Set.inter_subset_left
        Set.inter_subset_left) (fun i => (hf i).inter hA)]
      exact ne_top_of_le_ne_top hμA.ne (measure_mono (Set.iUnion_subset fun i =>
        Set.inter_subset_right))
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds
      (ENNReal.tendsto_tsum_compl_atTop_zero htot) (fun s => bot_le) fun s => ?_
    calc μ (((⋃ i ∈ s, f i) ∩ A) ∆ ((⋃ i, f i) ∩ A))
        ≤ μ (⋃ i : {i // i ∉ s}, f i ∩ A) := by
          apply measure_mono
          intro x hx
          rcases hx with ⟨⟨hx1, hxA⟩, hx2⟩ | ⟨⟨hx1, hxA⟩, hx2⟩
          · obtain ⟨i, -, hi⟩ := Set.mem_iUnion₂.mp hx1
            exact absurd ⟨Set.mem_iUnion.mpr ⟨i, hi⟩, hxA⟩ hx2
          · obtain ⟨i, hi⟩ := Set.mem_iUnion.mp hx1
            have his : i ∉ s := fun his => hx2 ⟨Set.mem_biUnion his hi, hxA⟩
            exact Set.mem_iUnion.mpr ⟨⟨i, his⟩, hi, hxA⟩
      _ ≤ ∑' i : {i // i ∉ s}, μ (f i ∩ A) := measure_iUnion_le _
  let ν : SignedMeasure α :=
    { measureOf' := m
      empty' := hm_empty
      not_measurable' := fun F hF => by simp [hmdef, hF]
      m_iUnion' := hsum }
  have hνapp : ∀ F, ν F = m F := fun F => rfl
  have hac : ν ≪ᵥ (μ.restrict A).toENNRealVectorMeasure := by
    refine VectorMeasure.AbsolutelyContinuous.mk fun F hF h0 => ?_
    rw [Measure.toENNRealVectorMeasure_apply_measurable hF, Measure.restrict_apply hF] at h0
    rw [hνapp, hm_meas F hF]
    have : indicatorConstLp p (hF.inter hA) (hfin F) (1 : ℝ) = 0 := by
      rw [← norm_eq_zero, norm_indicatorConstLp hp0 hp, measureReal_def, h0]
      have : 0 < p.toReal := ENNReal.toReal_pos hp0 hp
      simp [Real.zero_rpow (inv_ne_zero this.ne')]
    rw [this, map_zero]
  have : IsFiniteMeasure (μ.restrict A) := isFiniteMeasure_restrict.mpr hμA.ne
  have hr := SignedMeasure.withDensityᵥ_rnDeriv_eq ν (μ.restrict A) hac
  refine ⟨A.indicator (ν.rnDeriv (μ.restrict A)),
    (SignedMeasure.measurable_rnDeriv _ _).stronglyMeasurable.indicator hA,
    fun x hx => Set.indicator_of_notMem hx _,
    (integrable_indicator_iff hA).mpr (SignedMeasure.integrable_rnDeriv _ _), ?_⟩
  intro F hF hμF hFA
  rw [setIntegral_indicator hA]
  have h1 : ν F = ∫ x in F, ν.rnDeriv (μ.restrict A) x ∂(μ.restrict A) := by
    conv_lhs => rw [← hr]
    rw [withDensityᵥ_apply (SignedMeasure.integrable_rnDeriv _ _) hF]
  rw [Measure.restrict_restrict hF] at h1
  rw [← h1, hνapp, hm_meas F hF]
  exact congrArg φ (ind_congr _ _ _ _ (Set.inter_eq_left.mpr hFA) 1)

lemma glue (hp : p ≠ ∞) (hσ : p = 1 → SigmaFinite μ) (φ : StrongDual ℝ (Lp ℝ p μ))
    (D : ℕ → Set α) (hDm : ∀ k, MeasurableSet (D k)) (hDμ : ∀ k, μ (D k) < ∞)
    (hDd : Pairwise (Function.onFun Disjoint D)) :
    ∃ g : α → ℝ, MemLp g q μ ∧ (∀ x, x ∉ ⋃ k, D k → g x = 0) ∧
      ∀ F (hF : MeasurableSet F) (hμF : μ F ≠ ∞), F ⊆ ⋃ k, D k →
        ∫ x in F, g x ∂μ = φ (indicatorConstLp p hF hμF (1 : ℝ)) := by
  classical
  choose h hhm hh0 hhi hhrep using fun k => fin_rep hp φ (hDm k) (hDμ k)
  -- the set function
  set ψ : Set α → ℝ := fun F => if hF : MeasurableSet F ∧ μ F ≠ ∞ then
    φ (indicatorConstLp p hF.1 hF.2 (1 : ℝ)) else 0 with hψdef
  have hψ : ∀ F (hF : MeasurableSet F) (hμF : μ F ≠ ∞),
      φ (indicatorConstLp p hF hμF (1 : ℝ)) = ψ F := by
    intro F hF hμF
    simp [hψdef, hF, hμF]
  have hψunion : ∀ s t, MeasurableSet s → MeasurableSet t → μ s ≠ ∞ → μ t ≠ ∞ →
      Disjoint s t → ψ (s ∪ t) = ψ s + ψ t := by
    intro s t hs ht hμs hμt hst
    rw [← hψ s hs hμs, ← hψ t ht hμt, ← map_add, ← indicatorConstLp_disjoint_union hs ht hμs hμt hst,
      hψ]
  set S := ⋃ k, D k with hSdef
  set B : ℕ → Set α := fun N => ⋃ k ∈ Finset.range N, D k with hBdef
  have hBm : ∀ N, MeasurableSet (B N) := fun N =>
    Finset.measurableSet_biUnion _ fun k _ => hDm k
  have hBμ : ∀ N, μ (B N) < ∞ := fun N =>
    measure_biUnion_lt_top (Finset.finite_toSet _) fun k _ => hDμ k
  have hBsucc : ∀ N, B (N + 1) = B N ∪ D N := by
    intro N
    simp only [hBdef, Finset.range_add_one, Finset.set_biUnion_insert]
    exact Set.union_comm _ _
  have hBS : ∀ N, B N ⊆ S := fun N =>
    Set.iUnion₂_subset fun k _ => Set.subset_iUnion D k
  -- finite additivity
  have hadd : ∀ F, MeasurableSet F → μ F ≠ ∞ → ∀ N,
      ∑ k ∈ Finset.range N, ψ (F ∩ D k) = ψ (F ∩ B N) := by
    intro F hF hμF N
    induction N with
    | zero =>
      simp only [Finset.range_zero, Finset.sum_empty, hBdef, Finset.notMem_empty,
        Set.iUnion_of_empty, Set.iUnion_empty, Set.inter_empty]
      rw [← hψ ∅ MeasurableSet.empty (by simp), indicatorConstLp_empty, map_zero]
    | succ N ih =>
      rw [Finset.sum_range_succ, ih, hBsucc, Set.inter_union_distrib_left]
      have hμ1 : μ (F ∩ B N) ≠ ∞ := ne_top_of_le_ne_top hμF (measure_mono Set.inter_subset_left)
      have hμ2 : μ (F ∩ D N) ≠ ∞ := ne_top_of_le_ne_top hμF (measure_mono Set.inter_subset_left)
      rw [hψunion _ _ (hF.inter (hBm N)) (hF.inter (hDm N)) hμ1 hμ2]
      rw [Set.disjoint_left]
      rintro x ⟨-, hx1⟩ ⟨-, hx2⟩
      obtain ⟨k, hk, hxk⟩ := Set.mem_iUnion₂.mp hx1
      have hkN : k ≠ N := fun h => by simp [h] at hk
      exact Set.disjoint_left.mp (hDd hkN) hxk hx2
  -- the glued function
  set g : α → ℝ := fun x => ∑' k, h k x with hgdef
  have hg_mem : ∀ j x, x ∈ D j → g x = h j x := by
    intro j x hx
    exact tsum_eq_single j fun k hk => hh0 k x (fun hxk => Set.disjoint_left.mp (hDd hk) hxk hx)
  have hg_out : ∀ x, x ∉ S → g x = 0 := by
    intro x hx
    have : ∀ k, h k x = 0 := fun k => hh0 k x (fun hk => hx (Set.mem_iUnion.mpr ⟨k, hk⟩))
    simp [hgdef, this]
  set G : ℕ → α → ℝ := fun N x => ∑ k ∈ Finset.range N, h k x with hGdef
  have hG_eq : ∀ N x, G N x = (B N).indicator g x := by
    intro N x
    by_cases hx : x ∈ S
    · obtain ⟨j, hj⟩ := Set.mem_iUnion.mp hx
      have hz : ∀ k, k ≠ j → h k x = 0 := fun k hk =>
        hh0 k x (fun hxk => Set.disjoint_left.mp (hDd hk) hxk hj)
      by_cases hjN : j ∈ Finset.range N
      · rw [Set.indicator_of_mem (show x ∈ B N from Set.mem_iUnion₂.mpr ⟨j, hjN, hj⟩), hg_mem j x hj]
        exact Finset.sum_eq_single_of_mem j hjN fun k _ hk => hz k hk
      · have hxB : x ∉ B N := by
          intro hxB
          obtain ⟨k, hk, hxk⟩ := Set.mem_iUnion₂.mp hxB
          have : k = j := by
            by_contra hkj
            exact Set.disjoint_left.mp (hDd hkj) hxk hj
          exact hjN (this ▸ hk)
        rw [Set.indicator_of_notMem hxB]
        exact Finset.sum_eq_zero fun k hk => hz k (fun h => hjN (h ▸ hk))
    · have hz : ∀ k, h k x = 0 := fun k => hh0 k x (fun hk => hx (Set.mem_iUnion.mpr ⟨k, hk⟩))
      have : G N x = 0 := Finset.sum_eq_zero fun k _ => hz k
      rw [this]
      by_cases hxB : x ∈ B N
      · rw [Set.indicator_of_mem hxB, hg_out x hx]
      · rw [Set.indicator_of_notMem hxB]
  have hGm : ∀ N, StronglyMeasurable (G N) := fun N =>
    Finset.stronglyMeasurable_fun_sum _ fun k _ => hhm k
  have hGint : ∀ N, Integrable (G N) μ := fun N =>
    integrable_finsetSum _ fun k _ => hhi k
  -- representation for G N
  have hGrep : ∀ N F (hF : MeasurableSet F), μ F ≠ ∞ →
      ∫ x in F, G N x ∂μ = ψ (F ∩ B N) := by
    intro N F hF hμF
    rw [hGdef]
    simp only
    rw [MeasureTheory.integral_finsetSum _ fun k _ => (hhi k).integrableOn, ← hadd F hF hμF N]
    refine Finset.sum_congr rfl fun k _ => ?_
    have hhk : h k = (D k).indicator (h k) := by
      funext x
      by_cases hx : x ∈ D k
      · rw [Set.indicator_of_mem hx]
      · rw [Set.indicator_of_notMem hx, hh0 k x hx]
    have hμk : μ (F ∩ D k) ≠ ∞ := ne_top_of_le_ne_top hμF (measure_mono Set.inter_subset_left)
    rw [hhk, setIntegral_indicator (hDm k),
      hhrep k (F ∩ D k) (hF.inter (hDm k)) hμk Set.inter_subset_right, hψ]
  have hGbound : ∀ N, eLpNorm (G N) q μ ≤ ENNReal.ofReal ‖φ‖ := by
    intro N
    refine key_bound hp hσ φ (hBm N) (hBμ N) (hGm N) (fun x hx => by rw [hG_eq,
      Set.indicator_of_notMem hx]) ?_
    intro F hF hμF hFB
    rw [hGrep N F hF hμF, Set.inter_eq_left.mpr hFB, hψ]
  -- convergence
  have hGlim : ∀ x, Tendsto (fun N => G N x) atTop (𝓝 (g x)) := by
    intro x
    by_cases hx : x ∈ S
    · obtain ⟨j, hj⟩ := Set.mem_iUnion.mp hx
      refine tendsto_const_nhds.congr' ?_
      filter_upwards [eventually_gt_atTop j] with N hN
      rw [hG_eq, Set.indicator_of_mem (show x ∈ B N from
        Set.mem_iUnion₂.mpr ⟨j, Finset.mem_range.mpr hN, hj⟩)]
    · have : ∀ N, G N x = g x := fun N => by
        rw [hG_eq, hg_out x hx]; exact Set.indicator_apply_eq_zero.mpr fun _ => hg_out x hx
      simp only [this]
      exact tendsto_const_nhds
  have hgm : StronglyMeasurable g :=
    stronglyMeasurable_of_tendsto atTop hGm (tendsto_pi_nhds.mpr hGlim)
  have hgle : eLpNorm g q μ ≤ ENNReal.ofReal ‖φ‖ :=
    Lp.eLpNorm_le_of_ae_tendsto (Eventually.of_forall hGbound)
      (fun N => (hGm N).aestronglyMeasurable) hgm.aestronglyMeasurable
      (Eventually.of_forall hGlim)
  have hgmem : MemLp g q μ := by
    rw [memLp_iff]; exact hgle.trans_lt ENNReal.ofReal_lt_top
  refine ⟨g, hgmem, hg_out, ?_⟩
  intro F hF hμF hFS
  have : Fact (μ F < ∞) := ⟨hμF.lt_top⟩
  have hgF : Integrable g (μ.restrict F) := (hgmem.restrict F).integrable Fact.out
  have h1 : Tendsto (fun N => ∫ x in F, G N x ∂μ) atTop (𝓝 (∫ x in F, g x ∂μ)) := by
    refine tendsto_integral_of_dominated_convergence (fun x => ‖g x‖)
      (fun N => (hGm N).aestronglyMeasurable) hgF.norm (fun N => ?_)
      (Eventually.of_forall hGlim)
    refine Eventually.of_forall fun x => ?_
    rw [hG_eq]
    by_cases hxB : x ∈ B N
    · rw [Set.indicator_of_mem hxB]
    · rw [Set.indicator_of_notMem hxB, norm_zero]; exact norm_nonneg _
  have h2 : Tendsto (fun N => ∫ x in F, G N x ∂μ) atTop
      (𝓝 (φ (indicatorConstLp p hF hμF (1 : ℝ)))) := by
    have hμFB : ∀ N, μ (F ∩ B N) ≠ ∞ := fun N =>
      ne_top_of_le_ne_top hμF (measure_mono Set.inter_subset_left)
    have he : (fun N => ∫ x in F, G N x ∂μ) =
        fun N => φ (indicatorConstLp p (hF.inter (hBm N)) (hμFB N) (1 : ℝ)) := by
      funext N; rw [hGrep N F hF hμF, hψ]
    rw [he]
    refine (φ.continuous.tendsto _).comp (tendsto_indicatorConstLp_set hp ?_)
    have hsd : ∀ N, (F ∩ B N) ∆ F = F \ B N := by
      intro N; ext x
      simp only [Set.mem_symmDiff, Set.mem_inter_iff, Set.mem_sdiff]
      tauto
    simp only [hsd]
    have hlim := tendsto_measure_iInter_atTop (μ := μ) (s := fun N => F \ B N)
      (fun N => (hF.diff (hBm N)).nullMeasurableSet)
      (fun N M hNM => Set.sdiff_subset_sdiff_right
        (Set.biUnion_subset_biUnion_left (by simpa using hNM)))
      ⟨0, ne_top_of_le_ne_top hμF (measure_mono Set.sdiff_subset)⟩
    have hempty : (⋂ N, F \ B N) = ∅ := by
      refine Set.eq_empty_iff_forall_notMem.mpr fun x hx => ?_
      have hx' := Set.mem_iInter.mp hx
      obtain ⟨j, hj⟩ := Set.mem_iUnion.mp (hFS (hx' 0).1)
      exact (hx' (j + 1)).2 (Set.mem_iUnion₂.mpr ⟨j, Finset.mem_range.mpr (Nat.lt_succ_self j), hj⟩)
    rw [hempty, measure_empty] at hlim
    exact hlim
  exact tendsto_nhds_unique h1 h2

lemma norm_rpow_eq_integral (hp : p ≠ ∞) (v : Lp ℝ p μ) :
    ‖v‖ ^ p.toReal = ∫ x, ‖v x‖ ^ p.toReal ∂μ := by
  have hp0 : p ≠ 0 := (zero_lt_one.trans_le (Fact.out : 1 ≤ p)).ne'
  have hP : 0 < p.toReal := ENNReal.toReal_pos hp0 hp
  have hI : 0 ≤ ∫ x, ‖v x‖ ^ p.toReal ∂μ := integral_nonneg fun _ => by positivity
  rw [Lp.norm_def, (Lp.memLp v).eLpNorm_eq_integral_rpow_norm hp0 hp,
    ENNReal.toReal_ofReal (by positivity), Real.rpow_inv_rpow hI hP.ne']

lemma exists_cover (hp : p ≠ ∞) (hp1 : p ≠ 1) (φ : StrongDual ℝ (Lp ℝ p μ)) :
    ∃ D : ℕ → Set α, (∀ k, MeasurableSet (D k)) ∧ (∀ k, μ (D k) < ∞) ∧
      Pairwise (Function.onFun Disjoint D) ∧
      ∀ G (hG : MeasurableSet G) (hμG : μ G ≠ ∞), G ⊆ (⋃ k, D k)ᶜ →
        φ (indicatorConstLp p hG hμG (1 : ℝ)) = 0 := by
  classical
  have hp0 : p ≠ 0 := (zero_lt_one.trans_le (Fact.out : 1 ≤ p)).ne'
  have hP1 : 1 < p.toReal := by
    have h1 : 1 < p := lt_of_le_of_ne (Fact.out : 1 ≤ p) (Ne.symm hp1)
    have := (ENNReal.toReal_lt_toReal ENNReal.one_ne_top hp).mpr h1
    simpa using this
  set P := p.toReal with hPdef
  have hP0 : 0 < P := by linarith
  -- a norming sequence
  have hnorming : ∀ n : ℕ, ∃ f : Lp ℝ p μ, ‖f‖ ≤ 1 ∧ ‖φ‖ - 1 / (n + 1) ≤ φ f := by
    intro n
    have hlt : ‖φ‖ - 1 / (n + 1) < ‖φ‖ := by
      have : (0 : ℝ) < 1 / (n + 1) := by positivity
      linarith
    obtain ⟨x, hx1, hx2⟩ := φ.exists_lt_apply_of_lt_opNorm hlt
    rcases le_or_gt 0 (φ x) with h | h
    · refine ⟨x, hx1.le, ?_⟩
      rw [Real.norm_eq_abs, abs_of_nonneg h] at hx2; exact hx2.le
    · refine ⟨-x, by rw [norm_neg]; exact hx1.le, ?_⟩
      rw [map_neg]; rw [Real.norm_eq_abs, abs_of_neg h] at hx2; exact hx2.le
  choose f hf1 hf2 using hnorming
  -- countably many finite-measure sets carrying all the f n
  have hfs : ∀ n, ∃ fs : ℕ → SimpleFunc α ℝ, (∀ j, μ (Function.support (fs j)) < ∞) ∧
      ∀ x, Tendsto (fun j => fs j x) atTop (𝓝 (f n x)) := fun n =>
    Lp.finStronglyMeasurable (f n) hp0 hp
  choose fs hfsμ hfslim using hfs
  set E : ℕ → Set α := fun m => Function.support (fs (Nat.unpair m).1 (Nat.unpair m).2)
    with hEdef
  have hEm : ∀ m, MeasurableSet (E m) := fun m => SimpleFunc.measurableSet_support _
  have hEμ : ∀ m, μ (E m) < ∞ := fun m => hfsμ _ _
  have hf0 : ∀ n x, x ∉ ⋃ m, E m → f n x = 0 := by
    intro n x hx
    have hz : ∀ j, fs n j x = 0 := fun j => by
      by_contra hne
      refine hx (Set.mem_iUnion.mpr ⟨Nat.pair n j, ?_⟩)
      simpa [hEdef, Nat.unpair_pair] using hne
    have : Tendsto (fun j => fs n j x) atTop (𝓝 0) := by simp only [hz]; exact tendsto_const_nhds
    exact tendsto_nhds_unique (hfslim n x) this
  refine ⟨disjointed E, MeasurableSet.disjointed hEm,
    fun k => (measure_mono (disjointed_subset E k)).trans_lt (hEμ k), disjoint_disjointed E, ?_⟩
  rw [iUnion_disjointed]
  intro G hG hμG hGsub
  set c := φ (indicatorConstLp p hG hμG (1 : ℝ)) with hc
  set m := μ.real G with hm
  set K := ‖φ‖ with hK
  have hm0 : 0 ≤ m := measureReal_nonneg
  have hK0 : 0 ≤ K := norm_nonneg _
  -- the basic inequality
  have hineq : ∀ (n : ℕ) (s : ℝ), φ (f n) + s * c ≤ K * (1 + |s| ^ P * m) := by
    intro n s
    set u := f n + s • indicatorConstLp p hG hμG (1 : ℝ) with hu
    have hφu : φ u = φ (f n) + s * c := by
      rw [hu, map_add, map_smul, smul_eq_mul]
    have hupt : (fun x => ‖u x‖ ^ P) =ᵐ[μ]
        fun x => ‖f n x‖ ^ P + G.indicator (fun _ => |s| ^ P) x := by
      filter_upwards [Lp.coeFn_add (f n) (s • indicatorConstLp p hG hμG (1 : ℝ)),
        Lp.coeFn_smul s (indicatorConstLp p hG hμG (1 : ℝ)),
        indicatorConstLp_coeFn (p := p) (hs := hG) (hμs := hμG) (c := (1 : ℝ))]
        with x h1 h2 h3
      rw [h1, Pi.add_apply, h2, Pi.smul_apply, h3]
      by_cases hxG : x ∈ G
      · have : f n x = 0 := hf0 n x (hGsub hxG)
        simp [hxG, this, Real.zero_rpow hP0.ne']
      · simp [hxG]
    have hu_rpow : ‖u‖ ^ P = ‖f n‖ ^ P + |s| ^ P * m := by
      rw [norm_rpow_eq_integral hp, norm_rpow_eq_integral hp, integral_congr_ae hupt,
        integral_add ((Lp.memLp (f n)).integrable_norm_rpow hp0 hp)
          ((integrable_indicator_iff hG).mpr (integrableOn_const hμG)),
        integral_indicator_const _ hG, smul_eq_mul, mul_comm]
    have hfnP : ‖f n‖ ^ P ≤ 1 := Real.rpow_le_one (norm_nonneg _) (hf1 n) hP0.le
    have hu_le : ‖u‖ ≤ 1 + |s| ^ P * m := by
      have hR : 1 ≤ 1 + |s| ^ P * m := by
        have : 0 ≤ |s| ^ P * m := by positivity
        linarith
      rcases le_or_gt ‖u‖ 1 with h | h
      · linarith
      · calc ‖u‖ = ‖u‖ ^ (1 : ℝ) := (Real.rpow_one _).symm
          _ ≤ ‖u‖ ^ P := Real.rpow_le_rpow_of_exponent_le h.le hP1.le
          _ = ‖f n‖ ^ P + |s| ^ P * m := hu_rpow
          _ ≤ 1 + |s| ^ P * m := by linarith
    calc φ (f n) + s * c = φ u := hφu.symm
      _ ≤ ‖φ u‖ := le_abs_self _
      _ ≤ K * ‖u‖ := φ.le_opNorm u
      _ ≤ K * (1 + |s| ^ P * m) := by gcongr
  -- remove the 1/(n+1)
  have hineq2 : ∀ s : ℝ, s * c ≤ K * (|s| ^ P * m) := by
    intro s
    refine le_of_forall_pos_lt_add fun ε hε => ?_
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hε
    have h1 := hineq n s
    have h2 := hf2 n
    nlinarith
  have hsmall : ∀ t : ℝ, 0 < t → |c| ≤ K * m * t ^ (P - 1) := by
    intro t ht
    have ha := hineq2 t
    have hb := hineq2 (-t)
    rw [abs_neg, abs_of_pos ht] at hb
    rw [abs_of_pos ht] at ha
    have hsplit : t ^ P = t * t ^ (P - 1) := by
      rw [← Real.rpow_one_add' ht.le (by linarith)]; ring_nf
    rw [hsplit] at ha hb
    have : t * |c| ≤ t * (K * m * t ^ (P - 1)) := by
      rcases le_or_gt 0 c with hc0 | hc0
      · rw [abs_of_nonneg hc0]; nlinarith
      · rw [abs_of_neg hc0]; nlinarith
    exact le_of_mul_le_mul_left this ht
  have hlim : Tendsto (fun t : ℝ => K * m * t ^ (P - 1)) (𝓝[>] 0) (𝓝 0) := by
    have hc : ContinuousAt (fun t : ℝ => K * m * t ^ (P - 1)) 0 :=
      continuousAt_const.mul (Real.continuousAt_rpow_const 0 (P - 1) (Or.inr (by linarith)))
    have := hc.tendsto
    rw [Real.zero_rpow (by linarith : P - 1 ≠ 0), mul_zero] at this
    exact tendsto_nhdsWithin_of_tendsto_nhds this
  have habs : |c| ≤ 0 := ge_of_tendsto hlim (eventually_nhdsWithin_of_forall fun t ht => hsmall t ht)
  exact abs_nonpos_iff.mp habs

lemma lpPair_surj (hp : p ≠ ∞) (hσ : p = 1 → SigmaFinite μ) (φ : StrongDual ℝ (Lp ℝ p μ)) :
    ∃ g : Lp ℝ q μ, ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ) g = φ := by
  obtain ⟨D, hDm, hDμ, hDd, hZ⟩ : ∃ D : ℕ → Set α, (∀ k, MeasurableSet (D k)) ∧
      (∀ k, μ (D k) < ∞) ∧ Pairwise (Function.onFun Disjoint D) ∧
      ∀ G (hG : MeasurableSet G) (hμG : μ G ≠ ∞), G ⊆ (⋃ k, D k)ᶜ →
        φ (indicatorConstLp p hG hμG (1 : ℝ)) = 0 := by
    by_cases hp1 : p = 1
    · have := hσ hp1
      refine ⟨disjointed (spanningSets μ), MeasurableSet.disjointed (measurableSet_spanningSets μ),
        fun k => (measure_mono (disjointed_subset _ k)).trans_lt (measure_spanningSets_lt_top μ k),
        disjoint_disjointed _, fun G hG hμG hsub => ?_⟩
      rw [iUnion_disjointed, iUnion_spanningSets, Set.compl_univ, Set.subset_empty_iff] at hsub
      subst hsub
      rw [indicatorConstLp_empty, map_zero]
    · exact exists_cover hp hp1 φ
  obtain ⟨g, hgmem, hg0, hgrep⟩ := glue (q := q) hp hσ φ D hDm hDμ hDd
  refine ⟨hgmem.toLp g, ?_⟩
  apply clm_ext_indicator hp
  intro s hs hμs
  rw [lpPair_indicator]
  have hS : MeasurableSet (⋃ k, D k) := MeasurableSet.iUnion hDm
  have hμ1 : μ (s ∩ ⋃ k, D k) ≠ ∞ := ne_top_of_le_ne_top hμs (measure_mono Set.inter_subset_left)
  have hμ2 : μ (s \ ⋃ k, D k) ≠ ∞ := ne_top_of_le_ne_top hμs (measure_mono Set.sdiff_subset)
  have hgS : g = (⋃ k, D k).indicator g := by
    funext x
    by_cases hx : x ∈ ⋃ k, D k
    · rw [Set.indicator_of_mem hx]
    · rw [Set.indicator_of_notMem hx, hg0 x hx]
  calc ∫ x in s, (hgmem.toLp g) x ∂μ = ∫ x in s, g x ∂μ :=
        integral_congr_ae (ae_restrict_of_ae hgmem.coeFn_toLp)
    _ = ∫ x in s, (⋃ k, D k).indicator g x ∂μ := by rw [← hgS]
    _ = ∫ x in s ∩ ⋃ k, D k, g x ∂μ := setIntegral_indicator hS
    _ = φ (indicatorConstLp p (hs.inter hS) hμ1 (1 : ℝ)) :=
        hgrep _ _ _ Set.inter_subset_right
    _ = φ (indicatorConstLp p (hs.inter hS) hμ1 (1 : ℝ))
          + φ (indicatorConstLp p (hs.diff hS) hμ2 (1 : ℝ)) := by
        rw [hZ _ _ _ (show s \ ⋃ k, D k ⊆ (⋃ k, D k)ᶜ from fun x hx => hx.2), add_zero]
    _ = φ (indicatorConstLp p hs hμs (1 : ℝ)) := by
        rw [← map_add, ← indicatorConstLp_disjoint_union _ _ _ _
          (Set.disjoint_sdiff_inter.symm)]
        exact congrArg φ (ind_congr _ _ _ _ (Set.inter_union_sdiff s _) 1)

end Helpers

#print axioms aux_sign
#print axioms lp_weights_mem
#print axioms aux_rpow
#print axioms ind_congr
#print axioms ind_smul_one
#print axioms lpPair_apply
#print axioms lpPair_norm_le
#print axioms lpPair_indicator
#print axioms clm_ext_indicator
#print axioms exists_indicator_clm
#print axioms norm_le_lpPair
#print axioms key_bound
#print axioms fin_rep
#print axioms glue
#print axioms norm_rpow_eq_integral
#print axioms exists_cover
#print axioms lpPair_surj

/-- The dual of ℓ^p, for 1 ≤ p < ∞ and q the conjugate exponent (1/p + 1/q = 1, with 1 paired
to ∞): weighted sums give an exact match between weight lists w in ℓ^q and the bounded linear
functionals on ℓ^p. Every functional is the weighted sum x ↦ ∑ wₙ xₙ for exactly one w in ℓ^q,
and its norm is exactly the q-size ‖w‖_q. -/
theorem dual_of_lp_is_lq_by_weighted_sums {p q : ℝ≥0∞} [Fact (1 ≤ p)] [Fact (1 ≤ q)]
    [p.HolderConjugate q] (hp : p ≠ ∞) :
    ∃ e : lp (fun _ : ℕ => ℝ) q ≃ₗᵢ[ℝ] StrongDual ℝ (lp (fun _ : ℕ => ℝ) p),
      ∀ (w : lp (fun _ : ℕ => ℝ) q) (x : lp (fun _ : ℕ => ℝ) p),
        e w x = ∑' n, w n * x n := by
  have hK : ∀ _ : ℕ, ‖ContinuousLinearMap.mul ℝ ℝ‖ ≤ ((1 : NNReal) : ℝ) := fun _ => by
    simp
  set Λ := lp.dualPairing q p (fun _ : ℕ => ContinuousLinearMap.mul ℝ ℝ) hK with hΛ
  have hΛapp : ∀ w x, Λ w x = ∑' n, w n * x n := fun w x => by
    rw [hΛ, lp.dualPairing_apply]; simp
  have hΛn : ‖Λ‖ ≤ 1 := by simpa using lp.norm_dualPairing (p := q) (q := p) _ hK
  have hp0 : 0 < p := zero_lt_one.trans_le Fact.out
  choose hmem hnorm using fun φ => lp_weights_mem (q := q) hp φ _ (fun _ => rfl)
  let Ψ : StrongDual ℝ (lp (fun _ : ℕ => ℝ) p) → lp (fun _ : ℕ => ℝ) q :=
    fun φ => ⟨_, hmem φ⟩
  have hΨΛ : ∀ w, Ψ (Λ w) = w := by
    intro w
    ext n
    show Λ w (lp.single p n (1:ℝ)) = w n
    rw [hΛapp, tsum_eq_single n]
    · simp
    · intro m hm; simp [hm]
  have hΛΨ : ∀ φ, Λ (Ψ φ) = φ := by
    intro φ
    ext x
    rw [hΛapp]
    have hs := (lp.hasSum_single hp x).mapL φ
    refine (HasSum.tsum_eq ?_)
    convert hs using 1
    funext i
    show φ (lp.single p i (1:ℝ)) * x i = φ (lp.single p i (x i))
    have : (lp.single p i (x i) : lp (fun _ : ℕ => ℝ) p) = x i • lp.single p i (1:ℝ) := by
      rw [← lp.single_smul]; simp
    rw [this, map_smul, smul_eq_mul, mul_comm]
  have hiso : ∀ w, ‖Λ w‖ = ‖w‖ := by
    intro w
    apply le_antisymm
    · calc ‖Λ w‖ ≤ ‖Λ‖ * ‖w‖ := Λ.le_opNorm w
        _ ≤ 1 * ‖w‖ := by gcongr
        _ = ‖w‖ := one_mul _
    · calc ‖w‖ = ‖Ψ (Λ w)‖ := by rw [hΨΛ]
        _ ≤ ‖Λ w‖ := hnorm _
  let L : lp (fun _ : ℕ => ℝ) q →ₗᵢ[ℝ] StrongDual ℝ (lp (fun _ : ℕ => ℝ) p) :=
    { toLinearMap := Λ.toLinearMap, norm_map' := hiso }
  have hsurj : Function.Surjective L := fun φ => ⟨Ψ φ, hΛΨ φ⟩
  exact ⟨LinearIsometryEquiv.ofSurjective L hsurj, fun w x => hΛapp w x⟩

/-- The dual of L^p, for 1 ≤ p < ∞ and q the conjugate exponent, on a measure space whose
measure is σ-finite when p = 1: integrals against weight functions give an exact match between
g in L^q and the bounded linear functionals on L^p. Every functional is f ↦ ∫ g f dμ for exactly
one g in L^q, and its norm is exactly ‖g‖_q. -/
theorem dual_of_Lp_is_Lq_by_integrals {α : Type*} [MeasurableSpace α] (μ : Measure α)
    {p q : ℝ≥0∞} [Fact (1 ≤ p)] [Fact (1 ≤ q)] [p.HolderConjugate q] (hp : p ≠ ∞)
    (hσ : p = 1 → SigmaFinite μ) :
    ∃ e : Lp ℝ q μ ≃ₗᵢ[ℝ] StrongDual ℝ (Lp ℝ p μ),
      ∀ (g : Lp ℝ q μ) (f : Lp ℝ p μ), e g f = ∫ a, g a * f a ∂μ := by
  let Λ := ContinuousLinearMap.lpPairing μ q p (ContinuousLinearMap.mul ℝ ℝ)
  have hiso : ∀ g, ‖Λ g‖ = ‖g‖ := fun g =>
    le_antisymm (lpPair_norm_le g) (norm_le_lpPair hp hσ g)
  let L : Lp ℝ q μ →ₗᵢ[ℝ] StrongDual ℝ (Lp ℝ p μ) :=
    { toLinearMap := Λ.toLinearMap, norm_map' := hiso }
  exact ⟨LinearIsometryEquiv.ofSurjective L (fun φ => lpPair_surj hp hσ φ),
    fun g f => lpPair_apply g f⟩

/-- The transpose of a bounded operator T : X → Y, which sends a functional ψ on Y to the
functional x ↦ ψ (T x) on X, has exactly the norm of T, and its kernel is the annihilator of the
range of T: the functionals that give 0 on every output of T. -/
theorem transpose_norm_and_kernel {X Y : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    [NormedAddCommGroup Y] [NormedSpace ℝ Y] (T : X →L[ℝ] Y) :
    ‖(ContinuousLinearMap.compL ℝ X Y ℝ).flip T‖ = ‖T‖ ∧
      {ψ : StrongDual ℝ Y | (ContinuousLinearMap.compL ℝ X Y ℝ).flip T ψ = 0} =
        {ψ : StrongDual ℝ Y | ∀ y ∈ Set.range T, ψ y = 0} := by
  have happly : ∀ ψ : StrongDual ℝ Y,
      (ContinuousLinearMap.compL ℝ X Y ℝ).flip T ψ = ψ.comp T := fun ψ => rfl
  refine ⟨le_antisymm ?_ ?_, ?_⟩
  · refine ContinuousLinearMap.opNorm_le_bound _ (norm_nonneg _) fun ψ => ?_
    rw [happly, mul_comm]
    exact ψ.opNorm_comp_le T
  · refine T.opNorm_le_bound (by positivity) fun x => ?_
    obtain ⟨ψ, hψ1, hψ2⟩ := exists_dual_vector'' ℝ (T x)
    calc ‖T x‖ = ψ (T x) := hψ2.symm
      _ ≤ ‖ψ (T x)‖ := Real.le_norm_self _
      _ = ‖(ContinuousLinearMap.compL ℝ X Y ℝ).flip T ψ x‖ := by rw [happly]; rfl
      _ ≤ ‖(ContinuousLinearMap.compL ℝ X Y ℝ).flip T ψ‖ * ‖x‖ :=
          ContinuousLinearMap.le_opNorm _ _
      _ ≤ ‖(ContinuousLinearMap.compL ℝ X Y ℝ).flip T‖ * ‖ψ‖ * ‖x‖ := by
          gcongr; exact ContinuousLinearMap.le_opNorm _ _
      _ ≤ ‖(ContinuousLinearMap.compL ℝ X Y ℝ).flip T‖ * 1 * ‖x‖ := by gcongr
      _ = _ := by ring
  · ext ψ
    simp only [Set.mem_ofPred_eq, happly, Set.mem_range, forall_exists_index,
      forall_apply_eq_imp_iff]
    constructor
    · intro h x
      have := congrArg (fun L : StrongDual ℝ X => L x) h
      simpa using this
    · intro h
      ext x
      simpa using h x

/-! The café's day: sales x (pounds) and head office's weights w, over eight hours. -/

-- The score of the day is 1,710.
example : ∑ i : Fin 8, (![3/2, 1, 1, 1/2, 1/2, 1, 3/2, 1] : Fin 8 → ℚ) i *
    (![120, 340, 260, 410, 380, 150, 90, 250] : Fin 8 → ℚ) i = 1710 := by
  norm_num [Fin.sum_univ_succ]

-- Total takings are £2,000.
example : ∑ i : Fin 8, (![120, 340, 260, 410, 380, 150, 90, 250] : Fin 8 → ℚ) i = 2000 := by
  norm_num [Fin.sum_univ_succ]

-- Busiest-hour sizing: the rule's norm is the weights' total, 8.
example : ∑ i : Fin 8, |(![3/2, 1, 1, 1/2, 1/2, 1, 3/2, 1] : Fin 8 → ℚ) i| = 8 := by
  norm_num [Fin.sum_univ_succ]

-- Root-sum-square sizing: the weights' squares add to 9, so the rule's norm is √9 = 3.
example : ∑ i : Fin 8, (![3/2, 1, 1, 1/2, 1/2, 1, 3/2, 1] : Fin 8 → ℚ) i ^ 2 = 9 := by
  norm_num [Fin.sum_univ_succ]

-- Total-takings sizing: the rule's norm is the largest weight, 3/2, reached at 9:00.
example : (∀ i : Fin 8, |(![3/2, 1, 1, 1/2, 1/2, 1, 3/2, 1] : Fin 8 → ℚ) i| ≤ 3/2) ∧
    (![3/2, 1, 1, 1/2, 1/2, 1, 3/2, 1] : Fin 8 → ℚ) 0 = 3/2 := by
  refine ⟨fun i => ?_, by norm_num⟩
  fin_cases i <;> norm_num

-- The running totals S x.
example : (Matrix.of fun i j : Fin 8 => if j ≤ i then (1 : ℤ) else 0) *ᵥ
    ![120, 340, 260, 410, 380, 150, 90, 250] = ![120, 460, 720, 1130, 1510, 1660, 1750, 2000] := by
  decide

-- Pulling back ψ = (reading at noon) + (reading at close) through the transpose gives the
-- weights (2, 2, 2, 1, 1, 1, 1, 1).
example : (Matrix.of fun i j : Fin 8 => if j ≤ i then (1 : ℤ) else 0)ᵀ *ᵥ
    ![0, 0, 1, 0, 0, 0, 0, 1] = ![2, 2, 2, 1, 1, 1, 1, 1] := by
  decide

-- Both ways of reading give 2,720: ψ(S x) = (Sᵀ ψ)(x).
example : (![2, 2, 2, 1, 1, 1, 1, 1] : Fin 8 → ℤ) ⬝ᵥ ![120, 340, 260, 410, 380, 150, 90, 250]
    = 2720 ∧ (![0, 0, 1, 0, 0, 0, 0, 1] : Fin 8 → ℤ) ⬝ᵥ
      ![120, 460, 720, 1130, 1510, 1660, 1750, 2000] = 2720 := by
  decide

-- Pulling back with S instead of its transpose gives the wrong 1,790.
example : ((Matrix.of fun i j : Fin 8 => if j ≤ i then (1 : ℤ) else 0) *ᵥ
    ![0, 0, 1, 0, 0, 0, 0, 1]) ⬝ᵥ ![120, 340, 260, 410, 380, 150, 90, 250] = 1790 := by
  decide

-- The reshuffle (£50 moved from 12:00 to 15:00): head office's rule scores +50, total takings 0.
example : (![3/2, 1, 1, 1/2, 1/2, 1, 3/2, 1] : Fin 8 → ℚ) ⬝ᵥ ![0, 0, 0, -50, 0, 0, 50, 0] = 50 ∧
    (![1, 1, 1, 1, 1, 1, 1, 1] : Fin 8 → ℚ) ⬝ᵥ ![0, 0, 0, -50, 0, 0, 50, 0] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_succ]

#print axioms dual_of_lp_is_lq_by_weighted_sums
#print axioms dual_of_Lp_is_Lq_by_integrals
#print axioms transpose_norm_and_kernel
