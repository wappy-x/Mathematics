-- Numerical range: for a bounded operator on a complex Hilbert space the set of averages <x, Tx> over unit vectors is convex, holds the spectrum in its closure, has largest size w with w <= ||T|| <= 2w, and an upper bound on the averages over a flow's states makes the flow settle at that exponential rate.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Normed.Algebra.Spectrum
import Mathlib.Analysis.Normed.Operator.Basic
import Mathlib.Analysis.Convex.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.InnerProductSpace.Positive
import Mathlib.Analysis.InnerProductSpace.LinearMap
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Topology.Order.IntermediateValue

open scoped InnerProductSpace

/-! Mathlib has no numerical range, so the card's two definitions are written out here:
`numericalRange T` is the card's `W(T)` and `numericalRadius T` its `w(T)`. The inner product
`⟪x, y⟫_ℂ` conjugates its first slot, as on the card. -/

section Operators

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H]

/-- The numerical range `W(T)`: every average `⟪x, T x⟫` over unit vectors `x`. -/
def numericalRange (T : H →L[ℂ] H) : Set ℂ :=
  {z | ∃ x : H, ‖x‖ = 1 ∧ ⟪x, T x⟫_ℂ = z}

/-- The numerical radius `w(T)`: the largest size of an average, `sup {|z| : z ∈ W(T)}`. -/
noncomputable def numericalRadius (T : H →L[ℂ] H) : ℝ :=
  sSup ((fun z : ℂ => ‖z‖) '' numericalRange T)

/-! Helper lemmas for the proofs below. -/

lemma numericalRange_inner_div_mem (T : H →L[ℂ] H) {x : H} (hx : x ≠ 0) :
    ⟪x, T x⟫_ℂ / ((‖x‖ ^ 2 : ℝ) : ℂ) ∈ numericalRange T := by
  have hn : ‖x‖ ≠ 0 := norm_ne_zero_iff.2 hx
  refine ⟨((‖x‖⁻¹ : ℝ) : ℂ) • x, ?_, ?_⟩
  · rw [norm_smul, Complex.norm_real, Real.norm_eq_abs, abs_inv, abs_norm,
      inv_mul_cancel₀ hn]
  · rw [map_smul, inner_smul_left, inner_smul_right, Complex.conj_ofReal]
    push_cast
    field_simp

lemma numericalRadius_bddAbove (T : H →L[ℂ] H) :
    BddAbove ((fun z : ℂ => ‖z‖) '' numericalRange T) := by
  refine ⟨‖T‖, ?_⟩
  rintro _ ⟨_, ⟨x, hx, rfl⟩, rfl⟩
  calc ‖⟪x, T x⟫_ℂ‖ ≤ ‖x‖ * ‖T x‖ := norm_inner_le_norm _ _
    _ ≤ ‖x‖ * (‖T‖ * ‖x‖) := by gcongr; exact T.le_opNorm x
    _ = ‖T‖ := by rw [hx]; ring

lemma numericalRadius_nonneg (T : H →L[ℂ] H) : 0 ≤ numericalRadius T :=
  Real.sSup_nonneg (by rintro _ ⟨z, _, rfl⟩; exact norm_nonneg z)

lemma numericalRadius_le_opNorm (T : H →L[ℂ] H) : numericalRadius T ≤ ‖T‖ := by
  refine Real.sSup_le ?_ (norm_nonneg T)
  rintro _ ⟨_, ⟨x, hx, rfl⟩, rfl⟩
  calc ‖⟪x, T x⟫_ℂ‖ ≤ ‖x‖ * ‖T x‖ := norm_inner_le_norm _ _
    _ ≤ ‖x‖ * (‖T‖ * ‖x‖) := by gcongr; exact T.le_opNorm x
    _ = ‖T‖ := by rw [hx]; ring

lemma norm_inner_le_numericalRadius_mul (T : H →L[ℂ] H) (x : H) :
    ‖⟪x, T x⟫_ℂ‖ ≤ numericalRadius T * ‖x‖ ^ 2 := by
  by_cases hx : x = 0
  · simp [hx]
  have hpos : 0 < ‖x‖ ^ 2 := by positivity
  have hmem := numericalRange_inner_div_mem T hx
  have hle : ‖⟪x, T x⟫_ℂ / ((‖x‖ ^ 2 : ℝ) : ℂ)‖ ≤ numericalRadius T :=
    le_csSup (numericalRadius_bddAbove T) ⟨_, hmem, rfl⟩
  rw [norm_div, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hpos,
    div_le_iff₀ hpos] at hle
  exact hle

lemma norm_inner_map_le (T : H →L[ℂ] H) (x y : H) :
    ‖⟪T y, x⟫_ℂ‖ ≤ numericalRadius T * (‖x‖ ^ 2 + ‖y‖ ^ 2) := by
  have hw : ∀ z : H, ‖⟪T z, z⟫_ℂ‖ ≤ numericalRadius T * ‖z‖ ^ 2 := by
    intro z
    rw [← inner_conj_symm, RCLike.norm_conj]
    exact norm_inner_le_numericalRadius_mul T z
  have hp := inner_map_polarization (T : H →ₗ[ℂ] H) x y
  simp only [ContinuousLinearMap.coe_coe] at hp
  rw [hp]
  have h1 := hw (x + y)
  have h2 := hw (x - y)
  have h3 := hw (x + Complex.I • y)
  have h4 := hw (x - Complex.I • y)
  have pl1 := parallelogram_law_with_norm ℂ x y
  have pl2 := parallelogram_law_with_norm ℂ x (Complex.I • y)
  rw [norm_smul, Complex.norm_I, one_mul] at pl2
  set a := ⟪T (x + y), x + y⟫_ℂ
  set b := ⟪T (x - y), x - y⟫_ℂ
  set c := ⟪T (x + Complex.I • y), x + Complex.I • y⟫_ℂ
  set d := ⟪T (x - Complex.I • y), x - Complex.I • y⟫_ℂ
  have hsum : ‖(a - b + Complex.I * c - Complex.I * d) / 4‖ ≤ (‖a‖ + ‖b‖ + ‖c‖ + ‖d‖) / 4 := by
    rw [norm_div]
    have : ‖(4 : ℂ)‖ = 4 := by norm_num
    rw [this]
    gcongr
    calc ‖a - b + Complex.I * c - Complex.I * d‖
        ≤ ‖a - b + Complex.I * c‖ + ‖Complex.I * d‖ := norm_sub_le _ _
      _ ≤ ‖a - b‖ + ‖Complex.I * c‖ + ‖Complex.I * d‖ := by gcongr; exact norm_add_le _ _
      _ ≤ ‖a‖ + ‖b‖ + ‖Complex.I * c‖ + ‖Complex.I * d‖ := by gcongr; exact norm_sub_le _ _
      _ = ‖a‖ + ‖b‖ + ‖c‖ + ‖d‖ := by simp [Complex.norm_I]
  refine hsum.trans ?_
  have q1 := congrArg (fun r => numericalRadius T * r) pl1
  have q2 := congrArg (fun r => numericalRadius T * r) pl2
  linarith

lemma opNorm_le_two_mul_numericalRadius (T : H →L[ℂ] H) : ‖T‖ ≤ 2 * numericalRadius T := by
  have hw0 := numericalRadius_nonneg T
  refine T.opNorm_le_bound (by positivity) fun y => ?_
  by_cases hTy : T y = 0
  · rw [hTy, norm_zero]; positivity
  have hy : y ≠ 0 := by rintro rfl; exact hTy (map_zero T)
  have hTyp : 0 < ‖T y‖ := norm_pos_iff.2 hTy
  have hyp : 0 < ‖y‖ := norm_pos_iff.2 hy
  set r : ℝ := ‖y‖ / ‖T y‖ with hr
  have h := norm_inner_map_le T ((r : ℂ) • T y) y
  rw [inner_smul_right, inner_self_eq_norm_sq_to_K, norm_smul, norm_mul, Complex.norm_real,
    Real.norm_eq_abs, abs_of_pos (by positivity)] at h
  have e1 : r * ‖T y‖ = ‖y‖ := by rw [hr]; field_simp
  simp only [norm_pow, RCLike.norm_ofReal, abs_norm] at h
  rw [e1] at h
  have : r * ‖T y‖ ^ 2 = ‖y‖ * ‖T y‖ := by rw [← e1]; ring
  rw [this] at h
  nlinarith

lemma resolvent_aux [CompleteSpace H] (T : H →L[ℂ] H) (μ : ℂ)
    (hd : 0 < Metric.infDist μ (numericalRange T)) :
    μ ∈ resolventSet ℂ T ∧
      ‖resolvent T μ‖ ≤ 1 / Metric.infDist μ (numericalRange T) := by
  set d := Metric.infDist μ (numericalRange T) with hdd
  set A : H →L[ℂ] H := algebraMap ℂ (H →L[ℂ] H) μ - T with hA
  have hAx : ∀ x, ⟪x, A x⟫_ℂ = μ * ((‖x‖ ^ 2 : ℝ) : ℂ) - ⟪x, T x⟫_ℂ := by
    intro x
    simp [A, inner_sub_right, inner_smul_right, inner_self_eq_norm_sq_to_K]
  have hlow : ∀ x, d * ‖x‖ ^ 2 ≤ ‖⟪x, A x⟫_ℂ‖ := by
    intro x
    by_cases hx : x = 0
    · simp [hx]
    have hpos : 0 < ‖x‖ ^ 2 := by positivity
    have hmem := numericalRange_inner_div_mem T hx
    have hle := Metric.infDist_le_dist_of_mem (x := μ) hmem
    rw [← hdd, Complex.dist_eq] at hle
    have hne : ((‖x‖ ^ 2 : ℝ) : ℂ) ≠ 0 := by exact_mod_cast hpos.ne'
    have : ⟪x, A x⟫_ℂ = ((‖x‖ ^ 2 : ℝ) : ℂ) *
        (μ - ⟪x, T x⟫_ℂ / ((‖x‖ ^ 2 : ℝ) : ℂ)) := by
      rw [hAx, mul_sub, mul_div_cancel₀ _ hne, mul_comm]
    rw [this, norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hpos]
    nlinarith
  have hunit : IsUnit A := by
    refine ContinuousLinearMap.isUnit_of_forall_le_norm_inner_map A (c := ⟨d, hd.le⟩)
      (by exact_mod_cast hd) fun x => ?_
    rw [← inner_conj_symm, RCLike.norm_conj, mul_comm]
    exact hlow x
  have hbound : ∀ x, d * ‖x‖ ≤ ‖A x‖ := by
    intro x
    by_cases hx : x = 0
    · simp [hx]
    have hxp : 0 < ‖x‖ := norm_pos_iff.2 hx
    have h1 := (hlow x).trans (norm_inner_le_norm x (A x))
    nlinarith
  refine ⟨hunit, ?_⟩
  obtain ⟨u, hu⟩ := hunit
  have hres : resolvent T μ = ((u⁻¹ : (H →L[ℂ] H)ˣ) : H →L[ℂ] H) := by
    rw [resolvent, ← hA, ← hu, Ring.inverse_unit]
  rw [hres]
  set B : H →L[ℂ] H := ((u⁻¹ : (H →L[ℂ] H)ˣ) : H →L[ℂ] H) with hB
  refine ContinuousLinearMap.opNorm_le_bound _ (by positivity) fun y => ?_
  have h := hbound (B y)
  have hy : A (B y) = y := by
    have hAB : A * B = 1 := by rw [hB, ← hu, Units.mul_inv]
    have := congrArg (fun F : H →L[ℂ] H => F y) hAB
    simpa using this
  rw [hy] at h
  rw [div_mul_eq_mul_div, one_mul, le_div_iff₀ hd, mul_comm]
  exact h

lemma numericalRange_core (S : H →L[ℂ] H) {x y : H} (hx : ‖x‖ = 1) (hy : ‖y‖ = 1)
    (h0 : ⟪x, S x⟫_ℂ = 0) (h1 : ⟪y, S y⟫_ℂ = 1) {t : ℝ} (ht0 : 0 ≤ t) (ht1 : t ≤ 1) :
    (t : ℂ) ∈ numericalRange S := by
  set α := ⟪x, S y⟫_ℂ
  set β := ⟪y, S x⟫_ℂ
  obtain ⟨c, hc, hcim⟩ : ∃ c : ℂ, ‖c‖ = 1 ∧ (c * (α - (starRingEnd ℂ) β)).im = 0 := by
    by_cases hg : α - (starRingEnd ℂ) β = 0
    · exact ⟨1, by simp, by simp [hg]⟩
    set g := α - (starRingEnd ℂ) β
    have hgn : (‖g‖ : ℂ) ≠ 0 := by exact_mod_cast norm_ne_zero_iff.2 hg
    refine ⟨(starRingEnd ℂ) g / (‖g‖ : ℂ), ?_, ?_⟩
    · rw [norm_div, RCLike.norm_conj, Complex.norm_real, Real.norm_eq_abs, abs_norm,
        div_self (norm_ne_zero_iff.2 hg)]
    · have : (starRingEnd ℂ) g / (‖g‖ : ℂ) * g = ((‖g‖ : ℝ) : ℂ) := by
        rw [div_mul_eq_mul_div, Complex.conj_mul', div_eq_iff hgn]
        ring
      rw [this, Complex.ofReal_im]
  have hcc : (starRingEnd ℂ) c * c = 1 := by
    rw [Complex.conj_mul', hc]; simp
  set y' := c • y with hy'
  have hy'n : ‖y'‖ = 1 := by rw [hy', norm_smul, hc, hy, one_mul]
  have h1' : ⟪y', S y'⟫_ℂ = 1 := by
    rw [hy', map_smul, inner_smul_left, inner_smul_right, h1, mul_one]
    exact hcc
  have hmix : (⟪x, S y'⟫_ℂ + ⟪y', S x⟫_ℂ).im = 0 := by
    rw [hy', map_smul, inner_smul_left, inner_smul_right]
    have e : c * α + (starRingEnd ℂ) c * β = c * (α - (starRingEnd ℂ) β) +
        (c * (starRingEnd ℂ) β + (starRingEnd ℂ) (c * (starRingEnd ℂ) β)) := by
      simp only [map_mul, Complex.conj_conj]; ring
    rw [e, Complex.add_im, hcim, Complex.add_conj, Complex.ofReal_im]
    simp
  set z : ℝ → H := fun u => ((1 - u : ℝ) : ℂ) • x + ((u : ℝ) : ℂ) • y' with hz
  have hq : ∀ u : ℝ, ⟪z u, S (z u)⟫_ℂ = (((1 - u) * u : ℝ) : ℂ) * (⟪x, S y'⟫_ℂ + ⟪y', S x⟫_ℂ)
      + ((u ^ 2 : ℝ) : ℂ) := by
    intro u
    simp only [hz, map_add, map_smul, inner_add_left, inner_add_right, inner_smul_left,
      inner_smul_right, Complex.conj_ofReal, h0, h1']
    push_cast; ring
  have hqim : ∀ u : ℝ, (⟪z u, S (z u)⟫_ℂ).im = 0 := by
    intro u
    rw [hq u, Complex.add_im, Complex.mul_im, hmix, Complex.ofReal_im, Complex.ofReal_im]
    simp
  have hzne : ∀ u : ℝ, z u ≠ 0 := by
    intro u hu
    have e : ((u : ℝ) : ℂ) • y' = -(((1 - u : ℝ) : ℂ) • x) :=
      eq_neg_of_add_eq_zero_right hu
    have e2 := congrArg (fun w => ⟪w, S w⟫_ℂ) e
    simp only [map_smul, map_neg, inner_smul_left, inner_smul_right, inner_neg_left,
      inner_neg_right, Complex.conj_ofReal, h0, h1'] at e2
    have hu0 : u = 0 := by
      have : ((u : ℂ) * u) = 0 := by simpa using e2
      exact_mod_cast mul_self_eq_zero.1 this
    rw [hu0] at hu
    simp [hz] at hu
    rw [hu, norm_zero] at hx
    exact zero_ne_one hx
  set g : ℝ → ℝ := fun u => (⟪z u, S (z u)⟫_ℂ).re - t * ‖z u‖ ^ 2 with hg
  have hzc : Continuous z := by rw [hz]; fun_prop
  have hgc : Continuous g := by
    rw [hg]
    have : Continuous fun u => ⟪z u, S (z u)⟫_ℂ := hzc.inner (S.continuous.comp hzc)
    fun_prop
  have hg0 : g 0 = -t := by simp [hg, hz, h0, hx]
  have hg1 : g 1 = 1 - t := by simp [hg, hz, h1', hy'n]
  obtain ⟨u, -, hu⟩ : (0 : ℝ) ∈ g '' Set.Icc 0 1 := by
    apply intermediate_value_Icc zero_le_one hgc.continuousOn
    rw [hg0, hg1]; constructor <;> linarith
  have hmem := numericalRange_inner_div_mem S (hzne u)
  have hzv : ⟪z u, S (z u)⟫_ℂ = ((t * ‖z u‖ ^ 2 : ℝ) : ℂ) := by
    apply Complex.ext
    · simp only [Complex.ofReal_re]; simp only [hg] at hu; linarith
    · rw [hqim u, Complex.ofReal_im]
  have hpos : (0 : ℝ) < ‖z u‖ ^ 2 := by have := norm_pos_iff.2 (hzne u); positivity
  rw [hzv, ← Complex.ofReal_div, mul_div_cancel_right₀ _ hpos.ne'] at hmem
  exact hmem

lemma convex_numericalRange (T : H →L[ℂ] H) : Convex ℝ (numericalRange T) := by
  rintro _ ⟨x, hx, rfl⟩ _ ⟨y, hy, rfl⟩ p q hp hq hpq
  set a := ⟪x, T x⟫_ℂ with ha
  set b := ⟪y, T y⟫_ℂ with hb
  by_cases hab : a = b
  · rw [hab, ← add_smul, hpq, one_smul]; exact ⟨y, hy, hb.symm⟩
  have hba : b - a ≠ 0 := sub_ne_zero.2 (Ne.symm hab)
  set S : H →L[ℂ] H := (b - a)⁻¹ • (T - a • ContinuousLinearMap.id ℂ H) with hS
  have hSz : ∀ z : H, ‖z‖ = 1 → ⟪z, S z⟫_ℂ = (b - a)⁻¹ * (⟪z, T z⟫_ℂ - a) := by
    intro z hz
    simp [S, inner_smul_right, inner_sub_right, inner_self_eq_norm_sq_to_K, hz]
  have hS0 : ⟪x, S x⟫_ℂ = 0 := by rw [hSz x hx, ← ha, sub_self, mul_zero]
  have hS1 : ⟪y, S y⟫_ℂ = 1 := by rw [hSz y hy, ← hb, inv_mul_cancel₀ hba]
  obtain ⟨z, hz, hzS⟩ := numericalRange_core S hx hy hS0 hS1 hq (by linarith)
  refine ⟨z, hz, ?_⟩
  rw [hSz z hz] at hzS
  have hp' : p = 1 - q := by linarith
  rw [Complex.real_smul, Complex.real_smul, hp']
  field_simp at hzS
  push_cast
  linear_combination hzS

lemma spectrum_subset_closure_aux [CompleteSpace H] (T : H →L[ℂ] H) :
    spectrum ℂ T ⊆ closure (numericalRange T) := by
  intro μ hμ
  by_contra hc
  rcases (numericalRange T).eq_empty_or_nonempty with he | hne
  · have hsub : Subsingleton H := by
      refine ⟨fun a b => ?_⟩
      have h0 : ∀ x : H, x = 0 := by
        intro x
        by_contra hx
        have := numericalRange_inner_div_mem T hx
        rw [he] at this
        exact this
      rw [h0 a, h0 b]
    have : Subsingleton (H →L[ℂ] H) :=
      ⟨fun A B => ContinuousLinearMap.ext fun x => Subsingleton.elim _ _⟩
    exact hμ (isUnit_of_subsingleton _)
  · have hd := (Metric.infDist_pos_iff_notMem_closure hne).1 hc
    exact hμ (resolvent_aux T μ hd).1

variable [CompleteSpace H]

/-- The card's three facts for every bounded operator `T` on a complex Hilbert space `H`:
the averages `⟪x, T x⟫` over unit vectors form a convex set (the Toeplitz–Hausdorff theorem);
every point of the spectrum `σ(T)` is an average or a limit of averages; and the numerical
radius lies between half the norm and the norm, `w(T) ≤ ‖T‖ ≤ 2 w(T)`. -/
theorem numerical_range_convex_holds_spectrum_and_bounds_norm (T : H →L[ℂ] H) :
    Convex ℝ (numericalRange T) ∧
      spectrum ℂ T ⊆ closure (numericalRange T) ∧
      numericalRadius T ≤ ‖T‖ ∧ ‖T‖ ≤ 2 * numericalRadius T := by
  exact ⟨convex_numericalRange T, spectrum_subset_closure_aux T, numericalRadius_le_opNorm T,
      opNorm_le_two_mul_numericalRadius T⟩

/-- Step 2's resolvent bound: if a complex number `μ` is at distance `d > 0` from the numerical
range, then `μ I − T` has a bounded inverse (so `μ` is in the resolvent set) and the resolvent
`R(μ, T) = (μ I − T)⁻¹` has norm at most `1 / d`. -/
theorem resolvent_norm_le_inv_dist_numerical_range (T : H →L[ℂ] H) (μ : ℂ)
    (hd : 0 < Metric.infDist μ (numericalRange T)) :
    μ ∈ resolventSet ℂ T ∧
      ‖resolvent T μ‖ ≤ 1 / Metric.infDist μ (numericalRange T) := by
  exact resolvent_aux T μ hd

end Operators

/-- Step 5, the gap gives the settling rate. Let `L` drive an evolution `v' = L v` on an inner
product space `E` (real or complex), and let `D` be the set of states the evolution moves
through: for the bar, `v(t) = u(t) − ū`, the profiles of average zero in `L`'s domain. If every
average of `L` on `D` is at most `−γ` times the squared length, `Re ⟪v, L v⟫ ≤ −γ ‖v‖²`, then the
distance shrinks at least like `e^(−γ t)`: `‖v(t)‖ ≤ e^(−γ t) ‖v(0)‖` for every `t ≥ 0`.
With `γ` the gap `π²` this is the bar's bound; with `−γ = ω`, the top of `Re W(A)`, it is
Step 6's bound `‖e^(tA)‖ ≤ e^(ω t)`. -/
theorem distance_from_steady_state_decays_at_gap_rate
    {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]
    [NormedSpace ℝ E] [IsScalarTower ℝ 𝕜 E]
    (L : E → E) (D : Set E) (γ : ℝ)
    (hgap : ∀ w ∈ D, RCLike.re ⟪w, L w⟫_𝕜 ≤ -γ * ‖w‖ ^ 2)
    (v : ℝ → E) (hD : ∀ t, 0 ≤ t → v t ∈ D)
    (hflow : ∀ t, 0 ≤ t → HasDerivWithinAt v (L (v t)) (Set.Ici 0) t) :
    ∀ t, 0 ≤ t → ‖v t‖ ≤ Real.exp (-γ * t) * ‖v 0‖ := by
  intro t ht
  set f : ℝ → ℝ := fun s => Real.exp (2 * γ * s) * ‖v s‖ ^ 2 with hf
  have hderiv : ∀ s, 0 ≤ s → HasDerivWithinAt f
      (Real.exp (2 * γ * s) * (2 * γ) * ‖v s‖ ^ 2 +
        Real.exp (2 * γ * s) * (2 * RCLike.re ⟪v s, L (v s)⟫_𝕜)) (Set.Ici 0) s := by
    intro s hs
    have h1 := (hflow s hs).inner 𝕜 (hflow s hs)
    have h2 : HasDerivWithinAt (fun r => ‖v r‖ ^ 2)
        (2 * RCLike.re ⟪v s, L (v s)⟫_𝕜) (Set.Ici 0) s := by
      have := (RCLike.reCLM (K := 𝕜)).hasFDerivAt.comp_hasDerivWithinAt s h1
      convert this using 1
      · funext r
        simp
      · simp only [RCLike.reCLM_apply, map_add]
        rw [← inner_conj_symm (v s) (L (v s)), RCLike.conj_re]
        ring
    have h3 : HasDerivWithinAt (fun r => Real.exp (2 * γ * r))
        (Real.exp (2 * γ * s) * (2 * γ)) (Set.Ici 0) s := by
      have := ((hasDerivAt_id s).const_mul (2 * γ)).exp
      simpa using this.hasDerivWithinAt
    exact h3.mul h2
  have hanti : AntitoneOn f (Set.Ici 0) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ici 0)
      (f' := fun s => Real.exp (2 * γ * s) * (2 * γ) * ‖v s‖ ^ 2 +
        Real.exp (2 * γ * s) * (2 * RCLike.re ⟪v s, L (v s)⟫_𝕜)) ?_ ?_ ?_
    · intro s hs
      exact (hderiv s hs).continuousWithinAt
    · intro s hs
      rw [interior_Ici] at hs ⊢
      exact (hderiv s (le_of_lt hs)).mono Set.Ioi_subset_Ici_self
    · intro s hs
      rw [interior_Ici] at hs
      have hg := hgap _ (hD s (le_of_lt hs))
      have he := Real.exp_pos (2 * γ * s)
      nlinarith
  have hft : f t ≤ f 0 := hanti (Set.mem_Ici.2 le_rfl) (Set.mem_Ici.2 ht) ht
  simp only [hf, mul_zero, Real.exp_zero, one_mul] at hft
  have hsq : ‖v t‖ ^ 2 ≤ (Real.exp (-γ * t) * ‖v 0‖) ^ 2 := by
    have e1 : Real.exp (-γ * t) ^ 2 * Real.exp (2 * γ * t) = 1 := by
      rw [← Real.exp_nat_mul, ← Real.exp_add]; norm_num; ring_nf
    have he := Real.exp_pos (-γ * t)
    rw [mul_pow]
    nlinarith [sq_nonneg (Real.exp (-γ * t)), norm_nonneg (v t)]
  exact (pow_le_pow_iff_left₀ (norm_nonneg _) (by positivity) two_ne_zero).1 hsq

/-! The card's whole-number worked examples, on its 2 × 2 test matrices. -/

-- N = [[0, 1], [0, 0]] has trace 0 and determinant 0 and N² = 0, so its spectrum is {0}.
example : (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 1; 0, 0] = 0 := by decide

-- The resolvent of N at λ = 1: (I − N)⁻¹ = [[1, 1], [0, 1]].
example : ((1 : Matrix (Fin 2) (Fin 2) ℤ) - !![0, 1; 0, 0]) * !![1, 1; 0, 1] = 1 ∧
    !![1, 1; 0, 1] * ((1 : Matrix (Fin 2) (Fin 2) ℤ) - !![0, 1; 0, 0]) = 1 := by decide

-- Its size squared is the top eigenvalue of [[1, 1], [0, 1]]ᵀ [[1, 1], [0, 1]] = [[1, 1], [1, 2]],
-- trace 3 and determinant 1, whose roots are φ² and 1/φ² for the golden ratio φ.
example : (!![1, 0; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) * !![1, 1; 0, 1] = !![1, 1; 1, 2] ∧
    Matrix.det (!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℤ) = 1 := by
  refine ⟨by decide, ?_⟩
  simp [Matrix.det_fin_two]

-- The hand bounds for N: w = 1/2, ‖N‖ = 1, and 1/2 ≤ 1 ≤ 2 · 1/2, tight on the right.
example : (1 / 2 : ℚ) ≤ 1 ∧ (1 : ℚ) ≤ 2 * (1 / 2) := by norm_num

-- B = [[1, 2], [0, −1]] has B² = I, so its eigenvalues, the ellipse's foci, are 1 and −1.
example : (!![1, 2; 0, -1] : Matrix (Fin 2) (Fin 2) ℤ) * !![1, 2; 0, -1] = 1 := by decide

-- The quarter turn Q = [[0, −1], [1, 0]] has Q² = −I, so its eigenvalues are i and −i.
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, -1; 1, 0] = -1 := by decide

-- A = [[−1, 6], [0, −2]]: (A + I)(A + 2I) = 0, so its eigenvalues are −1 and −2; its
-- symmetric part (A + Aᵀ)/2 = [[−1, 3], [3, −2]] has trace −3 and determinant −7, so its top
-- eigenvalue is ω = (−3 + √37)/2, the root of λ² + 3λ − 7.
example : ((!![-1, 6; 0, -2] : Matrix (Fin 2) (Fin 2) ℤ) + 1) * (!![-1, 6; 0, -2] + 2) = 0 ∧
    (!![-1, 6; 0, -2] : Matrix (Fin 2) (Fin 2) ℤ) + (!![-1, 6; 0, -2]).transpose
      = 2 • !![-1, 3; 3, -2] := by
  decide

example : Matrix.det (!![-1, 3; 3, -2] : Matrix (Fin 2) (Fin 2) ℤ) = -7 ∧
    Matrix.trace (!![-1, 3; 3, -2] : Matrix (Fin 2) (Fin 2) ℤ) = -3 := by
  simp [Matrix.det_fin_two, Matrix.trace_fin_two]

#print axioms numerical_range_convex_holds_spectrum_and_bounds_norm
#print axioms resolvent_norm_le_inv_dist_numerical_range
#print axioms distance_from_steady_state_decays_at_gap_rate
#print axioms numericalRange_inner_div_mem
#print axioms numericalRadius_bddAbove
#print axioms numericalRadius_nonneg
#print axioms numericalRadius_le_opNorm
#print axioms norm_inner_le_numericalRadius_mul
#print axioms norm_inner_map_le
#print axioms opNorm_le_two_mul_numericalRadius
#print axioms resolvent_aux
#print axioms numericalRange_core
#print axioms convex_numericalRange
#print axioms spectrum_subset_closure_aux
