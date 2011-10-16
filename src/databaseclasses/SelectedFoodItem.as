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
	 * a fooditem with one unit, and a chosen amount<br>
	 * 
	*/
	public class SelectedFoodItem
	{
		private var _itemDescription:String;
		private var _unit:Unit;
		private var _chosenAmount:Number;
		internal var _selectedItemId:int;
		private var _mealEventId:int;

		/**
		 * constructor taking description, unit and chosenamount as parameter
		 */
		public function SelectedFoodItem(description:String, unit:Unit,chosenAmount:Number):void
		{
			this._unit = new Unit(unit.unitDescription,unit.standardAmount,unit.kcal,unit.protein,unit.carbs,unit.fat);
			this._itemDescription = description;
			this._chosenAmount = chosenAmount;
		}
		
		
		public function get itemDescription():String
		{
			return _itemDescription;
		}

		public function set itemDescription(value:String):void
		{
			_itemDescription = value;
		}

		public function get unit():Unit
		{
			return _unit;
		}

		public function set unit(value:Unit):void
		{
			_unit = value;
		}

		public function get chosenAmount():Number
		{
			return _chosenAmount;
		}

		/**
		 * the amount chosen by the user.<br>
		 * when changed then also  database update happens with new value for chosenAmount 
		 */
		public function set chosenAmount(value:Number):void
		{
			_chosenAmount = value;
			Database.getInstance().updateSelectedFoodItemChosenAmount(this.selectedItemId,value,null);
		}
		

		internal function get selectedItemId():int
		{
			return _selectedItemId;
		}

		internal function set selectedItemId(value:int):void
		{
			_selectedItemId = value;
		}

		internal function get mealEventId():int
		{
			return _mealEventId;
		}

		internal function set mealEventId(value:int):void
		{
			_mealEventId = value;
		}


	}
}