package objects
{
	public class Unit
	{
		/**
		 * Desriptive text
		 */
		private var unitDescription:String;
		
		/**
		 * the weight of one unit, < 0 if unitweight is unknown
		 */
		private var unitWeight:int;
		
		/**
		 * The amount of units, to which number of kilocalories, proteins, carbs and fat correspond, always > 0
		 */
		private var standardAmount:int;
		
		/**
		 * amount of kilocalories, < 0 if amount is unknown
		 */
		private var kcal:int;
		
		/**
		 * amount of Proteins in grams, < 0 if amount is unknown 
		 */
		private  var protein:Number;
		
		/**
		 * amount of carbs in grams, always >= 0
		 */
		private var carbs:Number;
		
		/**
		 * amount of fat in grams, < 0 if amount is unknown
		 */
		private var fat:Number;
		
		/**
		 * Creates a Unit. 
		 * @param unitDescription
		 * @param unitWeight if unitWeight < 0 then the new Unit will have unitWeight = -1
		 * @param standardAmount if standardAmount <= 0, then the new Unit will have standardAmount = -1
		 * @param kcal if kcal < 0 then the new Unit will have kcal = -1
		 * @param protein if protein < 0 then the new Unit will have protein = -1
		 * @param carbs if carbs < 0 then the new Unit will have carbs value = 0
		 * @param fat if fat < 0 then the new Unit will have fat = -1
		 */
		public function Unit( unitDescription:String,
			 unitWeight:int,
			 standardAmount:int,
			int kcal:int,
			 protein:Number,
			 carbs:Number,
			 fat:Number) {
				this.unitDescription = unitDescription;
				if (unitWeight >= 0) {
					this.unitWeight = unitWeight; 
				} else {
					this.unitWeight = -1;
				}
				if (standardAmount > 0) {
					this.standardAmount = standardAmount; 
				} else {
					this.standardAmount = -1;
				}
				if (kcal >= 0) {
					this.kcal = kcal; 
				} else {
					this.kcal = -1;
				}
				if (protein >= 0) {
					this.protein = protein; 
				} else {
					this.protein = -1;
				}
				if (carbs >= 0) {
					this.carbs = carbs; 
				} else {
					this.carbs = 0;
				}
				if (fat >= 0) {
					this.fat = fat; 
				} else {
					this.fat = -1;
				}
			}
		
		/**
		 * constructor
		 * @param newUnit
		 */
		public function Unit (newUnit:Unit) {
			this.carbs = newUnit.carbs;
			this.fat = newUnit.fat;
			this.kcal = newUnit.kcal;
			this.protein = newUnit.protein;
			this.standardAmount = newUnit.standardAmount;
			this.unitDescription = newUnit.unitDescription;
			this.unitWeight = newUnit.unitWeight;
		}
		
		/**
		 * @return the unitDescription in a new String
		 */
		public function getDescription():String {
			return unitDescription;
		}
		
		/**
		 * @return the unitWeight
		 */
		public function getWeight():int {
			return unitWeight;
		}
		
		/**
		 * @return the standard Amount
		 */
		public function getStandardAmount():int {
			return standardAmount;
		}
		
		/**
		 * @return kcal
		 */
		public function getKcal():int {
			return kcal;
		}
		
		/**
		 * @return protein
		 */
		public function getProtein():Number {
			return protein;
		}
		
		/**
		 * @return carbs
		 */
		public function getCarbs():Number {
			return carbs;
		}
		
		/**
		 * @return fat
		 */
		public function getFat():Number {
			return fat;
		}
		
	}
}