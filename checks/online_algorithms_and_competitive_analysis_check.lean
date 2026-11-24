-- Online algorithms: buying skis on day B is (2 - 1/B)-competitive, no deterministic rule does better, and random marking's phase cost is at most f times the harmonic sum H_k.
import Mathlib.NumberTheory.Harmonic.Defs
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Push

/-- A rule is `c`-competitive with allowance `a` when, on every request sequence `σ`,
it pays at most `c` times what hindsight pays, plus `a`. -/
def IsCompetitive {S : Type*} (alg opt : S → ℕ) (c a : ℚ) : Prop :=
  ∀ σ : S, (alg σ : ℚ) ≤ c * (opt σ : ℚ) + a

/-- Ski rental, costs in days of rent, buying costs `B`. A deterministic rule is
`some t` ("rent, and buy on the morning of day `t`") or `none` ("never buy").
The family skis `d` days. -/
def skiCost (B : ℕ) : Option ℕ → ℕ → ℕ
  | none, d => d
  | some t, d => if d < t then d else t - 1 + B

/-- Hindsight pays the smaller of renting every day and buying at once. -/
def skiOpt (B d : ℕ) : ℕ := min d B


/-- The reflected tail of the harmonic sum: `1/(f+n) + ... + 1/(f+1) = H_(f+n) - H_f`. -/
lemma harmonic_tail_reflect (f n : ℕ) :
    ∑ i ∈ Finset.range n, (1 : ℚ) / ((f : ℚ) + n - i) = harmonic (f + n) - harmonic f := by
  induction n with
  | zero => simp
  | succ n ih =>
    calc ∑ i ∈ Finset.range (n + 1), (1 : ℚ) / ((f : ℚ) + ((n + 1 : ℕ) : ℚ) - i)
        = ∑ i ∈ Finset.range n, (1 : ℚ) / ((f : ℚ) + ((n + 1 : ℕ) : ℚ) - ((i + 1 : ℕ) : ℚ))
          + (1 : ℚ) / ((f : ℚ) + ((n + 1 : ℕ) : ℚ) - ((0 : ℕ) : ℚ)) :=
          Finset.sum_range_succ' _ _
      _ = ∑ i ∈ Finset.range n, (1 : ℚ) / ((f : ℚ) + n - i) + (1 : ℚ) / ((f : ℚ) + n + 1) := by
          congr 1
          · exact Finset.sum_congr rfl (fun i _ => by push_cast; ring_nf)
          · push_cast; ring_nf
      _ = harmonic (f + (n + 1)) - harmonic f := by
          rw [ih, ← add_assoc, harmonic_succ]
          push_cast
          ring

/-- `H_f ≥ 1` once `f ≥ 1`. -/
lemma one_le_harmonic_of_pos (f : ℕ) (hf : 1 ≤ f) : (1 : ℚ) ≤ harmonic f := by
  induction f with
  | zero => omega
  | succ n ih =>
    rw [harmonic_succ]
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; norm_num
    · have := ih h
      have : (0 : ℚ) ≤ (↑(n + 1))⁻¹ := by positivity
      linarith

/-- Ski rental: the rule "rent, and buy on the morning of day `B`" never pays more than
`2 - 1/B` times what hindsight pays, whatever the length of the season (strict ratio, a = 0). -/
theorem buy_on_day_B_is_two_minus_inv_B_competitive (B : ℕ) :
    IsCompetitive (skiCost B (some B)) (skiOpt B) (2 - 1 / (B : ℚ)) 0 := by
  intro d
  simp only [skiCost, skiOpt]
  rcases Nat.eq_zero_or_pos B with hB | hB
  · subst hB
    simp
  · have hBq : (1 : ℚ) ≤ B := by exact_mod_cast hB
    have hinv : 1 / (B : ℚ) ≤ 1 := by
      rw [div_le_one (by linarith)]; exact hBq
    have hBne : (B : ℚ) ≠ 0 := by positivity
    split_ifs with h
    · rw [min_eq_left h.le]
      have hd : (0 : ℚ) ≤ d := by positivity
      nlinarith
    · rw [not_lt] at h
      rw [min_eq_right h]
      have : ((B - 1 + B : ℕ) : ℚ) = 2 * B - 1 := by
        rw [Nat.cast_add, Nat.cast_sub hB]; push_cast; ring
      rw [this, sub_mul, one_div, inv_mul_cancel₀ hBne]
      linarith

/-- Ski rental lower bound: when buying costs at least one day of rent, no deterministic rule
(buy on some fixed day, or never buy) is `c`-competitive with the strict ratio for any
`c < 2 - 1/B`. -/
theorem no_deterministic_ski_rule_beats_two_minus_inv_B (B : ℕ) (hB : 1 ≤ B)
    (rule : Option ℕ) (c : ℚ) (hc : c < 2 - 1 / (B : ℚ)) :
    ¬ IsCompetitive (skiCost B rule) (skiOpt B) c 0 := by
  intro hcomp
  have hBq : (1 : ℚ) ≤ B := by exact_mod_cast hB
  have hBpos : (0 : ℚ) < B := by linarith
  have hinvpos : 0 < 1 / (B : ℚ) := by positivity
  have hBne : (B : ℚ) ≠ 0 := by positivity
  cases rule with
  | none =>
    have h := hcomp (2 * B)
    simp only [skiCost, skiOpt] at h
    rw [min_eq_right (by omega)] at h
    push_cast at h
    nlinarith
  | some t =>
    rcases Nat.eq_zero_or_pos t with ht | ht
    · subst ht
      have h := hcomp 0
      simp only [skiCost, skiOpt] at h
      simp at h
      linarith
    · have h := hcomp t
      simp only [skiCost, skiOpt, lt_irrefl, ite_false] at h
      have htq : (1 : ℚ) ≤ t := by exact_mod_cast ht
      have hcast : ((t - 1 + B : ℕ) : ℚ) = t - 1 + B := by
        rw [Nat.cast_add, Nat.cast_sub ht]; push_cast; ring
      rw [hcast] at h
      rcases le_total t B with htB | htB
      · rw [min_eq_left htB] at h
        have htBq : (t : ℚ) ≤ B := by exact_mod_cast htB
        -- c * t < (2 - 1/B) * t ≤ t - 1 + B
        have h1 : c * t < (2 - 1 / (B : ℚ)) * t := by nlinarith
        have h2 : (2 - 1 / (B : ℚ)) * t ≤ t - 1 + B := by
          have key : (t - 1 + B) - (2 - 1 / (B : ℚ)) * t = (B - t) * (1 - 1 / B) := by
            field_simp; ring
          have hinv1 : 1 / (B : ℚ) ≤ 1 := by rw [div_le_one hBpos]; exact hBq
          nlinarith [key]
        linarith
      · rw [min_eq_right htB] at h
        have htBq : (B : ℚ) ≤ t := by exact_mod_cast htB
        have h1 : c * B < (2 - 1 / (B : ℚ)) * B := by nlinarith
        have h2 : (2 - 1 / (B : ℚ)) * B = 2 * B - 1 := by
          rw [sub_mul, one_div, inv_mul_cancel₀ hBne]
        linarith

/-- Random marking, one phase with `f` fresh tracks and a cache of `k` tracks: the `f` faults
on fresh tracks plus the chances `f/(k - j + 1)` that the `j`-th stale track is missing add up
to `f (H_k - H_f + 1)`, and that is at most `f H_k`. -/
theorem marking_phase_expected_faults_le (k f : ℕ) (hfk : f ≤ k) :
    (f : ℚ) + ∑ j ∈ Finset.Icc 1 (k - f), (f : ℚ) / ((k : ℚ) - j + 1)
        = f * (harmonic k - harmonic f + 1) ∧
      (f : ℚ) * (harmonic k - harmonic f + 1) ≤ f * harmonic k := by
  obtain ⟨n, rfl⟩ := Nat.exists_eq_add_of_le hfk
  refine ⟨?_, ?_⟩
  · have hsub : f + n - f = n := by omega
    have hmap : Finset.Icc 1 n = (Finset.range n).map ⟨(· + 1), add_left_injective 1⟩ := by
      ext j; simp only [Finset.mem_Icc, Finset.mem_map, Finset.mem_range,
        Function.Embedding.coeFn_mk]
      constructor
      · intro h; exact ⟨j - 1, by omega, by omega⟩
      · rintro ⟨i, hi, rfl⟩; omega
    rw [hsub, hmap, Finset.sum_map]
    simp only [Function.Embedding.coeFn_mk]
    have h : ∀ i ∈ Finset.range n,
        (f : ℚ) / (((f + n : ℕ) : ℚ) - ((i + 1 : ℕ) : ℚ) + 1)
          = (f : ℚ) * ((1 : ℚ) / ((f : ℚ) + n - i)) := by
      intro i _
      rw [mul_one_div]
      congr 1
      push_cast
      ring
    rw [Finset.sum_congr rfl h, ← Finset.mul_sum, harmonic_tail_reflect]
    ring
  · rcases Nat.eq_zero_or_pos f with hf | hf
    · subst hf; simp
    · have := one_le_harmonic_of_pos f hf
      have hfq : (0 : ℚ) ≤ f := by positivity
      nlinarith

-- Ski rental with B = 10 days (£250 at £25 a day): buy on day 10.
example : skiCost 10 (some 10) 3 = 3 ∧ skiOpt 10 3 = 3 := by decide
example : skiCost 10 (some 10) 10 = 19 ∧ skiOpt 10 10 = 10 := by decide
example : skiCost 10 (some 10) 25 = 19 ∧ skiOpt 10 25 = 10 := by decide
example : 25 * skiCost 10 (some 10) 10 = 475 ∧ 25 * skiOpt 10 10 = 250 := by decide
example : (2 : ℚ) - 1 / 10 = 19 / 10 := by norm_num
-- Buy on day 1: 250 against 25 pounds, ratio 10.
example : skiCost 10 (some 1) 1 = 10 ∧ skiOpt 10 1 = 1 := by decide
-- Never buy: ratio 10 at 100 days, 100 at 1000.
example : skiCost 10 none 100 = 10 * skiOpt 10 100 := by decide
example : skiCost 10 none 1000 = 100 * skiOpt 10 1000 := by decide

-- Paging with k = 4 on 2000 requests: the adversary's OPT cap k + ⌈(n - k)/k⌉ = 503,
-- LRU pays k per phase over 500 phases, and OPT 503 is at least 500 - 1.
example : 4 + (2000 - 4 + 3) / 4 = 503 := by norm_num
example : 4 * 500 = 2000 ∧ 500 - 1 ≤ 503 := by norm_num
-- H_4 = 25/12 (2.0833), 2 H_4 = 25/6 (4.17), 2 H_5 = 137/30 (4.567).
example : harmonic 4 = 25 / 12 := by norm_num [harmonic, Finset.sum_range_succ]
example : 2 * harmonic 4 = 25 / 6 := by norm_num [harmonic, Finset.sum_range_succ]
example : 2 * harmonic 5 = 137 / 30 := by norm_num [harmonic, Finset.sum_range_succ]
-- Marking on the 2000-request cycle: 4 + 499 H_4 = 12523/12 (1043.58) expected faults.
example : (4 : ℚ) + 499 * harmonic 4 = 12523 / 12 := by norm_num [harmonic, Finset.sum_range_succ]
-- One fresh track per phase: the bound f (H_4 - H_f + 1) is exactly H_4.
example : (1 : ℚ) * (harmonic 4 - harmonic 1 + 1) = harmonic 4 := by norm_num [harmonic]

#print axioms harmonic_tail_reflect
#print axioms one_le_harmonic_of_pos
#print axioms buy_on_day_B_is_two_minus_inv_B_competitive
#print axioms no_deterministic_ski_rule_beats_two_minus_inv_B
#print axioms marking_phase_expected_faults_le
