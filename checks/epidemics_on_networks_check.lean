-- Epidemics on a network: a large outbreak is possible exactly when T times the mean excess degree kappa = (<k^2> - <k>)/<k> is above one, kappa is the average of a friend's other friends, and random doses shrink kappa by 1 - f.
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Real.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Algebra.Ring.Real
import Mathlib.Tactic.LinearCombination

open Finset

/-- An upper bound for `(1 - s)^n` on `0 ≤ s ≤ 1`. -/
lemma epi_pow_le_quad (s : ℝ) (hs0 : 0 ≤ s) (hs1 : s ≤ 1) (n : ℕ) :
    (1 - s) ^ n ≤ 1 - (n : ℝ) * s + (n : ℝ) ^ 2 * s ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [pow_succ]
    push_cast
    have h1 : 0 ≤ 1 - s := by linarith
    have h2 := mul_le_mul_of_nonneg_right ih h1
    have h3 : 0 ≤ (n : ℝ) := Nat.cast_nonneg n
    nlinarith [mul_nonneg (mul_nonneg (sq_nonneg (n : ℝ)) (sq_nonneg s)) hs0,
      mul_nonneg (by linarith : (0 : ℝ) ≤ n + 1) (sq_nonneg s)]

/-- Strict Bernoulli inequality for exponents at least 2. -/
lemma epi_pow_gt_lin (y : ℝ) (hy0 : 0 < y) (hy1 : y ≤ 1) (n : ℕ) :
    1 - ((n : ℝ) + 2) * y < (1 - y) ^ (n + 2) := by
  induction n with
  | zero => norm_num; nlinarith
  | succ n ih =>
    rw [pow_succ]
    push_cast
    have h1 : 0 ≤ 1 - y := by linarith
    have h2 := mul_le_mul_of_nonneg_right ih.le h1
    have h3 : 0 ≤ (n : ℝ) := Nat.cast_nonneg n
    nlinarith [mul_pos (by linarith : (0 : ℝ) < n + 2) (mul_pos hy0 hy0)]

/-- Weak Bernoulli inequality in the form used below. -/
lemma epi_pow_ge_lin (y : ℝ) (hy0 : 0 ≤ y) (hy1 : y ≤ 1) (n : ℕ) :
    1 - (n : ℝ) * y ≤ (1 - y) ^ n := by
  have := one_add_mul_le_pow (a := -y) (by linarith) n
  simpa [sub_eq_add_neg] using this

/-- `Σ k p_k (k - 1) = m₂ - m₁`, with `k - 1` taken in `ℕ`. -/
lemma epi_sum_pred (K : ℕ) (p : ℕ → ℝ) :
    ∑ k ∈ range (K + 1), (k : ℝ) * p k * ((k - 1 : ℕ) : ℝ) =
      ∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k - ∑ k ∈ range (K + 1), (k : ℝ) * p k := by
  rw [← sum_sub_distrib]
  refine sum_congr rfl fun k _ => ?_
  rcases k with _ | k
  · simp
  · simp only [Nat.add_sub_cancel]
    push_cast
    ring

/-- The binomial weights sum to one. -/
lemma epi_binom_m0 (q f : ℝ) (h : q + f = 1) (n : ℕ) :
    ∑ j ∈ range (n + 1), ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) = 1 := by
  have := add_pow q f n
  rw [h, one_pow] at this
  rw [this]
  exact sum_congr rfl fun j _ => by ring

/-- Shifting a binomial sum weighted by `j`. -/
lemma epi_binom_shift (q f : ℝ) (a : ℕ → ℝ) (n : ℕ) :
    ∑ j ∈ range (n + 2), (j : ℝ) * a j * (((n + 1).choose j : ℝ) * q ^ j * f ^ (n + 1 - j)) =
      ((n : ℝ) + 1) * q * ∑ j ∈ range (n + 1), a (j + 1) * ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) := by
  rw [sum_range_succ']
  simp only [Nat.cast_zero, zero_mul, add_zero]
  rw [mul_sum]
  refine sum_congr rfl fun j _ => ?_
  have hc := congrArg (Nat.cast (R := ℝ)) (Nat.add_one_mul_choose_eq n j)
  push_cast at hc
  rw [show n + 1 - (j + 1) = n - j by omega, pow_succ]
  push_cast
  linear_combination (-(a (j + 1) * q ^ j * q * f ^ (n - j))) * hc

lemma epi_binom_m1 (q f : ℝ) (h : q + f = 1) (n : ℕ) :
    ∑ j ∈ range (n + 1), (j : ℝ) * ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) = (n : ℝ) * q := by
  rcases n with _ | n
  · simp
  · have := epi_binom_shift q f (fun _ => 1) n
    simp only [mul_one, one_mul] at this
    rw [this, epi_binom_m0 q f h n]
    push_cast; ring

lemma epi_binom_m2 (q f : ℝ) (h : q + f = 1) (n : ℕ) :
    ∑ j ∈ range (n + 1), (j : ℝ) ^ 2 * ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) =
      (n : ℝ) * q + (n : ℝ) * ((n : ℝ) - 1) * q ^ 2 := by
  rcases n with _ | n
  · simp
  · have := epi_binom_shift q f (fun j => (j : ℝ)) n
    have e : ∑ j ∈ range (n + 1 + 1), (j : ℝ) ^ 2 * (((n + 1).choose j : ℝ) * q ^ j * f ^ (n + 1 - j))
        = ∑ j ∈ range (n + 2), (j : ℝ) * (j : ℝ) * (((n + 1).choose j : ℝ) * q ^ j * f ^ (n + 1 - j)) :=
      sum_congr rfl fun j _ => by ring
    rw [e, this]
    have e2 : ∑ j ∈ range (n + 1), ((j + 1 : ℕ) : ℝ) * ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) =
        ∑ j ∈ range (n + 1), (j : ℝ) * ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) +
        ∑ j ∈ range (n + 1), ((n.choose j : ℝ) * q ^ j * f ^ (n - j)) := by
      rw [← sum_add_distrib]
      exact sum_congr rfl fun j _ => by push_cast; ring
    rw [e2, epi_binom_m1 q f h n, epi_binom_m0 q f h n]
    push_cast; ring

/-- Binomial sums over a longer range: the extra terms vanish. -/
lemma epi_binom_extend (q f : ℝ) (g : ℕ → ℝ) (k K : ℕ) (hk : k ≤ K) :
    ∑ j ∈ range (K + 1), g j * ((k.choose j : ℝ) * q ^ j * f ^ (k - j)) =
      ∑ j ∈ range (k + 1), g j * ((k.choose j : ℝ) * q ^ j * f ^ (k - j)) := by
  symm
  apply sum_subset
  · intro j hj
    simp only [mem_range] at hj ⊢
    omega
  · intro j _ hj'
    simp only [mem_range, not_lt] at hj'
    rw [Nat.choose_eq_zero_of_lt (by omega)]
    simp

/-- Summing a function of the far end of each dart. -/
lemma epi_sum_dart_snd {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (g : V → ℝ) :
    ∑ d : G.Dart, g d.snd = ∑ v, (G.degree v : ℝ) * g v := by
  have e1 : ∑ d : G.Dart, g d.snd = ∑ d : G.Dart, g d.fst :=
    Fintype.sum_equiv (SimpleGraph.Dart.symm_involutive.toPerm _) _ _ (fun d => rfl)
  rw [e1, ← Finset.sum_fiberwise Finset.univ (fun d : G.Dart => d.fst) (fun d => g d.fst)]
  refine sum_congr rfl fun v _ => ?_
  rw [sum_congr rfl (g := fun _ => g v) (fun d hd => by rw [(mem_filter.1 hd).2]), sum_const,
    nsmul_eq_mul, G.dart_fst_fiber_card_eq_degree v]

#print axioms epi_pow_le_quad
#print axioms epi_pow_gt_lin
#print axioms epi_pow_ge_lin
#print axioms epi_sum_pred
#print axioms epi_binom_m0
#print axioms epi_binom_shift
#print axioms epi_binom_m1
#print axioms epi_binom_m2
#print axioms epi_binom_extend
#print axioms epi_sum_dart_snd

/-- The threshold. Take a degree distribution `p k` (the share of people with `k` friends,
`k = 0 … K`) with mean `⟨k⟩ > 0`, its mean excess degree `κ = (⟨k²⟩ - ⟨k⟩)/⟨k⟩`, and a
transmissibility `T` between 0 and 1. Let `h u = G₁(1 - T + T u)`, where
`G₁ x = (1/⟨k⟩) Σ k p_k x^(k-1)`, and `G₀ x = Σ p_k x^k`.
If `T κ > 1`, the equation `u = h u` has a root `u` below 1, and the share ill
`z = 1 - G₀(1 - T + T u)` is positive: a large outbreak is possible.
If `T κ ≤ 1`, the only root in 0 to 1 is `u = 1` (so `z = 0`: no large outbreak). This second
part needs `h 0 > 0`, which the card's argument uses: `T < 1` or some people have exactly one
friend. The one case it rules out is `T = 1` with every person who has friends having exactly 2;
there `h u = u` for every `u`. -/
theorem large_outbreak_iff_T_kappa_above_one (K : ℕ) (p : ℕ → ℝ) (T : ℝ)
    (hp : ∀ k, 0 ≤ p k) (hsum : ∑ k ∈ range (K + 1), p k = 1)
    (hmean : 0 < ∑ k ∈ range (K + 1), (k : ℝ) * p k)
    (hT0 : 0 ≤ T) (hT1 : T ≤ 1) :
    let m1 := ∑ k ∈ range (K + 1), (k : ℝ) * p k
    let m2 := ∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k
    let κ := (m2 - m1) / m1
    let G₀ := fun x : ℝ => ∑ k ∈ range (K + 1), p k * x ^ k
    let G₁ := fun x : ℝ => (1 / m1) * ∑ k ∈ range (K + 1), (k : ℝ) * p k * x ^ (k - 1)
    let h := fun u : ℝ => G₁ (1 - T + T * u)
    (1 < T * κ → ∃ u ∈ Set.Ico (0 : ℝ) 1, h u = u ∧ 0 < 1 - G₀ (1 - T + T * u)) ∧
    (T * κ ≤ 1 → (T < 1 ∨ 0 < p 1) → ∀ u ∈ Set.Icc (0 : ℝ) 1, h u = u → u = 1) := by
  intro m1 m2 κ G₀ G₁ h
  have hm1 : 0 < m1 := hmean
  have hsub : ∑ k ∈ range (K + 1), (k : ℝ) * p k * ((k - 1 : ℕ) : ℝ) = m2 - m1 := epi_sum_pred K p
  have hκdef : κ = (m2 - m1) / m1 := rfl
  have hG₁ : ∀ x, m1 * G₁ x = ∑ k ∈ range (K + 1), (k : ℝ) * p k * x ^ (k - 1) := by
    intro x
    show m1 * ((1 / m1) * _) = _
    rw [← mul_assoc, mul_one_div_cancel hm1.ne', one_mul]
  have hterm_nn : ∀ k : ℕ, 0 ≤ (k : ℝ) * p k := fun k => mul_nonneg (Nat.cast_nonneg k) (hp k)
  constructor
  · intro hTk
    have hT : 0 < T := by
      rcases hT0.lt_or_eq with hT | hT
      · exact hT
      · rw [← hT, zero_mul] at hTk; linarith
    have hδ : m1 < T * (m2 - m1) := by
      rw [hκdef, mul_div_assoc', lt_div_iff₀ hm1, one_mul] at hTk
      exact hTk
    obtain ⟨B, hBdef⟩ : ∃ B, B = ∑ k ∈ range (K + 1), (k : ℝ) * p k * ((k - 1 : ℕ) : ℝ) ^ 2 :=
      ⟨_, rfl⟩
    have hB : 0 ≤ B := by
      rw [hBdef]; exact sum_nonneg fun k _ => mul_nonneg (hterm_nn k) (sq_nonneg _)
    have hup : ∀ s, 0 ≤ s → s ≤ 1 → m1 * G₁ (1 - s) ≤ m1 - s * (m2 - m1) + s ^ 2 * B := by
      intro s hs0 hs1
      rw [hG₁]
      calc ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - s) ^ (k - 1)
          ≤ ∑ k ∈ range (K + 1), (k : ℝ) * p k *
              (1 - ((k - 1 : ℕ) : ℝ) * s + ((k - 1 : ℕ) : ℝ) ^ 2 * s ^ 2) :=
            sum_le_sum fun k _ =>
              mul_le_mul_of_nonneg_left (epi_pow_le_quad s hs0 hs1 _) (hterm_nn k)
        _ = m1 - s * (m2 - m1) + s ^ 2 * B := by
            rw [← hsub, hBdef, show m1 = ∑ k ∈ range (K + 1), (k : ℝ) * p k from rfl,
              mul_sum, mul_sum, ← sum_sub_distrib, ← sum_add_distrib]
            exact sum_congr rfl fun k _ => by ring
    obtain ⟨δ, hδdef⟩ : ∃ δ, δ = T * (m2 - m1) - m1 := ⟨_, rfl⟩
    have hδpos : 0 < δ := by rw [hδdef]; linarith
    obtain ⟨D, hDdef⟩ : ∃ D, D = T ^ 2 * B := ⟨_, rfl⟩
    have hD : 0 ≤ D := by rw [hDdef]; positivity
    obtain ⟨ε, hεdef⟩ : ∃ ε, ε = δ / (δ + D) := ⟨_, rfl⟩
    have hεpos : 0 < ε := by rw [hεdef]; exact div_pos hδpos (by linarith)
    have hε1 : ε ≤ 1 := by rw [hεdef, div_le_one (by linarith)]; linarith
    have hεD : ε * D < δ := by
      rw [hεdef, div_mul_eq_mul_div, div_lt_iff₀ (by linarith)]
      nlinarith
    have hneg : h (1 - ε) < 1 - ε := by
      have hs0 : 0 ≤ T * ε := by positivity
      have hs1 : T * ε ≤ 1 := by nlinarith
      have hx : 1 - T + T * (1 - ε) = 1 - T * ε := by ring
      have h1 := hup (T * ε) hs0 hs1
      have h2 : m1 * h (1 - ε) = m1 * G₁ (1 - T * ε) := by
        show m1 * G₁ (1 - T + T * (1 - ε)) = _
        rw [hx]
      have h3 : m1 * h (1 - ε) < m1 * (1 - ε) := by
        rw [h2]
        have h4 : 0 < ε * (δ - ε * D) := mul_pos hεpos (by linarith)
        calc m1 * G₁ (1 - T * ε) ≤ m1 - T * ε * (m2 - m1) + (T * ε) ^ 2 * B := h1
          _ = m1 * (1 - ε) - ε * (δ - ε * D) := by rw [hδdef, hDdef]; ring
          _ < m1 * (1 - ε) := by linarith
      exact lt_of_mul_lt_mul_left h3 hm1.le
    have hcont : Continuous h := by
      show Continuous fun u : ℝ =>
        (1 / m1) * ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - T + T * u) ^ (k - 1)
      fun_prop
    have h0 : 0 ≤ h 0 := by
      show 0 ≤ (1 / m1) * ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - T + T * 0) ^ (k - 1)
      exact mul_nonneg (one_div_pos.mpr hm1).le
        (sum_nonneg fun k _ => mul_nonneg (hterm_nn k) (pow_nonneg (by linarith) _))
    have hu0 : (0 : ℝ) ≤ 1 - ε := by linarith
    obtain ⟨u, ⟨hu0', hu1'⟩, hu⟩ : (0 : ℝ) ∈ (fun u => h u - u) '' Set.Icc 0 (1 - ε) :=
      intermediate_value_Icc' hu0 ((hcont.sub continuous_id).continuousOn)
        ⟨show h (1 - ε) - (1 - ε) ≤ 0 by linarith, show 0 ≤ h 0 - 0 by linarith⟩
    simp only at hu
    refine ⟨u, ⟨hu0', by linarith⟩, by linarith, ?_⟩
    have hx0 : 0 ≤ 1 - T + T * u := by nlinarith [mul_nonneg hT0 hu0']
    have hx1 : 1 - T + T * u < 1 := by
      nlinarith [mul_lt_mul_of_pos_left (show u < 1 by linarith) hT]
    obtain ⟨k0, hk0, hk0pos⟩ : ∃ k ∈ range (K + 1), 0 < (k : ℝ) * p k := by
      by_contra hcon
      simp only [not_exists, not_and, not_lt] at hcon
      have := sum_nonpos hcon
      linarith
    have hk0ne : k0 ≠ 0 := by rintro rfl; simp at hk0pos
    have hpk0 : 0 < p k0 := by
      rcases (hp k0).lt_or_eq with h' | h'
      · exact h'
      · rw [← h', mul_zero] at hk0pos; exact absurd hk0pos (lt_irrefl 0)
    have hlt : G₀ (1 - T + T * u) < 1 := by
      show ∑ k ∈ range (K + 1), p k * (1 - T + T * u) ^ k < 1
      refine (sum_lt_sum (f := fun k => p k * (1 - T + T * u) ^ k) (g := p) (fun k _ => mul_le_of_le_one_right (hp k) (pow_le_one₀ hx0 hx1.le))
        ⟨k0, hk0, mul_lt_of_lt_one_right hpk0 (pow_lt_one₀ hx0 hx1 hk0ne)⟩).trans_eq hsum
    linarith
  · intro hTk hcase u hu hfix
    by_contra hne
    have hu1 : u < 1 := lt_of_le_of_ne hu.2 hne
    have hδ : T * (m2 - m1) ≤ m1 := by
      rw [hκdef, mul_div_assoc', div_le_iff₀ hm1, one_mul] at hTk
      exact hTk
    obtain ⟨y, hy⟩ : ∃ y, y = T * (1 - u) := ⟨_, rfl⟩
    have hy0 : 0 ≤ y := by rw [hy]; exact mul_nonneg hT0 (by linarith)
    have hy1 : y ≤ 1 := by rw [hy]; nlinarith [hu.1, mul_nonneg hT0 hu.1]
    have hx : 1 - T + T * u = 1 - y := by rw [hy]; ring
    have hS : ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - y) ^ (k - 1) = m1 * u := by
      rw [← hG₁, ← hx]
      show m1 * h u = m1 * u
      rw [hfix]
    have hDnn : ∀ k ∈ range (K + 1),
        0 ≤ (k : ℝ) * p k * ((1 - y) ^ (k - 1) - (1 - ((k - 1 : ℕ) : ℝ) * y)) :=
      fun k _ => mul_nonneg (hterm_nn k) (by linarith [epi_pow_ge_lin y hy0 hy1 (k - 1)])
    have hDsum : ∑ k ∈ range (K + 1),
        (k : ℝ) * p k * ((1 - y) ^ (k - 1) - (1 - ((k - 1 : ℕ) : ℝ) * y)) =
        (1 - u) * (T * (m2 - m1) - m1) := by
      have : ∑ k ∈ range (K + 1),
          (k : ℝ) * p k * ((1 - y) ^ (k - 1) - (1 - ((k - 1 : ℕ) : ℝ) * y)) =
          ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - y) ^ (k - 1) -
            ∑ k ∈ range (K + 1), (k : ℝ) * p k +
            y * ∑ k ∈ range (K + 1), (k : ℝ) * p k * ((k - 1 : ℕ) : ℝ) := by
        rw [mul_sum, ← sum_sub_distrib, ← sum_add_distrib]
        exact sum_congr rfl fun k _ => by ring
      rw [this, hS, hsub, hy]
      show m1 * u - m1 + T * (1 - u) * (m2 - m1) = _
      ring
    have hsumnn := sum_nonneg hDnn
    have heq : T * (m2 - m1) = m1 := by
      rw [hDsum] at hsumnn
      by_contra hne'
      have hlt : T * (m2 - m1) - m1 < 0 := by
        rcases lt_or_eq_of_le hδ with h' | h'
        · linarith
        · exact absurd h' hne'
      nlinarith [mul_pos (sub_pos.2 hu1) (neg_pos.2 hlt)]
    have hsum0 : ∑ k ∈ range (K + 1),
        (k : ℝ) * p k * ((1 - y) ^ (k - 1) - (1 - ((k - 1 : ℕ) : ℝ) * y)) = 0 := by
      rw [hDsum, heq, sub_self, mul_zero]
    have hT : 0 < T := by
      rcases hT0.lt_or_eq with hT | hT
      · exact hT
      · rw [← hT, zero_mul] at heq; linarith
    have hypos : 0 < y := by rw [hy]; exact mul_pos hT (by linarith)
    have hzero := (sum_eq_zero_iff_of_nonneg hDnn).mp hsum0
    have hbig : ∀ k ∈ range (K + 1), 3 ≤ k → p k = 0 := by
      intro k hk hk3
      have h1 := hzero k hk
      obtain ⟨n, rfl⟩ : ∃ n, k = n + 3 := ⟨k - 3, by omega⟩
      have hpos : 0 < (1 - y) ^ (n + 3 - 1) - (1 - ((n + 3 - 1 : ℕ) : ℝ) * y) := by
        rw [show n + 3 - 1 = n + 2 by omega]
        have := epi_pow_gt_lin y hypos hy1 n
        push_cast
        linarith
      rcases mul_eq_zero.mp h1 with h2 | h2
      · rcases mul_eq_zero.mp h2 with h3 | h3
        · exact absurd h3 (by positivity)
        · exact h3
      · linarith
    have hlin : ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - T * ((k - 1 : ℕ) : ℝ)) = 0 := by
      have : ∑ k ∈ range (K + 1), (k : ℝ) * p k * (1 - T * ((k - 1 : ℕ) : ℝ)) =
          ∑ k ∈ range (K + 1), (k : ℝ) * p k -
            T * ∑ k ∈ range (K + 1), (k : ℝ) * p k * ((k - 1 : ℕ) : ℝ) := by
        rw [mul_sum, ← sum_sub_distrib]
        exact sum_congr rfl fun k _ => by ring
      rw [this, hsub]
      show m1 - T * (m2 - m1) = 0
      linarith
    have hlin_nn : ∀ k ∈ range (K + 1), 0 ≤ (k : ℝ) * p k * (1 - T * ((k - 1 : ℕ) : ℝ)) := by
      intro k hk
      by_cases hk3 : 3 ≤ k
      · rw [hbig k hk hk3]; simp
      · have hc : ((k - 1 : ℕ) : ℝ) ≤ 1 := by exact_mod_cast (by omega : k - 1 ≤ 1)
        apply mul_nonneg (hterm_nn k)
        nlinarith [mul_le_mul_of_nonneg_left hc hT0]
    have hzero2 := (sum_eq_zero_iff_of_nonneg hlin_nn).mp hlin
    rcases hcase with hT1' | hp1
    · have hall : ∀ k ∈ range (K + 1), (k : ℝ) * p k = 0 := by
        intro k hk
        by_cases hk3 : 3 ≤ k
        · rw [hbig k hk hk3, mul_zero]
        · have hc : ((k - 1 : ℕ) : ℝ) ≤ 1 := by exact_mod_cast (by omega : k - 1 ≤ 1)
          have hpos : 0 < 1 - T * ((k - 1 : ℕ) : ℝ) := by
            nlinarith [mul_le_mul_of_nonneg_left hc hT0]
          rcases mul_eq_zero.mp (hzero2 k hk) with h1 | h1
          · exact h1
          · linarith
      have : m1 = 0 := sum_eq_zero hall
      linarith
    · rcases Nat.eq_zero_or_pos K with hK | hK
      · subst hK
        have : m1 = 0 := by
          show ∑ k ∈ range (0 + 1), (k : ℝ) * p k = 0
          simp
        linarith
      · have h1 := hzero2 1 (by simp; omega)
        simp at h1
        linarith

/-- The friendship paradox as a number. On any finite friendship network, walk along every
friendship from both ends and count the far person's other friends: the average equals
`κ = (⟨k²⟩ - ⟨k⟩)/⟨k⟩`, built from the mean degree and the mean squared degree. -/
theorem edge_walk_average_eq_mean_excess_degree {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    let n : ℝ := Fintype.card V
    let m1 := (∑ v, (G.degree v : ℝ)) / n
    let m2 := (∑ v, (G.degree v : ℝ) ^ 2) / n
    (∑ d : G.Dart, ((G.degree d.snd : ℝ) - 1)) / Fintype.card G.Dart = (m2 - m1) / m1 := by
  intro n m1 m2
  have hA : ∑ d : G.Dart, ((G.degree d.snd : ℝ) - 1) =
      ∑ v, (G.degree v : ℝ) ^ 2 - ∑ v, (G.degree v : ℝ) := by
    rw [epi_sum_dart_snd G (fun v => (G.degree v : ℝ) - 1), ← sum_sub_distrib]
    exact sum_congr rfl fun v _ => by ring
  have hB : (Fintype.card G.Dart : ℝ) = ∑ v, (G.degree v : ℝ) := by
    rw [G.dart_card_eq_sum_degrees]; push_cast; rfl
  rw [hA, hB]
  rcases eq_or_ne n 0 with hn | hn
  · have h0 : Fintype.card V = 0 := Nat.cast_eq_zero.mp hn
    have : IsEmpty V := Fintype.card_eq_zero_iff.mp h0
    simp [m1, m2]
  · simp only [m1, m2]
    rw [← sub_div, div_div_div_cancel_right₀ hn]

/-- Random doses. Vaccinate a share `f` at random: a person with `k` friends keeps `j` of them
with the binomial chance `C(k, j) (1-f)^j f^(k-j)`. The new degree distribution `p'` has mean
excess degree exactly `(1 - f)` times the old one. -/
theorem random_doses_shrink_kappa (K : ℕ) (p : ℕ → ℝ) (f : ℝ)
    (hp : ∀ k, 0 ≤ p k) (hsum : ∑ k ∈ range (K + 1), p k = 1)
    (hf0 : 0 ≤ f) (hf1 : f ≤ 1) :
    let p' := fun j : ℕ => ∑ k ∈ range (K + 1),
      p k * (k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j)
    let κ := fun r : ℕ → ℝ =>
      ((∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * r k) - ∑ k ∈ range (K + 1), (k : ℝ) * r k) /
        ∑ k ∈ range (K + 1), (k : ℝ) * r k
    κ p' = (1 - f) * κ p := by
  intro p' κ
  have hqf : (1 - f) + f = 1 := by ring
  have e1 : ∑ j ∈ range (K + 1), (j : ℝ) * p' j =
      (1 - f) * ∑ k ∈ range (K + 1), (k : ℝ) * p k := by
    simp only [p', mul_sum]
    rw [sum_comm]
    refine sum_congr rfl fun k hk => ?_
    have hkK : k ≤ K := by simp only [mem_range] at hk; omega
    have h1 : ∑ j ∈ range (K + 1), (j : ℝ) * ((k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j)) =
        (k : ℝ) * (1 - f) :=
      (epi_binom_extend (1 - f) f (fun j => (j : ℝ)) k K hkK).trans (epi_binom_m1 (1 - f) f hqf k)
    calc ∑ j ∈ range (K + 1), (j : ℝ) * (p k * (k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j))
        = p k * ∑ j ∈ range (K + 1), (j : ℝ) * ((k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j)) := by
          rw [mul_sum]; exact sum_congr rfl fun j _ => by ring
      _ = (1 - f) * ((k : ℝ) * p k) := by rw [h1]; ring
  have e2 : ∑ j ∈ range (K + 1), (j : ℝ) ^ 2 * p' j =
      ∑ k ∈ range (K + 1), p k * ((k : ℝ) * (1 - f) + (k : ℝ) * ((k : ℝ) - 1) * (1 - f) ^ 2) := by
    simp only [p', mul_sum]
    rw [sum_comm]
    refine sum_congr rfl fun k hk => ?_
    have hkK : k ≤ K := by simp only [mem_range] at hk; omega
    have h2 : ∑ j ∈ range (K + 1), (j : ℝ) ^ 2 * ((k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j)) =
        (k : ℝ) * (1 - f) + (k : ℝ) * ((k : ℝ) - 1) * (1 - f) ^ 2 :=
      (epi_binom_extend (1 - f) f (fun j => (j : ℝ) ^ 2) k K hkK).trans
        (epi_binom_m2 (1 - f) f hqf k)
    calc ∑ j ∈ range (K + 1), (j : ℝ) ^ 2 * (p k * (k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j))
        = p k * ∑ j ∈ range (K + 1),
            (j : ℝ) ^ 2 * ((k.choose j : ℝ) * (1 - f) ^ j * f ^ (k - j)) := by
          rw [mul_sum]; exact sum_congr rfl fun j _ => by ring
      _ = _ := by rw [h2]
  have e3 : ∑ k ∈ range (K + 1), p k * ((k : ℝ) * (1 - f) + (k : ℝ) * ((k : ℝ) - 1) * (1 - f) ^ 2) =
      (1 - f) * ∑ k ∈ range (K + 1), (k : ℝ) * p k + (1 - f) ^ 2 *
        (∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k - ∑ k ∈ range (K + 1), (k : ℝ) * p k) := by
    rw [← sum_sub_distrib, mul_sum, mul_sum, ← sum_add_distrib]
    exact sum_congr rfl fun k _ => by ring
  show (∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p' k - ∑ k ∈ range (K + 1), (k : ℝ) * p' k) /
      ∑ k ∈ range (K + 1), (k : ℝ) * p' k =
    (1 - f) * ((∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k - ∑ k ∈ range (K + 1), (k : ℝ) * p k) /
      ∑ k ∈ range (K + 1), (k : ℝ) * p k)
  rw [e1, e2, e3]
  generalize ∑ k ∈ range (K + 1), (k : ℝ) * p k = A
  generalize ∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k = B
  rcases eq_or_ne (1 - f) 0 with hq | hq
  · rw [hq]; simp
  rcases eq_or_ne A 0 with hA | hA
  · rw [hA]; simp
  field_simp
  ring

-- 17,134 friendships have 34,268 ends, two each.
example : 2 * 17134 = 34268 := by norm_num

-- The mean number of friends: 34,268 ends over 5,000 people.
example : (34268 : ℚ) / 5000 = 8567 / 1250 := by norm_num

-- 50 doses are 1% of 5,000 people, and 4,950 are left.
example : 5000 / 100 = 50 ∧ 5000 - 50 = 4950 := by decide

-- The ring: everyone has 6 friends, so <k> = 6, <k^2> = 36 and kappa = (36 - 6)/6 = 5.
example : ((36 : ℚ) - 6) / 6 = 5 := by norm_num

-- On the ring, 3 neighbours on each side means 3 + 2 + 1 = 6 friendships cross any point.
example : 3 + 2 + 1 = 6 := by decide

#print axioms large_outbreak_iff_T_kappa_above_one
#print axioms edge_walk_average_eq_mean_excess_degree
#print axioms random_doses_shrink_kappa
