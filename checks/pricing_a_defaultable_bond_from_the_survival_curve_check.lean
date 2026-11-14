-- A risky bond from the hazard curve: with a flat riskless rate and a flat hazard the survival-weighted bond price equals its closed form with merged rate k = r + lambda, a price between zero and the cash added up has exactly one positive yield, and under recovery of market value the spread is exactly lambda (1 - R).
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

open Real

/-- Helper: the bond price as a function of a flat yield is strictly decreasing. -/
lemma bond_price_strictAnti (n : ℕ) (t : Fin n → ℝ) (c F T : ℝ)
    (hc : 0 ≤ c) (hF : 0 < F) (ht : ∀ i, 0 ≤ t i) (hT : 0 < T) :
    StrictAnti (fun y : ℝ => (∑ i, c * exp (-y * t i)) + F * exp (-y * T)) := by
  intro a b hab
  simp only
  apply add_lt_add_of_le_of_lt
  · exact Finset.sum_le_sum fun i _ =>
      mul_le_mul_of_nonneg_left (exp_le_exp.mpr (by nlinarith [ht i])) hc
  · exact mul_lt_mul_of_pos_left (exp_lt_exp.mpr (by nlinarith)) hF

#print axioms bond_price_strictAnti

/-- With flat curves, discount factor `D(t) = e^{-r t}`, survival `Q(t) = e^{-λ t}` and the
constant hazard `λ`, the risky-bond price (each coupon `c` at its date `tᵢ` and the face `F`
at maturity `T`, discounted and weighted by survival, plus the recovery
`R F ∫₀ᵀ D(t) λ Q(t) dt`) equals the closed form with the merged rate `k = r + λ`:
`Σ c e^{-k tᵢ} + F e^{-k T} + R F λ (1 - e^{-k T}) / k`. -/
theorem risky_bond_price_flat_closed_form (n : ℕ) (t : Fin n → ℝ) (c F R r lam T : ℝ)
    (D Q : ℝ → ℝ) (hD : ∀ s, D s = exp (-r * s)) (hQ : ∀ s, Q s = exp (-lam * s))
    (hk : r + lam ≠ 0) :
    (∑ i, c * D (t i) * Q (t i)) + F * D T * Q T
        + R * F * ∫ s in (0 : ℝ)..T, D s * lam * Q s
      = (∑ i, c * exp (-(r + lam) * t i)) + F * exp (-(r + lam) * T)
        + R * F * lam * (1 - exp (-(r + lam) * T)) / (r + lam) := by
  simp only [hD, hQ]
  have e : ∀ s, exp (-r * s) * exp (-lam * s) = exp (-(r + lam) * s) := by
    intro s; rw [← exp_add]; ring_nf
  have hint : ∫ s in (0 : ℝ)..T, exp (-r * s) * lam * exp (-lam * s)
      = lam * (1 - exp (-(r + lam) * T)) / (r + lam) := by
    have h1 : ∀ s, exp (-r * s) * lam * exp (-lam * s) = lam * exp (-(r + lam) * s) := by
      intro s; rw [← e]; ring
    simp_rw [h1]
    rw [intervalIntegral.integral_const_mul]
    have hderiv : ∀ x ∈ Set.uIcc (0 : ℝ) T,
        HasDerivAt (fun s => exp (-(r + lam) * s) / (-(r + lam))) (exp (-(r + lam) * x)) x := by
      intro x _
      have := (((hasDerivAt_id x).const_mul (-(r + lam))).exp).div_const (-(r + lam))
      convert this using 1
      · simp only [id]
      · simp only [id]; field_simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv
      ((by fun_prop : Continuous fun s => exp (-(r + lam) * s)).intervalIntegrable _ _)]
    field_simp
    simp only [mul_zero, neg_zero, exp_zero]
    ring
  rw [hint]
  have hs : (∑ i, c * exp (-r * t i) * exp (-lam * t i)) = ∑ i, c * exp (-(r + lam) * t i) :=
    Finset.sum_congr rfl fun i _ => by rw [mul_assoc, e]
  rw [hs, mul_assoc F, e]
  ring

/-- The yield exists and is unique: when every payment is positive and every payment date is
in the future, each price `P` strictly between zero and the cash added up, `n c + F`, is
reached by exactly one positive flat continuously compounded rate `y`, meaning
`Σ c e^{-y tᵢ} + F e^{-y T} = P`. -/
theorem bond_yield_exists_unique (n : ℕ) (t : Fin n → ℝ) (c F T P : ℝ)
    (hc : 0 < c) (hF : 0 < F) (ht : ∀ i, 0 < t i) (hT : 0 < T)
    (hP0 : 0 < P) (hP : P < n * c + F) :
    ∃! y : ℝ, 0 < y ∧ (∑ i, c * exp (-y * t i)) + F * exp (-y * T) = P := by
  have hS : 0 < (n : ℝ) * c + F := by positivity
  set f : ℝ → ℝ := fun y => (∑ i, c * exp (-y * t i)) + F * exp (-y * T) with hf
  have hanti := bond_price_strictAnti n t c F T hc.le hF (fun i => (ht i).le) hT
  have hf0 : f 0 = n * c + F := by simp [hf]
  have hcont : Continuous f := by rw [hf]; fun_prop
  have htend : Filter.Tendsto f Filter.atTop (nhds 0) := by
    have h : Filter.Tendsto f Filter.atTop
        (nhds ((∑ _i : Fin n, c * 0) + F * 0)) := by
      apply Filter.Tendsto.add
      · apply tendsto_finsetSum
        intro i _
        apply Filter.Tendsto.const_mul
        apply Real.tendsto_exp_atBot.comp
        have : Filter.Tendsto (fun y : ℝ => y * t i) Filter.atTop Filter.atTop :=
          Filter.tendsto_id.atTop_mul_const (ht i)
        exact (Filter.tendsto_neg_atTop_atBot.comp this).congr fun y => by simp [neg_mul]
      · apply Filter.Tendsto.const_mul
        apply Real.tendsto_exp_atBot.comp
        have : Filter.Tendsto (fun y : ℝ => y * T) Filter.atTop Filter.atTop :=
          Filter.tendsto_id.atTop_mul_const hT
        exact (Filter.tendsto_neg_atTop_atBot.comp this).congr fun y => by simp [neg_mul]
    simpa using h
  obtain ⟨Y, hYP, hY0⟩ : ∃ Y, f Y < P ∧ 0 ≤ Y :=
    ((htend.eventually (gt_mem_nhds hP0)).and (Filter.eventually_ge_atTop (0 : ℝ))).exists
  have hsub := intermediate_value_Icc' hY0 hcont.continuousOn
  obtain ⟨y, hyI, hyP⟩ := hsub ⟨hYP.le, by rw [hf0]; exact hP.le⟩
  refine ⟨y, ⟨?_, hyP⟩, ?_⟩
  · rcases hyI.1.eq_or_lt with h | h
    · rw [← h, hf0] at hyP; linarith
    · exact h
  · rintro z ⟨_, hz⟩
    exact hanti.injective (hz.trans hyP.symm)

/-- Recovery of market value: the bond priced by discounting every payment at
`r + λ (1 - R)` has that rate as its one and only yield, so its credit spread `y - r` is
exactly the loss rate `λ (1 - R)`. -/
theorem rmv_spread_eq_loss_rate (n : ℕ) (t : Fin n → ℝ) (c F T r lam R y : ℝ)
    (hc : 0 < c) (hF : 0 < F) (ht : ∀ i, 0 < t i) (hT : 0 < T)
    (hy : (∑ i, c * exp (-y * t i)) + F * exp (-y * T)
        = (∑ i, c * exp (-(r + lam * (1 - R)) * t i)) + F * exp (-(r + lam * (1 - R)) * T)) :
    y - r = lam * (1 - R) := by
  have hanti := bond_price_strictAnti n t c F T hc.le hF (fun i => (ht i).le) hT
  have := hanti.injective hy
  linarith

/-- Northwind's bond at yield zero is the cash added up: five coupons of 6 and a face of 100
make 130. -/
example : (∑ i : Fin 5, (6 : ℝ) * exp (-0 * ((i : ℝ) + 1))) + 100 * exp (-0 * 5) = 130 := by
  norm_num [Fin.sum_univ_five]

/-- Northwind under recovery of market value: hazard 2% times the 60% lost is a spread of
exactly 120 basis points, and the discount rate is 5% + 1.2% = 6.2%. -/
example : (2 / 100 : ℚ) * (1 - 40 / 100) * 10000 = 120 ∧
    (5 / 100 : ℚ) + 2 / 100 * (1 - 40 / 100) = 62 / 1000 := by
  norm_num

#print axioms risky_bond_price_flat_closed_form
#print axioms bond_yield_exists_unique
#print axioms rmv_spread_eq_loss_rate
