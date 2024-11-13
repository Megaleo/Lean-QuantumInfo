import StatMech.ThermoQuantities

noncomputable section

--! Specializing to an ideal gas of distinguishable particles.

/-- The Hamiltonian for an ideal gas: particles live in a cube of volume V^(1/3), and each contributes an energy p^2/2.
The per-particle mass is normalized to 1. -/
def IdealGas : NVEHamiltonian where
  --The dimension of the manifold is 6 times the number of particles: three for position, three for momentum.
  dim := fun (n,_) ↦ Fin n × (Fin 3 ⊕ Fin 3)
  --The energy is ∞ if any positions are outside the cube, otherwise it's the sum of the momenta squared over 2.
  H := fun {d} config ↦
    let (n,V) := d
    let R := V^(1/3:ℝ) / 2 --half-sidelength of a cubical box
    if ∀ (i : Fin n) (ax : Fin 3), |config (i,.inl ax)| <= R then
      ∑ (i : Fin n) (ax : Fin 3), config (i,.inr ax)^2 / (2 : ℝ)
    else
      ⊤

namespace IdealGas
open MicroHamiltonian
open NVEHamiltonian

variable (n : ℕ) {V β T : ℝ}

/-- The partition function Z for an ideal gas. -/
theorem PartitionZ_eq (hV : 0 < V) (hβ : 0 < β) :
    IdealGas.PartitionZ (n,V) β = V^n * (2 * Real.pi / β)^(3 * n / 2 : ℝ) := by
  rw [PartitionZ, IdealGas]
  simp only [Finset.univ_product_univ, one_div, Fintype.sum_prod_type, ite_eq_right_iff, neg_mul]
  have : ∀ (config : IdealGas.dim (n,V) → ℝ),
    ∑ x : Fin n, ∑ x_1 : Fin 3, (config (x, Sum.inr x_1) ^ 2 / (2 : ℝ) : WithTop ℝ) ≠ ⊤ := by
    intro config
    -- rw [WithTop.sum_eq_top]
    sorry
  sorry

/-- The Helmholtz Free Energy A for an ideal gas. -/
theorem HelmholtzA_eq (hV : 0 < V) (hT : 0 < T) : IdealGas.HelmholtzA (n,V) T =
    -n * T * (Real.log V + (3/2) * Real.log (2 * Real.pi * T)) := by
  rw [HelmholtzA, PartitionZT, PartitionZ_eq n hV (one_div_pos.mpr hT), Real.log_mul,
    Real.log_pow, Real.log_rpow, one_div, div_inv_eq_mul]
  ring_nf
  all_goals positivity

theorem ZIntegrable (hV : 0 < V) (hβ : 0 < β) : IdealGas.ZIntegrable (n,V) β := by
  have hZpos : 0 < PartitionZ IdealGas (n, V) β := by
    rw [PartitionZ_eq n hV hβ]
    positivity
  constructor
  · apply MeasureTheory.Integrable.of_integral_ne_zero
    rw [← PartitionZ]
    exact hZpos.ne'
  · exact hZpos.ne'

/-- The ideal gas law: PV = nRT. In our unitsless system, R = 1.-/
theorem IdealGasLaw (hV : 0 < V) (hT : 0 < T) :
    let P := IdealGas.Pressure (n,V) T;
    let R := 1;
    P * V = n * R * T := by
  dsimp [Pressure]
  rw [← derivWithin_of_isOpen (s := Set.Ioi 0) isOpen_Ioi hV]
  rw [derivWithin_congr (f := fun V' ↦ -n * T * (Real.log V' + (3/2) * Real.log (2 * Real.pi * T))) ?_ ?_]
  rw [derivWithin_of_isOpen (s := Set.Ioi 0) isOpen_Ioi hV]
  rw [deriv_mul (by fun_prop) (by fun_prop (disch := exact hV.ne'))]
  field_simp
  ring_nf
  · exact fun _ hV' ↦ HelmholtzA_eq n hV' hT
  · exact HelmholtzA_eq n hV hT

-- Now proving Boyle's Law ("for an ideal gas with a fixed particle number, P and V are inversely proportional")
-- is a fast consequence of the ideal gas law.

end IdealGas