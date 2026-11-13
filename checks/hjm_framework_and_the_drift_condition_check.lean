-- Heath-Jarrow-Morton: the drift condition in its exact calculus form, its closed form for an exponentially fading volatility, and the Hull-White drift it produces.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.Deriv.Pow

open intervalIntegral Real

/-- Helper: the area under the exponential volatility. -/
theorem hjm_helper_exp_integral (σ a t T : ℝ) (ha : a ≠ 0) :
    ∫ u in t..T, σ * exp (-a * (u - t)) = σ / a * (1 - exp (-a * (T - t))) := by
  have hd : ∀ x ∈ Set.uIcc t T,
      HasDerivAt (fun u => -(σ / a) * exp (-a * (u - t))) (σ * exp (-a * (x - t))) x := by
    intro x _
    have h1 : HasDerivAt (fun u => -a * (u - t)) (-a * 1) x :=
      ((hasDerivAt_id x).sub_const t).const_mul (-a)
    have h2 := (h1.exp).const_mul (-(σ / a))
    convert h2 using 1
    field_simp
  rw [integral_eq_sub_of_hasDerivAt hd
    ((by fun_prop : Continuous fun x => σ * exp (-a * (x - t))).intervalIntegrable _ _)]
  simp only [sub_self, mul_zero, exp_zero]
  ring

#print axioms hjm_helper_exp_integral

/-- The HJM drift condition (Steps 4 and 5 of the card). Fix the current time `t`. With the
volatility `σ t u` and the drift `α t u` continuous in the maturity `u`, the total drift piled up
between now and every maturity `T ≥ t` pays exactly for half the squared volatility area,
`∫ₜᵀ α(t,u) du = ½ (∫ₜᵀ σ(t,u) du)²`, if and only if every drift equals its own volatility
times the volatility area: `α(t,T) = σ(t,T) ∫ₜᵀ σ(t,u) du`. -/
theorem hjm_drift_condition (α σ : ℝ → ℝ → ℝ) (t : ℝ)
    (hα : Continuous (α t)) (hσ : Continuous (σ t)) :
    (∀ T, t ≤ T → ∫ u in t..T, α t u = (1 / 2) * (∫ u in t..T, σ t u) ^ 2) ↔
      (∀ T, t ≤ T → α t T = σ t T * ∫ u in t..T, σ t u) := by
  set S : ℝ → ℝ := fun T => ∫ u in t..T, σ t u with hS
  have hSd : ∀ x, HasDerivAt S (σ t x) x := fun x =>
    (hσ.integral_hasStrictDerivAt t x).hasDerivAt
  have hSc : Continuous S := continuous_iff_continuousAt.2 fun x => (hSd x).continuousAt
  have hGd : ∀ x, HasDerivAt (fun T => (1 / 2) * S T ^ 2) (σ t x * S x) x := by
    intro x
    have := ((hSd x).pow 2).const_mul (1 / 2 : ℝ)
    convert this using 1
    push_cast
    ring
  constructor
  · intro h
    have hopen : ∀ T, t < T → α t T = σ t T * S T := by
      intro T hT
      have hF : HasDerivAt (fun T => ∫ u in t..T, α t u) (α t T) T :=
        (hα.integral_hasStrictDerivAt t T).hasDerivAt
      have heq : (fun T => ∫ u in t..T, α t u) =ᶠ[nhds T] (fun T => (1 / 2) * S T ^ 2) := by
        filter_upwards [Ioi_mem_nhds hT] with x hx
        exact h x (le_of_lt hx)
      exact (hF.congr_of_eventuallyEq heq.symm).unique (hGd T)
    have hcl : Set.EqOn (α t) (fun T => σ t T * S T) (closure (Set.Ioi t)) :=
      Set.EqOn.closure (fun T hT => hopen T hT) hα (hσ.mul hSc)
    rw [closure_Ioi] at hcl
    intro T hT
    exact hcl hT
  · intro h T hT
    have hcongr : ∫ u in t..T, α t u = ∫ u in t..T, σ t u * S u := by
      apply integral_congr
      intro u hu
      rw [Set.uIcc_of_le hT] at hu
      exact h u hu.1
    rw [hcongr, integral_eq_sub_of_hasDerivAt (fun x _ => hGd x)
      ((hσ.mul hSc).intervalIntegrable _ _)]
    simp [hS]

/-- The card's exponential volatility `σ(t,T) = σ e^{-a(T-t)}` with fading speed `a > 0`. The
forced drift `σ(t,T) ∫ₜᵀ σ(t,u) du` has the closed form `(σ²/a) e^{-a(T-t)} (1 - e^{-a(T-t)})`;
it never exceeds `σ²/(4a)`, and it reaches that peak when `T - t = ln 2 / a`. -/
theorem hjm_exponential_volatility_drift (σ a t T : ℝ) (ha : 0 < a) :
    (σ * exp (-a * (T - t))) * (∫ u in t..T, σ * exp (-a * (u - t)))
        = σ ^ 2 / a * exp (-a * (T - t)) * (1 - exp (-a * (T - t))) ∧
      σ ^ 2 / a * exp (-a * (T - t)) * (1 - exp (-a * (T - t))) ≤ σ ^ 2 / (4 * a) ∧
      (T - t = log 2 / a →
        σ ^ 2 / a * exp (-a * (T - t)) * (1 - exp (-a * (T - t))) = σ ^ 2 / (4 * a)) := by
  have hint := hjm_helper_exp_integral σ a t T ha.ne'
  set E := exp (-a * (T - t)) with hE
  refine ⟨?_, ?_, ?_⟩
  · rw [hint]
    field_simp
  · have hk : 0 ≤ σ ^ 2 / a := div_nonneg (sq_nonneg σ) ha.le
    have hq : E * (1 - E) ≤ 1 / 4 := by nlinarith [sq_nonneg (E - 1 / 2)]
    calc σ ^ 2 / a * E * (1 - E) = σ ^ 2 / a * (E * (1 - E)) := by ring
      _ ≤ σ ^ 2 / a * (1 / 4) := mul_le_mul_of_nonneg_left hq hk
      _ = σ ^ 2 / (4 * a) := by field_simp
  · intro hT
    have hE2 : E = 1 / 2 := by
      rw [hE, hT, show -a * (log 2 / a) = -log 2 by field_simp, exp_neg,
        exp_log (by norm_num : (0 : ℝ) < 2)]
      norm_num
    rw [hE2]
    field_simp
    ring

/-- The exponential volatility is Hull-White (Step 6 of the card). The drift piled up at the
front, `c(t) = ∫₀ᵗ α(u,t) du` with `α(u,t) = σ e^{-a(t-u)} ∫ᵤᵗ σ e^{-a(v-u)} dv`, is the
convexity term `σ²/(2a²) (1 - e^{-at})²`, and `c'(t) + a c(t) = σ²/(2a) (1 - e^{-2at})`, the
volatility part of the Hull-White target drift `θ(t)`. -/
theorem hjm_exponential_volatility_is_hull_white (σ a t : ℝ) (ha : 0 < a) :
    let c : ℝ → ℝ := fun s =>
      ∫ u in (0 : ℝ)..s, (σ * exp (-a * (s - u))) * ∫ v in u..s, σ * exp (-a * (v - u))
    c t = σ ^ 2 / (2 * a ^ 2) * (1 - exp (-a * t)) ^ 2 ∧
      deriv c t + a * c t = σ ^ 2 / (2 * a) * (1 - exp (-2 * a * t)) := by
  intro c
  have hc : ∀ s, c s = σ ^ 2 / (2 * a ^ 2) * (1 - exp (-a * s)) ^ 2 := by
    intro s
    have hin : ∀ u, ∫ v in u..s, σ * exp (-a * (v - u)) = σ / a * (1 - exp (-a * (s - u))) :=
      fun u => hjm_helper_exp_integral σ a u s ha.ne'
    show (∫ u in (0 : ℝ)..s, (σ * exp (-a * (s - u))) * ∫ v in u..s, σ * exp (-a * (v - u)))
      = _
    simp_rw [hin]
    have hd : ∀ x ∈ Set.uIcc (0 : ℝ) s,
        HasDerivAt (fun u => σ ^ 2 / a * (exp (-a * (s - u)) / a - exp (-a * (s - u)) ^ 2 / (2 * a)))
          ((σ * exp (-a * (s - x))) * (σ / a * (1 - exp (-a * (s - x))))) x := by
      intro x _
      have h1 : HasDerivAt (fun u => -a * (s - u)) (-a * (0 - 1)) x :=
        ((hasDerivAt_const x s).sub (hasDerivAt_id x)).const_mul (-a)
      have h2 := h1.exp
      have h3 := ((h2.div_const a).sub ((h2.pow 2).div_const (2 * a))).const_mul (σ ^ 2 / a)
      convert h3 using 1
      field_simp
      push_cast
      ring
    rw [integral_eq_sub_of_hasDerivAt hd (by
      apply Continuous.intervalIntegrable
      fun_prop)]
    simp only [sub_self, mul_zero, exp_zero, sub_zero]
    field_simp
    ring
  have hcf : c = fun s => σ ^ 2 / (2 * a ^ 2) * (1 - exp (-a * s)) ^ 2 := funext hc
  refine ⟨hc t, ?_⟩
  have hd : HasDerivAt c (σ ^ 2 / (2 * a ^ 2) * (2 * (1 - exp (-a * t)) * (-(exp (-a * t) * (-a * 1))))) t := by
    rw [hcf]
    have h1 : HasDerivAt (fun s => -a * s) (-a * 1) t := (hasDerivAt_id t).const_mul (-a)
    have h2 := ((h1.exp).const_sub 1).pow 2
    have h3 := h2.const_mul (σ ^ 2 / (2 * a ^ 2))
    convert h3 using 1
    push_cast
    ring
  rw [hd.deriv, hc t, show exp (-2 * a * t) = exp (-a * t) ^ 2 by rw [sq, ← exp_add]; ring_nf]
  field_simp
  ring

/-- The card's peak drift: with `σ = 0.01` and `a = 0.3`, `σ²/(4a) = 1/12000 = 0.0000833333…`. -/
example : ((1 : ℝ) / 100) ^ 2 / (4 * (3 / 10)) = 1 / 12000 := by norm_num

#print axioms hjm_drift_condition
#print axioms hjm_exponential_volatility_drift
#print axioms hjm_exponential_volatility_is_hull_white
