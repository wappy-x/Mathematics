-- Implied hazard from a bond price, and why the CDS disagrees: under the card's coupon-beats-waiting-cost condition the flat-hazard bond price falls strictly, so every price in its range comes from exactly one hazard, the price runs from the riskless value down toward the recovery value, and Northwind meets the condition up to a 185% hazard.
import Mathlib
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Order.Basic

open Real Filter Topology

/-- The card's bond price at a flat hazard `h`: coupon `c` paid at years `1, …, n` while alive,
face `F` at maturity `n` while alive, and recovery `R * F` paid at the moment of default,
all discounted at the riskless rate `r`; the combined decay rate is `u = r + h`. -/
noncomputable def bondPrice (c F R r : ℝ) (n : ℕ) (h : ℝ) : ℝ :=
  (∑ i ∈ Finset.Icc 1 n, c * exp (-(r + h) * i)) + F * exp (-(r + h) * n)
    + R * F * (h / (r + h)) * (1 - exp (-(r + h) * n))

/-- The timing factor `g(u) = (e^u - 1) / u` from the credit-triangle card. -/
noncomputable def timingFactor (u : ℝ) : ℝ := (exp u - 1) / u

lemma timingFactor_mono {a b : ℝ} (ha : 0 < a) (hab : a ≤ b) :
    timingFactor a ≤ timingFactor b := by
  unfold timingFactor
  have hb : 0 < b := ha.trans_le hab
  rw [div_le_div_iff₀ ha hb]
  have h1 : exp b = exp a * exp (b - a) := by rw [← exp_add]; ring_nf
  have h2 : b - a + 1 ≤ exp (b - a) := add_one_le_exp _
  have h3 : -a + 1 ≤ exp (-a) := add_one_le_exp _
  have h4 : exp a * exp (-a) = 1 := by rw [← exp_add]; simp
  have h5 : 0 < exp a := exp_pos a
  have h6 : exp a - 1 ≤ a * exp a := by nlinarith
  rw [h1]
  nlinarith [mul_le_mul_of_nonneg_left h2 (le_of_lt (mul_pos ha h5)), sub_nonneg.2 hab]

lemma weighted_geom (x : ℝ) (n : ℕ) :
    (1 - x) * ∑ i ∈ Finset.Icc 1 n, (i : ℝ) * x ^ i
      = x * ((∑ j ∈ Finset.range n, x ^ j) - n * x ^ n) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_range_succ, mul_add, ih]
    push_cast
    ring

lemma exp_nat (u : ℝ) (k : ℕ) : exp (-u * k) = exp (-u) ^ k := by
  rw [← Real.exp_nat_mul]; ring_nf

lemma bond_hasDerivAt (c F R r : ℝ) (n : ℕ) (h : ℝ) (hu : 0 < r + h) :
    HasDerivAt (bondPrice c F R r n)
      ((∑ i ∈ Finset.Icc 1 n, c * (exp (-(r + h) * i) * (-(1:ℝ) * i)))
        + F * (exp (-(r + h) * n) * (-(1:ℝ) * n))
        + (R * F * ((1 * (r + h) - h * 1) / (r + h) ^ 2) * (1 - exp (-(r + h) * n))
          + R * F * (h / (r + h)) * (-(exp (-(r + h) * n) * (-(1:ℝ) * n))))) h := by
  have he : ∀ k : ℝ, HasDerivAt (fun y => exp (-(r + y) * k)) (exp (-(r + h) * k) * (-(1:ℝ) * k)) h :=
    fun k => (((hasDerivAt_id h).const_add r).neg.mul_const k).exp
  have hq : HasDerivAt (fun y => y / (r + y)) ((1 * (r + h) - h * 1) / (r + h) ^ 2) h :=
    (hasDerivAt_id h).div ((hasDerivAt_id h).const_add r) hu.ne'
  have hs := HasDerivAt.sum (u := Finset.Icc 1 n) (fun i _ => (he (i : ℝ)).const_mul c)
  have := (hs.add ((he n).const_mul F)).add ((hq.const_mul (R * F)).mul ((he n).const_sub 1))
  convert this using 1
  ext y; simp [bondPrice, Finset.sum_apply]

lemma deriv_neg_core (c F R r : ℝ) (n : ℕ) (h Λ : ℝ)
    (hF : 0 < F) (hR0 : 0 ≤ R) (hR1 : R < 1) (hr : 0 < r) (hn : 1 ≤ n)
    (hh : 0 ≤ h) (hhΛ : h ≤ Λ) (hcond : R * F * r * timingFactor (r + Λ) ≤ c) :
    ((∑ i ∈ Finset.Icc 1 n, c * (exp (-(r + h) * i) * (-(1:ℝ) * i)))
        + F * (exp (-(r + h) * n) * (-(1:ℝ) * n))
        + (R * F * ((1 * (r + h) - h * 1) / (r + h) ^ 2) * (1 - exp (-(r + h) * n))
          + R * F * (h / (r + h)) * (-(exp (-(r + h) * n) * (-(1:ℝ) * n))))) < 0 := by
  have hu : 0 < r + h := by linarith
  have hK : 0 ≤ R * F * r := by positivity
  have hc' : R * F * r * timingFactor (r + h) ≤ c :=
    le_trans (mul_le_mul_of_nonneg_left (timingFactor_mono hu (by linarith)) hK) hcond
  simp_rw [exp_nat]
  set u := r + h with hu_def
  set x := exp (-u) with hx_def
  have hx0 : 0 < x := exp_pos _
  have hexpu : exp u = x⁻¹ := by rw [hx_def, exp_neg, inv_inv]
  have hx1 : x < 1 := by rw [hx_def, exp_lt_one_iff]; linarith
  have h1x : 1 - x ≤ u := by have := add_one_le_exp (-u); rw [← hx_def] at this; linarith
  have htf : timingFactor u = (x⁻¹ - 1) / u := by rw [timingFactor, hexpu]
  rw [htf] at hc'
  set S1 := ∑ i ∈ Finset.Icc 1 n, (i : ℝ) * x ^ i with hS1
  set G := ∑ j ∈ Finset.range n, x ^ j with hG_def
  have hsum : (∑ i ∈ Finset.Icc 1 n, c * (x ^ i * (-(1:ℝ) * i))) = -(c * S1) := by
    rw [hS1, Finset.mul_sum, ← Finset.sum_neg_distrib]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [hsum]
  have hId := weighted_geom x n
  rw [← hS1, ← hG_def] at hId
  have hG : G * (1 - x) = 1 - x ^ n := geom_sum_mul_neg x n
  have hG0 : 0 ≤ G := Finset.sum_nonneg (fun j _ => by positivity)
  have hS0 : 0 ≤ S1 := Finset.sum_nonneg (fun i _ => by positivity)
  have hxn : 0 < x ^ n := by positivity
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  set T := (1 - x ^ n) - u * n * x ^ n with hT
  have hT1 : T ≤ u * (G - n * x ^ n) := by
    have : 1 - x ^ n ≤ G * u := by rw [← hG]; exact mul_le_mul_of_nonneg_left h1x hG0
    rw [hT]; nlinarith
  have hT2 : u * (G - n * x ^ n) = u * ((1 - x) * S1 / x) := by
    rw [hId]; field_simp
  have hKT : R * F * r / u ^ 2 * T ≤ c * S1 := by
    calc R * F * r / u ^ 2 * T ≤ R * F * r / u ^ 2 * (u * ((1 - x) * S1 / x)) := by
          rw [← hT2]; exact mul_le_mul_of_nonneg_left hT1 (by positivity)
      _ = R * F * r * ((x⁻¹ - 1) / u) * S1 := by field_simp
      _ ≤ c * S1 := mul_le_mul_of_nonneg_right hc' hS0
  have hexpr : (-(c * S1)) + F * (x ^ n * (-(1:ℝ) * n))
        + (R * F * ((1 * u - h * 1) / u ^ 2) * (1 - x ^ n)
          + R * F * (h / u) * (-(x ^ n * (-(1:ℝ) * n))))
      = -(c * S1) - (1 - R) * F * n * x ^ n + R * F * r / u ^ 2 * T := by
    rw [hT]
    have : h = u - r := by rw [hu_def]; ring
    rw [this]; field_simp; ring
  rw [hexpr]
  have : 0 < (1 - R) * F * n * x ^ n := by
    have : (0:ℝ) < n := by linarith
    have : 0 < 1 - R := by linarith
    positivity
  linarith

#print axioms timingFactor_mono
#print axioms weighted_geom
#print axioms exp_nat
#print axioms bond_hasDerivAt
#print axioms deriv_neg_core

/-- The card's main claim (Step 3): as long as one year's coupon beats one year's interest on the
recovery, grossed up by the timing factor (`R F r g(r + Λ) ≤ c`), the bond price falls strictly
for hazards from 0 to `Λ`, so every price between `B(Λ)` and the riskless price `B(0)` is
reached by exactly one flat hazard in that range. -/
theorem implied_hazard_exists_unique (c F R r : ℝ) (n : ℕ) (Λ : ℝ)
    (hF : 0 < F) (hR0 : 0 ≤ R) (hR1 : R < 1) (hr : 0 < r) (hn : 1 ≤ n)
    (hΛ : 0 ≤ Λ) (hcond : R * F * r * timingFactor (r + Λ) ≤ c) :
    StrictAntiOn (bondPrice c F R r n) (Set.Icc 0 Λ) ∧
      ∀ P ∈ Set.Icc (bondPrice c F R r n Λ) (bondPrice c F R r n 0),
        ∃! h, h ∈ Set.Icc 0 Λ ∧ bondPrice c F R r n h = P := by
  have hcont : ContinuousOn (bondPrice c F R r n) (Set.Icc 0 Λ) := fun h hh =>
    (bond_hasDerivAt c F R r n h (by linarith [hh.1])).continuousAt.continuousWithinAt
  have hanti : StrictAntiOn (bondPrice c F R r n) (Set.Icc 0 Λ) :=
    strictAntiOn_of_deriv_neg (convex_Icc 0 Λ) hcont (fun h hh => by
      rw [interior_Icc] at hh
      rw [(bond_hasDerivAt c F R r n h (by linarith [hh.1])).deriv]
      exact deriv_neg_core c F R r n h Λ hF hR0 hR1 hr hn hh.1.le hh.2.le hcond)
  refine ⟨hanti, fun P hP => ?_⟩
  obtain ⟨h, hh, hBh⟩ := intermediate_value_Icc' hΛ hcont hP
  exact ⟨h, ⟨hh, hBh⟩, fun y ⟨hy, hBy⟩ => hanti.injOn hy hh (hBy.trans hBh.symm)⟩

/-- The two ends (Step 2): at zero hazard the bond is worth its riskless price, and as the hazard
grows without limit the price tends to the recovery-only value `R * F`. -/
theorem bond_price_ends (c F R r : ℝ) (n : ℕ) (hr : 0 < r) (hn : 1 ≤ n) :
    bondPrice c F R r n 0 =
        (∑ i ∈ Finset.Icc 1 n, c * exp (-r * i)) + F * exp (-r * n) ∧
      Tendsto (bondPrice c F R r n) atTop (𝓝 (R * F)) := by
  constructor
  · simp [bondPrice]
  · have hlin : Tendsto (fun h : ℝ => r + h) atTop atTop :=
      tendsto_atTop_add_const_left _ r tendsto_id
    have hE : ∀ k : ℕ, 1 ≤ k → Tendsto (fun h : ℝ => exp (-(r + h) * k)) atTop (𝓝 0) := by
      intro k hk
      have hk' : (0:ℝ) < k := by exact_mod_cast hk
      have : Tendsto (fun h : ℝ => (r + h) * k) atTop atTop := hlin.atTop_mul_const hk'
      exact (tendsto_exp_atBot.comp (tendsto_neg_atTop_atBot.comp this)).congr
        (fun h => by simp only [Function.comp_apply, neg_mul])
    have hS : Tendsto (fun h : ℝ => ∑ i ∈ Finset.Icc 1 n, c * exp (-(r + h) * i)) atTop (𝓝 0) := by
      have := tendsto_finsetSum (Finset.Icc 1 n)
        (fun i hi => (hE i (Finset.mem_Icc.1 hi).1).const_mul c)
      simpa using this
    have hq : Tendsto (fun h : ℝ => h / (r + h)) atTop (𝓝 1) := by
      have h1 : Tendsto (fun h : ℝ => r / (r + h)) atTop (𝓝 0) :=
        tendsto_const_nhds.div_atTop hlin
      have h2 := h1.const_sub 1
      rw [sub_zero] at h2
      apply h2.congr'
      filter_upwards [eventually_gt_atTop 0] with h hh
      have : r + h ≠ 0 := by linarith
      field_simp
      ring
    have := (hS.add ((hE n hn).const_mul F)).add
      ((hq.const_mul (R * F)).mul ((hE n hn).const_sub 1))
    unfold bondPrice
    convert this using 2
    ring

/-- Northwind (coupon 6, face 100, recovery 40%, rate 5%): the condition `R F r g(u) ≤ c`,
that is `2 g(u) ≤ 6`, holds at a hazard of 185% a year (`u = 1/20 + 37/20`), so the proof
covers every hazard up to there. -/
theorem northwind_condition_holds_to_185_percent :
    (2 / 5 : ℝ) * 100 * (1 / 20) * timingFactor (1 / 20 + 37 / 20) ≤ 6 := by
  have h1 := Real.exp_one_lt_d9
  have h2 := Real.quadratic_le_exp_of_nonneg (x := (1 / 10 : ℝ)) (by norm_num)
  have h3 : exp (19 / 10) * exp (1 / 10) = exp 1 * exp 1 := by
    rw [← exp_add, ← exp_add]; norm_num
  have h4 : exp (19 / 10) ≤ 67 / 10 := by
    have e0 : 0 < exp 1 := exp_pos 1
    have e1 : 0 < exp (19 / 10) := exp_pos _
    nlinarith
  have h5 : (exp (19 / 10) - 1) / (19 / 10) ≤ 3 := by
    rw [div_le_iff₀ (by norm_num)]; linarith
  unfold timingFactor
  norm_num
  linarith

-- Northwind's yearly interest on the recovery: R F r = 40 × 5% = 2 dollars.
example : (2 / 5 : ℚ) * 100 * (1 / 20) = 2 := by norm_num
-- The coupon against that interest: the condition is g(u) ≤ 6 / 2 = 3.
example : (6 : ℚ) / 2 = 3 := by norm_num
-- The basis trade at default: the bond pays 40 and the CDS pays 60, exactly 100.
example : (2 / 5 : ℚ) * 100 + (1 - 2 / 5) * 100 = 100 := by norm_num

#print axioms implied_hazard_exists_unique
#print axioms bond_price_ends
#print axioms northwind_condition_holds_to_185_percent
