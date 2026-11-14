-- Queues: in any system that keeps up, the long-run average number inside equals the arrival rate times the average stay (Little's law), and the cut equations of the one-till and many-till queues give the waits ρ/(μ − λ) and Erlang C, checked on the bakery's 55 customers an hour.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Filter Topology Finset

namespace Queues

/-! ## Little's law on one long run

Customers are numbered `0, 1, 2, …` in order of arrival. Customer `i` arrives at time `A i` and
leaves at time `D i ≥ A i`, so the stay is `W i = D i - A i`. The count of arrivals by time `T`
is `n(T) = #{i | A i ≤ T}`, and the number inside at time `t` is `N(t) = #{i | A i ≤ t < D i}`. -/

open MeasureTheory in
/-- Helper: the time an interval `[a, d)` spends inside `[0, T]`, when `0 ≤ a ≤ T`. -/
theorem integral_indicator_Ico_aux {a d T : ℝ} (ha : 0 ≤ a) (haT : a ≤ T) (had : a ≤ d) :
    ∫ t in (0 : ℝ)..T, (Set.Ico a d).indicator (fun _ => (1 : ℝ)) t = min d T - a := by
  rw [intervalIntegral.integral_of_le (ha.trans haT), integral_indicator_const _ measurableSet_Ico,
    smul_eq_mul, mul_one, Measure.real_def, Measure.restrict_apply measurableSet_Ico]
  have h1 : volume (Set.Ico a d ∩ Set.Ioc 0 T) = volume (Set.Ioc a d ∩ Set.Ioc 0 T) :=
    measure_congr (Ico_ae_eq_Ioc.inter (ae_eq_refl _))
  rw [h1, Set.Ioc_inter_Ioc, Real.volume_Ioc, max_eq_left ha,
    ENNReal.toReal_ofReal (by simp [had, haT])]

open MeasureTheory in
theorem intervalIntegrable_indicator_Ico_aux (a d T : ℝ) :
    IntervalIntegrable ((Set.Ico a d).indicator (fun _ => (1 : ℝ))) volume 0 T := by
  apply IntervalIntegrable.mono_fun (intervalIntegrable_const (c := (1:ℝ)))
  · exact (aestronglyMeasurable_const.indicator measurableSet_Ico)
  · refine Eventually.of_forall (fun t => ?_)
    by_cases h : t ∈ Set.Ico a d <;> simp [h]

#print axioms integral_indicator_Ico_aux
#print axioms intervalIntegrable_indicator_Ico_aux

/-- **Little's law, `L = λ W`** (the sample-path form of Stidham, 1974). Number customers in order
of arrival, starting with an empty system at time 0, and let customer `i` arrive at `A i` and
leave at `D i ≥ A i`. Suppose the count of arrivals by any time is a finite number, and the two
long-run averages exist and are finite: arrivals per unit time `n(T)/T → λ`, and the average stay
of the first `n` customers `(1/n) ∑ (D i - A i) → W`. Then the time-average number inside,
`(1/T) ∫₀ᵀ N(t) dt`, tends to `λ W`. Nothing is assumed about the arrival pattern, the service
times, the number of servers or the order of service. -/
theorem littles_law (A D : ℕ → ℝ) (lam W : ℝ)
    (hstart : ∀ i, 0 ≤ A i) (horder : Monotone A) (hleave : ∀ i, A i ≤ D i)
    (hfinite : ∀ T : ℝ, {i : ℕ | A i ≤ T}.Finite)
    (hlam : Tendsto (fun T : ℝ => (Nat.card {i : ℕ | A i ≤ T} : ℝ) / T) atTop (𝓝 lam))
    (hW : Tendsto (fun n : ℕ => (∑ i ∈ range n, (D i - A i)) / n) atTop (𝓝 W)) :
    Tendsto (fun T : ℝ => (∫ t in (0 : ℝ)..T, (Nat.card {i : ℕ | A i ≤ t ∧ t < D i} : ℝ)) / T)
      atTop (𝓝 (lam * W)) := by
  classical
  have hex : ∀ T : ℝ, ∃ i, T < A i := by
    intro T
    obtain ⟨i, hi⟩ := (hfinite T).exists_notMem
    exact ⟨i, lt_of_not_ge hi⟩
  obtain ⟨k, hk⟩ : ∃ k : ℝ → ℕ, ∀ T i, A i ≤ T ↔ i < k T := by
    refine ⟨fun T => Nat.find (hex T), fun T i => ⟨fun h => ?_, fun h => ?_⟩⟩
    · by_contra h'
      push Not at h'
      have h1 := Nat.find_spec (hex T)
      have h2 := horder h'
      linarith
    · exact not_lt.1 (Nat.find_min (hex T) h)
  have hkmono : ∀ T T', T ≤ T' → k T ≤ k T' := by
    intro T T' hTT
    by_contra h
    push Not at h
    have := (hk T' (k T')).1 (((hk T (k T')).2 h).trans hTT)
    exact lt_irrefl _ this
  have hcard : ∀ T, (Nat.card {i : ℕ | A i ≤ T} : ℝ) = k T := by
    intro T
    have : {i : ℕ | A i ≤ T} = ↑(range (k T)) := by ext i; simp [hk T i]
    rw [this, Nat.card_coe_set_eq, Set.ncard_coe_finset, card_range]
  have hN : ∀ T t, t ≤ T → (Nat.card {i : ℕ | A i ≤ t ∧ t < D i} : ℝ) =
      ∑ i ∈ range (k T), (Set.Ico (A i) (D i)).indicator (fun _ => (1 : ℝ)) t := by
    intro T t ht
    have : {i : ℕ | A i ≤ t ∧ t < D i} =
        ↑((range (k T)).filter (fun i => A i ≤ t ∧ t < D i)) := by
      ext i
      simp only [Set.mem_ofPred_eq, coe_filter, mem_range]
      constructor
      · rintro ⟨h1, h2⟩; exact ⟨(hk T i).1 (h1.trans ht), h1, h2⟩
      · rintro ⟨_, h⟩; exact h
    rw [this, Nat.card_coe_set_eq, Set.ncard_coe_finset, card_filter]
    push_cast
    refine sum_congr rfl (fun i _ => ?_)
    by_cases h : A i ≤ t ∧ t < D i <;> simp [h]
  have hint : ∀ T, 0 ≤ T → ∫ t in (0 : ℝ)..T, (Nat.card {i : ℕ | A i ≤ t ∧ t < D i} : ℝ) =
      ∑ i ∈ range (k T), (min (D i) T - A i) := by
    intro T hT
    rw [intervalIntegral.integral_congr (g := fun t => ∑ i ∈ range (k T),
      (Set.Ico (A i) (D i)).indicator (fun _ => (1 : ℝ)) t)]
    · rw [intervalIntegral.integral_finsetSum
        (fun i _ => intervalIntegrable_indicator_Ico_aux _ _ _)]
      exact sum_congr rfl (fun i hi =>
        integral_indicator_Ico_aux (hstart i) ((hk T i).2 (mem_range.1 hi)) (hleave i))
    · intro t ht
      rw [Set.uIcc_of_le hT] at ht
      exact hN T t ht.2
  -- the running total of stays
  obtain ⟨S, hS⟩ : ∃ S : ℕ → ℝ, S = fun n => ∑ i ∈ range n, (D i - A i) := ⟨_, rfl⟩
  have hW' : Tendsto (fun n : ℕ => S n / n) atTop (𝓝 W) := by subst hS; exact hW
  have hw0 : ∀ i, 0 ≤ D i - A i := fun i => sub_nonneg.2 (hleave i)
  have hS0 : S 0 = 0 := by simp [hS]
  have hSsucc : ∀ n, S (n + 1) = S n + (D n - A n) := by intro n; simp only [hS, sum_range_succ]
  have hSnn : ∀ n, 0 ≤ S n := fun n => by simp only [hS]; exact sum_nonneg (fun i _ => hw0 i)
  have hcancel : ∀ (n : ℕ) (x : ℝ), S n / n * (n / x) = S n / x := by
    intro n x
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; simp [hS0]
    · exact div_mul_div_cancel₀ (by positivity)
  have hktend : Tendsto k atTop atTop := by
    rw [tendsto_atTop]
    intro m
    filter_upwards [eventually_ge_atTop (A m)] with T hT
    exact ((hk T m).1 hT).le
  have hlam' : Tendsto (fun T : ℝ => (k T : ℝ) / T) atTop (𝓝 lam) := by
    have := hlam; simp only [hcard] at this; exact this
  have hlam0 : 0 ≤ lam := ge_of_tendsto hlam' (by
    filter_upwards [eventually_ge_atTop 0] with T hT; positivity)
  have hW0 : 0 ≤ W := ge_of_tendsto' hW' (fun n => div_nonneg (hSnn n) (Nat.cast_nonneg _))
  have hSk : Tendsto (fun T => S (k T) / k T) atTop (𝓝 W) := hW'.comp hktend
  have hu : Tendsto (fun T => S (k T) / T) atTop (𝓝 (W * lam)) :=
    (hSk.mul hlam').congr (fun T => hcancel _ _)
  have hl : ∀ c : ℝ, 0 < c → Tendsto (fun T => S (k (c * T)) / T) atTop (𝓝 (W * lam * c)) := by
    intro c hc0
    have hcT : Tendsto (fun T : ℝ => c * T) atTop atTop := tendsto_id.const_mul_atTop hc0
    have h1 := (((hSk.comp hcT).mul (hlam'.comp hcT))).mul_const c
    refine h1.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with T hT
    simp only [Function.comp_apply]
    rw [hcancel]
    field_simp
  -- each single stay is small next to the clock
  have hwrate : Tendsto (fun n : ℕ => (D n - A n) / ((n : ℝ) + 1)) atTop (𝓝 0) := by
    have h1 : Tendsto (fun n : ℕ => S (n + 1) / ((n + 1 : ℕ) : ℝ)) atTop (𝓝 W) :=
      (tendsto_add_atTop_iff_nat 1).2 hW'
    have h2 := hW'.mul (tendsto_natCast_div_add_atTop (1 : ℝ))
    have h3 := h1.sub h2
    rw [mul_one, sub_self] at h3
    refine h3.congr (fun n => ?_)
    rw [hcancel, hSsucc]
    push_cast
    ring
  have hsmall : ∀ ε : ℝ, 0 < ε → ∀ᶠ T in atTop, ∀ i < k T, D i - A i ≤ ε * T := by
    intro ε hε
    have hC : 0 < lam + 1 := by linarith
    have hε' : 0 < ε / (2 * (lam + 1)) := by positivity
    obtain ⟨N0, hN0⟩ := eventually_atTop.1 (hwrate.eventually (gt_mem_nhds hε'))
    filter_upwards [hlam'.eventually (gt_mem_nhds (lt_add_one lam)), eventually_gt_atTop 0,
      eventually_ge_atTop (2 * S N0 / ε)] with T hkT hT hTbig i hi
    have hkT' : (k T : ℝ) < (lam + 1) * T := (div_lt_iff₀ hT).1 hkT
    have hhalf : S N0 ≤ ε * T / 2 := by
      rw [div_le_iff₀ hε] at hTbig; linarith
    by_cases hiN : N0 ≤ i
    · have h1 : D i - A i < ε / (2 * (lam + 1)) * ((i : ℝ) + 1) :=
        (div_lt_iff₀ (by positivity)).1 (hN0 i hiN)
      have h2 : (i : ℝ) + 1 ≤ k T := by exact_mod_cast hi
      have h3 : ε / (2 * (lam + 1)) * ((i : ℝ) + 1) ≤ ε / (2 * (lam + 1)) * ((lam + 1) * T) :=
        mul_le_mul_of_nonneg_left (by linarith) hε'.le
      have h4 : ε / (2 * (lam + 1)) * ((lam + 1) * T) = ε * T / 2 := by field_simp
      nlinarith
    · push Not at hiN
      have : D i - A i ≤ S N0 := by
        simp only [hS]
        exact single_le_sum (fun j _ => hw0 j) (mem_range.2 hiN)
      nlinarith
  have hlower : ∀ c : ℝ, 0 < c → c < 1 → ∀ᶠ T in atTop,
      S (k (c * T)) / T ≤ (∫ t in (0 : ℝ)..T, (Nat.card {i : ℕ | A i ≤ t ∧ t < D i} : ℝ)) / T := by
    intro c hc0 hc1
    filter_upwards [hsmall (1 - c) (by linarith), eventually_gt_atTop 0] with T hsm hT
    rw [hint T hT.le]
    apply div_le_div_of_nonneg_right _ hT.le
    have hsub : range (k (c * T)) ⊆ range (k T) :=
      range_subset_range.2 (hkmono _ _ (by nlinarith))
    calc S (k (c * T)) = ∑ i ∈ range (k (c * T)), (min (D i) T - A i) := by
          simp only [hS]
          refine sum_congr rfl (fun i hi => ?_)
          have hA : A i ≤ c * T := (hk _ i).2 (mem_range.1 hi)
          have := hsm i (mem_range.1 (hsub hi))
          rw [min_eq_left (by nlinarith)]
      _ ≤ ∑ i ∈ range (k T), (min (D i) T - A i) :=
          sum_le_sum_of_subset_of_nonneg hsub (fun i hi _ => by
            have hA := (hk T i).2 (mem_range.1 hi)
            have := hleave i
            rw [sub_nonneg]
            exact le_min this hA)
  have hupper : ∀ᶠ T in atTop,
      (∫ t in (0 : ℝ)..T, (Nat.card {i : ℕ | A i ≤ t ∧ t < D i} : ℝ)) / T ≤ S (k T) / T := by
    filter_upwards [eventually_gt_atTop 0] with T hT
    rw [hint T hT.le]
    apply div_le_div_of_nonneg_right _ hT.le
    simp only [hS]
    exact sum_le_sum (fun i _ => by linarith [min_le_left (D i) T])
  rw [tendsto_order]
  refine ⟨fun a ha => ?_, fun b hb => ?_⟩
  · obtain ⟨c, hc0, hc1, hca⟩ : ∃ c : ℝ, 0 < c ∧ c < 1 ∧ a < W * lam * c := by
      by_cases h : a < 0
      · exact ⟨1 / 2, by norm_num, by norm_num, by nlinarith [mul_nonneg hW0 hlam0]⟩
      · push Not at h
        have hP : 0 < W * lam := by nlinarith
        have hq : 0 ≤ a / (W * lam) := div_nonneg h hP.le
        have hq1 : a / (W * lam) < 1 := (div_lt_one hP).2 (by linarith)
        refine ⟨(a / (W * lam) + 1) / 2, by linarith, by linarith, ?_⟩
        have hP' : W * lam ≠ 0 := hP.ne'
        have e : W * lam * (a / (W * lam)) = a := mul_div_cancel₀ a hP'
        have : W * lam * ((a / (W * lam) + 1) / 2) = (a + W * lam) / 2 := by
          calc W * lam * ((a / (W * lam) + 1) / 2)
              = (W * lam * (a / (W * lam)) + W * lam) / 2 := by ring
            _ = (a + W * lam) / 2 := by rw [e]
        rw [this]; linarith
    filter_upwards [(hl c hc0).eventually (lt_mem_nhds hca), hlower c hc0 hc1] with T h1 h2
    linarith
  · filter_upwards [hu.eventually (gt_mem_nhds (show W * lam < b by linarith)), hupper]
      with T h1 h2
    linarith

/-! ## One till, M/M/1

`π n` is the long-run share of time with `n` people in the shop. Cutting between `n` and `n + 1`,
upward crossings happen at the arrival rate `λ` and downward ones at the service rate `μ`:
`λ π n = μ π (n + 1)`. The load is `ρ = λ/μ`. -/

/-- **The M/M/1 wait: one service time times busy over idle.** With arrival rate `λ ≥ 0` below the
service rate `μ` (stability, `ρ = λ/μ < 1`), the shares of time that balance the cut equations
and add to 1 are `π n = (1 - ρ) ρⁿ`. The average number in the shop is `L = ρ/(1 - ρ)`, the
average number in line (not at the till) is `L_q = ρ²/(1 - ρ)`, and the wait in line
`W_q = L_q/λ` equals both `ρ/(μ - λ)` and the arrival's view `L/μ`. -/
theorem mm1_wait_is_busy_over_idle (lam mu : ℝ) (hlam : 0 ≤ lam) (hstable : lam < mu)
    (π : ℕ → ℝ) (hcut : ∀ n, lam * π n = mu * π (n + 1)) (hsum : ∑' n, π n = 1) :
    (∀ n, π n = (1 - lam / mu) * (lam / mu) ^ n) ∧
      ∑' n : ℕ, (n : ℝ) * π n = (lam / mu) / (1 - lam / mu) ∧
      ∑' n, ((n - 1 : ℕ) : ℝ) * π n = (lam / mu) ^ 2 / (1 - lam / mu) ∧
      (∑' n, ((n - 1 : ℕ) : ℝ) * π n) / lam = (lam / mu) / (mu - lam) ∧
      (∑' n, ((n - 1 : ℕ) : ℝ) * π n) / lam = (∑' n : ℕ, (n : ℝ) * π n) / mu := by
  have hmu : 0 < mu := lt_of_le_of_lt hlam hstable
  set ρ := lam / mu with hρ
  have hρ0 : 0 ≤ ρ := div_nonneg hlam hmu.le
  have hρ1 : ρ < 1 := (div_lt_one hmu).2 hstable
  have hnorm : ‖ρ‖ < 1 := by rw [Real.norm_eq_abs, abs_of_nonneg hρ0]; exact hρ1
  have hstep : ∀ n, π (n + 1) = ρ * π n := by
    intro n; rw [hρ, div_mul_eq_mul_div, eq_div_iff hmu.ne', hcut n]; ring
  have hgeom : ∀ n, π n = π 0 * ρ ^ n := by
    intro n; induction n with
    | zero => simp
    | succ n ih => rw [hstep, ih]; ring
  have h0 : π 0 = 1 - ρ := by
    have : ∑' n, π n = π 0 * (1 - ρ)⁻¹ := by
      rw [tsum_congr hgeom, tsum_mul_left, tsum_geometric_of_lt_one hρ0 hρ1]
    rw [hsum] at this
    have h1 : 1 - ρ ≠ 0 := by linarith
    field_simp at this; linarith
  have hπ : ∀ n, π n = (1 - ρ) * ρ ^ n := by intro n; rw [hgeom, h0]
  have hL : ∑' n : ℕ, (n : ℝ) * π n = ρ / (1 - ρ) := by
    simp_rw [hπ]
    have : (fun n : ℕ => (n : ℝ) * ((1 - ρ) * ρ ^ n)) = fun n : ℕ => (1 - ρ) * ((n : ℝ) * ρ ^ n) := by
      funext n; ring
    rw [this, tsum_mul_left, tsum_coe_mul_geometric_of_norm_lt_one hnorm]
    have h1 : 1 - ρ ≠ 0 := by linarith
    field_simp
  have hLq : ∑' n, ((n - 1 : ℕ) : ℝ) * π n = ρ ^ 2 / (1 - ρ) := by
    have hs : Summable (fun n : ℕ => (((n + 1) - 1 : ℕ) : ℝ) * π (n + 1)) := by
      have := (summable_pow_mul_geometric_of_norm_lt_one 1 hnorm).mul_left ((1 - ρ) * ρ)
      refine this.congr (fun n => ?_)
      simp only [Nat.add_sub_cancel, hπ, pow_one]; ring
    rw [tsum_eq_zero_add' hs]
    have : (fun n : ℕ => (((n + 1) - 1 : ℕ) : ℝ) * π (n + 1)) = fun n : ℕ => ρ * ((n : ℝ) * π n) := by
      funext n; simp only [Nat.add_sub_cancel, hstep]; ring
    rw [this, tsum_mul_left, hL]
    simp
    ring
  refine ⟨hπ, hL, hLq, ?_, ?_⟩
  · rw [hLq, hρ]
    rcases eq_or_lt_of_le hlam with h | h
    · subst h; simp
    · have h1 : mu - lam ≠ 0 := by linarith
      field_simp
  · rw [hLq, hL, hρ]
    rcases eq_or_lt_of_le hlam with h | h
    · subst h; simp
    · have h1 : mu - lam ≠ 0 := by linarith
      field_simp

/-! ## Many tills sharing one line, M/M/c -/

/-- The Erlang C formula: with offered load `a = λ/μ` and utilisation `ρ = a/c`,
`P_wait = (aᶜ/c! · 1/(1 - ρ)) / (∑_{k<c} aᵏ/k! + aᶜ/c! · 1/(1 - ρ))`. -/
noncomputable def erlangC (lam mu : ℝ) (c : ℕ) : ℝ :=
  ((lam / mu) ^ c / c.factorial * (1 / (1 - lam / mu / c))) /
    (∑ k ∈ range c, (lam / mu) ^ k / k.factorial +
      (lam / mu) ^ c / c.factorial * (1 / (1 - lam / mu / c)))

/-- **Erlang C and the M/M/c wait.** With `c` tills sharing one line and arrivals slower than all
tills together (`λ < c μ`, with `λ ≥ 0`), take the shares of time `π n` that balance the cut
equations `λ π n = min(n + 1, c) μ π (n + 1)` and add to 1. Then the chance that an arrival
finds every till busy, `P_wait = ∑_{n ≥ c} π n`, is the Erlang C formula; the average number in
line is `L_q = ∑ (n - c)⁺ π n = P_wait · ρ/(1 - ρ)`; and the wait in line is
`W_q = L_q/λ = P_wait/(c μ - λ)`. -/
theorem erlang_c_wait (lam mu : ℝ) (c : ℕ) (hlam : 0 ≤ lam) (hstable : lam < c * mu)
    (π : ℕ → ℝ) (hcut : ∀ n, lam * π n = ((min (n + 1) c : ℕ) : ℝ) * mu * π (n + 1))
    (hsum : ∑' n, π n = 1) :
    (∑' n, if c ≤ n then π n else 0) = erlangC lam mu c ∧
      ∑' n, ((n - c : ℕ) : ℝ) * π n =
        erlangC lam mu c * ((lam / mu / c) / (1 - lam / mu / c)) ∧
      (∑' n, ((n - c : ℕ) : ℝ) * π n) / lam = erlangC lam mu c / (c * mu - lam) := by
  have hc : 0 < c := by
    rcases Nat.eq_zero_or_pos c with h | h
    · subst h; simp at hstable; linarith
    · exact h
  have hcR : (0 : ℝ) < c := by exact_mod_cast hc
  have hmu : 0 < mu := by
    by_contra h; push Not at h; nlinarith
  set a := lam / mu with ha
  set ρ := a / c with hρ
  have ha0 : 0 ≤ a := div_nonneg hlam hmu.le
  have hρ0 : 0 ≤ ρ := div_nonneg ha0 hcR.le
  have hρ1 : ρ < 1 := by
    rw [hρ, ha, div_div, div_lt_one (by positivity)]; linarith
  have hnorm : ‖ρ‖ < 1 := by rw [Real.norm_eq_abs, abs_of_nonneg hρ0]; exact hρ1
  -- the first c + 1 shares
  have hlow : ∀ n, n ≤ c → π n = π 0 * (a ^ n / n.factorial) := by
    intro n; induction n with
    | zero => intro _; simp
    | succ n ih =>
      intro hn
      have hmin : min (n + 1) c = n + 1 := min_eq_left hn
      have h := hcut n
      rw [hmin, ih (by omega)] at h
      have hn1 : ((n + 1 : ℕ) : ℝ) ≠ 0 := by positivity
      rw [Nat.factorial_succ, Nat.cast_mul, pow_succ]
      rw [ha]
      field_simp
      field_simp at h
      push_cast at h ⊢
      linarith
  have hhigh : ∀ m, π (m + c) = π c * ρ ^ m := by
    intro m; induction m with
    | zero => simp
    | succ m ih =>
      have hmin : min (m + c + 1) c = c := min_eq_right (by omega)
      have h := hcut (m + c)
      rw [hmin, ih] at h
      have hcm : (c : ℝ) * mu ≠ 0 := by positivity
      have e : π (m + c + 1) = (lam * π c * ρ ^ m) / (c * mu) := by
        rw [eq_div_iff hcm]; linarith [h]
      rw [show m + 1 + c = m + c + 1 by ring, e, pow_succ, hρ, ha]
      field_simp
  have hsumm : Summable (fun m => π (m + c)) := by
    simp_rw [hhigh]; exact (summable_geometric_of_lt_one hρ0 hρ1).mul_left _
  have htail : ∑' m, π (m + c) = π c / (1 - ρ) := by
    rw [tsum_congr hhigh, tsum_mul_left, tsum_geometric_of_lt_one hρ0 hρ1, div_eq_mul_inv]
  have h1ρ : 1 - ρ ≠ 0 := by linarith
  set Z := ∑ k ∈ range c, a ^ k / k.factorial + a ^ c / c.factorial * (1 / (1 - ρ)) with hZ
  have hπZ : π 0 * Z = 1 := by
    rw [← hsum, ← hsumm.sum_add_tsum_nat_add', htail, hZ, mul_add, mul_sum,
      hlow c le_rfl]
    congr 1
    · exact sum_congr rfl (fun k hk => (hlow k (mem_range.1 hk).le).symm)
    · ring
  have hπc : π c / (1 - ρ) = erlangC lam mu c := by
    rw [erlangC, ← ha, ← hρ, ← hZ, hlow c le_rfl]
    have hZ0 : Z ≠ 0 := by rintro h; rw [h, mul_zero] at hπZ; exact zero_ne_one hπZ
    field_simp
    rw [mul_right_comm, hπZ, one_mul]
  have hP : (∑' n, if c ≤ n then π n else 0) = erlangC lam mu c := by
    have hs : Summable (fun m => (fun n => if c ≤ n then π n else 0) (m + c)) := by
      simpa using hsumm
    rw [← hs.sum_add_tsum_nat_add']
    rw [sum_eq_zero (fun k hk => by simp [not_le.2 (mem_range.1 hk)])]
    simp only [le_add_iff_nonneg_left, zero_le, ite_true, zero_add]
    rw [htail, hπc]
  have hLq : ∑' n, ((n - c : ℕ) : ℝ) * π n = erlangC lam mu c * (ρ / (1 - ρ)) := by
    have hs : Summable (fun m => (fun n => ((n - c : ℕ) : ℝ) * π n) (m + c)) := by
      simp only [Nat.add_sub_cancel, hhigh]
      have := (summable_pow_mul_geometric_of_norm_lt_one 1 hnorm).mul_left (π c)
      refine this.congr (fun n => ?_); simp; ring
    rw [← hs.sum_add_tsum_nat_add']
    rw [sum_eq_zero (fun k hk => by simp [Nat.sub_eq_zero_of_le (mem_range.1 hk).le])]
    simp only [Nat.add_sub_cancel, hhigh, zero_add]
    have : (fun m : ℕ => (m : ℝ) * (π c * ρ ^ m)) = fun m : ℕ => π c * ((m : ℝ) * ρ ^ m) := by
      funext m; ring
    rw [this, tsum_mul_left, tsum_coe_mul_geometric_of_norm_lt_one hnorm, ← hπc]
    field_simp
  refine ⟨hP, hLq, ?_⟩
  rw [hLq, hρ, ha]
  rcases eq_or_lt_of_le hlam with h | h
  · subst h
    have : erlangC 0 mu c = 0 := by simp [erlangC, zero_pow hc.ne']
    simp [this]
  · have h2 : (c : ℝ) * mu - lam ≠ 0 := by linarith
    have h3 : 1 - lam / mu / c ≠ 0 := by rw [← ha, ← hρ]; exact h1ρ
    field_simp

/-! ## The card's numbers: 55 customers an hour, one till serving 60 an hour

Rates are per hour; waits in minutes are hours times 60. -/

-- Utilisation 55/60 = 11/12; the till stands idle 5 minutes an hour; spare rate 5 an hour.
example : (55 : ℝ) / 60 = 11 / 12 ∧ 60 * (1 - (55 : ℝ) / 60) = 5 ∧ (60 : ℝ) - 55 = 5 := by norm_num
-- In the shop L = ρ/(1 - ρ) = 11; in line L_q = ρ²/(1 - ρ) = 11 - 11/12 = 121/12 (10.083).
example : ((55 : ℝ) / 60) / (1 - 55 / 60) = 11 := by norm_num
example : ((55 : ℝ) / 60) ^ 2 / (1 - 55 / 60) = 121 / 12 ∧ (11 : ℝ) - 55 / 60 = 121 / 12 := by norm_num
-- Time in shop W = L/λ = 11/55 hours = 12 minutes; time in line W_q = L_q/λ = 11 minutes.
example : 60 * ((11 : ℝ) / 55) = 12 := by norm_num
example : 60 * ((121 / 12 : ℝ) / 55) = 11 := by norm_num
-- W_q = ρ/(μ - λ) = 11 minutes, the same as the arrival's view L/μ: 11 people × 1 minute.
example : 60 * (((55 : ℝ) / 60) / (60 - 55)) = 11 ∧ 60 * ((11 : ℝ) / 60) = 11 := by norm_num
-- The chart: W_q in minutes at 30, 36, 42, 48, 51, 54, 55, 57, 58, 59 an hour is
-- 1, 3/2, 7/3, 4, 17/3, 9, 11, 19, 29, 59; fixed service halves each.
example : 60 * (((30 : ℝ) / 60) / (60 - 30)) = 1 ∧ 60 * (((36 : ℝ) / 60) / (60 - 36)) = 3 / 2 ∧
    60 * (((42 : ℝ) / 60) / (60 - 42)) = 7 / 3 ∧ 60 * (((48 : ℝ) / 60) / (60 - 48)) = 4 ∧
    60 * (((51 : ℝ) / 60) / (60 - 51)) = 17 / 3 ∧ 60 * (((54 : ℝ) / 60) / (60 - 54)) = 9 ∧
    60 * (((57 : ℝ) / 60) / (60 - 57)) = 19 ∧ 60 * (((58 : ℝ) / 60) / (60 - 58)) = 29 ∧
    60 * (((59 : ℝ) / 60) / (60 - 59)) = 59 := by norm_num
example : 60 * (((55 : ℝ) / 60) / (2 * (60 - 55))) = 11 / 2 := by norm_num
-- W_q at 50 and 56 an hour: 5 and 14 minutes.
example : 60 * (((50 : ℝ) / 60) / (60 - 50)) = 5 ∧ 60 * (((56 : ℝ) / 60) / (60 - 56)) = 14 := by
  norm_num
-- Busy over idle: 1 at half busy, 4 at 80 percent, 59 at 59 an hour.
example : ((1 : ℝ) / 2) / (1 - 1 / 2) = 1 ∧ ((4 : ℝ) / 5) / (1 - 4 / 5) = 4 ∧
    ((59 : ℝ) / 60) / (1 - 59 / 60) = 59 := by norm_num
-- Plugging 62 an hour into ρ/(1 - ρ) gives the nonsense L = -31.
example : ((62 : ℝ) / 60) / (1 - 62 / 60) = -31 := by norm_num
-- Erlang C: one till gives P_wait = ρ = 11/12; two tills at 55 give 121/420 (0.2881),
-- L_q = 1331/5460 (0.244) and W_q = 121/455 minutes, between 15 and 16 seconds.
example : erlangC 55 60 1 = 11 / 12 := by
  norm_num [erlangC, Finset.sum_range_succ, Nat.factorial]
example : erlangC 55 60 2 = 121 / 420 := by
  norm_num [erlangC, Finset.sum_range_succ, Nat.factorial]
example : (121 / 420 : ℝ) * ((55 / 60 / 2) / (1 - 55 / 60 / 2)) = 1331 / 5460 ∧
    60 * ((121 / 420 : ℝ) / (2 * 60 - 55)) = 121 / 455 ∧
    15 < 3600 * ((121 / 420 : ℝ) / (2 * 60 - 55)) ∧ 3600 * ((121 / 420 : ℝ) / (2 * 60 - 55)) < 16 := by
  norm_num
-- Two tills facing 110 an hour: P_wait = 121/138 (0.8768) and L_q = 1331/138 (9.645).
example : erlangC 110 60 2 = 121 / 138 := by
  norm_num [erlangC, Finset.sum_range_succ, Nat.factorial]
example : (121 / 138 : ℝ) * ((110 / 60 / 2) / (1 - 110 / 60 / 2)) = 1331 / 138 := by norm_num
-- Three tills at 55: P_wait = 1331/18156 (0.0733).
example : erlangC 55 60 3 = 1331 / 18156 := by
  norm_num [erlangC, Finset.sum_range_succ, Nat.factorial]
-- Two separate lines, 55/2 an hour each: W_q = 11/13 minutes (0.85).
example : 60 * (((55 / 2 : ℝ) / 60) / (60 - 55 / 2)) = 11 / 13 := by norm_num
-- A till 10 percent faster, 66 an hour: W_q = 50/11 minutes (4.55); 62 an hour then has L = 31/2.
example : 60 * (((55 : ℝ) / 66) / (66 - 55)) = 50 / 11 ∧ ((62 : ℝ) / 66) / (1 - 62 / 66) = 31 / 2 := by
  norm_num
-- 30 vans on a 5/2-hour loop: Little's law read backwards gives 12 departures an hour.
example : (30 : ℝ) / (5 / 2) = 12 := by norm_num

#print axioms littles_law
#print axioms mm1_wait_is_busy_over_idle
#print axioms erlang_c_wait

end Queues
