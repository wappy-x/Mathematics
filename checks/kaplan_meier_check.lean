-- Kaplan-Meier: the product-limit curve comes from the record's best-fitting relapse chances (maximum likelihood), and Efron's redistribute-to-the-right gives the same curve.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic

/-! A patient's record is a pair `(c, e)`: the last month `c` the patient was watched, and
`e = true` for a relapse seen at month `c`, `e = false` for a dropout at month `c`.
Time is counted in whole months from joining (month 0).

* `atRisk recs s` is `r`: the patients still watched and relapse-free just before month `s`,
  that is, whose record ends at month `s` or later. A dropout counts in every `r` up to and
  including its own month.
* `relapses recs s` is `d`: the relapses seen at month `s`. A dropout is never counted here.
* `kmEstimate recs t` is `Ŝ(t)`, the product over months `s ≤ t` of `1 - d/r`. A month with no
  relapse has factor `1` (Lean's `0 / 0 = 0` covers months with nobody at risk), so this is the
  card's product over relapse months.
* `likelihood recs h` is the record's chance when a patient at risk relapses at month `s` with
  chance `h s`: a patient who relapses at `c` gets through months `0 … c-1` and then relapses;
  a patient who drops out at `c` gets through months `0 … c`. Under independent censoring the
  dropout-time chances form a separate factor with no `h` in it, so they are left out.
* `efronSurvival` is Efron's redistribute-to-the-right: every patient starts with share `1/n`;
  in record order, a relapse spends its share, and a dropout splits its share equally among
  the patients after it. The estimate at `t` is one minus the shares spent by month `t`. -/

namespace KaplanMeier

/-- Patients at risk just before month `s`: records ending at month `s` or later. -/
def atRisk (recs : List (ℕ × Bool)) (s : ℕ) : ℕ :=
  (recs.filter (fun p => decide (s ≤ p.1))).length

/-- Relapses seen at month `s`. -/
def relapses (recs : List (ℕ × Bool)) (s : ℕ) : ℕ :=
  (recs.filter (fun p => decide (p.1 = s) && p.2)).length

/-- The Kaplan-Meier estimate `Ŝ(t) = ∏_{s ≤ t} (1 - d_s / r_s)`. -/
noncomputable def kmEstimate (recs : List (ℕ × Bool)) (t : ℕ) : ℝ :=
  ∏ s ∈ Finset.range (t + 1), (1 - (relapses recs s : ℝ) / (atRisk recs s : ℝ))

/-- Greenwood's running sum `∑_{s ≤ t} d_s / (r_s (r_s - d_s))`. -/
noncomputable def greenwoodSum (recs : List (ℕ × Bool)) (t : ℕ) : ℝ :=
  ∑ s ∈ Finset.range (t + 1),
    (relapses recs s : ℝ) / ((atRisk recs s : ℝ) * ((atRisk recs s : ℝ) - relapses recs s))

/-- The record's chance when the chance of relapsing at month `s`, for a patient at risk,
is `h s`. -/
noncomputable def likelihood (recs : List (ℕ × Bool)) (h : ℕ → ℝ) : ℝ :=
  (recs.map fun p =>
    (∏ s ∈ Finset.range p.1, (1 - h s)) * (if p.2 then h p.1 else 1 - h p.1)).prod

/-- Efron's redistribute-to-the-right, run over records `(c, e, share)` in order:
returns the total share spent by relapses at or before month `t`. -/
noncomputable def efronSpent (t : ℕ) : List (ℕ × Bool × ℝ) → ℝ
  | [] => 0
  | (c, e, w) :: rest =>
    if e then (if c ≤ t then w else 0) + efronSpent t rest
    else efronSpent t (rest.map fun p => (p.1, p.2.1, p.2.2 + w / rest.length))
termination_by l => l.length
decreasing_by all_goals simp

/-- Efron's estimate at month `t`: every patient starts with share `1/n`, and the estimate is
one minus the shares spent by month `t`. -/
noncomputable def efronSurvival (recs : List (ℕ × Bool)) (t : ℕ) : ℝ :=
  1 - efronSpent t (recs.map fun p => (p.1, p.2, 1 / (recs.length : ℝ)))

/-- Records listed in time order, with a relapse listed before a dropout in the same month
(the card's rule: the relapse is counted first). -/
def InRecordOrder (recs : List (ℕ × Bool)) : Prop :=
  recs.Pairwise fun a b => a.1 < b.1 ∨ (a.1 = b.1 ∧ (a.2 = true ∨ b.2 = false))

/-! Helper lemmas for the proofs below. -/

theorem atRisk_cons (c : ℕ) (e : Bool) (l : List (ℕ × Bool)) (s : ℕ) :
    atRisk ((c, e) :: l) s = (if s ≤ c then 1 else 0) + atRisk l s := by
  unfold atRisk
  rw [List.filter_cons]
  split_ifs <;> simp_all <;> omega

#print axioms atRisk_cons

theorem relapses_cons (c : ℕ) (e : Bool) (l : List (ℕ × Bool)) (s : ℕ) :
    relapses ((c, e) :: l) s = (if c = s ∧ e = true then 1 else 0) + relapses l s := by
  unfold relapses
  rw [List.filter_cons]
  split_ifs <;> simp_all <;> omega

#print axioms relapses_cons

theorem relapses_le_atRisk (l : List (ℕ × Bool)) (s : ℕ) : relapses l s ≤ atRisk l s := by
  induction l with
  | nil => simp [relapses, atRisk]
  | cons p l ih =>
    obtain ⟨c, e⟩ := p
    rw [relapses_cons, atRisk_cons]
    split_ifs <;> omega

#print axioms relapses_le_atRisk

theorem relapses_eq_zero (l : List (ℕ × Bool)) (s : ℕ)
    (hl : ∀ p ∈ l, p.1 = s → p.2 = false) : relapses l s = 0 := by
  unfold relapses
  rw [List.length_eq_zero_iff, List.filter_eq_nil_iff]
  intro p hp
  have := hl p hp
  cases hp2 : p.2 <;> simp_all

#print axioms relapses_eq_zero

theorem atRisk_eq_length (l : List (ℕ × Bool)) (s : ℕ)
    (hl : ∀ p ∈ l, s ≤ p.1) : atRisk l s = l.length := by
  unfold atRisk
  rw [List.filter_eq_self.mpr]
  intro p hp
  simpa using hl p hp

#print axioms atRisk_eq_length

theorem km_cons_false (c : ℕ) (rest : List (ℕ × Bool)) (t : ℕ)
    (hrest : ∀ p ∈ rest, c < p.1 ∨ (c = p.1 ∧ p.2 = false)) :
    kmEstimate ((c, false) :: rest) t = kmEstimate rest t := by
  unfold kmEstimate
  apply Finset.prod_congr rfl
  intro s _
  rw [relapses_cons, atRisk_cons]
  by_cases hs : s ≤ c
  · have h0 : relapses rest s = 0 := by
      apply relapses_eq_zero
      intro p hp hps
      rcases hrest p hp with h | h
      · omega
      · exact h.2
    simp [h0]
  · simp [hs]

#print axioms km_cons_false

theorem km_cons_true (c : ℕ) (rest : List (ℕ × Bool)) (t : ℕ)
    (hrest : ∀ p ∈ rest, c ≤ p.1) :
    ((rest.length : ℝ) + 1) * kmEstimate ((c, true) :: rest) t =
      (if c ≤ t then 0 else 1) + (rest.length : ℝ) * kmEstimate rest t := by
  have hlow : ∀ s, s < c → relapses rest s = 0 := by
    intro s hs
    apply relapses_eq_zero
    intro p hp hps
    have := hrest p hp
    omega
  have hother : ∀ s, s ≠ c →
      (1 - (relapses ((c, true) :: rest) s : ℝ) / (atRisk ((c, true) :: rest) s : ℝ)) =
        (1 - (relapses rest s : ℝ) / (atRisk rest s : ℝ)) := by
    intro s hs
    rw [relapses_cons, atRisk_cons]
    rcases lt_or_gt_of_ne hs with h | h
    · have hcs : c ≠ s := by omega
      simp [hlow s h, hcs]
    · have h1 : ¬ s ≤ c := by omega
      have hcs : c ≠ s := by omega
      simp [h1, hcs]
  unfold kmEstimate
  split_ifs with hct
  · have hmem : c ∈ Finset.range (t + 1) := Finset.mem_range.2 (by omega)
    rw [← Finset.mul_prod_erase _ _ hmem, ← Finset.mul_prod_erase _ _ hmem]
    rw [Finset.prod_congr rfl (fun s hs => hother s (Finset.ne_of_mem_erase hs))]
    rw [relapses_cons, atRisk_cons, atRisk_eq_length rest c hrest]
    have hle := relapses_le_atRisk rest c
    rw [atRisk_eq_length rest c hrest] at hle
    simp only [le_refl, if_true, and_self]
    set D := relapses rest c
    set m := rest.length
    rcases Nat.eq_zero_or_pos m with hm | hm
    · have hD : D = 0 := by omega
      rw [hm, hD]; simp
    · have hm' : (0 : ℝ) < m := by exact_mod_cast hm
      push_cast
      field_simp
      ring
  · have h1 : ∀ s ∈ Finset.range (t + 1),
        (1 - (relapses ((c, true) :: rest) s : ℝ) / (atRisk ((c, true) :: rest) s : ℝ)) = 1 := by
      intro s hs
      have hs' : s < c := by simp at hs; omega
      rw [hother s (by omega), hlow s hs']
      simp
    have h2 : ∀ s ∈ Finset.range (t + 1),
        (1 - (relapses rest s : ℝ) / (atRisk rest s : ℝ)) = 1 := by
      intro s hs
      have hs' : s < c := by simp at hs; omega
      rw [hlow s hs']
      simp
    rw [Finset.prod_eq_one h1, Finset.prod_eq_one h2]
    ring

#print axioms km_cons_true

theorem efron_uniform (t : ℕ) (l : List (ℕ × Bool)) :
    ∀ w : ℝ, InRecordOrder l →
      efronSpent t (l.map fun p => (p.1, p.2, w)) = w * l.length * (1 - kmEstimate l t) := by
  induction l with
  | nil =>
    intro w _
    simp [efronSpent]
  | cons p rest ih =>
    intro w hord
    obtain ⟨c, e⟩ := p
    unfold InRecordOrder at hord
    rw [List.pairwise_cons] at hord
    obtain ⟨hhead, hrest⟩ := hord
    cases e with
    | true =>
      rw [List.map_cons, efronSpent]
      simp only [if_true]
      rw [ih w hrest]
      have key := km_cons_true c rest t (fun q hq => by
        rcases hhead q hq with h | h
        · exact h.le
        · exact h.1.le)
      simp only [List.length_cons]
      push_cast
      split_ifs at key ⊢ <;> linear_combination w * key
    | false =>
      rw [List.map_cons, efronSpent]
      simp only [Bool.false_eq_true, if_false, List.map_map, List.length_map]
      have hk := km_cons_false c rest t (fun q hq => by
        rcases hhead q hq with h | h
        · exact Or.inl h
        · right
          refine ⟨h.1, ?_⟩
          rcases h.2 with h' | h'
          · simp at h'
          · exact h')
      have := ih (w + w / rest.length) hrest
      simp only [Function.comp_def] at this ⊢
      rw [this, hk]
      simp only [List.length_cons]
      rcases Nat.eq_zero_or_pos rest.length with hm | hm
      · rw [List.length_eq_zero_iff.mp hm]
        simp [kmEstimate, relapses, atRisk]
      · have hm' : (0 : ℝ) < rest.length := by exact_mod_cast hm
        push_cast
        field_simp

#print axioms efron_uniform

theorem binomial_lt_aux (d r : ℕ) (hd : 0 < d) (hdr : d < r)
    (h : ℝ) (h0 : 0 ≤ h) (h1 : h ≤ 1) (hne : h ≠ (d : ℝ) / r) :
    h ^ d * (1 - h) ^ (r - d) < ((d : ℝ) / r) ^ d * (1 - (d : ℝ) / r) ^ (r - d) := by
  have hr : (0 : ℝ) < r := by exact_mod_cast (lt_trans hd hdr)
  have hd' : (0 : ℝ) < d := by exact_mod_cast hd
  have hdr' : (d : ℝ) < r := by exact_mod_cast hdr
  have ha0 : 0 < (d : ℝ) / r := div_pos hd' hr
  have ha1 : (d : ℝ) / r < 1 := (div_lt_one hr).2 hdr'
  have hb0 : 0 < 1 - (d : ℝ) / r := by linarith
  have hm0 : 0 < r - d := by omega
  have hRHS : 0 < ((d : ℝ) / r) ^ d * (1 - (d : ℝ) / r) ^ (r - d) :=
    mul_pos (pow_pos ha0 _) (pow_pos hb0 _)
  rcases eq_or_lt_of_le h0 with h0' | h0'
  · rw [← h0', zero_pow hd.ne', zero_mul]
    exact hRHS
  rcases eq_or_lt_of_le h1 with h1' | h1'
  · rw [h1', sub_self, zero_pow hm0.ne', mul_zero]
    exact hRHS
  have hc0 : 0 < 1 - h := by linarith
  have hL : 0 < h ^ d * (1 - h) ^ (r - d) := mul_pos (pow_pos h0' _) (pow_pos hc0 _)
  rw [← Real.log_lt_log_iff hL hRHS]
  rw [Real.log_mul (pow_pos h0' _).ne' (pow_pos hc0 _).ne',
    Real.log_mul (pow_pos ha0 _).ne' (pow_pos hb0 _).ne',
    Real.log_pow, Real.log_pow, Real.log_pow, Real.log_pow]
  have hq : h / ((d : ℝ) / r) ≠ 1 := by
    intro hq
    rw [div_eq_one_iff_eq ha0.ne'] at hq
    exact hne hq
  have k1 := Real.log_lt_sub_one_of_pos (div_pos h0' ha0) hq
  have k2 := Real.log_le_sub_one_of_pos (div_pos hc0 hb0)
  rw [Real.log_div h0'.ne' ha0.ne'] at k1
  rw [Real.log_div hc0.ne' hb0.ne'] at k2
  have hcast : ((r - d : ℕ) : ℝ) = (r : ℝ) - d := by
    rw [Nat.cast_sub hdr.le]
  have e1 : (d : ℝ) * (h / ((d : ℝ) / r) - 1) +
      ((r - d : ℕ) : ℝ) * ((1 - h) / (1 - (d : ℝ) / r) - 1) = 0 := by
    rw [hcast]
    have hrd : (r : ℝ) - d ≠ 0 := by linarith
    field_simp
    ring
  have hm' : (0 : ℝ) ≤ ((r - d : ℕ) : ℝ) := by positivity
  nlinarith [mul_lt_mul_of_pos_left k1 hd', mul_le_mul_of_nonneg_left k2 hm']

#print axioms binomial_lt_aux

theorem factor_le_at_ratio (d r : ℕ) (hdr : d ≤ r) (x : ℝ) (h0 : 0 ≤ x) (h1 : x ≤ 1) :
    x ^ d * (1 - x) ^ (r - d) ≤ ((d : ℝ) / r) ^ d * (1 - (d : ℝ) / r) ^ (r - d) := by
  rcases Nat.eq_zero_or_pos d with hd | hd
  · subst hd
    simp only [pow_zero, one_mul, Nat.cast_zero, zero_div, sub_zero, one_pow, Nat.sub_zero]
    exact pow_le_one₀ (by linarith) (by linarith)
  rcases eq_or_lt_of_le hdr with hdr' | hdr'
  · subst hdr'
    have hr : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
    simp only [Nat.sub_self, pow_zero, mul_one, div_self hr, one_pow]
    exact pow_le_one₀ h0 h1
  by_cases hx : x = (d : ℝ) / r
  · rw [hx]
  · exact (binomial_lt_aux d r hd hdr' x h0 h1 hx).le

#print axioms factor_le_at_ratio

theorem likelihood_eq_prod (h : ℕ → ℝ) (N : ℕ) (l : List (ℕ × Bool))
    (hl : ∀ p ∈ l, p.1 < N) :
    likelihood l h = ∏ s ∈ Finset.range N,
      h s ^ relapses l s * (1 - h s) ^ (atRisk l s - relapses l s) := by
  induction l with
  | nil => simp [likelihood, relapses, atRisk]
  | cons p l ih =>
    obtain ⟨c, e⟩ := p
    have hcN : c < N := hl (c, e) (by simp)
    have ih' := ih (fun q hq => hl q (by simp [hq]))
    have hll : likelihood ((c, e) :: l) h =
        ((∏ s ∈ Finset.range c, (1 - h s)) * (if e then h c else 1 - h c)) * likelihood l h := by
      simp [likelihood]
    rw [hll, ih']
    set g : ℕ → ℝ := fun s =>
      if s < c then 1 - h s else if s = c then (if e then h c else 1 - h c) else 1 with hg
    have key : ∀ s ∈ Finset.range N,
        h s ^ relapses ((c, e) :: l) s * (1 - h s) ^ (atRisk ((c, e) :: l) s -
          relapses ((c, e) :: l) s) =
        g s * (h s ^ relapses l s * (1 - h s) ^ (atRisk l s - relapses l s)) := by
      intro s _
      have hle := relapses_le_atRisk l s
      rw [relapses_cons, atRisk_cons, hg]
      rcases lt_trichotomy s c with hs | hs | hs
      · have e1 : c ≠ s := by omega
        have e2 : s ≤ c := hs.le
        simp only [e1, false_and, if_false, e2, if_true, hs, zero_add]
        rw [show 1 + atRisk l s - relapses l s = (atRisk l s - relapses l s) + 1 by omega,
          pow_succ]
        ring
      · subst hs
        cases e
        · simp only [Bool.false_eq_true, and_false, if_false, le_refl, if_true, lt_irrefl,
            zero_add]
          rw [show 1 + atRisk l s - relapses l s = (atRisk l s - relapses l s) + 1 by omega,
            pow_succ]
          ring
        · simp only [and_self, if_true, le_refl, lt_irrefl, if_false]
          rw [show 1 + atRisk l s - (1 + relapses l s) = atRisk l s - relapses l s by omega,
            pow_add]
          ring
      · have e1 : c ≠ s := by omega
        have e2 : ¬ s ≤ c := by omega
        have e3 : ¬ s < c := by omega
        have e4 : s ≠ c := by omega
        simp only [e1, false_and, if_false, e2, e3, e4, zero_add, one_mul]
    have hgprod : ∏ s ∈ Finset.range N, g s =
        (∏ s ∈ Finset.range c, (1 - h s)) * (if e then h c else 1 - h c) := by
      have hsub : Finset.range (c + 1) ⊆ Finset.range N := by
        intro s hs; simp at hs ⊢; omega
      rw [← Finset.prod_subset hsub (fun s _ hs => by
        simp at hs
        have e3 : ¬ s < c := by omega
        have e4 : s ≠ c := by omega
        simp [hg, e3, e4])]
      rw [Finset.prod_range_succ]
      congr 1
      · apply Finset.prod_congr rfl
        intro s hs
        simp at hs
        simp [hg, hs]
      · simp [hg]
    rw [Finset.prod_congr rfl key, Finset.prod_mul_distrib (f := g), hgprod]

#print axioms likelihood_eq_prod

theorem exists_bound (l : List (ℕ × Bool)) : ∃ N, ∀ p ∈ l, p.1 < N := by
  induction l with
  | nil => exact ⟨0, by simp⟩
  | cons p l ih =>
    obtain ⟨N, hN⟩ := ih
    refine ⟨max (p.1 + 1) N, ?_⟩
    intro q hq
    rcases List.mem_cons.1 hq with h | h
    · subst h; omega
    · have := hN q h; omega

#print axioms exists_bound

/-- The Kaplan-Meier curve is the maximum-likelihood estimate: for any record with dropouts,
and any choice of monthly relapse chances `h` between 0 and 1, the record is at most as
probable under `h` as under the chances `d/r` that the Kaplan-Meier curve multiplies. -/
theorem kaplan_meier_is_maximum_likelihood (recs : List (ℕ × Bool)) (h : ℕ → ℝ)
    (h0 : ∀ s, 0 ≤ h s) (h1 : ∀ s, h s ≤ 1) :
    likelihood recs h ≤
      likelihood recs (fun s => (relapses recs s : ℝ) / (atRisk recs s : ℝ)) := by
  obtain ⟨N, hN⟩ := exists_bound recs
  rw [likelihood_eq_prod h N recs hN, likelihood_eq_prod _ N recs hN]
  apply Finset.prod_le_prod₀
  · intro s _
    exact mul_nonneg (pow_nonneg (h0 s) _) (pow_nonneg (sub_nonneg.2 (h1 s)) _)
  · intro s _
    exact factor_le_at_ratio _ _ (relapses_le_atRisk recs s) (h s) (h0 s) (h1 s)

/-- One relapse month's factor `h^d (1-h)^(r-d)`, the binomial shape, has its unique maximum
at `h = d/r` when `0 < d < r`: any other chance between 0 and 1 gives a strictly smaller
value. -/
theorem binomial_factor_unique_max_at_ratio (d r : ℕ) (hd : 0 < d) (hdr : d < r)
    (h : ℝ) (h0 : 0 ≤ h) (h1 : h ≤ 1) (hne : h ≠ (d : ℝ) / r) :
    h ^ d * (1 - h) ^ (r - d) < ((d : ℝ) / r) ^ d * (1 - (d : ℝ) / r) ^ (r - d) := by
  exact binomial_lt_aux d r hd hdr h h0 h1 hne

/-- A second road: Efron's redistribute-to-the-right gives the same curve as the
Kaplan-Meier product at every month, for records in time order with each month's relapses
listed before its dropouts. -/
theorem redistribute_to_the_right_eq_kaplan_meier (recs : List (ℕ × Bool))
    (hord : InRecordOrder recs) (t : ℕ) :
    efronSurvival recs t = kmEstimate recs t := by
  unfold efronSurvival
  rw [efron_uniform t recs _ hord]
  rcases Nat.eq_zero_or_pos recs.length with hm | hm
  · rw [List.length_eq_zero_iff.mp hm]
    simp [kmEstimate, relapses, atRisk]
  · have hm' : (0 : ℝ) < recs.length := by exact_mod_cast hm
    field_simp
    ring

/-! The card's twelve-patient trial: relapses at 3, 5, 5, 8, 11, 14, 20 months;
dropouts at 4, 8, 12, 16, 24 months. -/

/-- The trial's records, in record order. -/
def trial : List (ℕ × Bool) :=
  [(3, true), (4, false), (5, true), (5, true), (8, true), (8, false), (11, true),
   (12, false), (14, true), (16, false), (20, true), (24, false)]

-- The table's at-risk counts and relapse counts.
example : atRisk trial 3 = 12 ∧ atRisk trial 5 = 10 ∧ atRisk trial 8 = 8 ∧
    atRisk trial 11 = 6 ∧ atRisk trial 14 = 4 ∧ atRisk trial 20 = 2 := by decide
example : relapses trial 5 = 2 ∧ relapses trial 8 = 1 ∧ relapses trial 4 = 0 := by decide
example : InRecordOrder trial := by unfold InRecordOrder trial; decide

-- S(14) = 77/192 (0.401042) and S(20) = 77/384 (0.200521).
example : kmEstimate trial 14 = 77 / 192 := by
  simp [kmEstimate, atRisk, relapses, trial, Finset.prod_range_succ]
  norm_num
example : kmEstimate trial 20 = 77 / 384 := by
  simp [kmEstimate, atRisk, relapses, trial, Finset.prod_range_succ]
  norm_num
-- The hand product at month 14.
example : (11 / 12 : ℝ) * (8 / 10) * (7 / 8) * (5 / 6) * (3 / 4) = 77 / 192 := by norm_num

-- Greenwood sum at month 14: 1/132 + 2/80 + 1/56 + 1/30 + 1/12.
example : greenwoodSum trial 14 = 1 / 132 + 2 / 80 + 1 / 56 + 1 / 30 + 1 / 12 := by
  simp [greenwoodSum, atRisk, relapses, trial, Finset.sum_range_succ]
  norm_num

-- Wrong: dropouts counted as relapses, S(14) = 1/4.
example : kmEstimate (trial.map fun p => (p.1, true)) 14 = 1 / 4 := by
  simp [kmEstimate, atRisk, relapses, trial, Finset.prod_range_succ]
  norm_num
-- Wrong: dropouts deleted, S(14) = 1/7 (0.142857).
example : kmEstimate (trial.filter fun p => p.2) 14 = 1 / 7 := by
  simp [kmEstimate, atRisk, relapses, trial, Finset.prod_range_succ]
  norm_num
-- Wrong: no clock, 5 of 12 never seen to relapse (0.416667).
example : (trial.filter fun p => !p.2).length = 5 ∧ trial.length = 12 := by decide
-- Try: the month-4 dropout relapses instead, S(14) = 35/96 (0.364583).
example : kmEstimate ((3, true) :: (4, true) :: trial.drop 2) 14 = 35 / 96 := by
  simp [kmEstimate, atRisk, relapses, trial, Finset.prod_range_succ]
  norm_num

#print axioms kaplan_meier_is_maximum_likelihood
#print axioms binomial_factor_unique_max_at_ratio
#print axioms redistribute_to_the_right_eq_kaplan_meier

end KaplanMeier
