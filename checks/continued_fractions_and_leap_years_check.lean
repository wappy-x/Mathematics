-- Continued fractions: a number's list of steps stops exactly when it is a fraction, the stops build from the steps, and each stop after step 1 or later is as close as any fraction with a bottom number no bigger than its own.
import Mathlib.Algebra.ContinuedFractions.Computation.TerminatesIffRat
import Mathlib.Algebra.ContinuedFractions.ContinuantsRecurrence
import Mathlib.Data.Rat.Floor
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

open GenContFract in
theorem cfl_contsAux_int (x : ℚ) : ∀ n : ℕ,
    ((∃ z : ℤ, ((GenContFract.of x).contsAux n).a = z) ∧ (∃ z : ℤ, ((GenContFract.of x).contsAux n).b = z)) ∧
    ((∃ z : ℤ, ((GenContFract.of x).contsAux (n+1)).a = z) ∧ (∃ z : ℤ, ((GenContFract.of x).contsAux (n+1)).b = z)) := by
  intro n
  induction n with
  | zero =>
    refine ⟨⟨⟨1, ?_⟩, ⟨0, ?_⟩⟩, ⟨⟨⌊x⌋, ?_⟩, ⟨1, ?_⟩⟩⟩ <;> simp [contsAux, GenContFract.of_h_eq_floor]
  | succ n ih =>
    refine ⟨ih.2, ?_⟩
    rcases hs : (GenContFract.of x).s.get? n with _ | gp
    · have : (GenContFract.of x).TerminatedAt n := hs
      rw [contsAux_stable_step_of_terminated this]
      exact ih.2
    · rw [contsAux_recurrence hs rfl rfl]
      obtain ⟨ha, ⟨k, hk⟩⟩ := of_partNum_eq_one_and_exists_int_partDen_eq hs
      obtain ⟨⟨⟨a0, h0⟩, ⟨b0, h1⟩⟩, ⟨⟨a1, h2⟩, ⟨b1, h3⟩⟩⟩ := ih
      refine ⟨⟨k * a1 + a0, ?_⟩, ⟨k * b1 + b0, ?_⟩⟩
      · simp [ha, hk, h0, h2]
      · simp [ha, hk, h1, h3]

open GenContFract in
theorem cfl_nums_int (x : ℚ) (n : ℕ) : ∃ z : ℤ, (GenContFract.of x).nums n = z := by
  rw [num_eq_conts_a, nth_cont_eq_succ_nth_contAux]
  exact (cfl_contsAux_int x n).2.1

open GenContFract in
theorem cfl_dens_int (x : ℚ) (n : ℕ) : ∃ z : ℤ, (GenContFract.of x).dens n = z := by
  rw [den_eq_conts_b, nth_cont_eq_succ_nth_contAux]
  exact (cfl_contsAux_int x n).2.2

open GenContFract in
theorem cfl_sign (x : ℚ) (m : ℕ) (ifp : IntFractPair.{0} ℚ)
    (h : IntFractPair.stream x m = some ifp) :
    0 ≤ (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m) ∧
      (ifp.fr ≠ 0 → 0 < (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m)) := by
  have key := sub_convs_eq h
  simp only at key
  have hsq : ((-1 : ℚ) ^ m) * (-1) ^ m = 1 := by
    rw [← mul_pow]; simp
  by_cases hfr : ifp.fr = 0
  · have : x - (GenContFract.of x).convs m = 0 := by
      have := key; rw [if_pos hfr] at this; exact this
    rw [this]; simp [hfr]
  · rw [if_neg hfr] at key
    have hpos : 0 < ((GenContFract.of x).contsAux (m + 1)).b * (ifp.fr⁻¹ * ((GenContFract.of x).contsAux (m + 1)).b
        + ((GenContFract.of x).contsAux m).b) := by
      have hor : m = 0 ∨ ¬(GenContFract.of x).TerminatedAt (m - 1) := by
        rcases m with _ | m
        · simp
        · have : IntFractPair.stream x (m + 1) ≠ none := by simp [h]
          have : ¬(GenContFract.of x).TerminatedAt m :=
            (not_congr of_terminatedAt_n_iff_succ_nth_intFractPair_stream_eq_none).2 this
          exact Or.inr this
      have pB_ineq : (Nat.fib m : ℚ) ≤ ((GenContFract.of x).contsAux m).b := by
        apply fib_le_of_contsAux_b
        rcases hor with h0 | h0
        · left; omega
        · by_cases hm : m ≤ 1
          · left; exact hm
          · right; exact mt (terminated_stable (by omega)) h0
      have B_ineq : (Nat.fib (m + 1) : ℚ) ≤ ((GenContFract.of x).contsAux (m + 1)).b := by
        apply fib_le_of_contsAux_b
        rcases hor with h0 | h0
        · left; omega
        · by_cases hm : m + 1 ≤ 1
          · left; exact hm
          · right; simpa using h0
      have hB : 0 < ((GenContFract.of x).contsAux (m + 1)).b :=
        B_ineq.trans_lt' (by exact_mod_cast Nat.fib_pos.2 (Nat.succ_pos m))
      have hpB : 0 ≤ ((GenContFract.of x).contsAux m).b := (Nat.cast_nonneg _).trans pB_ineq
      have hfr0 : 0 < ifp.fr :=
        (Ne.symm hfr).lt_of_le (IntFractPair.nth_stream_fr_nonneg h)
      positivity
    have e : (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m) =
        1 / (((GenContFract.of x).contsAux (m + 1)).b * (ifp.fr⁻¹ * ((GenContFract.of x).contsAux (m + 1)).b
        + ((GenContFract.of x).contsAux m).b)) := by
      rw [key, ← mul_div_assoc, hsq]
    have e2 : 0 < (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m) := by rw [e]; positivity
    exact ⟨e2.le, fun _ => e2⟩


theorem cfl_key (x : ℚ) (P0 Q0 P1 Q1 a b ε : ℤ) (hε : ε * ε = 1)
    (hdet : P0 * Q1 - Q0 * P1 = ε) (hQ0 : 0 < Q0) (hQ : Q0 < Q1)
    (h0 : (ε : ℚ) * (Q0 * x - P0) ≤ 0) (h1 : 0 ≤ (ε : ℚ) * (Q1 * x - P1))
    (hb : 0 < b) (hbQ : b < Q1) : |(Q0 : ℚ) * x - P0| ≤ |(b : ℚ) * x - a| := by
  obtain ⟨u, v, hua, hvb⟩ : ∃ u v : ℤ, a = u * P0 + v * P1 ∧ b = u * Q0 + v * Q1 := by
    refine ⟨ε * (a * Q1 - b * P1), ε * (P0 * b - Q0 * a), ?_, ?_⟩
    · linear_combination (-(ε * a)) * hdet + (-a) * hε
    · linear_combination (-(ε * b)) * hdet + (-b) * hε
  have hS : (b : ℚ) * x - a = u * (Q0 * x - P0) + v * (Q1 * x - P1) := by
    have e1 : (a : ℚ) = u * P0 + v * P1 := by exact_mod_cast hua
    have e2 : (b : ℚ) = u * Q0 + v * Q1 := by exact_mod_cast hvb
    rw [e1, e2]; ring
  have hcase : (0 < u ∧ v < 0) ∨ (u < 0 ∧ 0 < v) ∨ (0 < u ∧ v = 0) := by
    rcases lt_trichotomy u 0 with hu0 | hu0 | hu0 <;> rcases lt_trichotomy v 0 with hv0 | hv0 | hv0
    · exfalso; nlinarith
    · exfalso; nlinarith
    · right; left; exact ⟨hu0, hv0⟩
    · exfalso; rw [hu0] at hvb; nlinarith
    · exfalso; rw [hu0, hv0] at hvb; omega
    · exfalso; rw [hu0] at hvb; nlinarith
    · left; exact ⟨hu0, hv0⟩
    · right; right; exact ⟨hu0, hv0⟩
    · exfalso; nlinarith
  rw [hS]
  have hε' : ε = 1 ∨ ε = -1 := by
    have : ε ∣ 1 := ⟨ε, hε.symm⟩
    exact Int.isUnit_iff.mp (isUnit_of_dvd_one this)
  set D0 : ℚ := Q0 * x - P0
  set D1 : ℚ := Q1 * x - P1
  rcases hcase with ⟨hu1, hv1⟩ | ⟨hu1, hv1⟩ | ⟨hu1, hv1⟩
  · have hu1' : (1 : ℚ) ≤ u := by exact_mod_cast hu1
    have hv1' : (v : ℚ) ≤ -1 := by exact_mod_cast (by omega : v ≤ -1)
    rcases hε' with rfl | rfl
    · have : D0 ≤ 0 := by simpa using h0
      have : 0 ≤ D1 := by simpa using h1
      rw [abs_of_nonpos (by assumption)]
      rw [abs_of_nonpos (by nlinarith)]
      nlinarith
    · have : 0 ≤ D0 := by simpa using h0
      have : D1 ≤ 0 := by simpa using h1
      rw [abs_of_nonneg (by assumption)]
      rw [abs_of_nonneg (by nlinarith)]
      nlinarith
  · have hu1' : (u : ℚ) ≤ -1 := by exact_mod_cast (by omega : u ≤ -1)
    have hv1' : (1 : ℚ) ≤ v := by exact_mod_cast hv1
    rcases hε' with rfl | rfl
    · have : D0 ≤ 0 := by simpa using h0
      have : 0 ≤ D1 := by simpa using h1
      rw [abs_of_nonpos (by assumption)]
      rw [abs_of_nonneg (by nlinarith)]
      nlinarith
    · have : 0 ≤ D0 := by simpa using h0
      have : D1 ≤ 0 := by simpa using h1
      rw [abs_of_nonneg (by assumption)]
      rw [abs_of_nonpos (by nlinarith)]
      nlinarith
  · rw [hv1] at hvb ⊢
    have hu1' : (1 : ℚ) ≤ u := by exact_mod_cast hu1
    simp only [Int.cast_zero, zero_mul, add_zero]
    rw [abs_mul, abs_of_pos (by linarith : (0:ℚ) < u)]
    nlinarith [abs_nonneg D0]

#print axioms cfl_contsAux_int
#print axioms cfl_nums_int
#print axioms cfl_dens_int
#print axioms cfl_sign
#print axioms cfl_key

/-- Each stop is the best of its size. Take a fraction x and run Euclid's algorithm on it, which is
Mathlib's continued fraction `GenContFract.of x`. Cut the list short after step n, for n = 1, 2, 3,
and so on; the stop is `convs n` and its bottom number is `dens n`. Then no fraction a / b with a
bottom number b from 1 up to that bottom number is closer to x than the stop is. -/
theorem stop_is_closest_fraction_of_its_size (x : ℚ) (n : ℕ) (hn : 1 ≤ n) (a : ℤ) (b : ℕ)
    (hb : 0 < b) (hbq : (b : ℚ) ≤ (GenContFract.of x).dens n) :
    |x - (GenContFract.of x).convs n| ≤ |x - (a : ℚ) / b| := by
  by_cases ht : (GenContFract.of x).TerminatedAt n
  · have := GenContFract.of_correctness_of_terminatedAt ht
    rw [← this]; simp
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  -- stream facts
  have hne : GenContFract.IntFractPair.stream x (m + 1 + 1) ≠ none := fun h =>
    ht (GenContFract.of_terminatedAt_n_iff_succ_nth_intFractPair_stream_eq_none.2 h)
  obtain ⟨ifp1, hs1⟩ := Option.ne_none_iff_exists'.1 hne
  obtain ⟨ifp0, hs0, hfr0, -⟩ := GenContFract.IntFractPair.succ_nth_stream_eq_some_iff.1 hs1
  have S0 := (cfl_sign x (m + 1) ifp0 hs0).2 hfr0
  have S1 := (cfl_sign x (m + 1 + 1) ifp1 hs1).1
  -- integers
  obtain ⟨P0, hP0⟩ := cfl_nums_int x (m + 1)
  obtain ⟨P1, hP1⟩ := cfl_nums_int x (m + 1 + 1)
  obtain ⟨Q0, hQ0⟩ := cfl_dens_int x (m + 1)
  obtain ⟨Q1, hQ1⟩ := cfl_dens_int x (m + 1 + 1)
  -- positivity and growth of denominators
  have hnt : ¬(GenContFract.of x).TerminatedAt (m - 1) := mt (GenContFract.terminated_stable (by omega)) ht
  have hdm : (1 : ℚ) ≤ (GenContFract.of x).dens m := by
    have := GenContFract.succ_nth_fib_le_of_nth_den (v := x) (n := m)
      (by rcases m with _ | m
          · exact Or.inl rfl
          · exact Or.inr (mt (GenContFract.terminated_stable (by omega)) ht))
    have h1 : (1 : ℚ) ≤ (Nat.fib (m + 1) : ℚ) := by exact_mod_cast Nat.fib_pos.2 (Nat.succ_pos m)
    linarith
  obtain ⟨gp, hgp⟩ : ∃ gp, (GenContFract.of x).s.get? (m + 1) = some gp :=
    Option.ne_none_iff_exists'.1 ht
  have hga : gp.a = 1 := (GenContFract.of_partNum_eq_one_and_exists_int_partDen_eq hgp).left
  have hgb : (1 : ℚ) ≤ gp.b :=
    GenContFract.of_one_le_get?_partDen (GenContFract.partDen_eq_s_b hgp)
  have hrec := GenContFract.dens_recurrence hgp (rfl : (GenContFract.of x).dens m = _) rfl
  rw [hga] at hrec
  have hQ0pos : (1 : ℚ) ≤ (GenContFract.of x).dens (m + 1) := by
    have := GenContFract.of_den_mono (v := x) (n := m)
    linarith
  have hlt : (GenContFract.of x).dens (m + 1) < (GenContFract.of x).dens (m + 1 + 1) := by
    rw [hrec]; nlinarith
  -- determinant
  have hdet := (SimpContFract.of x).determinant (n := m + 1) ht
  have hdet' : (GenContFract.of x).nums (m + 1) * (GenContFract.of x).dens (m + 1 + 1) -
      (GenContFract.of x).dens (m + 1) * (GenContFract.of x).nums (m + 1 + 1) =
      (-1) ^ (m + 1 + 1) := hdet
  -- apply key
  have hP0' : (P0 : ℚ) = (GenContFract.of x).nums (m + 1) := hP0.symm
  have hP1' : (P1 : ℚ) = (GenContFract.of x).nums (m + 1 + 1) := hP1.symm
  have hQ0' : (Q0 : ℚ) = (GenContFract.of x).dens (m + 1) := hQ0.symm
  have hQ1' : (Q1 : ℚ) = (GenContFract.of x).dens (m + 1 + 1) := hQ1.symm
  have hQ0z : 0 < Q0 := by
    have : (1 : ℚ) ≤ Q0 := by rw [hQ0']; exact hQ0pos
    exact_mod_cast this
  have hQlt : Q0 < Q1 := by
    have : (Q0 : ℚ) < Q1 := by rw [hQ0', hQ1']; exact hlt
    exact_mod_cast this
  have hbz : (b : ℤ) < Q1 := by
    have : (b : ℚ) < Q1 := by linarith
    exact_mod_cast this
  have hbQ0 : (b : ℚ) ≤ Q0 := by rw [hQ0']; exact hbq
  have hdetZ : P0 * Q1 - Q0 * P1 = (-1 : ℤ) ^ (m + 1 + 1) := by
    have : (P0 : ℚ) * Q1 - Q0 * P1 = (-1 : ℚ) ^ (m + 1 + 1) := by
      rw [hP0', hP1', hQ0', hQ1']; exact hdet'
    exact_mod_cast this
  have hεε : ((-1 : ℤ) ^ (m + 1 + 1)) * (-1) ^ (m + 1 + 1) = 1 := by
    rw [← mul_pow]; simp
  have hεq : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) = -(-1 : ℚ) ^ (m + 1) := by
    push_cast; ring
  have hc0 : (GenContFract.of x).convs (m + 1) = (P0 : ℚ) / Q0 := by
    show (GenContFract.of x).nums (m + 1) / (GenContFract.of x).dens (m + 1) = _
    rw [hP0', hQ0']
  have hc1 : (GenContFract.of x).convs (m + 1 + 1) = (P1 : ℚ) / Q1 := by
    show (GenContFract.of x).nums (m + 1 + 1) / (GenContFract.of x).dens (m + 1 + 1) = _
    rw [hP1', hQ1']
  rw [hc0] at S0
  rw [hc1] at S1
  have hQ0q : (0 : ℚ) < Q0 := by exact_mod_cast hQ0z
  have hQ1q : (0 : ℚ) < Q1 := by exact_mod_cast hQ0z.trans hQlt
  have h0 : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q0 * x - P0) ≤ 0 := by
    have e : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q0 * x - P0) =
        -(((-1 : ℚ) ^ (m + 1) * (x - P0 / Q0)) * Q0) := by
      rw [hεq]; field_simp
    rw [e]
    have := mul_pos S0 hQ0q
    linarith
  have h1 : 0 ≤ (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q1 * x - P1) := by
    have e : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q1 * x - P1) =
        ((-1 : ℚ) ^ (m + 1 + 1) * (x - P1 / Q1)) * Q1 := by
      rw [hεq]; field_simp; ring
    rw [e]
    exact mul_nonneg S1 hQ1q.le
  have hk := cfl_key x P0 Q0 P1 Q1 a b _ hεε hdetZ hQ0z hQlt h0 h1 (by exact_mod_cast hb) hbz
  have hbq' : (0 : ℚ) < b := by exact_mod_cast hb
  have eL : |x - (P0 : ℚ) / Q0| = |(Q0 : ℚ) * x - P0| / Q0 := by
    rw [← abs_of_pos hQ0q, ← abs_div, abs_of_pos hQ0q]
    congr 1; field_simp
  have eR : |x - (a : ℚ) / b| = |(b : ℚ) * x - a| / b := by
    rw [← abs_of_pos hbq', ← abs_div, abs_of_pos hbq']
    congr 1; field_simp
  have hk' : |(Q0 : ℚ) * x - P0| ≤ |(b : ℚ) * x - a| := by simpa using hk
  rw [hc0, eL, eR, div_le_div_iff₀ hQ0q hbq']
  nlinarith [abs_nonneg ((Q0 : ℚ) * x - P0), abs_nonneg ((b : ℚ) * x - a)]

/-- The list stops exactly for fractions. Euclid's steps on a number run out after finitely many
steps when the number is a fraction, and go on forever when it is irrational. -/
theorem steps_stop_iff_number_is_a_fraction (x : ℝ) :
    (GenContFract.of x).Terminates ↔ ∃ q : ℚ, x = (q : ℝ) := by
  exact GenContFract.terminates_iff_rat x

/-- The stops build themselves from the steps: if the next step is s, the new top number is
s times the previous top plus the top before that, and the bottom numbers follow the same rule. -/
theorem stops_build_from_steps (x : ℚ) (n : ℕ) (s : ℚ)
    (hs : (GenContFract.of x).partDens.get? (n + 1) = some s) :
    (GenContFract.of x).nums (n + 2) =
        s * (GenContFract.of x).nums (n + 1) + (GenContFract.of x).nums n ∧
      (GenContFract.of x).dens (n + 2) =
        s * (GenContFract.of x).dens (n + 1) + (GenContFract.of x).dens n := by
  obtain ⟨gp, hgp, rfl⟩ := GenContFract.exists_s_b_of_partDen hs
  have ha : gp.a = 1 := (GenContFract.of_partNum_eq_one_and_exists_int_partDen_eq hgp).left
  constructor
  · rw [GenContFract.nums_recurrence hgp rfl rfl, ha]; ring
  · rw [GenContFract.dens_recurrence hgp rfl rfl, ha]; ring

-- The leftover 0.2422 is 2422/10000, which cuts down to 1211/5000.
example : (2422 : ℚ) / 10000 = 1211 / 5000 := by norm_num
-- Euclid's algorithm on 1211 and 5000: whole times 0, 4, 7, 1, 3, 4, 1, 1, 1, 2, then remainder 0.
example : 1211 = 0 * 5000 + 1211 ∧ 5000 = 4 * 1211 + 156 ∧ 1211 = 7 * 156 + 119 ∧
    156 = 1 * 119 + 37 ∧ 119 = 3 * 37 + 8 ∧ 37 = 4 * 8 + 5 ∧ 8 = 1 * 5 + 3 ∧ 5 = 1 * 3 + 2 ∧
    3 = 1 * 2 + 1 ∧ 2 = 2 * 1 + 0 := by decide
-- The same steps from Mathlib's continued fraction of 1211/5000: whole part 0, then the list.
example : (GenContFract.of (1211 / 5000 : ℚ)).h = 0 ∧
    (List.range 10).map (fun n => (GenContFract.of (1211 / 5000 : ℚ)).partDens.get? n) =
      [some 4, some 7, some 1, some 3, some 4, some 1, some 1, some 1, some 2, none] := by
  decide +kernel
-- The stops after steps 1 to 4: 1/4, 7/29, 8/33, 31/128.
example : (GenContFract.of (1211 / 5000 : ℚ)).convs 1 = 1 / 4 ∧
    (GenContFract.of (1211 / 5000 : ℚ)).convs 2 = 7 / 29 ∧
    (GenContFract.of (1211 / 5000 : ℚ)).convs 3 = 8 / 33 ∧
    (GenContFract.of (1211 / 5000 : ℚ)).convs 4 = 31 / 128 := by
  decide +kernel
-- The stop 31/128 has bottom number 128, so the first theorem covers every bottom up to 128.
example : (GenContFract.of (1211 / 5000 : ℚ)).dens 4 = 128 := by decide +kernel
-- From 7/29 and the step 1: 8 = 1 × 7 + 1, 33 = 1 × 29 + 4.
example : 8 = 1 * 7 + 1 ∧ 33 = 1 * 29 + 4 := by decide
-- Counting the real rule over 400 years gives 97 leap days: 100 multiples of 4, 3 centuries skipped.
example : ((Finset.Icc 1 400).filter (fun y => y % 4 = 0)).card = 100 ∧
    ((Finset.Icc 1 400).filter (fun y => y % 100 = 0 ∧ y % 400 ≠ 0)).card = 3 ∧
    ((Finset.Icc 1 400).filter (fun y => y % 4 = 0 ∧ (y % 100 ≠ 0 ∨ y % 400 = 0))).card = 97 := by
  decide
-- Drift over 400 years: 1/4 is 3.120 days too many, 97/400 is 0.120 days too many.
example : ((1 : ℚ) / 4 - 1211 / 5000) * 400 = 78 / 25 ∧
    ((97 : ℚ) / 400 - 1211 / 5000) * 400 = 3 / 25 := by norm_num
-- 97/400 is not best of its size: 31/128 is more than 20 times closer to 0.2422.
example : |(97 : ℚ) / 400 - 1211 / 5000| > 20 * |(31 : ℚ) / 128 - 1211 / 5000| := by norm_num
-- The Gregorian year 0.2425 = 97/400: steps 0, 4, 8, 12, and the last stop is 97/400 exactly.
example : (GenContFract.of (97 / 400 : ℚ)).h = 0 ∧
    (List.range 4).map (fun n => (GenContFract.of (97 / 400 : ℚ)).partDens.get? n) =
      [some 4, some 8, some 12, none] ∧
    (GenContFract.of (97 / 400 : ℚ)).convs 3 = 97 / 400 := by
  decide +kernel

#print axioms stop_is_closest_fraction_of_its_size
#print axioms steps_stop_iff_number_is_a_fraction
#print axioms stops_build_from_steps
