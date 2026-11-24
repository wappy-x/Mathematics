-- The Ionescu-Tulcea theorem: a law for the first step and a probability kernel for each next step given the whole past build, on any measurable spaces, exactly one probability on infinite sequences whose laws for the first n steps are the step-by-step compositions.
import Mathlib.Probability.Kernel.IonescuTulcea.Traj
import Mathlib.Probability.Kernel.Composition.MeasureCompProd
import Mathlib.Probability.Kernel.Composition.Lemmas
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Finset Preorder
open scoped ENNReal

namespace IonescuTulceaCard

/-! Steps are counted from 0 in Lean: the card's `E_1, E_2, …` are `X 0, X 1, …`, its
history `H_n` of the first n steps is `Π i : Iic (n - 1), X i`, its first-step law `P_1` is
`μ₀`, and its kernel `κ_n` from `H_n` to `E_{n+1}` is `κ (n - 1)`. Each `X n` carries any
sigma-algebra at all: no topology is assumed. -/

variable {X : ℕ → Type*} [∀ n, MeasurableSpace (X n)]

/-- Append a next value `y` to a history `x` of the steps `0, …, n`: the longer history
`(x, y)` of the steps `0, …, n + 1`. -/
noncomputable def extendHist (n : ℕ) (x : Π i : Iic n, X i) (y : X (n + 1)) :
    Π i : Iic (n + 1), X i :=
  IicProdIoc n (n + 1) (x, MeasurableEquiv.piSingleton n y)

/-- The card's step-by-step laws: the law of the first step is `μ₀`, and the law of one
more step is `P_{n+1} = P_n ⊗ κ_n`, the history `x` drawn from `P_n` and the next value
`y` from `κ_n(x, ·)`, glued into the longer history `(x, y)`. -/
noncomputable def stepLaw (μ₀ : Measure (X 0))
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) :
    (n : ℕ) → Measure (Π i : Iic n, X i)
  | 0 => μ₀.map (MeasurableEquiv.piUnique (fun i : Iic 0 => X i)).symm
  | n + 1 => (stepLaw μ₀ κ n ⊗ₘ κ n).map (fun p => extendHist n p.1 p.2)

theorem measurable_extendHist (n : ℕ) :
    Measurable (fun p : (Π i : Iic n, X i) × X (n + 1) => extendHist n p.1 p.2) :=
  measurable_IicProdIoc.comp
    (measurable_fst.prodMk ((MeasurableEquiv.piSingleton n).measurable.comp measurable_snd))

theorem stepLaw_eq_comp (μ₀ : Measure (X 0)) [IsProbabilityMeasure μ₀]
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) [∀ n, IsMarkovKernel (κ n)]
    (n : ℕ) :
    stepLaw μ₀ κ n = Kernel.partialTraj κ 0 n ∘ₘ
      (μ₀.map (MeasurableEquiv.piUnique (fun i : Iic 0 => X i)).symm) := by
  induction n with
  | zero => rw [Kernel.partialTraj_self, Measure.id_comp]; rfl
  | succ n ih =>
    have hsf : SFinite (stepLaw μ₀ κ n) := by rw [ih]; infer_instance
    rw [Kernel.partialTraj_succ_eq_comp (Nat.zero_le n), ← Measure.comp_assoc, ← ih,
      Kernel.partialTraj_succ_self, ← Measure.map_comp _ _ measurable_IicProdIoc,
      ← Measure.compProd_eq_comp_prod, Measure.compProd_map (MeasurableEquiv.measurable _),
      Measure.map_map measurable_IicProdIoc (by fun_prop)]
    rfl

theorem stepLaw_eq_map (μ₀ : Measure (X 0)) [IsProbabilityMeasure μ₀]
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) [∀ n, IsMarkovKernel (κ n)]
    (n : ℕ) :
    stepLaw μ₀ κ n = (Kernel.trajMeasure μ₀ κ).map (frestrictLe n) := by
  rw [stepLaw_eq_comp, Kernel.trajMeasure, Measure.map_comp _ _ (measurable_frestrictLe n),
    Kernel.traj_map_frestrictLe]

theorem isProbabilityMeasure_stepLaw (μ₀ : Measure (X 0)) [IsProbabilityMeasure μ₀]
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) [∀ n, IsMarkovKernel (κ n)]
    (n : ℕ) : IsProbabilityMeasure (stepLaw μ₀ κ n) := by
  rw [stepLaw_eq_map]
  infer_instance

/-- **The Ionescu-Tulcea theorem.** Give the first step a probability `μ₀`, and give each
later step a probability kernel `κ n`: for each history of the steps so far a probability
on the next value, depending measurably on that history. Then, on any measurable spaces,
there is exactly one probability `P` on the infinite sequences `ω = (ω₀, ω₁, …)`, with the
product sigma-algebra, such that for every `n` and every measurable set `A` of histories
of the steps `0, …, n`, the chance that `(ω₀, …, ω_n)` lies in `A` is the step-by-step
law `P_n(A)`. -/
theorem ionescu_tulcea_exists_unique (μ₀ : Measure (X 0)) [IsProbabilityMeasure μ₀]
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) [∀ n, IsMarkovKernel (κ n)] :
    ∃! P : Measure (Π n, X n), IsProbabilityMeasure P ∧
      ∀ (n : ℕ) (A : Set (Π i : Iic n, X i)), MeasurableSet A →
        P (frestrictLe n ⁻¹' A) = stepLaw μ₀ κ n A := by
  set P₀ := Kernel.trajMeasure μ₀ κ with hP₀
  refine ⟨P₀, ⟨inferInstance, fun n A hA => ?_⟩, ?_⟩
  · rw [stepLaw_eq_map, Measure.map_apply (measurable_frestrictLe n) hA]
  rintro Q ⟨hQ, hQA⟩
  have hproj : IsProjectiveMeasureFamily
      (inducedFamily (fun n => P₀.map (frestrictLe (π := X) n))) := by
    refine isProjectiveMeasureFamily_inducedFamily _ (fun a b hab => ?_)
    rw [Measure.map_map (measurable_frestrictLe₂ hab) (measurable_frestrictLe b),
      frestrictLe₂_comp_frestrictLe]
  have h1 : IsProjectiveLimit P₀ (inducedFamily (fun n => P₀.map (frestrictLe (π := X) n))) := by
    rw [isProjectiveLimit_nat_iff hproj]
    intro n
    rw [inducedFamily_Iic]
  have h2 : IsProjectiveLimit Q (inducedFamily (fun n => P₀.map (frestrictLe (π := X) n))) := by
    rw [isProjectiveLimit_nat_iff hproj]
    intro n
    rw [inducedFamily_Iic]
    ext A hA
    rw [Measure.map_apply (measurable_frestrictLe n) hA, hQA n A hA, stepLaw_eq_map]
  exact h2.unique h1

/-- **The composition formula.** The law of one more step gives a measurable set `C` of
longer histories the chance `P_{n+1}(C) = ∫ κ_n(x, C_x) P_n(dx)`, where the section
`C_x` is the set of next values `y` with `(x, y) ∈ C`. -/
theorem stepLaw_succ_apply (μ₀ : Measure (X 0)) [IsProbabilityMeasure μ₀]
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) [∀ n, IsMarkovKernel (κ n)]
    (n : ℕ) {C : Set (Π i : Iic (n + 1), X i)} (hC : MeasurableSet C) :
    stepLaw μ₀ κ (n + 1) C =
      ∫⁻ x, κ n x {y | extendHist n x y ∈ C} ∂(stepLaw μ₀ κ n) := by
  have := isProbabilityMeasure_stepLaw μ₀ κ n
  rw [stepLaw, Measure.map_apply (measurable_extendHist n) hC,
    Measure.compProd_apply (measurable_extendHist n hC)]
  rfl

/-- **The laws fit together for free** (Kolmogorov's consistency condition). When every
kernel gives total chance 1, a condition `A` on the steps `0, …, n` and none on step
`n + 1` has the same chance under `P_{n+1}` as `A` under `P_n`. -/
theorem stepLaw_consistent (μ₀ : Measure (X 0)) [IsProbabilityMeasure μ₀]
    (κ : (n : ℕ) → Kernel (Π i : Iic n, X i) (X (n + 1))) [∀ n, IsMarkovKernel (κ n)]
    (n : ℕ) {A : Set (Π i : Iic n, X i)} (hA : MeasurableSet A) :
    stepLaw μ₀ κ (n + 1) (frestrictLe₂ (Nat.le_succ n) ⁻¹' A) = stepLaw μ₀ κ n A := by
  rw [stepLaw_eq_map, stepLaw_eq_map,
    Measure.map_apply (measurable_frestrictLe _) (measurable_frestrictLe₂ _ hA),
    Measure.map_apply (measurable_frestrictLe _) hA, ← Set.preimage_comp,
    frestrictLe₂_comp_frestrictLe]

end IonescuTulceaCard

open IonescuTulceaCard

/-! The card's worked numbers, in exact fractions. -/

-- Polya's urn: P(R, R, R) = 1/2 × 2/3 × 3/4 = 1/4.
example : (1 / 2 : ℚ) * (2 / 3) * (3 / 4) = 1 / 4 := by norm_num
-- P(R, R, B) = 1/2 × 2/3 × 1/4 = 1/12, and P(B, R, R) = 1/2 × 1/3 × 2/4 = 1/12.
example : (1 / 2 : ℚ) * (2 / 3) * (1 / 4) = 1 / 12 := by norm_num
example : (1 / 2 : ℚ) * (1 / 3) * (2 / 4) = 1 / 12 := by norm_num
-- P(R, B, R) = 1/2 × 1/3 × 2/4 = 1/12 as well: the order does not matter.
example : (1 / 2 : ℚ) * (1 / 3) * (1 / 2) = 1 / 12 := by norm_num
-- Consistency at R, R: P(RRR) + P(RRB) = 1/4 + 1/12 = 1/3 = P(R, R) = 1/2 × 2/3.
example : (1 / 4 : ℚ) + 1 / 12 = 1 / 3 ∧ (1 / 2 : ℚ) * (2 / 3) = 1 / 3 := by norm_num
-- The eight histories of three draws add to 1: 1/4 + 6 × 1/12 + 1/4.
example : (1 / 4 : ℚ) + 6 * (1 / 12) + 1 / 4 = 1 := by norm_num
-- The proof's h for "R, R, R": h₁(R) = 2/3 × 3/4 = 1/2, h₀ = 1/2 × 1/2 + 1/2 × 0 = 1/4.
example : (2 / 3 : ℚ) * (3 / 4) = 1 / 2 ∧ (1 / 2 : ℚ) * (1 / 2) + 1 / 2 * 0 = 1 / 4 := by
  norm_num
-- A history with k reds in n draws has chance k! (n - k)! / (n + 1)!; three reds: 3! 0! / 4! = 1/4.
example : ((Nat.factorial 3 * Nat.factorial 0 : ℕ) : ℚ) / (Nat.factorial 4 : ℕ) = 1 / 4 := by
  norm_num [Nat.factorial]
-- Reds in 3 draws: each count k = 0..3 has chance C(3, k) k! (3 - k)! / 4! = 1/4.
example : ∀ k ∈ List.range 4,
    Nat.choose 3 k * Nat.factorial k * Nat.factorial (3 - k) * 4 = Nat.factorial 4 := by
  decide
-- Reds in 10 draws: each count k = 0..10 has chance C(10, k) k! (10 - k)! / 11! = 1/11.
example : ∀ k ∈ List.range 11,
    Nat.choose 10 k * Nat.factorial k * Nat.factorial (10 - k) * 11 = Nat.factorial 11 := by
  decide
-- At most 25 reds in 100 draws: 26 counts, each with chance 1/101, give 26/101.
example : (26 : ℚ) * (1 / 101) = 26 / 101 := by norm_num
-- Draws wrongly treated as independent halves: P(R, R, R) = 1/8, not 1/4.
example : (1 / 2 : ℚ) ^ 3 = 1 / 8 ∧ (1 / 8 : ℚ) ≠ 1 / 4 := by norm_num
-- The sticky coin: P(H, H, H) = 1/2 × 4/5 × 4/5 = 8/25 (the card's 0.32).
example : (1 / 2 : ℚ) * (4 / 5) * (4 / 5) = 8 / 25 := by norm_num
-- Weights 4/5 + 3/10 = 11/10: P_2(H, H) = 2/5 but P_3 summed over toss 3 gives 11/25.
example : (1 / 2 : ℚ) * (4 / 5) = 2 / 5 ∧ (2 / 5 : ℚ) * (4 / 5 + 3 / 10) = 11 / 25 ∧
    (11 / 25 : ℚ) ≠ 2 / 5 := by norm_num
-- The kernel that sees only the last draw: P(RRR) = 1/2 × 2/3 × 2/3 = 2/9, not 1/4.
example : (1 / 2 : ℚ) * (2 / 3) * (2 / 3) = 2 / 9 ∧ (2 / 9 : ℚ) ≠ 1 / 4 := by norm_num

#print axioms measurable_extendHist
#print axioms stepLaw_eq_comp
#print axioms stepLaw_eq_map
#print axioms isProbabilityMeasure_stepLaw
#print axioms ionescu_tulcea_exists_unique
#print axioms stepLaw_succ_apply
#print axioms stepLaw_consistent
