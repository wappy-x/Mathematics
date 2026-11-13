-- Pi-systems and Dynkin's theorem: two finite measures with the same total that agree on a pi-system agree on every set it generates, a lambda-system holding a pi-system holds the sigma-algebra it generates, and two probability measures on the real line with the same distribution function are equal.
import Mathlib.MeasureTheory.PiSystem
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real

open MeasureTheory Set

/-- Uniqueness of measures (the card's main claim). Let `P` be a pi-system on `Ω`, and let
`μ` and `ν` be measures on the sigma-algebra `σ(P)` that `P` generates. If the two measures
have the same finite total, `μ(Ω) = ν(Ω) < ∞`, and agree on every set of `P`, then they agree
on every set of `σ(P)`.
(Mathlib's `IsPiSystem` asks for closure only under overlaps that are non-empty, and does not
ask for `P` to be non-empty; the card's pi-system meets both conditions.) -/
theorem measures_agree_on_generated_sigma_algebra_of_agree_on_pi_system
    {Ω : Type*} [m : MeasurableSpace Ω] (P : Set (Set Ω))
    (hgen : m = MeasurableSpace.generateFrom P) (hP : IsPiSystem P)
    (μ ν : Measure Ω) (htotal : μ univ = ν univ) (hfinite : μ univ < ⊤)
    (hagree : ∀ A ∈ P, μ A = ν A) :
    ∀ A, MeasurableSet A → μ A = ν A := by
  have : IsFiniteMeasure μ := ⟨hfinite⟩
  have h : μ = ν := ext_of_generate_finite P hgen hP hagree htotal
  intro A _
  rw [h]

/-- Dynkin's pi-lambda theorem. Let `P` be a pi-system and `L` a lambda-system on `Ω`, in the
card's sense: `L` contains `Ω`, is closed under proper differences (`A ⊆ B` both in `L` give
`B \ A` in `L`), and is closed under increasing unions. If every set of `P` lies in `L`, then
every set of the sigma-algebra `σ(P)` lies in `L`. -/
theorem sigma_of_pi_system_subset_lambda_system
    {Ω : Type*} (P : Set (Set Ω)) (hP : IsPiSystem P) (L : Set (Set Ω))
    (hL_univ : univ ∈ L)
    (hL_diff : ∀ A B, A ∈ L → B ∈ L → A ⊆ B → B \ A ∈ L)
    (hL_union : ∀ A : ℕ → Set Ω, Monotone A → (∀ n, A n ∈ L) → (⋃ n, A n) ∈ L)
    (hPL : P ⊆ L) :
    ∀ A, MeasurableSet[MeasurableSpace.generateFrom P] A → A ∈ L := by
  have hcompl : ∀ A, A ∈ L → Aᶜ ∈ L := by
    intro A hA
    rw [compl_eq_univ_sdiff]
    exact hL_diff A univ hA hL_univ (subset_univ A)
  have hunion : ∀ A B, A ∈ L → B ∈ L → Disjoint A B → A ∪ B ∈ L := by
    intro A B hA hB hAB
    have h1 : Aᶜ \ B ∈ L := hL_diff B Aᶜ hB (hcompl A hA) hAB.subset_compl_left
    have h2 := hcompl _ h1
    have h3 : (Aᶜ \ B)ᶜ = A ∪ B := by
      ext x; simp only [mem_compl_iff, mem_sdiff, mem_union]; tauto
    rwa [h3] at h2
  intro A hA
  refine MeasurableSpace.induction_on_inter (C := fun t _ => t ∈ L) rfl hP ?_ ?_ ?_ ?_ A hA
  · have := hL_diff univ univ hL_univ hL_univ (subset_refl _)
    simpa using this
  · intro t ht
    exact hPL ht
  · intro t _ ht
    exact hcompl t ht
  · intro f hdisj _ hf
    have hacc : ∀ n, accumulate f n ∈ L := by
      intro n
      induction n with
      | zero => simpa using hf 0
      | succ n ih =>
        rw [accumulate_succ]
        exact hunion _ _ ih (hf (n + 1)) (disjoint_accumulate hdisj (Nat.lt_succ_self n))
    have := hL_union (accumulate f) monotone_accumulate hacc
    rwa [iUnion_accumulate] at this

/-- A distribution function fixes a law: two probability measures on the real line that give
the same chance to every half-line "at or below t" are the same measure on the Borel sets. -/
theorem probability_measures_eq_of_same_distribution_function
    (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hF : ∀ t : ℝ, μ (Iic t) = ν (Iic t)) :
    μ = ν := by
  exact Measure.ext_of_Iic μ ν hF

/-! ### The card's worked numbers, exactly -/

/-- Model A's distribution function, in the card's terms: with `s = (t - 8)/12`,
`F(t) = s^2/2` for `s` from 0 to 1 and `1 - (2 - s)^2/2` for `s` from 1 to 2. -/
def cardF (t : ℚ) : ℚ :=
  let s := (t - 8) / 12
  if s ≤ 0 then 0 else if s ≤ 1 then s ^ 2 / 2 else if s ≤ 2 then 1 - (2 - s) ^ 2 / 2 else 1

-- F(15) = 49/288, F(20) = 1/2, F(30) = 71/72.
example : cardF 15 = 49 / 288 := by norm_num [cardF]
example : cardF 20 = 1 / 2 := by norm_num [cardF]
example : cardF 30 = 71 / 72 := by norm_num [cardF]
-- Band 15 to 20, a proper difference: 1/2 - 49/288 = 95/288.
example : cardF 20 - cardF 15 = 95 / 288 := by norm_num [cardF]
-- Above 30, a complement: 1 - 71/72 = 1/72.
example : 1 - cardF 30 = 1 / 72 := by norm_num [cardF]
-- The farmer's event: 95/288 + 1/72 = 11/32, and the card's Dynkin-move route gives the same.
example : (cardF 20 - cardF 15) + (1 - cardF 30) = 11 / 32 := by norm_num [cardF]
example : 1 - ((1 - (cardF 20 - cardF 15)) - (1 - cardF 30)) = 11 / 32 := by norm_num [cardF]

-- Four bands, chances scaled by 4: model mu gives 1 to each band, model nu gives 0, 2, 0, 2.
-- They agree on exactly 6 of the 16 sets.
example :
    ((Finset.univ : Finset (Finset (Fin 4))).filter
      (fun A => A.card = ∑ i ∈ A, (![0, 2, 0, 2] : Fin 4 → ℕ) i)).card = 6 := by
  decide

#print axioms measures_agree_on_generated_sigma_algebra_of_agree_on_pi_system
#print axioms sigma_of_pi_system_subset_lambda_system
#print axioms probability_measures_eq_of_same_distribution_function
