-- Auctions: under the second-price rule bidding your true value is never beaten, first-price bidders best shade to (n-1)/n of their value, and an auction's average payments are fixed by who wins.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-- Helper: `t^m (m + 1 - m t) ≤ 1` for `t ≥ 0` (weighted AM-GM in polynomial form). -/
lemma auction_aux_pow_ineq (m : ℕ) (t : ℝ) (ht : 0 ≤ t) :
    t ^ m * ((m : ℝ) + 1 - m * t) ≤ 1 := by
  induction m with
  | zero => simp
  | succ m ih =>
    have h1 : (1 - t) * (t ^ (m + 1) - 1) ≤ 0 := by
      rcases le_total t 1 with h | h
      · have : t ^ (m + 1) ≤ 1 := pow_le_one₀ ht h
        nlinarith
      · have : 1 ≤ t ^ (m + 1) := one_le_pow₀ h
        nlinarith
    have h2 : t * (t ^ m * ((m : ℝ) + 1 - m * t)) ≤ t := by
      calc _ ≤ t * 1 := mul_le_mul_of_nonneg_left ih ht
        _ = t := mul_one t
    push_cast
    have e : t ^ (m + 1) * ((m : ℝ) + 1 + 1 - (m + 1) * t)
        = t * (t ^ m * ((m : ℝ) + 1 - m * t)) + t ^ (m + 1) * (1 - t) := by ring
    rw [e]
    nlinarith

/-- Helper: with incentive compatibility, the utility `y ↦ y * P y - m y` has derivative `P x`
within `[0, V]` at every `x ∈ [0, V]`. -/
lemma auction_aux_hasDerivWithinAt (V : ℝ) (P m : ℝ → ℝ)
    (hP : ContinuousOn P (Set.Icc 0 V))
    (hIC : ∀ v ∈ Set.Icc 0 V, ∀ x ∈ Set.Icc 0 V, v * P x - m x ≤ v * P v - m v) :
    ∀ x ∈ Set.Icc 0 V, HasDerivWithinAt (fun y => y * P y - m y) (P x) (Set.Icc 0 V) x := by
  intro x hx
  rw [hasDerivWithinAt_iff_isLittleO]
  have hT : Filter.Tendsto (fun y => P y - P x) (nhdsWithin x (Set.Icc 0 V)) (nhds 0) := by
    have := (hP x hx).tendsto.sub_const (P x)
    simpa using this
  have hsmall : (fun y => (y - x) * (P y - P x)) =o[nhdsWithin x (Set.Icc 0 V)]
      (fun y => y - x) := by
    have h1 := (Asymptotics.isBigO_refl (fun y : ℝ => y - x) (nhdsWithin x (Set.Icc 0 V))).mul_isLittleO
      ((Asymptotics.isLittleO_one_iff ℝ).mpr hT)
    simpa using h1
  refine Asymptotics.IsBigO.trans_isLittleO ?_ hsmall
  refine Asymptotics.IsBigO.of_bound 1 ?_
  filter_upwards [self_mem_nhdsWithin] with y hy
  have a1 := hIC y hy x hx
  have a2 := hIC x hx y hy
  simp only [smul_eq_mul, Real.norm_eq_abs, one_mul]
  rw [abs_le]
  have hb : 0 ≤ y * P y - m y - (x * P x - m x) - (y - x) * P x := by linarith
  have hc : y * P y - m y - (x * P x - m x) - (y - x) * P x ≤ (y - x) * (P y - P x) := by
    nlinarith
  constructor
  · have := neg_abs_le ((y - x) * (P y - P x))
    have := abs_nonneg ((y - x) * (P y - P x))
    linarith
  · exact hc.trans (le_abs_self _)

/-- Second-price (Vickrey) rule: a firm with value `v` that bids `b` wins when `b` beats the best
rival bid `c`, pays `c`, and makes profit `v - c`; otherwise its profit is 0. Bidding exactly its
value `v` gives at least as much profit as any other bid `b`, whatever the rival bid `c` is:
honesty is a weakly dominant strategy. -/
theorem second_price_truthful_bid_weakly_dominant (v b c : ℝ) :
    (if b > c then v - c else 0) ≤ (if v > c then v - c else 0) := by
  split_ifs <;> linarith

/-- First-price rule with `n` bidders whose values are spread evenly between 0 and `V`:
if every rival bids `(n-1)/n` of its value, rival bids are spread evenly up to `(n-1)/n · V`, so a
bid `b ≥ 0` beats all `n - 1` rivals with chance `min (b / ((n-1)/n · V)) 1 ^ (n-1)` and earns
`v - b` when it wins. A firm with value `v` then does best by bidding `(n-1)/n · v` as well:
no other bid gives a higher average profit, so shading by one part in `n` is a Nash equilibrium. -/
theorem first_price_best_reply_shades_bid (n : ℕ) (hn : 2 ≤ n) (V v : ℝ) (hV : 0 < V)
    (hv0 : 0 ≤ v) (hvV : v ≤ V) (b : ℝ) (hb : 0 ≤ b) :
    (v - b) * (min (b / (((n - 1) / n : ℝ) * V)) 1) ^ (n - 1) ≤
      (v - ((n - 1) / n : ℝ) * v) *
        (min ((((n - 1) / n : ℝ) * v) / (((n - 1) / n : ℝ) * V)) 1) ^ (n - 1) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hm1 : 1 ≤ m := by omega
  simp only [Nat.add_sub_cancel]
  have hk : (((m + 1 : ℕ) : ℝ) - 1) / ((m + 1 : ℕ) : ℝ) = (m : ℝ) / (m + 1) := by
    push_cast; ring
  rw [hk]
  set k : ℝ := (m : ℝ) / (m + 1) with hkdef
  have hmpos : (0 : ℝ) < m := by exact_mod_cast hm1
  have hk0 : 0 < k := by positivity
  have hkV : 0 < k * V := mul_pos hk0 hV
  have hR : min (k * v / (k * V)) 1 = v / V := by
    rw [mul_div_mul_left _ _ hk0.ne']
    exact min_eq_left ((div_le_one hV).mpr hvV)
  rw [hR]
  have key : ∀ b', 0 ≤ b' → (v - b') * (b' / (k * V)) ^ m ≤ (v - k * v) * (v / V) ^ m := by
    intro b' hb'
    rcases hv0.eq_or_lt with h | h
    · subst h
      have hX : 0 ≤ (b' / (k * V)) ^ m := by positivity
      simp only [mul_zero, sub_zero, zero_div, zero_sub]
      rw [zero_pow (by omega), mul_zero]
      nlinarith [mul_nonneg hb' hX]
    · set t := b' / (k * v) with htdef
      have ht : 0 ≤ t := by positivity
      have hkv : 0 < k * v := mul_pos hk0 h
      have hb'eq : b' = k * v * t := by rw [htdef]; field_simp
      have haux := auction_aux_pow_ineq m t ht
      rw [hb'eq]
      have e1 : (v - k * v * t) * (k * v * t / (k * V)) ^ m
          = v * (1 - k * t) * t ^ m * (v / V) ^ m := by
        rw [show k * v * t / (k * V) = t * (v / V) by field_simp]
        rw [mul_pow]; ring
      rw [e1]
      have h3 : (1 - k * t) * t ^ m ≤ 1 - k := by
        have e2 : (1 - k * t) * t ^ m = t ^ m * ((m : ℝ) + 1 - m * t) / (m + 1) := by
          rw [hkdef]; field_simp
        have e3 : 1 - k = 1 / ((m : ℝ) + 1) := by
          rw [hkdef]; field_simp; ring
        rw [e2, e3]
        exact div_le_div_of_nonneg_right haux (by positivity)
      calc v * (1 - k * t) * t ^ m * (v / V) ^ m = (v * (v / V) ^ m) * ((1 - k * t) * t ^ m) := by
            ring
        _ ≤ (v * (v / V) ^ m) * (1 - k) := mul_le_mul_of_nonneg_left h3 (by positivity)
        _ = (v - k * v) * (v / V) ^ m := by ring
  rcases le_or_gt b (k * V) with hbk | hbk
  · have hmin : min (b / (k * V)) 1 = b / (k * V) := min_eq_left ((div_le_one hkV).mpr hbk)
    rw [hmin]
    exact key b hb
  · have hmin : min (b / (k * V)) 1 = 1 := min_eq_right ((one_le_div hkV).mpr hbk.le)
    rw [hmin, one_pow, mul_one]
    have := key (k * V) hkV.le
    rw [div_self hkV.ne', one_pow, mul_one] at this
    linarith

/-- Revenue equivalence, Step 3 of the card: take any auction where a firm with value `v` in
`[0, V]` wins with chance `P v` (continuous) and pays `m v` on average, a firm with value 0 pays
nothing, and no firm gains by bidding as if its value were some other `x`. Then the average payment
is fixed by the win chance alone: `m v = v · P v - ∫₀^v P`. So two auctions with the same rule for
who wins charge every value the same on average and raise the same average revenue. -/
theorem payment_fixed_by_win_chance (V : ℝ) (P m : ℝ → ℝ)
    (hP : ContinuousOn P (Set.Icc 0 V)) (hm0 : m 0 = 0)
    (hIC : ∀ v ∈ Set.Icc 0 V, ∀ x ∈ Set.Icc 0 V, v * P x - m x ≤ v * P v - m v) :
    ∀ v ∈ Set.Icc 0 V, m v = v * P v - ∫ x in (0 : ℝ)..v, P x := by
  intro v hv
  have hder := auction_aux_hasDerivWithinAt V P m hP hIC
  have hsub : Set.Icc 0 v ⊆ Set.Icc 0 V := Set.Icc_subset_Icc le_rfl hv.2
  have hcont : ContinuousOn (fun y => y * P y - m y) (Set.Icc 0 v) := fun x hx =>
    (hder x (hsub hx)).continuousWithinAt.mono hsub
  have hint : IntervalIntegrable P MeasureTheory.volume 0 v :=
    (hP.mono hsub).intervalIntegrable_of_Icc hv.1
  have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hv.1 hcont
    (fun x hx => (hder x ⟨hx.1.le, hx.2.le.trans hv.2⟩).hasDerivAt
      (Icc_mem_nhds hx.1 (hx.2.trans_le hv.2))) hint
  rw [hftc]
  simp only [hm0]
  ring

-- The day, in pounds. Second-price: A (value 82,000) bids its value, B's 71,000 is the best
-- rival bid, so A pays 71,000 and makes 11,000.
example : (if (82000 : ℤ) > 71000 then (82000 : ℤ) - 71000 else 0) = 11000 := by decide
-- A shades to 65,600 in the second-price auction: it loses to B's 71,000 and makes 0.
example : (if (65600 : ℤ) > 71000 then (82000 : ℤ) - 71000 else 0) = 0 := by decide
-- E (value 40,000) bids 90,000 against A's 82,000: it wins, pays 82,000 and loses 42,000.
example : (if (90000 : ℤ) > 82000 then (40000 : ℤ) - 82000 else 0) = -42000 := by decide
-- First-price bids at (n-1)/n = 4/5 of value, for the five firms.
example : (4 * 82000 / 5, 4 * 71000 / 5, 4 * 64000 / 5, 4 * 55000 / 5, 4 * 40000 / 5)
    = (65600, 56800, 51200, 44000, 32000) := by decide
-- First-price: A wins with 65,600 and makes 82,000 - 65,600 = 16,400.
example : (82000 : ℤ) - 65600 = 16400 := by decide
-- Firm A's average payment (in thousands), from the envelope formula and from its first-price bid
-- 0.8 × 82 times its win chance (65.6 / 80)^4: the same number.
example : (82 : ℚ) * (82 / 100) ^ 4 - 82 ^ 5 / (5 * 100 ^ 4)
    = (4 / 5 * 82) * ((4 / 5 * 82) / 80) ^ 4 := by norm_num
-- Average revenue with 5 firms and values up to 100 (thousands): second-price (n-1)/(n+1) × 100
-- and first-price (n-1)/n × n/(n+1) × 100 are both 200/3, about 66.67.
example : ((5 : ℚ) - 1) / (5 + 1) * 100 = 200 / 3 := by norm_num
example : ((5 : ℚ) - 1) / 5 * (5 / (5 + 1)) * 100 = 200 / 3 := by norm_num

#print axioms auction_aux_pow_ineq
#print axioms auction_aux_hasDerivWithinAt
#print axioms second_price_truthful_bid_weakly_dominant
#print axioms first_price_best_reply_shades_bid
#print axioms payment_fixed_by_win_chance
