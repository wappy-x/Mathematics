-- Free boundaries: the Neumann formula solves the one-phase Stefan problem for ice at 0 °C under a lid held at T₀, its front constant λ is the one positive root of λ e^{λ²} erf λ = St/√π, and the heat through the lid equals the heat used to melt the ice plus the heat kept in the water.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Real Set

namespace StefanProblem

/-- The error function, `erf z = (2/√π) ∫₀^z e^{-u²} du`. Mathlib has no `erf`, so it is
defined here from Mathlib's interval integral, exponential, square root and `π`. -/
noncomputable def erf (z : ℝ) : ℝ :=
  2 / √π * ∫ u in (0 : ℝ)..z, exp (-u ^ 2)

/-- The Neumann front: the depth `s(t) = 2 λ √(κ t)` of the melting front at time `t`. -/
noncomputable def front (κ lam t : ℝ) : ℝ :=
  2 * lam * √(κ * t)

/-- The Neumann profile: the melt-water temperature
`T(x, t) = T₀ (1 - erf(x / (2 √(κ t))) / erf λ)`. -/
noncomputable def temp (T₀ κ lam x t : ℝ) : ℝ :=
  T₀ * (1 - erf (x / (2 * √(κ * t))) / erf lam)

lemma hasDerivAt_erf (z : ℝ) : HasDerivAt erf (2 / √π * exp (-z ^ 2)) z := by
  have h : Continuous fun u : ℝ => exp (-u ^ 2) := by fun_prop
  exact ((h.integral_hasStrictDerivAt 0 z).hasDerivAt).const_mul (2 / √π)

lemma erf_zero : erf 0 = 0 := by simp [erf]

lemma erf_strictMono : StrictMono erf :=
  strictMono_of_hasDerivAt_pos hasDerivAt_erf (fun x => by positivity)

lemma erf_pos {z : ℝ} (hz : 0 < z) : 0 < erf z := by
  simpa [erf_zero] using erf_strictMono hz

lemma deriv_erf : deriv erf = fun z => 2 / √π * exp (-z ^ 2) :=
  funext fun z => (hasDerivAt_erf z).deriv

lemma erf_contDiff : ContDiff ℝ 2 erf := by
  rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
  refine ⟨fun z => (hasDerivAt_erf z).differentiableAt, by simp, ?_⟩
  rw [deriv_erf]
  fun_prop

lemma erf_continuous : Continuous erf :=
  continuous_iff_continuousAt.2 fun z => (hasDerivAt_erf z).continuousAt

#print axioms hasDerivAt_erf
#print axioms erf_zero
#print axioms erf_strictMono
#print axioms erf_pos
#print axioms deriv_erf
#print axioms erf_contDiff
#print axioms erf_continuous

lemma hasDerivAt_temp_x (T₀ κ lam t y : ℝ) :
    HasDerivAt (fun y => temp T₀ κ lam y t)
      (-(T₀ / erf lam) * (2 / √π * exp (-(y / (2 * √(κ * t))) ^ 2)) * (1 / (2 * √(κ * t)))) y := by
  have h1 := (hasDerivAt_erf (y / (2 * √(κ * t)))).comp y ((hasDerivAt_id y).div_const (2 * √(κ * t)))
  have h2 := ((h1.div_const (erf lam)).const_sub 1).const_mul T₀
  refine h2.congr_deriv ?_
  ring

lemma deriv_temp_x (T₀ κ lam t : ℝ) :
    deriv (fun y => temp T₀ κ lam y t) = fun y =>
      -(T₀ / erf lam) * (2 / √π * exp (-(y / (2 * √(κ * t))) ^ 2)) * (1 / (2 * √(κ * t))) :=
  funext fun y => (hasDerivAt_temp_x T₀ κ lam t y).deriv

lemma hasDerivAt_temp_xx (T₀ κ lam t y : ℝ) :
    HasDerivAt (fun y =>
      -(T₀ / erf lam) * (2 / √π * exp (-(y / (2 * √(κ * t))) ^ 2)) * (1 / (2 * √(κ * t))))
      (-(T₀ / erf lam) * (2 / √π * (exp (-(y / (2 * √(κ * t))) ^ 2) *
        (-(2 * (y / (2 * √(κ * t))) * (1 / (2 * √(κ * t))))))) * (1 / (2 * √(κ * t)))) y := by
  have h0 : HasDerivAt (fun y => -(y / (2 * √(κ * t))) ^ 2)
      (-(2 * (y / (2 * √(κ * t))) * (1 / (2 * √(κ * t))))) y := by
    have := (((hasDerivAt_id y).div_const (2 * √(κ * t))).pow 2).neg
    refine this.congr_deriv ?_
    simp only [id]
    ring
  exact ((h0.exp.const_mul (2 / √π)).const_mul (-(T₀ / erf lam))).mul_const _

lemma hasDerivAt_temp_t (T₀ κ lam x t : ℝ) (hκt : 0 < κ * t) :
    HasDerivAt (fun τ => temp T₀ κ lam x τ)
      (-(T₀ / erf lam) * (2 / √π * exp (-(x / (2 * √(κ * t))) ^ 2)) *
        (-(x * (2 * (κ / (2 * √(κ * t))))) / (2 * √(κ * t)) ^ 2)) t := by
  have hA : HasDerivAt (fun τ => √(κ * τ)) (κ / (2 * √(κ * t))) t := by
    have := ((hasDerivAt_id t).const_mul κ).sqrt (by simpa using hκt.ne')
    refine this.congr_deriv ?_
    simp
  have hne : 2 * √(κ * t) ≠ 0 := by positivity
  have hq := (hasDerivAt_const t x).div (hA.const_mul 2) hne
  have h1 := (hasDerivAt_erf (x / (2 * √(κ * t)))).comp t hq
  have h2 := ((h1.div_const (erf lam)).const_sub 1).const_mul T₀
  refine h2.congr_deriv ?_
  ring

#print axioms hasDerivAt_temp_x
#print axioms deriv_temp_x
#print axioms hasDerivAt_temp_xx
#print axioms hasDerivAt_temp_t

/-- **The Neumann solution solves the Stefan problem.** Ice sits at exactly 0 °C, heat moves
only by conduction (one dimension, insulated sides), water and ice share one density `ρ`, and
the lid is held at `T₀ > 0`, so the phase being used up is not past its melting point. Let
`κ = k/(ρ c)` and let `λ > 0` solve `λ e^{λ²} erf λ = St/√π` with `St = c T₀ / L`. Then the
front `s(t) = 2λ√(κt)` and the profile `T(x, t) = T₀(1 - erf(x/2√(κt))/erf λ)` satisfy, for
every `t > 0`: the heat equation `T_t = κ T_xx` in the water `0 < x < s(t)`; the lid condition
`T(0, t) = T₀`; the front is at the melting point, `T(s(t), t) = 0`; and the Stefan condition
`ρ L s'(t) = -k T_x(s(t), t)`. Also `s(0) = 0`: no water at the start. -/
theorem neumann_solution_solves_stefan_problem
    (k ρ c L T₀ lam : ℝ) (hk : 0 < k) (hρ : 0 < ρ) (hc : 0 < c) (hL : 0 < L) (hT₀ : 0 < T₀)
    (hlam : 0 < lam)
    (hroot : lam * exp (lam ^ 2) * erf lam = (c * T₀ / L) / √π) :
    let κ := k / (ρ * c)
    front κ lam 0 = 0 ∧
    ∀ t : ℝ, 0 < t →
      (∀ x : ℝ, 0 < x → x < front κ lam t →
        ContDiffAt ℝ 2 (fun y => temp T₀ κ lam y t) x ∧
        HasDerivAt (fun τ => temp T₀ κ lam x τ)
          (κ * deriv (deriv (fun y => temp T₀ κ lam y t)) x) t) ∧
      temp T₀ κ lam 0 t = T₀ ∧
      temp T₀ κ lam (front κ lam t) t = 0 ∧
      ∃ v g : ℝ, HasDerivAt (front κ lam) v t ∧
        HasDerivAt (fun y => temp T₀ κ lam y t) g (front κ lam t) ∧
        ρ * L * v = -k * g := by
  intro κ
  have hκ : 0 < κ := div_pos hk (mul_pos hρ hc)
  have hE : 0 < erf lam := erf_pos hlam
  refine ⟨by simp [front], fun t ht => ?_⟩
  have hκt : 0 < κ * t := mul_pos hκ ht
  have hA : 0 < √(κ * t) := Real.sqrt_pos.2 hκt
  refine ⟨fun x _ _ => ⟨?_, ?_⟩, ?_, ?_, ?_⟩
  · have := erf_contDiff
    unfold temp
    fun_prop
  · rw [deriv_temp_x, (hasDerivAt_temp_xx T₀ κ lam t x).deriv]
    convert hasDerivAt_temp_t T₀ κ lam x t hκt using 1
    field_simp
  · simp [temp, erf_zero]
  · unfold temp front
    rw [show 2 * lam * √(κ * t) / (2 * √(κ * t)) = lam by field_simp]
    simp [hE.ne']
  · have hfront : HasDerivAt (front κ lam) (2 * lam * (κ / (2 * √(κ * t)))) t := by
      have := (((hasDerivAt_id t).const_mul κ).sqrt (by simpa using hκt.ne')).const_mul (2 * lam)
      refine this.congr_deriv ?_
      simp
    refine ⟨_, _, hfront, hasDerivAt_temp_x T₀ κ lam t _, ?_⟩
    unfold front
    rw [show 2 * lam * √(κ * t) / (2 * √(κ * t)) = lam by field_simp]
    have hκdef : κ = k / (ρ * c) := rfl
    have hpi : 0 < √π := Real.sqrt_pos.2 pi_pos
    have hexp : exp (lam ^ 2) * exp (-lam ^ 2) = 1 := by rw [← exp_add]; simp
    have key : lam * L * erf lam * √π = c * T₀ * exp (-lam ^ 2) := by
      have h := congrArg (fun z => z * (L * √π * exp (-lam ^ 2))) hroot
      field_simp at h
      linear_combination exp (-lam ^ 2) * h - (lam * L * erf lam * √π) * hexp
    rw [hκdef]
    field_simp
    linear_combination key

/-- **The front constant is unique.** For every Stefan number `St > 0`, the equation
`λ e^{λ²} erf λ = St/√π` has exactly one positive root `λ`. -/
theorem neumann_equation_has_unique_positive_root (St : ℝ) (hSt : 0 < St) :
    ∃! lam : ℝ, 0 < lam ∧ lam * exp (lam ^ 2) * erf lam = St / √π := by
  set y := St / √π with hydef
  have hy : 0 < y := by positivity
  have he1 := erf_pos one_pos
  have hf : Continuous fun l : ℝ => l * exp (l ^ 2) * erf l := by
    have := erf_continuous
    fun_prop
  set M := max 1 (y / erf 1)
  have hM1 : 1 ≤ M := le_max_left _ _
  have hfM : y ≤ M * exp (M ^ 2) * erf M := by
    have h1 : y ≤ M * erf 1 := by
      have := le_max_right 1 (y / erf 1)
      rwa [div_le_iff₀ he1] at this
    have h2 : erf 1 ≤ erf M := erf_strictMono.monotone hM1
    have h3 : 1 ≤ exp (M ^ 2) := one_le_exp (sq_nonneg _)
    have h4 : 0 < erf M := he1.trans_le h2
    calc y ≤ M * erf 1 := h1
      _ ≤ M * erf M := by gcongr
      _ = M * 1 * erf M := by ring
      _ ≤ M * exp (M ^ 2) * erf M := by gcongr
  obtain ⟨l, hl, hfl⟩ := intermediate_value_Icc (by linarith : (0 : ℝ) ≤ M) hf.continuousOn
    ⟨by simp [erf_zero]; linarith, hfM⟩
  simp only at hfl
  have hl0 : 0 < l := by
    rcases hl.1.eq_or_lt with h | h
    · subst h
      simp [erf_zero] at hfl
      linarith
    · exact h
  have mono : ∀ a b : ℝ, 0 < a → a < b → a * exp (a ^ 2) * erf a < b * exp (b ^ 2) * erf b := by
    intro a b ha hab
    have h1 : exp (a ^ 2) < exp (b ^ 2) := exp_lt_exp.2 (by nlinarith)
    have h2 : erf a < erf b := erf_strictMono hab
    have h3 : 0 < erf a := erf_pos ha
    have h4 : a * exp (a ^ 2) < b * exp (b ^ 2) := mul_lt_mul'' hab h1 ha.le (exp_pos _).le
    exact mul_lt_mul'' h4 h2 (by positivity) h3.le
  refine ⟨l, ⟨hl0, hfl⟩, fun m ⟨hm0, hfm⟩ => ?_⟩
  rcases lt_trichotomy m l with h | h | h
  · have := mono m l hm0 h
    linarith
  · exact h
  · have := mono l m hl0 h
    linarith

/-- **The energy books balance.** Under the same hypotheses, the heat through the lid up to
time `t`, `∫₀^t k T₀ / (erf λ √(π κ τ)) dτ`, equals the heat that melted the ice, `ρ L s(t)`,
plus the heat kept in the warm water, `ρ c ∫₀^{s(t)} T(x, t) dx`. -/
theorem neumann_energy_balance
    (k ρ c L T₀ lam : ℝ) (hk : 0 < k) (hρ : 0 < ρ) (hc : 0 < c) (hL : 0 < L) (hT₀ : 0 < T₀)
    (hlam : 0 < lam)
    (hroot : lam * exp (lam ^ 2) * erf lam = (c * T₀ / L) / √π)
    (t : ℝ) (ht : 0 < t) :
    let κ := k / (ρ * c)
    (∫ τ in (0 : ℝ)..t, k * T₀ / (erf lam * √(π * κ * τ))) =
      ρ * L * front κ lam t + ρ * c * ∫ x in (0 : ℝ)..front κ lam t, temp T₀ κ lam x t := by
  intro κ
  have hκ : 0 < κ := div_pos hk (mul_pos hρ hc)
  have hE : 0 < erf lam := erf_pos hlam
  have hpi : 0 < √π := Real.sqrt_pos.2 pi_pos
  have hst : 0 < √t := Real.sqrt_pos.2 ht
  have hsk : 0 < √κ := Real.sqrt_pos.2 hκ
  have hLHS : (∫ τ in (0 : ℝ)..t, k * T₀ / (erf lam * √(π * κ * τ))) =
      k * T₀ / (erf lam * √(π * κ)) * (2 * √t) := by
    have h1 : ∫ τ in (0 : ℝ)..t, τ ^ (-(1 / 2 : ℝ)) = 2 * √t := by
      rw [integral_rpow (Or.inl (by norm_num)), Real.sqrt_eq_rpow]
      norm_num
      ring
    rw [← h1, ← intervalIntegral.integral_const_mul]
    refine intervalIntegral.integral_congr fun τ hτ => ?_
    rw [uIcc_of_le ht.le] at hτ
    rcases hτ.1.eq_or_lt with h | h
    · subst h
      simp
    · rw [Real.rpow_neg h.le, ← Real.sqrt_eq_rpow, Real.sqrt_mul (by positivity) τ]
      field_simp
  set A := √(κ * t) with hAdef
  have hA : 0 < A := Real.sqrt_pos.2 (mul_pos hκ ht)
  clear_value A
  have hF : ∀ x ∈ uIcc 0 (front κ lam t), HasDerivAt
      (fun x => T₀ * (x - (x * erf (x / (2 * A)) + 2 * A / √π * exp (-(x / (2 * A)) ^ 2)) / erf lam))
      (temp T₀ κ lam x t) x := by
    intro x _
    have hu := (hasDerivAt_id x).div_const (2 * A)
    have he := (hasDerivAt_erf (x / (2 * A))).comp x hu
    have hprod := (hasDerivAt_id x).mul he
    have hex := ((hu.pow 2).neg.exp).const_mul (2 * A / √π)
    have htot := ((hasDerivAt_id x).sub ((hprod.add hex).div_const (erf lam))).const_mul T₀
    refine htot.congr_deriv ?_
    simp only [temp, id, Function.comp, Pi.neg_apply, Pi.pow_apply, ← hAdef]
    have hA0 : A ≠ 0 := hA.ne'
    field_simp
    ring_nf
    rw [show A * x * A⁻¹ = x by field_simp]
    ring
  have hint : IntervalIntegrable (fun x => temp T₀ κ lam x t) MeasureTheory.volume 0 (front κ lam t) := by
    apply Continuous.intervalIntegrable
    have := erf_continuous
    unfold temp
    fun_prop
  rw [hLHS, intervalIntegral.integral_eq_sub_of_hasDerivAt hF hint]
  have hs : front κ lam t / (2 * A) = lam := by
    unfold front
    rw [← hAdef]
    field_simp
  simp only [hs]
  unfold front
  simp only [zero_div, erf_zero, mul_zero, zero_add, ne_eq, OfNat.ofNat_ne_zero,
    not_false_eq_true, zero_pow, neg_zero, exp_zero, mul_one, zero_sub]
  have hexp : exp (lam ^ 2) * exp (-lam ^ 2) = 1 := by rw [← exp_add]; simp
  have key : lam * L * erf lam * √π = c * T₀ * exp (-lam ^ 2) := by
    have h := congrArg (fun z => z * (L * √π * exp (-lam ^ 2))) hroot
    field_simp at h
    linear_combination exp (-lam ^ 2) * h - (lam * L * erf lam * √π) * hexp
  have hk' : k = ρ * c * √κ ^ 2 := by
    rw [Real.sq_sqrt hκ.le]
    show k = ρ * c * (k / (ρ * c))
    field_simp
  rw [hAdef, Real.sqrt_mul hκ.le, Real.sqrt_mul pi_pos.le, hk']
  field_simp
  linear_combination (-1 : ℝ) * key

/-- The square-root law on the card: the front at 20 minutes (1200 s) is twice as deep as at
5 minutes (300 s), not four times. -/
example (κ lam : ℝ) (hκ : 0 ≤ κ) : front κ lam 1200 = 2 * front κ lam 300 := by
  unfold front
  rw [show κ * 1200 = 2 ^ 2 * (κ * 300) by ring, Real.sqrt_mul (by norm_num),
    Real.sqrt_sq (by norm_num)]
  ring

#print axioms neumann_solution_solves_stefan_problem
#print axioms neumann_equation_has_unique_positive_root
#print axioms neumann_energy_balance

end StefanProblem
