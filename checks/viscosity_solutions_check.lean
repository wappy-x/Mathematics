-- Viscosity solutions: on a road [0, L], a viscosity subsolution of max(u - ψ, |u'| - c) = 0 that starts below a supersolution at both ends stays below it everywhere, so the least cost min(ψ, c x, c (L - x)) is the only viscosity solution with zero end values.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Topology.Order.Compact
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul

open Set Filter Topology
open scoped ContDiff

/-- The left side of the tow equation at value `r` and slope `p`:
`F(r, p) = max(r - ψ, |p| - c)`, with `ψ` the tow fee and `c` the damage per km. -/
noncomputable def towF (c ψ r p : ℝ) : ℝ := max (r - ψ) (|p| - c)

/-- `φ` touches `u` from above at `x₀`: equal there, and `φ ≥ u` near `x₀`. -/
def TouchesAbove (φ u : ℝ → ℝ) (x₀ : ℝ) : Prop :=
  φ x₀ = u x₀ ∧ ∀ᶠ x in 𝓝 x₀, u x ≤ φ x

/-- `φ` touches `u` from below at `x₀`: equal there, and `φ ≤ u` near `x₀`. -/
def TouchesBelow (φ u : ℝ → ℝ) (x₀ : ℝ) : Prop :=
  φ x₀ = u x₀ ∧ ∀ᶠ x in 𝓝 x₀, φ x ≤ u x

/-- A viscosity subsolution of `max(u - ψ, |u'| - c) = 0` on the road `0 < x < L`:
`u` is continuous on `[0, L]`, and every smooth `φ` touching `u` from above at an
interior point `x₀` gives `F(u(x₀), φ'(x₀)) ≤ 0`. -/
def IsViscositySubsolution (c ψ L : ℝ) (u : ℝ → ℝ) : Prop :=
  ContinuousOn u (Icc 0 L) ∧
    ∀ x₀ ∈ Ioo 0 L, ∀ φ : ℝ → ℝ, ContDiff ℝ ∞ φ → TouchesAbove φ u x₀ →
      towF c ψ (u x₀) (deriv φ x₀) ≤ 0

/-- A viscosity supersolution: `u` is continuous on `[0, L]`, and every smooth `φ`
touching `u` from below at an interior point `x₀` gives `F(u(x₀), φ'(x₀)) ≥ 0`. -/
def IsViscositySupersolution (c ψ L : ℝ) (u : ℝ → ℝ) : Prop :=
  ContinuousOn u (Icc 0 L) ∧
    ∀ x₀ ∈ Ioo 0 L, ∀ φ : ℝ → ℝ, ContDiff ℝ ∞ φ → TouchesBelow φ u x₀ →
      0 ≤ towF c ψ (u x₀) (deriv φ x₀)

/-- A viscosity solution is both a subsolution and a supersolution. -/
def IsViscositySolution (c ψ L : ℝ) (u : ℝ → ℝ) : Prop :=
  IsViscositySubsolution c ψ L u ∧ IsViscositySupersolution c ψ L u

/-- The least cost from a breakdown at km `x`: stop for the tow at `ψ`, or drive to the
garage at km 0 or km `L` at `c` per km. -/
noncomputable def leastCost (c ψ L x : ℝ) : ℝ := min ψ (min (c * x) (c * (L - x)))


/-- A one-sided slope bound from the right gives an upper bound on the derivative. -/
theorem deriv_le_of_right {f : ℝ → ℝ} {a f' m : ℝ} (hd : HasDerivAt f f' a)
    (h : ∀ᶠ x in 𝓝 a, a < x → f x - f a ≤ m * (x - a)) : f' ≤ m := by
  have ht := (hasDerivAt_iff_tendsto_slope.1 hd).mono_left
    (nhdsWithin_mono a (fun y (hy : y ∈ Ioi a) => (ne_of_gt hy : y ≠ a)))
  refine le_of_tendsto ht ?_
  rw [eventually_nhdsWithin_iff]
  filter_upwards [h] with x hx hxa
  have hxa' : a < x := hxa
  rw [slope_def_field, div_le_iff₀ (by linarith)]
  exact hx hxa'

/-- A one-sided slope bound from the right gives a lower bound on the derivative. -/
theorem le_deriv_of_right {f : ℝ → ℝ} {a f' m : ℝ} (hd : HasDerivAt f f' a)
    (h : ∀ᶠ x in 𝓝 a, a < x → m * (x - a) ≤ f x - f a) : m ≤ f' := by
  have ht := (hasDerivAt_iff_tendsto_slope.1 hd).mono_left
    (nhdsWithin_mono a (fun y (hy : y ∈ Ioi a) => (ne_of_gt hy : y ≠ a)))
  refine ge_of_tendsto ht ?_
  rw [eventually_nhdsWithin_iff]
  filter_upwards [h] with x hx hxa
  have hxa' : a < x := hxa
  rw [slope_def_field, le_div_iff₀ (by linarith)]
  exact hx hxa'

/-- A one-sided slope bound from the left gives a lower bound on the derivative. -/
theorem le_deriv_of_left {f : ℝ → ℝ} {a f' m : ℝ} (hd : HasDerivAt f f' a)
    (h : ∀ᶠ x in 𝓝 a, x < a → f x - f a ≤ m * (x - a)) : m ≤ f' := by
  have ht := (hasDerivAt_iff_tendsto_slope.1 hd).mono_left
    (nhdsWithin_mono a (fun y (hy : y ∈ Iio a) => (ne_of_lt hy : y ≠ a)))
  refine ge_of_tendsto ht ?_
  rw [eventually_nhdsWithin_iff]
  filter_upwards [h] with x hx hxa
  have hxa' : x < a := hxa
  rw [slope_def_field, le_div_iff_of_neg (by linarith)]
  exact hx hxa'

/-- A one-sided slope bound from the left gives an upper bound on the derivative. -/
theorem deriv_le_of_left {f : ℝ → ℝ} {a f' m : ℝ} (hd : HasDerivAt f f' a)
    (h : ∀ᶠ x in 𝓝 a, x < a → m * (x - a) ≤ f x - f a) : f' ≤ m := by
  have ht := (hasDerivAt_iff_tendsto_slope.1 hd).mono_left
    (nhdsWithin_mono a (fun y (hy : y ∈ Iio a) => (ne_of_lt hy : y ≠ a)))
  refine le_of_tendsto ht ?_
  rw [eventually_nhdsWithin_iff]
  filter_upwards [h] with x hx hxa
  have hxa' : x < a := hxa
  rw [slope_def_field, div_le_iff_of_neg (by linarith)]
  exact hx hxa'

/-- Localized touching from above for a subsolution: maximizing `w` minus a tilted parabola
around `x₀` gives a nearby touching point where the slope and value bounds hold. -/
theorem sub_drift {c ψ L : ℝ} {w : ℝ → ℝ} (hw : IsViscositySubsolution c ψ L w) {x₀ r : ℝ}
    (hr : 0 < r) (h0 : 0 ≤ x₀ - r) (hL : x₀ + r ≤ L) (p : ℝ) :
    ∃ K > 0, ∃ y ∈ Ioo (x₀ - r) (x₀ + r), |p + 2 * K * (y - x₀)| ≤ c ∧ w y ≤ ψ ∧
      w x₀ + p * (y - x₀) + K * (y - x₀) ^ 2 ≤ w y := by
  set K : ℝ := (|w (x₀ - r) - w x₀| + |w (x₀ + r) - w x₀| + |p| * r + 1) / r ^ 2 with hKdef
  have hK : 0 < K := by positivity
  have hKr : K * r ^ 2 = |w (x₀ - r) - w x₀| + |w (x₀ + r) - w x₀| + |p| * r + 1 := by
    rw [hKdef]; field_simp
  set f : ℝ → ℝ := fun x => w x - (p * (x - x₀) + K * (x - x₀) ^ 2) with hf
  have hsub : Icc (x₀ - r) (x₀ + r) ⊆ Icc 0 L := Icc_subset_Icc h0 hL
  have hcont : ContinuousOn f (Icc (x₀ - r) (x₀ + r)) :=
    (hw.1.mono hsub).sub (by fun_prop)
  obtain ⟨y, hy, hmax⟩ := isCompact_Icc.exists_isMaxOn (nonempty_Icc.2 (by linarith)) hcont
  have hx₀ : x₀ ∈ Icc (x₀ - r) (x₀ + r) := ⟨by linarith, by linarith⟩
  have hfy : f x₀ ≤ f y := hmax hx₀
  have hfx₀ : f x₀ = w x₀ := by simp [hf]
  have hleft : f (x₀ - r) < w x₀ := by
    simp only [hf]
    have h1 := le_abs_self (w (x₀ - r) - w x₀)
    have h2 := le_abs_self p
    have h3 := abs_nonneg (w (x₀ + r) - w x₀)
    have h4 : p * (x₀ - r - x₀) = -(p * r) := by ring
    have h5 : K * (x₀ - r - x₀) ^ 2 = K * r ^ 2 := by ring
    rw [h4, h5]; nlinarith
  have hright : f (x₀ + r) < w x₀ := by
    simp only [hf]
    have h1 := le_abs_self (w (x₀ + r) - w x₀)
    have h2 := neg_abs_le p
    have h3 := abs_nonneg (w (x₀ - r) - w x₀)
    have h4 : p * (x₀ + r - x₀) = p * r := by ring
    have h5 : K * (x₀ + r - x₀) ^ 2 = K * r ^ 2 := by ring
    rw [h4, h5]; nlinarith
  have hyI : y ∈ Ioo (x₀ - r) (x₀ + r) := by
    refine ⟨lt_of_le_of_ne hy.1 ?_, lt_of_le_of_ne hy.2 ?_⟩
    · rintro rfl; linarith
    · rintro rfl; linarith
  set C : ℝ := w y - (p * (y - x₀) + K * (y - x₀) ^ 2) with hC
  set φ : ℝ → ℝ := fun x => p * (x - x₀) + K * (x - x₀) ^ 2 + C with hφ
  have hφs : ContDiff ℝ ∞ φ := by simp only [hφ]; fun_prop
  have htouch : TouchesAbove φ w y := by
    refine ⟨by simp only [hφ, hC]; ring, ?_⟩
    filter_upwards [Icc_mem_nhds hyI.1 hyI.2] with x hx
    have : f x ≤ f y := hmax hx
    simp only [hf] at this
    simp only [hφ, hC]; linarith
  have hderiv : HasDerivAt φ (p + 2 * K * (y - x₀)) y := by
    have h1 : HasDerivAt (fun x : ℝ => x - x₀) 1 y := (hasDerivAt_id y).sub_const x₀
    have h2 := ((h1.const_mul p).add ((h1.pow 2).const_mul K)).add_const C
    convert h2 using 1
    simp; ring
  have hyL : y ∈ Ioo 0 L := ⟨by linarith [hyI.1], by linarith [hyI.2]⟩
  have hv := hw.2 y hyL φ hφs htouch
  rw [hderiv.deriv, towF, max_le_iff] at hv
  refine ⟨K, hK, y, hyI, by linarith [hv.2], by linarith [hv.1], ?_⟩
  have : f x₀ ≤ f y := hfy
  simp only [hf] at this
  have h6 : p * (x₀ - x₀) + K * (x₀ - x₀) ^ 2 = 0 := by ring
  linarith

/-- A subsolution stays below the tow fee at every interior point. -/
theorem sub_le_fee {c ψ L : ℝ} {w : ℝ → ℝ} (hw : IsViscositySubsolution c ψ L w) {x : ℝ}
    (hx : x ∈ Ioo 0 L) : w x ≤ ψ := by
  have hr : 0 < min x (L - x) := lt_min hx.1 (by linarith [hx.2])
  obtain ⟨K, hK, y, -, -, hyψ, hy⟩ :=
    sub_drift (x₀ := x) hw hr (by linarith [min_le_left x (L - x)]) (by linarith [min_le_right x (L - x)]) 0
  nlinarith [sq_nonneg (y - x)]

/-- A subsolution cannot rise faster than `c` between two interior points. -/
theorem sub_slope_up {c ψ L : ℝ} {w : ℝ → ℝ} (hw : IsViscositySubsolution c ψ L w) {a b : ℝ}
    (ha : a ∈ Ioo 0 L) (hb : b ∈ Ioo 0 L) (hab : a ≤ b) : w b - w a ≤ c * (b - a) := by
  by_contra h
  push Not at h
  have hab' : a < b := by
    rcases eq_or_lt_of_le hab with rfl | h'
    · simp at h
    · exact h'
  set e := w b - w a - c * (b - a) with he
  have he0 : 0 < e := by linarith
  set c' := c + e / (2 * (b - a)) with hc'
  have hba : 0 < b - a := by linarith
  have hc'1 : c < c' := by have : 0 < e / (2 * (b - a)) := by positivity
                           linarith
  have hc'2 : c' * (b - a) < w b - w a := by
    have : e / (2 * (b - a)) * (b - a) = e / 2 := by field_simp
    have h3 : c' * (b - a) = c * (b - a) + e / 2 := by rw [hc', add_mul, this]
    linarith
  set g : ℝ → ℝ := fun x => w x - c' * x with hg
  have hsub : Icc a b ⊆ Icc 0 L := Icc_subset_Icc ha.1.le hb.2.le
  have hcont : ContinuousOn g (Icc a b) := (hw.1.mono hsub).sub (by fun_prop)
  obtain ⟨x₀, hx₀, hmax⟩ := isCompact_Icc.exists_isMaxOn (nonempty_Icc.2 hab) hcont
  have hgb : g b ≤ g x₀ := hmax ⟨hab, le_rfl⟩
  have hgab : g a < g b := by simp only [hg]; nlinarith
  have hax : a < x₀ := by
    rcases eq_or_lt_of_le hx₀.1 with h' | h'
    · rw [← h'] at hgb; linarith
    · exact h'
  have hr : 0 < min (x₀ - a) (L - x₀) := lt_min (by linarith) (by linarith [hx₀.2, hb.2])
  have hr1 := min_le_left (x₀ - a) (L - x₀)
  have hr2 := min_le_right (x₀ - a) (L - x₀)
  obtain ⟨K, hK, y, hy, hsl, -, hval⟩ :=
    sub_drift (x₀ := x₀) hw hr (by linarith [ha.1]) (by linarith) c'
  have hneg : y - x₀ < 0 := by
    by_contra h'
    push Not at h'
    have := le_abs_self (c' + 2 * K * (y - x₀))
    have : 0 ≤ 2 * K * (y - x₀) := by positivity
    linarith
  have hyI : y ∈ Icc a b := ⟨by linarith [hy.1], by linarith [hx₀.2]⟩
  have hgy : g y ≤ g x₀ := hmax hyI
  simp only [hg] at hgy
  have : 0 < K * (y - x₀) ^ 2 := by
    have : 0 < (y - x₀) ^ 2 := by nlinarith
    positivity
  nlinarith

/-- A subsolution cannot fall faster than `c` between two interior points. -/
theorem sub_slope_down {c ψ L : ℝ} {w : ℝ → ℝ} (hw : IsViscositySubsolution c ψ L w) {a b : ℝ}
    (ha : a ∈ Ioo 0 L) (hb : b ∈ Ioo 0 L) (hab : a ≤ b) : w a - w b ≤ c * (b - a) := by
  by_contra h
  push Not at h
  have hab' : a < b := by
    rcases eq_or_lt_of_le hab with rfl | h'
    · simp at h
    · exact h'
  set e := w a - w b - c * (b - a) with he
  have he0 : 0 < e := by linarith
  set c' := c + e / (2 * (b - a)) with hc'
  have hba : 0 < b - a := by linarith
  have hc'1 : c < c' := by have : 0 < e / (2 * (b - a)) := by positivity
                           linarith
  have hc'2 : c' * (b - a) < w a - w b := by
    have : e / (2 * (b - a)) * (b - a) = e / 2 := by field_simp
    have h3 : c' * (b - a) = c * (b - a) + e / 2 := by rw [hc', add_mul, this]
    linarith
  set g : ℝ → ℝ := fun x => w x + c' * x with hg
  have hsub : Icc a b ⊆ Icc 0 L := Icc_subset_Icc ha.1.le hb.2.le
  have hcont : ContinuousOn g (Icc a b) := (hw.1.mono hsub).add (by fun_prop)
  obtain ⟨x₀, hx₀, hmax⟩ := isCompact_Icc.exists_isMaxOn (nonempty_Icc.2 hab) hcont
  have hga : g a ≤ g x₀ := hmax ⟨le_rfl, hab⟩
  have hgab : g b < g a := by simp only [hg]; nlinarith
  have hxb : x₀ < b := by
    rcases eq_or_lt_of_le hx₀.2 with h' | h'
    · rw [h'] at hga; linarith
    · exact h'
  have hr : 0 < min (b - x₀) x₀ := lt_min (by linarith) (by linarith [hx₀.1, ha.1])
  have hr1 := min_le_left (b - x₀) x₀
  have hr2 := min_le_right (b - x₀) x₀
  obtain ⟨K, hK, y, hy, hsl, -, hval⟩ :=
    sub_drift (x₀ := x₀) hw hr (by linarith) (by linarith [hb.2]) (-c')
  have hpos : 0 < y - x₀ := by
    by_contra h'
    push Not at h'
    have := neg_abs_le (-c' + 2 * K * (y - x₀))
    have : 2 * K * (y - x₀) ≤ 0 := by
      have : 0 ≤ 2 * K * (x₀ - y) := by
        have : 0 ≤ x₀ - y := by linarith
        positivity
      linarith
    linarith
  have hyI : y ∈ Icc a b := ⟨by linarith [hx₀.1], by linarith [hy.2]⟩
  have hgy : g y ≤ g x₀ := hmax hyI
  simp only [hg] at hgy
  have : 0 < K * (y - x₀) ^ 2 := by
    have : 0 < (y - x₀) ^ 2 := by positivity
    positivity
  nlinarith

/-- A subsolution is `c`-Lipschitz on the open road. -/
theorem sub_lipschitz {c ψ L : ℝ} {w : ℝ → ℝ} (hw : IsViscositySubsolution c ψ L w) {x y : ℝ}
    (hx : x ∈ Ioo 0 L) (hy : y ∈ Ioo 0 L) : w x - w y ≤ c * |x - y| := by
  rcases le_total x y with h | h
  · rw [abs_of_nonpos (by linarith)]
    have := sub_slope_down hw hx hy h
    linarith
  · rw [abs_of_nonneg (by linarith)]
    exact sub_slope_up hw hy hx h

/-- A supersolution cannot sit above a cone of slope `k < c` with vertex at an interior point
where it is below the tow fee: a smoothed cone would touch it from below with slope below `c`. -/
theorem super_no_cone {c ψ L : ℝ} {z : ℝ → ℝ} (hz : IsViscositySupersolution c ψ L z) {xh k : ℝ}
    (hxhI : xh ∈ Ioo 0 L) (hzψ : z xh < ψ) (hk0 : 0 ≤ k) (hkc : k < c)
    (hcone : ∀ y ∈ Ioo 0 L, z xh - k * |y - xh| ≤ z y) : False := by
  set r := min xh (L - xh) / 2 with hr
  have hmin0 : 0 < min xh (L - xh) := lt_min hxhI.1 (by linarith [hxhI.2])
  have hr0 : 0 < r := by positivity
  have hr1 : r < xh := by have := min_le_left xh (L - xh); linarith
  have hr2 : r < L - xh := by have := min_le_right xh (L - xh); linarith
  set c' := (k + c) / 2 with hc'
  have hc'θ : k < c' := by rw [hc']; linarith
  have hc'c : c' < c := by rw [hc']; linarith
  have hc'0 : 0 < c' := by linarith
  set δ := (c' - k) * r / (2 * c') with hδ
  have hδ0 : 0 < δ := by
    have : 0 < c' - k := by linarith
    positivity
  have hc'δ : c' * δ = (c' - k) * r / 2 := by rw [hδ]; field_simp
  have hpos : ∀ y : ℝ, 0 < (y - xh) ^ 2 + δ ^ 2 := fun y => by
    have := sq_nonneg (y - xh); have := pow_pos hδ0 2; linarith
  set φ₀ : ℝ → ℝ := fun y => z xh - c' * (√((y - xh) ^ 2 + δ ^ 2) - δ) with hφ₀
  set G : ℝ → ℝ := fun y => z y - φ₀ y with hG
  have hsubI : Icc (xh - r) (xh + r) ⊆ Ioo 0 L :=
    fun y hy => ⟨by linarith [hy.1], by linarith [hy.2]⟩
  have hGc : ContinuousOn G (Icc (xh - r) (xh + r)) :=
    (hz.1.mono (hsubI.trans Ioo_subset_Icc_self)).sub (by simp only [hφ₀]; fun_prop)
  obtain ⟨ys, hys, hmin⟩ :=
    isCompact_Icc.exists_isMinOn (nonempty_Icc.2 (by linarith)) hGc
  have hGxh : G xh = 0 := by
    simp only [hG, hφ₀, sub_self]
    rw [show (0 : ℝ) ^ 2 + δ ^ 2 = δ ^ 2 by ring, Real.sqrt_sq hδ0.le]; ring
  have hGlow : ∀ y ∈ Ioo 0 L, (c' - k) * |y - xh| - c' * δ ≤ G y := by
    intro y hy
    have h1 := hcone y hy
    have h2 : |y - xh| ≤ √((y - xh) ^ 2 + δ ^ 2) :=
      Real.abs_le_sqrt (by have := sq_nonneg δ; linarith)
    have h3 : c' * |y - xh| ≤ c' * √((y - xh) ^ 2 + δ ^ 2) :=
      mul_le_mul_of_nonneg_left h2 hc'0.le
    simp only [hG, hφ₀]
    nlinarith
  have hGys : G ys ≤ 0 := hGxh ▸ hmin ⟨by linarith, by linarith⟩
  have hysI : ys ∈ Ioo (xh - r) (xh + r) := by
    refine ⟨lt_of_le_of_ne hys.1 ?_, lt_of_le_of_ne hys.2 ?_⟩
    · rintro h
      have := hGlow (xh - r) (hsubI ⟨le_rfl, by linarith⟩)
      rw [show xh - r - xh = -r by ring, abs_neg, abs_of_pos hr0, h] at this
      have hp : 0 < (c' - k) * r := mul_pos (by linarith) hr0
      linarith
    · rintro h
      have := hGlow (xh + r) (hsubI ⟨by linarith, le_rfl⟩)
      rw [show xh + r - xh = r by ring, abs_of_pos hr0, ← h] at this
      have hp : 0 < (c' - k) * r := mul_pos (by linarith) hr0
      linarith
  have hysL : ys ∈ Ioo 0 L := hsubI hys
  have hzys : z ys < ψ := by
    have h1 : δ ≤ √((ys - xh) ^ 2 + δ ^ 2) := by
      have := Real.abs_le_sqrt (x := δ) (y := (ys - xh) ^ 2 + δ ^ 2)
        (by have := sq_nonneg (ys - xh); linarith)
      rwa [abs_of_pos hδ0] at this
    have h2 : 0 ≤ c' * (√((ys - xh) ^ 2 + δ ^ 2) - δ) :=
      mul_nonneg hc'0.le (by linarith)
    simp only [hG, hφ₀] at hGys
    linarith
  set φ : ℝ → ℝ := fun y => φ₀ y + G ys with hφ
  have hφs : ContDiff ℝ ∞ φ := by
    simp only [hφ, hφ₀]
    exact (contDiff_const.sub (contDiff_const.mul
      ((ContDiff.sqrt (by fun_prop) (fun y => (hpos y).ne')).sub contDiff_const))).add
      contDiff_const
  have htouch : TouchesBelow φ z ys := by
    refine ⟨by simp only [hφ, hG]; ring, ?_⟩
    filter_upwards [Icc_mem_nhds hysI.1 hysI.2] with y hy
    have : G ys ≤ G y := hmin hy
    simp only [hφ]
    simp only [hG] at this ⊢
    linarith
  set S := √((ys - xh) ^ 2 + δ ^ 2) with hS
  have hS0 : 0 < S := Real.sqrt_pos.2 (hpos ys)
  have hderiv : HasDerivAt φ (-(c' * (2 * (ys - xh) / (2 * S)))) ys := by
    have h1 : HasDerivAt (fun y : ℝ => (y - xh) ^ 2 + δ ^ 2) (2 * (ys - xh)) ys := by
      have := (((hasDerivAt_id ys).sub_const xh).pow 2).add_const (δ ^ 2)
      convert this using 1 <;> simp
    have h2 := ((((h1.sqrt (hpos ys).ne').sub_const δ).const_mul c').const_sub
      (z xh)).add_const (G ys)
    exact h2
  have hdb : |-(c' * (2 * (ys - xh) / (2 * S)))| ≤ c' := by
    rw [abs_neg, abs_mul, abs_of_pos hc'0]
    have : |2 * (ys - xh) / (2 * S)| ≤ 1 := by
      rw [abs_div, abs_of_pos (by positivity : (0 : ℝ) < 2 * S), div_le_one (by positivity),
        abs_mul, abs_two]
      have : |ys - xh| ≤ S := Real.abs_le_sqrt (by have := sq_nonneg δ; linarith)
      linarith
    nlinarith [abs_nonneg (2 * (ys - xh) / (2 * S))]
  have hsup := hz.2 ys hysL φ hφs htouch
  rw [hderiv.deriv, towF, le_max_iff] at hsup
  rcases hsup with h | h
  · linarith
  · linarith

/-- Comparison principle for the tow equation: if the damage rate `c` and the tow fee `ψ`
are positive, `w` is a viscosity subsolution, `z` a viscosity supersolution, and `w ≤ z` at
both garages, then `w ≤ z` at every place on the road. -/
theorem comparison_principle_tow {c ψ L : ℝ} (hc : 0 < c) (hψ : 0 < ψ) {w z : ℝ → ℝ}
    (hw : IsViscositySubsolution c ψ L w) (hz : IsViscositySupersolution c ψ L z)
    (h0 : w 0 ≤ z 0) (hL : w L ≤ z L) :
    ∀ x ∈ Icc 0 L, w x ≤ z x := by
  intro x hx
  by_contra hlt
  push Not at hlt
  have hx0 : x ≠ 0 := by rintro rfl; linarith
  have hxL : x ≠ L := by rintro rfl; linarith
  have hxI : x ∈ Ioo 0 L := ⟨lt_of_le_of_ne hx.1 (Ne.symm hx0), lt_of_le_of_ne hx.2 hxL⟩
  set d := w x - z x with hd
  have hd0 : 0 < d := by linarith
  set a := min (min (w 0) (w L)) ψ with ha
  have ha0 : a ≤ w 0 := (min_le_left _ _).trans (min_le_left _ _)
  have haL : a ≤ w L := (min_le_left _ _).trans (min_le_right _ _)
  have haψ : a ≤ ψ := min_le_right _ _
  set m := |w x - a| with hm
  have hm0 : 0 ≤ m := abs_nonneg _
  set ε := d / (2 * (m + d)) with hε
  have hε0 : 0 < ε := by positivity
  have hε1 : ε ≤ 1 / 2 := by
    rw [hε, div_le_iff₀ (by positivity)]; linarith
  have hεd : ε * (w x - a) < d := by
    have h1 : ε * (w x - a) ≤ ε * m := mul_le_mul_of_nonneg_left (le_abs_self _) hε0.le
    have h2 : ε * m < d := by
      rw [hε, div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]; nlinarith
    linarith
  set θ := 1 - ε with hθ
  set D : ℝ → ℝ := fun y => θ * w y + ε * a - z y with hD
  have hDc : ContinuousOn D (Icc 0 L) :=
    ((continuousOn_const.mul hw.1).add continuousOn_const).sub hz.1
  obtain ⟨xh, hxh, hmax⟩ := isCompact_Icc.exists_isMaxOn ⟨x, hx⟩ hDc
  have hDx : 0 < D x := by
    have : D x = d - ε * (w x - a) := by simp only [hD, hd, hθ]; ring
    linarith
  have hDxh : D x ≤ D xh := hmax hx
  have hD0 : D 0 ≤ 0 := by
    have : ε * a ≤ ε * w 0 := mul_le_mul_of_nonneg_left ha0 hε0.le
    have : D 0 = w 0 - z 0 + (ε * a - ε * w 0) := by simp only [hD, hθ]; ring
    linarith
  have hDL : D L ≤ 0 := by
    have : ε * a ≤ ε * w L := mul_le_mul_of_nonneg_left haL hε0.le
    have : D L = w L - z L + (ε * a - ε * w L) := by simp only [hD, hθ]; ring
    linarith
  have hxhI : xh ∈ Ioo 0 L := by
    refine ⟨lt_of_le_of_ne hxh.1 ?_, lt_of_le_of_ne hxh.2 ?_⟩
    · rintro h; rw [← h] at hDxh; linarith
    · rintro h; rw [h] at hDxh; linarith
  have hθ0 : 0 ≤ θ := by linarith
  have hzψ : z xh < ψ := by
    have h1 : w xh ≤ ψ := sub_le_fee hw hxhI
    have h2 : θ * w xh ≤ θ * ψ := mul_le_mul_of_nonneg_left h1 hθ0
    have h3 : ε * a ≤ ε * ψ := mul_le_mul_of_nonneg_left haψ hε0.le
    have h4 : 0 < θ * w xh + ε * a - z xh := by
      have : D xh = θ * w xh + ε * a - z xh := rfl
      linarith
    have h5 : θ * ψ + ε * ψ = ψ := by rw [hθ]; ring
    linarith
  have hcone : ∀ y ∈ Ioo 0 L, z xh - θ * c * |y - xh| ≤ z y := by
    intro y hy
    have h1 : D y ≤ D xh := hmax (Ioo_subset_Icc_self hy)
    simp only [hD] at h1
    have h2 := sub_lipschitz hw hxhI hy
    rw [abs_sub_comm] at h2
    have h3 : θ * (w xh - w y) ≤ θ * (c * |y - xh|) := mul_le_mul_of_nonneg_left h2 hθ0
    nlinarith
  have hk0 : 0 ≤ θ * c := mul_nonneg hθ0 hc.le
  have hkc : θ * c < c := by rw [hθ]; nlinarith
  exact super_no_cone hz hxhI hzψ hk0 hkc hcone

/-- The least cost `min(ψ, c x, c (L - x))` is a viscosity solution of
`max(u - ψ, |u'| - c) = 0` on the road `0 < x < L`, and it is zero at both garages. -/
theorem least_cost_is_viscosity_solution {c ψ L : ℝ} (hc : 0 < c) (hψ : 0 < ψ) (hL : 0 < L) :
    IsViscositySolution c ψ L (leastCost c ψ L) ∧
      leastCost c ψ L 0 = 0 ∧ leastCost c ψ L L = 0 := by
  have hLip : ∀ x y, |leastCost c ψ L x - leastCost c ψ L y| ≤ c * |x - y| := by
    intro x y
    have e1 : |c * x - c * y| = c * |x - y| := by rw [← mul_sub, abs_mul, abs_of_pos hc]
    have e2 : |c * (L - x) - c * (L - y)| = c * |x - y| := by
      rw [show c * (L - x) - c * (L - y) = c * (y - x) by ring, abs_mul, abs_of_pos hc,
        abs_sub_comm]
    unfold leastCost
    calc |min ψ (min (c * x) (c * (L - x))) - min ψ (min (c * y) (c * (L - y)))|
        ≤ max |ψ - ψ| |min (c * x) (c * (L - x)) - min (c * y) (c * (L - y))| :=
          abs_min_sub_min_le_max _ _ _ _
      _ ≤ c * |x - y| := by
          refine max_le (by simp only [sub_self, abs_zero]; positivity) ?_
          exact (abs_min_sub_min_le_max _ _ _ _).trans (max_le e1.le e2.le)
  have hcont : Continuous (leastCost c ψ L) := by
    unfold leastCost
    exact continuous_const.min ((continuous_const.mul continuous_id).min
      (continuous_const.mul (continuous_const.sub continuous_id)))
  have hle : ∀ x, leastCost c ψ L x ≤ ψ := fun x => min_le_left _ _
  refine ⟨⟨⟨hcont.continuousOn, ?_⟩, ⟨hcont.continuousOn, ?_⟩⟩, ?_, ?_⟩
  · intro x₀ _ φ hφ ⟨heq, hev⟩
    have hd : HasDerivAt φ (deriv φ x₀) x₀ :=
      ((hφ.differentiable (by simp)) x₀).hasDerivAt
    have key : ∀ᶠ x in 𝓝 x₀, -(c * |x - x₀|) ≤ φ x - φ x₀ := by
      filter_upwards [hev] with x hx
      have := (abs_le.1 (hLip x x₀)).1
      linarith
    have hup : deriv φ x₀ ≤ c := by
      refine deriv_le_of_left hd ?_
      filter_upwards [key] with x hx hxa
      rw [abs_of_neg (by linarith)] at hx
      linarith
    have hlo : -c ≤ deriv φ x₀ := by
      refine le_deriv_of_right hd ?_
      filter_upwards [key] with x hx hxa
      rw [abs_of_pos (by linarith)] at hx
      linarith
    unfold towF
    exact max_le (by linarith [hle x₀]) (by linarith [abs_le.2 ⟨hlo, hup⟩])
  · intro x₀ _ φ hφ ⟨heq, hev⟩
    have hd : HasDerivAt φ (deriv φ x₀) x₀ :=
      ((hφ.differentiable (by simp)) x₀).hasDerivAt
    unfold towF
    by_cases hψe : leastCost c ψ L x₀ = ψ
    · exact le_max_of_le_left (by rw [hψe, sub_self])
    have hT : leastCost c ψ L x₀ = min (c * x₀) (c * (L - x₀)) := by
      unfold leastCost at hψe ⊢
      rcases min_choice ψ (min (c * x₀) (c * (L - x₀))) with h | h
      · exact absurd h hψe
      · exact h
    refine le_max_of_le_right ?_
    rcases le_total (c * x₀) (c * (L - x₀)) with h | h
    · rw [min_eq_left h] at hT
      have : c ≤ deriv φ x₀ := by
        refine le_deriv_of_left hd ?_
        filter_upwards [hev] with x hx _
        have : leastCost c ψ L x ≤ c * x :=
          (min_le_right _ _).trans (min_le_left _ _)
        linarith
      linarith [le_abs_self (deriv φ x₀)]
    · rw [min_eq_right h] at hT
      have : deriv φ x₀ ≤ -c := by
        refine deriv_le_of_right hd ?_
        filter_upwards [hev] with x hx _
        have : leastCost c ψ L x ≤ c * (L - x) :=
          (min_le_right _ _).trans (min_le_right _ _)
        linarith
      linarith [neg_abs_le (deriv φ x₀)]
  · unfold leastCost
    have : min (c * 0) (c * (L - 0)) = 0 := by
      rw [mul_zero, sub_zero]; exact min_eq_left (by positivity)
    rw [this]; exact min_eq_right hψ.le
  · unfold leastCost
    have : min (c * L) (c * (L - L)) = 0 := by
      rw [sub_self, mul_zero]; exact min_eq_right (by positivity)
    rw [this]; exact min_eq_right hψ.le

/-- Uniqueness: every viscosity solution that is zero at both garages equals the least cost
at every place on the road. -/
theorem viscosity_solution_unique {c ψ L : ℝ} (hc : 0 < c) (hψ : 0 < ψ) (hL : 0 < L)
    {v : ℝ → ℝ} (hv : IsViscositySolution c ψ L v) (h0 : v 0 = 0) (hvL : v L = 0) :
    ∀ x ∈ Icc 0 L, v x = leastCost c ψ L x := by
  intro x hx
  have h := least_cost_is_viscosity_solution hc hψ hL
  exact le_antisymm
    (comparison_principle_tow hc hψ hv.1 h.1.2 (by rw [h0, h.2.1]) (by rw [hvL, h.2.2]) x hx)
    (comparison_principle_tow hc hψ h.1.1 hv.2 (by rw [h0, h.2.1]) (by rw [hvL, h.2.2]) x hx)

-- The card's road: L = 10 km, c = 30 $/km, tow ψ = 120 $.
-- Least cost from km 3: drive back, 30 × 3 = 90 $.
example : leastCost 30 120 10 3 = 90 := by norm_num [leastCost]
-- From km 5 driving costs 150 $ to either garage, so the driver stops and pays 120 $.
example : (30 : ℝ) * 5 = 150 ∧ (30 : ℝ) * (10 - 5) = 150 := by norm_num
example : leastCost 30 120 10 5 = 120 := by norm_num [leastCost]
-- Driving and towing tie at km 4 and km 6: 120 / 30 = 4 and 10 - 4 = 6.
example : (120 : ℝ) / 30 = 4 ∧ (10 : ℝ) - 4 = 6 := by norm_num
example : leastCost 30 120 10 4 = 30 * 4 ∧ leastCost 30 120 10 6 = 30 * (10 - 6) := by
  norm_num [leastCost]
-- The phantom garage min(120, 30x, 30|x - 5|, 30(10 - x)) is 0 $ at km 5.
example : min (120 : ℝ) (min (30 * 5) (min (30 * |(5 : ℝ) - 5|) (30 * (10 - 5)))) = 0 := by
  norm_num
-- Its valley at km 5: a flat line touches from below and F = max(0 - 120, 0 - 30) = -30 < 0.
example : towF 30 120 0 0 = -30 := by norm_num [towF]
-- Forgetting the tow: the tent 30 min(x, 10 - x) is 150 $ at km 5; flipping the sign gives -150 $.
example : (30 : ℝ) * min 5 (10 - 5) = 150 ∧ -((30 : ℝ) * min 5 (10 - 5)) = -150 := by norm_num
-- Try lines: a tow of 150 $ gives u(5) = 150 $; damage 20 $/km gives u(5) = 100 $.
example : leastCost 30 150 10 5 = 150 := by norm_num [leastCost]
example : leastCost 20 120 10 5 = 100 := by norm_num [leastCost]

#print axioms deriv_le_of_right
#print axioms le_deriv_of_right
#print axioms le_deriv_of_left
#print axioms deriv_le_of_left
#print axioms sub_drift
#print axioms sub_le_fee
#print axioms sub_slope_up
#print axioms sub_slope_down
#print axioms sub_lipschitz
#print axioms super_no_cone
#print axioms comparison_principle_tow
#print axioms least_cost_is_viscosity_solution
#print axioms viscosity_solution_unique
