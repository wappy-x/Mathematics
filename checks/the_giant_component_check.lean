-- The giant component: the giant's share equation zeta = 1 - e^(-c zeta) has a root in (0, 1) exactly when c > 1, and the family-tree dying-out chance is its partner root.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Order.MonotoneConvergence

open Real Filter Topology

lemma giant_le_one_only_zero (c : ℝ) (hc : c ≤ 1) (ζ : ℝ) (h0 : 0 ≤ ζ)
    (hζ : ζ = 1 - exp (-c * ζ)) : ζ = 0 := by
  by_contra hne
  have hpos : 0 < ζ := lt_of_le_of_ne h0 (Ne.symm hne)
  rcases le_or_gt c 0 with hc0 | hc0
  · have : 1 ≤ exp (-c * ζ) := by
      apply one_le_exp; nlinarith
    linarith
  · have hx : (-c * ζ) ≠ 0 := by
      have : 0 < c * ζ := mul_pos hc0 hpos
      intro h; linarith
    have := add_one_lt_exp hx
    nlinarith

lemma giant_no_two_roots (c : ℝ) (a b : ℝ) (ha : 0 < a) (hab : a < b)
    (hA : a = 1 - exp (-c * a)) (hB : b = 1 - exp (-c * b)) (hc : 0 < c) : False := by
  have hb : 0 < b := lt_trans ha hab
  set t := a / b with ht
  have ht0 : 0 < t := div_pos ha hb
  have ht1 : t < 1 := (div_lt_one hb).2 hab
  have hne : (0 : ℝ) ≠ -c * b := by
    have : 0 < c * b := mul_pos hc hb
    intro h; linarith
  have key := strictConvexOn_exp.2 (Set.mem_univ (0 : ℝ)) (Set.mem_univ (-c * b)) hne
    (by linarith : (0 : ℝ) < 1 - t) ht0 (by ring)
  simp only [smul_eq_mul, mul_zero, zero_add, exp_zero, mul_one] at key
  have htb : t * b = a := by rw [ht]; field_simp
  have hx : t * (-c * b) = -c * a := by rw [← htb]; ring
  rw [hx] at key
  have : t * b = a := htb
  nlinarith

lemma giant_exists_root (c : ℝ) (hc : 1 < c) :
    ∃ ζ : ℝ, ζ ∈ Set.Ioo (0 : ℝ) 1 ∧ ζ = 1 - exp (-c * ζ) := by
  set f : ℝ → ℝ := fun z => 1 - exp (-c * z) - z with hf
  set δ := (c - 1) / (2 * c) with hδ
  have hc0 : 0 < c := by linarith
  have hδ0 : 0 < δ := div_pos (by linarith) (by linarith)
  have hδ1 : δ < 1 := by
    rw [hδ, div_lt_one (by linarith)]; linarith
  have hcδ : c * δ = (c - 1) / 2 := by rw [hδ]; field_simp
  have hfδ : 0 < f δ := by
    simp only [hf]
    have h1 : c * δ + 1 ≤ exp (c * δ) := add_one_le_exp _
    have h2 : exp (-c * δ) * exp (c * δ) = 1 := by
      rw [← exp_add]; simp
    have hpos : 0 < exp (-c * δ) := exp_pos _
    -- exp(-cδ) ≤ 1/(1+cδ)
    have h3 : exp (-c * δ) * (c * δ + 1) ≤ 1 := by
      calc exp (-c * δ) * (c * δ + 1) ≤ exp (-c * δ) * exp (c * δ) :=
            mul_le_mul_of_nonneg_left h1 hpos.le
        _ = 1 := h2
    -- need 1 - e - δ > 0, i.e. e < 1 - δ; e ≤ 1/(1+cδ) and 1/(1+cδ) < 1 - δ
    -- (1 - δ)(1 + cδ) = 1 + (c-1)δ - cδ^2 = 1 + δ (c - 1 - cδ) = 1 + δ (c-1)/2 > 1
    have h4 : 1 < (1 - δ) * (c * δ + 1) := by
      have : (1 - δ) * (c * δ + 1) = 1 + δ * ((c - 1) - c * δ) := by ring
      rw [this, hcδ]; nlinarith
    nlinarith
  have hf1 : f 1 < 0 := by simp only [hf]; have := exp_pos (-c * 1); linarith
  have hcont : ContinuousOn f (Set.Icc δ 1) := by
    apply Continuous.continuousOn
    simp only [hf]; fun_prop
  obtain ⟨z, hz, hfz⟩ := intermediate_value_Icc' hδ1.le hcont ⟨hf1.le, hfδ.le⟩
  refine ⟨z, ⟨lt_of_lt_of_le hδ0 hz.1, ?_⟩, ?_⟩
  · rcases lt_or_eq_of_le hz.2 with h | h
    · exact h
    · rw [h] at hfz; linarith
  · simp only [hf] at hfz; linarith

#print axioms giant_le_one_only_zero
#print axioms giant_no_two_roots
#print axioms giant_exists_root

/-- The giant's share equation `ζ = 1 - e^(-c ζ)`: if the average number of friends `c` is at
most one, zero is its only root in 0 to 1 (no giant); if `c` is above one, there is exactly one
root `ζ` strictly between 0 and 1 (the giant's share). -/
theorem giant_share_switch_at_one (c : ℝ) :
    (c ≤ 1 → ∀ ζ ∈ Set.Icc (0 : ℝ) 1, ζ = 1 - exp (-c * ζ) → ζ = 0) ∧
    (1 < c → ∃! ζ : ℝ, ζ ∈ Set.Ioo (0 : ℝ) 1 ∧ ζ = 1 - exp (-c * ζ)) := by
  refine ⟨fun hc ζ hζ he => giant_le_one_only_zero c hc ζ hζ.1 he, fun hc => ?_⟩
  obtain ⟨ζ, hζ, he⟩ := giant_exists_root c hc
  refine ⟨ζ, ⟨hζ, he⟩, fun y ⟨hy, hye⟩ => ?_⟩
  rcases lt_trichotomy y ζ with h | h | h
  · exact (giant_no_two_roots c y ζ hy.1 h hye he (by linarith)).elim
  · exact h
  · exact (giant_no_two_roots c ζ y hζ.1 h he hye (by linarith)).elim

/-- The family tree with Poisson(c) children: the chance `q_k` that the line is dead by
generation `k` obeys `q_k = e^(c (q_(k-1) - 1))` with `q_0 = 0`. It climbs to the smallest root
`q` of `q = e^(c (q - 1))` in 0 to 1, and that root is below 1 (the line can survive) exactly
when `c > 1`. -/
theorem extinction_chance_smallest_root (c : ℝ) (hc : 0 ≤ c) :
    ∃ q ∈ Set.Icc (0 : ℝ) 1,
      Tendsto (fun k : ℕ => (fun s : ℝ => exp (c * (s - 1)))^[k] 0) atTop (𝓝 q) ∧
      q = exp (c * (q - 1)) ∧
      (∀ r ∈ Set.Icc (0 : ℝ) 1, r = exp (c * (r - 1)) → q ≤ r) ∧
      (q < 1 ↔ 1 < c) := by
  set φ : ℝ → ℝ := fun s => exp (c * (s - 1)) with hφ
  have hmonoφ : Monotone φ := by
    intro x y hxy; simp only [hφ]; apply exp_le_exp.2; nlinarith
  have hφ1 : φ 1 = 1 := by simp [hφ]
  have hcontφ : Continuous φ := by simp only [hφ]; fun_prop
  have hbound : ∀ r, 0 ≤ r → φ r = r → ∀ k : ℕ, φ^[k] 0 ≤ r := by
    intro r hr hfix k
    induction k with
    | zero => simpa using hr
    | succ k ih =>
      rw [Function.iterate_succ_apply', ← hfix]; exact hmonoφ ih
  have hmono : Monotone (fun k : ℕ => φ^[k] 0) := by
    apply monotone_nat_of_le_succ
    intro k
    induction k with
    | zero => simp only [Function.iterate_zero, id, hφ]; exact (exp_pos _).le
    | succ k ih =>
      rw [Function.iterate_succ_apply', Function.iterate_succ_apply' φ (k + 1)]
      exact hmonoφ ih
  have hbdd : BddAbove (Set.range (fun k : ℕ => φ^[k] 0)) := by
    refine ⟨1, ?_⟩
    rintro _ ⟨k, rfl⟩; exact hbound 1 zero_le_one hφ1 k
  have hT := tendsto_atTop_ciSup hmono hbdd
  set q := ⨆ k, φ^[k] 0 with hq
  have hq0 : 0 ≤ q := by
    have := le_ciSup hbdd 0; simpa using this
  have hqle : ∀ r, 0 ≤ r → φ r = r → q ≤ r := fun r hr hfix =>
    ciSup_le (hbound r hr hfix)
  have hq1 : q ≤ 1 := hqle 1 zero_le_one hφ1
  have hfixq : φ q = q := by
    have h1 : Tendsto (fun k : ℕ => φ^[k + 1] 0) atTop (𝓝 q) :=
      hT.comp (tendsto_add_atTop_nat 1)
    have h2 : Tendsto (fun k : ℕ => φ^[k + 1] 0) atTop (𝓝 (φ q)) := by
      have := (hcontφ.tendsto q).comp hT
      refine this.congr ?_
      intro k; simp [Function.comp, Function.iterate_succ_apply']
    exact tendsto_nhds_unique h2 h1
  refine ⟨q, ⟨hq0, hq1⟩, hT, hfixq.symm, fun r hr hrfix => hqle r hr.1 hrfix.symm, ?_⟩
  constructor
  · intro hqlt
    by_contra hcle
    rw [not_lt] at hcle
    have hz := (giant_share_switch_at_one c).1 hcle (1 - q) ⟨by linarith, by linarith⟩ (by
      have : exp (-c * (1 - q)) = q := by
        have h' : exp (-c * (1 - q)) = φ q := by simp only [hφ]; congr 1; ring
        rw [h', hfixq]
      rw [this])
    linarith
  · intro hc1
    obtain ⟨ζ, ⟨hζ, he⟩, -⟩ := (giant_share_switch_at_one c).2 hc1
    have hr : φ (1 - ζ) = 1 - ζ := by
      simp only [hφ]
      have : c * (1 - ζ - 1) = -c * ζ := by ring
      rw [this]; linarith
    have := hqle (1 - ζ) (by linarith [hζ.2]) hr
    linarith [hζ.1]

/-- Below the switch, Chernoff's choice `t = ln(1/c)` turns the exponent `c (e^t - 1) - t`
into `-I` with `I = c - 1 - ln c`, and this rate `I` is positive, so the chance that one
person's island tops `k` people is at most `e^(-k I)`. -/
theorem small_island_rate (c : ℝ) (h0 : 0 < c) (h1 : c < 1) :
    c * (exp (log (1 / c)) - 1) - log (1 / c) = -(c - 1 - log c) ∧
      0 < c - 1 - log c := by
  have hlog : log (1 / c) = -log c := by rw [one_div, log_inv]
  have hexp : exp (log (1 / c)) = 1 / c := exp_log (by positivity)
  refine ⟨?_, ?_⟩
  · rw [hexp, hlog]; field_simp; ring
  · have := log_lt_sub_one_of_pos h0 (ne_of_lt h1); linarith

-- 1,000 people make 499,500 possible pairs.
example : 1000 * 999 / 2 = 499500 := by norm_num

-- 250 closed foursomes: 6 friendships each, 1,500 in all, an average of 3 friends per person.
example : 250 * Nat.choose 4 2 = 1500 ∧ 2 * 1500 / 1000 = 3 := by decide

-- 300 people with 3 friends and 700 with none average 9/10 of a friend,
-- yet a friend's new friends average 2.
example : ((300 * 3 : ℚ) / 1000 = 9 / 10) ∧ ((3 * 2 * 300 : ℚ) / 900 = 2) := by norm_num

-- The mean-island bound 1 / (1 - c) at c = 1/2 is 2.
example : (1 : ℚ) / (1 - 1 / 2) = 2 := by norm_num

#print axioms giant_share_switch_at_one
#print axioms extinction_chance_smallest_root
#print axioms small_island_rate
