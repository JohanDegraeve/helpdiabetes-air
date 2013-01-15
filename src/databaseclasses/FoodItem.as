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
	import mx.collections.ArrayCollection;
	
	public class FoodItem
	{
		private var _itemDescription:String;
		
		private var unitList:ArrayCollection;
		
		private var _itemid:int;
		
		/**
		 * expects an array of units<br>
		 * itemid is the id as known in the database<br>
		 * there's no database storage when creating a FoodItem<br>
		 */
		public function FoodItem(foodItemDescription:String, units:ArrayCollection,itemid:int) {
			unitList = units;
			this._itemDescription = foodItemDescription;
			this._itemid = itemid;
		}
		
		/*
		public function getItemDescription():String {
			return _itemDescription;
		}
		
		public function setItemDescription(itemDescription:String):void {
			this._itemDescription = itemDescription;
		}
		*/
		
		public function getUnit(location:int):Unit {
			return unitList.getItemAt(location) as Unit;
		}
		
		public function addUnit(newUnit:Unit):void {
			unitList.addItem(newUnit);
		}
		
		public function getNumberOfUnits():int {
			return unitList.length;
		}

		[Bindable]
		public function get itemDescription():String
		{
			return _itemDescription;
		}

		public function set itemDescription(value:String):void
		{
			_itemDescription = value;
		}

		internal function get itemid():int
		{
			return _itemid;
		}

		internal function set itemid(value:int):void
		{
			_itemid = value;
		}
		

	}
}