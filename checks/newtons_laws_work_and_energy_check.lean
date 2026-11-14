-- Newton's laws: if the total force is the rate of change of momentum of a fixed mass, then the work equals the change in kinetic energy, the impulse equals the change in momentum, and a ball thrown straight up against quadratic drag peaks at the card's closed-form height and time.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.InnerProductSpace.Calculus

open Set

/-- Work–energy theorem. A body of fixed mass `m` moves in `n`-dimensional space with
velocity `v t`. Newton's second law says the total force `F t` is the rate of change of
the momentum `m • v t`. Then the work done by the force between times `t₀` and `t₁`,
the integral of the power `F · v` (since `v dt = dr`, this is `∫_C F · dr`), equals the
change in kinetic energy `½ m |v|²`. The force is taken continuous so the work is an
ordinary integral. -/
theorem work_equals_change_in_kinetic_energy {n : ℕ} (m : ℝ)
    (v F : ℝ → EuclideanSpace ℝ (Fin n))
    (hlaw : ∀ t, HasDerivAt (fun s => m • v s) (F t) t)
    (hF : Continuous F) (t₀ t₁ : ℝ) :
    ∫ t in t₀..t₁, inner ℝ (F t) (v t)
      = (1 / 2) * m * ‖v t₁‖ ^ 2 - (1 / 2) * m * ‖v t₀‖ ^ 2 := by
  by_cases hm : m = 0
  · subst hm
    have hF0 : ∀ t, F t = 0 := by
      intro t
      have h := hlaw t
      simp only [zero_smul] at h
      exact h.unique (hasDerivAt_const t 0)
    simp [hF0]
  · have hv : ∀ t, HasDerivAt v (m⁻¹ • F t) t := by
      intro t
      have e : v = fun s => m⁻¹ • (m • v s) := by
        funext s; rw [smul_smul, inv_mul_cancel₀ hm, one_smul]
      rw [e]
      exact (hlaw t).const_smul m⁻¹
    have hvc : Continuous v := continuous_iff_continuousAt.2 fun t => (hv t).continuousAt
    have hE : ∀ t, HasDerivAt (fun s => (1 / 2) * m * ‖v s‖ ^ 2) (inner ℝ (F t) (v t)) t := by
      intro t
      have h := (HasDerivAt.norm_sq (hv t)).const_mul ((1 / 2) * m)
      convert h using 1
      rw [inner_smul_right, real_inner_comm]
      field_simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hE t)]
    exact (hF.inner hvc).intervalIntegrable _ _

/-- Impulse–momentum theorem. Under the same second law for a fixed mass `m`, the impulse
of the total force over the time from `t₀` to `t₁`, the integral of `F`, equals the change
in momentum `m v₁ - m v₀`. As a vector equation it holds in every direction separately. -/
theorem impulse_equals_change_in_momentum {n : ℕ} (m : ℝ)
    (v F : ℝ → EuclideanSpace ℝ (Fin n))
    (hlaw : ∀ t, HasDerivAt (fun s => m • v s) (F t) t)
    (hF : Continuous F) (t₀ t₁ : ℝ) :
    ∫ t in t₀..t₁, F t = m • v t₁ - m • v t₀ := by
  exact intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hlaw t)
    (hF.intervalIntegrable _ _)

/-- A ball thrown straight up into air with quadratic drag. On the way up, from release at
time `0` (height `0`, speed `v₀`) to the peak at time `T` (speed `0`), the height `y` and
upward speed `v` obey `ẏ = v` and `v̇ = -g - k v²`, with gravity `g > 0` and drag constant
`k > 0`. Then the peak height is `H = (1/(2k)) ln(1 + k v₀² / g)` and the time to the peak is
`arctan(v₀ √(k/g)) / √(g k)`. -/
theorem straight_up_throw_peak_height_and_time (g k v₀ T : ℝ) (y v : ℝ → ℝ)
    (hg : 0 < g) (hk : 0 < k) (hT : 0 ≤ T)
    (hyc : ContinuousOn y (Icc 0 T)) (hvc : ContinuousOn v (Icc 0 T))
    (hy : ∀ t ∈ Ioo 0 T, HasDerivAt y (v t) t)
    (hv : ∀ t ∈ Ioo 0 T, HasDerivAt v (-g - k * v t ^ 2) t)
    (hy0 : y 0 = 0) (hv0 : v 0 = v₀) (hvT : v T = 0) :
    y T = 1 / (2 * k) * Real.log (1 + k * v₀ ^ 2 / g) ∧
      T = Real.arctan (v₀ * Real.sqrt (k / g)) / Real.sqrt (g * k) := by
  have hsq1 : Real.sqrt (k / g) = Real.sqrt k / Real.sqrt g := Real.sqrt_div' k hg.le
  have hsq2 : Real.sqrt (g * k) = Real.sqrt g * Real.sqrt k := Real.sqrt_mul hg.le k
  have ha : 0 < Real.sqrt g := Real.sqrt_pos.2 hg
  have hb : 0 < Real.sqrt k := Real.sqrt_pos.2 hk
  have ha2 : Real.sqrt g ^ 2 = g := Real.sq_sqrt hg.le
  have hb2 : Real.sqrt k ^ 2 = k := Real.sq_sqrt hk.le
  have hpos : ∀ t, 0 < g + k * v t ^ 2 := fun t => by positivity
  constructor
  · -- ψ t = y t + (1/(2k)) log (g + k v²) is constant
    have hcont : ContinuousOn (fun t => y t + 1 / (2 * k) * Real.log (g + k * v t ^ 2))
        (Icc 0 T) := by
      apply hyc.add
      apply ContinuousOn.mul continuousOn_const
      apply ContinuousOn.log
      · exact continuousOn_const.add (continuousOn_const.mul (hvc.pow 2))
      · intro t _; exact (hpos t).ne'
    have hder : ∀ t ∈ Ioo 0 T, HasDerivAt
        (fun t => y t + 1 / (2 * k) * Real.log (g + k * v t ^ 2)) ((fun _ => (0:ℝ)) t) t := by
      intro t ht
      have h1 := (((hv t ht).pow 2).const_mul k).const_add g
      have h2 := (h1.log (hpos t).ne').const_mul (1 / (2 * k))
      have h3 := (hy t ht).add h2
      apply h3.congr_deriv
      have := (hpos t).ne'
      simp only [Pi.pow_apply]
      field_simp
      ring
    have h := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT hcont hder
      intervalIntegrable_const
    simp only [intervalIntegral.integral_zero, hy0, hv0, hvT] at h
    have hg' : g ≠ 0 := hg.ne'
    have hgv : g + k * v₀ ^ 2 ≠ 0 := by positivity
    rw [show 1 + k * v₀ ^ 2 / g = (g + k * v₀ ^ 2) / g by field_simp, Real.log_div hgv hg']
    simp at h
    linear_combination -h
  · have hcont : ContinuousOn
        (fun t => t + Real.arctan (v t * Real.sqrt (k / g)) / Real.sqrt (g * k)) (Icc 0 T) := by
      apply continuousOn_id.add
      apply ContinuousOn.div_const
      exact Real.continuous_arctan.comp_continuousOn (hvc.mul continuousOn_const)
    have hder : ∀ t ∈ Ioo 0 T, HasDerivAt
        (fun t => t + Real.arctan (v t * Real.sqrt (k / g)) / Real.sqrt (g * k))
        ((fun _ => (0:ℝ)) t) t := by
      intro t ht
      obtain ⟨a, ha', rfl⟩ : ∃ a, 0 < a ∧ g = a ^ 2 := ⟨Real.sqrt g, ha, ha2.symm⟩
      obtain ⟨b, hb', rfl⟩ : ∃ b, 0 < b ∧ k = b ^ 2 := ⟨Real.sqrt k, hb, hb2.symm⟩
      have e1 : Real.sqrt (b ^ 2 / a ^ 2) = b / a := by
        rw [Real.sqrt_div' _ (by positivity), Real.sqrt_sq hb'.le, Real.sqrt_sq ha'.le]
      have e2 : Real.sqrt (a ^ 2 * b ^ 2) = a * b := by
        rw [Real.sqrt_mul (by positivity), Real.sqrt_sq hb'.le, Real.sqrt_sq ha'.le]
      have h1 := (((hv t ht).mul_const (Real.sqrt (b ^ 2 / a ^ 2))).arctan).div_const
        (Real.sqrt (a ^ 2 * b ^ 2))
      have h2 := (hasDerivAt_id t).add h1
      apply h2.congr_deriv
      rw [e1, e2]
      have : 0 < a ^ 2 + b ^ 2 * v t ^ 2 := by positivity
      field_simp
      ring
    have h := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT hcont hder
      intervalIntegrable_const
    simp only [intervalIntegral.integral_zero, hv0, hvT] at h
    simp at h
    linarith

/-- Kinetic energy at release: ½ × 0.160 kg × (30 m/s)² = 72 J. -/
example : (1 / 2 : ℚ) * (160 / 1000) * 30 ^ 2 = 72 := by norm_num

#print axioms work_equals_change_in_kinetic_energy
#print axioms impulse_equals_change_in_momentum
#print axioms straight_up_throw_peak_height_and_time
