-- Bootstrapping a hazard curve: each bootstrap step has exactly one nonnegative hazard piece when the quote lies strictly between its floor and ceiling, a piece exists only then, and a contract's two legs read the hazard only up to its own tenor.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Topology.Order.IntermediateValue

open scoped BigOperators

/-! One bootstrap step, as in the card's Detailed proof.
Frozen totals `A₀ = A(T_{i-1})`, `P₀ = P(T_{i-1})`; weight `W = D(T_{i-1}) S(T_{i-1})`;
new piece of length `d`; riskless rate `r`; loss on default `L = 1 - R`; quote `s`.
The new stretch's premium dates sit at offsets `u j` from its start, `0 < u j ≤ d`, each paying
a quarter-year of premium. For a candidate flat hazard `h` on the stretch, the protection the new
piece adds is `L W g(h)` with `g(h) = h ∫₀^d e^{-(r+h)x} dx`, and the premium-years it adds are
`W a(h)` with `a(h) = ∑ 0.25 e^{-(r+h) u j}`. The quote is matched when
`P₀ + L W g(h) = s (A₀ + W a(h))`.
The floor is the quote matched at `h = 0`: `P₀ = s (A₀ + W a(0))`.
The ceiling is the limit as `h → ∞`: `s A₀ = P₀ + L W`. -/

lemma hazard_integral_closed (c d : ℝ) (hc : c ≠ 0) :
    ∫ x in (0 : ℝ)..d, Real.exp (-c * x) = (1 - Real.exp (-c * d)) / c := by
  have h := intervalIntegral.integral_comp_mul_left (a := 0) (b := d) (fun x => Real.exp x)
    (neg_ne_zero.mpr hc)
  rw [h, integral_exp, mul_zero, Real.exp_zero, smul_eq_mul]
  field_simp
  ring

lemma hazard_g_closed (r d h : ℝ) (hr : 0 ≤ r) (hh : 0 < h) :
    h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x) = h / (r + h) * (1 - Real.exp (-(r + h) * d)) := by
  rw [hazard_integral_closed (r + h) d (by positivity)]
  ring

lemma hazard_g_strictMonoOn (r d : ℝ) (hr : 0 ≤ r) (hd : 0 < d) :
    StrictMonoOn (fun h : ℝ => h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x)) (Set.Ici 0) := by
  intro h₁ h₁0 h₂ h₂0 h12
  simp only [Set.mem_Ici] at h₁0 h₂0
  have h2pos : 0 < h₂ := lt_of_le_of_lt h₁0 h12
  simp only
  rw [hazard_g_closed r d h₂ hr h2pos]
  have hb2 : Real.exp (-(r + h₂) * d) < 1 := by
    rw [Real.exp_lt_one_iff]; nlinarith
  have ha2 : 0 < h₂ / (r + h₂) := by positivity
  rcases h₁0.lt_or_eq with h1pos | h1z
  · rw [hazard_g_closed r d h₁ hr h1pos]
    have ha : h₁ / (r + h₁) ≤ h₂ / (r + h₂) := by
      rw [div_le_div_iff₀ (by positivity) (by positivity)]; nlinarith
    have hb : Real.exp (-(r + h₂) * d) < Real.exp (-(r + h₁) * d) := by
      rw [Real.exp_lt_exp]; nlinarith
    have hb1 : Real.exp (-(r + h₁) * d) < 1 := by
      rw [Real.exp_lt_one_iff]; nlinarith
    calc h₁ / (r + h₁) * (1 - Real.exp (-(r + h₁) * d))
        ≤ h₂ / (r + h₂) * (1 - Real.exp (-(r + h₁) * d)) :=
          mul_le_mul_of_nonneg_right ha (by linarith)
      _ < h₂ / (r + h₂) * (1 - Real.exp (-(r + h₂) * d)) :=
          mul_lt_mul_of_pos_left (by linarith) ha2
  · subst h1z
    rw [zero_mul]
    exact mul_pos ha2 (by linarith)

lemma hazard_g_lt_one (r d h : ℝ) (hr : 0 ≤ r) (hd : 0 < d) (hh : 0 ≤ h) :
    h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x) < 1 := by
  rcases hh.lt_or_eq with hpos | hz
  · rw [hazard_g_closed r d h hr hpos]
    have ha : h / (r + h) ≤ 1 := by
      rw [div_le_one (by positivity)]; linarith
    have hb : Real.exp (-(r + h) * d) < 1 := by
      rw [Real.exp_lt_one_iff]; nlinarith
    have hb0 : 0 < Real.exp (-(r + h) * d) := Real.exp_pos _
    calc h / (r + h) * (1 - Real.exp (-(r + h) * d))
        ≤ 1 * (1 - Real.exp (-(r + h) * d)) := mul_le_mul_of_nonneg_right ha (by linarith)
      _ < 1 := by linarith
  · subst hz; simp

lemma hazard_g_continuous (r d : ℝ) :
    Continuous (fun h : ℝ => h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x)) := by
  refine continuous_id.mul ?_
  exact intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
    (f := fun h x : ℝ => Real.exp (-(r + h) * x)) (by fun_prop) 0 d

lemma hazard_exp_tendsto_zero (r c : ℝ) (hc : 0 < c) :
    Filter.Tendsto (fun h : ℝ => Real.exp (-(r + h) * c)) Filter.atTop (nhds 0) := by
  have h1 : Filter.Tendsto (fun h : ℝ => (r + h) * c) Filter.atTop Filter.atTop :=
    (Filter.tendsto_atTop_add_const_left _ r Filter.tendsto_id).atTop_mul_const hc
  have h2 := Real.tendsto_exp_atBot.comp (Filter.tendsto_neg_atTop_atBot.comp h1)
  refine h2.congr ?_
  intro h; simp only [Function.comp_apply]; congr 1; ring

lemma hazard_g_tendsto (r d : ℝ) (hr : 0 ≤ r) (hd : 0 < d) :
    Filter.Tendsto (fun h : ℝ => h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x))
      Filter.atTop (nhds 1) := by
  have he := hazard_exp_tendsto_zero r d hd
  have hq : Filter.Tendsto (fun h : ℝ => r / (r + h)) Filter.atTop (nhds 0) :=
    Filter.Tendsto.div_atTop tendsto_const_nhds
      (Filter.tendsto_atTop_add_const_left _ r Filter.tendsto_id)
  have hlim : Filter.Tendsto
      (fun h : ℝ => (1 - Real.exp (-(r + h) * d)) - r / (r + h) * (1 - Real.exp (-(r + h) * d)))
      Filter.atTop (nhds ((1 - 0) - 0 * (1 - 0))) :=
    (tendsto_const_nhds.sub he).sub (hq.mul (tendsto_const_nhds.sub he))
  simp only [sub_zero, zero_mul] at hlim
  refine hlim.congr' ?_
  filter_upwards [Filter.eventually_gt_atTop 0] with h hh
  rw [hazard_g_closed r d h hr hh]
  have : r + h ≠ 0 := by positivity
  field_simp
  ring

lemma hazard_a_antitone {m : ℕ} (u : Fin m → ℝ) (r : ℝ) (hu : ∀ j, 0 ≤ u j) {h₁ h₂ : ℝ}
    (h12 : h₁ ≤ h₂) :
    ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h₂) * u j) ≤
      ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h₁) * u j) := by
  apply Finset.sum_le_sum
  intro j _
  have := hu j
  gcongr

lemma hazard_a_nonneg {m : ℕ} (u : Fin m → ℝ) (r h : ℝ) :
    0 ≤ ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j) := by
  positivity

lemma hazard_a_continuous {m : ℕ} (u : Fin m → ℝ) (r : ℝ) :
    Continuous (fun h : ℝ => ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j)) := by
  fun_prop

lemma hazard_a_tendsto {m : ℕ} (u : Fin m → ℝ) (r : ℝ) (hu : ∀ j, 0 < u j) :
    Filter.Tendsto (fun h : ℝ => ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j))
      Filter.atTop (nhds 0) := by
  have : Filter.Tendsto (fun h : ℝ => ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j))
      Filter.atTop (nhds (∑ _j : Fin m, (1 / 4 : ℝ) * 0)) :=
    tendsto_finsetSum _ (fun j _ => (hazard_exp_tendsto_zero r (u j) (hu j)).const_mul _)
  simpa using this

#print axioms hazard_integral_closed
#print axioms hazard_g_closed
#print axioms hazard_g_strictMonoOn
#print axioms hazard_g_lt_one
#print axioms hazard_g_continuous
#print axioms hazard_exp_tendsto_zero
#print axioms hazard_g_tendsto
#print axioms hazard_a_antitone
#print axioms hazard_a_nonneg
#print axioms hazard_a_continuous
#print axioms hazard_a_tendsto

/-- Each bootstrap step has exactly one answer when the quote is in range: if the quote lies
strictly above the floor (the spread reached at zero hazard) and strictly below the ceiling
(the spread approached as the hazard grows without bound), then exactly one nonnegative flat
hazard on the new stretch makes the protection leg equal the quoted premium leg. -/
theorem bootstrap_step_has_unique_piece
    (A₀ P₀ W d r L s : ℝ) {m : ℕ} (u : Fin m → ℝ)
    (hA₀ : 0 ≤ A₀) (hP₀ : 0 ≤ P₀) (hW : 0 < W) (hd : 0 < d) (hr : 0 ≤ r) (hL : 0 < L)
    (hs : 0 < s) (hu : ∀ j, 0 < u j ∧ u j ≤ d)
    (hfloor : P₀ < s * (A₀ + W * ∑ j, (1 / 4 : ℝ) * Real.exp (-r * u j)))
    (hceil : s * A₀ < P₀ + L * W) :
    ∃! h : ℝ, 0 ≤ h ∧
      P₀ + L * W * (h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x)) =
        s * (A₀ + W * ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j)) := by
  have hu0 : ∀ j, 0 ≤ u j := fun j => (hu j).1.le
  let F : ℝ → ℝ := fun h => P₀ + L * W * (h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x)) -
      s * (A₀ + W * ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j))
  have hLW : 0 < L * W := mul_pos hL hW
  have hsW : 0 < s * W := mul_pos hs hW
  have hmono : StrictMonoOn F (Set.Ici 0) := by
    intro h₁ h₁0 h₂ h₂0 h12
    have e1 := hazard_g_strictMonoOn r d hr hd h₁0 h₂0 h12
    have e2 := hazard_a_antitone u r hu0 h12.le
    simp only [F] at e1 ⊢
    nlinarith [mul_lt_mul_of_pos_left e1 hLW, mul_le_mul_of_nonneg_left e2 hsW.le]
  have hcont : Continuous F :=
    (continuous_const.add (continuous_const.mul (hazard_g_continuous r d))).sub
      (continuous_const.mul (continuous_const.add
        (continuous_const.mul (hazard_a_continuous u r))))
  have hF0 : F 0 < 0 := by
    simp only [F, zero_mul, mul_zero, add_zero]
    linarith
  have hlim : Filter.Tendsto F Filter.atTop (nhds (P₀ + L * W * 1 - s * (A₀ + W * 0))) :=
    (tendsto_const_nhds.add ((hazard_g_tendsto r d hr hd).const_mul _)).sub
      ((((hazard_a_tendsto u r (fun j => (hu j).1)).const_mul W).const_add A₀).const_mul s)
  have hpos : 0 < P₀ + L * W * 1 - s * (A₀ + W * 0) := by
    simp only [mul_one, mul_zero, add_zero]
    linarith
  obtain ⟨H, hFH, hH0⟩ :=
    ((hlim.eventually (lt_mem_nhds hpos)).and (Filter.eventually_ge_atTop 0)).exists
  obtain ⟨h, ⟨hh0, -⟩, hFh⟩ :=
    intermediate_value_Icc hH0 hcont.continuousOn ⟨hF0.le, hFH.le⟩
  refine ⟨h, ⟨hh0, sub_eq_zero.mp hFh⟩, ?_⟩
  rintro h' ⟨hh'0, hh'⟩
  have hFh' : F h' = 0 := sub_eq_zero.mpr hh'
  exact hmono.injOn hh'0 hh0 (hFh'.trans hFh.symm)

/-- When a step has an answer at all: a nonnegative flat hazard matching the quote exists exactly
when the quote is at or above the floor and strictly below the ceiling. A quote below the floor,
or at or above the ceiling, has no curve; a quote exactly at the floor has the piece zero. -/
theorem bootstrap_step_solvable_iff
    (A₀ P₀ W d r L s : ℝ) {m : ℕ} (u : Fin m → ℝ)
    (hA₀ : 0 ≤ A₀) (hP₀ : 0 ≤ P₀) (hW : 0 < W) (hd : 0 < d) (hr : 0 ≤ r) (hL : 0 < L)
    (hs : 0 < s) (hu : ∀ j, 0 < u j ∧ u j ≤ d) :
    (∃ h : ℝ, 0 ≤ h ∧
      P₀ + L * W * (h * ∫ x in (0 : ℝ)..d, Real.exp (-(r + h) * x)) =
        s * (A₀ + W * ∑ j, (1 / 4 : ℝ) * Real.exp (-(r + h) * u j))) ↔
      (P₀ ≤ s * (A₀ + W * ∑ j, (1 / 4 : ℝ) * Real.exp (-r * u j)) ∧ s * A₀ < P₀ + L * W) := by
  have hu0 : ∀ j, 0 ≤ u j := fun j => (hu j).1.le
  have hLW : 0 < L * W := mul_pos hL hW
  have hsW : 0 < s * W := mul_pos hs hW
  constructor
  · rintro ⟨h, hh0, hh⟩
    have e1 := hazard_g_lt_one r d h hr hd hh0
    have e2 := hazard_a_nonneg u r h
    constructor
    · have m1 := (hazard_g_strictMonoOn r d hr hd).monotoneOn
        (le_refl (0 : ℝ) : (0 : ℝ) ∈ Set.Ici 0) hh0 hh0
      have m2 := hazard_a_antitone u r hu0 hh0
      simp only [zero_mul, add_zero] at m1 m2
      nlinarith [mul_le_mul_of_nonneg_left m1 hLW.le, mul_le_mul_of_nonneg_left m2 hsW.le]
    · nlinarith [mul_lt_mul_of_pos_left e1 hLW, mul_nonneg hsW.le e2]
  · rintro ⟨hfl, hce⟩
    rcases hfl.lt_or_eq with hlt | heq
    · obtain ⟨h, hh, -⟩ :=
        bootstrap_step_has_unique_piece A₀ P₀ W d r L s u hA₀ hP₀ hW hd hr hL hs hu hlt hce
      exact ⟨h, hh⟩
    · refine ⟨0, le_refl _, ?_⟩
      simp only [zero_mul, mul_zero, add_zero]
      exact heq

/-- Survival under a hazard curve `lam`: `S(t) = e^{-∫₀^t λ}`. -/
noncomputable def survival (lam : ℝ → ℝ) (t : ℝ) : ℝ :=
  Real.exp (-∫ x in (0 : ℝ)..t, lam x)

/-- Risky annuity to tenor `T`: a quarter-year of premium on each quarter-date `j/4 ≤ T`,
discounted at rate `r` and weighted by survival. -/
noncomputable def riskyAnnuity (r : ℝ) (lam : ℝ → ℝ) (T : ℝ) : ℝ :=
  ∑ j ∈ Finset.Icc 1 ⌊4 * T⌋₊, (1 / 4 : ℝ) * Real.exp (-r * (j / 4)) * survival lam (j / 4)

/-- Protection leg to tenor `T`: `L ∫₀^T D(t) λ(t) S(t) dt` with `D(t) = e^{-rt}`. -/
noncomputable def protectionLeg (r L : ℝ) (lam : ℝ → ℝ) (T : ℝ) : ℝ :=
  L * ∫ t in (0 : ℝ)..T, Real.exp (-r * t) * lam t * survival lam t

/-- A contract only reads the hazard up to its own end date, which is why freezing works: if two
hazard curves agree from today to the tenor `T`, a contract of tenor `T` has the same risky
annuity and the same protection leg under both, so a quote matched before a later piece is
chosen stays matched whatever that later piece is. -/
theorem legs_read_hazard_only_up_to_tenor
    (r L T : ℝ) (lam lam' : ℝ → ℝ) (hT : 0 ≤ T) (hagree : Set.EqOn lam lam' (Set.Icc 0 T)) :
    riskyAnnuity r lam T = riskyAnnuity r lam' T ∧
      protectionLeg r L lam T = protectionLeg r L lam' T := by
  have hS : ∀ t, 0 ≤ t → t ≤ T → survival lam t = survival lam' t := by
    intro t ht0 htT
    have hI : ∫ x in (0 : ℝ)..t, lam x = ∫ x in (0 : ℝ)..t, lam' x := by
      apply intervalIntegral.integral_congr
      intro x hx
      rw [Set.uIcc_of_le ht0] at hx
      exact hagree ⟨hx.1, hx.2.trans htT⟩
    simp only [survival, hI]
  constructor
  · unfold riskyAnnuity
    apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mem_Icc] at hj
    have hjT : (j : ℝ) / 4 ≤ T := by
      have h1 : (j : ℝ) ≤ (⌊4 * T⌋₊ : ℝ) := by exact_mod_cast hj.2
      have h2 : (⌊4 * T⌋₊ : ℝ) ≤ 4 * T := Nat.floor_le (by positivity)
      rw [div_le_iff₀ (by norm_num : (0 : ℝ) < 4)]
      linarith
    rw [hS _ (by positivity) hjT]
  · unfold protectionLeg
    congr 1
    apply intervalIntegral.integral_congr
    intro t ht
    rw [Set.uIcc_of_le hT] at ht
    simp only
    rw [hagree ht, hS t ht.1 ht.2]

-- The straight line between the one-year (120 bp) and three-year (200 bp) quotes says 160 bp at two years.
example : ((120 : ℚ) + 200) / 2 = 160 := by norm_num
-- The straight line between 200 bp and 250 bp says 225 bp at four years.
example : ((200 : ℚ) + 250) / 2 = 225 := by norm_num
-- First guess for piece one: 120 bp divided by the loss 60% is a hazard of 2% a year.
example : ((120 : ℚ) / 10000) / (60 / 100) = 2 / 100 := by norm_num
-- The loss on default is one minus the 40% recovery.
example : (1 : ℚ) - 40 / 100 = 60 / 100 := by norm_num

#print axioms bootstrap_step_has_unique_piece
#print axioms bootstrap_step_solvable_iff
#print axioms legs_read_hazard_only_up_to_tenor
