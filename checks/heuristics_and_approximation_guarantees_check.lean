-- Heuristics with a promise: greedy covering by cheapest fee per new genre costs at most H(s) ≤ 1 + ln n times any covering lineup, genre prices that overprice no act are a floor under every (even fractional) lineup, and a two-opt move that uncrosses two crossing legs never lengthens a round in the plane.
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Affine.Convex
import Mathlib.Tactic.NormNum

namespace GreedyCover

variable {α ι K : Type*} [DecidableEq α] [DecidableEq ι]

/-- The genres of act `j` still open after the acts in `booked` have been booked. -/
def openGenres (E : ι → Finset α) (booked : List ι) (j : ι) : Finset α :=
  E j \ booked.toFinset.biUnion E

/-- A lineup `T` covers every genre: each genre is played by at least one booked act. -/
def IsCover [Fintype α] (E : ι → Finset α) (T : Finset ι) : Prop :=
  ∀ e : α, ∃ j ∈ T, e ∈ E j

/-- `picks` is a run of greedy covering: at every step the booked act covers at least one
open genre, and its fee per newly covered genre is the least among all acts that still
cover an open genre (ties may go any way); when the run ends, every genre is covered. -/
def IsGreedyRun [Fintype α] [Fintype ι] [Field K] [LinearOrder K]
    (E : ι → Finset α) (c : ι → K) (picks : List ι) : Prop :=
  (∀ k (hk : k < picks.length),
    (openGenres E (picks.take k) picks[k]).Nonempty ∧
    ∀ j, (openGenres E (picks.take k) j).Nonempty →
      c picks[k] / ((openGenres E (picks.take k) picks[k]).card : K) ≤
        c j / ((openGenres E (picks.take k) j).card : K)) ∧
  ∀ e : α, ∃ j ∈ picks, e ∈ E j

/-- The harmonic numbers, cast to the reals, never decrease. -/
theorem harmonic_real_mono {a b : ℕ} (h : a ≤ b) : (harmonic a : ℝ) ≤ harmonic b := by
  have : harmonic a ≤ harmonic b := by
    unfold harmonic
    apply Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_subset_range.mpr h)
    intro i _ _
    positivity
  exact_mod_cast this

#print axioms harmonic_real_mono

/-- Charging step: if `r * a ≤ q` with `r ≥ 0` and `b ≤ a`, then
`r * (a - b) ≤ q * (H a - H b)`. -/
theorem harmonic_charge (r q : ℝ) (hr : 0 ≤ r) (b : ℕ) :
    ∀ a, b ≤ a → r * a ≤ q → r * ((a : ℝ) - b) ≤ q * ((harmonic a : ℝ) - harmonic b) := by
  intro a hab
  induction a, hab using Nat.le_induction with
  | base => intro _; simp
  | succ n hbn ih =>
    intro hq
    push_cast at hq
    have hq' : r * n ≤ q := by nlinarith
    have h1 := ih hq'
    have hn : (0 : ℝ) < n + 1 := by positivity
    have h2 : r ≤ q * ((n : ℝ) + 1)⁻¹ := by
      rw [← div_eq_mul_inv, le_div_iff₀ hn]; linarith
    rw [harmonic_succ]
    push_cast
    nlinarith

#print axioms harmonic_charge

/-- A greedy run can be checked in whole numbers when every fee is a whole number over a
common positive denominator `D`. -/
theorem isGreedyRun_of_nat [Fintype α] [Fintype ι] (E : ι → Finset α) (a : ι → ℕ)
    (D : ℚ) (hD : 0 < D) (picks : List ι)
    (h1 : ∀ k (hk : k < picks.length),
      (openGenres E (picks.take k) picks[k]).Nonempty ∧
      ∀ j, (openGenres E (picks.take k) j).Nonempty →
        a picks[k] * (openGenres E (picks.take k) j).card ≤
          a j * (openGenres E (picks.take k) picks[k]).card)
    (h2 : ∀ e : α, ∃ j ∈ picks, e ∈ E j) :
    IsGreedyRun E (fun j => (a j : ℚ) / D) picks := by
  refine ⟨fun k hk => ⟨(h1 k hk).1, fun j hj => ?_⟩, h2⟩
  have hp := Finset.card_pos.mpr (h1 k hk).1
  have hjp := Finset.card_pos.mpr hj
  have hn := (h1 k hk).2 j hj
  have hm : (0 : ℚ) < (openGenres E (picks.take k) picks[k]).card := by exact_mod_cast hp
  have hj' : (0 : ℚ) < (openGenres E (picks.take k) j).card := by exact_mod_cast hjp
  have hnq : (a picks[k] : ℚ) * (openGenres E (picks.take k) j).card ≤
      (a j : ℚ) * (openGenres E (picks.take k) picks[k]).card := by exact_mod_cast hn
  simp only
  rw [div_div, div_div, div_le_div_iff₀ (by positivity) (by positivity)]
  nlinarith

#print axioms isGreedyRun_of_nat

/-- **The greedy promise.** Take any covering problem: genres `α` (there are `n` of them),
acts `ι`, act `j` playing the genres `E j` for a fee `c j ≥ 0`. Let greedy book, step by
step, an act of least fee per newly covered genre, until every genre is covered. Then
greedy's bill is at most `H(s)` times the bill of every lineup that covers every genre
(so at most `H(s) · OPT`), where `s` is the most genres any one act plays and
`H(s) = 1 + 1/2 + … + 1/s`; and `H(s) · OPT ≤ (1 + ln n) · OPT`. -/
theorem greedy_cover_within_harmonic_of_cheapest [Fintype α] [Fintype ι]
    (E : ι → Finset α) (c : ι → ℝ) (hc : ∀ j, 0 ≤ c j)
    (picks : List ι) (hgreedy : IsGreedyRun E c picks)
    (T : Finset ι) (hT : IsCover E T) :
    (picks.map c).sum ≤
        (harmonic (Finset.univ.sup fun j => (E j).card) : ℝ) * ∑ j ∈ T, c j ∧
      (harmonic (Finset.univ.sup fun j => (E j).card) : ℝ) * ∑ j ∈ T, c j ≤
        (1 + Real.log (Fintype.card α)) * ∑ j ∈ T, c j := by
  have hTnonneg : 0 ≤ ∑ j ∈ T, c j := Finset.sum_nonneg fun j _ => hc j
  refine ⟨?_, ?_⟩
  · obtain ⟨hstep, -⟩ := hgreedy
    let C : ℕ → Finset α := fun k => (picks.take k).toFinset.biUnion E
    let Φ : ℕ → ℝ := fun k => ∑ j ∈ T, c j * (harmonic (E j \ C k).card : ℝ)
    have key : ∀ k ≤ picks.length, ((picks.take k).map c).sum ≤ Φ 0 - Φ k := by
      intro k
      induction k with
      | zero => intro _; simp
      | succ k ih =>
        intro hk
        have hk' : k < picks.length := hk
        have ih := ih (by omega)
        rw [List.take_succ_eq_append_getElem hk', List.map_append, List.sum_append]
        simp only [List.map_cons, List.map_nil, List.sum_cons, List.sum_nil, add_zero]
        suffices h : c picks[k] ≤ Φ k - Φ (k + 1) by linarith
        obtain ⟨hne, hmin⟩ := hstep k hk'
        have hC : C (k + 1) = C k ∪ E picks[k] := by
          simp only [C]
          rw [List.take_succ_eq_append_getElem hk', List.toFinset_append]
          simp [Finset.union_comm]
        change (E picks[k] \ C k).Nonempty at hne
        set p := picks[k]
        set m := (E p \ C k).card with hm
        have hmpos : (0 : ℝ) < m := by exact_mod_cast Finset.card_pos.mpr hne
        set r := c p / m with hr
        have hr0 : 0 ≤ r := div_nonneg (hc p) hmpos.le
        have hrm : r * m = c p := by rw [hr]; field_simp
        have hjr : ∀ j ∈ T, r * ((E j \ C k).card : ℝ) ≤ c j := by
          intro j _
          by_cases hj : (E j \ C k).Nonempty
          · have hjpos : (0 : ℝ) < (E j \ C k).card := by exact_mod_cast Finset.card_pos.mpr hj
            have := hmin j hj
            exact (le_div_iff₀ hjpos).mp this
          · rw [Finset.not_nonempty_iff_eq_empty.mp hj]; simp [hc j]
        have hcard : ∀ j, (E j \ (C k ∪ E p)).card + ((E j \ C k) ∩ E p).card
            = (E j \ C k).card := by
          intro j
          have hset : E j \ (C k ∪ E p) = (E j \ C k) \ E p := by
            ext e; simp only [Finset.mem_sdiff, Finset.mem_union]; tauto
          rw [hset]
          exact Finset.card_sdiff_add_card_inter _ _
        have hcov : m ≤ ∑ j ∈ T, ((E j \ C k) ∩ E p).card := by
          refine le_trans (Finset.card_le_card ?_) Finset.card_biUnion_le
          intro e he
          obtain ⟨j, hjT, hej⟩ := hT e
          rw [Finset.mem_sdiff] at he
          rw [Finset.mem_biUnion]
          exact ⟨j, hjT, by simp [hej, he.1, he.2]⟩
        have hcovR : (m : ℝ) ≤ ∑ j ∈ T, (((E j \ C k).card : ℝ) - (E j \ (C k ∪ E p)).card) := by
          have : (m : ℝ) ≤ ∑ j ∈ T, (((E j \ C k) ∩ E p).card : ℝ) := by exact_mod_cast hcov
          refine this.trans (le_of_eq (Finset.sum_congr rfl fun j _ => ?_))
          have := hcard j
          rw [← this]; push_cast; ring
        calc c p = r * m := hrm.symm
          _ ≤ r * ∑ j ∈ T, (((E j \ C k).card : ℝ) - (E j \ (C k ∪ E p)).card) :=
            mul_le_mul_of_nonneg_left hcovR hr0
          _ = ∑ j ∈ T, r * (((E j \ C k).card : ℝ) - (E j \ (C k ∪ E p)).card) :=
            Finset.mul_sum _ _ _
          _ ≤ ∑ j ∈ T, c j * ((harmonic (E j \ C k).card : ℝ) -
                harmonic (E j \ (C k ∪ E p)).card) := by
            apply Finset.sum_le_sum
            intro j hj
            exact harmonic_charge r (c j) hr0 _ _ (by have := hcard j; omega) (hjr j hj)
          _ = Φ k - Φ (k + 1) := by
            simp only [Φ, hC, ← Finset.sum_sub_distrib, mul_sub]
    have h1 := key picks.length le_rfl
    rw [List.take_length] at h1
    have hΦn : 0 ≤ Φ picks.length := by
      apply Finset.sum_nonneg
      intro j _
      have := harmonic_real_mono (Nat.zero_le (E j \ C picks.length).card)
      simp only [harmonic_zero, Rat.cast_zero] at this
      exact mul_nonneg (hc j) this
    have hΦ0 : Φ 0 ≤ (harmonic (Finset.univ.sup fun j => (E j).card) : ℝ) * ∑ j ∈ T, c j := by
      simp only [Φ, C, List.take_zero, List.toFinset_nil, Finset.biUnion_empty,
        Finset.sdiff_empty]
      rw [Finset.mul_sum]
      apply Finset.sum_le_sum
      intro j _
      rw [mul_comm (c j)]
      apply mul_le_mul_of_nonneg_right _ (hc j)
      exact harmonic_real_mono (Finset.le_sup (f := fun j => (E j).card) (Finset.mem_univ j))
    linarith
  · apply mul_le_mul_of_nonneg_right _ hTnonneg
    have hs : (Finset.univ.sup fun j => (E j).card) ≤ Fintype.card α :=
      Finset.sup_le fun j _ => Finset.card_le_univ (E j)
    exact (harmonic_real_mono hs).trans (harmonic_le_one_add_log _)

/-- **Prices that overprice no act are a floor (weak LP duality).** Give every genre a price
`y e ≥ 0` so that no act's genres are priced above its fee: `∑_{e ∈ E j} y e ≤ c j`.
Then the prices add up to at most the bill of every lineup, even a fractional one that
books act `j` to the extent `x j ≥ 0` with every genre booked at least once in total. -/
theorem dual_prices_floor_every_lineup [Fintype α] [Fintype ι]
    (E : ι → Finset α) (c : ι → ℝ) (y : α → ℝ) (hy : ∀ e, 0 ≤ y e)
    (hfit : ∀ j, ∑ e ∈ E j, y e ≤ c j)
    (x : ι → ℝ) (hx : ∀ j, 0 ≤ x j)
    (hcover : ∀ e, 1 ≤ ∑ j ∈ Finset.univ.filter (fun j => e ∈ E j), x j) :
    ∑ e, y e ≤ ∑ j, c j * x j := by
  calc ∑ e, y e ≤ ∑ e, y e * ∑ j ∈ Finset.univ.filter (fun j => e ∈ E j), x j := by
        apply Finset.sum_le_sum
        intro e _
        nlinarith [hy e, hcover e]
    _ = ∑ j, x j * ∑ e ∈ E j, y e := by
        simp only [Finset.mul_sum, Finset.sum_filter]
        rw [Finset.sum_comm]
        apply Finset.sum_congr rfl
        intro j _
        simp only [mul_ite, mul_zero]
        rw [← Finset.sum_filter, Finset.filter_mem_eq_inter, Finset.univ_inter]
        simp [mul_comm]
    _ ≤ ∑ j, c j * x j := by
        apply Finset.sum_le_sum
        intro j _
        rw [mul_comm (c j)]
        exact mul_le_mul_of_nonneg_left (hfit j) (hx j)

/-- **Uncrossing two legs never lengthens the round.** With straight-line distances in the
plane, if leg `u–u'` and leg `v–v'` cross at a point `X`, then the two-opt move that
replaces them by `u–v` and `u'–v'` changes the length by
`Δ = d(u,v) + d(u',v') - d(u,u') - d(v,v') ≤ 0`. -/
theorem two_opt_uncrossing_does_not_lengthen (u u' v v' X : EuclideanSpace ℝ (Fin 2))
    (hX₁ : X ∈ segment ℝ u u') (hX₂ : X ∈ segment ℝ v v') :
    dist u v + dist u' v' - dist u u' - dist v v' ≤ 0 := by
  have h1 := dist_add_dist_of_mem_segment hX₁
  have h2 := dist_add_dist_of_mem_segment hX₂
  have h3 := dist_triangle u X v
  have h4 := dist_triangle u' X v'
  rw [dist_comm X u'] at h1
  rw [dist_comm v X] at h2
  linarith

/-! ### The festival: genres rock, pop, folk, jazz, soul, indie, techno, hip-hop, reggae,
metal are `0, …, 9`; acts P, Q, R, S, T, U, V are `0, …, 6`; fees in £ thousand. -/

/-- The genres each act plays. -/
def festE : Fin 7 → Finset (Fin 10) :=
  ![{0, 1, 2, 3, 4}, {5, 6, 7, 8, 9}, {0, 1, 2, 5, 6, 7}, {3, 4}, {8, 9}, {2, 3, 8}, {1, 9}]

/-- The fees: P 50, Q 50, R 54, S 30, T 36, U 40, V 28. -/
def festC : Fin 7 → ℚ := ![50, 50, 54, 30, 36, 40, 28]

/-- Greedy books R, then S, then T. -/
example : IsGreedyRun festE festC [2, 3, 4] := by
  have h : festC = fun j => ((![50, 50, 54, 30, 36, 40, 28] : Fin 7 → ℕ) j : ℚ) / 1 := by
    funext j; fin_cases j <;> simp [festC]
  rw [h]
  exact isGreedyRun_of_nat _ _ 1 one_pos _ (by decide) (by decide)

/-- Greedy's bill: 54 + 30 + 36 = 120. -/
example : ([2, 3, 4].map festC).sum = 120 := by
  simp [festC]; norm_num

/-- P with Q covers every genre for 100. -/
example : IsCover festE {0, 1} ∧ ∑ j ∈ ({0, 1} : Finset (Fin 7)), festC j = 100 := by
  refine ⟨by unfold IsCover; decide, ?_⟩
  simp [festC]; norm_num

/-- Every one of the 128 lineups that covers every genre costs at least 100. -/
example : ∀ T : Finset (Fin 7), IsCover festE T → 100 ≤ ∑ j ∈ T, festC j := by
  have h : festC = fun j => ((![50, 50, 54, 30, 36, 40, 28] : Fin 7 → ℕ) j : ℚ) := by
    funext j; fin_cases j <;> simp [festC]
  have hn : ∀ T : Finset (Fin 7), IsCover festE T →
      100 ≤ ∑ j ∈ T, (![50, 50, 54, 30, 36, 40, 28] : Fin 7 → ℕ) j := by
    unfold IsCover
    set_option maxRecDepth 100000 in decide
  intro T hT
  rw [h]
  have := hn T hT
  rw [← Nat.cast_sum]
  exact_mod_cast this

/-- The dual certificate: rock, pop, folk, indie, techno, hip-hop at 9, the rest at 23/2;
no act is overpriced and the prices add to 100. -/
example :
    (∀ j, ∑ e ∈ festE j, (![9, 9, 9, 23/2, 23/2, 9, 9, 9, 23/2, 23/2] : Fin 10 → ℚ) e ≤ festC j) ∧
      ∑ e, (![9, 9, 9, 23/2, 23/2, 9, 9, 9, 23/2, 23/2] : Fin 10 → ℚ) e = 100 := by
  refine ⟨fun j => ?_, ?_⟩
  · fin_cases j <;> simp [festE, festC, Finset.sum_insert] <;> norm_num
  · simp [Fin.sum_univ_succ]; norm_num

/-- The most genres one act plays is s = 6, and H(6) = 49/20 (2.450), H(10) = 7381/2520. -/
example : (Finset.univ.sup fun j => (festE j).card) = 6 ∧
    harmonic 6 = 49 / 20 ∧ harmonic 10 = 7381 / 2520 := by
  refine ⟨by decide, ?_, ?_⟩ <;> simp [harmonic, Finset.sum_range_succ] <;> norm_num

/-- Greedy's raw prices overcharge act P: 9 + 9 + 9 + 15 + 15 = 57 > 50. -/
example : (54 / 6 + 54 / 6 + 54 / 6 + 30 / 2 + 30 / 2 : ℚ) = 57 ∧ (57 : ℚ) > festC 0 := by
  simp [festC]; norm_num

/-! ### The near-tight family: solo act `i` (`i = 1, …, 10`, index `i - 1`) plays genre `i`
alone for `60 / i`; the big act (index 10) plays all ten genres for 61. -/

/-- The genres of the near-tight family. -/
def tightE (j : Fin 11) : Finset (Fin 10) :=
  if h : j.val < 10 then {⟨j.val, h⟩} else Finset.univ

/-- The fees of the near-tight family. -/
def tightC (j : Fin 11) : ℚ :=
  if j.val < 10 then 60 / (j.val + 1 : ℚ) else 61

/-- Greedy books the solo acts from genre 10 down to genre 1, for 60 · H(10) = 7381/42,
against the best bill of 61 (the big act alone). -/
example : IsGreedyRun tightE tightC [9, 8, 7, 6, 5, 4, 3, 2, 1, 0] ∧
    ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0].map tightC).sum = 7381 / 42 ∧
    (7381 / 42 : ℚ) = 60 * harmonic 10 ∧ IsCover tightE {10} ∧ tightC 10 = 61 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · have h : tightC = fun j => ((fun j : Fin 11 =>
        if j.val < 10 then 151200 / (j.val + 1) else 153720) j : ℚ) / 2520 := by
      funext j; fin_cases j <;> simp [tightC] <;> norm_num
    rw [h]
    exact isGreedyRun_of_nat _ _ 2520 (by norm_num) _ (by decide) (by decide)
  · simp [tightC]; norm_num
  · simp [harmonic, Finset.sum_range_succ]; norm_num
  · unfold IsCover; decide
  · simp [tightC]

#print axioms greedy_cover_within_harmonic_of_cheapest
#print axioms dual_prices_floor_every_lineup
#print axioms two_opt_uncrossing_does_not_lengthen

end GreedyCover
