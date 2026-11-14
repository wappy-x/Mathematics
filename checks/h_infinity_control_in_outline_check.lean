-- H-infinity design: if the peak over frequency of the stacked weighted gains is below 1, each weighted requirement holds at every frequency, and no choice of S can push the stack below the floor a c / sqrt (a^2 + c^2).
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Real.Sqrt

open Complex

/-- The card's main guarantee (Step 2). Take any plant `P`, controller `K` and weights `WP`, `WU`,
`W`, each given by its value at every frequency `ω`. Write `S = 1/(1 + P K)` for the sensitivity
and `T = P K/(1 + P K)` for the complementary sensitivity. If the peak over all frequencies of the
stack `sqrt (|WP S|^2 + |WU K S|^2 + |W T|^2)` is a finite number below 1, then at every frequency
`|WP S| < 1` (the error specification), `|WU K S| < 1` (the torque budget) and `|W T| < 1`
(the room the model error leaves). -/
theorem stack_peak_below_one_meets_every_requirement
    (P K WP WU W : ℝ → ℂ)
    (hbdd : BddAbove (Set.range fun ω : ℝ =>
      Real.sqrt (‖WP ω * (1 / (1 + P ω * K ω))‖ ^ 2
        + ‖WU ω * (K ω * (1 / (1 + P ω * K ω)))‖ ^ 2
        + ‖W ω * (P ω * K ω / (1 + P ω * K ω))‖ ^ 2)))
    (hγ : (⨆ ω : ℝ,
      Real.sqrt (‖WP ω * (1 / (1 + P ω * K ω))‖ ^ 2
        + ‖WU ω * (K ω * (1 / (1 + P ω * K ω)))‖ ^ 2
        + ‖W ω * (P ω * K ω / (1 + P ω * K ω))‖ ^ 2)) < 1) :
    ∀ ω : ℝ, ‖WP ω * (1 / (1 + P ω * K ω))‖ < 1
      ∧ ‖WU ω * (K ω * (1 / (1 + P ω * K ω)))‖ < 1
      ∧ ‖W ω * (P ω * K ω / (1 + P ω * K ω))‖ < 1 := by
  intro ω
  have hle := le_ciSup hbdd ω
  set x := ‖WP ω * (1 / (1 + P ω * K ω))‖ with hx
  set y := ‖WU ω * (K ω * (1 / (1 + P ω * K ω)))‖ with hy
  set z := ‖W ω * (P ω * K ω / (1 + P ω * K ω))‖ with hz
  have h0 : Real.sqrt (x ^ 2 + y ^ 2 + z ^ 2) < 1 := lt_of_le_of_lt hle hγ
  have hx0 : 0 ≤ x := norm_nonneg _
  have hy0 : 0 ≤ y := norm_nonneg _
  have hz0 : 0 ≤ z := norm_nonneg _
  have h1 : x ≤ Real.sqrt (x ^ 2 + y ^ 2 + z ^ 2) :=
    Real.le_sqrt_of_sq_le (by nlinarith [sq_nonneg y, sq_nonneg z])
  have h2 : y ≤ Real.sqrt (x ^ 2 + y ^ 2 + z ^ 2) :=
    Real.le_sqrt_of_sq_le (by nlinarith [sq_nonneg x, sq_nonneg z])
  have h3 : z ≤ Real.sqrt (x ^ 2 + y ^ 2 + z ^ 2) :=
    Real.le_sqrt_of_sq_le (by nlinarith [sq_nonneg y, sq_nonneg x])
  exact ⟨by linarith, by linarith, by linarith⟩

/-- The floor of Step 3. At one frequency, with `a = |WP| ≥ 0` and `c ≥ 0` the combined size of
`WU/P` and `W`, the squared stack is `a^2 |S|^2 + c^2 |1 - S|^2`. Over every complex number `S`,
the smallest value of its square root is exactly `a c / sqrt (a^2 + c^2)`. -/
theorem stack_floor_over_complex_s (a c : ℝ) (ha : 0 ≤ a) (hc : 0 ≤ c) :
    IsLeast (Set.range fun S : ℂ => Real.sqrt (a ^ 2 * ‖S‖ ^ 2 + c ^ 2 * ‖1 - S‖ ^ 2))
      (a * c / Real.sqrt (a ^ 2 + c ^ 2)) := by
  rcases eq_or_lt_of_le (add_nonneg (sq_nonneg a) (sq_nonneg c)) with hD | hD
  · have ha0 : a = 0 := by nlinarith [sq_nonneg a, sq_nonneg c]
    have hc0 : c = 0 := by nlinarith [sq_nonneg a, sq_nonneg c]
    subst ha0; subst hc0
    refine ⟨⟨0, by simp⟩, ?_⟩
    rintro _ ⟨S, rfl⟩
    simp
  · have hsD : 0 < Real.sqrt (a ^ 2 + c ^ 2) := Real.sqrt_pos.mpr hD
    have hlhs : 0 ≤ a * c / Real.sqrt (a ^ 2 + c ^ 2) := by positivity
    refine ⟨⟨((c ^ 2 / (a ^ 2 + c ^ 2) : ℝ) : ℂ), ?_⟩, ?_⟩
    · simp only
      have e1 : ‖((c ^ 2 / (a ^ 2 + c ^ 2) : ℝ) : ℂ)‖ = c ^ 2 / (a ^ 2 + c ^ 2) := by
        rw [Complex.norm_real, Real.norm_of_nonneg (by positivity)]
      have e2 : ‖(1 : ℂ) - ((c ^ 2 / (a ^ 2 + c ^ 2) : ℝ) : ℂ)‖ = a ^ 2 / (a ^ 2 + c ^ 2) := by
        have : (1 : ℂ) - ((c ^ 2 / (a ^ 2 + c ^ 2) : ℝ) : ℂ) = ((a ^ 2 / (a ^ 2 + c ^ 2) : ℝ) : ℂ) := by
          have hr : (1 : ℝ) - c ^ 2 / (a ^ 2 + c ^ 2) = a ^ 2 / (a ^ 2 + c ^ 2) := by
            field_simp
            ring
          rw [← Complex.ofReal_one, ← Complex.ofReal_sub, hr]
        rw [this, Complex.norm_real, Real.norm_of_nonneg (by positivity)]
      rw [e1, e2]
      have hin : a ^ 2 * (c ^ 2 / (a ^ 2 + c ^ 2)) ^ 2 + c ^ 2 * (a ^ 2 / (a ^ 2 + c ^ 2)) ^ 2
          = (a * c / Real.sqrt (a ^ 2 + c ^ 2)) ^ 2 := by
        rw [div_pow (a * c), Real.sq_sqrt (le_of_lt hD)]
        field_simp
        ring
      rw [hin, Real.sqrt_sq hlhs]
    · rintro _ ⟨S, rfl⟩
      simp only
      apply Real.le_sqrt_of_sq_le
      have hxy : 1 ≤ ‖S‖ + ‖1 - S‖ := by
        have := norm_add_le S (1 - S)
        simpa using this
      have hx0 : 0 ≤ ‖S‖ := norm_nonneg _
      have hy0 : 0 ≤ ‖1 - S‖ := norm_nonneg _
      have key : a ^ 2 * c ^ 2 ≤ (a ^ 2 * ‖S‖ ^ 2 + c ^ 2 * ‖1 - S‖ ^ 2) * (a ^ 2 + c ^ 2) := by
        have hsq : 1 ≤ (‖S‖ + ‖1 - S‖) ^ 2 := by nlinarith
        have hac : 0 ≤ a ^ 2 * c ^ 2 := by positivity
        nlinarith [sq_nonneg (a ^ 2 * ‖S‖ - c ^ 2 * ‖1 - S‖), mul_le_mul_of_nonneg_left hsq hac]
      rw [div_pow, Real.sq_sqrt (le_of_lt hD), div_le_iff₀ hD, mul_pow]
      exact key

/-- The two loop identities behind the floor: whatever the controller, `S + T = 1` and `K S = T / P`,
where `S = 1/(1 + P K)` and `T = P K/(1 + P K)`, for a loop with `1 + P K ≠ 0` and a plant value
`P ≠ 0`. -/
theorem sensitivity_identities (P K : ℂ) (hP : P ≠ 0) (hL : 1 + P * K ≠ 0) :
    1 / (1 + P * K) + P * K / (1 + P * K) = 1
      ∧ K * (1 / (1 + P * K)) = (P * K / (1 + P * K)) / P := by
  refine ⟨?_, ?_⟩
  · field_simp
  · field_simp

-- "When it holds": design B has Kp = 7, so a 3 rad/s speed step asks 7 x 3 = 21 N m, over a 20 N m drive.
example : (7 : ℕ) * 3 = 21 ∧ 20 < (7 : ℕ) * 3 := by norm_num

#print axioms stack_peak_below_one_meets_every_requirement
#print axioms stack_floor_over_complex_s
#print axioms sensitivity_identities
