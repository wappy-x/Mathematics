-- Learning with a guarantee: a family of rules that labels no set of more than d points in every way gives any n points at most C(n,0) + ... + C(n,d) labellings, a finite family of rules lets a bad rule fit m fair samples with chance at most |H| e^(-εm), and price caps give n points exactly n + 1 labellings.
import Mathlib.Combinatorics.SetFamily.Shatter
import Mathlib.Data.Set.Card
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory
open scoped Classical

/-- The counting lemma (Sauer–Shelah), in the card's terms. A rule is the set of points it
approves. Suppose the family `H` labels no set of more than `d` points in every possible way:
whenever `H` shatters a finite set `s` (every subset `t` of `s` is exactly the part of `s`
approved by some rule), `s` has at most `d` points. Then on any `n` points `S` the family gives
at most `C(n,0) + C(n,1) + ... + C(n,d)` different labellings: `Π_H(n) ≤ ∑_{i ≤ d} C(n,i)`. -/
theorem growth_le_sum_choose_of_vc_le {X : Type*}
    (H : Set (Set X)) (d : ℕ)
    (hd : ∀ s : Finset X,
      (∀ t ⊆ s, ∃ h ∈ H, s.filter (fun x => x ∈ h) = t) → s.card ≤ d)
    (S : Finset X) :
    (Set.image (fun h : Set X => S.filter (fun x => x ∈ h)) H).ncard
      ≤ ∑ i ∈ Finset.range (d + 1), S.card.choose i := by
  set 𝒜 : Finset (Finset X) :=
    S.powerset.filter (fun t => ∃ h ∈ H, S.filter (fun x => x ∈ h) = t) with h𝒜
  have hset : Set.image (fun h : Set X => S.filter (fun x => x ∈ h)) H = (𝒜 : Set (Finset X)) := by
    ext t
    simp only [Set.mem_image, h𝒜, Finset.coe_filter, Finset.mem_powerset, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨h, hh, rfl⟩
      exact ⟨Finset.filter_subset _ _, h, hh, rfl⟩
    · rintro ⟨_, h, hh, rfl⟩
      exact ⟨h, hh, rfl⟩
  rw [hset, Set.ncard_coe_finset]
  refine (Finset.card_le_card_shatterer 𝒜).trans ?_
  have hsub : 𝒜.shatterer ⊆ (Finset.range (d + 1)).biUnion (fun i => S.powersetCard i) := by
    intro s hs
    rw [Finset.mem_shatterer] at hs
    have hsS : s ⊆ S := by
      obtain ⟨u, hu, hsu⟩ := hs.exists_superset
      rw [h𝒜, Finset.mem_filter, Finset.mem_powerset] at hu
      exact hsu.trans hu.1
    have hcard : s.card ≤ d := by
      apply hd
      intro t ht
      obtain ⟨u, hu, hsu⟩ := hs ht
      rw [h𝒜, Finset.mem_filter] at hu
      obtain ⟨_, h, hh, rfl⟩ := hu
      refine ⟨h, hh, ?_⟩
      rw [← hsu]
      ext x
      simp only [Finset.mem_filter, Finset.mem_inter]
      constructor
      · rintro ⟨hx, hxh⟩; exact ⟨hx, hsS hx, hxh⟩
      · rintro ⟨hx, _, hxh⟩; exact ⟨hx, hxh⟩
    rw [Finset.mem_biUnion]
    exact ⟨s.card, Finset.mem_range.2 (Nat.lt_succ_of_le hcard),
      Finset.mem_powersetCard.2 ⟨hsS, rfl⟩⟩
  refine (Finset.card_le_card hsub).trans ?_
  refine Finset.card_biUnion_le.trans ?_
  simp [Finset.card_powersetCard]

/-- The bound for a finite family (Step 2, by the union bound). Sales are drawn independently
from a mix `μ`; the council approves the set `T`; each rule `h` in the finite family `H`
approves a set, and its error is the chance `μ (h ∆ T)` that it disagrees with the council.
Then the chance that a log of `m` sales lets through some rule that fits every sale yet has
error more than `ε` is at most `|H| e^(-εm)`. -/
theorem finite_family_bad_rule_fits_le {X : Type*} [MeasurableSpace X]
    (μ : Measure X) [IsProbabilityMeasure μ] (T : Set X) (hT : MeasurableSet T)
    (H : Finset (Set X)) (hH : ∀ h ∈ H, MeasurableSet h) (ε : ℝ) (hε : 0 ≤ ε) (m : ℕ) :
    Measure.pi (fun _ : Fin m => μ)
        {S | ∃ h ∈ H, (∀ i, S i ∈ h ↔ S i ∈ T) ∧ ENNReal.ofReal ε < μ (symmDiff h T)}
      ≤ (H.card : ENNReal) * ENNReal.ofReal (Real.exp (-(ε * m))) := by
  set f : Set X → Set (Fin m → X) := fun h =>
    {S | (∀ i, S i ∈ h ↔ S i ∈ T) ∧ ENNReal.ofReal ε < μ (symmDiff h T)} with hf
  have hset : {S : Fin m → X | ∃ h ∈ H, (∀ i, S i ∈ h ↔ S i ∈ T) ∧
      ENNReal.ofReal ε < μ (symmDiff h T)} = ⋃ h ∈ H, f h := by
    ext S
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, hf, exists_prop]
  rw [hset]
  refine (measure_biUnion_finset_le H f).trans ?_
  rw [← nsmul_eq_mul]
  refine Finset.sum_le_card_nsmul _ _ _ ?_
  intro h hh
  by_cases hbad : ENNReal.ofReal ε < μ (symmDiff h T)
  · have hfh : f h = Set.pi Set.univ (fun _ : Fin m => {x | x ∈ h ↔ x ∈ T}) := by
      ext S
      simp [hf, hbad]
    have hA : {x | x ∈ h ↔ x ∈ T} = (symmDiff h T)ᶜ := by
      ext x
      simp only [Set.mem_compl_iff, Set.mem_symmDiff]
      simp only [Set.mem_ofPred_eq]
      tauto
    have hmeas : MeasurableSet (symmDiff h T) := (hH h hh).symmDiff hT
    have hε1 : ε < 1 := by
      by_contra hc
      rw [not_lt] at hc
      have : ENNReal.ofReal ε ≥ 1 := by
        rw [ge_iff_le, ← ENNReal.ofReal_one]; exact ENNReal.ofReal_le_ofReal hc
      exact absurd (hbad.trans_le prob_le_one) (not_lt.2 this)
    have hμA : μ {x | x ∈ h ↔ x ∈ T} ≤ ENNReal.ofReal (1 - ε) := by
      rw [hA, prob_compl_eq_one_sub hmeas, ENNReal.ofReal_sub _ hε, ENNReal.ofReal_one]
      exact tsub_le_tsub_left hbad.le _
    rw [hfh, Measure.pi_pi, Finset.prod_const, Finset.card_univ, Fintype.card_fin]
    calc μ {x | x ∈ h ↔ x ∈ T} ^ m ≤ ENNReal.ofReal (1 - ε) ^ m := by gcongr
      _ = ENNReal.ofReal ((1 - ε) ^ m) := (ENNReal.ofReal_pow (by linarith) m).symm
      _ ≤ ENNReal.ofReal (Real.exp (-(ε * m))) := by
        apply ENNReal.ofReal_le_ofReal
        rw [show -(ε * m) = (m : ℝ) * (-ε) by ring, Real.exp_nat_mul]
        apply pow_le_pow_left₀ (by linarith)
        linarith [Real.add_one_le_exp (-ε)]
  · have hfh : f h = ∅ := by
      ext S
      simp [hf, hbad]
    rw [hfh, measure_empty]
    exact zero_le

/-- The caps "approve when `x ≤ c`", one for each real `c`, give any `n` distinct quotes
exactly `n + 1` labellings: a cap approves some number of the cheapest quotes, from 0 to `n`,
and refuses the rest. -/
theorem caps_labellings_eq (S : Finset ℝ) :
    (Set.image (fun h : Set ℝ => S.filter (fun x => x ∈ h)) (Set.range Set.Iic)).ncard
      = S.card + 1 := by
  have hset : Set.image (fun h : Set ℝ => S.filter (fun x => x ∈ h)) (Set.range Set.Iic)
      = ((insert ∅ (S.image (fun y => S.filter (fun x => x ≤ y))) : Finset (Finset ℝ)) :
          Set (Finset ℝ)) := by
    ext t
    simp only [Set.mem_image, Set.mem_range, Finset.coe_insert, Finset.coe_image,
      Set.mem_insert_iff, Finset.mem_coe]
    constructor
    · rintro ⟨_, ⟨c, rfl⟩, rfl⟩
      simp only [Set.mem_Iic]
      by_cases hne : (S.filter (fun x => x ≤ c)).Nonempty
      · right
        set y := (S.filter (fun x => x ≤ c)).max' hne with hy
        have hyS : y ∈ S.filter (fun x => x ≤ c) := Finset.max'_mem _ hne
        refine ⟨y, (Finset.mem_filter.1 hyS).1, ?_⟩
        ext x
        simp only [Finset.mem_filter]
        constructor
        · rintro ⟨hx, hxy⟩; exact ⟨hx, hxy.trans (Finset.mem_filter.1 hyS).2⟩
        · rintro ⟨hx, hxc⟩; exact ⟨hx, Finset.le_max' _ x (Finset.mem_filter.2 ⟨hx, hxc⟩)⟩
      · left
        exact Finset.not_nonempty_iff_eq_empty.1 hne
    · rintro (rfl | ⟨y, _, rfl⟩)
      · obtain ⟨b, hb⟩ := S.bddBelow
        refine ⟨Set.Iic (b - 1), ⟨b - 1, rfl⟩, ?_⟩
        ext x
        simp only [Finset.mem_filter, Set.mem_Iic, Finset.notMem_empty, iff_false, not_and,
          not_le]
        intro hx
        have := hb hx
        linarith
      · exact ⟨Set.Iic y, ⟨y, rfl⟩, by simp⟩
  rw [hset, Set.ncard_coe_finset]
  have hnot : (∅ : Finset ℝ) ∉ S.image (fun y => S.filter (fun x => x ≤ y)) := by
    simp only [Finset.mem_image, not_exists, not_and]
    intro y hy h
    have : y ∈ S.filter (fun x => x ≤ y) := Finset.mem_filter.2 ⟨hy, le_rfl⟩
    rw [h] at this
    exact Finset.notMem_empty _ this
  rw [Finset.card_insert_of_notMem hnot, Finset.card_image_of_injOn]
  intro y hy z hz h
  simp only [Finset.mem_coe] at hy hz
  simp only at h
  have h1 : y ∈ S.filter (fun x => x ≤ z) := by
    rw [← h]; exact Finset.mem_filter.2 ⟨hy, le_rfl⟩
  have h2 : z ∈ S.filter (fun x => x ≤ y) := by
    rw [h]; exact Finset.mem_filter.2 ⟨hz, le_rfl⟩
  exact le_antisymm (Finset.mem_filter.1 h1).2 (Finset.mem_filter.1 h2).2

-- The ten-sale log in pence: six quotes at or below the cap of 3150 are approved.
example : ([2240, 3895, 2710, 3320, 3085, 2475, 3605, 2960, 3210, 2150].filter
    (fun p : ℕ => p ≤ 3150)).length = 6 := by decide
-- Highest approved 3085p, lowest refused 3210p.
example : ([2240, 3895, 2710, 3320, 3085, 2475, 3605, 2960, 3210, 2150].filter
    (fun p : ℕ => p ≤ 3150)).max? = some 3085 := by decide
example : ([2240, 3895, 2710, 3320, 3085, 2475, 3605, 2960, 3210, 2150].filter
    (fun p : ℕ => 3150 < p)).min? = some 3210 := by decide
-- Sauer's count on ten quotes: 11 labellings for caps (d = 1), 56 for bands (d = 2), of 1,024.
example : ∑ i ∈ Finset.range 2, Nat.choose 10 i = 11 := by decide
example : ∑ i ∈ Finset.range 3, Nat.choose 10 i = 56 := by decide
example : 2 ^ 10 = 1024 := by norm_num
-- Whole-penny caps from 2000p to 4000p: 2,001 rules.
example : (Finset.Icc 2000 4000).card = 2001 := by simp
-- The general VC bound needs m ≥ 8/ε: 160 sales at ε = 1/20; at m = 726, Π(2m) = 2m + 1 = 1,453.
example : (8 : ℚ) / (1 / 20) = 160 := by norm_num
example : 2 * 726 + 1 = 1453 := by norm_num
-- Exact chance 2(1 - ε)^m - (1 - 2ε)^m at ε = 1/20: at most 1/100 at 104 sales, above it at 103.
example : 2 * (19 / 20 : ℚ) ^ 104 - (9 / 10 : ℚ) ^ 104 ≤ 1 / 100 := by norm_num
example : 1 / 100 < 2 * (19 / 20 : ℚ) ^ 103 - (9 / 10 : ℚ) ^ 103 := by norm_num
-- Guarding one strip only, ln(1/δ)/ε asks for 93 sales, where the true chance is above 1/100.
example : 1 / 100 < 2 * (19 / 20 : ℚ) ^ 93 - (9 / 10 : ℚ) ^ 93 := by norm_num

#print axioms growth_le_sum_choose_of_vc_le
#print axioms finite_family_bad_rule_fits_le
#print axioms caps_labellings_eq
