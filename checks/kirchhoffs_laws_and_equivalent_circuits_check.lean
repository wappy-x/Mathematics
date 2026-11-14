-- Kirchhoff's laws: in any linear resistor network that reaches ground, the voltage at one node is a fixed source voltage minus a fixed positive resistance times the current drawn there, so any lamp's current is one division, and node voltages make every loop's voltage sum zero.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Logic.Relation
import Mathlib.Combinatorics.SimpleGraph.Walk.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.FiniteDimensional.Basic

open BigOperators Matrix

/-! ### The model

A resistor network with `n` nodes whose voltages are unknown (node `i` has voltage `v i`,
measured from ground). Every other node (ground, a battery's top) has a fixed voltage.

* `c i j` is the conductance `1/R` of the resistor joining unknown nodes `i` and `j`
  (`0` when none is fitted); a resistor treats its two ends alike, so `c i j = c j i`.
* `g i` is the total conductance from node `i` to fixed-voltage nodes.
* `s i` is the current the fixed-voltage nodes would push into node `i` if it sat at 0 V
  (conductance times fixed voltage, summed).
* A current `I` is drawn out of node `b`, the lamp's top wire, by anything clipped there.

The current law at node `i`, with Ohm's law for each part, reads
`∑ j, c i j * (v i - v j) + g i * v i = s i - (I if i = b)`.
Every node has a path of resistors to a fixed-voltage node (`hground`). -/

/-- The node operator `v ↦ (∑ j, c i j * (v i - v j) + g i * v i)_i` as a linear map. -/
def kirchhoffNodeMap {n : ℕ} (c : Fin n → Fin n → ℝ) (g : Fin n → ℝ) :
    (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ) where
  toFun v i := ∑ j, c i j * (v i - v j) + g i * v i
  map_add' x y := by
    ext i
    simp only [Pi.add_apply, add_sub_add_comm, mul_add, Finset.sum_add_distrib]
    ring
  map_smul' r x := by
    ext i
    simp only [Pi.smul_apply, smul_eq_mul, RingHom.id_apply, mul_add, Finset.mul_sum]
    congr 1
    · exact Finset.sum_congr rfl fun j _ => by ring
    · ring

lemma kirchhoffNodeMap_apply {n : ℕ} (c : Fin n → Fin n → ℝ) (g v : Fin n → ℝ) (i : Fin n) :
    kirchhoffNodeMap c g v i = ∑ j, c i j * (v i - v j) + g i * v i := rfl

/-- Energy identity: twice the power fed into the network is the dissipation. -/
lemma kirchhoff_energy {n : ℕ} (c : Fin n → Fin n → ℝ) (hc_symm : ∀ i j, c i j = c j i)
    (g v : Fin n → ℝ) :
    2 * ∑ i, v i * (∑ j, c i j * (v i - v j) + g i * v i) =
      ∑ i, ∑ j, c i j * (v i - v j) ^ 2 + 2 * ∑ i, g i * v i ^ 2 := by
  have h1 : ∑ i, ∑ j, c i j * v i * (v i - v j) = ∑ i, ∑ j, c i j * (-v j) * (v i - v j) := by
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    rw [hc_symm j i]; ring
  have h2 : ∑ i, v i * (∑ j, c i j * (v i - v j) + g i * v i) =
      ∑ i, ∑ j, c i j * v i * (v i - v j) + ∑ i, g i * v i ^ 2 := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [mul_add, Finset.mul_sum]
    congr 1
    · exact Finset.sum_congr rfl fun j _ => by ring
    · ring
  have h3 : ∑ i, ∑ j, c i j * (v i - v j) ^ 2 =
      ∑ i, ∑ j, c i j * v i * (v i - v j) + ∑ i, ∑ j, c i j * (-v j) * (v i - v j) := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun j _ => by ring
  rw [h2, h3, ← h1]; ring

/-- If the power fed in is not positive, every node voltage is zero (the network reaches ground). -/
lemma kirchhoff_eq_zero_of_energy_nonpos {n : ℕ}
    (c : Fin n → Fin n → ℝ) (hc_symm : ∀ i j, c i j = c j i) (hc_nonneg : ∀ i j, 0 ≤ c i j)
    (g : Fin n → ℝ) (hg_nonneg : ∀ i, 0 ≤ g i)
    (hground : ∀ i, ∃ k, Relation.ReflTransGen (fun x y => 0 < c x y) i k ∧ 0 < g k)
    (v : Fin n → ℝ) (h : ∑ i, v i * (∑ j, c i j * (v i - v j) + g i * v i) ≤ 0) : v = 0 := by
  have hE := kirchhoff_energy c hc_symm g v
  have hT1 : 0 ≤ ∑ i, ∑ j, c i j * (v i - v j) ^ 2 :=
    Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ =>
      mul_nonneg (hc_nonneg i j) (sq_nonneg _)
  have hT2 : 0 ≤ ∑ i, g i * v i ^ 2 :=
    Finset.sum_nonneg fun i _ => mul_nonneg (hg_nonneg i) (sq_nonneg _)
  have hT1z : ∑ i, ∑ j, c i j * (v i - v j) ^ 2 = 0 := by linarith
  have hT2z : ∑ i, g i * v i ^ 2 = 0 := by linarith
  have hc0 : ∀ i j, c i j * (v i - v j) ^ 2 = 0 := by
    intro i j
    have hi := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => Finset.sum_nonneg fun j _ =>
      mul_nonneg (hc_nonneg i j) (sq_nonneg (v i - v j)))).mp hT1z i (Finset.mem_univ _)
    exact (Finset.sum_eq_zero_iff_of_nonneg (fun j _ =>
      mul_nonneg (hc_nonneg i j) (sq_nonneg (v i - v j)))).mp hi j (Finset.mem_univ _)
  have hg0 : ∀ i, g i * v i ^ 2 = 0 := fun i =>
    (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => mul_nonneg (hg_nonneg i) (sq_nonneg (v i)))).mp
      hT2z i (Finset.mem_univ _)
  have hpathEq : ∀ x y, Relation.ReflTransGen (fun x y => 0 < c x y) x y → v x = v y := by
    intro x y hp
    induction hp with
    | refl => rfl
    | @tail a d _ had ih =>
      rw [ih]
      rcases mul_eq_zero.mp (hc0 a d) with h0 | h0
      · exact absurd h0 had.ne'
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h0
        linarith
  funext i
  obtain ⟨k, hpath, hgk⟩ := hground i
  have hik : v i = v k := hpathEq i k hpath
  have hk : v k = 0 := by
    rcases mul_eq_zero.mp (hg0 k) with h0 | h0
    · exact absurd h0 hgk.ne'
    · exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h0
  rw [hik, hk]; rfl

lemma kirchhoffNodeMap_injective {n : ℕ}
    (c : Fin n → Fin n → ℝ) (hc_symm : ∀ i j, c i j = c j i) (hc_nonneg : ∀ i j, 0 ≤ c i j)
    (g : Fin n → ℝ) (hg_nonneg : ∀ i, 0 ≤ g i)
    (hground : ∀ i, ∃ k, Relation.ReflTransGen (fun x y => 0 < c x y) i k ∧ 0 < g k) :
    Function.Injective (kirchhoffNodeMap c g) := by
  intro x y hxy
  have h0 : kirchhoffNodeMap c g (x - y) = 0 := by rw [map_sub, hxy, sub_self]
  have := kirchhoff_eq_zero_of_energy_nonpos c hc_symm hc_nonneg g hg_nonneg hground (x - y) (by
    have : ∀ i, (∑ j, c i j * ((x - y) i - (x - y) j) + g i * (x - y) i) = 0 := fun i => by
      rw [← kirchhoffNodeMap_apply, h0]; rfl
    exact le_of_eq (Finset.sum_eq_zero fun i _ => by rw [this i, mul_zero]))
  exact sub_eq_zero.mp this

/-- Thevenin's theorem. Seen from one node `b` and ground, a linear resistor network that
reaches ground acts exactly like one battery `Vth` behind one resistor `Rth > 0`: for every
current `I` drawn out of `b`, the node equations have exactly one solution, and in it the
voltage at `b` is `Vth - Rth * I`. -/
theorem thevenin_equivalent {n : ℕ}
    (c : Fin n → Fin n → ℝ) (hc_symm : ∀ i j, c i j = c j i) (hc_nonneg : ∀ i j, 0 ≤ c i j)
    (g : Fin n → ℝ) (hg_nonneg : ∀ i, 0 ≤ g i)
    (hground : ∀ i, ∃ k, Relation.ReflTransGen (fun x y => 0 < c x y) i k ∧ 0 < g k)
    (s : Fin n → ℝ) (b : Fin n) :
    ∃ Vth Rth : ℝ, 0 < Rth ∧ ∀ I : ℝ,
      (∃! v : Fin n → ℝ,
        ∀ i, ∑ j, c i j * (v i - v j) + g i * v i = s i - if i = b then I else 0) ∧
      ∀ v : Fin n → ℝ,
        (∀ i, ∑ j, c i j * (v i - v j) + g i * v i = s i - if i = b then I else 0) →
          v b = Vth - Rth * I := by
  have hinj := kirchhoffNodeMap_injective c hc_symm hc_nonneg g hg_nonneg hground
  have hsurj := LinearMap.injective_iff_surjective.mp hinj
  obtain ⟨w, hw⟩ := hsurj s
  obtain ⟨z, hz⟩ := hsurj (fun i => if i = b then (1 : ℝ) else 0)
  have hzi : ∀ i, ∑ j, c i j * (z i - z j) + g i * z i = if i = b then 1 else 0 := fun i => by
    rw [← kirchhoffNodeMap_apply, hz]
  have hwi : ∀ i, ∑ j, c i j * (w i - w j) + g i * w i = s i := fun i => by
    rw [← kirchhoffNodeMap_apply, hw]
  -- the solution for current `I`
  have hsol : ∀ I : ℝ, ∀ i, ∑ j, c i j * ((w - I • z) i - (w - I • z) j) + g i * (w - I • z) i =
      s i - if i = b then I else 0 := fun I i => by
    rw [← kirchhoffNodeMap_apply, map_sub, map_smul, Pi.sub_apply, Pi.smul_apply, hw, hz]
    by_cases hib : i = b <;> simp [hib]
  have huniq : ∀ I : ℝ, ∀ v : Fin n → ℝ,
      (∀ i, ∑ j, c i j * (v i - v j) + g i * v i = s i - if i = b then I else 0) →
        v = w - I • z := fun I v hv => by
    apply hinj
    funext i
    rw [kirchhoffNodeMap_apply, kirchhoffNodeMap_apply, hv i, hsol I i]
  refine ⟨w b, z b, ?_, fun I => ⟨⟨w - I • z, hsol I, fun v hv => huniq I v hv⟩, fun v hv => ?_⟩⟩
  · by_contra hneg
    have hE : ∑ i, z i * (∑ j, c i j * (z i - z j) + g i * z i) ≤ 0 := by
      simp only [hzi, mul_ite, mul_one, mul_zero, Finset.sum_ite_eq', Finset.mem_univ, ite_true]
      linarith
    have hz0 := kirchhoff_eq_zero_of_energy_nonpos c hc_symm hc_nonneg g hg_nonneg hground z hE
    have := hzi b
    simp [hz0] at this
  · rw [huniq I v hv]
    simp [mul_comm]

/-- Any lamp in one division, and the Norton form. For the same network there are two fixed
numbers `Vth` and `Rth > 0` such that a lamp of any resistance `RL > 0` clipped from `b` to
ground carries the current `Vth / (Rth + RL)`, and a plain wire in the lamp's place carries
`I_N = Vth / Rth`. -/
theorem lamp_current_from_stand_in {n : ℕ}
    (c : Fin n → Fin n → ℝ) (hc_symm : ∀ i j, c i j = c j i) (hc_nonneg : ∀ i j, 0 ≤ c i j)
    (g : Fin n → ℝ) (hg_nonneg : ∀ i, 0 ≤ g i)
    (hground : ∀ i, ∃ k, Relation.ReflTransGen (fun x y => 0 < c x y) i k ∧ 0 < g k)
    (s : Fin n → ℝ) (b : Fin n) :
    ∃ Vth Rth : ℝ, 0 < Rth ∧
      (∀ RL : ℝ, 0 < RL → ∀ v : Fin n → ℝ,
        (∀ i, ∑ j, c i j * (v i - v j) + g i * v i = s i - if i = b then v b / RL else 0) →
          v b / RL = Vth / (Rth + RL)) ∧
      (∀ (I : ℝ) (v : Fin n → ℝ), v b = 0 →
        (∀ i, ∑ j, c i j * (v i - v j) + g i * v i = s i - if i = b then I else 0) →
          I = Vth / Rth) := by
  obtain ⟨Vth, Rth, hR, h⟩ := thevenin_equivalent c hc_symm hc_nonneg g hg_nonneg hground s b
  refine ⟨Vth, Rth, hR, fun RL hRL v hv => ?_, fun I v hvb hv => ?_⟩
  · have h1 := (h (v b / RL)).2 v hv
    have hpos : 0 < Rth + RL := by linarith
    rw [eq_div_iff hpos.ne']
    have : v b / RL * RL = v b := div_mul_cancel₀ _ hRL.ne'
    nlinarith
  · have h1 := (h I).2 v hv
    rw [eq_div_iff hR.ne']
    linarith

/-- The voltage law comes free from node voltages. If every part's voltage is the difference of
the voltages at its two ends, then round any closed loop of the circuit's wiring the part
voltages add to zero. -/
theorem voltage_law_from_node_voltages {V : Type*} (G : SimpleGraph V) (φ : V → ℝ)
    {u : V} (loop : G.Walk u u) :
    (loop.darts.map fun d => φ d.snd - φ d.fst).sum = 0 := by
  have key : ∀ {x y : V} (p : G.Walk x y),
      (p.darts.map fun d => φ d.snd - φ d.fst).sum = φ y - φ x := by
    intro x y p
    induction p with
    | nil => simp
    | cons h p ih => simp [ih]
  rw [key]; ring

/-! ### The card's worked numbers, exactly (7.5 = 15/2, 1.5 = 3/2, 2.25 = 9/4) -/

-- Current law at A and at B with conductances 1/2, 1/6, 2/3, 1/6, at V_A = 15/2, V_B = 6.
example : (1 / 2 : ℝ) * (15 / 2 - 12) + 1 / 6 * (15 / 2) + 2 / 3 * (15 / 2 - 6) = 0 ∧
    (2 / 3 : ℝ) * (6 - 15 / 2) + 1 / 6 * 6 = 0 := by norm_num

-- Node matrix times 6: [[8, -4], [-4, 5]] (V_A, V_B) = (36, 0).
example : !![(8 : ℝ), -4; -4, 5] *ᵥ ![15 / 2, 6] = ![36, 0] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- Elimination: row B + (1/2) row A = [0, 3 | 18], so V_B = 6, then V_A = (36 + 4 * 6)/8 = 15/2.
example : (-4 : ℝ) + 1 / 2 * 8 = 0 ∧ (5 : ℝ) + 1 / 2 * (-4) = 3 ∧ (0 : ℝ) + 1 / 2 * 36 = 18 ∧
    (18 : ℝ) / 3 = 6 ∧ ((36 : ℝ) + 4 * 6) / 8 = 15 / 2 := by norm_num

-- Currents: 9/4 A through R1, 5/4 A through R2, 1 A through R3 and the lamp; current law at A.
example : ((12 : ℝ) - 15 / 2) / 2 = 9 / 4 ∧ (15 / 2 : ℝ) / 6 = 5 / 4 ∧
    ((15 / 2 : ℝ) - 6) / (3 / 2) = 1 ∧ (6 : ℝ) / 6 = 1 ∧ (5 / 4 : ℝ) + 1 = 9 / 4 := by norm_num

-- Loop currents: [[8, -6], [-6, 27/2]] (J1, J2) = (12, 0) at J1 = 9/4, J2 = 1.
example : !![(8 : ℝ), -6; -6, 27 / 2] *ᵥ ![9 / 4, 1] = ![12, 0] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- Power: the battery gives 27 W, the four parts burn 27 W, the lamp 6 W, the network 21 W.
example : (12 : ℝ) * (9 / 4) = 27 ∧
    (9 / 4 : ℝ) ^ 2 * 2 + (5 / 4) ^ 2 * 6 + 1 ^ 2 * (3 / 2) + 1 ^ 2 * 6 = 27 ∧
    (1 : ℝ) ^ 2 * 6 = 6 ∧ (27 : ℝ) - 6 = 21 := by norm_num

-- The stand-in: V_th = 12 * 6/8 = 9, R_th = 2 * 6/8 + 3/2 = 3, I_N = 9/3 = 3;
-- the lamp gets 9/(3 + 6) = 1 A by Thevenin and 3 * 3/(3 + 6) = 1 A by Norton;
-- the stand-in resistor burns 3 W.
example : (12 : ℝ) * 6 / (2 + 6) = 9 ∧ (2 : ℝ) * 6 / (2 + 6) + 3 / 2 = 3 ∧ (9 : ℝ) / 3 = 3 ∧
    (9 : ℝ) / (3 + 6) = 1 ∧ (3 : ℝ) * 3 / (3 + 6) = 1 ∧ (1 : ℝ) ^ 2 * 3 = 3 := by norm_num

-- Pushing 1 A into B with the battery a wire: B rises to 3 V.
example : !![(1 / 2 + 1 / 6 + 2 / 3 : ℝ), -(2 / 3); -(2 / 3), 2 / 3] *ᵥ ![3 / 2, 3] = ![0, 1] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- The lamp sweep: current 9/(3 + R_L) and power I^2 R_L for R_L = 1, 2, 3, 4, 6, 8, 12.
example : (9 : ℝ) / (3 + 1) = 9 / 4 ∧ (9 : ℝ) / (3 + 2) = 9 / 5 ∧ (9 : ℝ) / (3 + 3) = 3 / 2 ∧
    (9 : ℝ) / (3 + 4) = 9 / 7 ∧ (9 : ℝ) / (3 + 6) = 1 ∧ (9 : ℝ) / (3 + 8) = 9 / 11 ∧
    (9 : ℝ) / (3 + 12) = 3 / 5 := by norm_num
example : (9 / 4 : ℝ) ^ 2 * 1 = 81 / 16 ∧ (9 / 5 : ℝ) ^ 2 * 2 = 162 / 25 ∧
    (3 / 2 : ℝ) ^ 2 * 3 = 27 / 4 ∧ (9 / 7 : ℝ) ^ 2 * 4 = 324 / 49 ∧ (1 : ℝ) ^ 2 * 6 = 6 ∧
    (9 / 11 : ℝ) ^ 2 * 8 = 648 / 121 ∧ (3 / 5 : ℝ) ^ 2 * 12 = 108 / 25 := by norm_num

-- The mistakes: all three in series gives 18/31 A, the battery as a gap 2/3 A,
-- V_th taken as 12 V gives 4/3 A; the cold 3/5-ohm filament draws 5/2 A.
example : (9 : ℝ) / (2 + 6 + 3 / 2 + 6) = 18 / 31 ∧ (9 : ℝ) / (6 + 3 / 2 + 6) = 2 / 3 ∧
    (12 : ℝ) / (3 + 6) = 4 / 3 ∧ (9 : ℝ) / (3 + 3 / 5) = 5 / 2 := by norm_num

-- R3 signed backwards at A: [[0, 2/3], [-2/3, 5/6]] (45/4, 9) = (6, 0), so the lamp gets 9/6 = 3/2 A.
example : !![(1 / 2 + 1 / 6 - 2 / 3 : ℝ), 2 / 3; -(2 / 3), 2 / 3 + 1 / 6] *ᵥ ![45 / 4, 9] = ![6, 0] ∧
    (9 : ℝ) / 6 = 3 / 2 := by
  refine ⟨?_, by norm_num⟩
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- Try changing: 24 V doubles the lamp to 2 A; R2 = 3 ohms gives 24/29 A;
-- R2 removed gives V_th = 12, R_th = 7/2 and 24/19 A.
example : (24 : ℝ) * 6 / (2 + 6) / (3 + 6) = 2 ∧
    ((12 : ℝ) * 3 / (2 + 3)) / ((2 * 3 / (2 + 3) + 3 / 2) + 6) = 24 / 29 ∧
    (2 : ℝ) + 3 / 2 = 7 / 2 ∧ (12 : ℝ) / (7 / 2 + 6) = 24 / 19 := by norm_num

#print axioms kirchhoffNodeMap_apply
#print axioms kirchhoff_energy
#print axioms kirchhoff_eq_zero_of_energy_nonpos
#print axioms kirchhoffNodeMap_injective
#print axioms thevenin_equivalent
#print axioms lamp_current_from_stand_in
#print axioms voltage_law_from_node_voltages
