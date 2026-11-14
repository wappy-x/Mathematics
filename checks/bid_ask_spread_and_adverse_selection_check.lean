-- The spread: the Glosten-Milgrom quotes from Bayes' rule give the spread formula, the spread rises with the informed share, and Roll's bid-ask bounce gives a lag-one covariance of minus the half-spread squared.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Basic

open MeasureTheory ProbabilityTheory

/-! ## The Glosten-Milgrom model

The value is `vH` (good news) or `vL` (bad news). The dealer's chance of good news is `π`.
A share `μ` of traders know the news: they buy on good news and sell on bad news.
The rest buy or sell with chance 1/2 each. The four cells below are the joint chances
of (news, order side). -/

/-- Chance that the news is good and a buy arrives: `π * (μ + (1 - μ)/2)`. -/
noncomputable def goodBuy (π μ : ℝ) : ℝ := π * (μ + (1 - μ) / 2)

/-- Chance that the news is bad and a buy arrives: only the uninformed buy. -/
noncomputable def badBuy (π μ : ℝ) : ℝ := (1 - π) * ((1 - μ) / 2)

/-- Chance that the news is good and a sell arrives: only the uninformed sell. -/
noncomputable def goodSell (π μ : ℝ) : ℝ := π * ((1 - μ) / 2)

/-- Chance that the news is bad and a sell arrives: `(1 - π) * (μ + (1 - μ)/2)`. -/
noncomputable def badSell (π μ : ℝ) : ℝ := (1 - π) * (μ + (1 - μ) / 2)

/-- The ask: the expected value given a buy, `E[V | buy]`, by Bayes' rule over the cells. -/
noncomputable def ask (vL vH π μ : ℝ) : ℝ :=
  (vH * goodBuy π μ + vL * badBuy π μ) / (goodBuy π μ + badBuy π μ)

/-- The bid: the expected value given a sell, `E[V | sell]`, by Bayes' rule over the cells. -/
noncomputable def bid (vL vH π μ : ℝ) : ℝ :=
  (vH * goodSell π μ + vL * badSell π μ) / (goodSell π μ + badSell π μ)

/-- The spread formula. When each quote is the value expected given the order that hits it
(ask `= E[V | buy]`, bid `= E[V | sell]`), the spread is
`s = Δ · 4μπ(1-π) / (1 - μ²(2π-1)²)` with `Δ = vH - vL`. It holds for every prior chance
`π` of good news and every informed share `μ` in `[0, 1]`, as long as both a buy and a sell
have positive chance, that is `μ(2π-1)` lies strictly between `-1` and `1`. -/
theorem spread_formula (vL vH π μ : ℝ) (hπ0 : 0 ≤ π) (hπ1 : π ≤ 1) (hμ0 : 0 ≤ μ) (hμ1 : μ ≤ 1)
    (hμd : |μ * (2 * π - 1)| < 1) :
    ask vL vH π μ - bid vL vH π μ
      = (vH - vL) * (4 * μ * π * (1 - π)) / (1 - μ ^ 2 * (2 * π - 1) ^ 2) := by
  have hb : 0 < 1 + μ * (2 * π - 1) := by
    have := neg_abs_le (μ * (2 * π - 1)); linarith
  have hs : 0 < 1 - μ * (2 * π - 1) := by
    have := le_abs_self (μ * (2 * π - 1)); linarith
  have hB : goodBuy π μ + badBuy π μ = (1 + μ * (2 * π - 1)) / 2 := by
    unfold goodBuy badBuy; ring
  have hS : goodSell π μ + badSell π μ = (1 - μ * (2 * π - 1)) / 2 := by
    unfold goodSell badSell; ring
  have hD : 1 - μ ^ 2 * (2 * π - 1) ^ 2 = (1 + μ * (2 * π - 1)) * (1 - μ * (2 * π - 1)) := by
    ring
  unfold ask bid
  rw [hB, hS, hD, div_sub_div _ _ (half_pos hb).ne' (half_pos hs).ne',
    div_eq_div_iff (mul_pos (half_pos hb) (half_pos hs)).ne' (mul_pos hb hs).ne']
  unfold goodBuy badBuy goodSell badSell
  ring

/-- More informed traders, wider spread: when the news is not yet certain (`0 < π < 1`) and the
two values differ (`vL < vH`), the spread `ask - bid` rises strictly with the informed share
`μ` across `[0, 1]`. -/
theorem spread_strictMonoOn_informed_share (vL vH π : ℝ) (hv : vL < vH)
    (hπ0 : 0 < π) (hπ1 : π < 1) :
    StrictMonoOn (fun μ => ask vL vH π μ - bid vL vH π μ) (Set.Icc 0 1) := by
  intro a ha b hb hab
  simp only [Set.mem_Icc] at ha hb
  have hk : |2 * π - 1| < 1 := by rw [abs_lt]; constructor <;> linarith
  have hd : ∀ μ, 0 ≤ μ → μ ≤ 1 → |μ * (2 * π - 1)| < 1 := by
    intro μ h0 h1
    rw [abs_mul, abs_of_nonneg h0]
    calc μ * |2 * π - 1| ≤ 1 * |2 * π - 1| := by gcongr
      _ < 1 := by linarith
  have hpos : ∀ μ, 0 ≤ μ → μ ≤ 1 → 0 < 1 - μ ^ 2 * (2 * π - 1) ^ 2 := by
    intro μ h0 h1
    have h := hd μ h0 h1
    have : (μ * (2 * π - 1)) ^ 2 < 1 := by
      rw [← sq_abs]; nlinarith [abs_nonneg (μ * (2 * π - 1))]
    nlinarith
  simp only
  rw [spread_formula vL vH π a (le_of_lt hπ0) (le_of_lt hπ1) ha.1 ha.2 (hd a ha.1 ha.2),
    spread_formula vL vH π b (le_of_lt hπ0) (le_of_lt hπ1) hb.1 hb.2 (hd b hb.1 hb.2)]
  have pa := hpos a ha.1 ha.2
  have pb := hpos b hb.1 hb.2
  rw [div_lt_div_iff₀ pa pb]
  have hA : 0 < (vH - vL) * (4 * π * (1 - π)) := by
    apply mul_pos (by linarith); apply mul_pos (by linarith) (by linarith)
  have hK : 0 ≤ (2 * π - 1) ^ 2 := sq_nonneg _
  have key : a * (1 - b ^ 2 * (2 * π - 1) ^ 2) < b * (1 - a ^ 2 * (2 * π - 1) ^ 2) := by
    have : 0 ≤ a * b * (2 * π - 1) ^ 2 := mul_nonneg (mul_nonneg ha.1 hb.1) hK
    nlinarith
  have := mul_lt_mul_of_pos_left key hA
  nlinarith

/-- Roll's covariance. Trade prices are a fair price plus half a spread `c` in the direction of
the trade: `price t = M t + c * Q t`, with `M (t+1) = M t + ε (t+1)`. The news steps `ε t` have
average zero and finite variance; the sides `Q t` are fair `±1` flips; all of them are
independent. Then any two successive price changes have covariance `-c²`. -/
theorem roll_covariance {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (c : ℝ) (ε Q M : ℕ → Ω → ℝ)
    (hindep : iIndepFun (Sum.elim ε Q) P)
    (hε2 : ∀ t, MemLp (ε t) 2 P) (hε0 : ∀ t, ∫ ω, ε t ω ∂P = 0)
    (hQmeas : ∀ t, Measurable (Q t)) (hQpm : ∀ t ω, Q t ω = 1 ∨ Q t ω = -1)
    (hQfair : ∀ t, P (Q t ⁻¹' {1}) = 1 / 2)
    (hM : ∀ t ω, M (t + 1) ω = M t ω + ε (t + 1) ω) (t : ℕ) :
    covariance
      (fun ω => (M (t + 2) ω + c * Q (t + 2) ω) - (M (t + 1) ω + c * Q (t + 1) ω))
      (fun ω => (M (t + 1) ω + c * Q (t + 1) ω) - (M t ω + c * Q t ω)) P
      = -c ^ 2 := by
  have hQmem : ∀ i, MemLp (Q i) 2 P := fun i =>
    MemLp.of_bound (hQmeas i).aestronglyMeasurable 1
      (Filter.Eventually.of_forall fun ω => by rcases hQpm i ω with h | h <;> simp [h])
  have hQmean : ∀ i, ∫ ω, Q i ω ∂P = 0 := by
    intro i
    have hset : MeasurableSet (Q i ⁻¹' {1}) := hQmeas i (measurableSet_singleton 1)
    have heq : Q i = fun ω => 2 * (Q i ⁻¹' {1}).indicator 1 ω - 1 := by
      funext ω
      rcases hQpm i ω with h | h
      · have : ω ∈ Q i ⁻¹' {1} := by simp [h]
        simp [h]; norm_num
      · have : ω ∉ Q i ⁻¹' {1} := by simp [h]; norm_num
        simp [Set.indicator_of_notMem this, h]
    rw [heq, integral_sub, integral_const_mul, integral_indicator_one hset]
    · simp [Measure.real, hQfair i]
    · exact ((integrable_indicator_iff hset).2 (integrable_const 1).integrableOn).const_mul 2
    · exact integrable_const 1
  have hQvar : ∀ i, cov[Q i, Q i; P] = 1 := by
    intro i
    rw [covariance_eq_sub (hQmem i) (hQmem i), hQmean i]
    have : Q i * Q i = fun _ => (1 : ℝ) := by
      funext ω; rcases hQpm i ω with h | h <;> simp [h]
    rw [this]; simp
  have iee : ∀ a b, a ≠ b → cov[ε a, ε b; P] = 0 := fun a b h =>
    (by simpa using hindep.indepFun (i := Sum.inl a) (j := Sum.inl b) (by simpa using h) :
      IndepFun (ε a) (ε b) P).covariance_eq_zero (hε2 a) (hε2 b)
  have ieq : ∀ a b, cov[ε a, Q b; P] = 0 := fun a b =>
    (by simpa using hindep.indepFun (i := Sum.inl a) (j := Sum.inr b) (by simp) :
      IndepFun (ε a) (Q b) P).covariance_eq_zero (hε2 a) (hQmem b)
  have iqe : ∀ a b, cov[Q a, ε b; P] = 0 := fun a b =>
    (by simpa using hindep.indepFun (i := Sum.inr a) (j := Sum.inl b) (by simp) :
      IndepFun (Q a) (ε b) P).covariance_eq_zero (hQmem a) (hε2 b)
  have iqq : ∀ a b, a ≠ b → cov[Q a, Q b; P] = 0 := fun a b h =>
    (by simpa using hindep.indepFun (i := Sum.inr a) (j := Sum.inr b) (by simpa using h) :
      IndepFun (Q a) (Q b) P).covariance_eq_zero (hQmem a) (hQmem b)
  have hX : (fun ω => (M (t + 2) ω + c * Q (t + 2) ω) - (M (t + 1) ω + c * Q (t + 1) ω))
      = ε (t + 2) + (c • Q (t + 2) - c • Q (t + 1)) := by
    funext ω
    have h := hM (t + 1) ω
    simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
    rw [show t + 1 + 1 = t + 2 from rfl] at h
    linarith
  have hY : (fun ω => (M (t + 1) ω + c * Q (t + 1) ω) - (M t ω + c * Q t ω))
      = ε (t + 1) + (c • Q (t + 1) - c • Q t) := by
    funext ω
    have h := hM t ω
    simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
    linarith
  have m := hQmem
  have e := hε2
  rw [hX, hY]
  rw [covariance_add_left (e _) (((m _).const_smul c).sub ((m _).const_smul c))
      ((e _).add (((m _).const_smul c).sub ((m _).const_smul c))),
    covariance_add_right (e _) (e _) (((m _).const_smul c).sub ((m _).const_smul c)),
    covariance_add_right (((m _).const_smul c).sub ((m _).const_smul c)) (e _)
      (((m _).const_smul c).sub ((m _).const_smul c)),
    covariance_sub_right (e _) ((m _).const_smul c) ((m _).const_smul c),
    covariance_sub_left ((m _).const_smul c) ((m _).const_smul c) (e _),
    covariance_sub_sub ((m _).const_smul c) ((m _).const_smul c) ((m _).const_smul c)
      ((m _).const_smul c)]
  simp only [covariance_smul_left, covariance_smul_right]
  rw [iee (t + 2) (t + 1) (by omega), ieq, ieq, iqe, iqe, iqq (t + 2) (t + 1) (by omega),
    iqq (t + 2) t (by omega), iqq (t + 1) t (by omega), hQvar]
  ring

/-! ## The card's worked numbers, in cents: values 9980 and 10020, even odds, 10% informed. -/

-- chance of good news after a buy, and after a sell: 0.55 and 0.45
example : goodBuy (1/2) (1/10) / (goodBuy (1/2) (1/10) + badBuy (1/2) (1/10)) = 11 / 20 := by
  norm_num [goodBuy, badBuy]
example : goodSell (1/2) (1/10) / (goodSell (1/2) (1/10) + badSell (1/2) (1/10)) = 9 / 20 := by
  norm_num [goodSell, badSell]
-- ask $100.02 and bid $99.98
example : ask 9980 10020 (1/2) (1/10) = 10002 := by norm_num [ask, goodBuy, badBuy]
example : bid 9980 10020 (1/2) (1/10) = 9998 := by norm_num [bid, goodSell, badSell]
-- spread from the formula: 40 * 4 * 0.10 * 0.25 / 1 = 4 cents
example : (40 : ℚ) * (4 * (1/10) * (1/2) * (1 - 1/2)) / (1 - (1/10) ^ 2 * (2 * (1/2) - 1) ^ 2) = 4 := by
  norm_num
-- the books balance: informed take 0.10 * (20 - 2) = uninformed pay 0.90 * 2 = 1.8 cents
example : (1/10 : ℚ) * (20 - 2) = 9/10 * 2 ∧ (9/10 : ℚ) * 2 = 9/5 := by norm_num
-- everyone informed: the spread is the whole 40-cent gap
example : ask 9980 10020 (1/2) 1 - bid 9980 10020 (1/2) 1 = 40 := by
  norm_num [ask, bid, goodBuy, badBuy, goodSell, badSell]
-- try: prior 3/4, 20% informed: bid 10006.67, ask 10012.73, spread 6.06 cents
example : bid 9980 10020 (3/4) (1/5) = 30020 / 3 := by norm_num [bid, goodSell, badSell]
example : ask 9980 10020 (3/4) (1/5) = 110140 / 11 := by norm_num [ask, goodBuy, badBuy]
example : (110140 / 11 : ℚ) - 30020 / 3 = 200 / 33 := by norm_num
-- try: half the traders informed gives 20 cents; a 100-cent gap with 10% informed gives 10 cents
example : ask 9980 10020 (1/2) (1/2) - bid 9980 10020 (1/2) (1/2) = 20 := by
  norm_num [ask, bid, goodBuy, badBuy, goodSell, badSell]
example : ask 9950 10050 (1/2) (1/10) - bid 9950 10050 (1/2) (1/10) = 10 := by
  norm_num [ask, bid, goodBuy, badBuy, goodSell, badSell]
-- Roll, exact over all 32 equally likely cases with c = 2: the products sum to -32 * 4
example : (List.sum (do
    let e1 ← [-1, 1]; let e0 ← [-1, 1]; let q2 ← [-1, 1]; let q1 ← [-1, 1]; let q0 ← [-1, 1]
    pure ((e1 + 2 * (q2 - q1)) * (e0 + 2 * (q1 - q0)) : ℤ))) = -32 * 2 ^ 2 := by decide
-- Roll: covariance -4 square cents gives the spread back, 2 * sqrt 4 = 4 cents
example : 2 * Real.sqrt (-(-4)) = 4 := by
  rw [neg_neg, show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num

#print axioms spread_formula
#print axioms spread_strictMonoOn_informed_share
#print axioms roll_covariance
