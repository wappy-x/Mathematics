-- Hurwitz's theorem: every irrational number has infinitely many fractions p/q within 1/(√5 q²), for the golden ratio no constant bigger than √5 works, and the golden ratio's stops make p² − pq − q² equal to ±1.
import Mathlib.NumberTheory.Real.GoldenRatio
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Data.Rat.Cast.Order
import Mathlib.Tactic.LinearCombination

open Real
open scoped goldenRatio

lemma hurwitz_sqrt5_irrational : Irrational √5 := by
  simpa using Nat.Prime.irrational_sqrt (show Nat.Prime 5 by norm_num)

lemma hurwitz_quad (x y w : ℝ) (hx : 0 < x) (hw : w ^ 2 = 5)
    (h1 : x ^ 2 + y ^ 2 ≤ w * x * y) (h2 : x ^ 2 + (x + y) ^ 2 ≤ w * x * (x + y)) :
    2 * y + x = w * x := by
  have hwx : w ^ 2 * x ^ 2 = 5 * x ^ 2 := by rw [hw]
  have a : w * x ≤ 2 * y + x := by
    by_contra h
    replace h := lt_of_not_ge h
    have e1 : y - (w - 1) * x / 2 < 0 := by linarith
    have e2 : y - (w + 1) * x / 2 < 0 := by nlinarith
    nlinarith [mul_pos_of_neg_of_neg e1 e2]
  have b : 2 * y + x ≤ w * x := by
    by_contra h
    replace h := lt_of_not_ge h
    have e1 : (x + y) - (w + 1) * x / 2 > 0 := by linarith
    have e2 : (x + y) - (w - 1) * x / 2 > 0 := by nlinarith
    nlinarith [mul_pos e1 e2]
  linarith

lemma hurwitz_sum (w x y u v : ℝ) (hw : 0 < w) (hx : 0 < x) (hy : 0 < y)
    (hu : 1 / (w * x ^ 2) ≤ u) (hv : 1 / (w * y ^ 2) ≤ v) (huv : u + v = 1 / (x * y)) :
    x ^ 2 + y ^ 2 ≤ w * x * y := by
  have h : 1 / (w * x ^ 2) + 1 / (w * y ^ 2) ≤ 1 / (x * y) := by linarith
  rw [div_add_div _ _ (by positivity) (by positivity), div_le_div_iff₀ (by positivity)
    (by positivity)] at h
  nlinarith [h, mul_pos (mul_pos hw hx) hy, mul_pos hx hy]

lemma hurwitz_rat_of (α : ℝ) (p : ℤ) (q : ℕ) (hq : 0 < q)
    (h : |α - (p : ℝ) / q| < 1 / (√5 * (q : ℝ) ^ 2)) :
    ∃ r : ℚ, (r : ℝ) = (p : ℝ) / q ∧ |α - r| < 1 / (√5 * (r.den : ℝ) ^ 2) := by
  have hcast : (((p : ℚ) / q : ℚ) : ℝ) = (p : ℝ) / q := by push_cast; ring
  refine ⟨(p : ℚ) / q, hcast, ?_⟩
  rw [hcast]
  have hden : ((p : ℚ) / q).den ≤ q := by
    have := Rat.den_dvd p q
    rw [Rat.divInt_eq_div] at this
    push_cast at this
    have := Int.le_of_dvd (by exact_mod_cast hq) this
    exact_mod_cast this
  have hd0 : (0 : ℝ) < ((p : ℚ) / q).den := by exact_mod_cast ((p : ℚ) / q).pos
  have hle : (((p : ℚ) / q).den : ℝ) ^ 2 ≤ (q : ℝ) ^ 2 := by
    have : (((p : ℚ) / q).den : ℝ) ≤ q := by exact_mod_cast hden
    gcongr
  have h5 : (0 : ℝ) < √5 := by positivity
  calc |α - (p : ℝ) / q| < 1 / (√5 * (q : ℝ) ^ 2) := h
    _ ≤ 1 / (√5 * (((p : ℚ) / q).den : ℝ) ^ 2) := by
      apply one_div_le_one_div_of_le (by positivity)
      exact mul_le_mul_of_nonneg_left hle h5.le

lemma hurwitz_score_aux (p : ℤ) (q : ℕ) (hq : 0 < q) :
    1 ≤ ((q : ℝ) ^ 2 * |φ - (p : ℝ) / q|) *
      (√5 + ((q : ℝ) ^ 2 * |φ - (p : ℝ) / q|) / (q : ℝ) ^ 2) := by
  have hQ : (0 : ℝ) < q := by exact_mod_cast hq
  set Q : ℝ := (q : ℝ) with hQdef
  set P : ℝ := (p : ℝ) with hPdef
  set t : ℝ := Q * φ - P with htdef
  have hrw : |φ - P / Q| = |t| / Q := by
    rw [show φ - P / Q = t / Q by rw [htdef]; field_simp, abs_div, abs_of_pos hQ]
  rw [hrw]
  have hexp : (Q ^ 2 * (|t| / Q)) * (√5 + (Q ^ 2 * (|t| / Q)) / Q ^ 2)
      = |t| * (Q * √5 + |t|) := by
    field_simp
  rw [hexp]
  have h5 : √5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
  have hid : P ^ 2 - P * Q - Q ^ 2 = t * (t - Q * √5) := by
    rw [htdef, goldenRatio]
    linear_combination (Q ^ 2 / 4) * h5
  have hN : p ^ 2 - p * (q : ℤ) - (q : ℤ) ^ 2 ≠ 0 := by
    intro h0
    have h0' : P ^ 2 - P * Q - Q ^ 2 = 0 := by
      rw [hPdef, hQdef]; exact_mod_cast h0
    rw [hid] at h0'
    rcases mul_eq_zero.mp h0' with ht | ht
    · apply goldenRatio_irrational.ne_rational p q
      push_cast
      rw [← hPdef, ← hQdef, eq_div_iff hQ.ne', goldenRatio]
      rw [htdef, goldenRatio] at ht
      linear_combination ht
    · apply goldenConj_irrational.ne_rational p q
      push_cast
      rw [← hPdef, ← hQdef, eq_div_iff hQ.ne', goldenConj]
      rw [htdef, goldenRatio] at ht
      linear_combination ht
  have h1 : (1 : ℝ) ≤ |P ^ 2 - P * Q - Q ^ 2| := by
    have := Int.one_le_abs hN
    rw [hPdef, hQdef]
    exact_mod_cast this
  rw [hid, abs_mul] at h1
  have h2 : |t - Q * √5| ≤ |t| + Q * √5 := by
    calc |t - Q * √5| ≤ |t| + |Q * √5| := abs_sub _ _
      _ = |t| + Q * √5 := by rw [abs_of_pos (mul_pos hQ (by positivity) : (0:ℝ) < Q * √5)]
  calc (1 : ℝ) ≤ |t| * |t - Q * √5| := h1
    _ ≤ |t| * (|t| + Q * √5) := mul_le_mul_of_nonneg_left h2 (abs_nonneg _)
    _ = |t| * (Q * √5 + |t|) := by ring

lemma hurwitz_no_triple (α : ℝ) (hα : Irrational α) (a c : ℤ) (b d : ℕ) (hb : 0 < b)
    (hd : 0 < d) (hdet : (b : ℤ) * c - a * d = 1) (hl : (a : ℝ) / b < α)
    (hr : α < (c : ℝ) / d) :
    ∃ r : ℚ, |α - r| < 1 / (√5 * (r.den : ℝ) ^ 2) ∧ |α - r| < 1 / ((b : ℝ) * d) := by
  have hB : (0 : ℝ) < b := by exact_mod_cast hb
  have hD : (0 : ℝ) < d := by exact_mod_cast hd
  have hdetR : (b : ℝ) * c - a * d = 1 := by exact_mod_cast hdet
  have hw0 : (0 : ℝ) < √5 := by positivity
  have hw : √5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
  have hgap : (c : ℝ) / d - a / b = 1 / ((b : ℝ) * d) := by
    field_simp
    linarith
  have hgapA : ((a : ℝ) + c) / (b + d) - a / b = 1 / ((b : ℝ) * (b + d)) := by
    field_simp
    linarith
  have hgapC : (c : ℝ) / d - (a + c) / (b + d) = 1 / ((d : ℝ) * (b + d)) := by
    field_simp
    linarith
  have hpos1 : (0 : ℝ) < 1 / ((b : ℝ) * (b + d)) := by positivity
  have hpos2 : (0 : ℝ) < 1 / ((d : ℝ) * (b + d)) := by positivity
  have cand : ∀ (p : ℤ) (q : ℕ), 0 < q → |α - (p : ℝ) / q| < 1 / ((b : ℝ) * d) →
      |α - (p : ℝ) / q| < 1 / (√5 * (q : ℝ) ^ 2) →
      ∃ r : ℚ, |α - r| < 1 / (√5 * (r.den : ℝ) ^ 2) ∧ |α - r| < 1 / ((b : ℝ) * d) := by
    intro p q hq hclose hgood
    obtain ⟨r, hr, hg⟩ := hurwitz_rat_of α p q hq hgood
    exact ⟨r, hg, hr ▸ hclose⟩
  by_contra H
  have hA : 1 / (√5 * (b : ℝ) ^ 2) ≤ α - a / b := by
    by_contra h
    replace h := lt_of_not_ge h
    refine H (cand a b hb ?_ ?_)
    · rw [abs_of_pos (by linarith)]; linarith
    · rw [abs_of_pos (by linarith)]; exact h
  have hC : 1 / (√5 * (d : ℝ) ^ 2) ≤ c / d - α := by
    by_contra h
    replace h := lt_of_not_ge h
    refine H (cand c d hd ?_ ?_)
    · rw [abs_sub_comm, abs_of_pos (by linarith)]; linarith
    · rw [abs_sub_comm, abs_of_pos (by linarith)]; exact h
  have hM : 1 / (√5 * ((b : ℝ) + d) ^ 2) ≤ |α - (a + c) / (b + d)| := by
    by_contra h
    replace h := lt_of_not_ge h
    have hq : 0 < b + d := by omega
    refine H (cand (a + c) (b + d) hq ?_ ?_)
    · push_cast
      rw [abs_sub_lt_iff]
      constructor <;> linarith
    · push_cast; exact h
  have P1 : (b : ℝ) ^ 2 + (d : ℝ) ^ 2 ≤ √5 * b * d :=
    hurwitz_sum √5 b d _ _ hw0 hB hD hA hC (by linarith)
  have hne : α ≠ ((a : ℝ) + c) / (b + d) := by
    have := hα.ne_rational (a + c) ((b + d : ℕ) : ℤ)
    push_cast at this
    exact this
  rcases lt_or_gt_of_ne hne with h | h
  · rw [abs_of_neg (by linarith)] at hM
    have P2 : (b : ℝ) ^ 2 + ((b : ℝ) + d) ^ 2 ≤ √5 * b * (b + d) :=
      hurwitz_sum √5 b (b + d) _ _ hw0 hB (by positivity) hA hM (by linarith)
    have hq := hurwitz_quad b d √5 hB hw P1 P2
    apply hurwitz_sqrt5_irrational.ne_rational (2 * d + b) b
    push_cast
    field_simp
    linarith
  · rw [abs_of_pos (by linarith)] at hM
    have P1' : (d : ℝ) ^ 2 + (b : ℝ) ^ 2 ≤ √5 * d * b := by linarith
    have P2 : (d : ℝ) ^ 2 + ((d : ℝ) + b) ^ 2 ≤ √5 * d * (d + b) := by
      have := hurwitz_sum √5 d (b + d) _ _ hw0 hD (by positivity) hC hM (by linarith)
      linarith
    have hq := hurwitz_quad d b √5 hD hw P1' P2
    apply hurwitz_sqrt5_irrational.ne_rational (2 * b + d) d
    push_cast
    field_simp
    linarith

lemma hurwitz_descent (α : ℝ) (hα : Irrational α) (n : ℕ) :
    ∃ (a c : ℤ) (b d : ℕ), 0 < b ∧ 0 < d ∧ (b : ℤ) * c - a * d = 1 ∧ (a : ℝ) / b < α ∧
      α < (c : ℝ) / d ∧ (n : ℝ) + 1 ≤ (b : ℝ) * d := by
  induction n with
  | zero =>
    refine ⟨⌊α⌋, ⌊α⌋ + 1, 1, 1, one_pos, one_pos, by ring, ?_, ?_, by norm_num⟩
    · simp only [Nat.cast_one, div_one]
      exact lt_of_le_of_ne (Int.floor_le α) (fun h => hα.ne_int ⌊α⌋ h.symm)
    · simp only [Nat.cast_one, div_one]
      push_cast
      exact Int.lt_floor_add_one α
  | succ n ih =>
    obtain ⟨a, c, b, d, hb, hd, hdet, hl, hr, hn⟩ := ih
    have hB : (1 : ℝ) ≤ b := by exact_mod_cast hb
    have hD : (1 : ℝ) ≤ d := by exact_mod_cast hd
    have hne : α ≠ ((a : ℝ) + c) / (b + d) := by
      have := hα.ne_rational (a + c) ((b + d : ℕ) : ℤ)
      push_cast at this
      exact this
    rcases lt_or_gt_of_ne hne with h | h
    · refine ⟨a, a + c, b, b + d, hb, by omega, ?_, hl, ?_, ?_⟩
      · push_cast; linear_combination hdet
      · push_cast; exact h
      · push_cast; nlinarith
    · refine ⟨a + c, c, b + d, d, by omega, hd, ?_, ?_, hr, ?_⟩
      · push_cast; linear_combination hdet
      · push_cast; exact h
      · push_cast; nlinarith

/-- Hurwitz's theorem. Every irrational number α has infinitely many fractions p/q (in lowest
terms, q = the bottom number) with |α − p/q| < 1/(√5 q²); and for the golden ratio
φ = (1 + √5)/2, no constant k bigger than √5 works: only finitely many fractions p/q have
|φ − p/q| < 1/(k q²). -/
theorem hurwitz_approximation_theorem :
    (∀ α : ℝ, Irrational α →
      {r : ℚ | |α - r| < 1 / (√5 * (r.den : ℝ) ^ 2)}.Infinite) ∧
    (∀ k : ℝ, √5 < k →
      {r : ℚ | |φ - r| < 1 / (k * (r.den : ℝ) ^ 2)}.Finite) := by
  constructor
  · intro α hα
    have close : ∀ ε : ℝ, 0 < ε → ∃ r ∈ {r : ℚ | |α - r| < 1 / (√5 * (r.den : ℝ) ^ 2)},
        |α - r| < ε := by
      intro ε hε
      obtain ⟨n, hn⟩ := exists_nat_one_div_lt hε
      obtain ⟨a, c, b, d, hb, hd, hdet, hl, hr, hbd⟩ := hurwitz_descent α hα n
      obtain ⟨r, hgood, hclose⟩ := hurwitz_no_triple α hα a c b d hb hd hdet hl hr
      refine ⟨r, hgood, lt_of_lt_of_le hclose ?_⟩
      have : 1 / ((b : ℝ) * d) ≤ 1 / ((n : ℝ) + 1) :=
        one_div_le_one_div_of_le (by positivity) hbd
      linarith
    refine Or.resolve_left (Set.finite_or_infinite _) fun h => ?_
    obtain ⟨r0, hr0, _⟩ := close 1 one_pos
    obtain ⟨q, hqS, hq⟩ := Set.exists_min_image _ (fun q : ℚ => |α - q|) h ⟨r0, hr0⟩
    have hpos : 0 < |α - q| := abs_pos.mpr (sub_ne_zero.mpr (hα.ne_rat q))
    obtain ⟨q', hq'S, hq'⟩ := close _ hpos
    exact lt_irrefl _ (lt_of_le_of_lt (hq q' hq'S) hq')
  · intro k hk
    have h5 : (2 : ℝ) < √5 := by
      rw [show (2 : ℝ) = √4 by rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]]
      exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
    have hk0 : 0 < k := by linarith
    set M : ℝ := 1 / (k * (k - √5)) with hMdef
    set N : ℕ := ⌈M⌉₊ with hNdef
    apply Set.Finite.subset (((Set.finite_Icc (-(3 * N : ℤ)) (3 * N)).prod
      (Set.finite_Iic N)).image (fun pq : ℤ × ℕ => (pq.1 : ℚ) / pq.2))
    intro r hr
    replace hr : |φ - r| < 1 / (k * (r.den : ℝ) ^ 2) := hr
    have hcast : (r : ℝ) = (r.num : ℝ) / (r.den : ℝ) := Rat.cast_def r
    have score := hurwitz_score_aux r.num r.den r.pos
    rw [← hcast] at score
    have hQ1 : (1 : ℝ) ≤ r.den := by exact_mod_cast r.pos
    set Q : ℝ := (r.den : ℝ) with hQdef
    set e : ℝ := |φ - r| with hedef
    have he0 : 0 ≤ e := abs_nonneg _
    have hQ0 : 0 < Q := by linarith
    rw [mul_div_cancel_left₀ _ (by positivity : Q ^ 2 ≠ 0)] at score
    rw [lt_div_iff₀ (by positivity)] at hr
    have hke : k * (Q ^ 2 * e) < 1 := by linarith
    have hs1 : k ≤ k * (Q ^ 2 * e) * (√5 + e) := by
      have := mul_le_mul_of_nonneg_left score hk0.le
      linarith
    have hs2 : k * (Q ^ 2 * e) * (√5 + e) < 1 * (√5 + e) :=
      mul_lt_mul_of_pos_right hke (by positivity)
    have hek : k - √5 < e := by linarith
    have hQM : Q ^ 2 < M := by
      rw [hMdef, lt_div_iff₀ (mul_pos hk0 (by linarith))]
      have hkQ : 0 < k * Q ^ 2 := by positivity
      nlinarith [mul_lt_mul_of_pos_left hek hkQ]
    have hQN : Q < N := by
      have : Q ≤ Q ^ 2 := by nlinarith
      have := Nat.le_ceil M
      linarith
    have hden : r.den ≤ N := by
      have : r.den < N := by rw [hQdef] at hQN; exact_mod_cast hQN
      omega
    have he1 : e < 1 := by
      have : 1 ≤ k * Q ^ 2 := by nlinarith
      nlinarith
    have hφ1 := one_lt_goldenRatio
    have hφ2 := goldenRatio_lt_two
    have hr03 := abs_sub_lt_iff.mp he1
    have hnum : (r.num : ℝ) = (r : ℝ) * Q := by
      rw [hcast]; field_simp
    have hnum1 : (0 : ℝ) ≤ r.num := by rw [hnum]; nlinarith
    have hnum2 : (r.num : ℝ) ≤ 3 * N := by rw [hnum]; nlinarith
    simp only [Set.mem_image, Set.mem_prod, Set.mem_Icc, Set.mem_Iic, Prod.exists]
    refine ⟨r.num, r.den, ⟨⟨?_, ?_⟩, hden⟩, Rat.num_div_den r⟩
    · have : (0 : ℤ) ≤ r.num := by exact_mod_cast hnum1
      omega
    · exact_mod_cast hnum2

/-- Step 4's key inequality. For any fraction p/q with q > 0, write the score
s = q² × |φ − p/q|. Since p² − pq − q² is a nonzero whole number, s × (√5 + s/q²) ≥ 1. -/
theorem golden_ratio_score_bound (p : ℤ) (q : ℕ) (hq : 0 < q) :
    1 ≤ ((q : ℝ) ^ 2 * |φ - (p : ℝ) / q|) *
      (√5 + ((q : ℝ) ^ 2 * |φ - (p : ℝ) / q|) / (q : ℝ) ^ 2) := by
  exact hurwitz_score_aux p q hq

/-- The golden ratio's stops are ratios of neighbouring Fibonacci numbers p/q, and for each
of them p² − pq − q² is exactly ±1, alternating in sign: −1 at 1/1, +1 at 2/1, −1 at 3/2, … -/
theorem golden_ratio_stops_norm (n : ℕ) :
    (Nat.fib (n + 2) : ℤ) ^ 2 - Nat.fib (n + 2) * Nat.fib (n + 1) - (Nat.fib (n + 1) : ℤ) ^ 2
      = (-1) ^ (n + 1) := by
  induction n with
  | zero => norm_num [Nat.fib]
  | succ n ih =>
    have h : Nat.fib (n + 3) = Nat.fib (n + 1) + Nat.fib (n + 2) := Nat.fib_add_two
    show (Nat.fib (n + 3) : ℤ) ^ 2 - Nat.fib (n + 3) * Nat.fib (n + 2) - (Nat.fib (n + 2) : ℤ) ^ 2
      = (-1) ^ (n + 2)
    rw [h]
    push_cast
    linear_combination (-1 : ℤ) * ih

-- The card's table: p² − pq − q² at the stops 1/1, 2/1, 3/2, 5/3, 8/5, 13/8, 21/13, 34/21.
example : (1 : ℤ) ^ 2 - 1 * 1 - 1 ^ 2 = -1 := by norm_num
example : (2 : ℤ) ^ 2 - 2 * 1 - 1 ^ 2 = 1 := by norm_num
example : (3 : ℤ) ^ 2 - 3 * 2 - 2 ^ 2 = -1 := by norm_num
example : (5 : ℤ) ^ 2 - 5 * 3 - 3 ^ 2 = 1 := by norm_num
example : (8 : ℤ) ^ 2 - 8 * 5 - 5 ^ 2 = -1 := by norm_num
example : (13 : ℤ) ^ 2 - 13 * 8 - 8 ^ 2 = 1 := by norm_num
example : (21 : ℤ) ^ 2 - 21 * 13 - 13 ^ 2 = -1 := by norm_num
example : (34 : ℤ) ^ 2 - 34 * 21 - 21 ^ 2 = 1 := by norm_num
-- The worked arithmetic: 64 − 40 − 25 = −1 at 8/5 and 169 − 104 − 64 = 1 at 13/8.
example : (64 : ℤ) - 40 - 25 = -1 ∧ (169 : ℤ) - 104 - 64 = 1 := by norm_num
-- These stops are ratios of Fibonacci numbers: fib 7 / fib 6 = 13/8 and fib 9 / fib 8 = 34/21.
example : Nat.fib 7 = 13 ∧ Nat.fib 6 = 8 ∧ Nat.fib 9 = 34 ∧ Nat.fib 8 = 21 := by decide

#print axioms hurwitz_sqrt5_irrational
#print axioms hurwitz_quad
#print axioms hurwitz_sum
#print axioms hurwitz_rat_of
#print axioms hurwitz_score_aux
#print axioms hurwitz_no_triple
#print axioms hurwitz_descent
#print axioms hurwitz_approximation_theorem
#print axioms golden_ratio_score_bound
#print axioms golden_ratio_stops_norm
