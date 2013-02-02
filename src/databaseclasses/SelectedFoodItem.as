/**
 Copyright (C) 2013  hippoandfriends
 
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
		private var _eventid:Number;
		private var _mealEventId:Number;

		public function get mealEventId():Number
		{
			return _mealEventId;
		}

		public function set mealEventId(value:Number):void
		{
			_mealEventId = value;
		}


		private var _lastModifiedTimestamp:Number;//i don't know why but if I set this private and use the getter and setter, I get errors "access of undefined poperty" ...
		
		public function get lastModifiedTimestamp():Number
		{
			return _lastModifiedTimestamp;
		}
		
		public function set lastModifiedTimestamp(value:Number):void
		{
			_lastModifiedTimestamp = value;
		}
		
		/**
		 * constructor taking description, unit and chosenamount as parameter
		 */
		public function SelectedFoodItem(newSelectedItemId:Number,description:String, unit:Unit,chosenAmount:Number, newLastModifiedTimeStamp:Number = Number.NaN):void
		{
			this._unit = new Unit(unit.unitDescription,unit.standardAmount,unit.kcal,unit.protein,unit.carbs,unit.fat);
			this._itemDescription = description;
			this._chosenAmount = chosenAmount;
			this._eventid = newSelectedItemId;

			if (!isNaN(newLastModifiedTimeStamp))
				_lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				_lastModifiedTimestamp = (new Date()).valueOf();
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
		 * when changed then also  database update happens with new value for chosenAmount<br>
		 * lastmodifiedtimestamp will get current date
		 */
		public function set chosenAmount(value:Number):void
		{
			_chosenAmount = value;
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp)) > _lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,_lastModifiedTimestamp.toString());
			
			_lastModifiedTimestamp = new Date().valueOf();
			
			Database.getInstance().updateSelectedFoodItem(_eventid,_mealEventId,_itemDescription,value,unit,_lastModifiedTimestamp,null);
		}
		

		public function get eventid():Number
		{
			return _eventid;
		}

		public function set eventid(value:Number):void
		{
			 _eventid = value;
		}
		
		/**
		 * deletes from database 
		 */
		public function deleteEvent():void {
			Database.getInstance().deleteSelectedFoodItem(_eventid,null);
		}
		
		/**
		 * if newLastModifiedTimestamp isnan the current timestamp is used 
		 */
		public function updateSelectedFoodItem(newDescription:String,newUnit:Unit,newLastModifiedTimeStamp:Number,newChosenAmount:Number):void  {
			_itemDescription = newDescription;
			_unit = newUnit;

			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp)) > _lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,_lastModifiedTimestamp.toString());

			_lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			_chosenAmount = newChosenAmount;
			
			Database.getInstance().updateSelectedFoodItem(_eventid,_mealEventId,_itemDescription,_chosenAmount,unit,_lastModifiedTimestamp,null);

		}

	}
}