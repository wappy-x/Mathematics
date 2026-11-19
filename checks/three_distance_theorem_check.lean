-- Three distances: hits placed at {nα} for n = 0, …, N − 1 with α irrational cut the loop into gaps of at most three lengths u, v and u + v, set by the bars a and b that land closest after and before the downbeat, and the golden step's Fibonacci bars land exactly φ^(−k) from a whole loop.
import Mathlib.NumberTheory.Real.GoldenRatio
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.LinearCombination

open Real

/-- The gap after the hit of bar n, when bars 0, 1, …, N − 1 have put their hits at
{0·α}, {1·α}, …, {(N − 1)·α} on a loop of length 1: the distance forward round the loop
to the nearest other hit. Going forward from {nα} to {mα} covers {(m − n)α} of the loop. -/
noncomputable def gapAfter (α : ℝ) (N n : ℕ) : ℝ :=
  sInf ((fun m : ℕ => Int.fract (((m : ℝ) - n) * α)) '' {m : ℕ | m < N ∧ m ≠ n})

/-- Helper: with α irrational, the offsets sα for different whole numbers s have
different fractional parts. -/
theorem fract_int_mul_injective {α : ℝ} (hα : Irrational α) {s t : ℤ}
    (h : Int.fract ((s : ℝ) * α) = Int.fract ((t : ℝ) * α)) : s = t := by
  rcases Int.fract_eq_fract.1 h with ⟨z, hz⟩
  by_contra hst
  have hne : s - t ≠ 0 := sub_ne_zero.2 hst
  have hirr := hα.intCast_mul hne
  apply hirr.ne_int z
  rw [← hz]; push_cast; ring

#print axioms fract_int_mul_injective

/-- Helper: subtracting a smaller fractional part. -/
theorem fract_sub_of_le {x y : ℝ} (h : Int.fract y ≤ Int.fract x) :
    Int.fract (x - y) = Int.fract x - Int.fract y := by
  rw [Int.fract_eq_iff]
  refine ⟨by linarith, by linarith [Int.fract_lt_one x, Int.fract_nonneg y], ⌊x⌋ - ⌊y⌋, ?_⟩
  simp only [Int.fract]; push_cast; ring

#print axioms fract_sub_of_le

/-- Helper: subtracting a larger fractional part. -/
theorem fract_sub_of_lt {x y : ℝ} (h : Int.fract x < Int.fract y) :
    Int.fract (x - y) = Int.fract x - Int.fract y + 1 := by
  rw [Int.fract_eq_iff]
  refine ⟨by linarith [Int.fract_lt_one y, Int.fract_nonneg x], by linarith, ⌊x⌋ - ⌊y⌋ - 1, ?_⟩
  simp only [Int.fract]; push_cast; ring

#print axioms fract_sub_of_lt

/-- Helper: the gap after a hit is c when c is one of the forward distances and no
forward distance is smaller. -/
theorem gapAfter_eq_of {α : ℝ} {N n : ℕ} {c : ℝ}
    (hmem : ∃ m : ℕ, m < N ∧ m ≠ n ∧ Int.fract ((((m : ℤ) - n : ℤ) : ℝ) * α) = c)
    (hlow : ∀ m : ℕ, m < N → m ≠ n → c ≤ Int.fract ((((m : ℤ) - n : ℤ) : ℝ) * α)) :
    gapAfter α N n = c := by
  unfold gapAfter
  apply IsLeast.csInf_eq
  constructor
  · obtain ⟨m, hm, hmn, hc⟩ := hmem
    refine ⟨m, ⟨hm, hmn⟩, ?_⟩
    simpa using hc
  · rintro x ⟨m, ⟨hm, hmn⟩, rfl⟩
    simpa using hlow m hm hmn

#print axioms gapAfter_eq_of

/-- Helper: the neighbour rule, proved here so the three-distance theorem can use it. -/
theorem gapAfter_neighbour_rule_aux {α : ℝ} (hα : Irrational α) {N a b : ℕ} (hN : 2 ≤ N)
    (ha : 1 ≤ a ∧ a < N) (ha_min : ∀ k, 1 ≤ k → k < N → Int.fract ((a : ℝ) * α) ≤ Int.fract ((k : ℝ) * α))
    (hb : 1 ≤ b ∧ b < N) (hb_max : ∀ k, 1 ≤ k → k < N → Int.fract ((k : ℝ) * α) ≤ Int.fract ((b : ℝ) * α))
    {n : ℕ} (hn : n < N) :
    gapAfter α N n =
      if n + a < N then Int.fract ((a : ℝ) * α)
      else if b ≤ n then 1 - Int.fract ((b : ℝ) * α)
      else Int.fract ((a : ℝ) * α) + (1 - Int.fract ((b : ℝ) * α)) := by
  have hinj : ∀ s t : ℤ, Int.fract ((s : ℝ) * α) = Int.fract ((t : ℝ) * α) → s = t :=
    fun s t h => fract_int_mul_injective hα h
  have hcastd : ∀ d : ℤ, 0 ≤ d → ((d.toNat : ℕ) : ℝ) = (d : ℝ) := by
    intro d hd
    rw [← Int.cast_natCast, Int.toNat_of_nonneg hd]
  have hmin : ∀ d : ℤ, 1 ≤ d → d < N →
      Int.fract (((a : ℤ) : ℝ) * α) ≤ Int.fract ((d : ℝ) * α) := by
    intro d h1 h2
    have h := ha_min d.toNat (by omega) (by omega)
    rw [hcastd d (by omega)] at h
    simpa only [Int.cast_natCast] using h
  have hmax : ∀ d : ℤ, 1 ≤ d → d < N →
      Int.fract ((d : ℝ) * α) ≤ Int.fract (((b : ℤ) : ℝ) * α) := by
    intro d h1 h2
    have h := hb_max d.toNat (by omega) (by omega)
    rw [hcastd d (by omega)] at h
    simpa only [Int.cast_natCast] using h
  have hpos : ∀ s : ℤ, s ≠ 0 → 0 < Int.fract ((s : ℝ) * α) := by
    intro s hs
    rcases (Int.fract_nonneg ((s : ℝ) * α)).lt_or_eq with h | h
    · exact h
    · exfalso
      apply hs
      apply hinj s 0
      simp only [Int.cast_zero, zero_mul, Int.fract_zero]
      exact h.symm
  have hneg : ∀ s : ℤ, s ≠ 0 →
      Int.fract (((-s : ℤ) : ℝ) * α) = 1 - Int.fract ((s : ℝ) * α) := by
    intro s hs
    rw [show (((-s : ℤ) : ℝ) * α) = -((s : ℝ) * α) by push_cast; ring]
    exact Int.fract_neg (hpos s hs).ne'
  have hsub_le : ∀ s t : ℤ, Int.fract ((t : ℝ) * α) ≤ Int.fract ((s : ℝ) * α) →
      Int.fract (((s - t : ℤ) : ℝ) * α) = Int.fract ((s : ℝ) * α) - Int.fract ((t : ℝ) * α) := by
    intro s t h
    rw [show (((s - t : ℤ) : ℝ) * α) = (s : ℝ) * α - (t : ℝ) * α by push_cast; ring]
    exact fract_sub_of_le h
  have hsub_lt : ∀ s t : ℤ, Int.fract ((s : ℝ) * α) < Int.fract ((t : ℝ) * α) →
      Int.fract (((s - t : ℤ) : ℝ) * α) = Int.fract ((s : ℝ) * α) - Int.fract ((t : ℝ) * α) + 1 := by
    intro s t h
    rw [show (((s - t : ℤ) : ℝ) * α) = (s : ℝ) * α - (t : ℝ) * α by push_cast; ring]
    exact fract_sub_of_lt h
  rw [← Int.cast_natCast a, ← Int.cast_natCast b]
  split_ifs with h1 h2
  · -- the next hit is bar n + a
    apply gapAfter_eq_of
    · refine ⟨n + a, h1, by omega, ?_⟩
      rw [show (((n + a : ℕ) : ℤ) - (n : ℤ)) = (a : ℤ) by push_cast; ring]
    · intro m hm hmn
      rcases lt_or_gt_of_ne (show (m : ℤ) - n ≠ 0 by omega) with hs | hs
      · by_contra hlt
        rw [not_le] at hlt
        have e := hsub_le (a : ℤ) ((m : ℤ) - n) hlt.le
        have h3 := hmin ((a : ℤ) - ((m : ℤ) - n)) (by omega) (by omega)
        have h4 := hpos ((m : ℤ) - n) (by omega)
        linarith
      · exact hmin _ (by omega) (by omega)
  · -- the next hit is bar n - b
    apply gapAfter_eq_of
    · refine ⟨n - b, by omega, by omega, ?_⟩
      rw [show (((n - b : ℕ) : ℤ) - (n : ℤ)) = -(b : ℤ) by omega]
      exact hneg _ (by omega)
    · intro m hm hmn
      rcases lt_or_gt_of_ne (show (m : ℤ) - n ≠ 0 by omega) with hs | hs
      · have e := hneg (-((m : ℤ) - n)) (by omega)
        rw [neg_neg] at e
        have h3 := hmax (-((m : ℤ) - n)) (by omega) (by omega)
        linarith
      · by_contra hlt
        rw [not_le] at hlt
        have eb := hneg (b : ℤ) (by omega)
        have e := hsub_lt ((m : ℤ) - n) (-(b : ℤ)) (by linarith)
        have h3 := hmax ((m : ℤ) - n - -(b : ℤ)) (by omega) (by omega)
        have h4 := hpos ((m : ℤ) - n) (by omega)
        linarith
  · -- the next hit is bar n + a - b
    have hab : a ≠ b := by
      intro hab
      subst hab
      rcases Nat.lt_or_ge a 2 with ha2 | ha2
      · omega
      · have h3 := hmin 1 le_rfl (by omega)
        have h4 := hmax 1 le_rfl (by omega)
        have := hinj 1 (a : ℤ) (le_antisymm h4 h3)
        omega
    have hablt : Int.fract (((a : ℤ) : ℝ) * α) < Int.fract (((b : ℤ) : ℝ) * α) := by
      refine lt_of_le_of_ne (hmax (a : ℤ) (by omega) (by omega)) ?_
      intro h
      exact hab (by exact_mod_cast hinj _ _ h)
    apply gapAfter_eq_of
    · refine ⟨n + a - b, by omega, by omega, ?_⟩
      rw [show (((n + a - b : ℕ) : ℤ) - (n : ℤ)) = (a : ℤ) - (b : ℤ) by omega,
        hsub_lt _ _ hablt]
      ring
    · intro m hm hmn
      rcases lt_or_gt_of_ne (show (m : ℤ) - n ≠ 0 by omega) with hs | hs
      · have e := hneg (-((m : ℤ) - n)) (by omega)
        rw [neg_neg] at e
        have h3 := hmax (-((m : ℤ) - n)) (by omega) (by omega)
        have eb := hneg (b : ℤ) (by omega)
        have e2 := hsub_le ((m : ℤ) - n) (-(b : ℤ)) (by linarith)
        have h5 := hmin ((m : ℤ) - n - -(b : ℤ)) (by omega) (by omega)
        linarith
      · have e := hsub_le ((m : ℤ) - n) (a : ℤ) (hmin _ (by omega) (by omega))
        have e2 := hneg ((a : ℤ) - ((m : ℤ) - n)) (by omega)
        rw [show -((a : ℤ) - ((m : ℤ) - n)) = (m : ℤ) - n - (a : ℤ) by ring] at e2
        have h3 := hmax ((a : ℤ) - ((m : ℤ) - n)) (by omega) (by omega)
        linarith

#print axioms gapAfter_neighbour_rule_aux

/-- The three-distance theorem. Step round a loop by one fixed irrational amount α, putting
hits at {nα} for n = 0, 1, …, N − 1 (with at least two hits). Then every gap between a hit
and the next one has one of at most three lengths, u, v or u + v, with u and v positive:
the longest length is the sum of the other two. -/
theorem three_distance_theorem {α : ℝ} (hα : Irrational α) {N : ℕ} (hN : 2 ≤ N) :
    ∃ u v : ℝ, 0 < u ∧ 0 < v ∧
      ∀ n < N, gapAfter α N n = u ∨ gapAfter α N n = v ∨ gapAfter α N n = u + v := by
  have hne : (Finset.Ico 1 N).Nonempty := ⟨1, by simp; omega⟩
  obtain ⟨a, haS, ha⟩ :=
    Finset.exists_min_image (Finset.Ico 1 N) (fun k : ℕ => Int.fract ((k : ℝ) * α)) hne
  obtain ⟨b, hbS, hb⟩ :=
    Finset.exists_max_image (Finset.Ico 1 N) (fun k : ℕ => Int.fract ((k : ℝ) * α)) hne
  simp only [Finset.mem_Ico] at haS hbS ha hb
  refine ⟨Int.fract ((a : ℝ) * α), 1 - Int.fract ((b : ℝ) * α), ?_, ?_, ?_⟩
  · rcases (Int.fract_nonneg ((a : ℝ) * α)).lt_or_eq with h | h
    · exact h
    · exfalso
      have := fract_int_mul_injective hα (s := (a : ℤ)) (t := 0)
        (by simp only [Int.cast_natCast, Int.cast_zero, zero_mul, Int.fract_zero]; exact h.symm)
      omega
  · linarith [Int.fract_lt_one ((b : ℝ) * α)]
  · intro n hn
    rw [gapAfter_neighbour_rule_aux hα hN haS (fun k h1 h2 => ha k ⟨h1, h2⟩) hbS
      (fun k h1 h2 => hb k ⟨h1, h2⟩) hn]
    split_ifs
    · exact Or.inl rfl
    · exact Or.inr (Or.inl rfl)
    · exact Or.inr (Or.inr rfl)

/-- The neighbour rule. Among bars 1 to N − 1, let bar a land closest after the downbeat,
at u = {aα}, and bar b land closest before it, at v = 1 − {bα}. Then the gap after the hit
of bar n is u when n < N − a, v when n ≥ b, and u + v otherwise. So there are N − a gaps
of length u, N − b of length v and a + b − N of length u + v. -/
theorem gapAfter_eq_neighbour_rule {α : ℝ} (hα : Irrational α) {N a b : ℕ} (hN : 2 ≤ N)
    (ha : 1 ≤ a ∧ a < N) (ha_min : ∀ k, 1 ≤ k → k < N → Int.fract ((a : ℝ) * α) ≤ Int.fract ((k : ℝ) * α))
    (hb : 1 ≤ b ∧ b < N) (hb_max : ∀ k, 1 ≤ k → k < N → Int.fract ((k : ℝ) * α) ≤ Int.fract ((b : ℝ) * α))
    {n : ℕ} (hn : n < N) :
    gapAfter α N n =
      if n + a < N then Int.fract ((a : ℝ) * α)
      else if b ≤ n then 1 - Int.fract ((b : ℝ) * α)
      else Int.fract ((a : ℝ) * α) + (1 - Int.fract ((b : ℝ) * α)) := by
  exact gapAfter_neighbour_rule_aux hα hN ha ha_min hb hb_max hn

/-- The golden step's closest returns. With the step α = φ − 1 and the Fibonacci numbers
F_1 = F_2 = 1, F_3 = 2, …, the Fibonacci bar F_k lands exactly φ^(−k) from the whole number
F_(k−1): F_k α − F_(k−1) = −(−1)^k φ^(−k), after it when k is odd and before it when k is even. -/
theorem fib_mul_golden_step_sub_fib {k : ℕ} (hk : 1 ≤ k) :
    (Nat.fib k : ℝ) * (goldenRatio - 1) - (Nat.fib (k - 1) : ℝ) = -(-1) ^ k * (goldenRatio⁻¹) ^ k := by
  obtain ⟨n, rfl⟩ : ∃ n, k = n + 1 := ⟨k - 1, by omega⟩
  have h1 := goldenConj_mul_fib_succ_add_fib n
  have h2 : goldenRatio - 1 = -goldenConj := by linarith [goldenRatio_add_goldenConj]
  have h3 : (-goldenConj) ^ (n + 1) = (-1) ^ (n + 1) * goldenConj ^ (n + 1) := neg_pow _ _
  rw [inv_goldenRatio, Nat.add_sub_cancel, h2, h3, ← h1]
  have : ((-1 : ℝ) ^ (n + 1)) * (-1) ^ (n + 1) = 1 := by
    rw [← mul_pow]; norm_num
  linear_combination (goldenConj * (Nat.fib (n+1) : ℝ) + Nat.fib n) * this

-- The sequencer rounded to its 16-step grid, a step of 10/16 of the loop: 10 hits land on
-- only 8 places (positions counted in sixteenths of the loop).
example : ((Finset.range 10).image (fun n => n * 10 % 16)).card = 8 := by decide

-- N = 10 hits, with a = 5 and b = 8: F_6 = 8 < 10 ≤ 13 = F_7, a + b = 13 ≥ 10, and the counts
-- N − a = 5, N − b = 2, a + b − N = 3 cover all 10 gaps.
example : Nat.fib 6 = 8 ∧ Nat.fib 7 = 13 := by decide
example : 10 ≤ 5 + 8 ∧ (10 - 5) + (10 - 8) + (5 + 8 - 10) = 10 := by norm_num

-- The Farey check at N = 10: p = 3, r = 5, and a r − b p = 5 × 5 − 8 × 3 = 1; for the golden
-- step this is Cassini's identity F_7 F_5 − F_6² = (−1)^6.
example : (5 : ℤ) * 5 - 8 * 3 = 1 := by norm_num
example : (Nat.fib 7 : ℤ) * Nat.fib 5 - (Nat.fib 6 : ℤ) ^ 2 = (-1) ^ 6 := by decide

-- Only two lengths show exactly at a Fibonacci number of hits: up to 100 these are
-- 2, 3, 5, 8, 13, 21, 34, 55 and 89.
example : (List.range 9).map (fun i => Nat.fib (i + 3)) = [2, 3, 5, 8, 13, 21, 34, 55, 89] := by decide

#print axioms three_distance_theorem
#print axioms gapAfter_eq_neighbour_rule
#print axioms fib_mul_golden_step_sub_fib
