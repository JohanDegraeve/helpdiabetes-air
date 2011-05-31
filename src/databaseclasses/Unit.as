/**
 Copyright (C) 2011  hippoandfriends
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package databaseclasses
{
	/**
	 * holds a unit : description, standard amount, amount of kilocalories in grams per standard amount, amount of protein, carbs, and fat 
	 * Values for kilocalories, protein and fat can be -1, meaning unknown value.
	 */ 
	
	public class Unit
	{
		private var _unitDescription:String;
		
		
		private var _standardAmount:int;
		
		private var _kcal:int;
		
		private  var _protein:Number;
		
		private var _carbs:Number;
		
		private var _fat:Number;
		
		/**
		 * Creates a Unit. <br>
		 * @param unitDescription<br>
		 * @param unitWeight if unitWeight < 0 then the new Unit will have unitWeight = -1<br>
		 * @param standardAmount if standardAmount <= 0, then the new Unit will have standardAmount = -1<br>
		 * @param kcal if kcal < 0 then the new Unit will have kcal = -1<br>
		 * @param protein if protein < 0 then the new Unit will have protein = -1<br>
		 * @param carbs if carbs < 0 then the new Unit will have carbs value = 0<br>
		 * @param fat if fat < 0 then the new Unit will have fat = -1<br>
		 */
		public function Unit( unitDescription:String,
			 standardAmount:int,
			 kcal:int,
			 protein:Number,
			 carbs:Number,
			 fat:Number) {
				this._unitDescription = unitDescription;
				if (standardAmount > 0) {
					this._standardAmount = standardAmount; 
				} else {
					this._standardAmount = -1;
				}
				if (kcal >= 0) {
					this._kcal = kcal; 
				} else {
					this._kcal = -1;
				}
				if (protein >= 0) {
					this._protein = protein; 
				} else {
					this._protein = -1;
				}
				if (carbs >= 0) {
					this._carbs = carbs; 
				} else {
					this._carbs = 0;
				}
				if (fat >= 0) {
					this._fat = fat; 
				} else {
					this._fat = -1;
				}
			}
		
		

		/**
		 * The amount of units, to which number of kilocalories, proteins, carbs and fat correspond, always > 0
		 */
		public function get standardAmount():int
		{
			return _standardAmount;
		}

		/**
		 * @private
		 */
		public function set standardAmount(value:int):void
		{
			_standardAmount = value;
		}

		/**
		 * amount of kilocalories, < 0 if amount is unknown
		 */
		public function get kcal():int
		{
			return _kcal;
		}

		/**
		 * @private
		 */
		public function set kcal(value:int):void
		{
			_kcal = value;
		}

		/**
		 * Desriptive text
		 */
		public function get unitDescription():String
		{
			return _unitDescription;
		}

		/**
		 * @private
		 */
		public function set unitDescription(value:String):void
		{
			_unitDescription = value;
		}

		/**
		 * amount of Proteins in grams, < 0 if amount is unknown 
		 */
		public function get protein():Number
		{
			return _protein;
		}

		/**
		 * @private
		 */
		public function set protein(value:Number):void
		{
			_protein = value;
		}

		/**
		 * amount of carbs in grams, always >= 0
		 */
		public function get carbs():Number
		{
			return _carbs;
		}

		/**
		 * @private
		 */
		public function set carbs(value:Number):void
		{
			_carbs = value;
		}

		/**
		 * amount of fat in grams, < 0 if amount is unknown
		 */
		public function get fat():Number
		{
			return _fat;
		}

		/**
		 * @private
		 */
		public function set fat(value:Number):void
		{
			_fat = value;
		}

		
	}
}