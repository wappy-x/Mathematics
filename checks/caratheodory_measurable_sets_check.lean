-- Caratheodory's criterion: for any outer measure, the sets that split every test set with no loss form a sigma-algebra on which outer measure adds up countably, and for Lebesgue outer measure on the line every interval, every set of size zero and every Borel set passes.
import Mathlib.MeasureTheory.OuterMeasure.Caratheodory
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open Set MeasureTheory ENNReal Function

/-- The card's splitting test: `E` passes for the outer measure `μ` when every test set `T`
is cut by `E` into a part inside and a part outside whose sizes add up to exactly `μ T`. -/
def CaratheodoryMeasurable {Ω : Type*} (μ : Set Ω → ℝ≥0∞) (E : Set Ω) : Prop :=
  ∀ T : Set Ω, μ T = μ (T ∩ E) + μ (T ∩ Eᶜ)

/-- Lebesgue outer measure, as on the Outer measure card: over every list `(c k, d k)` of open
intervals whose union contains `A`, take the total length `∑ (d k - c k)`, and take the
infimum of those totals. -/
noncomputable def lambdaStar (A : Set ℝ) : ℝ≥0∞ :=
  ⨅ (c : ℕ → ℝ) (d : ℕ → ℝ) (_ : A ⊆ ⋃ k, Ioo (c k) (d k)), ∑' k, ENNReal.ofReal (d k - c k)


/-- Lebesgue measure of any set is at most `lambdaStar` of it. -/
theorem volume_le_lambdaStar (A : Set ℝ) : volume A ≤ lambdaStar A := by
  unfold lambdaStar
  refine le_iInf fun c => le_iInf fun d => le_iInf fun hA => ?_
  calc volume A ≤ volume (⋃ k, Ioo (c k) (d k)) := measure_mono hA
    _ ≤ ∑' k, volume (Ioo (c k) (d k)) := measure_iUnion_le _
    _ = ∑' k, ENNReal.ofReal (d k - c k) := by simp [Real.volume_Ioo]

/-- `lambdaStar` of any set is at most its Lebesgue measure. -/
theorem lambdaStar_le_volume (A : Set ℝ) : lambdaStar A ≤ volume A := by
  have hv : volume A = StieltjesFunction.id.outer A := by
    rw [Real.volume_eq_stieltjes_id, StieltjesFunction.measure]
    rfl
  rw [hv, StieltjesFunction.outer, OuterMeasure.ofFunction_apply]
  refine le_iInf fun t => le_iInf fun ht => ?_
  refine ENNReal.le_of_forall_pos_le_add fun ε ε0 hS => ?_
  rcases ENNReal.exists_pos_sum_of_countable (ENNReal.coe_pos.2 ε0).ne' ℕ with ⟨ε', ε'0, hε⟩
  have key : ∀ n, ∃ a b : ℝ, t n ⊆ Ioo a b ∧
      ENNReal.ofReal (b - a) ≤ StieltjesFunction.id.length (t n) + (ε' n : ℝ≥0∞) := by
    intro n
    have hfin : StieltjesFunction.id.length (t n) ≠ ∞ :=
      ((le_tsum _ n).trans_lt hS).ne
    have hδ : (0 : ℝ) < (ε' n : ℝ) / 2 := by have := ε'0 n; positivity
    have hl := ENNReal.lt_add_right hfin (ENNReal.ofReal_pos.2 hδ).ne'
    conv at hl => lhs; rw [StieltjesFunction.length_eq]
    simp only [iInf_lt_iff] at hl
    rcases hl with ⟨a, b, h₁, h₂⟩
    refine ⟨a, b + (ε' n : ℝ) / 2, ?_, ?_⟩
    · intro x hx
      have hx' := h₁ ⟨hx, fun h => not_isBot x h⟩
      exact ⟨hx'.1, by linarith [hx'.2]⟩
    · have e1 : b + (ε' n : ℝ) / 2 - a = (b - a) + (ε' n : ℝ) / 2 := by ring
      rw [e1]
      calc ENNReal.ofReal ((b - a) + (ε' n : ℝ) / 2)
          ≤ ENNReal.ofReal (b - a) + ENNReal.ofReal ((ε' n : ℝ) / 2) := ENNReal.ofReal_add_le
        _ ≤ (StieltjesFunction.id.length (t n) + ENNReal.ofReal ((ε' n : ℝ) / 2))
              + ENNReal.ofReal ((ε' n : ℝ) / 2) := by
            gcongr
            simpa [StieltjesFunction.id_apply] using h₂.le
        _ = StieltjesFunction.id.length (t n) + (ε' n : ℝ≥0∞) := by
            rw [add_assoc, ← ENNReal.ofReal_add hδ.le hδ.le, add_halves,
              ENNReal.ofReal_coe_nnreal]
  choose a b hab hlen using key
  unfold lambdaStar
  refine iInf_le_of_le a (iInf_le_of_le b (iInf_le_of_le ?_ ?_))
  · exact ht.trans (iUnion_mono hab)
  · calc ∑' k, ENNReal.ofReal (b k - a k)
        ≤ ∑' k, (StieltjesFunction.id.length (t k) + (ε' k : ℝ≥0∞)) := tsum_le_tsum hlen
      _ = ∑' k, StieltjesFunction.id.length (t k) + ∑' k, (ε' k : ℝ≥0∞) := tsum_add
      _ ≤ ∑' k, StieltjesFunction.id.length (t k) + ε := by gcongr

/-- `lambdaStar` is Lebesgue measure. -/
theorem lambdaStar_eq_volume (A : Set ℝ) : lambdaStar A = volume A :=
  le_antisymm (lambdaStar_le_volume A) (volume_le_lambdaStar A)

/-- Every measurable set passes the splitting test for `lambdaStar`. -/
theorem caratheodoryMeasurable_lambdaStar_of_measurableSet {B : Set ℝ} (hB : MeasurableSet B) :
    CaratheodoryMeasurable lambdaStar B := by
  intro T
  simp only [lambdaStar_eq_volume]
  exact (measure_inter_add_sdiff T hB).symm

/-- **Caratheodory's theorem.** For any outer measure `μ` on any space `Ω` (empty set 0,
monotone, countably subadditive), the sets passing the splitting test form a sigma-algebra:
the empty set passes, complements of passing sets pass, and the union of any list of passing
sets passes. On them outer measure adds up countably: for passing sets `E 0, E 1, E 2, …`
with no point in two of them, the size of the union is the sum of the sizes. -/
theorem caratheodory_measurable_sigma_algebra_countably_additive {Ω : Type*}
    (μ : OuterMeasure Ω) :
    CaratheodoryMeasurable ⇑μ ∅ ∧
    (∀ E : Set Ω, CaratheodoryMeasurable ⇑μ E → CaratheodoryMeasurable ⇑μ Eᶜ) ∧
    (∀ E : ℕ → Set Ω, (∀ i, CaratheodoryMeasurable ⇑μ (E i)) →
      CaratheodoryMeasurable ⇑μ (⋃ i, E i)) ∧
    (∀ E : ℕ → Set Ω, (∀ i, CaratheodoryMeasurable ⇑μ (E i)) → Pairwise (Disjoint on E) →
      μ (⋃ i, E i) = ∑' i, μ (E i)) := by
  refine ⟨μ.isCaratheodory_empty, fun E hE => μ.isCaratheodory_compl hE,
    fun E hE => μ.isCaratheodory_iUnion hE, fun E hE hd => μ.f_iUnion hE hd⟩

/-- **For length on the line, every interval and every set of size zero passes.** An
interval is a set of reals that contains every point between two of its points (open,
closed, half-open, a half-line or the whole line); every such set passes the splitting test
for Lebesgue outer measure, and so does every set whose Lebesgue outer measure is 0. -/
theorem lebesgue_intervals_and_null_sets_pass :
    (∀ s : Set ℝ, s.OrdConnected → CaratheodoryMeasurable lambdaStar s) ∧
    (∀ N : Set ℝ, lambdaStar N = 0 → CaratheodoryMeasurable lambdaStar N) := by
  refine ⟨fun s hs => caratheodoryMeasurable_lambdaStar_of_measurableSet hs.measurableSet, ?_⟩
  intro N hN T
  simp only [lambdaStar_eq_volume] at hN ⊢
  have h1 : volume (T ∩ N) = 0 := measure_mono_null inter_subset_right hN
  rw [h1, zero_add]
  refine le_antisymm ?_ (measure_mono inter_subset_left)
  calc volume T ≤ volume (T ∩ N) + volume (T \ N) := measure_le_inter_add_sdiff _ _ _
    _ = volume (T ∩ Nᶜ) := by rw [h1, zero_add]; rfl

/-- **Every Borel set passes.** Every set built from intervals by repeated complements and
countable unions passes the splitting test for Lebesgue outer measure. -/
theorem lebesgue_borel_sets_pass (B : Set ℝ) (hB : MeasurableSet B) :
    CaratheodoryMeasurable lambdaStar B := by
  exact caratheodoryMeasurable_lambdaStar_of_measurableSet hB

/-! The card's worked numbers. Lengths on the fence are whole tenth-millimetres
(1 m = 10000), as in the card's Rust code: E = [5000, 12000], T = [2000, 8000] and
[10000, 20000], the gap (8000, 10000), the hull [2000, 20000]. -/

-- Size of T: 6000 + 10000 = 16000 at most; 18000 - 2000 = 16000 at least.
example : (8000 - 2000) + (20000 - 10000) = 16000 ∧ (20000 - 2000) - (10000 - 8000) = 16000 := by
  decide
-- T inside E: [5000, 8000] and [10000, 12000], 3000 + 2000 = 5000 at most; 7000 - 2000 at least.
example : (8000 - 5000) + (12000 - 10000) = 5000 ∧ (12000 - 5000) - (10000 - 8000) = 5000 := by
  decide
-- T outside E: [2000, 5000) and (12000, 20000], 3000 + 8000 = 11000 at most; 18000 - 7000 at least.
example : (5000 - 2000) + (20000 - 12000) = 11000 ∧ (20000 - 2000) - (12000 - 5000) = 11000 := by
  decide
-- E's test: 5000 + 11000 = 16000, the size of T.
example : 5000 + 11000 = 16000 := by decide
-- Rust spots at 3k/100 m, k = 1 … 100: 20 lie in [0.2, 0.8] and 33 in [1.0, 2.0], 53 in all.
example : ((Finset.Icc 1 100).filter (fun k => 20 ≤ 3 * k ∧ 3 * k ≤ 80)).card = 20 ∧
    ((Finset.Icc 1 100).filter (fun k => 100 ≤ 3 * k ∧ 3 * k ≤ 200)).card = 33 ∧
    ((Finset.Icc 1 100).filter
      (fun k => (20 ≤ 3 * k ∧ 3 * k ≤ 80) ∨ (100 ≤ 3 * k ∧ 3 * k ≤ 200))).card = 53 := by
  decide
-- A cover of T 0.01 m over its size, cut at 0.5 and 1.2 (whole 0.1 mm, so 25 per end):
-- 5050 inside E plus 11050 outside gives 16100.
example : (8025 - 5000) + (12000 - 9975) = 5050 ∧ (5000 - 1975) + (20025 - 12000) = 11050 ∧
    5050 + 11050 = 16100 := by decide

/-! The toy fence: panels a, b, c, d are bits 1, 2, 4, 8 of a number below 16; boards cover
{a}, {b, c}, {c, d}, each costing 1. `toyBill A` is the cheapest number of boards covering A. -/

/-- The panels under the boards chosen by the bits of `k`. -/
def toyCovered (k : ℕ) : ℕ :=
  (if k.testBit 0 then 1 else 0) ||| (if k.testBit 1 then 6 else 0) ||| (if k.testBit 2 then 12 else 0)

/-- The cheapest bill: the fewest boards whose panels include every panel of `A`. -/
def toyBill (A : ℕ) : ℕ :=
  ((List.range 8).filter (fun k => A &&& toyCovered k == A)).foldl
    (fun m k => min m ((k.testBit 0).toNat + (k.testBit 1).toNat + (k.testBit 2).toNat)) 3

/-- The splitting test on the toy fence, against all 16 test sets. -/
def toyPasses (A : ℕ) : Bool :=
  (List.range 16).all (fun X => toyBill X == toyBill (X &&& A) + toyBill (X &&& (A ^^^ 15)))

-- The bills: -:0 a:1 b:1 ab:2 c:1 ac:2 bc:1 abc:2 d:1 ad:2 bd:2 abd:3 cd:1 acd:2 bcd:2 abcd:3.
example : (List.range 16).map toyBill = [0, 1, 1, 2, 1, 2, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3] := by
  decide
-- The sets passing all 16 tests are exactly -, a, bcd, abcd.
example : (List.range 16).filter toyPasses = [0, 1, 14, 15] := by decide
-- Adding up on them: bill(a) + bill(bcd) = 1 + 2 = 3 = bill(abcd).
example : toyBill 1 + toyBill 14 = toyBill 15 := by decide
-- b passes the whole-fence test, 1 + 2 = 3, but fails T = bc: 1 + 1 against 1.
example : toyBill 2 + toyBill 13 = toyBill 15 ∧ toyBill 2 + toyBill 4 = 2 ∧ toyBill 6 = 1 := by
  decide

#print axioms volume_le_lambdaStar
#print axioms lambdaStar_le_volume
#print axioms lambdaStar_eq_volume
#print axioms caratheodoryMeasurable_lambdaStar_of_measurableSet
#print axioms caratheodory_measurable_sigma_algebra_countably_additive
#print axioms lebesgue_intervals_and_null_sets_pass
#print axioms lebesgue_borel_sets_pass
