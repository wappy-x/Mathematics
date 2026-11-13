-- Asian Greeks and implied volatility: the fixings already in turn an Asian call into a smaller Asian on the fixings to come with a shifted strike, spreading the average around its centre strictly raises a call's payoff, and a continuous price that rises strictly with volatility between a floor and a ceiling gives each quote in the band exactly one implied volatility.
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Filter Topology Finset

/-- The fixings already in are a fixed amount. Take `k` fixings already in (prices `past`)
and `m ≥ 1` fixings still to come (prices `future`), `n = k + m` in all. Write `ā` for the
average of the fixings in, `A_rest` for the average of those to come, and `w = m / n` for
the open weight. Then the call on the whole average, `(A - K)⁺`, equals `w` times a call on
the open average with the shifted strike `K* = (K - (k/n) ā) / w`. -/
theorem asian_call_seasoned_payoff_split (k m : ℕ) (hm : 0 < m)
    (past : Fin k → ℝ) (future : Fin m → ℝ) (K : ℝ) :
    let n : ℝ := (k : ℝ) + m
    let A : ℝ := ((∑ i, past i) + ∑ j, future j) / n
    let abar : ℝ := (∑ i, past i) / k
    let Arest : ℝ := (∑ j, future j) / m
    let w : ℝ := (m : ℝ) / n
    let Kstar : ℝ := (K - (k : ℝ) / n * abar) / w
    A = (k : ℝ) / n * abar + w * Arest ∧
      max (A - K) 0 = w * max (Arest - Kstar) 0 := by
  intro n A abar Arest w Kstar
  set P := ∑ i, past i with hP
  set F := ∑ j, future j with hF
  have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
  have hn : (0 : ℝ) < n := by
    show (0 : ℝ) < (k : ℝ) + m
    positivity
  have hw : 0 < w := div_pos hmpos hn
  have hkab : (k : ℝ) / n * abar = P / n := by
    rcases Nat.eq_zero_or_pos k with hk | hk
    · subst hk
      have : P = 0 := by simp [hP]
      simp [abar, this]
    · have hkpos : (0 : ℝ) < k := by exact_mod_cast hk
      simp only [abar]
      field_simp
      rw [hP]
  have hwA : w * Arest = F / n := by
    simp only [w, Arest]
    field_simp
    rw [hF]
  have hA : A = (k : ℝ) / n * abar + w * Arest := by
    rw [hkab, hwA]
    simp only [A]
    ring
  refine ⟨hA, ?_⟩
  rw [mul_max_of_nonneg _ _ hw.le, mul_zero, mul_sub]
  have hwK : w * Kstar = K - (k : ℝ) / n * abar := by
    simp only [Kstar]
    field_simp
  rw [hwK, hA]
  ring_nf

/-- Spreading the average strictly raises the call. If an average `x` is replaced by a
spread of outcomes `y i` with probabilities `p i` centred on it (mean exactly `x`), the
expected call payoff is at least the payoff at the centre, and strictly larger when the
spread straddles the strike: some outcome with positive probability is below `K` and some
is above it. -/
theorem call_payoff_spread_strictly_raises {ι : Type*} (s : Finset ι) (p y : ι → ℝ)
    (x K : ℝ) (hp : ∀ i ∈ s, 0 ≤ p i) (hsum : ∑ i ∈ s, p i = 1)
    (hmean : ∑ i ∈ s, p i * y i = x)
    (hlo : ∃ i ∈ s, 0 < p i ∧ y i < K) (hhi : ∃ j ∈ s, 0 < p j ∧ K < y j) :
    max (x - K) 0 < ∑ i ∈ s, p i * max (y i - K) 0 := by
  have key : ∀ i ∈ s, p i * max (y i - K) 0 = p i * (y i - K) + p i * max (K - y i) 0 := by
    intro i _
    rw [← mul_add]
    congr 1
    rcases le_total (y i) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have hsplit : ∑ i ∈ s, p i * max (y i - K) 0
      = (x - K) + ∑ i ∈ s, p i * max (K - y i) 0 := by
    rw [Finset.sum_congr rfl key, Finset.sum_add_distrib]
    congr 1
    simp_rw [mul_sub]
    rw [Finset.sum_sub_distrib, hmean, ← Finset.sum_mul, hsum, one_mul]
  obtain ⟨i, hi, hpi, hyi⟩ := hlo
  obtain ⟨j, hj, hpj, hyj⟩ := hhi
  have hnn1 : ∀ l ∈ s, 0 ≤ p l * max (K - y l) 0 :=
    fun l hl => mul_nonneg (hp l hl) (le_max_right _ _)
  have hnn2 : ∀ l ∈ s, 0 ≤ p l * max (y l - K) 0 :=
    fun l hl => mul_nonneg (hp l hl) (le_max_right _ _)
  rcases le_total K x with hx | hx
  · rw [max_eq_left (by linarith), hsplit]
    have h1 : p i * max (K - y i) 0 ≤ ∑ l ∈ s, p l * max (K - y l) 0 :=
      Finset.single_le_sum hnn1 hi
    have h2 : 0 < p i * max (K - y i) 0 :=
      mul_pos hpi (lt_max_of_lt_left (by linarith))
    linarith
  · rw [max_eq_right (by linarith)]
    have h1 : p j * max (y j - K) 0 ≤ ∑ l ∈ s, p l * max (y l - K) 0 :=
      Finset.single_le_sum hnn2 hj
    have h2 : 0 < p j * max (y j - K) 0 :=
      mul_pos hpj (lt_max_of_lt_left (by linarith))
    linarith

/-- Exactly one implied volatility for each quote in the band. If the price `V σ` is
continuous for volatility `σ > 0`, rises strictly with volatility, tends to the floor `L`
as volatility falls to 0 and to the ceiling `U` as volatility grows without bound, then
every quote `Q` strictly between the floor and the ceiling is matched by exactly one
volatility `σ > 0`. -/
theorem implied_volatility_exists_unique (V : ℝ → ℝ) (L U Q : ℝ)
    (hcont : ContinuousOn V (Set.Ioi 0)) (hmono : StrictMonoOn V (Set.Ioi 0))
    (hfloor : Tendsto V (𝓝[>] 0) (𝓝 L)) (hceil : Tendsto V atTop (𝓝 U))
    (hQ : Q ∈ Set.Ioo L U) :
    ∃! σ : ℝ, 0 < σ ∧ V σ = Q := by
  obtain ⟨hLQ, hQU⟩ := hQ
  have ev1 : ∀ᶠ σ in 𝓝[>] (0 : ℝ), V σ < Q ∧ 0 < σ :=
    (hfloor.eventually (gt_mem_nhds hLQ)).and self_mem_nhdsWithin
  obtain ⟨a, ha, ha0⟩ := ev1.exists
  have ev2 : ∀ᶠ σ in (atTop : Filter ℝ), Q < V σ ∧ 0 < σ :=
    (hceil.eventually (lt_mem_nhds hQU)).and (eventually_gt_atTop 0)
  obtain ⟨b, hb, hb0⟩ := ev2.exists
  have hab : a ≤ b := by
    by_contra h
    rw [not_le] at h
    have := hmono hb0 ha0 h
    linarith
  have hsub : Set.Icc a b ⊆ Set.Ioi 0 := fun t ht => lt_of_lt_of_le ha0 ht.1
  obtain ⟨c, hc, hVc⟩ := intermediate_value_Icc hab (hcont.mono hsub) ⟨ha.le, hb.le⟩
  refine ⟨c, ⟨hsub hc, hVc⟩, ?_⟩
  rintro d ⟨hd0, hVd⟩
  exact hmono.injOn hd0 (hsub hc) (hVd.trans hVc.symm)

-- The share of log-variance kept by 52 weekly fixings: (n+1)(2n+1)/(6n²) = 53·105/(6·52²).
example : ((52 + 1) * (2 * 52 + 1) : ℚ) / (6 * 52 ^ 2) = 53 * 105 / (6 * 52 ^ 2) := by norm_num
example : ((52 + 1) * (2 * 52 + 1) : ℚ) / (6 * 52 ^ 2) = 1855 / 5408 := by norm_num

-- Seasoned example: 26 of 52 fixings in at $105. Fixed part 26/52 × 105 = 52.50,
-- open weight 26/52 = 1/2, and the open average must beat (100 - 52.50)/(1/2) = 95.
example : (26 / 52 : ℚ) * 105 = 105 / 2 := by norm_num
example : (26 / 52 : ℚ) = 1 / 2 := by norm_num
example : ((100 : ℚ) - 26 / 52 * 105) / (26 / 52) = 95 := by norm_num

-- Seasoned payoff chart: (52.50 + 0.5 x - 100)⁺ at x = 85, 90, ..., 115 is
-- 0, 0, 0, 2.50, 5, 7.50, 10, and it equals 0.5 (x - 95)⁺ at every point.
example : [85, 90, 95, 100, 105, 110, 115].map
    (fun x : ℚ => max (105 / 2 + x / 2 - 100) 0) = [0, 0, 0, 5 / 2, 5, 15 / 2, 10] := by
  norm_num
example : [85, 90, 95, 100, 105, 110, 115].map
    (fun x : ℚ => (1 / 2 : ℚ) * max (x - 95) 0) = [0, 0, 0, 5 / 2, 5, 15 / 2, 10] := by
  norm_num

#print axioms asian_call_seasoned_payoff_split
#print axioms call_payoff_spread_strictly_raises
#print axioms implied_volatility_exists_unique
